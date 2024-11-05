FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

WORKDIR /app

RUN apt update \
  && apt install -y --no-install-recommends wget zip unzip libturbojpeg libglfw3-dev libgles2-mesa-dev ninja-build \
  && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="$PYTHONPATH:/app/attributes/"
ENV EGL_DEVICE_ID=1
# ENV CUDA_SAMPLES_INC=/app/include
# ENV

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
