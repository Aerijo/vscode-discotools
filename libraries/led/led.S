.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 0.1.0
 * @brief
 *   Provides a thread safe interface with the user LEDs
 *
 *   By thread safe, I mean toggling the pins will not affect operations on
 *   unrelated pins. Naturally, odd things can still happen if two separate
 *   threads are both trying to toggle the one LED. Initialisation is not thread safe.
 *
 *   The LEDs are treated separately in all cases. You must run `led_<colour>_init` before
 *   using the LED of that colour. After, you can turn it on, off, or toggle it's state.
 *
 * @pins B2, E8
 */


@@@@@@@@@@@@
@@ Public @@
@@@@@@@@@@@@

.global led_red_init
.type led_red_init, %function
led_red_init:
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << 1)
    str r1, [r0, RCC_AHB2ENR]

    ldr r0, =GPIOB
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << 4)
    orr r1, (0b01 << 4)
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << 2)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << 4)
    orr r1, (0b10 << 4)
    str r1, [r0, GPIOx_PUPDR]

    bx lr
.size led_red_init, . - led_red_init


.global led_green_init
.type led_green_init, %function
led_green_init:
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << 4)
    str r1, [r0, RCC_AHB2ENR]

    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << 16)
    orr r1, (0b01 << 16)
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << 8)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << 16)
    orr r1, (0b10 << 16)
    str r1, [r0, GPIOx_PUPDR]

    bx lr
.size led_green_init, . - led_green_init


.global led_red_on
.type led_red_on, %function
led_red_on:
    ldr r0, =GPIOB
    ldr r1, =(1 << 2)
    str r1, [r0, GPIOx_BSRR]
    bx lr
.size led_red_on, . - led_red_on


.global led_red_off
.type led_red_off, %function
led_red_off:
    ldr r0, =GPIOB
    ldr r1, =(1 << 2)
    str r1, [r0, GPIOx_BSRR + 0x10]
    bx lr
.size led_red_off, . - led_red_off


.global led_red_toggle
.type led_red_toggle, %function
led_red_toggle:
    ldr r0, =GPIOB
    ldr r1, [r0, GPIOx_ODR]
    tst r1, (1 << 2)
    ldr r1, =(1 << 2)
    ite eq
    streq r1, [r0, GPIOx_BSRR]
    strne r1, [r0, GPIOx_BSRR + 0x10]
    bx lr
.size led_red_toggle, . - led_red_toggle


.global led_green_on
.type led_green_on, %function
led_green_on:
    ldr r0, =GPIOE
    ldr r1, =(1 << 8)
    str r1, [r0, GPIOx_BSRR]
    bx lr
.size led_green_on, . - led_green_on


.global led_green_off
.type led_green_off, %function
led_green_off:
    ldr r0, =GPIOE
    ldr r1, =(1 << 8)
    str r1, [r0, GPIOx_BSRR + 0x10]
    bx lr
.size led_green_off, . - led_green_off


.global led_green_toggle
.type led_green_toggle, %function
led_green_toggle:
    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_ODR]
    tst r1, (1 << 8)
    ldr r1, =(1 << 8)
    ite eq
    streq r1, [r0, GPIOx_BSRR]
    strne r1, [r0, GPIOx_BSRR + 0x10]
    bx lr
.size led_green_toggle, . - led_green_toggle


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.equiv RCC, 0x40021000
    .equiv RCC_AHB2ENR, 0x4C

.equiv GPIOB, 0x48000400
.equiv GPIOE, 0x48001000
    .equiv GPIOx_MODER, 0x0
    .equiv GPIOx_OTYPER, 0x4
    .equiv GPIOx_PUPDR, 0xC
    .equiv GPIOx_ODR, 0x14
    .equiv GPIOx_BSRR, 0x18