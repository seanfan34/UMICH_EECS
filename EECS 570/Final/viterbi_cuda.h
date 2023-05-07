#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <iostream>
#include <iomanip>
//#include <string>
#include <vector>
#include <tuple>
#include <cmath>
#include <queue>
#include <stack>
//#include <string_view>
#include <functional>
#include <cassert>
#include <cstring>
#include <cuda_runtime.h>

#define SIZE 256
#define read_length 4
#define haplotype_length 5


// #define blocks 32
__global__ void align_kernel(int* d_scores, int* d_weight_arr, int* align_scores, int* insert_scores, int* delete_scores, int N, int M, int m2m, int i2m, int i2i, int m2i, int idx) {
    
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    // int j = blockDim.x * gridDim.x;
    // int j = 0;

    // int temp_align_score[] = {};
    // int temp_insert_score[] = {};
    // int temp_delete_score[] = {};
    // int temp_align_score[read_length][haplotype_length];
    // int temp_insert_score[read_length][haplotype_length];
    // int temp_delete_score[read_length][haplotype_length];
    // printf("m2m = %d\n", m2m);
    int temp_align_score;
    int temp_insert_score;
    int temp_delete_score;


    int temp_align_score_1;
    int temp_insert_score_1;
    int temp_align_score_2;
    int temp_delete_score_2;
    int temp_align_score_3;
    int temp_insert_score_3;

    // if(j>1170)
    // {
    //     // printf("j = %d\n", j);
    // }

    // if(i>196)
    // {
    //     // printf("i = %d\n", i);
    // }

    // printf("N = %d\n", N);
    // printf("M = %d\n", M);

    // int* m2m_ptr = &m2m;
    // int* i2m_ptr = &i2m;

    // int* zero_ptr = &zero;
    // printf("m2m = %\n");

// printf("m2m = %d\n", m2m);
    // int index = (i+1)*(M+1)+(j+1);

    // if (i < N && j < M) {
        // temp_align_score = align_scores[i*M+j] + d_weight_arr[i*M+j] + m2m;
        // temp_insert_score = insert_scores[i*M+j] + d_weight_arr[i*M+j] + i2m;
        // temp_delete_score = delete_scores[i*M+j] + d_weight_arr[i*M+j] + i2m;
    // printf("m2m = %d\n", align_scores [0]);
    // printf("d_weight_arr = %d\n", *(d_weight_arr + (i * 1) + j));
    
    // for (int a = 0; a < N; a++) {
    //     for (int b = 0; b < M; b++) {
    //         if (a==i && b==j){
            // printf("i = %d\t", i);
            // printf("j = %d\t", j);
            // printf("weight_scores = %d\n", *(d_weight_arr + (i * M) + j));
    //         }
    //     }
    // }

    // if (i==0 && j==289){
    //     printf("weight_scores = %d\n", *(d_weight_arr + (i * M) + j));
    // }


    //  if (i==0 && j==0){

    //     printf("align_scores = %d\n", *(align_scores + (i * M) + j));

    //  }

    // printf("i = %d\n", i);
    for (int j = 0; j < M; j++){

    if (i < N && j < M) {

        // if(*(align_scores + (i * M) + j) !=0){
        if ((i+j)==idx){

            // printf("j = %d\n", j);
            // printf("i = %d\t", i);
            // printf("j = %d\t", j);
            // temp_align_score = *(align_scores + (i * M) + j) + *(d_weight_arr + (i * M) + j) + m2m;
            // temp_insert_score = *(insert_scores + (i * M) + j) + *(d_weight_arr + (i * M) + j) + i2m;
            // temp_delete_score = *(delete_scores + (i * M) + j) + *(d_weight_arr + (i * M) + j) + i2m;
            
            temp_align_score = align_scores[i*M+j] + d_weight_arr[i*M+j] + m2m;
            temp_insert_score = insert_scores[i*M+j] + d_weight_arr[i*M+j] + i2m;
            temp_delete_score = delete_scores[i*M+j] + d_weight_arr[i*M+j] + i2m;
            
            // printf("d_weight_arr = %d\n", d_weight_arr[i*M+j]);
        
       

            

    // printf("m2m = %d\n", temp_align_score);
    // printf("m2m = %\n");


    
        
    //     if (temp_delete_score > temp_align_score && temp_delete_score > temp_insert_score)
    //         align_scores[(i+1)*(M+1)+(j+1)] = temp_delete_score;
    //     else if (temp_insert_score > temp_align_score)
    //         align_scores[(i+1)*(M+1)+(j+1)] = temp_insert_score;
    //     else
    //         align_scores[(i+1)*(M+1)+(j+1)] = temp_align_score;
    // }
    
        
    //    if (i < N && j < M) {
        
        if (temp_delete_score > temp_align_score && temp_delete_score > temp_insert_score)
            align_scores[(i+1)*(M+1)+(j+1)] = temp_delete_score;
        else if (temp_insert_score > temp_align_score)
            align_scores[(i+1)*(M+1)+(j+1)] = temp_insert_score;
        else
            align_scores[(i+1)*(M+1)+(j+1)] = temp_align_score;
        // }
    
    
        //dan
        
        temp_align_score_1  = align_scores[i*M+j+1] + m2i;
        temp_insert_score_1 = insert_scores[i*M+j+1] + i2i;

        // temp_align_score_1  = *(align_scores + (i * M) + (j+1)) + m2i;
        // temp_insert_score_1 = *(insert_scores + (i * M) + (j+1)) + i2i;

            // insert_scores[i+1][j+1] = log10sumpow10(temp_align_score, temp_insert_score);
        // if (i < N && j < M) {
        //     if (temp_insert_score_1 > temp_align_score_1)
        //         insert_scores[(i+1)*M+j+1] = temp_insert_score_1;
        //     else
        //         insert_scores[(i+1)*M+j+1] = temp_align_score_1;
        // }


        if (temp_insert_score_1 > temp_align_score_1)
            insert_scores[(i+1)*M + (j+1)] = temp_insert_score_1;
        else
            insert_scores[(i+1)*M + (j+1)] = temp_align_score_1;

            //delete_cuda(&align_scores[0][0], &delete_scores[0][0], m2i, i2i, read_length, haplotype_length);
        
            //delete scores operation
            temp_align_score_2  = align_scores[(i+1)*M+j]  + m2i;
            temp_delete_score_2 = delete_scores[(i+1)*M+j] + i2i;
            // temp_align_score_2  = *(align_scores + ((i+1) * M) + j)  + m2i;
            // temp_delete_score_2 = *(delete_scores + ((i+1) * M) + j) + i2i;

            // delete_scores[i+1][j+1] = log10sumpow10(temp_align_score, temp_delete_score);
        // if (i < N && j < M) {
        //     if (temp_delete_score_2 > temp_align_score_2)
        //         delete_scores[(i+1)*M+j+1] = temp_delete_score_2;
        //     else
        //         delete_scores[(i+1)*M+j+1] = temp_align_score_2;
        // }

            if (temp_delete_score_2 > temp_align_score_2)
                delete_scores[(i+1)*M + (j+1)] = temp_delete_score_2;
            else
                delete_scores[(i+1)*M + (j+1)] = temp_align_score_2;

            // scores operation
            temp_align_score_3  = align_scores[(i+1)*M+j+1];
            temp_insert_score_3 = insert_scores[(i+1)*M+j+1];
            // temp_align_score_3  = *(align_scores + ((i+1) * M) + (j+1));
            // temp_insert_score_3 = *(insert_scores + ((i+1) * M) + (j+1));


            // scores[i][j] = log10sumpow10(temp_align_score, temp_insert_score);
        // if (i < N && j < M) {
        //     if (temp_insert_score_3 > temp_align_score_3)
        //         d_scores[i*M+j] = temp_insert_score_3;
        //     else
        //         d_scores[i*M+j] = temp_align_score_3;
        // }
            if (temp_insert_score_3 > temp_align_score_3)
                d_scores[i*M+j] = temp_insert_score_3;
            else
                d_scores[i*M+j] = temp_align_score_3;
            
            // printf("d_scores = %d\n", d_scores[i*M+j]);
    // }
    
        }
    }
    }

        // printf("d_scores = %d\n", d_scores[i*M+j]);

            // if (i == read_length-1) {
            //     if (scores[i*(M+1)+j] > highest_score)
            //         highest_score = scores[i*(M+1)+j];
            // }
            //dan
            
        // }
    // }
    
    // printf("score = %d\n", d_scores[0]);
    
    
}    
    

        



/*
void align_cuda(int* scores, int* weight_arr, int* align_scores, int* insert_scores, int* delete_scores, int N, int M, int weight, int m2m, int i2m, int i2i, int m2i) {
    //int *d_scores, *d_weight_arr, *d_align_scores, *d_insert_scores, *d_delete_scores;
    /*cudaMalloc(&d_align_scores, (N+1)*(M+1)*sizeof(int));
    cudaMalloc(&d_insert_scores, (N+1)*(M+1)*sizeof(int));
    cudaMalloc(&d_delete_scores, (N+1)*(M+1)*sizeof(int));

    cudaMemcpy(d_align_scores, align_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_insert_scores, insert_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_delete_scores, delete_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);

    // cudaMalloc((void**)&temp_align_score, N*M);
    // cudaMalloc((void**)&temp_insert_score, N*M);
    // cudaMalloc((void**)&temp_delete_score, N*M);
    int d_scores[N][M];
    int d_weight_arr[N][M];
    int d_align_scores[N][M];
    int d_insert_scores[N][M];
    int d_delete_scores[N][M];



    cudaMalloc((void**)&d_scores, (N+1)*(M+1));
    cudaMalloc((void**)&d_weight_arr, (N+1)*(M+1));
    cudaMalloc((void**)&d_align_scores, (N+1)*(M+1));
    cudaMalloc((void**)&d_insert_scores, (N+1)*(M+1));
    cudaMalloc((void**)&d_delete_scores, (N+1)*(M+1));

    cudaMemcpy(d_scores, scores, (N+1)*(M+1), cudaMemcpyHostToDevice);
    cudaMemcpy(d_weight_arr, weight_arr, (N+1)*(M+1), cudaMemcpyHostToDevice);
    cudaMemcpy(d_align_scores, align_scores, (N+1)*(M+1), cudaMemcpyHostToDevice);
    cudaMemcpy(d_insert_scores, insert_scores, (N+1)*(M+1), cudaMemcpyHostToDevice);
    cudaMemcpy(d_delete_scores, delete_scores, (N+1)*(M+1), cudaMemcpyHostToDevice);


    dim3 dimBlock(16, 16);
    dim3 dimGrid((16+dimBlock.x-1)/dimBlock.x, (16+dimBlock.y-1)/dimBlock.y);

    align_kernel<<<dimGrid, dimBlock>>>(d_scores, d_weight_arr, d_align_scores, d_insert_scores, d_delete_scores, N, M, m2m, i2m, i2i, m2i);
    cudaDeviceSynchronize();

    cudaMemcpy(scores, d_scores, (N+1)*(M+1), cudaMemcpyDeviceToHost);
    cudaMemcpy(weight_arr, d_weight_arr, (N+1)*(M+1), cudaMemcpyDeviceToHost);
    cudaMemcpy(align_scores, d_align_scores, (N+1)*(M+1), cudaMemcpyDeviceToHost);
    cudaMemcpy(insert_scores, d_insert_scores, (N+1)*(M+1), cudaMemcpyDeviceToHost);
    cudaMemcpy(delete_scores, d_delete_scores, (N+1)*(M+1), cudaMemcpyDeviceToHost);

    // cudaFree(temp_align_score);
    // cudaFree(temp_insert_score);
    // cudaFree(temp_delete_score);
    cudaFree(d_scores);
    cudaFree(d_weight_arr);
    cudaFree(d_align_scores);
    cudaFree(d_insert_scores);
    cudaFree(d_delete_scores);
 
}
*/
/*
global void insert_kernel(int* align_scores, int* insert_scores,
                                     int m2i, int i2i, int N, int M) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    if (i < N && j < M) {
    int temp_align_score = align_scores[(i * M) + (j + 1)] + m2i;
    int temp_insert_score = insert_scores[(i * M) + (j + 1)] + i2i;

    if (temp_insert_score > temp_align_score) {
        insert_scores[((i + 1) * M) + (j + 1)] = temp_insert_score;
    }
    else {
        insert_scores[((i + 1) * M) + (j + 1)] = temp_align_score;
    }
    }
}

void insert_cuda(int* align_scores, int* insert_scores,
                           int m2i, int i2i, int N, int M) {
    int *d_align_scores, *d_insert_scores;
    cudaMalloc(&d_align_scores, (N+1)*(M+1)*sizeof(int));
    cudaMalloc(&d_insert_scores, (N+1)*(M+1)*sizeof(int));

    cudaMemcpy(d_align_scores, align_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_insert_scores, insert_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    
    dim3 block_size(16, 16);
    dim3 num_blocks((N + block_size.x - 1) / block_size.x,
                    (M + block_size.y - 1) / block_size.y);

    insert_kernel<<<num_blocks, block_size>>>(align_scores, insert_scores, m2i, i2i, N, M);
    cudaDeviceSynchronize();

    cudaMemcpy(insert_scores, d_insert_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(d_align_scores);
    cudaFree(d_insert_scores);
}

global void delete_kernel(int* align_scores, int* delete_scores, int m2i, int i2i, int N, int M) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    if (i < N && j < M) {
    int temp_align_score  = align_scores[(i+1)*M + j]  + m2i;
    int temp_delete_score = delete_scores[(i+1)*M + j] + i2i;
    if (temp_delete_score > temp_align_score) {
        delete_scores[(i+1)*M+(j+1)] = temp_delete_score;
    } else {
        delete_scores[(i+1)*M +(j+1)] = temp_align_score;
    }
    }
}

void delete_cuda(int* align_scores, int* delete_scores, int m2i, int i2i, int N, int M) {

    int *d_align_scores, *d_delete_scores;
    cudaMalloc(&d_align_scores, (N+1)*(M+1)*sizeof(int));
    cudaMalloc(&d_delete_scores, (N+1)*(M+1)*sizeof(int));

    cudaMemcpy(d_align_scores, align_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_delete_scores, delete_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyHostToDevice);
    
    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((N + threadsPerBlock.x - 1) / threadsPerBlock.x,
                   (M + threadsPerBlock.y - 1) / threadsPerBlock.y);
    delete_kernel<<<numBlocks, threadsPerBlock>>>(align_scores, delete_scores, m2i, i2i, N, M);
    cudaDeviceSynchronize();

    cudaMemcpy(delete_scores, d_delete_scores, (N+1)*(M+1)*sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(d_align_scores);
    cudaFree(d_delete_scores);
}*/

void viterbi_decoding(
    char *haplotype, char *read, char *read_BQ,
    int bias_score,
    int m2m, int i2m, int m2i, int i2i,
    int BQ0_match, int BQ0_mismatch, 
    int BQ1_match, int BQ1_mismatch, 
    int BQ2_match, int BQ2_mismatch, 
    int BQ3_match, int BQ3_mismatch,
    int *log_likelihoods, int log_likelihoods_idx) {

    // std::cout<<BQ0_match<<"\n"<<BQ0_mismatch<<"\n"<<BQ1_match<<"\n"<<BQ1_mismatch<<"\n"<<BQ2_match<<"\n"<<BQ2_mismatch<<"\n"<<BQ3_match<<"\n"<<BQ3_mismatch<<"\n";


    // std::cout<<"read "<<read[0]<<"\n";
    //int read_length = strlen(read);
    //int haplotype_length = strlen(haplotype);

    // std::cout<<read_length;
    // std::cout<<haplotype_length;

    // int align_scores[read_length][haplotype_length]  = {};
    // int insert_scores[read_length][haplotype_length] = {};
    // int delete_scores[read_length][haplotype_length] = {};

    // int align_scores[151+1][360+1]  = {};
    // int insert_scores[151+1][360+1] = {};
    // int delete_scores[151+1][360+1] = {};
    
    // int **align_scores = new int*[read_length+1];
    // int **insert_scores = new int*[read_length+1];
    // int **delete_scores = new int*[read_length+1];

    // int **align_scores = new int*[read_length+1];
    // int **insert_scores = new int*[read_length+1];
    // int **delete_scores = new int*[read_length+1];
    // int **weight_arr = new int*[read_length+1];


    // for (int i = 0; i <= read_length; i++) {
    //     align_scores[i] = new int[haplotype_length+1];
    //     insert_scores[i] = new int[haplotype_length+1];
    //     delete_scores[i] = new int[haplotype_length+1];
    //     weight_arr[i] = new int[haplotype_length+1];
    // }
    int numblock = 16;
    int blocksize = 16;

    // int **align_scores = new int*[read_length+1];
    // int **insert_scores = new int*[read_length+1];
    // int **delete_scores = new int*[read_length+1];
    // int **weight_arr = new int*[read_length+1];
    // int **scores = new  int*[read_length];
    // int* scores = new int[read_length * haplotype_length];
    int* align_scores;
    int* insert_scores;
    int* delete_scores;
    int* weight_arr;
    int* scores;

    align_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    insert_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    delete_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    weight_arr = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    scores = (int*)malloc(read_length*haplotype_length* numblock*blocksize);

    // int *align_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    // int *insert_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    // int *delete_scores = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    // int *weight_arr = (int*)malloc((read_length+1)*(haplotype_length+1)* numblock*blocksize);
    // int *scores = (int*)malloc(read_length*haplotype_length* numblock*blocksize);

    // int* align_scores = new int[(read_length+1) * (haplotype_length+1)];   // Device pointer to actual data
    // int* insert_scores = new int[(read_length+1) * (haplotype_length+1)];
    // int* delete_scores = new int[(read_length+1) * (haplotype_length+1)];
    // int* weight_arr = new int[(read_length+1) * (haplotype_length+1)];
    // int* scores = new int[read_length * haplotype_length];

    // for (int i = 0; i <= read_length; i++) {
    //     align_scores[i] = new int[haplotype_length+1];
    //     insert_scores[i] = new int[haplotype_length+1];
    //     delete_scores[i] = new int[haplotype_length+1];
    //     weight_arr[i] = new int[haplotype_length+1];
        // scores[i] = new int[haplotype_length];
    // }
    // for (int i = 0; i < read_length; i++) {
    //     scores[i] = new int[haplotype_length];
    // }

    // printf("Testing3\n");
    // int count = 0;

    // for (int i = 1; i < read_length + 1; ++i) {
    //     for (int j = 0; j < haplotype_length + 1; ++j) {
    //         align_scores[i*haplotype_length+j] = 1;
    //         // std::cout<<"align"<<align_scores[i*haplotype_length+j]<<"\n";
    //         // count +=1;
    //     }
    // }
    // for (int i = 1; i < read_length + 1; ++i) {
    //     for (int j = 0; j < haplotype_length + 1; ++j) {
    //         insert_scores[i*haplotype_length+j] = 2;
    //         // count +=1;
    //     }
    // }
    // for (int i = 1; i < read_length + 1; ++i) {
    //     for (int j = 0; j < haplotype_length + 1; ++j) {
    //         delete_scores[i*haplotype_length+j] = 3;
    //         // count +=1;
    //     }
    // }
    // for (int i = 1; i < read_length + 1; ++i) {
    //     for (int j = 0; j < haplotype_length + 1; ++j) {
    //         weight_arr[i*haplotype_length+j] = 4;
    //         // count +=1;
    //     }
    // }

// for (int i = 1; i < read_length + 1; ++i) {
//     for (int j = 0; j < haplotype_length + 1; ++j) {
//         std::cout<<"align "<<align_scores[i][j]<<"\n";
//     }
// }
    for (int j = 0; j < haplotype_length + 1; ++j) {
        align_scores[j] = -pow(2, 15);
        insert_scores[j] = -pow(2, 15);
        delete_scores[j] = bias_score;
    }
    for (int i = 1; i < read_length + 1; ++i) {
        align_scores[i*haplotype_length] = -pow(2, 15);
        insert_scores[i*haplotype_length] = -pow(2, 15);
        delete_scores[i*haplotype_length] = -pow(2, 15);
    }


    // printf("Testing4\n");
    // int scores[196][1170] = {0};    // Need to change size when data change
    //int **scores = new int*[read_length];
    // int** scores[read_length][haplotype_length];

    // for(int i = 0; i < read_length; i++){
    //     scores[i] = new int[haplotype_length];
    // }

    int weight = 0;
    // int temp_align_score = 0;
    // int temp_insert_score = 0;
    // int temp_delete_score = 0;
    int highest_score = -pow(2, 15);


    for (int i=0; i<read_length; ++i) {
        for (int j=0; j<haplotype_length; ++j) {
            // align scores operation
            char read_base = read[i];
            char haplotype_base = haplotype[j];
            if (read_BQ[i]=='0') {
                if (read_base == haplotype_base)
                    weight = BQ0_match;
                else
                    weight = BQ0_mismatch;
            } else if (read_BQ[i]=='1') {
                if (read_base == haplotype_base)
                    weight = BQ1_match;
                else
                    weight = BQ1_mismatch;
            } else if (read_BQ[i]=='2') {
                if (read_base == haplotype_base)
                    weight = BQ2_match;
                else
                    weight = BQ2_mismatch;
            } else if (read_BQ[i]=='3') {
                if (read_base == haplotype_base)
                    weight = BQ3_match;
                else
                    weight = BQ3_mismatch;
            }
            weight_arr[i*haplotype_length + j] = weight;
            // std::cout<<weight_arr[i][j]<<"\n";
        }
    }

// std::cout<<weight_arr[1][1];

    // int d_scores[read_length][haplotype_length];
    // int d_weight_arr[read_length][haplotype_length];
    // int d_align_scores[read_length][haplotype_length];
    // int d_insert_scores[read_length][haplotype_length];
    // int d_delete_scores[read_length][haplotype_length];

   
    // int* align_scores_data = (int*)malloc((read_length+1)*(haplotype_length+1));   // Device pointer to actual data
    // int* insert_scores_data = (int*)malloc((read_length+1)*(haplotype_length+1));
    // int* delete_scores_data = (int*)malloc((read_length+1)*(haplotype_length+1));
    // int* weight_arr_data = (int*)malloc((read_length+1)*(haplotype_length+1));
    // int* scores_data = (int*)malloc(read_length*haplotype_length);

    // int* scores_data = new int[(read_length+1) * (haplotype_length+1)];

    // int* align_scores_data = new int[(read_length+1) * (haplotype_length+1)];   // Device pointer to actual data
    // int* insert_scores_data = new int[(read_length+1) * (haplotype_length+1)];
    // int* delete_scores_data = new int[(read_length+1) * (haplotype_length+1)];
    // int* weight_arr_data = new int[(read_length+1) * (haplotype_length+1)];
    // int* scores_data = new int[read_length * haplotype_length];

    int* align_scores_data;
    int* insert_scores_data;
    int* delete_scores_data;
    int* weight_arr_data;
    int* scores_data;






// Allocate memory for array of pointers on the device
    // cudaMalloc((void**)&ppArray_a, haplotype_length * sizeof(int*));

    // for(int i=0; i<10; i++){
    //     cudaMalloc(&someHostArray[i], 100*sizeof(int)); /* Replace 100 with the dimension that u want */
    // }

    // cudaMemcpy(ppArray_a, someHostArray, 10*sizeof(int *), cudaMemcpyHostToDevice);

    // cudaMalloc((void**)&align_scores, (read_length+1) * (haplotype_length+1) * sizeof(int));
    // cudaMalloc((void**)&insert_scores,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    // cudaMalloc((void**)&delete_scores,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    // cudaMalloc((void**)&weight_arr,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    // cudaMalloc((void**)&scores, read_length * haplotype_length * sizeof(int));
    

    cudaMalloc((void**)&align_scores_data, (read_length+1) * (haplotype_length+1) * sizeof(int));
    cudaMalloc((void**)&insert_scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    cudaMalloc((void**)&delete_scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    cudaMalloc((void**)&weight_arr_data,  (read_length+1) * (haplotype_length+1) * sizeof(int));
    cudaMalloc((void**)&scores_data, read_length * haplotype_length * sizeof(int));
    // cudaMalloc((void**)&scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int*));

for(int idx=2; idx<(read_length+haplotype_length); idx++){

    cudaMemcpy(align_scores_data, align_scores,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(insert_scores_data, insert_scores,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(delete_scores_data, delete_scores,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(weight_arr_data, weight_arr,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(scores_data, scores, read_length * haplotype_length * sizeof(int), cudaMemcpyHostToDevice);
    // cudaMemcpy(scores_data, scores, read_length * haplotype_length * sizeof(int*), cudaMemcpyHostToDevice);
    // std::cout<<*(weight_arr_data+read_length+1)<<"\n";

    // cudaMemcpy(scores, scores_data, read_length * sizeof(int*), cudaMemcpyHostToDevice);



    // cudaMemcpy(scores_data, scores, read_length * sizeof(int*), cudaMemcpyHostToDevice);
    // cudaMemcpy(d_weight_arr, weight_arr, read_length*haplotype_length, cudaMemcpyHostToDevice);
    // cudaMemcpy(d_align_scores, align_scores, read_length*haplotype_length, cudaMemcpyHostToDevice);
    // cudaMemcpy(d_insert_scores, insert_scores, read_length*haplotype_length, cudaMemcpyHostToDevice);
    // cudaMemcpy(d_delete_scores, delete_scores, read_length*haplotype_length, cudaMemcpyHostToDevice);


    // dim3 dimBlock(16, 16);
    // dim3 dimGrid((16+dimBlock.x-1)/dimBlock.x, (16+dimBlock.y-1)/dimBlock.y);

    // int threadsPerBlock = 256;
    // int blocksPerGrid = ((read_length+1) * (haplotype_length+1) + threadsPerBlock - 1) / threadsPerBlock;
    // dim3 dimBlock(threadsPerBlock, 1);
    // dim3 dimGrid(5*blocksPerGrid, 1);
    // dim3 dimBlock(4, 4);
    // dim3 dimGrid(512, 512);
    // dim3 dimBlock(1024, 1024);
    // dim3 dimGrid(2, 2);
    // dim3 dimBlock(8, 8); // choose an appropriate block size
    // dim3 dimGrid(256, 32);


    // Calculate the number of blocks needed to cover the data sets
    // const int blocksPerGrid1 = (numElements1 + threadsPerBlock - 1) / threadsPerBlock;
    // const int blocksPerGrid2 = (numElements2 + threadsPerBlock - 1) / threadsPerBlock;
    // const int blocksPerGrid3 = (numElements3 + threadsPerBlock - 1) / threadsPerBlock;
    // const int blocksPerGrid4 = (numElements4 + threadsPerBlock - 1) / threadsPerBlock;
    // const int blocksPerGrid5 = (numElements5 + threadsPerBlock - 1) / threadsPerBlock;

    // Choose a suitable number of blocks per grid based on the total number of blocks needed
    // const int maxBlocksPerGrid = 65535;
    // const int blocksPerGrid = std::min(maxBlocksPerGrid, blocksPerGrid1 + blocksPerGrid2 + blocksPerGrid3 + blocksPerGrid4 + blocksPerGrid5);

    // Choose a suitable number of threads per dimension for the grid of thread blocks
    // const int threadsPerDimension = std::ceil(std::pow(threadsPerBlock, 1.0 / 3.0));

    // Calculate the dimensions of the grid of thread blocks
    // const int numBlocksPerDimension = std::ceil(std::pow(blocksPerGrid, 1.0 / 3.0));
    // const dim3 dimBlock(threadsPerDimension, threadsPerDimension, threadsPerDimension);
    // const dim3 dimGrid(numBlocksPerDimension, numBlocksPerDimension, numBlocksPerDimension);

    
    // std::cout<<"scana";
    align_kernel<<<numblock,blocksize>>>(scores_data, weight_arr_data, align_scores_data, insert_scores_data, delete_scores_data, read_length, haplotype_length, m2m, i2m, i2i, m2i, idx);
    cudaDeviceSynchronize();

    cudaMemcpy(align_scores, align_scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(insert_scores, insert_scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(delete_scores, delete_scores_data,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(weight_arr, weight_arr_data,  (read_length+1) * (haplotype_length+1) * sizeof(int), cudaMemcpyDeviceToHost);

    cudaMemcpy(scores, scores_data, read_length * haplotype_length * sizeof(int), cudaMemcpyDeviceToHost);
    
}


    // cudaFree(scores_data);
    // cudaFree(weight_arr_data);
    // cudaFree(align_scores_data);
    // cudaFree(insert_scores_data);
    // cudaFree(delete_scores_data);



    // std::cout<<"align"<<align_scores[1][1]<<"\n";
    // std::cout<<"score"<<scores[1]<<"\n";
    // cudaError_t err;
    // err = cudaGetLastError();
    // if (err!=cudaSuccess)
    // {
    //     printf("Error:%s\n", cudaGetErrorString(err));
    // }
    // std::cout<<"score"<<scores[1][1]<<"\n";
    // cudaMemcpy(scores, d_scores, read_length*haplotype_length, cudaMemcpyDeviceToHost);
    // cudaMemcpy(weight_arr, d_weight_arr, read_length*haplotype_length, cudaMemcpyDeviceToHost);
    // cudaMemcpy(align_scores, d_align_scores, read_length*haplotype_length, cudaMemcpyDeviceToHost);
    // cudaMemcpy(insert_scores, d_insert_scores, read_length*haplotype_length, cudaMemcpyDeviceToHost);
    // cudaMemcpy(delete_scores, d_delete_scores, read_length*haplotype_length, cudaMemcpyDeviceToHost);

    // cudaFree(temp_align_score);
    // cudaFree(temp_insert_score);
    // cudaFree(temp_delete_score);
    // cudaFree(d_scores);
    // cudaFree(d_weight_arr);
    // cudaFree(d_align_scores);
    // cudaFree(d_insert_scores);
    // cudaFree(d_delete_scores);




    // for (int j=0; j<300; ++j) {
    // std::cout<<"align ";
    // std::cout<<align_scores[5][1];
    // std::cout<<"\n";
    // }
    //align_cuda((int*)scores, (int*)weight_arr, (int*)align_scores, (int*)insert_scores, (int*)delete_scores, read_length, haplotype_length, weight, m2m, i2m, i2i, m2i);    
    // for (int j=0; j<300; ++j) {
    // std::cout<<"align_new ";
    // std::cout<<align_scores[5][j];
    // std::cout<<"\n";
    // }

            //align_cuda((int*)weight_arr, (int*)align_scores, (int*)insert_scores, (int*)delete_scores, read_length, haplotype_length, weight, m2m, i2m);
            
            //printf("Testing5\n");
            // std::cout<<i;
            // std::cout<<"\n";
            // std::cout<<j;
            // temp_align_score  = align_scores[i][j]  + weight + m2m;
            // temp_insert_score = insert_scores[i][j] + weight + i2m;
            // temp_delete_score = delete_scores[i][j] + weight + i2m;
            // // align_scores[i+1][j+1] = log10sumpow10(temp_align_score, temp_insert_score, temp_delete_score);
            // if (temp_delete_score > temp_align_score && temp_delete_score > temp_insert_score)
            //     align_scores[i+1][j+1] = temp_delete_score;
            // else if (temp_insert_score > temp_align_score)
            //     align_scores[i+1][j+1] = temp_insert_score;
            // else
            //     align_scores[i+1][j+1] = temp_align_score;
            
            //insert_cuda(&align_scores, &insert_scores, m2i, i2i, read_length, haplotype_length);
            // insert scores operation

    // std::cout<< weight_arr[1][1];


    for (int i=0; i<read_length; ++i) {
        for (int j=0; j<haplotype_length; ++j) {
            // temp_align_score  = align_scores[i][j+1]  + m2i;
            // temp_insert_score = insert_scores[i][j+1] + i2i;
            // // insert_scores[i+1][j+1] = log10sumpow10(temp_align_score, temp_insert_score);
            // if (temp_insert_score > temp_align_score)
            //     insert_scores[i+1][j+1] = temp_insert_score;
            // else
            //     insert_scores[i+1][j+1] = temp_align_score;
            // //delete_cuda(&align_scores[0][0], &delete_scores[0][0], m2i, i2i, read_length, haplotype_length);
            
            // //delete scores operation
            // temp_align_score  = align_scores[i+1][j]  + m2i;
            // temp_delete_score = delete_scores[i+1][j] + i2i;
            // // delete_scores[i+1][j+1] = log10sumpow10(temp_align_score, temp_delete_score);
            // if (temp_delete_score > temp_align_score)
            //     delete_scores[i+1][j+1] = temp_delete_score;
            // else
            //     delete_scores[i+1][j+1] = temp_align_score;

            // // scores operation
            // temp_align_score  = align_scores[i+1][j+1];
            // temp_insert_score = insert_scores[i+1][j+1];
            // temp_delete_score = delete_scores[i+1][j+1];
            // // scores[i][j] = log10sumpow10(temp_align_score, temp_insert_score);
            // if (temp_insert_score > temp_align_score)
            //     scores[i][j] = temp_insert_score;
            // else
            //     scores[i][j] = temp_align_score;
// std::cout<<scores[0];

            // if (i == read_length-1) {
            //     if (scores[i*haplotype_length + j] > highest_score)
            //         highest_score = scores[i*haplotype_length + j];
            // }
            if (i == read_length-1) {
                if (scores[i*haplotype_length + j] > highest_score)
                    highest_score = scores[i*haplotype_length + j];
            }





// std::cout<<weight_arr[i][j];
// std::cout<<"\n";
        //     if (i == read_length-1) {
        //         if (&scores[i*haplotype_length + j] > highest_score)
        //             highest_score = &scores[i*haplotype_length + j];
        //     }
        }
    } // end of dynamic programming


    // return highest_score;
    log_likelihoods[log_likelihoods_idx] = highest_score;

    // std::cout<<"log";
    // std::cout<<log_likelihoods[log_likelihoods_idx];
    // std::cout<<"\n";


    free(scores);
    free(weight_arr);
    free(align_scores);
    free(insert_scores);
    free(delete_scores);


    cudaFree(scores_data);
    cudaFree(weight_arr_data);
    cudaFree(align_scores_data);
    cudaFree(insert_scores_data);
    cudaFree(delete_scores_data);

    // delete[] align_scores_data;
    // delete[] insert_scores_data;
    // delete[] delete_scores_data;
    // delete[] weight_arr_data;
    // delete[] scores_data;
    // delete[] align_scores;
    // delete[] insert_scores;
    // delete[] delete_scores;
    // delete[] weight_arr;
    // delete[] scores;
 

    return;

}

#endif