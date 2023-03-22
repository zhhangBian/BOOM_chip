/*
    Copyright 2008 Adobe Systems Incorporated
    Copyright 2018-2019 Chris Cox
    Distributed under the MIT License (see accompanying file LICENSE_1_0_0.txt
    or a copy at http://stlab.adobe.com/licenses.html )


Goal:  Test performance of various idioms for calculating the inner product of two sequences.

NOTE:  Inner products are common in mathematical and geometry processing applications,
        plus some audio and image processing.


Assumptions:
    1) The compiler will optimize inner product operations.

    2) The compiler may recognize ineffecient inner product idioms
        and substitute efficient methods when it can.
        NOTE: the best method is highly dependent on the data types and CPU architecture

    3) std::inner_product will be well optimized for all types and containers.


*/

/******************************************************************************/

#include <time.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

/******************************************************************************/
/******************************************************************************/

clock_t start_time, end_time;

// this constant may need to be adjusted to give reasonable minimum times
// For best results, times should be about 1.0 seconds for the minimum test run
int iterations = 5;


// 8000 items, or between 8 and 64k of data
// this is intended to remain within the L2 cache of most common CPUs
const int SIZE = 8000;


// initial value for filling our arrays, may be changed from the command line
int32_t init_value_8 = 3;
int32_t init_value_16 = 211;
int32_t init_value_32 = 1065;
float init_value_f16 = 5.0;
double init_value_f32 = 365.0;

/******************************************************************************/
/******************************************************************************/

void fill_8(int8_t * first, int8_t * last, int8_t value) {
    while (first != last) *first++ = (int8_t)(value);
}

void fill_u8(uint8_t * first, uint8_t * last, uint8_t value) {
    while (first != last) *first++ = (uint8_t)(value);
}

void fill_16(int16_t * first, int16_t * last, int16_t value) {
    while (first != last) *first++ = (int16_t)(value);
}

void fill_u16(uint16_t * first, uint16_t * last, uint16_t value) {
    while (first != last) *first++ = (uint16_t)(value);
}

void fill_32(int32_t * first, int32_t * last, int32_t value) {
    while (first != last) *first++ = (int32_t)(value);
}

void fill_u32(uint32_t * first, uint32_t * last, uint32_t value) {
    while (first != last) *first++ = (uint32_t)(value);
}

void fill_f16(float * first, float * last, float value) {
    while (first != last) *first++ = (float)(value);
}

void fill_f32(double * first, double * last, double value) {
    while (first != last) *first++ = (double)(value);
}

/******************************************************************************/
/******************************************************************************/
// a trivial for loop

void test_inner_product_8( const int8_t* first, const int8_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        int8_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        int8_t target = (int8_t)(init_value_8)*(int8_t)(init_value_8)*SIZE;
        if ( abs( sum - target ) > (int8_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_u8( const uint8_t* first, const uint8_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        uint8_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        uint8_t target = (uint8_t)(init_value_8)*(uint8_t)(init_value_8)*SIZE;
        if ( ( sum - target ) > (uint8_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_16( const int16_t* first, const int16_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        int16_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        int16_t target = (int16_t)(init_value_16)*(int16_t)(init_value_16)*SIZE;
        if ( abs( sum - target ) > (int16_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_u16( const uint16_t* first, const uint16_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        uint16_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        uint16_t target = (uint16_t)(init_value_16)*(uint16_t)(init_value_16)*SIZE;
        if ( ( sum - target ) > (uint16_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_32( const int32_t* first, const int32_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        int32_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        int32_t target = (int32_t)(init_value_32)*(int32_t)(init_value_32)*SIZE;
        if ( abs( sum - target ) > (int32_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_u32( const uint32_t* first, const uint32_t* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        uint32_t sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        uint32_t target = (uint32_t)(init_value_32)*(uint32_t)(init_value_32)*SIZE;
        if ( ( sum - target ) > (uint32_t)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_f16( const float* first, const float* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        float sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        float target = (float)(init_value_f16)*(float)(init_value_f16)*SIZE;
        if ( fabs( sum - target ) > (float)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_inner_product_f32( const double* first, const double* second, const size_t count, const char *label) {

    start_time = clock();

    for(int i = 0; i < iterations; ++i) {

        double sum = 0 ;
        for (size_t j = 0; j < count; ++j) {
            sum += first[j] * second[j];
        }
        
        //check_sum( sum, label );
        double target = (double)(init_value_f32)*(double)(init_value_f32)*SIZE;
        if ( fabs( sum - target ) > (double)(1.0e-6) )
            printf("test %s failed\n", label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

/******************************************************************************/
/******************************************************************************/

// NOTE - can't make generic template template argument without C++17
// I would like to have TestOneFunction to handle all the types and if's, but need to use different types with it inside
// see sum_sequence.cpp


void TestOneType_8()
{
    int8_t data[SIZE];
    int8_t dataB[SIZE];

    fill_8(data, data+SIZE, (int8_t)(init_value_8));
    fill_8(dataB, dataB+SIZE, (int8_t)(init_value_8));
   
    test_inner_product_8( data, dataB, SIZE, "int_8 inner_product1 to int_8");
}

void TestOneType_u8()
{
    uint8_t data[SIZE];
    uint8_t dataB[SIZE];

    fill_u8(data, data+SIZE, (uint8_t)(init_value_8));
    fill_u8(dataB, dataB+SIZE, (uint8_t)(init_value_8));
   
    test_inner_product_u8( data, dataB, SIZE, "uint_8 inner_product1 to uint_8");
}


void TestOneType_16()
{
    int16_t data[SIZE];
    int16_t dataB[SIZE];

    fill_16(data, data+SIZE, (int16_t)(init_value_16));
    fill_16(dataB, dataB+SIZE, (int16_t)(init_value_16));
   
    test_inner_product_16( data, dataB, SIZE, "int_16 inner_product1 to int_16");
}

void TestOneType_u16()
{
    uint16_t data[SIZE];
    uint16_t dataB[SIZE];

    fill_u16(data, data+SIZE, (uint16_t)(init_value_16));
    fill_u16(dataB, dataB+SIZE, (uint16_t)(init_value_16));
   
    test_inner_product_u16( data, dataB, SIZE, "uint_16 inner_product1 to uint_16");
}

void TestOneType_32()
{
    int32_t data[SIZE];
    int32_t dataB[SIZE];

    fill_32(data, data+SIZE, (int32_t)(init_value_32));
    fill_32(dataB, dataB+SIZE, (int32_t)(init_value_32));
   
    test_inner_product_32( data, dataB, SIZE, "int_32 inner_product1 to int_32");
}

void TestOneType_u32()
{
    uint32_t data[SIZE];
    uint32_t dataB[SIZE];

    fill_u32(data, data+SIZE, (uint32_t)(init_value_32));
    fill_u32(dataB, dataB+SIZE, (uint32_t)(init_value_32));
   
    test_inner_product_u32( data, dataB, SIZE, "uint_32 inner_product1 to uint_32");
}

void TestOneType_f16()
{
    float data[SIZE];
    float dataB[SIZE];

    fill_f16(data, data+SIZE, (float)(init_value_f16));
    fill_f16(dataB, dataB+SIZE, (float)(init_value_f16));
   
    test_inner_product_f16( data, dataB, SIZE, "float inner_product1 to float");
}

void TestOneType_f32()
{
    double data[SIZE];
    double dataB[SIZE];

    fill_f32(data, data+SIZE, (double)(init_value_f32));
    fill_f32(dataB, dataB+SIZE, (double)(init_value_f32));
   
    test_inner_product_f32( data, dataB, SIZE, "double inner_product1 to double");
}
/******************************************************************************/
/******************************************************************************/

int main(int argc, char** argv) {

    // output command for documentation:
    int i;
    // for (i = 0; i < argc; ++i)
    //     printf("%s ", argv[i] );
    // printf("\n");

    if (argc > 1) iterations = atoi(argv[1]);
    // if (argc > 2) init_value = (int32_t) atoi(argv[2]);


    TestOneType_8();
    TestOneType_u8();
    TestOneType_16();
    TestOneType_u16();
    TestOneType_32();
    TestOneType_u32();

    TestOneType_f16();
    TestOneType_f32();

    return 0;
}

// the end
/******************************************************************************/
/******************************************************************************/
