.syntax unified

/**
 * @author   Benjamin Gray (u6677379)
 * @license  MIT
 * @version  0.1.0
 * @brief
 *   Provides an interface to the onboard LCD
 *
 *   The hardware facing end of this LCD library is largely a translation of
 *   https://github.com/frisnit/STM32L476-radar/blob/master/software/STM32-radar/STM32L476G-Discovery/stm32l476g_discovery_glass_lcd.c
 *   from C to Assembly.
 *
 * @pins A6--A10, A15, B0, B1, B4, B5, B9, B12--B15, C3--C8, D8--D15
 *
 * @interface
 * - `lcd_init`: call this once at the start of your program, like with the audio init function.
 *        Doing so sets up the necessary GPIO pins in the correct modes to interface with the LCD,
 *        sets up the right clock, etc. You can see exactly what it does by reading it's definition.
 *
 * - `lcd_update_display`: Updates the physical display. The effects of most of the following
 *        functions will not be seen until this function is called.
 *
 * - `lcd_clear`: Wipes the display. Note it only wipes the RAM values; you need to call
 *        `lcd_update_display` afterwards to update the display.
 *
 * - `lcd_write_raw`: You probably won't need this one; it allows you to specify exactly which
 *        segments for a given position are activated, but the relationship between the segments and
 *        the bits is kind of weird. See [this section of the C library](https://github.com/frisnit/STM32L476-radar/blob/master/software/STM32-radar/STM32L476G-Discovery/stm32l476g_discovery_glass_lcd.c#L81)
 *        for how it works & what segments are available
 *
 * - `lcd_decode_ascii`: Converts an ASCII value to the encoding needed by `lcd_write_raw`. Will
 *        work on all alphanumeric characters, and many special characters. Read the definition to
 *        see what special characters are allowed.
 *
 * - `lcd_write_char`: Write an ASCII character to a position. Also allows the 10th and 9th bits to
 *        set the period and colon respectively (note this will set the bars instead if the position
 *        is one of the last two)
 *
 * - `lcd_write_string`: Writes up to 6 ASCII characters to the display, starting at the provided
 *        position, and null terminated (the character `0x00` marks the end of the string). Note the
 *        6 character limit means null termination only matters for strings of length 5 or less.
 *
 * - `lcd_write_scroll`: Writes an arbitrarily long null terminated string to the display, scrolling
 *        at a given speed and repeating a given number of times. Unlike the other display functions,
 *        this one will update the display immediately and will block all execution until it is done.
 *        There is currently no way to stop it (but I might look into using the joystick to interrupt it).
 */


@@@@@@@@@@@@@@@@@@@@
@@ User constants @@
@@@@@@@@@@@@@@@@@@@@

.eqv DEFAULT_SCROLL_SPEED, 400000 @ I found 200000 to be a close lower bound to how quickly it can draw with default settings


@@@@@@@@@@@@@@@@@
@@ Error codes @@
@@@@@@@@@@@@@@@@@

/** These will be in register r1, and hopefully be displayed on the LCD itself too */
.equiv LCD_ERROR_DISPLAY_POSITION, 1 @ position is not in range 0--5
.equiv LCD_ERROR_ASCII_DECODE, 2 @ could not decode into displayable ASCII

/*
If you see an unlisted error, either the board has grown self aware (unlikely) or
I forgot to set an error code (likely).
*/


@@@@@@@@@@@@
@@ Public @@
@@@@@@@@@@@@

/**
 * Initialises everything necessary to use the LCD.
 * See [BSP_LCD_GLASS_Init](#1) for the C version
 *
 * Note that some delays have been removed. If this
 * is found to cause issues, they can be added back.
 *
 * @param {null}
 * @return {null}
 */
.global lcd_init
.type lcd_init, %function
lcd_init:
    push {lr}

    /** #1 Enable PWR peripheral Clock */
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, 1 << RCC_APB1ENR1_PWREN
    str r1, [r0, RCC_APB1ENR1]
    @ bl delay

    /** #2 Configure LSE as RTC clock source */
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    orr r1, 1 << PWR_CR1_DBP
    str r1, [r0, PWR_CR1]
    bl wait_for_PWR_CR1_DBP

    ldr r0, =RCC
    ldr r1, [r0, RCC_BDCR]
    orr r1, 1 << RCC_BDCR_LSEON
    str r1, [r0, RCC_BDCR]
    bl wait_for_RCC_BDCR_LSERDY

    /** #3 Select LSE as RTC clock source */
    @ NOTE: duplicates above
    @ ldr r0, =PWR
    @ ldr r1, [r0, PWR_CR1]
    @ orr r1, 1 << PWR_CR1_DBP
    @ str r1, [r0, PWR_CR1]
    @ bl wait_for_PWR_CR1_DBP

    ldr r0, =RCC
    ldr r1, [r0, RCC_BDCR]
    and r2, r1, 0b11 << RCC_BDCR_RTCSEL
    orr r3, r2, 0b01 << RCC_BDCR_RTCSEL
    cmp r2, r3
    it ne
    blne reset_backup_domain

    ldr r0, =RCC
    ldr r1, [r0, RCC_BDCR]
    bic r1, 0b11 << RCC_BDCR_RTCSEL
    orr r1, 0b01 << RCC_BDCR_RTCSEL
    str r1, [r0, RCC_BDCR]

    /** #4 Enable LCD GPIO Clocks */
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR] @ NOTE: Original enables one at a time, with delay
    orr r1, (1 << RCC_AHB2ENR_GPIOAEN | 1 << RCC_AHB2ENR_GPIOBEN | 1 << RCC_AHB2ENR_GPIOCEN | 1 << RCC_AHB2ENR_GPIODEN)
    str r1, [r0, RCC_AHB2ENR]
    @ bl delay

    /** #5 Configure peripheral GPIO */
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ldr r0, =GPIOA

        ldr r1, [r0, GPIOx_AFRL]
        bic r1, 0xFF000000
        orr r1, 0xBB000000
        str r1, [r0, GPIOx_AFRL]
        ldr r1, [r0, GPIOx_AFRH]
        ldr r2, =0xF0000FFF
        bic r1, r2
        ldr r2, =0xB0000BBB
        orr r1, r2
        str r1, [r0, GPIOx_AFRH]

        ldr r1, [r0, GPIOx_MODER]
        ldr r2, =0b11000000001111111111000000000000
        bic r1, r2
        ldr r2, =0b10000000001010101010000000000000
        orr r1, r2
        str r1, [r0, GPIOx_MODER]

        ldr r1, [r0, GPIOx_OSPEEDR]
        ldr r2, =0b11000000001111111111000000000000
        orr r1, r2
        str r1, [r0, GPIOx_OSPEEDR]

        ldr r1, [r0, GPIOx_OTYPER]
        ldr r2, =0b1000011111000000
        bic r1, r2
        str r1, [r0, GPIOx_OTYPER]

        ldr r1, [r0, GPIOx_PUPDR]
        ldr r2, =0b11000000001111111111000000000000
        bic r1, r2
        str r1, [r0, GPIOx_PUPDR]

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ldr r0, =GPIOB

        ldr r1, [r0, GPIOx_AFRL]
        bic r1, 0x00FF00FF
        orr r1, 0x00BB00BB
        str r1, [r0, GPIOx_AFRL]
        ldr r1, [r0, GPIOx_AFRH]
        ldr r2, =0xFFFF00F0
        bic r1, r2
        ldr r2, =0xBBBB00B0
        orr r1, r2
        str r1, [r0, GPIOx_AFRH]

        ldr r1, [r0, GPIOx_MODER]
        ldr r2, =0b11111111000011000000111100001111
        bic r1, r2
        ldr r2, =0b10101010000010000000101000001010
        orr r1, r2
        str r1, [r0, GPIOx_MODER]

        ldr r1, [r0, GPIOx_OSPEEDR]
        ldr r2, =0b11111111000011000000111100001111
        orr r1, r2
        str r1, [r0, GPIOx_OSPEEDR]

        ldr r1, [r0, GPIOx_OTYPER]
        ldr r2, =0b1111001000110011
        bic r1, r2
        str r1, [r0, GPIOx_OTYPER]

        ldr r1, [r0, GPIOx_PUPDR]
        ldr r2, =0b11111111000011000000111100001111
        bic r1, r2
        str r1, [r0, GPIOx_PUPDR]

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ldr r0, =GPIOC

        ldr r1, [r0, GPIOx_AFRL]
        ldr r2, =0xFFFFF000
        bic r1, r2
        ldr r2, =0xBBBBB000
        orr r1, r2
        str r1, [r0, GPIOx_AFRL]
        ldr r1, [r0, GPIOx_AFRH]
        bic r1, 0x0000000F
        orr r1, 0x0000000B
        str r1, [r0, GPIOx_AFRH]

        ldr r1, [r0, GPIOx_MODER]
        ldr r2, =0b00000000000000111111111111000000
        bic r1, r2
        ldr r2, =0b00000000000000101010101010000000
        orr r1, r2
        str r1, [r0, GPIOx_MODER]

        ldr r1, [r0, GPIOx_OSPEEDR]
        ldr r2, =0b00000000000000111111111111000000
        orr r1, r2
        str r1, [r0, GPIOx_OSPEEDR]

        ldr r1, [r0, GPIOx_OTYPER]
        ldr r2, =0b0000000111111000
        bic r1, r2
        str r1, [r0, GPIOx_OTYPER]

        ldr r1, [r0, GPIOx_PUPDR]
        ldr r2, =0b00000000000000111111111111000000
        bic r1, r2
        str r1, [r0, GPIOx_PUPDR]

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ldr r0, =GPIOD

        ldr r1, =0xBBBBBBBB
        str r1, [r0, GPIOx_AFRH]

        ldr r1, [r0, GPIOx_MODER]
        ldr r2, =0b11111111111111110000000000000000
        bic r1, r2
        ldr r2, =0b10101010101010100000000000000000
        orr r1, r2
        str r1, [r0, GPIOx_MODER]

        ldr r1, [r0, GPIOx_OSPEEDR]
        ldr r2, =0b11111111111111110000000000000000
        orr r1, r2
        str r1, [r0, GPIOx_OSPEEDR]

        ldr r1, [r0, GPIOx_OTYPER]
        ldr r2, =0b1111111100000000
        bic r1, r2
        str r1, [r0, GPIOx_OTYPER]

        ldr r1, [r0, GPIOx_PUPDR]
        ldr r2, =0b11111111111111110000000000000000
        bic r1, r2
        str r1, [r0, GPIOx_PUPDR]

    @ bl delay_for_two_ms

    /** #6 Enable LCD peripheral Clock */
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, 1 << RCC_APB1ENR1_LCDEN
    str r1, [r0, RCC_APB1ENR1]
    @ bl delay

    /** #7 Disable peripheral */
    ldr r0, =LCD
    ldr r1, [r0, LCD_CR]
    bic r1, 1 << LCD_CR_LCDEN
    str r1, [r0, LCD_CR]

    /** #8 Clear the RAM */
    bl lcd_clear

    /** #9 Enable display request */
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    orr r1, 1 << LCD_SR_UDR
    str r1, [r0, LCD_SR]

    /** #10 Set the Prescaler, Divider, Blink Mode, and Blink Frequency */
    ldr r1, [r0, LCD_FCR]
    ldr r2, =0b11111111111111111111110001
    bic r1, r2
    ldr r2, =0b00001111000101010001000000
    orr r1, r2
    str r1, [r0, LCD_FCR]
    bl wait_for_LCD_SR_FCRSF

    /** #11 Set the Duty, Bias, Voltage Source, Multiplexity */
    ldr r0, =LCD
    ldr r1, [r0, LCD_CR]
    ldr r2, =0b011111110
    bic r1, r2
    ldr r2, =0b001001100
    orr r1, r2
    str r1, [r0, LCD_CR]

    /** #12 Enable the peripheral */
    ldr r1, [r0, LCD_CR]
    orr r1, 1 << LCD_CR_LCDEN
    str r1, [r0, LCD_CR]
    bl wait_for_LCD_SR_ENS
    bl wait_for_LCD_SR_RDY

    pop {pc}
.size lcd_init, . - lcd_init


/**
 * Writes the encoded data (r0) into the given position (r1).
 * E.g., `ldr r0, =0xFE00; mov r1, 0; bl lcd_write` will prepare
 * the first position to display an `A`
 *
 * Note the display is not updated yet; you need to call
 * {lcd_update_display} to display what has been written.
 *
 * @param r0: 16 bits encoded output (e.g., 'A' = 0xFE00)
 * @param r1: position [0..5] (left to right)
 * @return {null}
 */
.global lcd_write_raw
.type lcd_write_raw, %function
lcd_write_raw:
    push {r4, lr}
    push {r0, r1}

    cmp r1, 5
    bls 1f

    mov r1, LCD_ERROR_DISPLAY_POSITION
    bl lcd_error

    1:
    bl wait_for_reset_LCD_SR_UDR

    pop {r0, r1}
    ldr r3, =LCD

    tbh [pc, r1, LSL 1]
    1:
    .hword (0f - 1b) / 2
    .hword (1f - 1b) / 2
    .hword (2f - 1b) / 2
    .hword (3f - 1b) / 2
    .hword (4f - 1b) / 2
    .hword (5f - 1b) / 2

    0:
        ldr r4, =LCD_DIGIT1_SEG_MASK

        and r2, r0, 0x1000
        lsr r2, 8 @ LCD_SEG0_SHIFT
        mov r1, r2
        and r2, r0, 0x2000
        lsl r2, 10 @ LCD_SEG1_SHIFT
        orr r1, r2
        and r2, r0, 0x4000
        lsl r2, 8 @ LCD_SEG22_SHIFT
        orr r1, r2
        and r2, r0, 0x8000
        lsr r2, 12 @ LCD_SEG23_SHIFT
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x0100
        lsr r2, 4 @ LCD_SEG0_SHIFT
        mov r1, r2
        and r2, r0, 0x0200
        lsl r2, 14 @ LCD_SEG1_SHIFT
        orr r1, r2
        and r2, r0, 0x0400
        lsl r2, 12 @ LCD_SEG22_SHIFT
        orr r1, r2
        and r2, r0, 0x0800
        lsr r2, 8 @ LCD_SEG23_SHIFT
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0010
        @ lsr r2, 0 @ LCD_SEG0_SHIFT
        mov r1, r2
        and r2, r0, 0x0020
        lsl r2, 18 @ LCD_SEG1_SHIFT
        orr r1, r2
        and r2, r0, 0x0040
        lsl r2, 16 @ LCD_SEG22_SHIFT
        orr r1, r2
        and r2, r0, 0x0080
        lsr r2, 4 @ LCD_SEG23_SHIFT
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0001
        lsl r2, 4 @ LCD_SEG0_SHIFT
        mov r1, r2
        and r2, r0, 0x0002
        lsl r2, 22 @ LCD_SEG1_SHIFT
        orr r1, r2
        and r2, r0, 0x0004
        lsl r2, 20 @ LCD_SEG22_SHIFT
        orr r1, r2
        and r2, r0, 0x0008
        @ lsr r2, 0 @ LCD_SEG23_SHIFT
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

    b 900f

    1:
        ldr r4, =LCD_DIGIT2_SEG_MASK

        and r2, r0, 0x1000
        lsr r2, 6 @ LCD_SEG2_SHIFT == 6
        mov r1, r2
        and r2, r0, 0x2000
        @ lsr r2, 0 @ LCD_SEG3_SHIFT == 13
        orr r1, r2
        and r2, r0, 0x4000
        lsr r2, 2 @ LCD_SEG20_SHIFT == 12
        orr r1, r2
        and r2, r0, 0x8000
        lsr r2, 10 @ LCD_SEG21_SHIFT == 5
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x0100
        lsr r2, 2 @ LCD_SEG2_SHIFT == 6
        mov r1, r2
        and r2, r0, 0x0200
        lsl r2, 4 @ LCD_SEG3_SHIFT == 13
        orr r1, r2
        and r2, r0, 0x0400
        lsl r2, 2 @ LCD_SEG20_SHIFT == 12
        orr r1, r2
        and r2, r0, 0x0800
        lsr r2, 6 @ LCD_SEG21_SHIFT == 5
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0010
        lsl r2, 2 @ LCD_SEG2_SHIFT == 6
        mov r1, r2
        and r2, r0, 0x0020
        lsl r2, 8 @ LCD_SEG3_SHIFT == 13
        orr r1, r2
        and r2, r0, 0x0040
        lsl r2, 6 @ LCD_SEG20_SHIFT == 12
        orr r1, r2
        and r2, r0, 0x0080
        lsr r2, 2 @ LCD_SEG21_SHIFT == 5
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0001
        lsl r2, 6 @ LCD_SEG2_SHIFT == 6
        mov r1, r2
        and r2, r0, 0x0002
        lsl r2, 12 @ LCD_SEG3_SHIFT == 13
        orr r1, r2
        and r2, r0, 0x0004
        lsl r2, 10 @ LCD_SEG20_SHIFT == 12
        orr r1, r2
        and r2, r0, 0x0008
        lsl r2, 2 @ LCD_SEG21_SHIFT == 5
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

    b 900f

    2:
        ldr r4, =LCD_DIGIT3_SEG_MASK

        and r2, r0, 0x1000
        lsl r2, 3 @ LCD_SEG4_SHIFT == 15
        mov r1, r2
        and r2, r0, 0x2000
        lsl r2, 16 @ LCD_SEG5_SHIFT == 29
        orr r1, r2
        and r2, r0, 0x4000
        lsl r2, 14 @ LCD_SEG18_SHIFT == 28
        orr r1, r2
        and r2, r0, 0x8000
        lsr r2, 1 @ LCD_SEG19_SHIFT == 14
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x0100
        lsl r2, 7 @ LCD_SEG4_SHIFT == 15
        mov r1, r2
        and r2, r0, 0x0200
        lsl r2, 20 @ LCD_SEG5_SHIFT == 29
        orr r1, r2
        and r2, r0, 0x0400
        lsl r2, 18 @ LCD_SEG18_SHIFT == 28
        orr r1, r2
        and r2, r0, 0x0800
        lsl r2, 3 @ LCD_SEG19_SHIFT == 14
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0010
        lsl r2, 11 @ LCD_SEG4_SHIFT == 15
        mov r1, r2
        and r2, r0, 0x0020
        lsl r2, 24 @ LCD_SEG5_SHIFT == 29
        orr r1, r2
        and r2, r0, 0x0040
        lsl r2, 22 @ LCD_SEG18_SHIFT == 28
        orr r1, r2
        and r2, r0, 0x080
        lsl r2, 7 @ LCD_SEG19_SHIFT == 14
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0001
        lsl r2, 15 @ LCD_SEG4_SHIFT == 15
        mov r1, r2
        and r2, r0, 0x0002
        lsl r2, 28 @ LCD_SEG5_SHIFT == 29
        orr r1, r2
        and r2, r0, 0x0004
        lsl r2, 26 @ LCD_SEG18_SHIFT == 28
        orr r1, r2
        and r2, r0, 0x008
        lsl r2, 11 @ LCD_SEG19_SHIFT == 14
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

    b 900f

    3:
        and r2, r0, 0x1000
        lsl r2, 19 @ LSD_SEG6 == 31
        mov r1, r2
        and r2, r0, 0x8000
        lsl r2, 15 @ LSD_SEG17 == 30
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0]
        ldr r4, =LCD_DIGIT4_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x2000
        lsr r2, 12 @ LSD_SEG7 == 1
        mov r1, r2
        and r2, r0, 0x4000
        lsr r2, 14 @ LSD_SEG16 == 0
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM0_1]
        ldr r4, =LCD_DIGIT4_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM0_1]

        and r2, r0, 0x0100
        lsl r2, 23 @ LSD_SEG6 == 31
        mov r1, r2
        and r2, r0, 0x0800
        lsl r2, 19 @ LSD_SEG17 == 30
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        ldr r4, =LCD_DIGIT4_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0200
        lsr r2, 8 @ LSD_SEG7 == 1
        mov r1, r2
        and r2, r0, 0x0400
        lsr r2, 10 @ LSD_SEG16 == 0
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM1_1]
        ldr r4, =LCD_DIGIT4_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM1_1]

        and r2, r0, 0x0010
        lsl r2, 27 @ LSD_SEG6 == 31
        mov r1, r2
        and r2, r0, 0x0080
        lsl r2, 23 @ LSD_SEG17 == 30
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        ldr r4, =LCD_DIGIT4_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0020
        lsr r2, 4 @ LSD_SEG7 == 1
        mov r1, r2
        and r2, r0, 0x0040
        lsr r2, 6 @ LSD_SEG16 == 0
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM2_1]
        ldr r4, =LCD_DIGIT4_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM2_1]

        and r2, r0, 0x0001
        lsl r2, 31 @ LSD_SEG6 == 31
        mov r1, r2
        and r2, r0, 0x0008
        lsl r2, 27 @ LSD_SEG17 == 30
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        ldr r4, =LCD_DIGIT4_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

        and r2, r0, 0x0002
        @ lsr r2, 0 @ LSD_SEG7 == 1
        mov r1, r2
        and r2, r0, 0x0004
        lsr r2, 2 @ LSD_SEG16 == 0
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM3_1]
        ldr r4, =LCD_DIGIT4_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM3_1]

    b 900f

    4:
        and r2, r0, 0x2000
        lsl r2, 12 @ LCD_SEG9 == 25
        mov r1, r2
        and r2, r0, 0x4000
        lsl r2, 10 @ LCD_SEG14 == 24
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0]
        ldr r4, =LCD_DIGIT5_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x1000
        lsr r2, 9 @ LCD_SEG8 == 3
        mov r1, r2
        and r2, r0, 0x8000
        lsr r2, 13 @ LCD_SEG15 == 2
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM0_1]
        ldr r4, =LCD_DIGIT5_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM0_1]

        and r2, r0, 0x0200
        lsl r2, 16 @ LCD_SEG9 == 25
        mov r1, r2
        and r2, r0, 0x0400
        lsl r2, 14 @ LCD_SEG14 == 24
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        ldr r4, =LCD_DIGIT5_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0100
        lsr r2, 5 @ LCD_SEG8 == 3
        mov r1, r2
        and r2, r0, 0x0800
        lsr r2, 9 @ LCD_SEG15 == 2
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM1_1]
        ldr r4, =LCD_DIGIT5_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM1_1]

        and r2, r0, 0x0020
        lsl r2, 20 @ LCD_SEG9 == 25
        mov r1, r2
        and r2, r0, 0x0040
        lsl r2, 18 @ LCD_SEG14 == 24
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        ldr r4, =LCD_DIGIT5_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0010
        lsr r2, 1 @ LCD_SEG8 == 3
        mov r1, r2
        and r2, r0, 0x0080
        lsr r2, 5 @ LCD_SEG15 == 2
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM2_1]
        ldr r4, =LCD_DIGIT5_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM2_1]

        and r2, r0, 0x0002
        lsl r2, 24 @ LCD_SEG9 == 25
        mov r1, r2
        and r2, r0, 0x0004
        lsl r2, 22 @ LCD_SEG14 == 24
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        ldr r4, =LCD_DIGIT5_COM0_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

        and r2, r0, 0x0001
        lsl r2, 3 @ LCD_SEG8 == 3
        mov r1, r2
        and r2, r0, 0x0008
        lsr r2, 1 @ LCD_SEG15 == 2
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT4_COM3_1]
        ldr r4, =LCD_DIGIT5_COM0_1_SEG_MASK
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT4_COM3_1]

    b 900f

    5:
        ldr r4, =LCD_DIGIT6_SEG_MASK

        and r2, r0, 0x1000
        lsl r2, 5 @ LCD_SEG10_SHIFT == 17
        mov r1, r2
        and r2, r0, 0x2000
        lsr r2, 5 @ LCD_SEG11_SHIFT == 8
        orr r1, r2
        and r2, r0, 0x4000
        lsr r2, 5 @ LCD_SEG12_SHIFT == 9
        orr r1, r2
        and r2, r0, 0x8000
        lsl r2, 11 @ LCD_SEG13_SHIFT == 26
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM0] @ r3 == LCD
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM0]

        and r2, r0, 0x0100
        lsl r2, 9 @ LCD_SEG10_SHIFT == 17
        mov r1, r2
        and r2, r0, 0x0200
        lsr r2, 1 @ LCD_SEG11_SHIFT == 8
        orr r1, r2
        and r2, r0, 0x0400
        lsr r2, 1 @ LCD_SEG12_SHIFT == 9
        orr r1, r2
        and r2, r0, 0x0800
        lsl r2, 15 @ LCD_SEG13_SHIFT == 26
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM1]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM1]

        and r2, r0, 0x0010
        lsl r2, 13 @ LCD_SEG10_SHIFT == 17
        mov r1, r2
        and r2, r0, 0x0020
        lsl r2, 3 @ LCD_SEG11_SHIFT == 8
        orr r1, r2
        and r2, r0, 0x0040
        lsl r2, 3 @ LCD_SEG12_SHIFT == 9
        orr r1, r2
        and r2, r0, 0x0080
        lsl r2, 19 @ LCD_SEG13_SHIFT == 26
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM2]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM2]

        and r2, r0, 0x0001
        lsl r2, 17 @ LCD_SEG10_SHIFT == 17
        mov r1, r2
        and r2, r0, 0x0002
        lsl r2, 7 @ LCD_SEG11_SHIFT == 8
        orr r1, r2
        and r2, r0, 0x0004
        lsl r2, 7 @ LCD_SEG12_SHIFT == 9
        orr r1, r2
        and r2, r0, 0x0008
        lsl r2, 23 @ LCD_SEG13_SHIFT == 26
        orr r1, r2

        ldr r2, [r3, LCD_DIGIT1_COM3]
        and r2, r4
        orr r2, r1
        str r2, [r3, LCD_DIGIT1_COM3]

    900:
    pop {r4, pc}
.size lcd_write_raw, . - lcd_write_raw


/**
 * Decodes the last 10 bits in r0 from ASCII to the LCD
 * value, and writes it to the position in r1. Adds a
 * period and/or colon based on 10th and 9th bits
 * (10th == period, 9th == colon)
 *
 * Optionally errors if setting colon / period on the last two
 * positions, which will set the bars instead (usually unintended)
 *
 * @param r0: ASCII char
 * @param r1: display position
 * @return {null}
 */
.global lcd_write_char
.type lcd_write_char, %function
lcd_write_char:
    push {lr}

    @ TODO: error on last 2 pos + colon/period

    push {r1}
    bl lcd_decode_ascii
    pop {r1}

    bl lcd_write_raw

    pop {pc}
.size lcd_write_char, . - lcd_write_char


/**
 * Displays 6 characters, or fewer if null terminated
 *
 * @param r0: pointer to ASCII string
 * @param r1: start position on LCD display
 * @return {null}
 */
.global lcd_write_string
.type lcd_write_string, %function
lcd_write_string:
    push {r4-r6, lr}

    mov r4, r0
    mov r5, r1

    @ We will load in 4 bytes at a time, even if we don't use them all
    ldr r6, [r4], #4
    ands r0, r6, 0xFF
    beq 900f @ is null char
    mov r1, r5
    bl lcd_write_char

    add r5, 1
    cmp r5, 6
    beq 900f

    lsr r6, 8
    ands r0, r6, 0xFF
    beq 900f
    mov r1, r5
    bl lcd_write_char

    add r5, 1
    cmp r5, 6
    beq 900f

    lsr r6, 8
    ands r0, r6, 0xFF
    beq 900f
    mov r1, r5
    bl lcd_write_char

    add r5, 1
    cmp r5, 6
    beq 900f

    lsr r6, 8
    ands r0, r6, 0xFF
    beq 900f
    mov r1, r5
    bl lcd_write_char

    add r5, 1
    cmp r5, 6
    beq 900f

    ldr r6, [r4], #4
    ands r0, r6, 0xFF
    beq 900f
    mov r1, r5
    bl lcd_write_char

    add r5, 1
    cmp r5, 6
    beq 900f

    lsr r6, 8
    ands r0, r6, 0xFF
    beq 900f
    mov r1, r5
    bl lcd_write_char

    900:
    pop {r4-r6, pc}
.size lcd_write_string, . - lcd_write_string


/**
 * Displays a null terminated string by scrolling across the display
 * Will only scroll once, and is blocking until the action finishes.
 *
 * @param r0: pointer to ASCII string
 * @param r1: number of repetitions (at least one will play)
 * @param r2: scroll speed (default if 0)
 * @return {null}
 */
.global lcd_write_scroll
.type lcd_write_scroll, %function
lcd_write_scroll:
    push {r4-r8, lr}
    subs r1, 1

    mov r6, r0
    mov r7, r0

    mov r4, r1
    movs r5, r2
    it eq
    ldreq r5, =DEFAULT_SCROLL_SPEED

    0:
    movs r8, 5

    1:
    bl lcd_clear
    mov r0, r6
    mov r1, r8
    bl lcd_write_string
    bl lcd_update_display

    mov r0, r5
    bl var_delay

    subs r8, 1
    bpl 1b
    movs r8, 0

    ldrb r0, [r6], 1
    cmp r0, 0
    bne 1b

    mov r6, r7
    subs r4, 1
    bpl 0b

    pop {r4-r8, pc}
.size lcd_write_scroll, . - lcd_write_scroll


/**
 * Converts an ASCII value into a decoded value
 * such that writing the decoded value to a LCD
 * display will somewhat resemble the original ASCII.
 *
 * Only limited non alphanumeric characters are supported.
 *
 * @param r0: ASCII value, plus 9th and 10th bits to set colon and period
 * @return r0: decoded value, ready for {lcd_write_raw}
 */
.global lcd_decode_ascii
.type lcd_decode_ascii, %function
lcd_decode_ascii:
    @ Extract period & colon
    movs r2, 0
    tst r0, 0x200
    it ne
    orrne r2, 0x0002
    tst r0, 0x100
    it ne
    orrne r2, 0x0020

    ands r0, 0xFF

    @ Special case: Print full display
    cmp r0, 0xFF
    bne 1f

    orr r0, 0xFFDD
    bx lr

    1:
    cmp r0, ' '
    bmi 901f

    cmp r0, ('~' + 1)
    bpl 901f

    sub r0, ' '
    ldr r1, =ascii_map
    ldrh r0, [r1, r0, LSL 1]
    orr r0, r2
    bx lr

    901:
    @ If we get here, we couldn't decode the value
    mov r1, LCD_ERROR_ASCII_DECODE
    bl lcd_error
.size lcd_decode_ascii, . - lcd_decode_ascii


/**
 * Updates the physical screen to reflect the current
 * contents of RAM.
 *
 * @param {null}
 * @return {null}
 */
.global lcd_update_display
.type lcd_update_display, %function
lcd_update_display:
    push {lr}

    ldr r0, =LCD
    ldr r1, =0b1000
    str r1, [r0, LCD_CLR]

    ldr r1, [r0, LCD_SR]
    orr r1, 1 << LCD_SR_UDR
    str r1, [r0, LCD_SR]

    bl wait_for_LCD_SR_UDD

    pop {pc}
.size lcd_update_display, . - lcd_update_display


/**
 * Clears the RAM. Call {lcd_update_display} after to clear
 * the display too.
 *
 * @param {null}
 * @return {null}
 */
.global lcd_clear
.type lcd_clear, %function
lcd_clear:
    ldr r0, =(LCD + 0x14)
    mov r1, 0
    mov r2, 0
    mov r3, 0

    .rept 4
    stm r0!, {r1-r3}
    .endr

    bx lr
.size lcd_clear, . - lcd_clear


@@@@@@@@@@@@@
@@ Private @@
@@@@@@@@@@@@@

/**
 * Captures any errors related to interfacing with the LCD (after it has been initialised).
 * Will attempt to display the error number.
 *
 * (i.e., if this is reached, then your code is 99% likely wrong (1% possibly bug in library))
 *
 * @param r1: error code
 * @noreturn
 */
.type lcd_error, %function
lcd_error:
    mov r9, r1

    bl lcd_clear

    ldr r0, =lcd_error_message
    bl lcd_write_string

    movs r0, 10
    cmp r9, r0
    bge 1f

    ldr r0, ='0'
    add r0, r9
    movs r1, 4
    bl lcd_write_char

    1:
    bl lcd_update_display

    1:
    nop
    b 1b

    lcd_error_message:
    .asciz "Err "
    .align
.size lcd_error, . - lcd_error


.type delay, %function
delay:
    push {r0}
    pop {r0}
    bx lr
.size delay, . - delay


.type var_delay, %function
var_delay:
    subs r0, 1
    bne var_delay
    bx lr
.size var_delay, . - var_delay


.type wait_for_PWR_CR1_DBP, %function
wait_for_PWR_CR1_DBP:
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    tst r1, 1 << PWR_CR1_DBP
    beq wait_for_PWR_CR1_DBP
    bx lr
.size wait_for_PWR_CR1_DBP, . - wait_for_PWR_CR1_DBP


.type wait_for_RCC_BDCR_LSERDY, %function
wait_for_RCC_BDCR_LSERDY:
    ldr r0, =RCC
    ldr r1, [r0, RCC_BDCR]
    tst r1, 1 << RCC_BDCR_LSERDY
    beq wait_for_RCC_BDCR_LSERDY
    bx lr
.size wait_for_RCC_BDCR_LSERDY, . - wait_for_RCC_BDCR_LSERDY


.type wait_for_frame_sync, %function
wait_for_frame_sync:
    ldr r0, =LCD

    wait1:
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_FCRSF
    beq wait1

    bx lr
.size wait_for_frame_sync, . - wait_for_frame_sync


/**
 * @param r1: the current value of RCC_BDCR
 */
.type reset_backup_domain, %function
reset_backup_domain:
    bic r1, 0b11 << RCC_BDCR_RTCSEL

    @ Toggle on and off
    ldr r0, =RCC
    ldr r3, [r0, RCC_BDCR]
    orr r3, 1 << RCC_BDCR_BDRST
    str r3, [r0, RCC_BDCR]
    bic r3, 1 << RCC_BDCR_BDRST
    str r3, [r0, RCC_BDCR]
    str r1, [r0, RCC_BDCR]

    ands r1, 1 << RCC_BDCR_LSERDY
    it ne
    bxne lr

    push {lr}
    bl wait_for_RCC_BDCR_LSERDY
    pop {pc}
.size reset_backup_domain, . - reset_backup_domain


.type delay_for_two_ms, %function
delay_for_two_ms:
    ldr r0, =100000
    delay_for_two_ms_loop:
    subs r0, 1
    bne delay_for_two_ms_loop
    bx lr
.size delay_for_two_ms, . - delay_for_two_ms


.type wait_for_LCD_SR_FCRSF, %function
wait_for_LCD_SR_FCRSF:
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_FCRSF
    beq wait_for_LCD_SR_FCRSF
    bx lr
.size wait_for_LCD_SR_FCRSF, . - wait_for_LCD_SR_FCRSF


.type wait_for_LCD_SR_ENS, %function
wait_for_LCD_SR_ENS:
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_ENS
    beq wait_for_LCD_SR_ENS
    bx lr
.size wait_for_LCD_SR_ENS, . - wait_for_LCD_SR_ENS


.type wait_for_LCD_SR_RDY, %function
wait_for_LCD_SR_RDY:
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_RDY
    beq wait_for_LCD_SR_RDY
    bx lr
.size wait_for_LCD_SR_RDY, . - wait_for_LCD_SR_RDY


.type wait_for_reset_LCD_SR_UDR, %function
wait_for_reset_LCD_SR_UDR:
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_UDR
    bne wait_for_reset_LCD_SR_UDR
    bx lr
.size wait_for_reset_LCD_SR_UDR, . - wait_for_reset_LCD_SR_UDR


.type wait_for_LCD_SR_UDD, %function
wait_for_LCD_SR_UDD:
    ldr r0, =LCD
    ldr r1, [r0, LCD_SR]
    tst r1, 1 << LCD_SR_UDD
    beq wait_for_LCD_SR_UDD
    bx lr
.size wait_for_LCD_SR_UDD, . - wait_for_LCD_SR_UDD


ascii_map:
    @ Start at ASCII 0x20 (lower are not visible characters)
    .hword 0x0000 @ space
    .hword 0xFFFF @ !
    .hword 0xFFFF @ "
    .hword 0xFFFF @ #
    .hword 0xAF14 @ $
    .hword 0xB300 @ %
    .hword 0xFFFF @ &
    .hword 0x0040 @ '
    .hword 0x0041 @ (
    .hword 0x0088 @ )
    .hword 0xA0DD @ *
    .hword 0xA014 @ +
    .hword 0x0080 @ ,
    .hword 0xA000 @ -
    .hword 0x0181 @ .
    .hword 0x00C0 @ /

            /* 0       1       2       3       4       5       6       7       8       9 */
    .hword  0x5F00, 0x4200, 0xF500, 0x6700, 0xEA00, 0xAF00, 0xBF00, 0x4600, 0xFF00, 0xEF00

    .hword 0xFFFF @ :
    .hword 0xFFFF @ ;
    .hword 0xFFFF @ <
    .hword 0xFFFF @ =
    .hword 0xFFFF @ >
    .hword 0xF400 @ ?
    .hword 0xFFFF @ @

            /* A       B       C       D       E       F       G       H       I */
    .hword  0xFE00, 0x6714, 0x1D00, 0x4714, 0x9D00, 0x9C00, 0x3F00, 0xFA00, 0x0014
            /* J       K       L       M       N       O       P       Q       R */
    .hword  0x5300, 0x9841, 0x1900, 0x5A48, 0x5A09, 0x5F00, 0xFC00, 0x5F01, 0xFC01
            /* S       T       U       V       W       X       Y       Z */
    .hword  0xAF00, 0x0414, 0x5B00, 0x18C0, 0x5A81, 0x00C9, 0x0058, 0x05C0

    .hword 0x1D00 @ [
    .hword 0x0009 @ \
    .hword 0x4700 @ ]
    .hword 0x0081 @ ^
    .hword 0xFFFF @ _
    .hword 0x0008 @ `

            /* a       b       c       d       e       f       g       h       i */
    .hword  0xFE00, 0x6714, 0x1D00, 0xF300, 0x9D00, 0x9C00, 0x3F00, 0xFA00, 0x0014
            /* j       k       l       m       n       o       p       q       r */
    .hword  0x5300, 0x9841, 0x1900, 0xB210, 0x2210, 0xB300, 0xFC00, 0x5F01, 0xFC01
            /* s       t       u       v       w       x       y       z */
    .hword  0xAF00, 0x0414, 0x5B00, 0x18C0, 0x5A81, 0x00C9, 0x0058, 0x05C0

    .hword 0x8041 @ {
    .hword 0x0014 @ |
    .hword 0x2088 @ }
    .hword 0xFFFF @ ~
.align


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@
    .eqv PWR, 0x40007000
        .eqv PWR_CR1, 0x0
            .eqv PWR_CR1_DBP, 8

    .eqv RCC, 0x40021000
        .eqv RCC_APB1ENR1, 0x58
            .eqv RCC_APB1ENR1_PWREN, 28
            .eqv RCC_APB1ENR1_LCDEN, 9
        .eqv RCC_BDCR, 0x90
            .eqv RCC_BDCR_BDRST, 16
            .eqv RCC_BDCR_RTCSEL, 8
            .eqv RCC_BDCR_LSEBYP, 2
            .eqv RCC_BDCR_LSERDY, 1
            .eqv RCC_BDCR_LSEON, 0
        .eqv RCC_AHB2ENR, 0x4C
            .eqv RCC_AHB2ENR_GPIOAEN, 0
            .eqv RCC_AHB2ENR_GPIOBEN, 1
            .eqv RCC_AHB2ENR_GPIOCEN, 2
            .eqv RCC_AHB2ENR_GPIODEN, 3

    .eqv LCD, 0x40002400
        .eqv LCD_CR, 0x0
            .eqv LCD_CR_BUFEN, 8    @ Voltage output buffer enable
            .eqv LCD_CR_MUX_SEG, 7  @ Mux segment enable
            .eqv LCD_CR_BIAS, 5     @ Bias selector
            .eqv LCD_CR_DUTY, 2     @ Duty selection
            .eqv LCD_CR_VSEL, 1     @ Voltage source selection
            .eqv LCD_CR_LCDEN, 0    @ LCD controller enable (TODO)
        .eqv LCD_FCR, 0x04
            .eqv LCD_FCR_PS, 22     @ PS 16-bit prescaler
            .eqv LCD_FCR_DIV, 18    @ DIV clock divider
            .eqv LCD_FCR_BLINK, 16  @ Blink mode selection
            .eqv LCD_FCR_BLINKF, 13 @ Blink frequency selection
            .eqv LCD_FCR_CC, 10     @ Contrast control
            .eqv LCD_FCR_DEAD, 7    @ Dead time duration
            .eqv LCD_FCR_PON, 4     @ Pulse ON duration
            .eqv LCD_FCR_UDDIE, 3   @ Update display done interupt enable
            .eqv LCD_FCR_SOFIE, 1   @ Start of frame interupt enable
            .eqv LCD_FCR_HD, 0      @ High drive enable
        .eqv LCD_SR, 0x08 @ These are mostly read only
            .eqv LCD_SR_FCRSF, 5    @ Frame control register synchronisation flag
            .eqv LCD_SR_RDY, 4      @ Ready flag
            .eqv LCD_SR_UDD, 3      @ Update display done
            .eqv LCD_SR_UDR, 2      @ Update display request
            .eqv LCD_SR_SOF, 1      @ Start of frame flag
            .eqv LCD_SR_ENS, 0      @ LCD enabled status
        .eqv LCD_CLR, 0x0C
            .eqv LCD_CLR_UDDC, 3    @ Update display done clear
            .eqv LCD_CLR_SOFC, 1    @ Start of frame flag clear
        .eqv LCD_RAM, 0x14          @ Each bit corresponds to one pixel of the LCD display

    .eqv GPIOA, 0x48000000
    .eqv GPIOB, 0x48000400
    .eqv GPIOC, 0x48000800
    .eqv GPIOD, 0x48000C00
        .eqv GPIOx_MODER, 0x0
        .eqv GPIOx_OTYPER, 0x4
        .eqv GPIOx_OSPEEDR, 0x8
        .eqv GPIOx_PUPDR, 0xC
        .eqv GPIOx_AFRL, 0x20
        .eqv GPIOx_AFRH, 0x24

    .eqv LCD_SEG0, 1 << 4
    .eqv LCD_SEG1, 1 << 23
    .eqv LCD_SEG2, 1 << 6
    .eqv LCD_SEG3, 1 << 13
    .eqv LCD_SEG4, 1 << 15
    .eqv LCD_SEG5, 1 << 29
    .eqv LCD_SEG6, 1 << 31
    .eqv LCD_SEG7, 1 << 1
    .eqv LCD_SEG8, 1 << 3
    .eqv LCD_SEG9, 1 << 25
    .eqv LCD_SEG10, 1 << 17
    .eqv LCD_SEG11, 1 << 8
    .eqv LCD_SEG12, 1 << 9
    .eqv LCD_SEG13, 1 << 26
    .eqv LCD_SEG14, 1 << 24
    .eqv LCD_SEG15, 1 << 2
    .eqv LCD_SEG16, 1 << 0
    .eqv LCD_SEG17, 1 << 30
    .eqv LCD_SEG18, 1 << 28
    .eqv LCD_SEG19, 1 << 14
    .eqv LCD_SEG20, 1 << 12
    .eqv LCD_SEG21, 1 << 5
    .eqv LCD_SEG22, 1 << 22
    .eqv LCD_SEG23, 1 << 3

    .eqv LCD_DIGIT1_SEG_MASK, ~(LCD_SEG0 | LCD_SEG1 | LCD_SEG22 | LCD_SEG23)
    .eqv LCD_DIGIT2_SEG_MASK, ~(LCD_SEG2 | LCD_SEG3 | LCD_SEG20 | LCD_SEG21)
    .eqv LCD_DIGIT3_SEG_MASK, ~(LCD_SEG4 | LCD_SEG5 | LCD_SEG18 | LCD_SEG19)

    .eqv LCD_DIGIT4_COM0_SEG_MASK, ~(LCD_SEG6 | LCD_SEG17)
    .eqv LCD_DIGIT4_COM0_1_SEG_MASK, ~(LCD_SEG7 | LCD_SEG16)

    .eqv LCD_DIGIT5_COM0_SEG_MASK, ~(LCD_SEG9 | LCD_SEG14)
    .eqv LCD_DIGIT5_COM0_1_SEG_MASK, ~(LCD_SEG8 | LCD_SEG15)

    .eqv LCD_DIGIT6_SEG_MASK, ~(LCD_SEG10 | LCD_SEG11 | LCD_SEG12 | LCD_SEG13)

    .eqv LCD_DIGIT1_COM0, 0x14
    .eqv LCD_DIGIT4_COM0_1, 0x18
    .eqv LCD_DIGIT1_COM1, 0x1C
    .eqv LCD_DIGIT4_COM1_1, 0x20
    .eqv LCD_DIGIT1_COM2, 0x24
    .eqv LCD_DIGIT4_COM2_1, 0x28
    .eqv LCD_DIGIT1_COM3, 0x2C
    .eqv LCD_DIGIT4_COM3_1, 0x30
