;
; movement-api.scm
;
; Definitions providing the movement API.
;
; The definitions here give the API only, but not an implememtation.
; The only current implementation is in the module `(opencog movement)`
; which connects these to ROS blender API robot animations.

; Delete the current definition, if any.
(define (delete-definition STR)
	(define dfn
		(cog-get-link 'DefineLink 'DefinedPredicateNode
			(DefinedPredicate STR)))

	(if (not (null? dfn)) (cog-delete (car dfn)) #f))

; Printer stub
(define-public (prt-pred-defn PRED)
   (format #t "Called (DefinedPredicate ~a)\n" (cog-name PRED))
   (stv 1 1))

; Create a definition that is just a stub.
(define (dfn-pred PRED)
	(DefineLink
		PRED
		(EvaluationLink
			(GroundedPredicate "scm: prt-pred-defn")
			(ListLink PRED))))

;
; XXX FIXME: these record the animation that was chosen, and a
; timestamp in some StateLinks. These need to be replaced by the
; TimeServer, instead.
;
; -------------------------------------------------------------
; Request a display of a facial expression (smile, frown, etc.)
; The expression name should be one of the supported blender animations.
;
; Example usage:
;    (cog-evaluate! (Put (DefinedPredicate "Show facial expression")
;         (ListLink (Concept "happy") (Number 6) (Number 0.6))))
;
(delete-definition "Do show facial expression")
(DefineLink
	(DefinedPredicate "Do show facial expression")
	(LambdaLink
		(VariableList
			(Variable "$expr")
			(Variable "$duration")
			(Variable "$intensity"))
		(SequentialAndLink
			(TrueLink)
		)))

; -------------------------------------------------------------
; Request a display of a facial gesture (blink, nod, etc.)
; The expression name should be one of the supported blender animations.
;
; Example usage:
;    (cog-evaluate! (Put (DefinedPredicate "Show gesture")
;         (ListLink (Concept "blink") (Number 0.8) (Number 3) (Number 1))))
;
(delete-definition "Do show gesture")
(DefineLink
	(DefinedPredicate "Do show gesture")
	(LambdaLink
		(VariableList
			(Variable "$gest")
			(Variable "$insensity")
			(Variable "$repeat")
			(Variable "$speed"))
		(SequentialAndLink
			(True)
		)))

; -------------------------------------------------------------
; Eye-saccade control.
; Saying things should alter the saccade mode
;
; (cog-evaluate! (Put (DefinedPredicate "Say") (Node "this is a test"))))

(delete-definition "Conversational Saccade")
(delete-definition "Listening Saccade")
(delete-definition "Explore Saccade")

(dfn-pred (DefinedPredicate "Conversational Saccade"))
(dfn-pred (DefinedPredicate "Listening Saccade"))
(dfn-pred (DefinedPredicate "Explore Saccade"))

; -------------------------------------------------------------
; Control the blink rate of the robot.

(delete-definition "Blink rate")
(DefineLink
	(DefinedPredicate "Blink rate")
	(LambdaLink
		(VariableList (Variable "$mean") (Variable "$var"))
		(True)))

; -------------------------------------------------------------
; Request robot to look at a specific coordinate point.

(delete-definition "Do look at point")
(DefineLink
	(DefinedPredicate "Do look at point")
	(LambdaLink
		(VariableList (Variable "$x") (Variable "$y") (Variable "$z"))
		(SequentialAndLink
			(True)
		)))

;---------------------------------------------------------------

; Request robot to turn eyes at a specific coordinate point.

(delete-definition "Do gaze at point")
(DefineLink
	(DefinedPredicate "Do gaze at point")
	(LambdaLink
		(VariableList (Variable "$x") (Variable "$y") (Variable "$z"))
		(SequentialAndLink
			(True)
		)))

; -------------------------------------------------------------
; As above, but (momentarily) break eye contact, first.
; Otherwise, the behavior tree forces eye contact to be continually
; running, and the turn-look command is promptly over-ridden.
; XXX FIXME, this is still broken during search for attention.

(DefineLink
	(DefinedPredicate "Look command")
	(LambdaLink
		(VariableList (Variable "$x") (Variable "$y") (Variable "$z"))
		(SequentialAndLink
			(DefinedPredicate "break eye contact")
			(EvaluationLink (DefinedPredicate "Gaze at point")
				(ListLink (Variable "$x") (Variable "$y") (Variable "$z")))
			(EvaluationLink (DefinedPredicate "Look at point")
				(ListLink (Variable "$x") (Variable "$y") (Variable "$z")))
		)))

(DefineLink
	(DefinedPredicate "Gaze command")
	(LambdaLink
		(VariableList (Variable "$x") (Variable "$y") (Variable "$z"))
		(SequentialAndLink
			(DefinedPredicate "break eye contact")
			(EvaluationLink (DefinedPredicate "Gaze at point")
				(ListLink (Variable "$x") (Variable "$y") (Variable "$z")))
		)))

; The language-subsystem can understand commands such as "look at me"
; or, more generally, "look at this thing". At the moment, the only
; thing we can look at are faces, and the "salient point"
(DefineLink
	(DefinedPredicate "Look-at-thing cmd")
	(LambdaLink
		(Variable "$object-id")
		(SequentialOr
			(SequentialAnd
				(Equal (Variable "$object-id") (Concept "salient-point"))
				(DefinedPredicate "look at salient point"))
			(Evaluation
				(DefinedPredicate "Set interaction target")
				(ListLink (Variable "$object-id")))
		)))

;Salient
(DefineLink
	(DefinedPredicate "look at salient point")
	(SequentialAnd
		(True (Put
			(Evaluation (DefinedPredicate "Look at point")
				(List (Variable "$x") (Variable "$y") (Variable "$z")))
			(Get (State salient-loc
				(List (Variable "$x") (Variable "$y") (Variable "$z"))))
		))
		(True (Put
			(Evaluation (DefinedPredicate "Gaze at point")
				(List (Variable "$x") (Variable "$y") (Variable "$z")))
			(Get (State salient-loc
				(List (Variable "$x") (Variable "$y") (Variable "$z"))))
		))
	))

; -------------------------------------------------------------
; Publish the current behavior.
; Cheap hack to allow external ROS nodes to know what we are doing.
; The string name of the node is sent directly as a ROS String message
; to the "robot_behavior" topic.
;
; Example usage:
;    (cog-evaluate! (Put (DefinedPredicate "Publish behavior")
;         (ListLink (Concept "foobar joke"))))
;
(DefineLink
	(DefinedPredicate "Publish behavior")
	(LambdaLink
		(VariableList (Variable "$bhv"))
		(True)
		))

; -------------------------------------------------------------
; Request to change the soma state.
; Takes two arguments: the requestor, and the proposed state.
;
; Currently, this always honors all requests.
; Currently, the requestor is ignored.
;
; Some future version may deny change requests, depending on the
; request source or on other factors.

(DefineLink
	(DefinedPredicate "Request Set Soma State")
	(LambdaLink
		(VariableList
			(Variable "$requestor")
			(Variable "$state"))
		(True (State soma-state (Variable "$state")))
	))

; -------------------------------------------------------------
; Request to change the facial expression state.
; Takes two arguments: the requestor, and the proposed state.
;
; Currently, this always honors all requests.
; Currently, the requestor is ignored.
;
; XXX Currently, this does nothing at all. Some future version may
; deny change requests, depending on the request source or on other
; factors.  XXX This is incompletely thought out and maybe should be
; removed.

(DefineLink
	(DefinedPredicate "Request Set Face Expression")
	(LambdaLink
		(VariableList
			(Variable "$requestor")
			(Variable "$state"))
		(True)
	))

; -------------------------------------------------------------

; Call once, to fall asleep.
(DefineLink
	(DefinedPredicate "Go to sleep")
	(SequentialAnd
		; Proceed only if we are allowed to.
		(Put (DefinedPredicate "Request Set Face Expression")
			(ListLink bhv-source (ConceptNode "sleepy")))

		; Proceed with the sleep animation only if the state
		; change was approved.
		(Evaluation (DefinedPredicate "Request Set Soma State")
			(ListLink bhv-source soma-sleeping))

		(Evaluation (GroundedPredicate "scm: print-msg-time")
			(ListLink (Node "--- Go to sleep.")
				(Minus (TimeLink) (DefinedSchema "get bored timestamp"))))
		(True (DefinedSchema "set sleep timestamp"))

		(Put (DefinedPredicate "Publish behavior")
			(Concept "Falling asleep"))

		; First, show some yawns ...
		(Put (DefinedPredicate "Show random gesture")
			(Concept "sleepy"))

		; Finally, play the go-to-sleep animation.
		(Evaluation (GroundedPredicate "py:do_go_sleep") (ListLink))
	))

; Wake-up sequence
(DefineLink
	(DefinedPredicate "Wake up")
	(SequentialAnd
		; Request change soma state to being awake. Proceed only if
		; the request is accepted.
		(Evaluation (DefinedPredicate "Request Set Soma State")
			(ListLink bhv-source soma-awake))

		; Proceed only if we are allowed to.
		(Put (DefinedPredicate "Request Set Face Expression")
			(ListLink bhv-source (ConceptNode "wake-up")))

		(Evaluation (GroundedPredicate "scm: print-msg-time")
			(ListLink (Node "--- Wake up!")
				(Minus (TimeLink) (DefinedSchema "get sleep timestamp"))))

		(Put (DefinedPredicate "Publish behavior")
			(Concept "Waking up"))

		; Reset the bored timestamp, as otherwise we'll fall asleep
		; immediately (cause we're bored).
		(True (DefinedSchema "set bored timestamp"))

		; Reset the "heard something" state and timestamp.
		(True (DefinedPredicate "Heard Something?"))
		(True (DefinedSchema "set heard-something timestamp"))

		; Run the wake animation.
		(Evaluation (GroundedPredicate "py:do_wake_up") (ListLink))

		; Also show the wake-up expression (head shake, etc.)
		(Put (DefinedPredicate "Show random expression")
			(Concept "wake-up"))
		(Put (DefinedPredicate "Show random gesture")
			(Concept "wake-up"))
	))

; -------------------------------------------------------------
; Say something. To test run,
; (cog-evaluate! (Put (DefinedPredicate "Say") (Node "this is a test"))))
(DefineLink
	(DefinedPredicate "Say")
	(LambdaLink (Variable "sentence")
		(Evaluation
			(GroundedPredicate "py: say_text")
			(List (Variable "sentence")))
	))

; -------------------------------------------------------------
; Return true if ROS is still running.
(DefineLink
	(DefinedPredicate "ROS is running?") (True))

; -------------------------------------------------------------
*unspecified*  ; Make the load be silent
