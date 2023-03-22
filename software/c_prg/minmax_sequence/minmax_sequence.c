/*
    Copyright 2008-2009 Adobe Systems Incorporated
    Copyright 2018-2019 Chris Cox
    Distributed under the MIT License (see accompanying file LICENSE_1_0_0.txt
    or a copy at http://stlab.adobe.com/licenses.html )


Goal: Test the performance of various idioms for finding maximum and maximum of a sequence.


Assumptions:
    1) The compiler will optimize minimum and maximum finding operations.

    2) The compiler may recognize ineffecient minimum or maximum idioms and substitute efficient methods.



NOTE - min or max between two sequences is tested in minmax.cpp.

NOTE - pin values in sequence, see minmax.cpp

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
int iterations = 5;


// 8000 items, or between 8 and 64k of data
// this is intended to remain within the L2 cache of most common CPUs
#define SIZE     8000


// initial value for filling our arrays, may be changed from the command line
int32_t init_value = 3;

/******************************************************************************/

double gMinResult = 0;
double gMaxResult = 0;

size_t gMinPosition = 0;
size_t gMaxPosition = 0;


/******************************************************************************/
/******************************************************************************/

void check_min_position(size_t result, const char * label) {
    if (result != (size_t)(gMinPosition))
        printf("test %s failed (got %tu instead of %zu)\n", label, result, gMinPosition );
}

/******************************************************************************/

void check_max_position(size_t result, const char * label) {
    if (result != (size_t)(gMaxPosition))
        printf("test %s failed (got %tu instead of %zu)\n", label, result, gMaxPosition );
}

/******************************************************************************/
/******************************************************************************/

int8_t find_minimum_8( int8_t * first, int8_t * last ) {
    int8_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

uint8_t find_minimum_u8( uint8_t * first, uint8_t * last ) {
    uint8_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

int16_t find_minimum_16( int16_t * first, int16_t * last ) {
    int16_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

uint16_t find_minimum_u16( uint16_t * first, uint16_t * last ) {
    uint16_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

int32_t find_minimum_32( int32_t * first, int32_t * last ) {
    int32_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

uint32_t find_minimum_u32( uint32_t * first, uint32_t * last ) {
    uint32_t min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

float find_minimum_f16( float * first, float * last ) {
    float min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

double find_minimum_f32( double * first, double * last ) {
    double min_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first < min_value)
            min_value = *first;
        ++first;
    }
    return  min_value;
}

/******************************************************************************/
int8_t find_maximum_8( int8_t * first, int8_t * last ) {
    int8_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

uint8_t find_maximum_u8( uint8_t * first, uint8_t * last ) {
    uint8_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

int16_t find_maximum_16( int16_t * first, int16_t * last ) {
    int16_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

uint16_t find_maximum_u16( uint16_t * first, uint16_t * last ) {
    uint16_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

int32_t find_maximum_32( int32_t * first, int32_t * last ) {
    int32_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

uint32_t find_maximum_u32( uint32_t * first, uint32_t * last ) {
    uint32_t max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

float find_maximum_f16( float * first, float * last ) {
    float max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

double find_maximum_f32( double * first, double * last ) {
    double max_value = *first;
    if (first != last)
        ++first;
    while (first != last) {
        if (*first > max_value)
            max_value = *first;
        ++first;
    }
    return  max_value;
}

/******************************************************************************/
size_t find_minimum_position_8( int8_t * first, size_t count) {
    int8_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_u8( uint8_t * first, size_t count) {
    uint8_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_16( int16_t * first, size_t count) {
    int16_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_u16( uint16_t * first, size_t count) {
    uint16_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_32( int32_t * first, size_t count) {
    int32_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_u32( uint32_t * first, size_t count) {
    uint32_t min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_f16( float * first, size_t count) {
    float min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

size_t find_minimum_position_f32( double * first, size_t count) {
    double min_value = first[0];
    size_t minpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] < min_value) {
            min_value = first[k];
            minpos = k;
        }
    }
    return minpos;
}

/******************************************************************************/
size_t find_maximum_position_8( int8_t * first, size_t count) {
    int8_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_u8( uint8_t * first, size_t count) {
    uint8_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_16( int16_t * first, size_t count) {
    int16_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_u16( uint16_t * first, size_t count) {
    uint16_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_32( int32_t * first, size_t count) {
    int32_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_u32( uint32_t * first, size_t count) {
    uint32_t max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_f16( float * first, size_t count) {
    float max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

size_t find_maximum_position_f32( double * first, size_t count) {
    double max_value = first[0];
    size_t maxpos = 0;
    for (size_t k = 1; k < count; ++k) {
        if (first[k] > max_value) {
            max_value = first[k];
            maxpos = k;
        }
    }
    return maxpos;
}

/******************************************************************************/
/******************************************************************************/
void test_min_value2_8(int8_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int8_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (int8_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_u8(uint8_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint8_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (uint8_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_16(int16_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int16_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (int16_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_u16(uint16_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint16_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (uint16_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_32(int32_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int32_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (int32_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_u32(uint32_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint32_t min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (uint32_t)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_f16(float* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        float min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (float)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
    }

    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_value2_f32(double* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        double min_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < min_value)
                min_value = first[k];
        }

        if (min_value != (double)(gMinResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)min_value, gMinResult );
        
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

void test_max_value2_8(int8_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int8_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (int8_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_u8(uint8_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint8_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (uint8_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_16(int16_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int16_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (int16_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_u16(uint16_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint16_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (uint16_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_32(int32_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        int32_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (int32_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_u32(uint32_t* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        uint32_t max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (uint32_t)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_f16(float* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        float max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (float)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();
    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_value2_f32(double* first, size_t count, const char * label) {
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        double max_value = first[0];
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > max_value)
                max_value = first[k];
        }
        
        if (max_value != (double)(gMaxResult))
            printf("test %s failed (got %g instead of %g)\n", label, (double)max_value, gMaxResult );
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
/******************************************************************************/

void test_min_position1_8(int8_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_u8(uint8_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_16(int16_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_u16(uint16_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_32(int32_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_u32(uint32_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_f16(float* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_min_position1_f32(double* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t minpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] < first[minpos]) {
                minpos = k;
            }
        }
        check_min_position(minpos, label);
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

void test_max_position1_8(int8_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_u8(uint8_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_16(int16_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_u16(uint16_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_32(int32_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_u32(uint32_t* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_f16(float* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
    }
    
    // need the labels to remain valid until we print the summary
    end_time = clock();

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);
    printf("\"%s, %lu items\"  %f sec\n",
        label,
        count,
        time_cost);
}

void test_max_position1_f32(double* first, size_t count, const char * label)
{
    start_time = clock();

    for(int i = 0; i < iterations; ++i) {
        size_t maxpos = 0;
        for (size_t k = 1; k < count; ++k) {
            if (first[k] > first[maxpos]) {
                maxpos = k;
            }
        }
        check_max_position(maxpos, label);
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

/******************************************************************************/
/******************************************************************************/

void TestOneType_8()
{   
    int8_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    int8_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (int8_t)rand();
    }
    
    gMinResult = find_minimum_8( data, data+SIZE );
    gMaxResult = find_maximum_8( data, data+SIZE );
    gMinPosition = find_minimum_position_8( data, SIZE );
    gMaxPosition = find_maximum_position_8( data, SIZE );

    test_min_value2_8( data, SIZE, "int8_t minimum value sequence2");
    test_max_value2_8( data, SIZE, "int8_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_8( data, SIZE, "int8_t minimum position sequence1");  
    test_max_position1_8( data, SIZE, "int8_t maximum position sequence1");  
  
    iterations = iterations_base;
}

void TestOneType_u8()
{   
    uint8_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    uint8_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (uint8_t)rand();
    }
    
    gMinResult = find_minimum_u8( data, data+SIZE );
    gMaxResult = find_maximum_u8( data, data+SIZE );
    gMinPosition = find_minimum_position_u8( data, SIZE );
    gMaxPosition = find_maximum_position_u8( data, SIZE );

    test_min_value2_u8( data, SIZE, "uint8_t minimum value sequence2");
    test_max_value2_u8( data, SIZE, "uint8_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_u8( data, SIZE, "uint8_t minimum position sequence1");  
    test_max_position1_u8( data, SIZE, "uint8_t maximum position sequence1");  
  
    iterations = iterations_base;
}

void TestOneType_16()
{   
    int16_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    int16_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (int16_t)rand();
    }
    
    gMinResult = find_minimum_16( data, data+SIZE );
    gMaxResult = find_maximum_16( data, data+SIZE );
    gMinPosition = find_minimum_position_16( data, SIZE );
    gMaxPosition = find_maximum_position_16( data, SIZE );

    test_min_value2_16( data, SIZE, "int16_t minimum value sequence2");
    test_max_value2_16( data, SIZE, "int16_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_16( data, SIZE, "int16_t minimum position sequence1");  
    test_max_position1_16( data, SIZE, "int16_t maximum position sequence1");  
  
    iterations = iterations_base;
}

void TestOneType_u16()
{   
    uint16_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    uint16_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (uint16_t)rand();
    }
    
    gMinResult = find_minimum_u16( data, data+SIZE );
    gMaxResult = find_maximum_u16( data, data+SIZE );
    gMinPosition = find_minimum_position_u16( data, SIZE );
    gMaxPosition = find_maximum_position_u16( data, SIZE );

    test_min_value2_u16( data, SIZE, "uint16_t minimum value sequence2");
    test_max_value2_u16( data, SIZE, "uint16_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_u16( data, SIZE, "uint16_t minimum position sequence1");  
    test_max_position1_u16( data, SIZE, "uint16_t maximum position sequence1");  
  
    iterations = iterations_base;
}

void TestOneType_32()
{   
    int32_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    int32_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (int32_t)rand();
    }
    
    gMinResult = find_minimum_32( data, data+SIZE );
    gMaxResult = find_maximum_32( data, data+SIZE );
    gMinPosition = find_minimum_position_32( data, SIZE );
    gMaxPosition = find_maximum_position_32( data, SIZE );

    test_min_value2_32( data, SIZE, "int32_t minimum value sequence2");
    test_max_value2_32( data, SIZE, "int32_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_32( data, SIZE, "int32_t minimum position sequence1");  
    test_max_position1_32( data, SIZE, "int32_t maximum position sequence1");  
  
    iterations = iterations_base;
}

void TestOneType_u32()
{   
    uint32_t data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    uint32_t * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (uint32_t)rand();
    }
    
    gMinResult = find_minimum_u32( data, data+SIZE );
    gMaxResult = find_maximum_u32( data, data+SIZE );
    gMinPosition = find_minimum_position_u32( data, SIZE );
    gMaxPosition = find_maximum_position_u32( data, SIZE );

    test_min_value2_u32( data, SIZE, "uint32_t minimum value sequence2");
    test_max_value2_u32( data, SIZE, "uint32_t maximum value sequence2");

    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;

    test_min_position1_u32( data, SIZE, "uint32_t minimum position sequence1");  
    test_max_position1_u32( data, SIZE, "uint32_t maximum position sequence1");  
  
    iterations = iterations_base;
}

/******************************************************************************/
/******************************************************************************/

void TestOneFloat_f16()
{   
    float data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    float * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (float)rand();
    }
    
    gMinResult = find_minimum_f16( data, data+SIZE );
    gMaxResult = find_maximum_f16( data, data+SIZE );
    gMinPosition = find_minimum_position_f16( data, SIZE );
    gMaxPosition = find_maximum_position_f16( data, SIZE );
    
    test_min_value2_f16( data, SIZE, "float minimum value sequence2");
    test_max_value2_f16( data, SIZE, "float maximum value sequence2");
 
    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;
    
    test_min_position1_f16( data, SIZE, "float minimum position sequence1"); 
    test_max_position1_f16( data, SIZE, "float maximum position sequence1");  
 
    iterations = iterations_base;
}

void TestOneFloat_f32()
{   
    double data[SIZE];

    srand( (unsigned int)init_value + 123 );  
    double * data_p = data;
    while (data_p != (data+SIZE)) {
        *data_p++ = (double)rand();
    }
    
    gMinResult = find_minimum_f32( data, data+SIZE );
    gMaxResult = find_maximum_f32( data, data+SIZE );
    gMinPosition = find_minimum_position_f32( data, SIZE );
    gMaxPosition = find_maximum_position_f32( data, SIZE );
    
    test_min_value2_f32( data, SIZE, "double minimum value sequence2");
    test_max_value2_f32( data, SIZE, "double maximum value sequence2");
 
    // position tests are much slower, even at their best
    int iterations_base = iterations;
    iterations = iterations / 5;
    
    test_min_position1_f32( data, SIZE, "double minimum position sequence1"); 
    test_max_position1_f32( data, SIZE, "double maximum position sequence1");  
 
    iterations = iterations_base;
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
    if (argc > 2) init_value = (int32_t) atoi(argv[2]);


    TestOneType_8();
    TestOneType_u8();
    TestOneType_16();
    TestOneType_u16();
    
    TestOneType_32();
    TestOneType_u32();
    
    TestOneFloat_f16();
    TestOneFloat_f32();

    return 0;
}

// the end
/******************************************************************************/
/******************************************************************************/
