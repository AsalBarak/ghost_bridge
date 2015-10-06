#! /bin/bash
#
# eva.sh
#
# ROS + blender launch script for the Hanson Robotics Eva blender head.
# This shell script wiill start up the various bits and pieces needed to
# get things to work.
#
# It needs to run in the catkin_ws directory where the various ROS nodes
# and blender models were installed. It assumes that catkin_make was
# already run.

# Change this for your setup!
export BLENDIR="../hr/blender_api"
export OCBHAVE="../opencog/ros-behavior-scripting/"
export PYTHONPATH=$PYTHONPATH:`pwd`/$OCBHAVE/src
export LD_LIBRARY_PATH=/usr/local/lib/opencog/modules

# Without this, some ros messages seem to run astray.
export ROS_IP=127.0.0.1

source devel/setup.sh
echo "Starting... this will take 15-20 seconds..."

# Use byobu so that the scroll bars actually work
byobu new-session -d -n 'ros' 'roscore; $SHELL'
sleep 4;

# Single Video (body) camera and face tracker
tmux new-window -n 'trk' 'roslaunch robots_config tracker-single-cam.launch; $SHELL'
# Publish the geometry messages
tmux new-window -n 'geo' 'roslaunch robots_config geometry.launch gui:=false; $SHELL'

### Start the blender GUI
tmux new-window -n 'eva' 'cd $BLENDIR && blender -y Eva.blend -P autostart.py; $SHELL'

# Start the cogserver.
tmux new-window -n 'cog' 'cogserver -c $OCBHAVE/scripts/opencog.conf; $SHELL'

cd $OCBHAVE/src
# Load data into the CogServer
sleep 10
# echo -e "py\n" | cat - ros_commo.py |netcat localhost 17020
echo -e "py\n" | cat - atomic.py |netcat localhost 17020
cat faces.scm |netcat localhost 17020
cat btree.scm |netcat localhost 17020
sleep 5

# Run the new face-tracker.
# tmux new-window -n 'face' '$OCBHAVE/face_track/main.py; $SHELL'
tmux new-window -n 'fce' '../face_track/main.py; $SHELL'

# Telnet shell
tmux new-window -n 'tel' 'rlwrap telnet localhost 17020; $SHELL'

# Fix the annoying byobu display
echo "tmux_left=\"session\"" > $HOME/.byobu/status
echo "tmux_right=\"load_average disk_io\"" >> $HOME/.byobu/status
tmux attach

echo "Started"
