#!/bin/bash
# Download and install OpenPose

# clone repo
git clone -q --depth 1 https://github.com/CMU-Perceptual-Computing-Lab/openpose.git

# download models and extract
wget --progress=dot:giga 'https://drive.usercontent.google.com/download?id=1QCSxJZpnWvM00hx49CJ2zky7PWGzpcEh&export=download&authuser=0&confirm=t&uuid=049ae68b-ace5-4b2d-b813-308d8d8c2361&at=AENtkXYDlTLPUckKTkfNsT-ivbYB%3A1731252327225' -O 'openpose_models.zip' --continue
unzip openpose_models.zip
mv openpose_models/pose/body_25/pose_iter_584000.caffemodel ./openpose/models/pose/body_25/pose_iter_584000.caffemodel
mv openpose_models/face/pose_iter_116000.caffemodel ./openpose/models/face/pose_iter_116000.caffemodel
mv openpose_models/hand/pose_iter_102000.caffemodel ./openpose/models/hand/pose_iter_102000.caffemodel
rm openpose_models.zip
rm -rf openpose_models

# set up python path
# export PYTHONPATH=$PYTHONPATH:/workspace/openpose/build/python
# ./build/examples/openpose/openpose.bin --image_dir /workspace/body-shape-detector/api/images/ --write-json /workspace/body-shape-detector/api/openpose --display 0 --render_pose 0
