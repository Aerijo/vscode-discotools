.syntax unified


.global main
.type main, %function
main:
    bl rng_init

    loop:

    bl rng_get_number
    mov r4, r0

    bl rng_get_number
    mov r5, r0

    bl rng_get_number
    mov r6, r0

    bl rng_get_number
    mov r7, r0

    b loop
.size main, . - main
