/*
    Copyright 2018 Chris Cox
    Distributed under the MIT License (see accompanying file LICENSE_1_0_0.txt
    or a copy at http://stlab.adobe.com/licenses.html )


Goal:  Examine performance optimizations related to loop induction variables.


Assumptions:
    1) The compiler will normalize all loop types and optimize all equally.
        (this is a necessary step before doing induction variable analysis)
        
    2) The compiler will remove unused induction variables.
        This could happen due to several optimizations.

    2) The compiler will recognize induction variables with linear relations (x = a*b + c)
        and optimize out redundant variables.

    3) The compiler will apply strength reduction to induction variable usage.

    4) The compiler will remove bounds checks by recognizing or adjusting loop limits.
        (can be an explict loop optimization, or part of range propagation)


*/

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


// 32000 items, or about 128k of data
// this is intended to remain within the L2 cache of most common CPUs
const int SIZE = 32000;


// initial value for filling our arrays, may be changed from the command line
int init_value = 3;

/******************************************************************************/

void fill_random(int32_t * first, int32_t * last) {
    while (first != last) {
        *first++ = (int32_t)rand();
    }
}

/******************************************************************************/
/******************************************************************************/


void test_copy(const int32_t *source, int32_t *dest, int count, const char *label) {
    int i;
    
    fill_random( dest, dest+count );

    start_time = clock();

    for(i = 0; i < iterations; ++i) {
        int i, j, k;
        for ( i=0, j=0, k=0; k < count; ++i, ++j, ++k ) {
            dest[i] = source[j];
        }
    }
    
    end_time = clock();
    
    if ( memcmp(dest, source, count*sizeof(int32_t)) != 0 )
        printf("test %s failed\n", label);

    double time_cost = (end_time - start_time)/ (double)(CLOCKS_PER_SEC);

    printf("\"%s, %d items\"  %f sec\n",
        label,
        count,
        time_cost);
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
    if (argc > 2) init_value = (int) atoi(argv[2]);
    
    int32_t intSrc[ SIZE ];
    int32_t intDst[ SIZE ];
    
    
    srand( (unsigned int)init_value + 123);
    fill_random( intSrc, intSrc+SIZE );


    test_copy( &intSrc[0], &intDst[0], SIZE, "int32_t for induction copy" );


    return 0;
}

// the end
/******************************************************************************/
/******************************************************************************/
