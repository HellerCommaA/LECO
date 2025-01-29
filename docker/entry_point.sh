#!/bin/bash

DOWNLOAD_MODELS=${DOWNLOAD_MODELS:-"true"}  # Default if not set
DOWNLOAD_BF16=${DOWNLOAD_BF16:-"false"}  # Default if not set
REPO_DIR=${REPO_DIR:-"/workspace/diffusion-pipe"}

echo "DOWNLOAD_MODELS is: $DOWNLOAD_MODELS and DOWNLOAD_BF16 is: $DOWNLOAD_BF16"

source /opt/conda/etc/profile.d/conda.sh
conda activate pyenv

echo "Adding environmnent variables"
export PYTHONPATH="$REPO_DIR:$REPO_DIR/submodules/HunyuanVideo:$PYTHONPATH"
export PATH="$REPO_DIR/configs:$PATH"
export PATH="$REPO_DIR:$PATH"

echo $PATH
echo $PYTHONPATH

cd /workspace/diffusion-pipe

# Use conda python instead of system python
echo "Starting Gradio interface..."
python gradio_interface.py &

# Use debugpy for debugging
# exec python -m debugpy --wait-for-client --listen 0.0.0.0:5678 gradio_interface.py

echo "Starting Tensorboard interface..."
$CONDA_DIR/bin/conda run -n pyenv tensorboard --logdir_spec=/workspace/outputs --bind_all --port 6006 &

wait
