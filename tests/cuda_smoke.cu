#include <cuda_runtime.h>

#include <iostream>

int main()
{
    int device_count = 0;
    const cudaError_t result = cudaGetDeviceCount(&device_count);

    if (result != cudaSuccess) {
        std::cerr << "CUDA device discovery failed: "
                  << cudaGetErrorString(result) << std::endl;
        return 1;
    }

    if (device_count < 1) {
        std::cerr << "No CUDA device is visible inside the container." << std::endl;
        return 1;
    }

    std::cout << "CUDA device count: " << device_count << std::endl;
    return 0;
}
