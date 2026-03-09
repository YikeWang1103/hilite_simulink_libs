
/*
 * Include Files
 *
 */
#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
#define SIMPLIFIED_RTWTYPES_COMPATIBILITY
#include "rtwtypes.h"
#undef SIMPLIFIED_RTWTYPES_COMPATIBILITY
#endif



/* %%%-SFUNWIZ_wrapper_includes_Changes_BEGIN --- EDIT HERE TO _END */
#include <math.h>
/* %%%-SFUNWIZ_wrapper_includes_Changes_END --- EDIT HERE TO _BEGIN */
#define u_width 8
#define u_1_width 1
#define u_2_width 1
#define u_3_width 1
#define u_4_width 1
#define u_5_width 1
#define u_6_width 1
#define y_width 1

/*
 * Create external references here.  
 *
 */
/* %%%-SFUNWIZ_wrapper_externs_Changes_BEGIN --- EDIT HERE TO _END */
/* extern double func(double a); */
/* %%%-SFUNWIZ_wrapper_externs_Changes_END --- EDIT HERE TO _BEGIN */

/*
 * Output function
 *
 */
extern void canSignalParser_Outputs_wrapper(const uint8_T *data,
			const int8_T *startBit,
			const int8_T *length,
			const boolean_T *isSigned,
			const real_T *factor,
			const real_T *offset,
			const boolean_T *isBigEndian,
			real_T *y0);

void canSignalParser_Outputs_wrapper(const uint8_T *data,
			const int8_T *startBit,
			const int8_T *length,
			const boolean_T *isSigned,
			const real_T *factor,
			const real_T *offset,
			const boolean_T *isBigEndian,
			real_T *y0)
{
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_BEGIN --- EDIT HERE TO _END */
    /* CAN */
    int32_T rawValue = 0;
    int8_T i;
    
    /*  */
    if (*isBigEndian) {
        /*  */
        for (i = 0; i < *length; i++) {
            int8_T currentBit = *startBit + i;
            int8_T byteIndex = currentBit / 8;
            int8_T bitIndex = 7 - (currentBit % 8);
            
            if (byteIndex < 8) { /* CAN8 */
                if (data[byteIndex] & (1 << bitIndex)) {
                    rawValue |= (1 << (*length - 1 - i));
                }
            }
        }
    } else {
        /*  */
        for (i = 0; i < *length; i++) {
            int8_T currentBit = *startBit + i;
            int8_T byteIndex = currentBit / 8;
            int8_T bitIndex = currentBit % 8;
            
            if (byteIndex < 8) { /* CAN8 */
                if (data[byteIndex] & (1 << bitIndex)) {
                    rawValue |= (1 << i);
                }
            }
        }
    }
    
    /*  */
    if (*isSigned && *length > 0) {
        /* 1 */
        if (rawValue & (1 << (*length - 1))) {
            /*  */
            int32_T mask = (1 << *length) - 1;
            rawValue = -((~rawValue & mask) + 1);
        }
    }
    
    /*  */
    *y0 = (real_T)rawValue * (*factor) + (*offset);
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_END --- EDIT HERE TO _BEGIN */
}


