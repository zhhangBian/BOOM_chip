/*
    Copyright 2008 Adobe Systems Incorporated
    Copyright 2019 Chris Cox
    Distributed under the MIT License (see accompanying file LICENSE_1_0_0.txt
    or a copy at http://stlab.adobe.com/licenses.html )


Goal: Test performance of various idioms for calculating the product of a sequence.


Assumptions:
    1) The compiler will optimize product operations.
    
    2) The compiler may recognize ineffecient product idioms and substitute efficient methods.


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

clock_t start_time, end_time;

/******************************************************************************/

// this constant may need to be adjusted to give reasonable minimum times
// For best results, times should be about 1.0 seconds for the minimum test run
int iterations = 10;


// 4000 items, or about 32k of data
// this is intended to remain within the L2 cache of most common CPUs
const int SIZE = 4000;


// initial value for filling our arrays, may be changed from the command line
double init_value = 2.1;

/******************************************************************************/
/******************************************************************************/

void fill_f16(float * first, float * last, float value) {
    while (first != last) *first++ = (float)(value);
}

void fill_f32(double * first, double * last, double value) {
    while (first != last) *first++ = (double)(value);
}


void testOneFunction_f16(const float* first, const int count, const char * label) {
    int i;

    start_time = clock();

    for(i = 0; i < iterations; ++i) {
    
        float result = (float)(1);
        for (int j = 0; j < count; ++j) {
            result = result * first[j];
        }
       
        if ( fabs( result - pow(init_value,(double)SIZE) ) > 1.0e-6 ) 
            printf("test %s failed\n", label);
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);

    printf("\"%s, %d items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void testOneFunction_f32(const double* first, const int count, const char * label) {
    int i;

    start_time = clock();

    for(i = 0; i < iterations; ++i) {
    
        double result = (double)(1);
        for (int j = 0; j < count; ++j) {
            result = result * first[j];
        }
        
        if ( fabs( result - pow(init_value,(double)SIZE) ) > 1.0e-6 ) 
            printf("test %s failed\n", label);
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);

    printf("\"%s, %d items\"  %f sec\n",
        label,
        count,
        time_cost);
}

/******************************************************************************/
void TestOneType_f16()
{

    float data[SIZE];

    fill_f16(data, data+SIZE, (float)(init_value));
    
    testOneFunction_f16( data, SIZE, "float product sequence1" );

}

void TestOneType_f32()
{

    double data[SIZE];

    fill_f32(data, data+SIZE, (double)(init_value));
    
    testOneFunction_f32( data, SIZE, "double product sequence1" );

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
    if (argc > 2) init_value = (double) atof(argv[2]);


    TestOneType_f16();

    TestOneType_f32();


    return 0;
}

// the end
/******************************************************************************/
/******************************************************************************/
