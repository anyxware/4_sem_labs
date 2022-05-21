    .arch armv8-a
    .text
    .align 2

    .type   get_element, %function
// w2 - channels, w4 - tmp_buffer, w8 - a, w9 - b, w10 - c, w11 - channel
// w8 - tmp_buffer[(a * b + c) * channels]
get_element:
    madd    w8, w8, w9, w10
    madd    w8, w8, w2, w11
    ldrb    w8, [x4, w8, uxtw]
    ret
    .size   get_element, .-get_element

    .type   put_element, %function
put_element:
    mov     w8, w5
    sub     w8, w8, #1
    mov     w9, w0
    sub     w9, w9, #2
    madd    w8, w8, w9, w6
    sub     w8, w8, #1
    madd    w8, w8, w2, w11
    strb    w7, [x3, w8, uxtw]
    ret
    .size   put_element, .-put_element


    .type   calc_res, %function
// w0 - x + 2, w2 - channels, x4 - tmp_buffer, w5 - i, w6 - j, w11 - channel
// w7 - res
calc_res:
    mov     x19, x30

// 1)
    mov     w8, w5
    mov     w9, w0
    mov     w10, w6
    bl      get_element

    mov     w12, #8
    mul     w7, w8, w12

// 2)
    mov     w8, w5
    sub     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    sub     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

// 3)
    mov     w8, w5
    sub     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    bl      get_element

    subs    w7, w7, w8

// 4)
    mov     w8, w5
    sub     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    add     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

// 5)
    mov     w8, w5
    mov     w9, w0
    mov     w10, w6
    sub     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

// 6)
    mov     w8, w5
    mov     w9, w0
    mov     w10, w6
    add     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

// 7)
    mov     w8, w5
    add     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    sub     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

// 8)
    mov     w8, w5
    add     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    bl      get_element

    subs    w7, w7, w8

// 9)
    mov     w8, w5
    add     w8, w8, #1
    mov     w9, w0
    mov     w10, w6
    add     w10, w10, #1
    bl      get_element

    subs    w7, w7, w8

    mov     w8, #255
    mov     w9, #0
    csel    w7, w9, w7, mi
    cmp     w7, w8
    csel    w7, w8, w7, ge

    mov     x30, x19
    ret

    .size   calc_res, .-calc_res


    .global process_image_asm
    .type   process_image_asm, %function
// w0 - x + 2, w1 - y + 2, w2 - channels, w3 - buffer, w4 - tmp_buffer
// w5 - i, w6 - j, w7 - res, w8 w9 - temporary calcs
process_image_asm:
    mov     x18, x30 // save ret address
    add     w0, w0, #2
    add     w1, w1, #2

    mov     w5, #0
i_cycle:
    add     w5, w5, #1

    mov     w8, w1
    sub     w8, w8, #1
    cmp     w5, w8
    bge     end

    mov     w6, #0
j_cycle:
    add     w6, w6, #1

    mov     w8, w0
    sub     w8, w8, #1
    cmp     w6, w8
    bge     i_cycle

    mov     w11, #0
    bl      calc_res
    bl      put_element

    mov     w11, #1
    bl      calc_res
    bl      put_element

    mov     w11, #2
    bl      calc_res
    bl      put_element

    b       j_cycle

end:
    mov     x30, x18
    mov     x0, #0
    ret

    .size   process_image_asm, .-process_image_asm

