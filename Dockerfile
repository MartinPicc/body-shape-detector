FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-devel as dev

WORKDIR /app

RUN apt update && apt install wget zip unzip

COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH=$PYTHONPATH:$(pwd)/attributes/
ENV CUDA_SAMPLES_INC=$(pwd)/include

RUN cd ./attributes && python setup.py install
RUN cd ./mesh-mesh-intersection && python setup.py install

ARG shapy_usr
ARG shapy_pwd
RUN ./download_models.sh $shapy_usr $shapy_pwd

FROM dev

RUN apt update && apt install libglib2.0-0 libturbojpeg

CMD tail -f /dev/null
