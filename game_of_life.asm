.text
coordinates: .byte 0x11, 0x12, 0x33, 0x23, 0x22 // ===> coordinates 0x[x][y] (do not enter a quantity that is a multiple of 4)
.align 0
.global _start
_start:

mov sp,#0 // reset the stack
mov r0,#0
mov r3,#0x10
mov r8,#0x4     // ***** number of iterations (the part that gets modified) *********** 
mov r5,#0x7     //<---- defines the dimensions of the matrix y-axis
mov r6,#0x9     //<---- defines the dimensions of the matrix x-axis
lsl r7, r6,#0x4     //<---- defines the dimensions of the matrix x-axis
add r7,r5      //<---- defines the dimensions of the matrix x-axis
add r5,#1
add r6,#1
sub r3,r5
mov r11,#0xaa  //<----- dead cells

ldr r1,=0x1000 //<---- matrix address
bl horizontal_frame   

ldr r1,=0x1010
mov r0,#0
bl vertical_frame

mov r0,#0
bl horizontal_frame

ldr r1,=coordinates 
bl initialize

mov r2,#0x0
mov r0,#0
ldr r1,=0x1011

play:                  //<--- function just to step over and see each generation of cells
    bl redraw
    cmp r0,r8
    add r0,#1
bne play
1:b 1b

initialize: ldrb r0,[r1],#1 //<---- extracts information from the coordinates string
    push {r1}
        ldr r1, =0x1000
        add r1,r0
        strb r11,[r1]  //<---- draw initial cells
    pop {r1}
    ldrb r0,[r1]
    cmp r0,#0
    moveq pc,lr
b initialize

horizontal_frame: ldr r2,=0x7e //<---- top and bottom of the matrix frame
    strb r2,[r1],#0x1
    cmp r0,r5    
    moveq pc,lr    
    and r0, r1, #0xf
b horizontal_frame

vertical_frame: cmp r0,r6  //<---- sides of the matrix frame
    ldr r2,=0x7c
    moveq pc,lr
    strb r2,[r1],#1
    center:     //<---- fill matrix with dead cells
        strb r10,[r1],#0x1
        and r0, r1, #0xf
        cmp r0,r5
    bne center 
    strb r2,[r1],r3
    and r0, r1, #0xff
    lsr r0,#0x4
b vertical_frame

redraw: ldr r2,=0x2000 
    push {lr,r0,r2}   	//<---- draw the next generation of cells in the matrix
    ldr r1,=0x1011
    matrix:            //<---- iterate through the matrix and analyze the neighbors of each cell or coordinate to determine its fate
        mov r12,#0
        ldrb r0,[r1]
        cmp r0,#0x7e
            cmpne r0,#0x7c
            blne analyze_cells //<---- check and count the number of live cells around each coordinate
        add r1,#1
        and r0,r1,#0xff
        cmp r0,r7             //<---- end of matrix
    bne matrix
    ldr r1,=0x1010
    bl vertical_frame  	//<---- redraw the matrix with only dead cells 
    ldr r2,=0x2000
    bl cells  	//<---- add the cells that are still alive or born within the matrix and remove those that died 
    pop {lr,r0,r2}
mov pc,lr

cells: ldr r0,[r2] //<----- draw the cells that were born or remained alive
    and r0,#0xff
    cmp r0,#0xaa
    moveq pc,lr
    ldr r1,[r2],#0x4
    strb r11,[r1]
b cells

analyze_cells: //<---- check and count the number of live cells around each coordinate
    //neighbors above
    push {lr}
        ldrb r0,[r1,#-0xf]
        bl count
        ldrb r0,[r1,#-0x10]
        bl count
        ldrb r0,[r1,#-0x11]
        bl count
    //neighbors below 
        ldrb r0,[r1,#0xf]
        bl count
        ldrb r0,[r1,#0x10]
        bl count
        ldrb r0,[r1,#0x11]
        bl count
    //side neighbors
        ldrb r0,[r1,#-0x1]
        bl count
        ldrb r0,[r1,#0x1]
        bl count
    pop {lr}
    ldrb r0,[r1]
    //Game of Life rules
    cmp r0, #0xaa		//<--- check if the analyzed coordinate is a live cell
        cmpeq r12,#2    //<--- check if the cell stays alive or dies
        streq r1,[r2],#4  
    cmp r12, #3
        streq r1,[r2],#4 //<--- a cell is born or stays alive (any other case other than the ones compared, the cell dies or simply does not born)
mov pc,lr

count:  		 //<------ function to count the number of live cells around a coordinate point
    cmp r0, r11
        addeq r12,#1
mov pc,lr
