#!/bin/bash


#SBATCH --job-name=Covid                  # Job name
#SBATCH --nodes=1              		  # Number of nodes
#SBATCH --ntasks=32                       # Number of tasks (processes)
#SBATCH --output=%x.%j.out                # Stdout (%j expands to jobId)
#SBATCH --error=%x.%j.err                 # Stderr (%j expands to jobId)
#SBATCH --time=14-00:00:00                # Walltime
#SBATCH --mail-type=ALL                   # Mail notification
#SBATCH --mail-user=acatano@eafit.edu.co  # User Email
#SBATCH --partition=longjobs	          # Partition

##### Python #####
cd ..
module load python-3.6.0-gcc-11.2.0-emhuany
module load miniconda3-4.10.3-oneapi-2022.0.0-2mgeehu
source activate covid19
python download.py

##### ENVIRONMENT CREATION #####
cd ValidacionChimera
module load matlab/r2021a

##### JOB COMMANDS ####
matlab -nosplash -nodesktop < run.m

#### UPDATE SERVER ####
scp -i ~/.ssh/efcv_webapp_keypair.pem Outs/*.json ubuntu@54.83.170.197:~/mathcovid/mathcovid/modulos/chimera/test/estimations/

