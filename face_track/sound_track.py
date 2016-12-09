#
# sound_track.py -  Tracking of sound sources
# Copyright (C) 2014,2015,2016  Hanson Robotics
# Copyright (C) 2015,2016 Linas Vepstas
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import rospy
import logging

from std_msgs.msg import Int32

from face_atomic import FaceAtomic
from geometry_msgs.msg import PoseStamped # for sound localization

logger = logging.getLogger('hr.eva_behavior.sound_track')

# Thin python wrapper, to subscribe to ManyEars sound-source ROS
# messages, and then re-wrap these as opencog atoms, via FaceAtomic,
#a and forward them on into the OpenCog space-time server.
#
class SoundTrack:

	def __init__(self):

		rospy.init_node("OpenCog_Facetracker")
		logger.info("Starting OpenCog Face Tracker ROS Node")

		# The OpenCog API. This is used to send face data to OpenCog.
		self.atomo = FaceAtomic()

		# Sound localization
		parameter_name = "sound_localization/mapping_matrix"
		if rospy.has_param(parameter_name):
			self.sl_matrix = rospy.get_param(parameter_name)
			rospy.Subscriber("/manyears/source_pose", PoseStamped, \
				self.sound_cb)

	# ---------------------------------------------------------------
	# Store the location of the strongest sound-source in the
	# OpenCog space server.  This data arrives at a rate of about
	# 30 Hz, currently, from ManyEars.
	def sound_cb(self, msg):
		# Convert to camera coordinates, using an affine matrix
		# (which combines a rotation and translation).
		#
		# A typical sl_matrix looks like this:
		#
		#   0.943789   0.129327   0.304204 0.00736024
		#   -0.131484   0.991228 -0.0134787 0.00895614
		#   -0.303278 -0.0272767   0.952513  0.0272001
		#   0          0          0          1
		#
		vs = [msg.pose.position.x, \
		      msg.pose.position.y, \
		      msg.pose.position.z, \
		      1]

		r = [0, 0, 0, 0]
		for i in range(0,3):
			for j in range(0,3):
				r[i] += self.sl_matrix[i][j] * vs[j]

		self.atomo.update_sound(r[0], r[1], r[2])

	# ----------------------------------------------------------
