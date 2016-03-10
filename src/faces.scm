;
; Assorted utilities for supporting face tracking
; XXX most of face-tracking is now in self-model.scm
; Perhaps this file is not needed any more? XXX FIXME
;
(add-to-load-path "/usr/local/share/opencog/scm")

(use-modules (opencog))
(use-modules (opencog exec))
(use-modules (opencog query))

;; XXX FIXME: This file defines a "Room State", which currently can
;; be "empty" or "non-empty", depending on whether faces are visible
;; or not.  But this is kind-of pointless: its probably easier to just
;; check if the number of visible faces is greater than zero, or not.
;; Thus, this adds a complex mechanism, ripe for bugs, that is not
;; really needed .. and should probably be removed.  Right?

; Is the room empty, or is someone in it?
(define room-state (AnchorNode "Room State"))
(define room-empty (ConceptNode "room empty"))
(define room-nonempty (ConceptNode "room nonempty"))

;; Assume room empty at first
(StateLink room-state room-empty)

; A rule that looks for the visible-face marker, and
; sets the room-is-not-empty flag if a face is visible.
(DefineLink
	(DefinedPredicateNode "Check if room non-empty")
	(SatisfactionLink
		(SequentialAndLink
			; If someone is visible...
			(PresentLink (EvaluationLink (PredicateNode "visible face")
					(ListLink (VariableNode "$face-id"))))
			; Change the status of the room to "non-empty"
			(TrueLink (PutLink
					(StateLink room-state (VariableNode "$x"))
					room-nonempty)))))

; A rule that inverts the above.
(DefineLink
	(DefinedPredicateNode "Check if room empty")
	(SatisfactionLink
		(SequentialAndLink
			; If no-one is visible...
			(AbsentLink (EvaluationLink (PredicateNode "visible face")
						(ListLink (VariableNode "$face-id"))))

			; Change the status of the room to "empty"
			(TrueLink (PutLink
					(StateLink room-state (VariableNode "$x"))
					room-empty)))))

; A rule to update the room state
(DefineLink
	(DefinedPredicateNode "Update room state")
	(SatisfactionLink
		(SequentialOrLink
			(DefinedPredicateNode "Check if room non-empty")
			(DefinedPredicateNode "Check if room empty"))))

; -----------------------------------------------------------------
; Assorted debugging utilities.
;
;; Display the current room state
(define (show-visible-faces)
	(define visible-face (PredicateNode "visible face"))
	(map (lambda (x) (car (cog-outgoing-set x)))
	(cog-chase-link 'EvaluationLink 'ListLink visible-face)))

(define (show-acked-faces)
	(define acked-face (PredicateNode "acked face"))
	(map (lambda (x) (car (cog-outgoing-set x)))
	(cog-chase-link 'EvaluationLink 'ListLink acked-face)))

(define (show-room-state)
	(car (cog-chase-link 'StateLink 'ConceptNode room-state)))


(define (show-eye-contact-state)
	(define e-c-state (AnchorNode "Eye Contact State"))
	(car (cog-chase-link 'StateLink 'ConceptNode e-c-state)))


; define-public because `unit-test.scm` uses it.
(define-public (make-new-face id)
"
 make-new-face ID

 Debug utility - Quick hack to fill the room.

 Call this function to trick opencog into thinking there is a new
 visible face.  There will not be any corresponding 3D coords, so
 the ROS tf2 will not be able to make the robot turn to look...
"
	(EvaluationLink (PredicateNode "visible face")
		(ListLink (ConceptNode id))))

(define-public (remove-face id)
"
 remove-face ID

 Quick hack to remove face ID from the room
"
	(cog-delete (EvaluationLink (PredicateNode "visible face")
		(ListLink (ConceptNode id)))))

(define (undefine def)
	(cog-delete (car (cog-incoming-set def))))

#|
;; Example usage:
;;
(cog-evaluate! (DefinedPredicateNode "Update room state"))
(show-room-state)

(cog-incoming-set (PredicateNode "visible face"))

|#

;; ----
