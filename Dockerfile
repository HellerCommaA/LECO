ARG CUDA_VERSION="12.4.1"
ARG CUDNN_VERSION=""
ARG UBUNTU_VERSION="22.04"
ARG DOCKER_FROM=nvidia/cuda:$CUDA_VERSION-cudnn$CUDNN_VERSION-devel-ubuntu$UBUNTU_VERSION
ARG GRADIO_PORT=7860

FROM $DOCKER_FROM AS base

WORKDIR /

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHON_VERSION=3.10
ENV CONDA_DIR=/opt/conda
ENV PATH="$CONDA_DIR/bin:$PATH"
ENV NUM_GPUS=1

# Install dependencies required for Miniconda
RUN apt-get update -y && \
    apt-get install -y wget bzip2 ca-certificates git curl && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    emacs \
    git \
    jq \
    libcurl4-openssl-dev \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libsm6 \
    libssl-dev \
    libxext6 \
    libxrender-dev \
    software-properties-common \
    openssh-server \
    openssh-client \
    git-lfs \
    vim \
    zip \
    unzip \
    zlib1g-dev \
    libc6-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda init bash

# Create environment with Python 3.10 and MPI
RUN $CONDA_DIR/bin/conda create -n pyenv python=3.10 -y && \
    $CONDA_DIR/bin/conda install -n pyenv -c conda-forge openmpi mpi4py -y


# Define PyTorch versions via arguments
ARG PYTORCH="2.5.1"
ARG CUDA="124"

COPY requirements.txt /workspace

# Install PyTorch with specified version and CUDA
RUN $CONDA_DIR/bin/conda run -n pyenv \
    pip install torch==$PYTORCH torchvision torchaudio --index-url https://download.pytorch.org/whl/cu$CUDA && \
    pip install xformers && \
    pip install -r /workspace/requirements.txt

RUN $CONDA_DIR/bin/conda install -n pyenv nvidia/label/cuda-12.4.1::cuda-nvcc


# Install git lfs
RUN apt-get update && apt-get install -y git-lfs && git lfs install

# Install nginx
RUN apt-get update && \
    apt-get install -y nginx

COPY docker/default /etc/nginx/sites-available/default

# Add Jupyter Notebook
RUN pip install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions nodejs

EXPOSE 8888

# Tensorboard
EXPOSE 6006

# Debug
# RUN $CONDA_DIR/bin/conda run -n pyenv \
#     pip install debugpy

# EXPOSE 5678


# Copy the entire project
COPY --chmod=755 . /workspace

COPY --chmod=755 docker/initialize.sh /initialize.sh
COPY --chmod=755 docker/entry_point.sh /entry_point.sh

# Expose the Gradio port
EXPOSE $GRADIO_PORT

CMD [ "/initialize.sh" ]