#!/usr/bin/env bash

#SBATCH -C gpu
#SBATCH --time=00:30:00
#SBATCH -q debug

### This script works for any number of nodes, Ray will find and manage all resources
#SBATCH --nodes=2

### Give all resources to a single Ray task, ray can manage the resources internally
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-task=4
#SBATCH --cpus-per-task=128

export RAY_NODE_ADDRESS=$1
SHIFTER_IMAGE=vllm/vllm-openai:v0.5.0
SHIFTER_MODULES="gpu,nccl-2.18"

nodes=$(scontrol show hostnames $SLURM_JOB_NODELIST) # Getting the node names
nodes_array=( $nodes )

## Start ray worker
worker_num=$SLURM_JOB_NUM_NODES #number of nodes
echo "[slurm] - Starting $worker_num ray worker"
for ((  i=0; i<$worker_num; i++ ))
do
  node_i=${nodes_array[$i]}
  echo "    - $i at $node_i"
  srun --nodes=1 --ntasks=1 -w $node_i \
    shifter --image=$SHIFTER_IMAGE --module=$SHIFTER_MODULES \
        ray start --address $RAY_NODE_ADDRESS --block &
done

sleep infinity 

echo "[slurm] Exiting slurm script..."
exit