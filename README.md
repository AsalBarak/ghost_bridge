ghost_bridge
============
ghost_bridge is a ROS package that connects the Hanson Robotics stack and [GHOST](https://github.com/opencog/opencog/tree/master/opencog/ghost).
It provides a set of actions that can be called from GHOST and a set of perceptions that are sent to the OpenCog
Atomspace, an overview of the actions and perceptions are provided below.

#### Actions:
* **say**: make the robot vocalize text.
* **gaze-at**: turn the robot's eyes towards the given target point.
* **face-toward**: turn the robot's face towards the given target point.
* **blink**: set the robot's blink cycle.
* **saccade**: set the robot's eye saccade cycle, i.e. how the eye's twitch and move around automatically.
* **emote**: set the robot's emotional state.
* **gesture**: set a pose on the robot's face.
* **soma**: sets the robot's background facial expressions.

#### Perceptions:
* **perceive-emotion**: perceive an emotion.
* **perceive-eye_state**: perceive the state of a person's eyes.
* **perceive-face-talking**: the probability of whether a particular face is talking or not.
* **perceive-word**: perceive an individual word that is a part of the sentence a person is currently speaking.
* **perceive-sentence** (ghost): perceive the whole sentence after the user has finished speaking.

Setup
-------
Follow the steps below to setup the ghost_bridge stack.

#### 1. Setup HEAD stack
Setup the Hanson Robotics head stack by following [these instructions](https://github.com/hansonrobotics/hrtool).

#### 2. Configure ~/.bashrc
Add the following to your ~/.bashrc, 
```bash
source /opt/ros/kinetic/setup.bash
export HR_WORKSPACE="$(hr env | grep HR_WORKSPACE | cut -d = -f 2)"
source ${HR_WORKSPACE}/HEAD/devel/setup.bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64/
```

Ensure you source your ~/.bashrc afterwards:
```bash
source ~/.bashrc
```

#### 3. Install dependencies
If you have an NVIDIA GPU and have CUDA setup:
```bash
sudo pip install dlib tensorflow-gpu keras
```

Otherwise:
```bash
sudo pip install dlib tensorflow keras
```

#### 4. Checkout ghost repos
Clone ghost_bridge:
```bash
cd ${HR_WORKSPACE}/HEAD/src && git clone https://github.com/opencog/ghost_bridge.git
```

Clone ros_people_model:
```bash
cd ${HR_WORKSPACE}/HEAD/src && git clone https://github.com/elggem/ros_people_model.git
```

Checkout the ghost branch of chatbot, hr_launchpad and configs:
```bash
cd ${HR_WORKSPACE}/HEAD/src/chatbot && git checkout ghost
cd ${HR_WORKSPACE}/configs && git checkout ghost
cd ${HR_WORKSPACE}/hr_launchpad && git checkout ghost
```

Build the head stack
```bash
hr build head
```

#### 5. Setup OpenCog
Install octool and OpenCog dependencies:
```bash
sudo curl -L http://raw.github.com/opencog/ocpkg/master/ocpkg -o /usr/local/bin/octool
sudo chmod +x /usr/local/bin/octool
octool -d
```

Install OpenCog repos:
```bash
hr update opencog
```

Remove ros-behavior-scripting and checkout the ghost-lai branch of opencog and atomspace:
```bash
sudo rm -r ${HR_WORKSPACE}/OpenCog/ros-behavior-scripting
cd ${HR_WORKSPACE}/OpenCog/atomspace && git checkout ghost-lai
cd ${HR_WORKSPACE}/OpenCog/opencog && git checkout ghost-lai
```

Build OpenCog:
```bash
hr build opencog
```

Running
-------
Run the robot first:
```bash
hr run --nogui --dev sophia10
```

Then run ghost_bridge:
```bash
rosrun ghost_bridge run.sh
```

To stop the robot:
```bash
hr stop
```

To stop ghost_bridge:
```bash
rosrun ghost_bridge stop.sh
```

Design Goals
------------
TODO

Architecture
-------------------------------
TODO