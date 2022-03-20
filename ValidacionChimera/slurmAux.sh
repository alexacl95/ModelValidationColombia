#!/bin/bash


#SBATCH --job-name=Covid                  # Job name
#SBATCH --nodes=1              		  # Number of nodes
#SBATCH --ntasks=1                       # Number of tasks (processes)
#SBATCH --output=%x.%j.out                # Stdout (%j expands to jobId)
#SBATCH --error=%x.%j.err                 # Stderr (%j expands to jobId)
#SBATCH --time=3-00:00:00                # Walltime
#SBATCH --mail-type=ALL                   # Mail notification
#SBATCH --mail-user=acatano@eafit.edu.co  # User Email
#SBATCH --partition=learning	              # Partition



##### ENVIRONMENT CREATION #####
module load matlab/r2020a

##### JOB COMMANDS ####
matlab -nosplash -nodesktop < updateJson.m




