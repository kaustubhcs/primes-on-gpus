#!/bin/sh

# Created by KAUSTUBH SHIVDIKAR

TARGET=primes.bin
GPU_ARCH = compute_35
GPU_CODE = sm_35
NVCC=nvcc
FLAGS=-O0 -std=c++11 -Xcompiler="-pthread" -arch=$(GPU_ARCH) -code=$(GPU_CODE) #-g -G -Xptxas=-v
LDFLAGS=
ROOT_DIR=$(PWD)
CODE_DIR=$(ROOT_DIR)/src/code
HEADER_DIR=$(ROOT_DIR)/src/headers
INC_DIR=$(ROOT_DIR)/src/inc
LIB_DIR=$(ROOT_DIR)/src/lib
OBJ_DIR=$(ROOT_DIR)/src/obj
BIN_DIR=$(ROOT_DIR)/src/bin
OBJ=$(OBJ_DIR)/primes.o $(OBJ_DIR)/functions.o $(OBJ_DIR)/debugger.o



all: $(OBJ)
	$(NVCC) $(FLAGS) $(LDFLAGS) -o $(BIN_DIR)/$(TARGET) $(OBJ)
	cp $(BIN_DIR)/$(TARGET) $(ROOT_DIR)

$(OBJ_DIR)/%.o: $(CODE_DIR)/%.cu
	$(NVCC) $(FLAGS) $(LDFLAGS) -I$(HEADER_DIR) -c $<
	mv $(@F) $(OBJ_DIR)

clean:
	printf "\n\e[1;32mCleaning all Object files\e[0m\n"
	rm -f $(OBJ_DIR)/*.o $(BIN_DIR)/*.bin $(ROOT_DIR)/*.bin

run: clean all
	$(BIN_DIR)/$(TARGET)



clean-dat:
	printf "\n\e[1;32mCleaning all Data files\e[0m\n"
	rm -f $(ROOT_DIR)/*.dat



dist: clean
	dir=`basename $$PWD`; cd ..; tar cvf $$dir.tar ./$$dir; gzip $$dir.tar

