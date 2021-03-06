
#include <debugger.h>
#include<functions.h>

using namespace std;


// Global Variables.
uint64_cu pl_end_number = 100;
int number_of_gpus = 1;

PrimeHeader pheader;
GpuHandler gpu_data;
const char* PRIME_FILENAME = "diskprime.txt";
//long long int end_val = 1000000;




// ********************** KERNEL DEFINITION **********************

__global__ void prime_generator(int* d_input_list, uint64_cu* d_prime_list, uint64_cu* d_startPrimelist,uint64_cu* d_total_inputsize,uint64_cu* d_number_of_primes)
{

    uint64_cu tid = (blockIdx.x*blockDim.x) + threadIdx.x;

    //uint64_cu primes= d_prime_list[tid];
    /*if(tid< d_number_of_primes[0])
      printf("%d ---->  %llu\n",tid,primes);*/

    //printf("THE NUMBER OF PRIMES ARE: %llu\n",*d_number_of_primes); 
    if (tid < *d_number_of_primes) {
        //printf("Kaustubh\n");
        uint64_cu primes=d_prime_list[tid];
        for(uint64_cu i=0;i<d_total_inputsize[0];i++) { // Added less than eual to here.
            uint64_cu bucket= i/(WORD);
            int setbit= i%(WORD);
            uint64_cu number=d_startPrimelist[0]+i;
            //printf("THE NUMBER %llu IS BEING DIVIDED BY %llu\n",number,primes);
            if(number%primes==0) {
                //printf("%llu is divisible by %llu \n", number,primes);
                // THIS WAS WRONG  : d_input_list[bucket]=d_input_list[bucket]| 1U<<setbit;
                if(0 == (d_input_list[bucket] & 1U<<setbit)){ // testbit 
                    atomicOr(&d_input_list[bucket],1U<<setbit); // setbit
                }
            }
        }
    } 
}



// ********************** PTHREAD ITERATION **********************

void *one_iteration(void *tid) {
    long gpu_id = (long) tid; // Dont use tid, Use gpu_id instead
    // Select the device:
    gpuErrchk( cudaSetDevice(gpu_id) );

    if (DEBUG >= 1) {
        cout << "Launched GPU Handler: " << gpu_id << endl;
    }

    cudaEvent_t start_kernel; 
    cudaEvent_t stop_kernel;
    float time;
    gpuErrchk( cudaEventCreate (&start_kernel) );
    gpuErrchk( cudaEventCreate (&stop_kernel) );

    // cudaStream_t stream[gpu_data.gpus];
    // for (int i=0;i<gpu_data.gpus;i++) {
    //     stream[i] = i;
    // }




    // Saurin's Code
    gpu_data.IL_start = 100000000 +1;
    gpu_data.IL_end = 1000000000;

    //gpu_data.IL_start = pl_end_number +1;
    //gpu_data.IL_end = pl_end_number* pl_end_number;


    gpuErrchk( cudaEventRecord(start_kernel,0));

    //return (void*) kernelLauncher(gpu_id);
    ThreadRetValue* trv = kernelLauncher(gpu_id);
    cout<< ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PRINTING trv "<< endl;
    //printList(trv->primelist,trv->length);
    cout << "trv address " << trv << endl;


    gpuErrchk( cudaEventRecord(stop_kernel,0) );
    gpuErrchk( cudaEventSynchronize(stop_kernel));
    gpuErrchk( cudaEventElapsedTime(&time, start_kernel, stop_kernel));
    green_start();
    printf("GPU %ld Time: %.2f ms\n", gpu_id, time);
    color_reset();
    return (void*) trv;
}




// ********************** MAIN FUNCTION **********************

int main(int argc, char *argv[]) { 

    start_info(); // Complete

    number_of_gpus = find_number_of_gpus(); // Complete
    number_of_gpus = pow(2,int(log(number_of_gpus)/log(2)));
    //number_of_gpus = 1; // TODO REMOVE THIS LINE!!!
    gpu_data.gpus = number_of_gpus;

    // Accepting input from Console
    switch (argc) { // For getting input from console
        case 6:
            //long input_5;
            //input_5 = atol(argv[5]); //Fifth Input

        case 5:
            //long input_4;
            //input_4 = atol(argv[4]); //Fourth Input

        case 4:
            //long input_3;
            //input_3 = atol(argv[3]); // Third Input

        case 3:
            long input_2;
            input_2 = atol(argv[2]); // Second Input
            number_of_gpus = (int)input_2; // Number of GPUs on the NODE.
            // Over-ride with input value.
        case 2:
            long input_1;
            input_1 = atol(argv[1]); // First input
            pl_end_number = (uint64_cu)input_1;

            break;
        case 1:
            // Keep this empty
            break;
        default:
            red_start();
            cout << "FATAL ERROR: Wrong Number of Inputs" << endl; // If incorrect number of inputs are used.
            color_reset();
            return 1;
    }

    if (number_of_gpus != find_number_of_gpus()) {
        //cyan_start();
        cout << "INFO: Running on " << number_of_gpus << " GPUs out of " << find_number_of_gpus() << " GPUs." << endl;
        //color_reset();
    }

    pheader = readPrimes();

    if(pheader.length == 0){
        cout << " FILE HAD NO PRIMES , SO CALUCLATING on CPU first iteration" << endl;
        pheader = calculate_primes_on_cpu(pheader,pl_end_number);
    }else{
        cout << pheader.length <<" primes were read from the file" << endl;
        pl_end_number = pheader.lastMaxNo ;
    }

    cout << "pheader.length: " << pheader.length << endl;

    cout << endl <<"pthread launch starting"<< endl;

    //    while(end_reached) {

    //  *************** PTHREADS LAUNCH *******************


    pthread_t *thread = new pthread_t [number_of_gpus];
    int *thread_error = new int [number_of_gpus];
    ThreadRetValue** trvs = new ThreadRetValue*[number_of_gpus];

    for (long i = 0; i < number_of_gpus; i++) {
        thread_error[i] = pthread_create(&thread[i], NULL, one_iteration, (void *) i);
        if (thread_error[i] && WARNINGS) {
            yellow_start();
            cout << "Warning: Thread " << i << " failed to launch" << endl;
            cout << "GPU: " << i << " is being mishandled." << endl;
            color_reset();
        }
    }
    cout << "number_of_gpus -->>>> " << number_of_gpus<<endl;
    void* ret ;
    for (long i = 0; i < number_of_gpus; i++) {
        thread_error[i] = pthread_join(thread[i], &ret);
        trvs[i] = (ThreadRetValue*) ret;
    }

    // FIRST find total new primes from each thread
    uint64_cu newPrimesFromThreads = 0 ;
    for (long i = 0; i < number_of_gpus; i++) {
        newPrimesFromThreads += trvs[i]->length;
    }

    uint64_cu thisIterationPrimes = newPrimesFromThreads;
    newPrimesFromThreads += pheader.length;

    cout << endl << "all newPrimesFromThreads " << newPrimesFromThreads << endl;
    cout<<endl<<"this is before iteration combined"<<endl;
    //printList(pheader.primelist,pheader.length);

    // now do realloc
    //uint64_cu previousIterationPrimes = pheader.length;
    uint64_cu* allPrimes = (uint64_cu*) realloc(pheader.primelist,newPrimesFromThreads*sizeof(uint64_cu));
    //uint64_cu* allPrimes = (uint64_cu*) malloc (pheader.primelist,newPrimesFromThreads);
    uint64_cu* cpyPointer = allPrimes + pheader.length;

    // combine results
    uint64_cu prevLength = 0; 
    for (long i = 0; i < number_of_gpus; i++) {
        uint64_cu threadListLength = trvs[i] -> length;
        uint64_cu threadListBytes = threadListLength * sizeof(uint64_cu);
        memcpy(cpyPointer + prevLength , trvs[i]->primelist, threadListBytes);
        prevLength = threadListLength; 
    }

    pheader.primelist = allPrimes;
    pheader.length = newPrimesFromThreads;
    pheader.lastMaxNo = gpu_data.IL_end; 
    cout<<endl<< "this is after memcpy"<<endl;
    //printList(pheader.primelist,pheader.length);


    // write this iterations combined results
    cout << "thisIterationPrimes: "<< thisIterationPrimes << endl;
    //printList(cpyPointer, thisIterationPrimes);
    //writePrimes(pheader.primelist,pheader.length,pheader.lastMaxNo);
    writePrimes(cpyPointer, thisIterationPrimes, pheader.lastMaxNo);

    // output_combine();

    // INLINE
    //iteration_info();

    //}


    // CODE

    // INLINE
    //end_info();

    return 0;
}

