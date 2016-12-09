
ROS Messaging Shims
===================

The code in this directory translates sensory input (vision, sound)
between ROS and OpenCog. It is written in python, because python
is a very natural API for ROS; it subscribes to assorted ROS topics,
and when ROS messages are received, these are converted into atomese
and sent on the to cogserver.  The interface and the translation is
rather informal, and ad hoc.

The `face_track.py` file implements a ROS node to pass information
about the visible human faces into the opencog `spacetime` server.
It receives 3D face locations from the webcam + `pi_vision` subsystem,
and auditory infromation from the `many_ears` subsystem.

As an example, face-detected events are converted to atoms of the form
```
  (EvaluationLink
     (PredicateNode "visible face")
     (ListLink
        (NumberNode "12")))  ;; the face id is currently an integer.
```

Similarly, we have:
 * `audio_power.py` - general loudness and sudden sounds (bangs, shouts)
 * `chat_track.py` - speech-to-text messages
 * `sound_track.py` - sound source localization (3D direction)

Running
-------
Just start `main.py` in a terminal.  This does not have any of the
pretty ROS rosrun, config, setup.py stuff in it yet.  Its a quick hack.


TODO
----
Maybe the `pi_vision` subsystem should be replaced by this:
http://wiki.ros.org/face_detection_tracking
https://github.com/phil333/face_detection
http://www.phil.lu/?page_id=328


Design discussion
-----------------
There are two design choices for having OpenCog interact with ROS:

A) Write a cogserver agent that subscribes to ROS messages, and then
   pokes the resulting data directly into the atomspace and/or the
   spacetime server.

B) Write a stand-alone ROS node that subscribes to ROS messages, and
   then converts these into (scheme) strings, which are then sent to
   the cogserver.

Lets review the pro's and cons of each.  Choice A seems direct; however,
it would require a putting a significant amount of ROS code running
within the cogserver.  For each received message, the ROS message would
need to be converted into Atoms.  However, Python is single-threaded;
running python in the cogserver requires grabbing the Python GIL.  Thus,
ultimately, this is not scalable: there is a bottleneck.  Python does
not work well in such scenarios.

Design A could work if the ROS code was written in C++ instead of python,
but that woud be yucky: C++ is hard to write. The ROS build system
conflicts with the opencog build system. Converting ROS messges into
atoms, in C++, is icky. The rosrun main loop can conflict with the
cogserver main loop.

Design choice B is scalable, because we can run as many guile threads
as we want. Its more CPU intensive though: on the cogserver side, for
each utf8-string message, we have to create a thread, grab an unused
guile interpreter, interpret the string, poke the atoms into the
atomspace, and shut it all down again.

For Eva, the number of messages that we anticipate sending to the
cogserver is low: currently, no more than a few hundred per second,
and so either solution A or B should work fine. Solution B was
implemented because it was easier.

Sending messages from OpenCog
-----------------------------
Sending ROS messages is simpler than subscribing to them, because
there is no need for a ROS main loop. These can be sent directly
from OpenCog.  Using python is the simplest, and the file
`../src/ros_commo.py` implements a normal python class. This has a
silly wrapper around it, because the current OpenCog python API does
not play nice with python classes. The wrapper is in `../src/atomic.py`.
