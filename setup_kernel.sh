#!/usr/bin/env bash

# Create Jupyter Kernel from Shifter images
# By Andrew Naylor - May 24

JUPYTER_KERNEL=~/.local/share/jupyter/kernels
SHIFTER_IMAGE=vllm/vllm-openai:v0.5.0
ENV_NAME=vllm_0.5.0
ENV_JSON=$JUPYTER_KERNEL/$ENV_NAME/kernel.json


#Install ipykernel + ray dashboard
echo "-- Setup ipykernel --"
shifter --image=$SHIFTER_IMAGE \
        python3 -m pip install ipykernel "ray[default]==2.24.0"

echo "-- Creating Jupyter Kernel --"
shifter --image=$SHIFTER_IMAGE \
        python3 -m ipykernel install \
        --prefix $HOME/.local \
        --name $ENV_NAME --display-name $ENV_NAME

jq ".argv = [\"shifter\", \"--image=$SHIFTER_IMAGE\", \"--module=gpu,nccl-2.18\"] + .argv " $ENV_JSON | \
sponge $ENV_JSON

echo "-- Kernel creation complete, restart JupyterHub --"