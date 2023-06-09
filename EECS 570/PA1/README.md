# Accelerating Ultrasound Beamforming on the Xeon Phi

## Programming Assignment 1

3D ultrasound is a growing area in medical imaging, but due to the high computation requirements, high frame rates and large imaging apertures are difficult to achieve without large cluster systems or specialized architectures. The computation itself is inherently simple but requires massive parallelism and optimized memory accesses to complete efficiently. The goal of this project is to explore how to map ultrasound processing to the Intel Xeon Phi accelerator to drastically improve performance over a sequential baseline.

The main aim of the assignment is to ensure all students in EECS 570 have some familiarity with parallel programming using pthreads and/or the SIMD units available on the Xeon Phi.

## Programming Task

We have supplied you a sample program that performs delay-and-sum beamforming given pre-processed receive channel data from an array of ultrasound transducers. The program we have provided is sequential. Your task is to accelerate this program by parallelizing the computation on the Xeon Phi.
Along with the sample program, we have supplied three input files, beamforming_input_{16,32,64}.bin. These input files are preloaded on bane and all the Xeon Phi accelerators. These files contain transducer geometry, ultrasound image geometry, and pre-processed receive channel data for three different image resolutions (number of scanlines in the lateral image dimensions). The total amount of computation scales approximately quadratically in the number of scanlines, so the three inputs allow you to scale the runtime of the program. You should use the smallest input (16) for development and testing and then measure the final speedup of your solution on the largest input (64). You will be graded only on your performance on the largest input.

The supplied example program initializes various data structures, allocates memory, and then loads the input data from a file. Because transferring files to the Xeon Phi accelerators is rather complicated, we have pre-loaded the three inputs and correct outputs on each of the Xeon Phi. The paths to these pre-loaded files are hard-coded in the source code; you select among the three inputs by specifying 16, 32, or 64 as a paramter to the binary.

Once the geometry and data is loaded, the computation proceeds in two steps. The first loop nest computes the distance from each transmitting transducer to each focal point in the image geometry, using Euclidean distance. The second loop nest calculates the distance from the focal point to each receiving transducer, sums the two distances, and then determines the index within the receive data that is nearest to the corresponding round trip time. This receive data element is then read from the rx_data array and added to the appropriate focal point in the image array.

The final image is then written to beamforming_output.bin. The output file can be compared against reference outputs from MATLAB using the solution_check program supplied along with the assignment, which checks the output file in the current directory (or the most recently generated output on a Xeon Phi) against a reference output.

For the 64-scanline input, the baseline runtime of the computation phase of the unmodified sequential code we provided on a single Xeon Phi accelerator is about 111.5 seconds. We will use this time as a baseline against which we measure your speedup. We will run your final submission at least three times and base your speedup on the median runtime.

## Infrastructure

Intel has donated 14 Xeon Phi accelerators for use by this course. 7 accelerators each are installed on bane.eecs.umich.edu and penguin.eecs.umich.edu.
There are far more students in EECS 570 than Xeon Phi accelerators. To facilitate shared access and ensure it is possible for students to have exclusive access to a Xeon Phi to measure performance, we have designated half of the accelerators for interactive development and debugging, and half for running batch jobs with exclusive access to an accelerator.

You have all been granted interactive login access and a local home directories on bane.eecs.umich.edu. This system has all Intel developer tools for Xeon Phi installed. You may use it for development and interactive debugging, using the 32 logical cores on the host system or any of the 7 Xeon Phi accelerators. Note, however, that there is no access control or reservation system for the cores and accelerators - anyone can run any job, anywhere, at any time. Hence, you cannot reliably measure performance on this system - your job may be time-sharing with someone else's on the same cores/accelerators.

## Compiling

To compile the sample programs to run on the host system, invoke:
```bash
icc -o beamform beamform.c 
icc -o solution_check solution_check.c
```
The binary can then be run on bane via:
```bash
./beamform {16|32|64}
```
The parameter specifies which input file to load. The input file locations are hard-coded in the source. The beamforming code generates beamforming_output.bin in the current directory. You can confirm the output is correct by building and running:
```bash
./solution_check {16|32|64}
```
To compile binaries for the accelerator, invoke:
```bash
icc -o beamform.mic -mmic beamform.c 
icc -o solution_check.mic -mmic solution_check.c
```
## Batch Job Submission

We have included a sample submission script, 570_pbs_submit.sh, for the batch system on the project web site. The script can be used to run a job interactively on the MIC accelerators on bane or submit a job to penguin for batch execution.
You configure which input file to use by setting the INPUT_SIZE variable in the script. For interactive jobs, you can set the USE_LOCAL_MIC_NUMBER variable to select which accelerator [0-6] to use. Note that there is no check performed to see if anyone else is using the same accelerator. Since the output file names are hard-coded, two jobs that run concurrently on the same accelerator will overwrite one another's output.

To run a local job:
```bash
./570_pbs_submit.sh
```
## PThreads

Pthreads POSIX threads or Pthreads is a library implementation of a standardized C threads API that enables shared memory programming. In particular, the API provides two major functionalities -
Thread Management: Functions for creating, detaching, joining threads etc...
Synchronization: Mutexes, Conditional variables etc.
For more information on the Pthreads, check this tutorial from Lawrence Livermore National Labs.
