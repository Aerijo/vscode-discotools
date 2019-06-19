.syntax unified

/**
 * This example demonstrates some syntax, like aliases for registers (using `.req`)
 * and temporary labels using `n:` and `b nf` (goto next `n`) or `b nb` (goto previous `n`),
 * where `n` is any integer.
 *
 * The actual effect is to have the LEDs toggling with random intervals.
 */

RED_COUNT   .req r4
GREEN_COUNT .req r5

.global main
.type main, %function
main:
    bl led_red_init
    bl led_green_init
    bl rng_init

    mov RED_COUNT, 0
    mov GREEN_COUNT, 0

    loop:

    cmp RED_COUNT, 0
    beq 1f

    sub RED_COUNT, 1
    b 2f

    1:
    bl rng_get_number
    and RED_COUNT, r0, 0b111
    bl led_red_toggle

    2:
    cmp GREEN_COUNT, 0
    beq 1f

    sub GREEN_COUNT, 1
    b 2f

    1:
    bl rng_get_number
    and GREEN_COUNT, r0, 0b111
    bl led_green_toggle

    2:
    ldr r0, =0x20000
    bl delay

    b loop
.size main, . - main


.type delay, %function
delay:
    subs r0, 1
    bne delay
    bx lr
.size delay, . - delay