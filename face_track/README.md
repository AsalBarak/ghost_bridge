
Human Face Visual Servoing/Tracking
===================================

This is implements a quick-n-dirty ROS node to keep track of the
human faces visible in a scene.  It receives face-enter/leave events
from the webcam + pi_vision subsystem, as well as the current face
locations, in cooperation with the ROS tf2 position database, which
actually holds the actual 3D positions of the visible faces.

It takes this data and publishes face-detected/face-lost events to the
OpenCog AtomSpace.  The published messages are not ROS messages, but
are OpenCog atoms; for example, the current visible-face structure is:
```
  (EvaluationLink
     (PredicateNode "visible face")
     (ListLink
        (NumberNode "12")))
```
This node also listens for look-at messages from OpenCog, and reacts to
those, by giving Eva explicit instructions for where to look.

Running
-------
Just start `main.py` in a terminal.  This does not have any of the
pretty ROS rosrun, config, setup.py stuff in it yet.  Its a quick hack.

Design discussion
-----------------
This is a stand-alone ROS node only because of a simple, stupid reason:
it implements a form of imprecise visual servoing: when told to look
at a face, it will cause Eva to actively track that face as it moves
around in the scene.  This update needs to be done continuously, i.e. at
least 3-5 times a second, and this behavior is currently too
real-time-ish, to difficult to bother with in the AtomSpace. Currently.
This may change in the future, as we get beyond the prototyping stage.

For sending messages to opencog, there are two design choices:

A) Have the cogserver subscribe to ROS messages.

B) Send atoms, as strings, as mentioned above.

Lets review the pro's and cons of each.  Choice A seems direct, however,
it would require a putting a significant amount of ROS code running
within the cogserver.  For each received message, the ROS message would
need to be converted into Atoms.  However, Python is single-threaded;
running python in the cogserver requires grabbing the GIL.  Thus,
ultimately, this is not scalable: there is a bottleneck.

Choice A could work if we wrote the ROS code in C++ instead of python,
but that woud be yucky. Also converting ROS messges into atoms, in C++
would also be kind of icky.

Choice B is scalable, because we can run as many guile threads as we
want. Its more CPU intensive though: for each utf8-string message,
we have to create a thread, grab an unused guile interpreter,
interpret the string, poke the atoms into the atomspace, and shut
it all down again.

For Eva, the number of messages that we anticipate sending to the
cogserver is fairly low: a few per second, at most a few hundred per
second, so either solution A or B should work fine. Solution B was
implemented because it ws easier.

What actually happens
---------------------
Have `main.py` running in a shell. It creates an instance of FaceTrack,
and then loops forever.  FaceTrack is implemented in `face_track.py`
It subscribes to `pi_vision` ROS topics and uses tf to maintain
face locations in 3D.

When faces become visible, or disappear, the face ID is sent to the
OpenCog cogserver, using class `FaceAtomic`, implemented in
`face_atomic.py`.

FaceTrack has methods:
   gaze_at_face(face_id)
	look_at_face(face_id)
	glance_at_face(face_id)


We also have some python code running in the CogServer.  Its python, and
not something else, because that is the easiest way of sending ROS
messages out from OpenCog.  We need to be able to send such messages in
order to directly control blender, or for other reasons. That code is
in `../src/ros_commo.py`, implemetned as a normal python class. There is
a wrapper around it, because OpenCog currently does not play nice with
python classes. The wrapper is in `../src/atomic.py`.
