    .arch armv8-a
// Calculate sin(x)
    .data
pi:
    .double 3.14159265358979
msgX:
    .string "Input x: "
msgDelta:
    .string "Input delta: "
msg2:
    .string "%lf"
msg3:
    .string "sin(%.17g)=%.17g\n"
msg4:
    .string "mysin(%.17g)=%.17g\n"
usage:
    .string "Usage: %s filename\n"
mode:
    .string "w"
print_element:
    .string "%.0lf %.17g\n"

    .text
    .align 2
    .type   mysin, %function
// x0 - filestruct, d0 - res, d1 - delta, d2 - prev value, d3 - prev delta, [, d4 - x, d5 - counter]
mysin:
    stp     x29, x30, [sp, #-16]!

    fmov    d4, d0          // x
    fmov    d5, xzr         // 0
    fmov    d10, #1.0       // 1
    adr     x2, pi
    ldr     x2, [x2]
    fmov    d9, x2          // pi

0:
    fadd    d5, d5, d10    // n++
    fmov    d2, d0         // save previous value
    fmov    d3, d6         // save previous correction

// calc current element
    fmul    d6, d4, d4      // x**2      (1)
    fmul    d7, d5, d5      // n**2      (2)
    fmul    d11, d9, d9     // pi**2     (3)
    fmul    d11, d7, d11    // (2)*(3)   (4)
    fdiv    d11, d6, d11    // (1)/(4)   (5)
    fsub    d11, d10, d11   // 1-(5)     (6)
    fmul    d0, d0, d11     // S*=(6)    (7)

// save values on stack
    sub     sp, sp, #56
    stp     d0, d1, [sp]
    stp     d2, d3, [sp, #16]
    stp     d4, d5, [sp, #32]
    str     x0, [sp, #48]
// write to file
    // filestruct already in x0
    adr     x1, print_element
    fmov    d0, d5          // n
    fmov    d1, d11         // element
    bl      fprintf
// load values from stack
    ldp     d0, d1, [sp]
    ldp     d2, d3, [sp, #16]
    ldp     d4, d5, [sp, #32]
    ldr     x0, [sp, #48]
    add     sp, sp, #56

// check could cycle be broken
    fsub    d6, d0, d2
    fabs    d6, d6
    fsub    d7, d6, d3
    fabs    d7, d7

    fcmp    d7, d1
    bge     0b

    #fsub    d6, d11, d2     // dXn = An - An-1
    #fabs    d6, d6          // abs(dXn) correction
    #fsub    d7, d6, d3      // e = dXn - dXn-1
    #fabs    d7, d7          // abs(e)  delta of corrections

    #fcmp    d7, d1
    #bge     0b

    ldp     x29, x30, [sp], #16
    ret
    .size   mysin, .-mysin

    .text
    .align 2
    .global main
    .type   main, %function

    .equ    val, 16
    .equ    delta, 24
    .equ    sine, 32
    .equ    mysine, 40
    .equ    progname, 48
    .equ    filename, 56
    .equ    filestruct, 64

main:
// save registers I will change
    stp     x29, x30, [sp, #-72]!
    mov     x29, sp

    cmp     w0, #2
    beq     preparation

// print usage message if wrong usage
    ldr     x2, [x1]
    adr     x0, stderr
    ldr     x0, [x0]
    adr     x1, usage
    bl      fprintf

    mov     w0, #1
    b       exit

preparation:
    ldr     x0, [x1]
    str     x0, [x29, progname]
    ldr     x0, [x1, #8]
    str     x0, [x29, filename]
    adr     x1, mode
    bl      fopen
    cbnz    x0, work

// print about error
    ldr     x0, [x29, filename]
    bl      perror
    mov     w0, #1
    b       exit

work:

// save filestruct
    str     x0, [x29, filestruct]

// read value
    adr     x0, msgX
    bl      printf
    adr     x0, msg2
    add     x1, x29, val
    bl      scanf

// read delta
    adr     x0, msgDelta
    bl      printf
    adr     x0, msg2
    add     x1, x29, delta
    bl      scanf

// calc sine with func from libc
// and save it on the stack
    ldr     d0, [x29, val]
    bl      sin
    str     d0, [x29, sine]

// calc sine with my func
// and save it too
    ldr     x0, [x29, filestruct]
    ldr     d0, [x29, val]
    ldr     d1, [x29, delta]
    bl      mysin
    str     d0, [x29, mysine]

// display values
    adr     x0, msg3
    ldr     d0, [x29, val]
    ldr     d1, [x29, sine]
    bl      printf

    adr     x0, msg4
    ldr     d0, [x29, val]
    ldr     d1, [x29, mysine]
    bl      printf

// close file
    ldr     x0, [x29, filestruct]
    bl      fclose

exit:
    ldp     x29, x30, [sp], #72
    mov     w0, #0
    ret
    .size   main, .-main




