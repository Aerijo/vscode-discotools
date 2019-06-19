.syntax unified

/**
 * NOTE: This example also requires the `led.S` library.
 *
 * Alternatively, remove the `led_...` functions, and just
 * set breakpoints in the interrupt handlers to try it out.
 */

.global main
.type main, %function
main:
    bl led_red_init
    bl led_green_init

    mov r0, 0b101111
    bl joystick_init_buttons

    mov r0, 0b101111
    bl joystick_enable_interrupt_buttons

    loop:
    nop @ everything else is done via interrupts
    b loop
.size main, . - main


/** Centre button */
.global EXTI0_IRQHandler
.type EXTI0_IRQHandler, %function
EXTI0_IRQHandler:
    push {lr}
    mov r0, (1 << 0)
    bl joystick_clear_interrupt
    bl led_red_toggle
    bl led_green_toggle
    pop {pc}
.size EXTI0_IRQHandler, . - EXTI0_IRQHandler


/** Left button */
.global EXTI1_IRQHandler
.type EXTI1_IRQHandler, %function
EXTI1_IRQHandler:
    push {lr}
    mov r0, (1 << 1)
    bl joystick_clear_interrupt
    bl led_red_toggle
    pop {pc}
.size EXTI1_IRQHandler, . - EXTI1_IRQHandler


/** Right button */
.global EXTI2_IRQHandler
.type EXTI2_IRQHandler, %function
EXTI2_IRQHandler:
    push {lr}
    mov r0, (1 << 2)
    bl joystick_clear_interrupt
    bl led_red_toggle
    pop {pc}
.size EXTI2_IRQHandler, . - EXTI2_IRQHandler


/** Up button */
.global EXTI3_IRQHandler
.type EXTI3_IRQHandler, %function
EXTI3_IRQHandler:
    push {lr}
    mov r0, (1 << 3)
    bl joystick_clear_interrupt
    bl led_green_toggle
    pop {pc}
.size EXTI3_IRQHandler, . - EXTI3_IRQHandler


/** Down button */
.global EXTI9_5_IRQHandler
.type EXTI9_5_IRQHandler, %function
EXTI9_5_IRQHandler:
    push {lr}
    mov r0, (1 << 5)
    bl joystick_clear_interrupt
    bl led_green_toggle
    pop {pc}
.size EXTI9_5_IRQHandler, . - EXTI9_5_IRQHandler
