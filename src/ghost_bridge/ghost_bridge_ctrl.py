import rospy
from hr_msgs.msg import ChatMessage
from ghost_bridge.perception_ctrl import PerceptionCtrl
from ros_people_model.msg import Faces
from ghost_bridge.netcat import netcat

'''
Subscribes to topics published by
    https://github.com/hansonrobotics/asr/blob/master/scripts/google_speech.py
and forwards them to OpenCog as per
    https://github.com/opencog/opencog/tree/master/opencog/ghost
'''


class OpenCogBridge:
    EMOTION_MAP = {
        0: "anger",
        1: "disgust",
        2: "fear",
        3: "happy",
        4: "sad",
        5: "surprise",
        6: "neutral"
    }

    EYE_MAP = {
        0: "left",
        1: "right"
    }

    START_AGENTS_CMD = "agents-start opencog::AFImportanceDiffusionAgent opencog::WAImportanceDiffusionAgent " \
                       "opencog::AFRentCollectionAgent opencog::WARentCollectionAgent"

    def __init__(self):
        self.hostname = "localhost"
        self.port = 17001

        self.perception_ctrl = PerceptionCtrl(self.hostname, self.port)
        self.robot_name = rospy.get_param("robot_name")
        self.face_id = ''

        rospy.Subscriber(self.robot_name + "/words", ChatMessage, self.perceived_word)
        rospy.Subscriber(self.robot_name + "/speech", ChatMessage, self.perceived_sentence)
        rospy.Subscriber('/faces_throttled', Faces, self.faces_cb)

        self.start_agents()

    def start_agents(self):
        netcat(self.hostname, self.port, OpenCogBridge.START_AGENTS_CMD)

    def perceived_word(self, msg):
        self.perception_ctrl.perceive_word(self.face_id, msg.utterance)
        self.perception_ctrl.perceive_face_talking(self.face_id, 1.0)

    def perceived_sentence(self, msg):
        self.perception_ctrl.perceive_sentence(msg.utterance)
        self.perception_ctrl.perceive_face_talking(self.face_id, 0.0)

    def faces_cb(self, data):
        for face in data.faces:
            if face.face_id is "":
                continue

            self.perception_ctrl.perceive_face(face.face_id, face.position.x, face.position.y, face.position.z,
                                               face.certainty)

            if len(face.eye_states) > 0:
                for i, state in enumerate(face.eye_states):
                    self.perception_ctrl.perceive_eye_state(face.face_id, OpenCogBridge.EYE_MAP[i], state)

            if len(face.emotions) > 0:
                for i, confidence in enumerate(face.emotions):
                    self.perception_ctrl.perceive_emotion(face.face_id, OpenCogBridge.EMOTION_MAP[i], confidence)
