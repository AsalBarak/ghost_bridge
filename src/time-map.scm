;
; time-map.scm
;
; Copyright 2016 Hanson Robotics
;
(use-modules (srfi srfi-1) )
(use-modules (opencog) (opencog atom-types)
	(opencog eva-model) (opencog eva-behavior))

(use-modules (opencog ato pointmem)); needed for maps
(use-modules (opencog python))

(StateLink (ConceptNode "last person who spoke") (NumberNode "0"))
(StateLink (ConceptNode "previous person who spoke") (NumberNode "0"))
(define new-person-spoke 0)

; --------------------------------------------------------------------
; For recording facial coordinates, create octomap with 15hz,
; 10 second or 150 frames buffer and 1 cm spatial resolution.
(create-map "faces" 0.01 66 150)
; Initialize  the map
(step-time-unit "faces")
; Make the stepping take place automatically
(auto-step-time-on "faces")
; time-span is the amount of time in milliseconds to be considered
; for locating a face. The time limit for spatial memory for faces :-).
; The value is dependent on the frequency of update of the map and
; the number of frames, and is set as half the size of the total buffer.
(define face-loc-time-span 8000) ; (8000 milliseconds or 8 seconds)

; ---------------------------------------------------------------------
;; look-turn-at-face - Publish ROS message to turn or look at face.
;;
;; `FACE-ID-NODE` should be a Node holding a face-id.
;; `PY-CMD` should be the name of the python function to call to
;;     publish the ROS message. (This is hacky, because there are
;;     currently to scheme bindings to ROS. Alternately, this entire
;;     routine should have been written in python... XXX FIXME.)
;; Returns TRUE_TV if the face-id was found, else returns FALSE_TV.
;;
;; Given a face-id, this will get the last-known 3D (x,y,z) location
;; for that face from the space server. This 3D coordinate is then
;; published, via a python wrapper, as a ROS gaze-at or look-at command.
;; The robot (currently, the blender model) listens to this ROS topic,
;; and will move the robot.
;;
;; The python `gaze_at_face_point` function will move only the eyes,
;; while the python `look_at_face_point` will turn the neck+head.
;;
(define (look-turn-at-face FACE-ID-NODE PY-CMD)
	(define loc-atom
			(get-last-locs-ato "faces" FACE-ID-NODE face-loc-time-span))
	; XXX TODO wtf is loc-atom? what is being erturned here? where
	; is the get-last-locs-ato function documented?
	(if (cog-atom? loc-atom)
		(let* ((loc-link (car (cog-outgoing-set loc-atom)))
				(xx (number->string (loc-link-x loc-link)))
				(yy (number->string (loc-link-y loc-link)))
				(zz (number->string (loc-link-z loc-link))))
			(python-eval
				(string-append PY-CMD "(" xx "," yy "," zz ")"))
			(stv 1 1)
		)

		; There was no location, return false.
		(stv 0 1)
	)
)

;; glance-at-face - Turn the eyes to look at the given face-id.
;; look-at-face - Turn entire head to look at the given face-id.
;; See the `look-turn-at-face` for complete documentation.
;;
(define (glance-at-face FACE-ID-NODE)
	(look-turn-at-face FACE-ID-NODE "gaze_at_face_point")
)

(define (look-at-face FACE-ID-NODE)
	(look-turn-at-face FACE-ID-NODE "look_at_face_point")
)

; ---------------------------------------------------------------------
;; below creates say atom for face if sound came from it
;; XXX FIXME huh? this needs documentation.
(define (who-said? sent)
	;;request eye contact

	;;Debug below
	;(display "###### WHO SAID: ")
	;(display (cog-name
	;	(GetLink (TypedVariable (Variable "$fid") (TypeNode "NumberNode"))
	;		(StateLink
	;			(ConceptNode "last person who spoke")(VariableNode "$fid")))))

	(cog-execute!
	(PutLink
		(StateLink request-eye-contact-state (VariableNode "$fid"))
		(GetLink (TypedVariable (Variable "$fid") (TypeNode "NumberNode"))
			(StateLink
				(ConceptNode "last person who spoke") (VariableNode "$fid")))
	))
	;;generate info
	(cog-execute!
	(PutLink
	(AtTimeLink
		(TimeNode (number->string (current-time)))
		(EvaluationLink
			(PredicateNode "say_face")
				(ListLink
					(ConceptNode (cog-name (VariableNode "$fid")))
					(SentenceNode sent)))
			(ConceptNode "sound-perception"))
	(GetLink (TypedVariable (Variable "$fid") (TypeNode "NumberNode"))
		(StateLink
			(ConceptNode "last person who spoke") (VariableNode "$fid")))
	))
)

; ---------------------------------------------------------------------
;; Returns null string if atom not found, number x y z string if okay.
;; These functions assume only one location for one atom in a map at
;; a time.
(define (get-last-xyz map-name id-node elapse)
	(let* ((loc-atom (get-last-locs-ato map-name id-node elapse) ))
		(if (cog-atom? loc-atom)
			(let* ((loc-link (car (cog-outgoing-set loc-atom)))
					(xx (loc-link-x loc-link))
					(yy (loc-link-y loc-link))
					(zz (loc-link-z loc-link)))
				(list xx yy zz))
			(list)
		)
	)
)

;;scm code
(define (get-face face-id-node e-start)
	(get-last-xyz "faces" face-id-node (round e-start))
)

;;math
(define (dot-prod ax ay az bx by bz) (+ (* ax bx) (* ay by)(* az bz)))
(define (magnitude ax ay az) (sqrt (+ (* ax ax) (* ay ay) (* az az))))
(define (angle ax ay az bx by bz)
	(let* ((dp (dot-prod ax ay az bx by bz))
			(denom (* (magnitude ax ay az)(magnitude bx by bz))))
		(if (> denom 0)
			(acos (/ dp denom))
			0.0
		)
	)
)

;assuming common zero in coordinates
;assuming sound was saved with co-oridinate transform applied for camera
;angle in radians

(define (angle_face_id_snd face-id xx yy zz)
	(let* ((fc (get-face (NumberNode face-id) face-loc-time-span)))
		(if (null? fc)
			(* 2 3.142)
			(angle (car fc) (cadr fc) (caddr fc) xx yy zz)
		)
	)
)



;; Get all face-ids and only one sound id 1.0, compare them.
;; threshold = sound in +-15 degrees of face
;; below returns face id of face nearest to sound vector at least
;; 10 degrees, or 0 face id
(define (snd-nearest-face xx yy zz)

	; The visible faces are stored as EvaluationLinks, attached
	; to the predicate "visible face". This function returns a
	; list of nodes (NumberNodes, actually) holding the face id's.
	(define (get-visible-faces)
	   (define visible-face (PredicateNode "visible face"))
		(filter (lambda(y) (equal? (cog-type y) 'NumberNode))
			(map (lambda (x) (car (cog-outgoing-set x)))
				(cog-chase-link 'EvaluationLink 'ListLink visible-face))))

	; This converts the list of visible faces into ???
	(define face-list
		(map
			(lambda (x)
				(list (string->number (cog-name x))
					(angle_face_id_snd (cog-name x) xx yy zz)))
			 (get-visible-faces) ))

	(if (< (length face-list) 1)
		0
		(let* ((alist (append-map (lambda (x)(cdr x)) face-list))
				(amin (fold (lambda (n p) (min (abs p) (abs n)))
					(car alist) alist)))
			(if (> (/ (* 3.142 15.0) 180.0) amin)
				(car (car (filter
					(lambda (x) (> (+ amin 0.0001) (abs (cadr x)))) face-list)))
				0
			)
		)
	)
)

;; TODO: change this function to psi-rule later
(define (request-attention fid)
	(set! new-person-spoke fid)
	(StateLink request-eye-contact-state (NumberNode fid))
)

;; This needs to be define-public, so that ros-bridge can send this
;; to the cogserver.
(define-public (map-sound xx yy zz)
	(let* ((fid (snd-nearest-face xx yy zz)))
		(if (> fid 0)
			(StateLink (ConceptNode "last person who spoke") (NumberNode fid))
		)
	)
)
