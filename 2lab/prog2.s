    .arch armv8-a

    .data

n:  .byte 3
m:  .byte 9

    .align 1

matrix:
    .short 3, 4, 1
    .short 2, 7, 2
    .short 5, 9, 3
    .short 8, 1, 4
    .short 6, 6, 5
    .short 1, 8, 6
    .short 9, 5, 7
    .short 7, 2, 8
    .short 4, 3, 9

index_array:
    .skip 9 * 2
    //.short 0, 1, 2, 3, 4, 5, 6, 7, 8 // shorts
    .align 2
summs_array:
    .skip 9 * 4
    //.long  0, 0, 0, 0, 0, 0, 0, 0, 0 // longs
new_matrix:
    .skip 9*3*2

    .global _start
    .type   _start, %function

    .text

_start:

// load parameters

    adr     x0, n
    ldrb    w1, [x0]
    adr     x0, m
    ldrb    w2, [x0]
    adr     x3, matrix
    adr     x4, index_array
    adr     x5, summs_array
    adr     x22, new_matrix

// w1 - n - width
// w2 - m - heght
// x3 - matrix beginning
// x4 - index_array beginning
// x5 - summs_array beginning

// init arrays

    mov     w0, #0
    mov     x6, #0
init_L0:
    cmp     w2, w6
    bls     init_L1

    str     w0, [x5, x6, lsl #2]
    strh    w6, [x4, x6, lsl #1]
    add     w6, w6, #1
    b       init_L0

// count summs

init_L1:
    mov     x6, #0                  // i = 0
L0:
    cmp     w2, w6                  // while i < m
    bls     L3                      // |

    ldr     w8, [x5, x6, lsl #2]    // summs_array[i]
    mov     x7, #0                  // j = 0
L1:
    cmp     w1, w7                  // while j < n
    bls     L2                      // |

    mul     w9, w6, w1              // i * n
    add     w9, w9, w7              // i * n + j
    ldrsh   w10, [x3, x9, lsl #1]   // matrix[(i * n + j) * sizeof(element)]
    add     w8, w8, w10, sxth       // summs_array[i] += matrix + (i * n + j) * sizeof(element)
    add     w7, w7, #1              // j++
    b       L1
L2:
    str     w8, [x5, x6, lsl #2]    // summs_array[i]
    add     w6, w6, #1
    b       L0

// sort array

L3:
    mov     w0, #2
    udiv    w6, w2, w0              // interval = m // 2
L4:
    cmp     w6, #0                  // while interval > 0                             \
    bls     L9                      // |                                              |
                                    //                                                |
    uxtw    x7, w6                  // i = interval
    //mov     x0, #0
    //add     x7, x0, w6, uxtw
L5:                                 //                                                |
    cmp     w2, w7                  // while i < m                                   \|
    bls     L8                      //                                               ||
                                    //                                               ||
    ldr     w8, [x5, x7, lsl #2]    // temp_sum = summs_array[i]                     ||
    ldrh    w12, [x4, x7, lsl #1]   // temp_ind = index_array[i]                     ||
    mov     x9, x7                  // j = i                                         ||
L6:                                 //                                               ||
    cmp     w9, w6                  // while j >= interval                          \||
    blo     L7                      // |                                            |||
    sub     x10, x9, w6, uxtw       // j - interval                                 |||
    ldr     w11, [x5, x10, lsl #2]  // summs_array[j-interval]                      |||
    cmp     w11, w8                 // and while summs_arra[j-interval] |<| temp_sum|||
.ifndef REVERSE
    bls     L7                      // defined string
.else
    bhs     L7
.endif

    str     w11, [x5, x9, lsl #2]   // summs_array[j] = summs_array[j-interval]     |||
    ldrh    w13, [x4, x10, lsl #1]  // index_array[j-interval]                      |||
    strh    w13, [x4, x9, lsl #1]   // index_array[j] = index_array[j-interval]     |||
                                    //                                              |||
    mov     x9, x10                 // j = j - interval                             |||
    b       L6                      //                                              /||
L7:                                 //                                               ||
    str     w8, [x5, x9, lsl #2]    // summs_array[j] = temp_sum                     ||
    strh    w12, [x4, x9, lsl #1]   // index_array[j] = temp_ind                     ||
    add     x7, x7, #1              // i += 1                                        ||
    b       L5                      //                                               /|
L8:                                 //                                                |
    mov     w0, #2                  //                                                |
    udiv    w6, w6, w0              // interval = interval // 2                       |
    b       L4                      //                                                /

// sort matrix
L9:
    mov     x6, #0                  // i = 0
    mov     x7, #0
L10:
    cmp     w2, w6                  // while i < m
    bls     L13                     // |
                                    //
    ldrh    w7, [x4, x6, lsl #1]    // k = index_array[i]
    mov     x8, #0                  // j = 0
L11:
    cmp     w1, w8                  // while j < n
    bls     L12                     // |
                                    //
    mul     w9, w6, w1              // i * n
    add     w9, w9, w8              // i * n + j
    mul     w10, w7, w1             // k * n
    add     w10, w10, w8            // k * n + j
    ldrh    w12, [x3, x10, lsl #1]   // matrix[k * n + j]
    strh    w12, [x22, x9, lsl #1]   // new_matrix[i * n + j]
    add     w8, w8, #1              // j++
    b       L11
L12:
    add     w6, w6, #1              // i++
    b       L10
L13:

    mov     x0, #0
    mov     x8, #93
    svc     #0


    .size   _start, . - _start
