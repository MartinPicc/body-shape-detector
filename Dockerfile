FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

ARG DIR=/app
WORKDIR ${DIR}

# install external dependencies
RUN apt update \
  && apt install -y --no-install-recommends wget zip unzip libturbojpeg libglfw3-dev libgles2-mesa-dev ninja-build libatlas-base-dev libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libgflags-dev libgoogle-glog-dev liblmdb-dev opencl-headers ocl-icd-opencl-dev libviennacl-dev libopencv-dev cmake cudnn9-cuda-11 libboost-all-dev \
  && apt clean \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy files and build dependencies
COPY ./shapy ./shapy
ARG TORCH_CUDA_ARCH_LIST="3.7;5.0;6.0;7.0;7.5;8.0;8.6;9.0+PTX"
RUN cd ./shapy/attributes \
  && python setup.py install \
  && rm -rf ./build ./dist ./*.egg-info
RUN cd ./shapy/mesh-mesh-intersection \
  && python setup.py install \
  && rm -rf ./build ./dist ./*.egg-info

# download models
ARG shapy_usr
ARG shapy_pwd
RUN cd ./shapy/data \
  && chmod +x ./download_models.sh \
  && ./download_models.sh "$shapy_usr" "$shapy_pwd"

# Install OpenPose and models
COPY ./install_openpose.sh .
RUN chmod +x ./install_openpose.sh \
  && ./install_openpose.sh

# copy API folder
COPY ./api ./api

# ENV
ENV PYTHONPATH="${PYTHONPATH}:/app/shapy/attributes/:/app/shapy/regressor"
ENV EGL_DEVICE_ID=1
ENV SHAPY_DIR=${DIR}/shapy
ENV OPENPOSE_DIR=${DIR}/openpose
ENV API_DIR=${DIR}/shapy/regressor
ENV TEMP_DIR=${DIR}/temp

# CMD tail -f /dev/null
CMD python -u ${API_DIR}/main.py
