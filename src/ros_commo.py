#
# ros_commo.py - ROS messaging module for OpenCog behaviors.
# Copyright (C) 2015  Hanson Robotics
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License v3 as
# published by the Free Software Foundation and including the exceptions
# at http://opencog.org/wiki/Licenses
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to:
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


import rospy
import roslib
import time
import logging
import random
# Eva ROS message imports
from std_msgs.msg import String, Int32
from blender_api_msgs.msg import AvailableEmotionStates, AvailableGestures
from blender_api_msgs.msg import EmotionState
from blender_api_msgs.msg import SetGesture
from blender_api_msgs.msg import Target
from blender_api_msgs.msg import BlinkCycle
from blender_api_msgs.msg import SaccadeCycle

from put_atoms import PutAtoms
logger = logging.getLogger('hr.OpenCog_Eva')
# This class publishes various ROS messages to various locations.
# Class members are meant to be invoked from within the cogserver.
# Note that it ONLY publishes, it does not listen; currently listening
# must be done in some other ROS node, which must then convert those
# messages to scheme commands, and netcat them to the cogserver.
class EvaControl():

	def step(self):
		print "step once"
		return not rospy.is_shutdown()

	def look_left(self):
		self.look_at_point(1.0, 0.5, 0.0)
		return

	def look_right(self):
		self.look_at_point(1.0, -0.5, 0.0)
		return

	def look_center(self):
		self.look_at_point(1.0, 0.0, 0.0)
		return

	def happy(self):
		# Create the message
		exp = EmotionState()
		exp.name = 'happy'
		exp.magnitude = 1.0
		exp.duration.secs = 5
		exp.duration.nsecs = 250*1000000
		self.emotion_pub.publish(exp)
		print "Just published: ", exp.name

	def sad(self):
		# Create the message
		exp = EmotionState()
		exp.name = 'sad'
		exp.magnitude = 1.0
		exp.duration.secs = 5
		exp.duration.nsecs = 250*1000000
		self.emotion_pub.publish(exp)
		print "Just published: ", exp.name

	def nod(self):
		ges = SetGesture()
		ges.name = 'nod-2'
		ges.magnitude = 1.0
		ges.repeat = False
		ges.speed = 1.0
		self.gesture_pub.publish(ges)
		print "Just published gesture: ", ges.name

	# ----------------------------------------------------------
	# Wrapper for emotional expressions
	def expression(self, name, intensity, duration):
		if 'noop' == name :
			return
		# Create the message
		exp = EmotionState()
		exp.name = name
		exp.magnitude = intensity
		exp.duration.secs = int(duration)
		exp.duration.nsecs = 1000000000 * (duration - int(duration))
		self.emotion_pub.publish(exp)
		print "Publish expression: ", exp.name

	# Wrapper for gestures
	def gesture(self, name, intensity, repeat, speed):
		if 'noop' == name :
			return
		# Create the message
		ges = SetGesture()
		ges.name = name
		ges.magnitude = intensity
		ges.repeat = repeat
		ges.speed = speed
		self.gesture_pub.publish(ges)
		print "Published gesture: ", ges.name

	# ----------------------------------------------------------
	# Look at, gaze at, glance at face id's
	# Look_at turns entire head in that direction, once.
	# Gaze_at has the eyes track the face location (servoing)
	# Glance_t is a momentary eye movement towards the face target.

	def look_at(self, face_id):
		# Can get called 10x/second, don't print.
		# print "----- Looking at face: " + str(face_id)
		self.look_at_pub.publish(face_id)

	def gaze_at(self, face_id):
		print "----- Gazing at face: " + str(face_id)
		self.gaze_at_pub.publish(face_id)

	def glance_at(self, face_id):
		print "----- Glancing at face: " + str(face_id)
		self.glance_at_pub.publish(face_id)

	# ----------------------------------------------------------
	# Explicit directional look-at, gaze-at locations

	# Turn only the eyes towards the given target point.
	# Coordinates: meters; x==forward, y==to Eva's left.
	def gaze_at_point(self, x, y, z):
		print "gaze at point: ", x, y, z

		trg = Target()
		trg.x = x
		trg.y = y
		trg.z = z
		self.gaze_pub.publish(trg)

	# Turn head towards the given target point.
	# Coordinates: meters; x==forward, y==to Eva's left.
	def look_at_point(self, x, y, z):
		print "look at point: ", x, y, z

		trg = Target()
		trg.x = x
		trg.y = y
		trg.z = z
		self.turn_pub.publish(trg)

	# ----------------------------------------------------------
	# Wrapper for saccade generator.
	# This is setup entirely in python, and not in the AtomSpace,
	# as, at this time, there are no knobs worth twiddling.

	# Explore-the-room saccade when not conversing.
	def explore_saccade(self):

		# Switch to conversational (micro) saccade parameters
		msg = SaccadeCycle()
		msg.mean =  1.6          # saccade_explore_interval_mean
		msg.variation = 0.11     # saccade_explore_interval_var
		msg.paint_scale = 0.70   # saccade_explore_paint_scale
		# From study face, maybe better default should be defined for
		# explore
		msg.eye_size = 16.0      # saccade_study_face_eye_size
		msg.eye_distance = 27.0  # saccade_study_face_eye_distance
		msg.mouth_width = 7.0    # saccade_study_face_mouth_width
		msg.mouth_height = 18.0  # saccade_study_face_mouth_height
		msg.weight_eyes = 0.4    # saccade_study_face_weight_eyes
		msg.weight_mouth = 0.6   # saccade_study_face_weight_mouth
		self.saccade_pub.publish(msg)

	# Used during conversation to study face being looked at.
	def conversational_saccade(self):

		# Switch to conversational (micro) saccade parameters
		msg = SaccadeCycle()
		msg.mean =  0.42         # saccade_micro_interval_mean
		msg.variation = 0.10     # saccade_micro_interval_var
		msg.paint_scale = 0.40   # saccade_micro_paint_scale
		#
		msg.eye_size = 16.0      # saccade_study_face_eye_size
		msg.eye_distance = 27.0  # saccade_study_face_eye_distance
		msg.mouth_width = 7.0    # saccade_study_face_mouth_width
		msg.mouth_height = 18.0  # saccade_study_face_mouth_height
		msg.weight_eyes = 0.4    # saccade_study_face_weight_eyes
		msg.weight_mouth = 0.6   # saccade_study_face_weight_mouth
		self.saccade_pub.publish(msg)


	# ----------------------------------------------------------
	# Wrapper for controlling the blink rate.
	def blink_rate(self, mean, variation):
		msg = BlinkCycle()
		msg.mean = mean
		msg.variation = variation
		self.blink_pub.publish(msg)

	# ----------------------------------------------------------
	# Subscription callbacks
	# Get the list of available gestures.
	def get_gestures_cb(self, msg):
		print("Available Gestures:" + str(msg.data))

	# Get the list of available emotional expressions.
	def get_emotion_states_cb(self, msg):
		print("Available Emotion States:" + str(msg.data))

	def chat_event_cb(self,chat_event):
		rospy.loginfo('chat_event, type ' + chat_event.data)
		if chat_event.data == "speechstart":
			rospy.loginfo("webui starting speech")
			self.puta.chatbot_speech_start()

		elif chat_event.data == "speechend":
			self.puta.chatbot_speech_end()
			rospy.loginfo("webui ending speech")

	# Chatbot requests blink.
	def chatbot_blink_cb(self, blink):

		# XXX currently, this by-passes the OC behavior tree.
		# Does that matter?  Currently, probably not.
		rospy.loginfo(blink.data + ' says blink')
		blink_probabilities = {
			'chat_heard' : 0.4,
			'chat_saying' : 0.7,
			'tts_end' : 0.7 }
		# If we get a string not in the dictionary, return 1.0.
		blink_probability = blink_probabilities[blink.data]
		if random.random() < blink_probability:
			self.gesture('blink', 1.0, 1, 1.0)

	# The perceived emotional content of speech in the message.
	# emo is of type std_msgs/String
	# TODO best would be probably specify required behavior and see how that could be implemented
	# TODO Make use of config values
	# Currently this is workaround so chatbot provides answers fot those queries with emotional content
	def chatbot_affect_perceive_cb(self, emo):
		exp = EmotionState()
		exp.magnitude = random.choice([0.3,0.4,0.5])
		exp.duration.secs = random.choice([2,3,4])
		exp.duration.nsecs = 0
		rospy.loginfo('chatbot perceived emo class =' + emo.data)
		if emo.data == "happy":
			self.puta.chatbot_affect_happy()
			exp.name = random.choice(["happy","comprehending","engaged"])
		else:
			self.puta.chatbot_affect_negative()
			exp.name = random.choice(["confused","recoil","surprised"])
		# Only publish to chatbot. Emotoin should be controlled in opencog.
		# TODO replace expression name from behavior tree state
		self.affect_pub.publish(exp)


	# Turn behaviors on and off.
	# Do not to clean visible faces as these can still be added/removed while tree is paused
	def behavior_switch_callback(self, data):
		if data.data == "btree_on":
			self.puta.btree_state_running()
		if data.data == "btree_off":
			self.puta.btree_state_paused()


	def __init__(self):

		self.puta = PutAtoms()
		rospy.init_node("OpenCog_Eva")
		print("Starting OpenCog Behavior Node")

		rospy.Subscriber("/blender_api/available_emotion_states",
		       AvailableEmotionStates, self.get_emotion_states_cb)

		rospy.Subscriber("/blender_api/available_gestures",
		       AvailableGestures, self.get_gestures_cb)

		# Emotional content that the chatbot perceived i.e. did it hear
		# (or reply with) angry words, polite words, etc?
		# Currently chatbot supplies string rather than specific
		# EmotionState with timing, allowing that to be handled here where
		# timings have been tuned.
		rospy.logwarn("setting up chatbot affect perceive and express links")
		rospy.Subscriber("chatbot_affect_perceive", String,
			self.chatbot_affect_perceive_cb)

		# Chatbot can request blinks correlated with hearing and speaking.
		rospy.Subscriber("chatbot_blink", String, self.chatbot_blink_cb)

		# Handle messages from incoming speech to simulate listening
		# engagement.
		rospy.Subscriber("chat_events", String, self.chat_event_cb)

		self.emotion_pub = rospy.Publisher("/blender_api/set_emotion_state",
		                                   EmotionState, queue_size=1)
		self.gesture_pub = rospy.Publisher("/blender_api/set_gesture",
		                                   SetGesture, queue_size=1)
		self.blink_pub = rospy.Publisher("/blender_api/set_blink_randomly",
		                                   BlinkCycle, queue_size=1)
		self.saccade_pub = rospy.Publisher("/blender_api/set_saccade",
		                                   SaccadeCycle, queue_size=1)

		self.affect_pub = rospy.Publisher("chatbot_affect_express",
		                                   EmotionState, queue_size=1)

		# XYZ coordinates of where to turn and look.
		self.turn_pub = rospy.Publisher("/blender_api/set_face_target",
			Target, queue_size=1)

		self.gaze_pub = rospy.Publisher("/blender_api/set_gaze_target",
			Target, queue_size=1)

		# Int32 faceid of the face to glence at or turn and face.
		self.glance_at_pub = rospy.Publisher("/opencog/glance_at",
			Int32, queue_size=1)

		self.look_at_pub = rospy.Publisher("/opencog/look_at",
			Int32, queue_size=1)

		self.gaze_at_pub = rospy.Publisher("/opencog/gaze_at",
			Int32, queue_size=1)

		rospy.Subscriber("/behavior_switch", String, self.behavior_switch_callback)
