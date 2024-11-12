#!/bin/bash

set -e

# Check if parameters are set
if [[ -z "$1" || -z "$2" || -z "$2" ]]; then
  echo "Usage: $0 <path> <shapy_path> <openpose_path>"
  exit 1
fi

# Assign command-line arguments to variables
path="$1"
shapy_path="$2"
openpose_path="$3"

# run OpenPose
$openpose_path/build/examples/openpose/openpose.bin --model-folder $openpose_path/models --image_dir $path/images --write-json $path/openpose --display 0 --render_pose 0

# run Shapy
python $shapy_path/regressor/demo.py --save-vis false --save-params true --save-mesh false --split test --datasets openpose --output-folder $path/shapy/ --exp-cfg $shapy_path/regressor/configs/b2a_expose_hrnet_demo.yaml --exp-opts output_folder=$shapy_path/data/trained_models/shapy/SHAPY_A part_key=pose datasets.pose.openpose.data_folder=$path datasets.pose.openpose.img_folder=images  datasets.pose.openpose.keyp_folder=openpose datasets.batch_size=1 datasets.pose_shape_ratio=1.0
