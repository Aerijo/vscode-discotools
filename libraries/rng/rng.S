.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 0.1.0
 * @brief
 *   Provides an interface to the random number generator
 *
 *   Currently configured to use the MSI clock, which is the
 *   default system clock. This library may break if the system
 *   clock is changed. It also does not detect errors properly.
 *
 * @pins {null}
 */


.global rng_init
.type rng_init, %function
rng_init:
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << RCC_AHB2ENR_RNGEN)
    str r1, [r0, RCC_AHB2ENR]

    ldr r1, [r0, RCC_CCIPR]
    orr r1, (0b11 << RCC_CCIPR_CLK48SEL) @ Use MSI clock (default system clock)
    str r1, [r0, RCC_CCIPR]

    ldr r0, =RNG
    ldr r1, [r0, RNG_CR]
    bic r1, (1 << RNG_CR_IE) @ disable interrupts
    orr r1, (1 << RNG_CR_RNGEN) @ enable RNG
    str r1, [r0, RNG_CR]

    bx lr
.size rng_init, . - rng_init


.global rng_get_number
.type rng_get_number, %function
rng_get_number:
    ldr r0, =RNG

    try_ready:
    ldr r1, [r0, RNG_SR]
    tst r1, (1 << RNG_SR_DRDY)
    beq try_ready

    ldr r0, [r0, RNG_DR]
    bx lr
.size rng_get_number, . - rng_get_number


.equiv RCC, 0x40021000
    .equiv RCC_CR, 0x00
    .equiv RCC_AHB2ENR, 0x4C
        .equiv RCC_AHB2ENR_RNGEN, 18
    .equiv RCC_CCIPR, 0x88
        .equiv RCC_CCIPR_CLK48SEL, 26

.equiv RNG, 0x50060800
    .equiv RNG_CR, 0x0
        .equiv RNG_CR_RNGEN, 2
        .equiv RNG_CR_IE, 3
    .equiv RNG_SR, 0x4
        .equiv RNG_SR_DRDY, 0
    .equiv RNG_DR, 0x8