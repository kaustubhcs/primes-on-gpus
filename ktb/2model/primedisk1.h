#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

typedef unsigned long long int uint64_cu;
#define INTSIZE sizeof(uint64_cu)

const char* PRIME_FILENAME = "diskprime.txt";

typedef struct PrimeHeader{
    uint64_cu lastMaxNo;
    uint64_cu length;
    uint64_cu* primelist;
}PrimeHeader;

void logError(const char* errMesg){
    fprintf(stderr,"%s %d , %s\n", __FILE__, __LINE__,errMesg);
}

void printList(uint64_cu* ilist, uint64_cu len){
    printf("\n(START, length-> %llu)\n", len);
    int c = 0 ;
    for(uint64_cu index=0; index<len ; index++){
        printf("%llu ",ilist[index]);
        c++;
        if(c==100){
            printf("\n");
            c = 0;
        }
    }
    printf("\nEND \n");
}

void writePrimes(uint64_cu primes[], uint64_cu length, uint64_cu lastNo){
    FILE * fout1 = fopen(PRIME_FILENAME,"ab+");
    if(!fout1){
        fprintf(stderr,"Error opening %s file for writing primes, error-> %s",PRIME_FILENAME,strerror(errno));
        exit(1);
    }

    PrimeHeader hdr;
    hdr.lastMaxNo = lastNo;
    hdr.length = length;

    size_t num = fwrite(&hdr, sizeof(PrimeHeader), 1, fout1);
    if(num!=1){
        fprintf(stderr,"Error writing prime header needed 1 , written only %ld",num);
        exit(1);
    }
    num = fwrite(primes, INTSIZE, length, fout1);
    if(num!=length){
        fprintf(stderr,"Error writing prime header needed %llu , written only %ld",length,num);
        exit(1);
    }
    num = fclose(fout1);
    if(num != 0){
        fprintf(stderr,"Error clossing %s file, error-> %s",PRIME_FILENAME,strerror(errno));
        exit(1);
    }
}


PrimeHeader readPrimes(){
    PrimeHeader ret;
    FILE* fin = fopen(PRIME_FILENAME,"rb");
    if(!fin){
        ret.lastMaxNo = 0 ;
        ret.length = 0;
        ret.primelist = NULL;
        printf("fin null pointer");
        return ret;
    }
    uint64_cu aggregatePrimes = 0 ;
    PrimeHeader hdr;
    uint64_cu offset = 0;
    printf("\nFIRST PASS: to find number of total primes\n");
    while(!feof(fin)){
        uint64_cu nread = fread(&hdr, sizeof(PrimeHeader), 1, fin);
        if(nread == 0)break;
        aggregatePrimes += hdr.length;
        printf("\nnread %llu ",nread);
        printf("\tlastMaxNo-> %llu ",hdr.lastMaxNo);
        printf("\tlength -> %llu ",hdr.length);
        // skip past primes in current line
        int ret = fseek(fin, (hdr.length *INTSIZE) , SEEK_CUR);
        if(ret==-1){
            fprintf(stderr,"Error in fseek %s file, error-> %s",PRIME_FILENAME,strerror(errno));
            exit(1);
        }
    }

    printf("\nAggregatePrimes %llu",aggregatePrimes);

    // now read all primes
    printf("\nSECOND PASS: to read all primes\n");
    fseek(fin,0,SEEK_SET);
    uint64_cu* retPtr = (uint64_cu*) malloc(aggregatePrimes * INTSIZE);
    if(!retPtr){
        fprintf(stderr,"Error in malloc of %llu primes, error-> %s",aggregatePrimes,strerror(errno));
        exit(1);
    }
    offset = 0;

    while(!feof(fin)){
        uint64_cu nread = fread(&hdr, sizeof(PrimeHeader), 1, fin);
        if(nread == 0)break;
        printf("\nnread %llu ",nread);
        ret.lastMaxNo = hdr.lastMaxNo;
        printf("\tlastMaxNo-> %llu ",hdr.lastMaxNo);
        printf("\tlength -> %llu ",hdr.length);
        uint64_cu nreadArr = fread(retPtr + offset ,INTSIZE,hdr.length,fin);
        if(nreadArr == 0){
            fprintf(stderr,"Error in reading of %llu primes, 0 were read",hdr.length);
            exit(1);
        }
        printf("\t %llu",nreadArr);
        offset += hdr.length;
    }
    printf("\n*************  PRINT AGGREGATE PRIMES ****************\n");
    //printList(retPtr,aggregatePrimes);
    ret.length = aggregatePrimes;
    ret.primelist = retPtr;
    size_t num = fclose(fin);
    if(num != 0){
        fprintf(stderr,"Error clossing %s file, error-> %s",PRIME_FILENAME,strerror(errno));
    }
    return ret;
}
