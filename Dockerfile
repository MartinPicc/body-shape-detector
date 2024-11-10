FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

WORKDIR /app

RUN apt update \
  && apt install -y --no-install-recommends wget zip unzip libturbojpeg libglfw3-dev libgles2-mesa-dev ninja-build \
  && apt clean \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="${PYTHONPATH}:/app/attributes/:/app/regressor"
ENV EGL_DEVICE_ID=1

COPY . .
ARG TORCH_CUDA_ARCH_LIST="3.7;5.0;6.0;7.0;7.5;8.0;8.6;9.0+PTX"
RUN cd ./attributes \
  && python setup.py install \
  && rm -rf ./build ./dist ./*.egg-info
RUN cd ./mesh-mesh-intersection \
  && python setup.py install \
  && rm -rf ./build ./dist ./*.egg-info

ARG shapy_usr
ARG shapy_pwd
RUN cd ./data \
  && chmod +x ./download_models.sh \
  && ./download_models.sh "$shapy_usr" "$shapy_pwd"

CMD tail -f /dev/null


git clone -q --depth 1 https://github.com/CMU-Perceptual-Computing-Lab/openpose.git
apt update && apt install -y libatlas-base-dev libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libgflags-dev libgoogle-glog-dev liblmdb-dev opencl-headers ocl-icd-opencl-dev libviennacl-dev libopencv-dev cmake cudnn9-cuda-11 libboost-all-dev
# DL models from https://www.kaggle.com/datasets/changethetuneman/openpose-model
wget --progress=dot:giga 'https://drive.usercontent.google.com/download?id=1QCSxJZpnWvM00hx49CJ2zky7PWGzpcEh&export=download&authuser=0&confirm=t&uuid=049ae68b-ace5-4b2d-b813-308d8d8c2361&at=AENtkXYDlTLPUckKTkfNsT-ivbYB%3A1731252327225' -O 'openpose-models.zip' --continue
unzip openpose-models.zip
mv openpose-models/pose/body_25/pose_iter_584000.caffemodel ./openpose/models/pose/body_25/pose_iter_584000.caffemodel
mv openpose-models/face/pose_iter_116000.caffemodel ./openpose/models/face/pose_iter_116000.caffemodel
mv openpose-models/hand/pose_iter_102000.caffemodel ./openpose/models/hand/pose_iter_102000.caffemodel
export PYTHONPATH=$PYTHONPATH:/workspace/openpose/build/python
./build/examples/openpose/openpose.bin --image_dir /workspace/body-shape-detector/api/images/ --write-json /workspace/body-shape-detector/api/openpose --display 0 --render_pose 0

