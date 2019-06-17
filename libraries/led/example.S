.syntax unified


.global main
.type main, %function
main:
    bl led_red_init
    bl led_green_init

    bl led_red_on
    bl led_green_off

    loop:
    ldr r0, =0x100000
    bl delay

    bl led_red_toggle
    bl led_green_toggle

    b loop
.size main, . - main


.type delay, %function
delay:
    subs r0, 1
    bne delay
    bx lr
.size delay, . - delay