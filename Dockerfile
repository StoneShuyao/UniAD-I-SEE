FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
# SHELL ["/bin/bash", "-lc"]
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

ARG CUDA_SM_LIST="6.0 6.1 6.2 7.0 7.2 7.5 8.0 8.6 8.9 9.0"
# 2) Export it for CMake (>=3.18) and PyTorch builds:
ENV CMAKE_CUDA_ARCHITECTURES=${CUDA_SM_LIST} \
    TORCH_CUDA_ARCH_LIST=${CUDA_SM_LIST}
ENV CPLUS_INCLUDE_PATH=/usr/local/cuda/include
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.9 python3.9-distutils python3.9-dev curl ca-certificates \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    git git-lfs ninja-build cmake build-essential \
    && rm -rf /var/lib/apt/lists/*

# Bootstrap pip for Python 3.9 (Ubuntu packages don't provide pip for alt versions)
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && python3.9 /tmp/get-pip.py \
    && rm -f /tmp/get-pip.py \
    && ln -sf /usr/bin/python3.9 /usr/local/bin/python \
    && ln -sf /usr/bin/python3.9 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.9 /usr/local/bin/pip \
    && ln -sf /usr/local/bin/pip3.9 /usr/local/bin/pip3

RUN python -m pip install --upgrade pip setuptools wheel pybind11 \
 && python -m pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118

WORKDIR /
RUN git clone https://github.com/open-mmlab/mmcv.git 
WORKDIR /mmcv
RUN git checkout v1.6.0
ENV MMCV_WITH_OPS=1 
ENV MMCV_CUDA_ARGS=-std=c++17
ENV CXXFLAGS="-std=c++17" CFLAGS="-std=c++17"
ENV CUDA_HOME=/usr/local/cuda 
ENV PATH=/usr/local/cuda/bin:$PATH 
ENV FORCE_CUDA=1
RUN pip install -r requirements/optional.txt
RUN MAX_JOBS=$(nproc) pip install . -v
# RUN pip install mmcv
# RUN pip install -U openmim
# RUN mim install mmengine
# RUN mim install 'mmcv==2.1.0'
# RUN mim install 'mmdet==2.26.0' 'mmsegmentation==0.29.1' 'mmdet3d==1.0.0rc6'
# RUN python .dev_scripts/check_installation.py
RUN pip install mmdet==2.26.0 mmsegmentation==0.29.1 mmdet3d==1.0.0rc6

COPY . /UniAD
WORKDIR /UniAD
RUN pip install -r requirements.txt
# Fix ImportError: networkx 2.2 uses fractions.gcd removed in Python 3.9+
RUN pip install --upgrade "networkx>=2.6,<3.0"

WORKDIR /workspace
CMD ["/bin/bash"]
