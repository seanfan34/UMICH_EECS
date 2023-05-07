#!/bin/bash
# "#SBATCH" directives that convey submission options:
##### The name of the job
#SBATCH --job-name=gpu-tutorial
##### When to send e-mail: pick from NONE, BEGIN, END, FAIL, REQUEUE, ALL
#SBATCH --mail-type=END,FAIL
##### Resources for your job
# number of physical nodes
#SBATCH --nodes=1
# number of task per a node (number of CPU-cores per a node)
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
# memory per a node
#SBATCH --mem-per-cpu=5g
##### Maximum amount of time the job will be allowed to run
##### Recommended formats: MM:SS, HH:MM:SS, DD-HH:MM
#SBATCH --time=30:00
##### The resource account; who pays
#SBATCH --account=eecs570s001w23_class
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
########## End of preamble! #########################################
echo "SLURM_GPUS_ON_NODE=$SLURM_GPUS_ON_NODE"
echo "GPU Id: $CUDA_VISIBLE_DEVICES"
# This script requires:
module load gcc cuda/11.6.2
# Job command:
nvcc 570_cuda.cu -o cuda
#./cuda
cuda-memcheck ./cuda
