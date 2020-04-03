.syntax unified

@@@@@@@@@@@@
@@ Public @@
@@@@@@@@@@@@

.global audio_init
.type audio_init, %function
audio_init:
    push {lr}

    bl HAL_RCCEx_PeriphCLKConfig_asm_sai1

    bl AUDIO_SAIx_Init_asm

    bl cs43l22_drv_ReadID_asm

    bl cs43l22_Init_asm

    ldr r0, =15000
    bl audio_buffer

    pop {pc}
.size audio_init, . - audio_init


/**
 * Buffers the given output.
 *
 * @param r0 - amplitude to emit (16 bit)
 * @return {null}
 */
.global audio_play_sample
.type audio_play_sample, %function
audio_play_sample:
    @ We want to wait for the LVL to not be full, then emit the payload
    ldr r2, =SAI1
    1:
    ldr r1, [r2, SAIx_ASR]
    and r1, (0b111 << SAIx_xSR_FLVL)
    cmp r1, (0b101 << SAIx_xSR_FLVL) @ 0b101 is full
    beq 1b

    str r0, [r2, SAIx_ADR]

    bx lr
.size audio_play_sample, . - audio_play_sample


/**
 * Play a number of samples with 0 amplitude. Used
 * to wait for the SAI to "warm up"? It may cut off
 * the starting sound if not used.
 *
 * @param r0 - number of samples to play
 */
.global audio_buffer
.type audio_buffer, %function
audio_buffer:
  push {r4, lr}
  mov r4, r0

  1:
  mov r0, 0
  bl audio_play_sample
  subs r4, 1
  bne 1b

  pop {r4, pc}
.size audio_buffer, . - audio_buffer


@@@@@@@@@@@@@
@@ Private @@
@@@@@@@@@@@@@

.type HAL_RCCEx_PeriphCLKConfig_asm_sai1, %function
HAL_RCCEx_PeriphCLKConfig_asm_sai1:
    push {lr}

    bl RCCEx_PLLSAI1_Config_asm

    ldr r0, =RCC
    ldr r1, [r0, RCC_CCIPR]
    bic r1, (0b11 << RCC_CCIPR_SAI1SEL)
    str r1, [r0, RCC_CCIPR]

    pop {lr}
    bx lr
.size HAL_RCCEx_PeriphCLKConfig_asm_sai1, . - HAL_RCCEx_PeriphCLKConfig_asm_sai1


.type RCCEx_PLLSAI1_Config_asm, %function
RCCEx_PLLSAI1_Config_asm:
    @ __HAL_RCC_PLLSAI1_DISABLE
    ldr r0, =RCC
    ldr r1, [r0, RCC_CR]
    bic r1, (1 << RCC_CR_PLLSAI1ON)
    str r1, [r0, RCC_CR]

    @ Wait until PLLSAI1 is ready to be updated
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLSAI1RDY)
    bne 1b

    @ Configure the PLLSAI1 Division factor P and Multiplication factor N
    ldr r1, [r0, RCC_PLLSAI1CFGR]
    bic r1, (0x7F << RCC_PLLSAI1CFGR_PLLSAI1N)
    orr r1, (43 << RCC_PLLSAI1CFGR_PLLSAI1N)
    bic r1, (1 << RCC_PLLSAI1CFGR_PLLSAI1P)
    str r1, [r0, RCC_PLLSAI1CFGR]

    @ Enable the PLLSAI1 again by setting PLLSAI1ON to 1
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_PLLSAI1ON)
    str r1, [r0, RCC_CR]

    @ Wait till PLLSAI1 is ready
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLSAI1RDY)
    beq 1b

    @ __HAL_RCC_PLLSAI1CLKOUT_ENABLE
    ldr r1, [r0, RCC_PLLSAI1CFGR]
    orr r1, (1 << RCC_PLLSAI1CFGR_PLLSAI1PEN)
    str r1, [r0, RCC_PLLSAI1CFGR]

    bx lr
.size RCCEx_PLLSAI1_Config_asm, . - RCCEx_PLLSAI1_Config_asm


.type AUDIO_SAIx_Init_asm, %function
AUDIO_SAIx_Init_asm:
    push {lr}

    @ __HAL_SAI_DISABLE
    ldr r0, =SAI1
    ldr r1, [r0, SAIx_ACR1]
    bic r1, (1 << SAIx_xCR1_SAIxEN)
    str r1, [r0, SAIx_ACR1]

    bl HAL_SAI_Init_asm

    @ Enable SAI peripheral to generate MCLK
    ldr r0, =SAI1
    ldr r1, [r0, SAIx_ACR1]
    orr r1, (1 << SAIx_xCR1_SAIxEN)
    str r1, [r0, SAIx_ACR1]

    pop {lr}
    bx lr
.size AUDIO_SAIx_Init_asm, . - AUDIO_SAIx_Init_asm


.type HAL_SAI_Init_asm, %function
HAL_SAI_Init_asm:
    push {lr}

    bl HAL_SAI_MspInit_asm

    @ SAI_Disable
    ldr r0, =SAI1
    ldr r1, [r0, SAIx_ACR1]
    bic r1, (1 << SAIx_xCR1_SAIxEN)
    str r1, [r0, SAIx_ACR1]

    @ Wait for reset
    1:
    ldr r1, [r0, SAIx_ACR1]
    tst r1, (1 << SAIx_xCR1_SAIxEN)
    bne 1b

    @ Set GCR to 0
    mov r1, 0
    str r1, [r0, SAIx_GCR]

    @ Configure SAI1 ACR1
    ldr r1, [r0, SAIx_ACR1]
    bic r1, (0b11 << SAIx_xCR1_MODE | 0b11 << SAIx_xCR1_PRTCFG | 0b111 << SAIx_xCR1_DS)
    bic r1, (1 << SAIx_xCR1_LSBFIRST | 0b11 << SAIx_xCR1_SYNCEN)
    bic r1, (1 << SAIx_xCR1_DMAEN | 1 << SAIx_xCR1_NODIV | 0xF << SAIx_xCR1_MCKDIV)
    orr r1, (0b100 << SAIx_xCR1_DS)
    orr r1, (1 << SAIx_xCR1_CKSTR | 1 << SAIx_xCR1_MONO | 1 << SAIx_xCR1_OUTDRIV)
    orr r1, (0x1 << SAIx_xCR1_MCKDIV)
    str r1, [r0, SAIx_ACR1]

    @ SAI CR2 Configuration
    ldr r1, [r0, SAIx_ACR2]
    bic r1, (0b111 << SAIx_xCR2_FTH | 1 << SAIx_xCR2_FFLUSH)
    bic r1, (1 << SAIx_xCR2_CPL | 0b11 << SAIx_xCR2_COMP)
    orr r1, (0b001 << SAIx_xCR2_FTH)
    str r1, [r0, SAIx_ACR2]

    @ SAI Frame Configuration
    ldr r1, [r0, SAIx_AFRCR]
    bic r1, (0xFF << SAIx_xFRCR_FRL)
    bic r1, (0x7F << SAIx_xFRCR_FSALL)
    bic r1, (1 << SAIx_xFRCR_FSPOL)
    orr r1, (0x1F << SAIx_xFRCR_FRL)
    orr r1, (0x0F << SAIx_xFRCR_FSALL)
    orr r1, (1 << SAIx_xFRCR_FSDEF | 1 << SAIx_xFRCR_FSOFF)
    str r1, [r0, SAIx_AFRCR]

    @ SAI Block_x SLOT Configuration
    ldr r1, [r0, SAIx_ASLOTR]
    bic r1, (0x1F << SAIx_xSLOTR_FBOFF | 0b11 << SAIx_xSLOTR_SLOTSZ)
    bic r1, (0xF << SAIx_xSLOTR_NBSLOT)
    bic r1, (0xFF << SAIx_xSLOTR_SLOTEN)
    bic r1, (0xFF << (SAIx_xSLOTR_SLOTEN + 8))
    orr r1, (0x1 << SAIx_xSLOTR_NBSLOT)
    orr r1, (0x0003 << SAIx_xSLOTR_SLOTEN)
    str r1, [r0, SAIx_ASLOTR]

    pop {lr}
    bx lr
.size HAL_SAI_Init_asm, . - HAL_SAI_Init_asm


.type HAL_SAI_MspInit_asm, %function
HAL_SAI_MspInit_asm:
    @ Enable SAI clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB2ENR]
    orr r1, (1 << RCC_APB2ENR_SAI1EN)
    str r1, [r0, RCC_APB2ENR]

    @ Enable GPIO clock
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << RCC_AHB2ENR_GPIOEEN)
    str r1, [r0, RCC_AHB2ENR]

    @ CODEC_SAI pins configuration: FS, SCK, MCK and SD pins
    @ FS=E4, SCK=E5, MCK=E2, SD=E6 (from user manual sec.8, fig.12)
    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << 8 | 0b11 << 10 | 0b11 << 12)
    bic r1, (0b11 << 4)
    orr r1, (0b10 << 8 | 0b10 << 10 | 0b10 << 12)
    orr r1, (0b10 << 4)
    str r1, [r0, GPIOx_MODER]
    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << 2 | 1 << 4 | 1 << 5 | 1 << 6)
    str r1, [r0, GPIOx_OTYPER]
    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << 8 | 0b11 << 10 | 0b11 << 12)
    orr r1, (0b11 << 4)
    str r1, [r0, GPIOx_OSPEEDR]
    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << 8 | 0b11 << 10 | 0b11 << 12)
    bic r1, (0b11 << 4)
    str r1, [r0, GPIOx_PUPDR]
    ldr r1, [r0, GPIOx_AFRL]
    bic r1, (0xF << 20 | 0xF << 24)
    orr r1, (0xD << 20 | 0xD << 24)
    bic r1, (0xF << 16)
    orr r1, (0xD << 16)
    bic r1, (0xF << 8)
    orr r1, (0xD << 8)
    str r1, [r0, GPIOx_AFRL]

    bx lr
.size HAL_SAI_MspInit_asm, . - HAL_SAI_MspInit_asm


.type cs43l22_drv_ReadID_asm, %function
cs43l22_drv_ReadID_asm:
    push {lr}

    bl AUDIO_IO_Init_asm

    mov r0, 1
    mov r1, 1
    bl HAL_I2C_Mem_Read_asm

    pop {lr}
    bx lr
.size cs43l22_drv_ReadID_asm, . - cs43l22_drv_ReadID_asm


.type AUDIO_IO_Init_asm, %function
AUDIO_IO_Init_asm:
    push {lr}

    @ Enable Reset GPIO Clock
    @ no-op (GPIOE already enabled)

    @ Audio reset pin configuration (pin E3, see user manual s.8, fig.12)
    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << 6)
    orr r1, (0b01 << 6)
    str r1, [r0, GPIOx_MODER]
    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << 3)
    str r1, [r0, GPIOx_OTYPER]
    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << 6)
    str r1, [r0, GPIOx_OSPEEDR]
    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << 6)
    str r1, [r0, GPIOx_PUPDR]

    bl I2C1_Init_asm

    ldr r0, =GPIOE
    ldr r1, =(1 << 3)
    str r1, [r0, GPIOx_BSRR]

    pop {lr}
    bx lr
.size AUDIO_IO_Init_asm, . - AUDIO_IO_Init_asm


.type I2C1_Init_asm, %function
I2C1_Init_asm:
    push {lr}

    bl I2C1_MspInit_asm

    bl HAL_I2C_Init_asm

    pop {lr}
    bx lr
.size I2C1_Init_asm, . - I2C1_Init_asm


.type I2C1_MspInit_asm, %function
I2C1_MspInit_asm:
    push {lr}

    @ IOSV bit MUST be set to access GPIO port G[2:15]
    @ __HAL_RCC_PWR_CLK_ENABLE
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, (1 << RCC_APB1ENR1_PWREN)
    str r1, [r0, RCC_APB1ENR1]

    @ Wait after enabling peripheral clock
    1:
    ldr r1, [r0, RCC_APB1ENR1]
    tst r1, (1 << RCC_APB1ENR1_PWREN)
    beq 1b

    @ HAL_PWREx_EnableVddIO2
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR2]
    orr r1, (1 << PWR_CR2_IOSV)
    str r1, [r0, PWR_CR2]

    @ Configure the Discovery I2C clock source. The clock is derived from the SYSCLK
    ldr r0, =RCC
    ldr r1, [r0, RCC_CCIPR]
    bic r1, (0b11 << RCC_CCIPR_I2C1SEL)
    orr r1, (0b01 << RCC_CCIPR_I2C1SEL)
    str r1, [r0, RCC_CCIPR]

    @ Configure the GPIOs
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << RCC_AHB2ENR_GPIOBEN)
    str r1, [r0, RCC_AHB2ENR]

    @ Configure I2C Rx/Tx as alternate function (B6, B7)
    ldr r0, =GPIOB
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << 12 | 0b11 << 14)
    orr r1, (0b10 << 12 | 0b10 << 14)
    str r1, [r0, GPIOx_MODER]
    ldr r1, [r0, GPIOx_OTYPER]
    orr r1, (1 << 6 | 1 << 7)
    str r1, [r0, GPIOx_OTYPER]
    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << 12 | 0b11 << 14)
    str r1, [r0, GPIOx_OSPEEDR]
    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << 12 | 0b11 << 14)
    orr r1, (0b01 << 12 | 0b01 << 14)
    str r1, [r0, GPIOx_PUPDR]
    ldr r1, [r0, GPIOx_AFRL]
    bic r1, (0xF << 24 | 0xF << 28)
    orr r1, (0x4 << 24 | 0x4 << 28)
    str r1, [r0, GPIOx_AFRL]

    @ Configure the Discovery I2C1 peripheral
    @ Enable Discovery I2C1 clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, (1 << RCC_APB1ENR1_I2C1EN)
    str r1, [r0, RCC_APB1ENR1]

    @ Wait after enabling peripheral clock
    1:
    ldr r1, [r0, RCC_APB1ENR1]
    tst r1, (1 << RCC_APB1ENR1_I2C1EN)
    beq 1b

    @ Force and release the I2C Peripheral Clock Reset
    ldr r1, [r0, RCC_APB1RSTR1]
    orr r1, (1 << RCC_APB1RSTR1_I2C1RST)
    str r1, [r0, RCC_APB1RSTR1]
    ldr r1, [r0, RCC_APB1RSTR1]
    bic r1, (1 << RCC_APB1RSTR1_I2C1RST)
    str r1, [r0, RCC_APB1RSTR1]

    @ Enable and set Discovery I2C1 Interrupt to the highest priority
    ldr r0, =NVIC
    ldr r1, [r0, NVIC_IPR7]
    bic r1, (0xF << 28) @ interrupt 31 = (4 * 7) + 3
    str r1, [r0, NVIC_IPR7]
    ldr r1, [r0, NVIC_ISER0]
    orr r1, (1 << 31)
    str r1, [r0, NVIC_ISER0]

    @ Enable and set Discovery I2C1 Event Interrupt to the highest priority
    ldr r1, [r0, NVIC_IPR8]
    bic r1, (0xF << 4) @ interrupt 32 = (4 * 8) + 0
    str r1, [r0, NVIC_IPR8]
    ldr r1, [r0, NVIC_ISER1]
    orr r1, (1 << 0)
    str r1, [r0, NVIC_ISER1]

    pop {lr}
    bx lr
.size I2C1_MspInit_asm, . - I2C1_MspInit_asm


.type HAL_I2C_Init_asm, %function
HAL_I2C_Init_asm:
    push {lr}

    @ __HAL_I2C_DISABLE
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR1]
    bic r1, (1 << I2Cx_CR1_PE)
    str r1, [r0, I2Cx_CR1]

    @ Configure I2Cx: Frequency range
    ldr r1, =0x90112626
    str r1, [r0, I2Cx_TIMINGR]

    @ Disable Own Address1 before set the Own Address1 configuration
    ldr r1, [r0, I2Cx_OAR1]
    bic r1, (1 << I2Cx_OAR1_OA1EN)
    str r1, [r0, I2Cx_OAR1]

    @ Configure I2Cx: Own Address1 and ack own address1 mode
    ldr r1, =0x00008000
    str r1, [r0, I2Cx_OAR1]

    @ Configure I2Cx: Addressing Master mode
    @ Enable the AUTOEND by default, and enable NACK (should be disable only during Slave process
    ldr r1, [r0, I2Cx_CR2]
    orr r1, (1 << I2Cx_CR2_AUTOEND)
    orr r1, (1 << I2Cx_CR2_NACK)
    str r1, [r0, I2Cx_CR2]

    @ Disable Own Address2 before set the Own Address2 configuration
    ldr r1, [r0, I2Cx_OAR2]
    bic r1, (1 << I2Cx_OAR2_OA2EN)
    str r1, [r0, I2Cx_OAR2]

    @ Configure I2Cx: Dual mode and Own Address2
    ldr r1, =0
    str r1, [r0, I2Cx_OAR2]

    @ Configure I2Cx: Generalcall and NoStretch mode
    ldr r1, =0
    str r1, [r0, I2Cx_CR1]

    @ Enable the selected I2C peripheral
    ldr r1, [r0, I2Cx_CR1]
    orr r1, (1 << I2Cx_CR1_PE)
    str r1, [r0, I2Cx_CR1]

    pop {lr}
    bx lr
.size HAL_I2C_Init_asm, . - HAL_I2C_Init_asm


/**
 * @param r0 - MemAddress
 * @param r1 - MemAddSize
 */
.type HAL_I2C_Mem_Read_asm, %function
HAL_I2C_Mem_Read_asm:
    push {r4-r5, lr}

    mov r4, r0
    mov r5, r1

    mov r0, (1 << I2Cx_ISR_BUSY)
    bl wait_for_I2Cx_flag_reset

    mov r0, r4
    mov r1, r5
    bl I2C_RequestMemoryRead_asm

    mov r0, 1
    mov r1, (1 << I2Cx_CR2_AUTOEND)
    mov r2, 0x80000000
    orr r2, (1 << I2Cx_CR2_START | 1 << I2Cx_CR2_RD_WRN)
    bl I2C_TransferConfig_asm

    mov r0, (1 << I2Cx_ISR_RXNE)
    bl wait_for_I2C1_flag_set

    ldr r0, =I2C1
    ldr r4, [r0, I2Cx_RXDR]

    mov r0, (1 << I2Cx_ISR_STOPF)
    bl wait_for_I2C1_flag_set

    bl __HAL_I2C_CLEAR_STOP_FLAG_asm

    bl I2C_RESET_CR2_asm

    mov r0, r4
    pop {r4-r5, lr}
    bx lr
.size HAL_I2C_Mem_Read_asm, . - HAL_I2C_Mem_Read_asm


/**
 * @param r0 - MemAddress
 * @param r1 - MemAddSize
 */
.type I2C_RequestMemoryRead_asm, %function
I2C_RequestMemoryRead_asm:
    push {r4, lr}

    and r4, r0, 0xFF

    mov r0, r1
    mov r1, 0
    ldr r2, =(0x80000000 | 1 << 13)
    bl I2C_TransferConfig_asm

    mov r0, (1 << I2Cx_ISR_TXIS)
    bl wait_for_I2C1_flag_set

    ldr r0, =I2C1
    str r4, [r0, I2Cx_TXDR]

    mov r0, (1 << I2Cx_ISR_TC)
    bl wait_for_I2C1_flag_set

    pop {r4, lr}
    bx lr
.size I2C_RequestMemoryRead_asm, . - I2C_RequestMemoryRead_asm


/**
 * @param r0 - Size
 * @param r1 - Mode
 * @param r2 - Request
 */
.type I2C_TransferConfig_asm, %function
I2C_TransferConfig_asm:
    push {r4-r5}
    ldr r3, =I2C1
    ldr r4, [r3, I2Cx_CR2]

    bic r4, (0xFF << I2Cx_CR2_SADD0)
    bic r4, (1 << I2Cx_CR2_START | 1 << I2Cx_CR2_STOP | 0x3 << (I2Cx_CR2_SADD0 + 8))
    bic r4, (0xFF << I2Cx_CR2_NBYTES)
    bic r4, (1 << I2Cx_CR2_RELOAD | 1 << I2Cx_CR2_AUTOEND)

    lsl r5, r2, 21 @ 31 - I2Cx_CR2_RD_WRN
    and r5, (1 << I2Cx_CR2_RD_WRN)
    bic r4, r5

    orr r4, (0x94 << I2Cx_CR2_SADD0)
    lsl r0, 16 @ I2Cx_CR2_NBYTES
    orr r4, r0
    orr r4, r1
    orr r4, r2

    str r4, [r3, I2Cx_CR2]
    pop {r4-r5}
    bx lr
.size I2C_TransferConfig_asm, . - I2C_TransferConfig_asm


/**
 * Delays execution until the specified flag is set in
 * the I2C1_ISR register.
 *
 * @param r0 - flag
 */
.type wait_for_I2C1_flag_set, %function
wait_for_I2C1_flag_set:
    ldr r2, =I2C1
    1:
    ldr r1, [r2, I2Cx_ISR]
    tst r1, r0
    beq 1b
    bx lr
.size wait_for_I2C1_flag_set, . - wait_for_I2C1_flag_set


/**
 * Delays execution until the specified flag is reset / clear
 * in the I2C1_ISR register.
 *
 * @param r0 - flag
 */
.type wait_for_I2Cx_flag_reset, %function
wait_for_I2Cx_flag_reset:
    ldr r2, =I2C1
    1:
    ldr r1, [r2, I2Cx_ISR]
    tst r1, r0
    bne 1b
    bx lr
.size wait_for_I2Cx_flag_reset, . - wait_for_I2Cx_flag_reset


.type __HAL_I2C_CLEAR_STOP_FLAG_asm, %function
__HAL_I2C_CLEAR_STOP_FLAG_asm:
    ldr r0, =I2C1
    mov r1, (1 << I2Cx_ICR_STOPF)
    str r1, [r0, I2Cx_ICR]
    bx lr
.size __HAL_I2C_CLEAR_STOP_FLAG_asm, . - __HAL_I2C_CLEAR_STOP_FLAG_asm


.type I2C_RESET_CR2_asm, %function
I2C_RESET_CR2_asm:
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR2]
    ldr r2, 1f
    bic r1, r2
    str r1, [r0, I2Cx_CR2]
    bx lr
    1:
    .word (0x3FF << I2Cx_CR2_SADD0 \
        | 1 << I2Cx_CR2_HEAD10R \
        | 0xFF << I2Cx_CR2_NBYTES \
        | 1 << I2Cx_CR2_RELOAD \
        | 1 << I2Cx_CR2_RD_WRN)
.size I2C_RESET_CR2_asm, . - I2C_RESET_CR2_asm


.type cs43l22_Init_asm, %function
cs43l22_Init_asm:
    push {lr}

    mov r0, 0x02
    mov r1, 0x01
    bl AUDIO_IO_Write_asm

    mov r0, 0x04
    mov r1, 0xAF
    bl AUDIO_IO_Write_asm

    mov r0, 0x05
    mov r1, 0x81
    bl AUDIO_IO_Write_asm

    mov r0, 0x06
    mov r1, 0x04
    bl AUDIO_IO_Write_asm

    mov r0, 60 // VOLUME
    bl cs43l22_SetVolume_asm

    mov r0, 0x0A
    mov r1, 0x00
    bl AUDIO_IO_Write_asm

    mov r0, 0x0E
    mov r1, 0x04
    bl AUDIO_IO_Write_asm

    mov r0, 0x27
    mov r1, 0x00
    bl AUDIO_IO_Write_asm

    mov r0, 0x1F
    mov r1, 0x0F
    bl AUDIO_IO_Write_asm

    mov r0, 0x1A
    mov r1, 0x0A
    bl AUDIO_IO_Write_asm

    mov r0, 0x1B
    mov r1, 0x0A
    bl AUDIO_IO_Write_asm

    mov r0, 0x0E
    mov r1, 0x06
    bl AUDIO_IO_Write_asm

    mov r0, 0x02
    mov r1, 0x9E
    bl AUDIO_IO_Write_asm

    pop {lr}
    bx lr
.size cs43l22_Init_asm, . - cs43l22_Init_asm


/**
 * @param r0 - Volume (0--100)
 */
.type cs43l22_SetVolume_asm, %function
cs43l22_SetVolume_asm:
    push {r4, lr}

    cmp r0, 100
    bgt volume_error

    mov r1, 255
    mov r2, 100
    mul r0, r1
    udiv r0, r2

    cmp r0, 0xE6
    ble 1f
    sub r4, r0, 0xE7
    b 2f
    1:
    add r4, r0, 0x19
    2:

    mov r0, 0x20
    mov r1, r4
    bl AUDIO_IO_Write_asm

    mov r0, 0x21
    mov r1, r4
    bl AUDIO_IO_Write_asm

    pop {r4, lr}
    bx lr

    volume_error:
    b volume_error
.size cs43l22_SetVolume_asm, . - cs43l22_SetVolume_asm


/**
 * @param r0 - Reg
 * @param r1 - Value
 */
.type AUDIO_IO_Write_asm, %function
AUDIO_IO_Write_asm:
    push {r4-r5, lr}
    mov r2, r1

    mov r4, r0
    mov r5, r2

    mov r0, (1 << I2Cx_ISR_BUSY)
    bl wait_for_I2Cx_flag_reset

    mov r0, r4
    mov r1, 1
    bl I2C_RequestMemoryWrite_asm

    mov r0, 1
    mov r1, (1 << I2Cx_CR2_AUTOEND)
    mov r2, 0
    bl I2C_TransferConfig_asm

    mov r0, (1 << I2Cx_ISR_TXIS)
    bl wait_for_I2C1_flag_set

    ldr r0, =I2C1
    str r5, [r0, I2Cx_TXDR]

    mov r0, (1 << I2Cx_ISR_STOPF)
    bl wait_for_I2C1_flag_set

    bl __HAL_I2C_CLEAR_STOP_FLAG_asm

    bl I2C_RESET_CR2_asm

    pop {r4-r5, lr}
    bx lr
.size AUDIO_IO_Write_asm, . - AUDIO_IO_Write_asm


/**
 * @param r0 - MemAddress
 * @param r1 - MemAddSize
 */
.type I2C_RequestMemoryWrite_asm, %function
I2C_RequestMemoryWrite_asm:
    push {r4, lr}
    mov r4, r0

    mov r0, r1
    mov r1, (1 << I2Cx_CR2_RELOAD)
    ldr r2, =(0x80000000)
    orr r2, (1 << I2Cx_CR2_START)
    bl I2C_TransferConfig_asm

    mov r0, (1 << I2Cx_ISR_TXIS)
    bl wait_for_I2C1_flag_set

    ldr r0, =I2C1
    and r1, r4, 0xFF
    str r1, [r0, I2Cx_TXDR]

    mov r0, (1 << I2Cx_ISR_TCR)
    bl wait_for_I2C1_flag_set

    pop {r4, lr}
    bx lr
.size I2C_RequestMemoryWrite_asm, . - I2C_RequestMemoryWrite_asm

















@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.equiv I2C1, 0x40005400
    .equiv I2Cx_CR1, 0x00
        .equiv I2Cx_CR1_PE, 0
        .equiv I2Cx_CR1_TXIE, 1
        .equiv I2Cx_CR1_RXIE, 2
        .equiv I2Cx_CR1_ADDRIE, 3
        .equiv I2Cx_CR1_NACKIE, 4
        .equiv I2Cx_CR1_STOPIE, 5
        .equiv I2Cx_CR1_TCIE, 6
        .equiv I2Cx_CR1_ERRIE, 7
        .equiv I2Cx_CR1_DNF, 8 @ [4]
        .equiv I2Cx_CR1_ANFOFF, 12
        .equiv I2Cx_CR1_TXDMAEN, 14
        .equiv I2Cx_CR1_RXDMAEN, 15
        .equiv I2Cx_CR1_SBC, 16
        .equiv I2Cx_CR1_NOSTRETCH, 17
        .equiv I2Cx_CR1_WUPEN, 18
        .equiv I2Cx_CR1_GCEN, 19
        .equiv I2Cx_CR1_SMBHEN, 20
        .equiv I2Cx_CR1_SMBDEN, 21
        .equiv I2Cx_CR1_ALERTEN, 22
        .equiv I2Cx_CR1_PECEN, 23
    .equiv I2Cx_CR2, 0x04
        .equiv I2Cx_CR2_SADD0, 0
        .equiv I2Cx_CR2_SADD, 1 @ [9]
        .equiv I2Cx_CR2_RD_WRN, 10
        .equiv I2Cx_CR2_ADD10, 11
        .equiv I2Cx_CR2_HEAD10R, 12
        .equiv I2Cx_CR2_START, 13
        .equiv I2Cx_CR2_STOP, 14
        .equiv I2Cx_CR2_NACK, 15
        .equiv I2Cx_CR2_NBYTES, 16 @ [8]
        .equiv I2Cx_CR2_RELOAD, 24
        .equiv I2Cx_CR2_AUTOEND, 25
        .equiv I2Cx_CR2_PECBYTE, 26
    .equiv I2Cx_OAR1, 0x08
        .equiv I2Cx_OAR1_OA1EN, 15
    .equiv I2Cx_OAR2, 0x0C
        .equiv I2Cx_OAR2_OA2, 1 @ [7]
        .equiv I2Cx_OAR2_OA2MSK, 8 @ [3]
        .equiv I2Cx_OAR2_OA2EN, 15
    .equiv I2Cx_TIMINGR, 0x10
    .equiv I2Cx_TIMEOUTR, 0x14
    .equiv I2Cx_ISR, 0x18
        .equiv I2Cx_ISR_TXIS, 1
        .equiv I2Cx_ISR_RXNE, 2
        .equiv I2Cx_ISR_STOPF, 5
        .equiv I2Cx_ISR_TC, 6
        .equiv I2Cx_ISR_TCR, 7
        .equiv I2Cx_ISR_BUSY, 15
    .equiv I2Cx_ICR, 0x1C
        .equiv I2Cx_ICR_STOPF, 5
    .equiv I2Cx_PECR, 0x20
    .equiv I2Cx_RXDR, 0x24
    .equiv I2Cx_TXDR, 0x28
.equiv PWR, 0x40007000
    .equiv PWR_CR1, 0x00
        .equiv PWR_CR1_VOS, 9 @ [2] Voltage range
    .equiv PWR_CR2, 0x04
        .equiv PWR_CR2_IOSV, 9
    .equiv PWR_SR2, 0x14
        .equiv PWR_SR2_VOSF, 10
.equiv SAI1, 0x40015400
    .equiv SAIx_GCR, 0x0
    .equiv SAIx_ACR1, 0x4
        .equiv SAIx_xCR1_MODE,     0
        .equiv SAIx_xCR1_PRTCFG,   2 @ [2]
        .equiv SAIx_xCR1_DS,       5 @ [3]
        .equiv SAIx_xCR1_LSBFIRST, 8
        .equiv SAIx_xCR1_CKSTR,    9
        .equiv SAIx_xCR1_SYNCEN,  10 @ [2]
        .equiv SAIx_xCR1_MONO,    12
        .equiv SAIx_xCR1_OUTDRIV, 13
        .equiv SAIx_xCR1_SAIxEN,  16
        .equiv SAIx_xCR1_DMAEN,   17
        .equiv SAIx_xCR1_NODIV,   19
        .equiv SAIx_xCR1_MCKDIV,  20 @ [4]
    .equiv SAIx_ACR2, 0x8
        .equiv SAIx_xCR2_FTH,     0 @ [3]
        .equiv SAIx_xCR2_FFLUSH,  3
        .equiv SAIx_xCR2_TRIS,    4
        .equiv SAIx_xCR2_MUTE,    5
        .equiv SAIx_xCR2_MUTEVAL, 6
        .equiv SAIx_xCR2_MUTECNT, 7 @ [6]
        .equiv SAIx_xCR2_CPL,    13
        .equiv SAIx_xCR2_COMP,   14 @ [2]
    .equiv SAIx_AFRCR, 0xC
        .equiv SAIx_xFRCR_FRL,    0 @ [8]
        .equiv SAIx_xFRCR_FSALL,  8 @ [7]
        .equiv SAIx_xFRCR_FSDEF, 16
        .equiv SAIx_xFRCR_FSPOL, 17
        .equiv SAIx_xFRCR_FSOFF, 18
    .equiv SAIx_ASLOTR, 0x10
        .equiv SAIx_xSLOTR_FBOFF, 0 @ [5]
        .equiv SAIx_xSLOTR_SLOTSZ, 6 @ [2]
        .equiv SAIx_xSLOTR_NBSLOT, 8 @ [4]
        .equiv SAIx_xSLOTR_SLOTEN, 16 @ [16]
    .equiv SAIx_ASR, 0x18
        .equiv SAIx_xSR_FLVL, 16 @ [3]
    .equiv SAIx_ADR, 0x20
.equiv RCC, 0x40021000
    .equiv RCC_CR, 0x00
        .equiv RCC_CR_MSION,       0 @ MSI enable
        .equiv RCC_CR_MSIRDY,      1 @ MSI clock ready
        .equiv RCC_CR_MSIPLLEN,    2 @ MSI clock PLL enable
        .equiv RCC_CR_MSIRGSEL,    3 @ MSI clock range selection
        .equiv RCC_CR_MSIRANGE,    4 @ [4] MSI clock ranges
        .equiv RCC_CR_HSION,       8 @ HSI16 clock enable
        .equiv RCC_CR_HSIKERON,    9 @ HSI16 always enable for peripheral kernels
        .equiv RCC_CR_HSIRDY,     10 @ HSI16 clock ready
        .equiv RCC_CR_HSIASFS,    11 @ HSI16 automatic start from stop
        .equiv RCC_CR_HSEON,      16 @ HSE clock enable
        .equiv RCC_CR_HSERDY,     17 @ HSE clock ready
        .equiv RCC_CR_HSEBYP,     18 @ HSE crystal oscillator bypass
        .equiv RCC_CR_CSSON,      19 @ Clock security system enable
        .equiv RCC_CR_PLLON,      24 @ Main PLL enable
        .equiv RCC_CR_PLLRDY,     25 @ Main PLL clock ready
        .equiv RCC_CR_PLLSAI1ON,  26 @ SAI1 PLL enable
        .equiv RCC_CR_PLLSAI1RDY, 27 @ SAI1 PLL clock ready
        .equiv RCC_CR_PLLSAI2ON,  28 @ SAI2 PLL enable
        .equiv RCC_CR_PLLSAI2RDY, 29 @ SAI2 PLL clock ready
    .equiv RCC_ICSCR, 0x04
        .equiv RCC_ICSCR_MSICAL,   0 @ [8] MSI clock calibration
        .equiv RCC_ICSCR_MSITRIM,  8 @ [8] MSI clock trimming
        .equiv RCC_ICSCR_HSICAL,  16 @ [8] HSI16 clock calibration
        .equiv RCC_ICSCR_HSITRIM, 24 @ [5] HSI16 clock trimming
    .equiv RCC_CFGR, 0x08
        .equiv RCC_CFGR_SW,        0 @ [2] System clock switch
        .equiv RCC_CFGR_SWS,       2 @ [2] System clock switch status
        .equiv RCC_CFGR_HPRE,      4 @ [4] AHB prescaler
        .equiv RCC_CFGR_PPRE1,     8 @ [3] APB low-speed prescaler (APB1)
        .equiv RCC_CFGR_PPRE2,    11 @ [3] APB high-speed prescaler (APB2)
        .equiv RCC_CFGR_STOPWUCK, 15 @ Wakeup from Stop and CSS backup clock selection
        .equiv RCC_CFGR_MCOSEL,   24 @ [3] Microcontroller clock output
        .equiv RCC_CFGR_MCOPRE,   28 @ [3] Microcontroller clock output prescaler
    .equiv RCC_PLLCFGR, 0x0C
        .equiv RCC_PLLCFGR_PLLSRC,  0 @ [2] Main PLL, PLLSAI1, and PLLSAI2 entry clock source
        .equiv RCC_PLLCFGR_PLLM,    4 @ [3] Division factor for the main PLL and audio PLL input clock
        .equiv RCC_PLLCFGR_PLLN,    8 @ [7] Main PLL multiplication factor for VCO
        .equiv RCC_PLLCFGR_PLLPEN, 16 @ Main PLL PLLSAI3CLK output enable
        .equiv RCC_PLLCFGR_PLLP,   17 @ Main PLL division factor for PLLSAI3CLK (SAI1 & SAI2 clock)
        .equiv RCC_PLLCFGR_PLLQEN, 20 @ Main PLL PLL48M1CLK output enable
        .equiv RCC_PLLCFGR_PLLQ,   21 @ [2] Main PLL division factor for PLL48M1CLK (48 MHz clock)
        .equiv RCC_PLLCFGR_PLLREN, 24 @ Main PLL PLLCLK output enable
        .equiv RCC_PLLCFGR_PLLR,   25 @ [2] Main PLL division factor for PLLCLK (system clock)
    .equiv RCC_PLLSAI1CFGR, 0x10
        .equiv RCC_PLLSAI1CFGR_PLLSAI1N,    8 @ [7] SAI1PLL multiplication factor for VCO
        .equiv RCC_PLLSAI1CFGR_PLLSAI1PEN, 16 @ SAI1PLL PLLSAI1CLK output enable
        .equiv RCC_PLLSAI1CFGR_PLLSAI1P,   17 @ SAI1PLL division factor for PLLSAI1CLK (SAI1 or SAI2 clock)
        .equiv RCC_PLLSAI1CFGR_PLLSAI1QEN, 20 @ SAI1PLL PLL48M2CLK output enable
        .equiv RCC_PLLSAI1CFGR_PLLSAI1Q,   21 @ [2] SAI1PLL division factor for PLL48M2CLK (48 MHz clock)
        .equiv RCC_PLLSAI1CFGR_PLLSAI1REN, 24 @ PLLSAI1 PLLADC1CLK output enable
        .equiv RCC_PLLSAI1CFGR_PLLSAI1R,   25 @ [2] PLLSAI1 division factor for PLLADC1CLK (ADC clock)
    .equiv RCC_PLLSAI2CFGR, 0x14
        .equiv RCC_PLLSAI2CFGR_PLLSAI2N,    8 @ [7] SAI2PLL multiplication factor for VCO
        .equiv RCC_PLLSAI2CFGR_PLLSAI2PEN, 16 @ SAI2PLL PLLSAI2CLK output enable
        .equiv RCC_PLLSAI2CFGR_PLLSAI2P,   17 @ [2] SAI2PLL division factor for PLLSAI2CLK (SAI1 or SAI2 clock)
        .equiv RCC_PLLSAI2CFGR_PLLSAI2REN, 24 @ PLLSAI2 PLLADC2CLK output enable
        .equiv RCC_PLLSAI2CFGR_PLLSAI2R,   25 @ [2] PLLSAI2 division factor for PLLADC2CLK (ADC clock)
    .equiv RCC_CIER, 0x18
        .equiv RCC_CIER_LSIRDYIE,     0 @ LSI ready interrupt enable
        .equiv RCC_CIER_LSERDYIE,     1 @ LSE ready interrupt enable
        .equiv RCC_MSIRDYIE,          2 @ MSI ready interrupt enable
        .equiv RCC_CIER_HSIRDYIE,     3 @ HSI16 ready interrupt enable
        .equiv RCC_CIER_HSERDYIE,     4 @ HSE ready interrupt enable
        .equiv RCC_CIER_PLLRDYIE,     5 @ PLL ready interrupt enable
        .equiv RCC_CIER_PLLSAI1RDYIE, 6 @ PLLSAI1 ready interrupt enable
        .equiv RCC_CIER_PLLSAI2RDYIE, 7 @ PLLSAI2 ready interrupt enable
        .equiv RCC_CIER_LSECSSIE,     9 @ LSE clock security system interrupt enable
    .equiv RCC_CIFR, 0x1C
        .equiv RCC_CIER_LSIRDYF,     0 @ LSI ready interrupt flag
        .equiv RCC_CIER_LSERDYF,     1 @ LSE ready interrupt flag
        .equiv RCC_MSIRDYF,          2 @ MSI ready interrupt flag
        .equiv RCC_CIER_HSIRDYF,     3 @ HSI16 ready interrupt flag
        .equiv RCC_CIER_HSERDYF,     4 @ HSE ready interrupt flag
        .equiv RCC_CIER_PLLRDYF,     5 @ PLL ready interrupt flag
        .equiv RCC_CIER_PLLSAI1RDYF, 6 @ PLLSAI1 ready interrupt flag
        .equiv RCC_CIER_PLLSAI2RDYF, 7 @ PLLSAI2 ready interrupt flag
        .equiv RCC_CIER_LSECSSF,     9 @ LSE clock security system interrupt flag
    .equiv RCC_CICR, 0x20
        .equiv RCC_CIER_LSIRDYC,     0 @ LSI ready interrupt clear
        .equiv RCC_CIER_LSERDYC,     1 @ LSE ready interrupt clear
        .equiv RCC_CIER_MSIRDYC,     2 @ MSI ready interrupt clear
        .equiv RCC_CIER_HSIRDYC,     3 @ HSI16 ready interrupt clear
        .equiv RCC_CIER_HSERDYC,     4 @ HSE ready interrupt clear
        .equiv RCC_CIER_PLLRDYC,     5 @ PLL ready interrupt clear
        .equiv RCC_CIER_PLLSAI1RDYC, 6 @ PLLSAI1 ready interrupt clear
        .equiv RCC_CIER_PLLSAI2RDYC, 7 @ PLLSAI2 ready interrupt clear
        .equiv RCC_CIER_LSECSSC,     9 @ LSE clock security system interrupt clear
    .equiv RCC_APB1RSTR1, 0x38
        .equiv RCC_APB1RSTR1_I2C1RST, 21
    .equiv RCC_AHB2ENR, 0x4C
        .equiv RCC_AHB2ENR_GPIOBEN, 1
        .equiv RCC_AHB2ENR_GPIOEEN, 4
    .equiv RCC_APB1ENR1, 0x58
        .equiv RCC_APB1ENR1_I2C1EN, 21
        .equiv RCC_APB1ENR1_PWREN, 28
    .equiv RCC_APB2ENR, 0x60
        .equiv RCC_APB2ENR_SAI1EN, 21
    .equiv RCC_CCIPR, 0x88
        .equiv RCC_CCIPR_I2C1SEL, 12 @ [2] IC21 clock source selection
        .equiv RCC_CCIPR_SAI1SEL, 22 @ [2] SAI1 clock source selection
.equiv FLASH, 0x40022000
    .equiv FLASH_ACR, 0x00
        .equiv FLASH_ACR_LATENCY, 0
        .equiv FLASH_ACR_PRFTEN,  8
.equiv GPIOB, 0x48000400
.equiv GPIOE, 0x48001000
    .equiv GPIOx_MODER,   0x00
    .equiv GPIOx_OTYPER,  0x04
    .equiv GPIOx_OSPEEDR, 0x08
    .equiv GPIOx_PUPDR,   0x0C
    .equiv GPIOx_ODR,     0x14
    .equiv GPIOx_BSRR,    0x18
    .equiv GPIOx_AFRL,    0x20
    .equiv GPIOx_BRR,     0x28
.equiv NVIC, 0xE000E100
    .equiv NVIC_ISER0, 0x000
    .equiv NVIC_ISER1, 0x004
    .equiv NVIC_IPR7,  0x31C
    .equiv NVIC_IPR8,  0x320
