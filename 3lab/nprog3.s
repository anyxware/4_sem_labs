    .arch armv8-a

    .data

errmsg1:
    .string "Usage: "
    .equ    errlen1, .-errmsg1
errmsg2:
    .string " filename\n"
    .equ    errlen2, .-errmsg2
greet_data:
    .string "Enter smth: "
    .equ    greetlen, .-greet_data

    .text
    .align 2

    .global _start
    .type   _start, %function
_start:

// check count of cmd line args

    ldr     x0, [sp]
    cmp     x0, #2
    beq     2f
// if error
// print errmsg1
    mov     x0, #2
    adr     x1, errmsg1
    mov     x2, errlen1
    mov     x8, #64
    svc     #0
// print file name
    mov     x0, #2
    mov     x2, #0
    ldr     x1, [sp, #8]
0:
    ldrb    w3, [x1, x2]
    cbz     w3, 1f
    add     x2, x2, #1
    b       0b
1:
    mov     x8, #64
    svc     #0
// print errmsg2
    mov     x0, #2
    adr     x1, errmsg2
    mov     x2, errlen2
    mov     x8, #64
    svc     #0

    mov     x0, #1
    b       _exit
// if ok
2:
// load filename from cmdline parameters
    ldr     x0, [sp, #16]
// and start working
    bl work
_exit:
    mov     x8, #93
    svc     #0

    .size   _start, .-_start

    .type   work, %function
// reserve first 16 bytes for x29 and x30
// then address of filename, file descriptor and buffer address
    .equ    filename, 16
    .equ    fd, 24
    .equ    buf, 32
work:
    mov     x16, #48 // buf_size = 16 // buffer
    sub     sp, sp, x16
    stp     x29, x30, [sp]
    mov     x29, sp

    str     x0, [x29, filename] // store filename on stack
// open file
    mov     x1, x0
    mov     x0, #-100
    mov     x2, #0x201
    mov     x8, #56
    svc     #0

    cmp     x0, #0
    bge     0f //
    bl      writerr
    b       4f //

0:
    str     x0, [x29, fd]
1:
    mov     x0, #1
    adr     x1, greet_data
    mov     x2, greetlen
    mov     x8, #64
    svc     #0
// read data
    mov     x0, #0
    add     x1, x29, buf
    mov     x2, #16 // buffer
    mov     x8, #63
    svc     #0

    cmp     x0, #0
    beq     4f // EOF
    bgt     2f // OK

// error
    ldr     x0, [sp], #16
    bl      writerr
    b       3f

2:
// correct the line
    add     x0, x29, buf // buffer as an argument
    ldr     x1, [x29, fd] // and fd
    bl      correct

// write data to a file
    mov     x2, x0
    ldr     x0, [x29, fd]
    add     x1, x29, buf
    mov     x8, #64
    svc     #0

    b       1b

3:
// close file, got error
    ldr     x0, [x29, fd]
    mov     x8, #57
    svc     #0
    mov     x0, #1
    b       5f
4:
// close file, all ok
    ldr     x0, [x29, fd]
    mov     x8, #57
    svc     #0
    mov     x0, #0
5:
    ldp     x29, x30, [sp]
    mov     x16, #48
    add     sp, sp, x16
    ret

    .size   work, .-work

    .type   writeerr, %function

    .data
nofile:
    .string "No such file or directory\n"
    .equ    nofilelen, .-nofile
permission:
    .string "Permission denied\n"
    .equ    permissionlen, .-permission
unknown:
    .string "Unknown error\n"
    .equ    unknownlen, .-unknown

    .text
    .align 2

writerr:
    cmp     x0, #-2
    bne     0f
    adr     x1, nofile
    mov     x2, nofilelen
    b       2f
0:
    cmp     x0, #-13
    bne     1f
    adr     x1, permission
    mov     x2, permissionlen
    b       2f
1:
    adr     x1, unknown
    mov     x2, unknownlen
2:
    mov     x0, #2
    mov     x8, #64
    svc     #0
    ret

    .size   writerr, .-writerr

    .type   correct, %function
    .equ    buf_addr, 16
    .equ    fd_out, 24
correct:
    sub     sp, sp, #32
    stp     x29, x30, [sp]
    mov     x29, sp
    str     x0, [x29, buf_addr]
    str     x1, [x29, fd]

    mov     x1, x0 // uncorrected string
    mov     x2, x0 // corrected string
    mov     x10, #0 // buffer size counter
    mov     x19, #0 // another buffer size counter
// skip spaces before the first word

0:
    ldrb    w3, [x1], #1
    add     x10, x10, #1
    add     x19, x19, #1

    cmp     w3, ' '
    beq     0b
    cmp     w3, '\t'
    beq     0b
    cmp     w3, '\n'
    beq     end_of_line

    sub     x1, x1, #1
    sub     x10, x10, #1
    sub     x19, x19, #1

// go to the end of the first word
1:
    ldrb    w3, [x1], #1
    add     x10, x10, #1
    add     x19, x19, #1

    cmp     w3, ' '
    beq     add_space
    cmp     w3, '\t'
    beq     add_space
    cmp     w3, '\n'
    beq     end_of_line

    mov     w4, w3
    strb    w4, [x2], #1

    mov     x12, #16
    cmp     x19, x12
    #beq     string_more_than_buffer
    beq     add_space

    b       1b
// now last symbol is in the w4
add_space:
// add space after word
    mov     w3, ' '
    strb    w3, [x2], #1

    mov     x12, #16
    cmp     x19, x12
    beq     string_more_than_buffer

2:
// skip spaces before another word
    mov     x11, #0
3:
    ldrb    w3, [x1], #1
    add     x10, x10, #1

    mov     x12, #16
    cmp     x10, x12
    beq     string_more_than_buffer

    cmp     w3, ' '
    beq     3b
    cmp     w3, '\t'
    beq     3b
    cmp     w3, '\n'
    beq     end_of_line

    sub     x1, x1, #1
    sub     x10, x10, #1

// go to the end of another word and compare last symbol
// and save the beginning of the word
    mov     x6, x1
4:
    ldrb    w3, [x1], #1
    add     x10, x10, #1
    add     x11, x11, #1

    mov     x12, #16
    cmp     x10, x12
    beq     string_more_than_buffer

    cmp     w3, ' '
    beq     5f
    cmp     w3, '\t'
    beq     5f
    cmp     w3, '\n'
    beq     5f

    mov     w5, w3
    b       4b
// now the last word's symbol is in the w5
// compare w4 and w5, if they're equal, write this word to the buffer, else go to the next word
5:
    cmp     w4, w5
    beq     have_same_symbol
    cmp     w3, ' '
    beq     2b
    cmp     w3, '\t'
    beq     2b
    cmp     w3, '\n'
    beq     end_of_line

have_same_symbol:
    mov     x1, x6

// write word
6:
    ldrb    w3, [x1], #1
    cmp     w3, ' '
    beq     7f
    cmp     w3, '\t'
    beq     7f
    cmp     w3, '\n'
    beq     end_of_line

    strb    w3, [x2], #1
    b       6b
// add space to the end
// and go to the next
7:
    mov     w3, ' '
    strb    w3, [x2], #1

    b       2b

string_more_than_buffer:
// save address of the beggining of the last word
    sub     x10, x1, x11
// write data to a file
    ldr     x0, [x29, fd_out]
    ldr     x1, [x29, buf_addr]
    sub     x2, x2, x1
    mov     x8, #64
    svc     #0
// copy part of not whole data to the beginning
    mov     x12, #0
0:
    cmp     x11, x12
    beq     1f
    ldrb    w3, [x10], #1
    strb    w3, [x1], #1
    add     x12, x12, #1
    b       0b
1:
// read new part of data
    mov     x0, #0
    // buf addr already in the x1
    mov     x2, #16
    sub     x2, x2, x11 // 16 - len
    mov     x8, #63
    svc     #0
// init pointers and read data size
    ldr     x1, [x29, buf_addr]
    ldr     x2, [x29, buf_addr]
    mov     x10, #0

// and go ahead
    b       2b


// if end of line was reached
end_of_line:
    ldr     w3, [x2, #-1]!
    cmp     w3, ' '
    bne     all_ok
    sub     x2, x2, #1

all_ok:
    add     x2, x2, #1
    mov     w3, '\n'
    strb    w3, [x2], #1

    ldr     x0, [x29, buf_addr]
    sub     x0, x2, x0 // return size of buffer

    mov     sp, x29
    ldp     x29, x30, [sp]
    add     sp, sp, #32

    ret


    .size   correct, .-correct

