.syntax unified


.data
hello_world: .asciz "'HELLO, WORLD'"
alphabet:    .asciz "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
.text


.global main
.type main, %function
main:
    bl lcd_init

    ldr r0, =hello_world
    ldr r1, =3
    bl lcd_write_string
    bl lcd_update_display

    @ display shows "   'HE"

    ldr r0, =2000000
    delay_loop1:
    subs r0, 1
    bne delay_loop1

    bl lcd_clear
    bl lcd_update_display

    @ display empty

    ldr r0, =2000000
    delay_loop2:
    subs r0, 1
    bne delay_loop2

    ldr r0, =hello_world
    ldr r1, =2 @ scroll twice
    ldr r2, =200000 @ do this many single operations between updates
    bl lcd_write_scroll

    @ display scrolls "'HELLO, WORLD'" twice quickly

    ldr r0, =alphabet
    ldr r1, =0x7FFFFFFF @ max signed int repetitions
    ldr r2, =0  @ default scroll speed
    bl lcd_write_scroll

    @ display scrolls the alphabet + numbers effectively indefinitely
.size main, . - main