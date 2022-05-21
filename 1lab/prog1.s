//res=a*c/b+d*b/e-c*c/a/d

	.arch armv8-a

	.data

	    .align	3
res:	.skip 	8
a:	    .short	10
b:	    .short 	0
c:	    .short 	0
d:	    .short 	12
e:	    .short 	13

	.global _start
	.type 	_start, %function

	.text

	.align 	2
_start:
	// load operands
	adr	    x0, a
	ldrsh	w1, [x0]
	adr	    x0, b
	ldrsh	w2, [x0]
	adr	    x0, c
	ldrsh	w3, [x0]
	adr	    x0, d
	ldrsh	w4, [x0]
	adr	    x0, e
	ldrsh	w5, [x0]

	// check if some operands are zero's
	cbz	    w1, _bad_exit
	cbz	    w2, _bad_exit
	cbz	    w4, _bad_exit
	cbz	    w5, _bad_exit

	// p1 = a * c / b
	mul	    w6, w1, w3
	sdiv	w7, w6, w2
    // p2 = d * b / e
	mul	    w8, w4, w2
	sdiv	w9, w8, w5
	// p3 = (c * c) / (a * d)
	mul	    w2, w3, w3
	mul	    w5, w1, w4
	sdiv	w1, w2, w5
    // 0 + p1 + p2 - p3
    mov     x20, #0
	add     x7, x20, w7, sxtw
    add	    x2, x7, w9, sxtw
	subs	x3, x2, w1, sxtw

	// get result
	adr	    x0, res
	str	    x3, [x0]
    mov     x0, #0
    b       _exit
_bad_exit:
    mov	    x0, #1
_exit:
    mov	    x8, #93
	svc	    #0

	.size 	_start, .-_start
