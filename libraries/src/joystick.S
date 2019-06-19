.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 0.1.0
 * @brief
 *   Provides an interface to the joystick
 *
 *   You can use `joystick_init_all` to enable all buttons, or
 *   use `joystick_init_buttons` with a parameter to enable specific
 *   buttons. Likewise for `joystick_enable_interrupts_all` and
 *   `joystick_enable_interrupt_buttons`. The interrupt initialisers are
 *   both hardcoded for rising edge (press down) only.
 *
 *   When setting specific buttons, the bits 0, 1, 2, 3, and 5 in r0 are
 *   taken to be enabling pins 0, 1, 2, 3, and 5 respectively. The init
 *   functions will not disable any pins or interrupts.
 *
 *   The button-pin-interrupt handler mapping is as follows
 *     BUTTON  PIN  HANDLER_NAME
 *   * centre - 0 - EXTI0_IRQHandler
 *   * left   - 1 - EXTI1_IRQHandler
 *   * right  - 2 - EXTI2_IRQHandler
 *   * up     - 3 - EXTI3_IRQHandler
 *   * down   - 5 - EXTI9_5_IRQHandler
 *
 * @pins A0--A3, A5 (or just the ones configured)
 */


/**
 * Initialises all 5 joystick buttons. Use the other init functions
 * if you only want to use specific buttons. Don't forget to initialise
 * interrupts as well; a separate init function has been provided
 * for this (both are required to init joystick + interrupt)
 */
.global joystick_init_all
.type joystick_init_all, %function
joystick_init_all:
    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << 0) @ GPIOA
    str r1, [r0, RCC_AHB2ENR]

    ldr r0, =GPIOA
    ldr r2, =(0b11 << 0 | 0b11 << 2 | 0b11 << 4 | 0b11 << 6 | 0b11 << 10)
    ldr r1, [r0, GPIOx_MODER]
    bic r1, r2
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, r2
    orr r1, (0b10 << 0 | 0b10 << 2 | 0b10 << 4 | 0b10 << 6)
    orr r1, (0b10 << 10)
    str r1, [r0, GPIOx_PUPDR]

    bx lr
.size joystick_init_all, . - joystick_init_all


/**
 * Note: the "complicated" bit shifts here are just to form the proper
 * masks for the selected pins. See `joystick_init_all` for the less
 * convoluted process.
 *
 * @param r0 - Pins to initialise (bits 0--3 and 5 correspond to pins 0--3 and 5)
 */
.global joystick_init_buttons
.type joystick_init_buttons, %function
joystick_init_buttons:
    and r3, r0, 0b101111
    mov r2, 0

    tst r3, (1 << 0)
    it ne
    addne r2, (0b10 << 0)
    tst r3, (1 << 1)
    it ne
    addne r2, (0b10 << 2)
    tst r3, (1 << 2)
    it ne
    addne r2, (0b10 << 4)
    tst r3, (1 << 3)
    it ne
    addne r2, (0b10 << 6)
    tst r3, (1 << 5)
    it ne
    addne r2, (0b10 << 10)

    ldr r0, =RCC
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << 0) @ GPIOA
    str r1, [r0, RCC_AHB2ENR]

    ldr r0, =GPIOA
    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, r3
    str r1, [r0, GPIOx_OTYPER]

    add r3, r2, r2, LSR 1

    ldr r1, [r0, GPIOx_MODER]
    bic r1, r3
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, r3
    orr r1, r2
    str r1, [r0, GPIOx_PUPDR]

    bx lr
.size joystick_init_buttons, . - joystick_init_buttons


/**
 * Enables the interrupt lines for the joystick buttons. Make sure to
 * define the handler for each enabled interrupt, as the default handler
 * is just an infinite loop.
 */
.global joystick_enable_interrupts_all
.type joystick_enable_interrupts_all, %function
joystick_enable_interrupts_all:
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB2ENR]
    bic r1, (1 << 0) @ SYSCFG (required to select EXTI interrupt lines)
    str r1, [r0, RCC_APB2ENR]

    ldr r0, =SYSCFG
    ldr r1, [r0, SYSCFG_EXTICR1]
    bic r1, (0b111 << 0 | 0b111 << 4)
    bic r1, (0b111 << 8 | 0b111 << 12)
    str r1, [r0, SYSCFG_EXTICR1]

    ldr r1, [r0, SYSCFG_EXTICR2]
    bic r1, (0b111 << 4)
    str r1, [r0, SYSCFG_EXTICR2]

    ldr r0, =EXTI
    ldr r1, [r0, EXTI_IMR1]
    orr r1, (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5)
    str r1, [r0, EXTI_IMR1]

    ldr r1, [r0, EXTI_RTSR1]
    orr r1, (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5)
    str r1, [r0, EXTI_RTSR1]

    ldr r1, [r0, EXTI_FTSR1]
    bic r1, (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5)
    str r1, [r0, EXTI_FTSR1]

    ldr r0, =NVIC
    ldr r1, [r0, NVIC_ICER0]
    orr r1, (1 << 6 | 1 << 7 | 1 << 8 | 1 << 9)
    orr r1, (1 << 23)
    str r1, [r0, NVIC_ICER0]

    bx lr
.size joystick_enable_interrupts_all, . - joystick_enable_interrupts_all


/**
 * Note: Like with `joystick_init_buttons`, use `joystick_enable_interrupts_all` to get
 * a better sense of what is being configured, without all the bit operations.
 *
 * @param r0 - Pins to set interrupts (bits 0--3 and 5 correspond to pins 0--3 and 5)
 */
.global joystick_enable_interrupt_buttons
.type joystick_enable_interrupt_buttons, %function
joystick_enable_interrupt_buttons:
    and r2, r0, 0b101111

    ldr r0, =RCC
    ldr r1, [r0, RCC_APB2ENR]
    bic r1, (1 << 0) @ SYSCFG (required to select EXTI interrupt lines)
    str r1, [r0, RCC_APB2ENR]

    ldr r0, =SYSCFG
    ldr r1, [r0, SYSCFG_EXTICR1]
    tst r2, (1 << 0)
    it ne
    bicne r1, (0b111 << 0)
    tst r2, (1 << 1)
    it ne
    bicne r1, (0b111 << 4)
    tst r2, (1 << 2)
    it ne
    bicne r1, (0b111 << 8)
    tst r2, (1 << 3)
    it ne
    bicne r1, (0b111 << 12)
    str r1, [r0, SYSCFG_EXTICR1]

    tst r2, (1 << 5)
    beq 1f

    ldr r1, [r0, SYSCFG_EXTICR2]
    bic r1, (0b111 << 4)
    str r1, [r0, SYSCFG_EXTICR2]

    1:

    ldr r0, =EXTI
    ldr r1, [r0, EXTI_IMR1]
    orr r1, r2
    str r1, [r0, EXTI_IMR1]

    ldr r1, [r0, EXTI_RTSR1]
    orr r1, r2
    str r1, [r0, EXTI_RTSR1]

    ldr r1, [r0, EXTI_FTSR1]
    bic r1, r2
    str r1, [r0, EXTI_FTSR1]

    ldr r0, =NVIC
    ldr r1, [r0, NVIC_ICER0]
    tst r2, (1 << 5)
    and r2, 0b1111
    orr r1, r1, r2, LSL 6
    it ne
    orrne r1, (1 << 23)
    str r1, [r0, NVIC_ICER0]

    bx lr
.size joystick_enable_interrupt_buttons, . - joystick_enable_interrupt_buttons


/**
 * @param r0 - Pins to clear interrupts (bits 0--3 and 5 correspond to pins 0--3 and 5)
 */
.global joystick_clear_interrupt
.type joystick_clear_interrupt, %function
joystick_clear_interrupt:
    and r1, r0, 0b101111
    ldr r0, =EXTI
    str r1, [r0, EXTI_PR1]
    bx lr
.size joystick_clear_interrupt, . - joystick_clear_interrupt


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.equiv RCC, 0x40021000
    .equiv RCC_AHB2ENR, 0x4C
    .equiv RCC_APB2ENR, 0x60

.equiv GPIOA, 0x48000000
    .equiv GPIOx_MODER, 0x0
    .equiv GPIOx_OTYPER, 0x4
    .equiv GPIOx_PUPDR, 0xC
    .equiv GPIOx_ODR, 0x14
    .equiv GPIOx_BSRR, 0x18

.equiv SYSCFG, 0x40010000
    .equiv SYSCFG_EXTICR1, 0x08
    .equiv SYSCFG_EXTICR2, 0x0C

.equiv EXTI, 0x40010400
    .equiv EXTI_IMR1, 0x00
    .equiv EXTI_RTSR1, 0x08
    .equiv EXTI_FTSR1, 0x0C
    .equiv EXTI_PR1, 0x14

.equiv NVIC, 0xE000E100
    .equiv NVIC_ICER0, 0x0
