.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 1.0.0
 * @brief
 *   Provides an interface to the random number generator
 *
 *   It is configured to use the MSI clock, so make sure you
 *   are either running a default clock setup or `clock_init`
 *   configured setup (or you know what you are doing).
 *
 * @pins {null}
 */


.global rng_init
.type rng_init, %function
rng_init:
    @ Enable RNG clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << RCC_AHB2ENR_RNGEN)
    str r1, [r0, RCC_AHB2ENR]

    @ Source RNG clock from MSI (48 MHz as per `clock_init`)
    ldr r1, [r0, RCC_CCIPR]
    orr r1, (0b11 << RCC_CCIPR_CLK48SEL)
    str r1, [r0, RCC_CCIPR]

    @ Enable RNG peripheral, disable interrupts
    ldr r0, =RNG
    ldr r1, [r0, RNG_CR]
    bic r1, (1 << RNG_CR_IE)
    orr r1, (1 << RNG_CR_RNGEN)
    str r1, [r0, RNG_CR]

    bx lr
.size rng_init, . - rng_init


/**
 * @param {null}
 * @return r0 - A 32 bit random number
 */
.global rng_get_number
.type rng_get_number, %function
rng_get_number:
    ldr r0, =RNG

    @ Wait until ready while checking for errors
    1:
    ldr r1, [r0, RNG_SR]
    tst r1, (1 << RNG_SR_CECS | 1 << RNG_SR_SECS)
    bne 2f
    tst r1, (1 << RNG_SR_DRDY)
    beq 1b

    @ Read generated random number
    ldr r0, [r0, RNG_DR]
    bx lr

    2:
    @ ERROR in CECS (clock) or SECS (faulty sequence)
    nop
    b 2b
.size rng_get_number, . - rng_get_number


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.set RCC, 0x40021000
    .set RCC_CR, 0x00
    .set RCC_AHB2ENR, 0x4C
        .set RCC_AHB2ENR_RNGEN, 18
    .set RCC_CCIPR, 0x88
        .set RCC_CCIPR_CLK48SEL, 26

.set RNG, 0x50060800
    .set RNG_CR, 0x0
        .set RNG_CR_RNGEN, 2
        .set RNG_CR_IE, 3
    .set RNG_SR, 0x4
        .set RNG_SR_DRDY, 0
        .set RNG_SR_CECS, 1
        .set RNG_SR_SECS, 2
    .set RNG_DR, 0x8
