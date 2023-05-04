Compiling

To compile the sample programs to run on the host system, invoke:
icc -o beamform beamform.c 
icc -o solution_check solution_check.c

The binary can then be run on bane via:

./beamform {16|32|64}

The parameter specifies which input file to load. The input file locations are hard-coded in the source. The beamforming code generates beamforming_output.bin in the current directory. You can confirm the output is correct by building and running:

./solution_check {16|32|64}

To compile binaries for the accelerator, invoke:

icc -o beamform.mic -mmic beamform.c 
icc -o solution_check.mic -mmic solution_check.c

Batch Job Submission

We have included a sample submission script, 570_pbs_submit.sh, for the batch system on the project web site. The script can be used to run a job interactively on the MIC accelerators on bane or submit a job to penguin for batch execution.
You configure which input file to use by setting the INPUT_SIZE variable in the script. For interactive jobs, you can set the USE_LOCAL_MIC_NUMBER variable to select which accelerator [0-6] to use. Note that there is no check performed to see if anyone else is using the same accelerator. Since the output file names are hard-coded, two jobs that run concurrently on the same accelerator will overwrite one another's output.

To run a local job:

./570_pbs_submit.sh

On penguin, a free accelerator is selected automatically by PBS. C stdout is redirected to a file in your home directory on bane based on the job id assigned by pbs. To submit a job, issue the command:

qsub 570_pbs_submit.sh This will submit a job to the penguin queue. You can see all your queued and running jobs with: qstat See PBS documentation for more information on how to manage queued jobs.
