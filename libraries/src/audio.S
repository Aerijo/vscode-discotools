.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 1.0.0
 * @brief
 *   This library configures the SAI and external DAC to play sound
 *   at 48 kHz. The clocks must all be pre-configured using `clock_init`.
 *
 *   The general configuration is as follows:
 *   - An external DAC (Cirrus Logic CS43L22) generates analog output in the
 *     headphone jack based on 16-bit digital samples.
 *   - This DAC is clocked by the SAI peripheral. This SAI generates the master clock
 *     (MCLK) that the DAC needs to do work, as well as the SCK which indicates time
 *     to read a new data bit and the FC which controls when the sample is considered
 *     finished. FC also directly controls the sound output frequency.
 *   - The SAI also maintains a FIFO sample buffer that automatically sends samples to the DAC.
 *     It is apparently 8 words large. We configure it and the DAC to use the I2S protocol to
 *     send the data.
 *   - The DAC itself is configured using the I2C bus. This lets us control the power, volume,
 *     data format, etc. As noted above, the output frequency is determined by the MCLK/SCK/FS
 *      clocks provided from the SAI.
 *   - The SAI itself is clocked using a phase-locked loop (PLL) clock. PLLs are interesting
 *     devices that can be used to accurately *multiply* an input clock speed. This means we
 *     use one of the several clocks on the board (HSE, HSI16, MSI, etc.) to generate a much
 *     higher clock speed than the clock itself can output. In our case, we have the MSI clock
 *     at 48 MHz (so RNG can use it), and scale it up to 80 MHz for the SYSCLK (clock driving the CPU),
 *     and down to 49.14 MHz for the SAI peripheral.
 *     NOTE: PLLSAI1 and SAI1 have no particular relation to each other. PLLSAI1 refers to the
 *           PLL clock, SAI1 to one of the actual SAI peripherals.
 *
 *   Relevant links:
 *   - CS43L22: https://www.cirrus.com/products/cs43l22/ (see the data sheet for configuration details)
 *   - I2C bus: https://en.wikipedia.org/wiki/I%C2%B2C
 *   - I2S interface: https://en.wikipedia.org/wiki/I%C2%B2S
 *   - PLLs: https://en.wikipedia.org/wiki/Phase-locked_loop
 *   - STM32L476VG: https://www.st.com/en/microcontrollers-microprocessors/stm32l476vg.html (see the data sheet for clock connections, GPIO alternate functions)
 *   - STM32 Peripherals: https://www.st.com/resource/en/reference_manual/dm00083560-stm32l4x5-and-stm32l4x6-advanced-armbased-32bit-mcus-stmicroelectronics.pdf
 *       (for peripheral register locations and meanings, plus in depth peripheral descriptions)
 *
 * @pins B6, B7, E2-6
 */

.global audio_init
.type audio_init, %function
audio_init:
    push {lr}

    @ Enable PLLSAI1/P
    ldr r0, =RCC
    ldr r1, [r0, RCC_PLLSAI1CFGR]
    orr r1, (1 << RCC_PLLSAI1CFGR_PLLSAI1PEN)
    str r1, [r0, RCC_PLLSAI1CFGR]

    @ Enable PLLSAI1
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_PLLSAI1ON)
    str r1, [r0, RCC_CR]

    @ Wait until change takes effect
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLSAI1RDY)
    beq 1b

    @ Set SAI1 to use PLLSAI1/P clock
    ldr r1, [r0, RCC_CCIPR]
    bic r1, (0b11 << RCC_CCIPR_SAI1SEL)
    str r1, [r0, RCC_CCIPR]

    @ Enable SAI1 clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB2ENR]
    orr r1, (1 << RCC_APB2ENR_SAI1EN)
    str r1, [r0, RCC_APB2ENR]

    @ Enable GPIOB (I2C1) and GPIOE (SAI1) clocks
    ldr r1, [r0, RCC_AHB2ENR]
    orr r1, (1 << RCC_AHB2ENR_GPIOBEN)
    orr r1, (1 << RCC_AHB2ENR_GPIOEEN)
    str r1, [r0, RCC_AHB2ENR]

    @ Set GPIOE pins for SAI1 functionality (STM32L476VGT6 datasheet, 4 Table 17, p84)
    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << GPIOx_MODER_MODE2)
    orr r1, (0b10 << GPIOx_MODER_MODE2)
    bic r1, (0b11 << GPIOx_MODER_MODE4)
    orr r1, (0b10 << GPIOx_MODER_MODE4)
    bic r1, (0b11 << GPIOx_MODER_MODE5)
    orr r1, (0b10 << GPIOx_MODER_MODE5)
    bic r1, (0b11 << GPIOx_MODER_MODE6)
    orr r1, (0b10 << GPIOx_MODER_MODE6)
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << GPIOx_OTYPER_OT2)
    bic r1, (1 << GPIOx_OTYPER_OT4)
    bic r1, (1 << GPIOx_OTYPER_OT5)
    bic r1, (1 << GPIOx_OTYPER_OT6)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED2)
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED4)
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED5)
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED6)
    str r1, [r0, GPIOx_OSPEEDR]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << GPIOx_PUPDR_PUPD2)
    bic r1, (0b11 << GPIOx_PUPDR_PUPD4)
    bic r1, (0b11 << GPIOx_PUPDR_PUPD5)
    bic r1, (0b11 << GPIOx_PUPDR_PUPD6)
    str r1, [r0, GPIOx_PUPDR]

    ldr r1, [r0, GPIOx_AFRL]
    bic r1, (0xF << GPIOx_AFRL_AFSEL2)
    orr r1, (13 << GPIOx_AFRL_AFSEL2)
    bic r1, (0xF << GPIOx_AFRL_AFSEL4)
    orr r1, (13 << GPIOx_AFRL_AFSEL4)
    bic r1, (0xF << GPIOx_AFRL_AFSEL5)
    orr r1, (13 << GPIOx_AFRL_AFSEL5)
    bic r1, (0xF << GPIOx_AFRL_AFSEL6)
    orr r1, (13 << GPIOx_AFRL_AFSEL6)
    str r1, [r0, GPIOx_AFRL]

    @ Disable SAI1
    ldr r0, =SAI1
    ldr r1, [r0, SAIx_ACR1]
    bic r1, (1 << SAIx_xCR1_SAIxEN)
    str r1, [r0, SAIx_ACR1]

    @ Wait for disable to take effect
    1:
    ldr r1, [r0, SAIx_ACR1]
    tst r1, (1 << SAIx_xCR1_SAIxEN)
    bne 1b

    @ Disable syncronisation
    ldr r1, [r0, SAIx_GCR]
    bic r1, (0b11 << SAIx_GCR_SYNCOUT)
    bic r1, (0b11 << SAIx_GCR_SYNCIN)
    str r1, [r0, SAIx_GCR]

    @ Configure SAI1 ACR1
    ldr r1, [r0, SAIx_ACR1]
    bic r1, (0b11 << SAIx_xCR1_MODE)   @ Set to master transmitter mode
    bic r1, (0b11 << SAIx_xCR1_PRTCFG) @ Set to free protocol
    bic r1, (0b111 << SAIx_xCR1_DS)    @ Set to 16 bit data size
    orr r1, (0b100 << SAIx_xCR1_DS)
    bic r1, (1 << SAIx_xCR1_LSBFIRST)  @ Send most significant bit first (expected by DAC in I2S mode)
    orr r1, (1 << SAIx_xCR1_CKSTR)     @ Set clock strobing edge to falling (signals change on SCK falling edge) (I2S)
    bic r1, (0b11 << SAIx_xCR1_SYNCEN) @ Set to asynchronous mode
    orr r1, (1 << SAIx_xCR1_MONO)      @ Set sound to mono output (sample is duplicated for left and right channels)
    orr r1, (1 << SAIx_xCR1_OUTDRIV)   @ Start driving audio block immediately
    orr r1, (1 << SAIx_xCR1_DMAEN)     @ Enable the DMA
    bic r1, (1 << SAIx_xCR1_NODIV)     @ Enable MCLK output
    bic r1, (0b1111 << SAIx_xCR1_MCKDIV) @ Divide the MCLK by 4 (from 49.142857143 MHz to 12.285714286 MHz)
    orr r1, (0b0010 << SAIx_xCR1_MCKDIV)
    str r1, [r0, SAIx_ACR1]

    @ Configure SAI1 ACR2
    ldr r1, [r0, SAIx_ACR2]
    bic r1, (0b111 << SAIx_xCR2_FTH) @ Set FIFO interrupt threshold to 1/2 full
    orr r1, (0b001 << SAIx_xCR2_FTH)
    orr r1, (1 << SAIx_xCR2_FFLUSH)  @ Flush the FIFO of any old data
    bic r1, (1 << SAIx_xCR2_TRIS)    @ Drive SD line low when slot inactive
    bic r1, (1 << SAIx_xCR2_MUTE)    @ Disable mute
    bic r1, (0b11 << SAIx_xCR2_COMP) @ Disable companding
    str r1, [r0, SAIx_ACR2]

    @ Configure SAI1 AFRCR
    ldr r1, [r0, SAIx_AFRCR]
    bic r1, (0xFF << SAIx_xFRCR_FRL)   @ Set frame size to 32 bits, as we are sending two 16 bit samples (left and right channels) (I2S)
    orr r1, (31 << SAIx_xFRCR_FRL)
    bic r1, (0x7F << SAIx_xFRCR_FSALL) @ Set frame synchronisation active level for half the frame size (16)
    orr r1, (0xF << SAIx_xFRCR_FSALL)
    orr r1, (1 << SAIx_xFRCR_FSDEF)    @ Set identification for left and right channels (I2S)
    bic r1, (1 << SAIx_xFRCR_FSPOL)    @ Set polarity to FS active low (falling edge) (I2S)
    orr r1, (1 << SAIx_xFRCR_FSOFF)    @ FS is asserted one bit before the first bit of the slot 0 (I2S)
    str r1, [r0, SAIx_AFRCR]

    @ Configure SAI1 ASLOTR
    ldr r1, [r0, SAIx_ASLOTR]
    bic r1, (0x1F << SAIx_xSLOTR_FBOFF)    @ Set first bit offset to 0
    bic r1, (0b11 << SAIx_xSLOTR_SLOTSZ)   @ Set slot size to equal data size
    bic r1, (0xF << SAIx_xSLOTR_NBSLOT)    @ Set 2 slots per audio frame (I2S)
    orr r1, (1 << SAIx_xSLOTR_NBSLOT)
    .set TMP, 0xFFFF << SAIx_xSLOTR_SLOTEN @ Set first two slots as enabled
    ldr r2, =TMP
    orr r1, (0b11 << SAIx_xSLOTR_SLOTEN)
    str r1, [r0, SAIx_ASLOTR]

    @ Enable SAI1
    ldr r0, =SAI1
    ldr r1, [r0, SAIx_ACR1]
    orr r1, (1 << SAIx_xCR1_SAIxEN)
    str r1, [r0, SAIx_ACR1]

    @ Configure GPIO pin for audio reset line (E3)
    ldr r0, =GPIOE
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << GPIOx_MODER_MODE3)
    orr r1, (0b01 << GPIOx_MODER_MODE3)
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    bic r1, (1 << GPIOx_OTYPER_OT3)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED3)
    str r1, [r0, GPIOx_OSPEEDR]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << GPIOx_PUPDR_PUPD3)
    str r1, [r0, GPIOx_PUPDR]

    @ Set I2C1 clock source to SYSCLK
    ldr r0, =RCC
    ldr r1, [r0, RCC_CCIPR]
    bic r1, (0b11 << RCC_CCIPR_I2C1SEL)
    orr r1, (0b01 << RCC_CCIPR_I2C1SEL)
    str r1, [r0, RCC_CCIPR]

    @ Set GPIOB pins 6 and 7 for I2C1 TX/RX
    ldr r0, =GPIOB
    ldr r1, [r0, GPIOx_MODER]
    bic r1, (0b11 << GPIOx_MODER_MODE6)
    orr r1, (0b10 << GPIOx_MODER_MODE6)
    bic r1, (0b11 << GPIOx_MODER_MODE7)
    orr r1, (0b10 << GPIOx_MODER_MODE7)
    str r1, [r0, GPIOx_MODER]

    ldr r1, [r0, GPIOx_OTYPER]
    orr r1, (1 << GPIOx_OTYPER_OT6)
    orr r1, (1 << GPIOx_OTYPER_OT7)
    str r1, [r0, GPIOx_OTYPER]

    ldr r1, [r0, GPIOx_OSPEEDR]
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED6)
    orr r1, (0b11 << GPIOx_OSPEEDR_OSPEED7)
    str r1, [r0, GPIOx_OSPEEDR]

    ldr r1, [r0, GPIOx_PUPDR]
    bic r1, (0b11 << GPIOx_PUPDR_PUPD6)
    orr r1, (0b01 << GPIOx_PUPDR_PUPD6)
    bic r1, (0b11 << GPIOx_PUPDR_PUPD7)
    orr r1, (0b01 << GPIOx_PUPDR_PUPD7)
    str r1, [r0, GPIOx_PUPDR]

    ldr r1, [r0, GPIOx_AFRL]
    bic r1, (0xF << GPIOx_AFRL_AFSEL6)
    orr r1, (4 << GPIOx_AFRL_AFSEL6)
    bic r1, (0xF << GPIOx_AFRL_AFSEL7)
    orr r1, (4 << GPIOx_AFRL_AFSEL7)
    str r1, [r0, GPIOx_AFRL]

    @ Enable I2C1 clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, (1 << RCC_APB1ENR1_I2C1EN)
    str r1, [r0, RCC_APB1ENR1]

    @ Wait for clock to enable
    1:
    ldr r1, [r0, RCC_APB1ENR1]
    tst r1, (1 << RCC_APB1ENR1_I2C1EN)
    beq 1b

    @ Disable I2C1
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR1]
    bic r1, (1 << I2Cx_CR1_PE)
    str r1, [r0, I2Cx_CR1]

    @ Wait for it to disable
    1:
    ldr r1, [r0, I2Cx_CR1]
    tst r1, (1 << I2Cx_CR1_PE)
    bne 1b

    @ Configure I2C1 CR1
    ldr r1, [r0, I2Cx_CR1]
    bic r1, (0b111 << I2Cx_CR1_DNF) @ disable digital noise filter
    orr r1, (0b000 << I2Cx_CR1_DNF)
    bic r1, (1 << I2Cx_CR1_ANFOFF)  @ disable analog noise filter
    bic r1, (1 << I2Cx_CR1_TXDMAEN) @ Disable DMA transmission
    bic r1, (1 << I2Cx_CR1_RXDMAEN) @ Disable DMA reception
    str r1, [r0, I2Cx_CR1]

    @ Configure I2C1 TIMINGR
    @ NOTE: This sets up various timings that all have various relational
    @       requirements. Typically this would be calculated by an ST tool, but
    @       we just use the value in the stm32l476g_discovery.h file authored
    @       by the MCD Application Team that notes it was picked for an 80 MHz
    @       input clock like we are using.
    ldr r1, =0x90112626
    str r1, [r0, I2Cx_TIMINGR]

    @ Enable I2C1
    ldr r1, [r0, I2Cx_CR1]
    orr r1, (1 << I2Cx_CR1_PE)
    str r1, [r0, I2Cx_CR1]

    @ Wait for enable to take effect
    1:
    ldr r1, [r0, I2Cx_CR1]
    tst r1, (1 << I2Cx_CR1_PE)
    beq 1b

    @ Set audio RESET line high
    ldr r0, =GPIOE
    mov r1, 1 << GPIOx_BSRR_BS3
    str r1, [r0, GPIOx_BSRR]

    @ Verify the DAC ID and revision
    bl cs43l22_verify

    @ Turn off the DAC
    mov r0, CS43L22_PWR1_02
    mov r1, 0x01
    bl cs43l22_write

    @ Enable headphones, disable speakers
    mov r0, CS43L22_PWR2_04
    mov r1, 0xAF
    bl cs43l22_write

    @ Auto detect speed mode & divide MCLK input by 2 (expected ratio is 128:1, fixed in SAI is 256:1)
    mov r0, CS43L22_CLK_05
    mov r1, 0x81
    bl cs43l22_write

    @ Slave mode, I2S format
    mov r0, CS43L22_ITRFC1_06
    mov r1, 0x04
    bl cs43l22_write

    @ Set volume to 50 (out of 0--100)
    mov r0, 50
    bl cs43l22_set_volume

    @ Change volume immediately
    mov r0, CS43L22_ZCSR_0A
    mov r1, 0x00
    bl cs43l22_write

    @ Disable volume soft ramp
    mov r0, CS43L22_MISC_0E
    mov r1, 0x00
    bl cs43l22_write

    @ Disable sound limiter / cushion
    mov r0, CS43L22_LIMITCTRL2_28
    mov r1, 0x00
    bl cs43l22_write

    @ Set treble and bass gain to 0 dB
    mov r0, CS43L22_TONE_1F
    mov r1, 0x88
    bl cs43l22_write

    @ Set volume/gain of PCM data from SDIN (+5 dB)
    mov r0, CS43L22_PCMA_1A
    mov r1, 0x0A
    bl cs43l22_write

    @ As above, for other ear
    mov r0, CS43L22_PCMB_1B
    mov r1, 0x0A
    bl cs43l22_write

    @ Turn on the DAC
    mov r0, CS43L22_PWR1_02
    mov r1, 0x9E
    bl cs43l22_write

    pop {pc}
.size audio_init, . - audio_init


/**
 * Set the volume to an arbitrary number in 0--100
 *
 * @param r0 - new volume level (0--100)
 */
.global cs43l22_set_volume
.type cs43l22_set_volume, %function
cs43l22_set_volume:
    push {r4, lr}

    cmp r0, 100
    bgt 99f

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
    mov r0, CS43L22_MSTVOLA_20
    mov r1, r4
    bl cs43l22_write

    mov r0, CS43L22_MSTVOLB_21
    mov r1, r4
    bl cs43l22_write

    pop {r4, pc}

    99:
    @ Volume error
    nop
    b 99b
.size cs43l22_set_volume, . - cs43l22_set_volume


/**
 * Places the sample in to FIFO buffer to be passed to
 * the DAC.
 *
 * @param r0 - 16 bit sample to output
 */
.global audio_play_sample
.type audio_play_sample, %function
audio_play_sample:
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
 * Reads the external DAC ID and revision number, ensuring
 * it is the right one. Also makes sure the I2C read is
 * working as expected.
 */
.type cs43l22_verify, %function
cs43l22_verify:
    push {lr}

    mov r0, CS43L22_ID_01
    bl cs43l22_read

    lsr r1, r0, 3
    cmp r1, 0b11100
    bne 2f

    and r1, r0, 0b111
    tst r1, 1 << 2
    bne 3f

    pop {pc}

    2:
    @ Device ID wrong
    nop
    b 2b

    3:
    @ Device revision level unexpected
    nop
    b 3b
.size cs43l22_verify, . - cs43l22_verify


/**
 * Reads the value at the provided address
 * @param r0 - address to read from
 * @returns r0 - byte value at address
 */
.global cs43l22_read
.type cs43l22_read, %function
cs43l22_read:
    mov r3, r0

    @ Program I2C1 to send to CS43L22
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR2]
    bic r1, (1 << I2Cx_CR2_RELOAD)
    bic r1, (1 << I2Cx_CR2_AUTOEND)
    bic r1, (1 << I2Cx_CR2_ADD10)     @ it has a 7 bit address
    .set TMP, 0x3FF << I2Cx_CR2_SADD0 @ set 7 bit address to 0x94 (from user manual)
    ldr r2, =TMP
    bic r1, r2
    orr r1, (0x94 << I2Cx_CR2_SADD0)
    bic r1, (1 << I2Cx_CR2_RD_WRN)    @ request a send (sending address)
    bic r1, (0xFF << I2Cx_CR2_NBYTES) @ send 1 byte
    orr r1, (1 << I2Cx_CR2_NBYTES)
    str r1, [r0, I2Cx_CR2]

    @ Send request
    ldr r1, [r0, I2Cx_CR2]
    orr r1, (1 << I2Cx_CR2_START)
    str r1, [r0, I2Cx_CR2]

    @ Wait for ready to send address
    1:
    ldr r1, [r0, I2Cx_ISR]
    tst r1, (1 << I2Cx_ISR_TXIS)
    beq 1b

    @ Send address to read from
    str r3, [r0, I2Cx_TXDR]

    @ Wait for transfer to complete
    1:
    ldr r1, [r0, I2Cx_ISR]
    tst r1, (1 << I2Cx_ISR_TC)
    beq 1b

    @ Program I2C1 to read from CS43L22
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR2]
    @ The address & NBYTES has already been configured above
    orr r1, (1 << I2Cx_CR2_AUTOEND)   @ automatically send stop & NACK reply
    orr r1, (1 << I2Cx_CR2_RD_WRN)    @ request a read
    str r1, [r0, I2Cx_CR2]

    @ Send request
    ldr r1, [r0, I2Cx_CR2]
    orr r1, (1 << I2Cx_CR2_START)
    str r1, [r0, I2Cx_CR2]

    @ Wait for reply to arrive
    @ NOTE: Do not pause and have debugger I2C1 open, as it will read RXDR and reset the flag
    1:
    ldr r1, [r0, I2Cx_ISR]
    tst r1, (1 << I2Cx_ISR_RXNE)
    beq 1b

    @ Read reply
    ldr r0, [r0, I2Cx_RXDR]

    @ Clear stop flag
    ldr r2, =I2C1
    mov r1, (1 << I2Cx_ICR_STOPF)
    str r1, [r2, I2Cx_ICR]

    bx lr
.size cs43l22_read, . - cs43l22_read


/**
 * Writes the value to the provided address
 *
 * @param r0 - address to send to
 * @param r1 - byte data to send
 */
.global cs43l22_write
.type cs43l22_write, %function
cs43l22_write:
    mov r2, r0
    mov r3, r1

    @ Program I2C1 to send to CS43L22
    ldr r0, =I2C1
    ldr r1, [r0, I2Cx_CR2]
    bic r1, (1 << I2Cx_CR2_RELOAD)
    orr r1, (1 << I2Cx_CR2_AUTOEND)
    bic r1, (1 << I2Cx_CR2_ADD10)     @ it has a 7 bit address
    bic r1, (0xFF << I2Cx_CR2_SADD0)  @ set 7 bit address to 0x94 (from user manual)
    orr r1, (0x94 << I2Cx_CR2_SADD0)
    bic r1, (1 << I2Cx_CR2_RD_WRN)    @ request a send (sending address)
    bic r1, (0xFF << I2Cx_CR2_NBYTES) @ send 2 bytes
    orr r1, (2 << I2Cx_CR2_NBYTES)
    str r1, [r0, I2Cx_CR2]

    @ Send request
    ldr r1, [r0, I2Cx_CR2]
    orr r1, (1 << I2Cx_CR2_START)
    str r1, [r0, I2Cx_CR2]

    @ Wait for ready to send address
    1:
    ldr r1, [r0, I2Cx_ISR]
    tst r1, (1 << I2Cx_ISR_TXIS)
    beq 1b

    @ Send address to write to
    str r2, [r0, I2Cx_TXDR]

    @ Wait for ready to send data
    1:
    ldr r1, [r0, I2Cx_ISR]
    tst r1, (1 << I2Cx_ISR_TXIS)
    beq 1b

    @ Send data
    str r3, [r0, I2Cx_TXDR]

    @ Clear stop flag
    ldr r2, =I2C1
    mov r1, (1 << I2Cx_ICR_STOPF)
    str r1, [r2, I2Cx_ICR]

    bx lr
.size cs43l22_write, . - cs43l22_write


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.set I2C1, 0x40005400
    .set I2Cx_CR1, 0x00
        .set I2Cx_CR1_PE, 0
        .set I2Cx_CR1_TXIE, 1
        .set I2Cx_CR1_RXIE, 2
        .set I2Cx_CR1_ADDRIE, 3
        .set I2Cx_CR1_NACKIE, 4
        .set I2Cx_CR1_STOPIE, 5
        .set I2Cx_CR1_TCIE, 6
        .set I2Cx_CR1_ERRIE, 7
        .set I2Cx_CR1_DNF, 8 @ [4]
        .set I2Cx_CR1_ANFOFF, 12
        .set I2Cx_CR1_TXDMAEN, 14
        .set I2Cx_CR1_RXDMAEN, 15
        .set I2Cx_CR1_SBC, 16
        .set I2Cx_CR1_NOSTRETCH, 17
        .set I2Cx_CR1_WUPEN, 18
        .set I2Cx_CR1_GCEN, 19
        .set I2Cx_CR1_SMBHEN, 20
        .set I2Cx_CR1_SMBDEN, 21
        .set I2Cx_CR1_ALERTEN, 22
        .set I2Cx_CR1_PECEN, 23
    .set I2Cx_CR2, 0x04
        .set I2Cx_CR2_SADD0, 0
        .set I2Cx_CR2_SADD, 1 @ [9]
        .set I2Cx_CR2_RD_WRN, 10
        .set I2Cx_CR2_ADD10, 11
        .set I2Cx_CR2_HEAD10R, 12
        .set I2Cx_CR2_START, 13
        .set I2Cx_CR2_STOP, 14
        .set I2Cx_CR2_NACK, 15
        .set I2Cx_CR2_NBYTES, 16 @ [8]
        .set I2Cx_CR2_RELOAD, 24
        .set I2Cx_CR2_AUTOEND, 25
        .set I2Cx_CR2_PECBYTE, 26
    .set I2Cx_OAR1, 0x08
        .set I2Cx_OAR1_OA1EN, 15
    .set I2Cx_OAR2, 0x0C
        .set I2Cx_OAR2_OA2, 1 @ [7]
        .set I2Cx_OAR2_OA2MSK, 8 @ [3]
        .set I2Cx_OAR2_OA2EN, 15
    .set I2Cx_TIMINGR, 0x10
    .set I2Cx_TIMEOUTR, 0x14
    .set I2Cx_ISR, 0x18
        .set I2Cx_ISR_TXIS, 1
        .set I2Cx_ISR_RXNE,2
        .set I2Cx_ISR_STOPF, 5
        .set I2Cx_ISR_TC, 6
        .set I2Cx_ISR_TCR, 7
        .set I2Cx_ISR_BUSY, 15
    .set I2Cx_ICR, 0x1C
        .set I2Cx_ICR_STOPF, 5
    .set I2Cx_PECR, 0x20
    .set I2Cx_RXDR, 0x24
    .set I2Cx_TXDR, 0x28
.set PWR, 0x40007000
    .set PWR_CR1, 0x00
        .set PWR_CR1_DBP, 8
        .set PWR_CR1_VOS, 9 @ [2] Voltage range
    .set PWR_CR2, 0x04
        .set PWR_CR2_IOSV, 9
    .set PWR_SR2, 0x14
        .set PWR_SR2_VOSF, 10
.set SAI1, 0x40015400
    .set SAIx_GCR, 0x0
        .set SAIx_GCR_SYNCIN, 0 @ [2]
        .set SAIx_GCR_SYNCOUT, 4 @ [2]
    .set SAIx_ACR1, 0x4
        .set SAIx_xCR1_MODE,     0
        .set SAIx_xCR1_PRTCFG,   2 @ [2]
        .set SAIx_xCR1_DS,       5 @ [3]
        .set SAIx_xCR1_LSBFIRST, 8
        .set SAIx_xCR1_CKSTR,    9
        .set SAIx_xCR1_SYNCEN,  10 @ [2]
        .set SAIx_xCR1_MONO,    12
        .set SAIx_xCR1_OUTDRIV, 13
        .set SAIx_xCR1_SAIxEN,  16
        .set SAIx_xCR1_DMAEN,   17
        .set SAIx_xCR1_NODIV,   19
        .set SAIx_xCR1_MCKDIV,  20 @ [4]
    .set SAIx_ACR2, 0x8
        .set SAIx_xCR2_FTH,     0 @ [3]
        .set SAIx_xCR2_FFLUSH,  3
        .set SAIx_xCR2_TRIS,    4
        .set SAIx_xCR2_MUTE,    5
        .set SAIx_xCR2_MUTEVAL, 6
        .set SAIx_xCR2_MUTECNT, 7 @ [6]
        .set SAIx_xCR2_CPL,    13
        .set SAIx_xCR2_COMP,   14 @ [2]
    .set SAIx_AFRCR, 0xC
        .set SAIx_xFRCR_FRL,    0 @ [8]
        .set SAIx_xFRCR_FSALL,  8 @ [7]
        .set SAIx_xFRCR_FSDEF, 16
        .set SAIx_xFRCR_FSPOL, 17
        .set SAIx_xFRCR_FSOFF, 18
    .set SAIx_ASLOTR, 0x10
        .set SAIx_xSLOTR_FBOFF, 0 @ [5]
        .set SAIx_xSLOTR_SLOTSZ, 6 @ [2]
        .set SAIx_xSLOTR_NBSLOT, 8 @ [4]
        .set SAIx_xSLOTR_SLOTEN, 16 @ [16]
    .set SAIx_ASR, 0x18
        .set SAIx_xSR_FLVL, 16 @ [3]
    .set SAIx_ADR, 0x20
.set RCC, 0x40021000
    .set RCC_CR, 0x00
        .set RCC_CR_MSION,       0 @ MSI enable
        .set RCC_CR_MSIRDY,      1 @ MSI clock ready
        .set RCC_CR_MSIPLLEN,    2 @ MSI clock PLL enable
        .set RCC_CR_MSIRGSEL,    3 @ MSI clock range selection
        .set RCC_CR_MSIRANGE,    4 @ [4] MSI clock ranges
        .set RCC_CR_HSION,       8 @ HSI16 clock enable
        .set RCC_CR_HSIKERON,    9 @ HSI16 always enable for peripheral kernels
        .set RCC_CR_HSIRDY,     10 @ HSI16 clock ready
        .set RCC_CR_HSIASFS,    11 @ HSI16 automatic start from stop
        .set RCC_CR_HSEON,      16 @ HSE clock enable
        .set RCC_CR_HSERDY,     17 @ HSE clock ready
        .set RCC_CR_HSEBYP,     18 @ HSE crystal oscillator bypass
        .set RCC_CR_CSSON,      19 @ Clock security system enable
        .set RCC_CR_PLLON,      24 @ Main PLL enable
        .set RCC_CR_PLLRDY,     25 @ Main PLL clock ready
        .set RCC_CR_PLLSAI1ON,  26 @ SAI1 PLL enable
        .set RCC_CR_PLLSAI1RDY, 27 @ SAI1 PLL clock ready
        .set RCC_CR_PLLSAI2ON,  28 @ SAI2 PLL enable
        .set RCC_CR_PLLSAI2RDY, 29 @ SAI2 PLL clock ready
    .set RCC_ICSCR, 0x04
        .set RCC_ICSCR_MSICAL,   0 @ [8] MSI clock calibration
        .set RCC_ICSCR_MSITRIM,  8 @ [8] MSI clock trimming
        .set RCC_ICSCR_HSICAL,  16 @ [8] HSI16 clock calibration
        .set RCC_ICSCR_HSITRIM, 24 @ [5] HSI16 clock trimming
    .set RCC_CFGR, 0x08
        .set RCC_CFGR_SW,        0 @ [2] System clock switch
        .set RCC_CFGR_SWS,       2 @ [2] System clock switch status
        .set RCC_CFGR_HPRE,      4 @ [4] AHB prescaler
        .set RCC_CFGR_PPRE1,     8 @ [3] APB low-speed prescaler (APB1)
        .set RCC_CFGR_PPRE2,    11 @ [3] APB high-speed prescaler (APB2)
        .set RCC_CFGR_STOPWUCK, 15 @ Wakeup from Stop and CSS backup clock selection
        .set RCC_CFGR_MCOSEL,   24 @ [3] Microcontroller clock output
        .set RCC_CFGR_MCOPRE,   28 @ [3] Microcontroller clock output prescaler
    .set RCC_PLLCFGR, 0x0C
        .set RCC_PLLCFGR_PLLSRC,  0 @ [2] Main PLL, PLLSAI1, and PLLSAI2 entry clock source
        .set RCC_PLLCFGR_PLLM,    4 @ [3] Division factor for the main PLL and audio PLL input clock
        .set RCC_PLLCFGR_PLLN,    8 @ [7] Main PLL multiplication factor for VCO
        .set RCC_PLLCFGR_PLLPEN, 16 @ Main PLL PLLSAI3CLK output enable
        .set RCC_PLLCFGR_PLLP,   17 @ Main PLL division factor for PLLSAI3CLK (SAI1 & SAI2 clock)
        .set RCC_PLLCFGR_PLLQEN, 20 @ Main PLL PLL48M1CLK output enable
        .set RCC_PLLCFGR_PLLQ,   21 @ [2] Main PLL division factor for PLL48M1CLK (48 MHz clock)
        .set RCC_PLLCFGR_PLLREN, 24 @ Main PLL PLLCLK output enable
        .set RCC_PLLCFGR_PLLR,   25 @ [2] Main PLL division factor for PLLCLK (system clock)
    .set RCC_PLLSAI1CFGR, 0x10
        .set RCC_PLLSAI1CFGR_PLLSAI1N,    8 @ [7] SAI1PLL multiplication factor for VCO
        .set RCC_PLLSAI1CFGR_PLLSAI1PEN, 16 @ SAI1PLL PLLSAI1CLK output enable
        .set RCC_PLLSAI1CFGR_PLLSAI1P,   17 @ [2] SAI1PLL division factor for PLLSAI1CLK (SAI1 or SAI2 clock)
        .set RCC_PLLSAI1CFGR_PLLSAI1QEN, 20 @ SAI1PLL PLL48M2CLK output enable
        .set RCC_PLLSAI1CFGR_PLLSAI1Q,   21 @ [2] SAI1PLL division factor for PLL48M2CLK (48 MHz clock)
        .set RCC_PLLSAI1CFGR_PLLSAI1REN, 24 @ PLLSAI1 PLLADC1CLK output enable
        .set RCC_PLLSAI1CFGR_PLLSAI1R,   25 @ [2] PLLSAI1 division factor for PLLADC1CLK (ADC clock)
    .set RCC_PLLSAI2CFGR, 0x14
        .set RCC_PLLSAI2CFGR_PLLSAI2N,    8 @ [7] SAI2PLL multiplication factor for VCO
        .set RCC_PLLSAI2CFGR_PLLSAI2PEN, 16 @ SAI2PLL PLLSAI2CLK output enable
        .set RCC_PLLSAI2CFGR_PLLSAI2P,   17 @ [2] SAI2PLL division factor for PLLSAI2CLK (SAI1 or SAI2 clock)
        .set RCC_PLLSAI2CFGR_PLLSAI2REN, 24 @ PLLSAI2 PLLADC2CLK output enable
        .set RCC_PLLSAI2CFGR_PLLSAI2R,   25 @ [2] PLLSAI2 division factor for PLLADC2CLK (ADC clock)
    .set RCC_CIER, 0x18
        .set RCC_CIER_LSIRDYIE,     0 @ LSI ready interrupt enable
        .set RCC_CIER_LSERDYIE,     1 @ LSE ready interrupt enable
        .set RCC_MSIRDYIE,          2 @ MSI ready interrupt enable
        .set RCC_CIER_HSIRDYIE,     3 @ HSI16 ready interrupt enable
        .set RCC_CIER_HSERDYIE,     4 @ HSE ready interrupt enable
        .set RCC_CIER_PLLRDYIE,     5 @ PLL ready interrupt enable
        .set RCC_CIER_PLLSAI1RDYIE, 6 @ PLLSAI1 ready interrupt enable
        .set RCC_CIER_PLLSAI2RDYIE, 7 @ PLLSAI2 ready interrupt enable
        .set RCC_CIER_LSECSSIE,     9 @ LSE clock security system interrupt enable
    .set RCC_CIFR, 0x1C
        .set RCC_CIER_LSIRDYF,     0 @ LSI ready interrupt flag
        .set RCC_CIER_LSERDYF,     1 @ LSE ready interrupt flag
        .set RCC_MSIRDYF,          2 @ MSI ready interrupt flag
        .set RCC_CIER_HSIRDYF,     3 @ HSI16 ready interrupt flag
        .set RCC_CIER_HSERDYF,     4 @ HSE ready interrupt flag
        .set RCC_CIER_PLLRDYF,     5 @ PLL ready interrupt flag
        .set RCC_CIER_PLLSAI1RDYF, 6 @ PLLSAI1 ready interrupt flag
        .set RCC_CIER_PLLSAI2RDYF, 7 @ PLLSAI2 ready interrupt flag
        .set RCC_CIER_LSECSSF,     9 @ LSE clock security system interrupt flag
    .set RCC_CICR, 0x20
        .set RCC_CIER_LSIRDYC,     0 @ LSI ready interrupt clear
        .set RCC_CIER_LSERDYC,     1 @ LSE ready interrupt clear
        .set RCC_CIER_MSIRDYC,     2 @ MSI ready interrupt clear
        .set RCC_CIER_HSIRDYC,     3 @ HSI16 ready interrupt clear
        .set RCC_CIER_HSERDYC,     4 @ HSE ready interrupt clear
        .set RCC_CIER_PLLRDYC,     5 @ PLL ready interrupt clear
        .set RCC_CIER_PLLSAI1RDYC, 6 @ PLLSAI1 ready interrupt clear
        .set RCC_CIER_PLLSAI2RDYC, 7 @ PLLSAI2 ready interrupt clear
        .set RCC_CIER_LSECSSC,     9 @ LSE clock security system interrupt clear
    .set RCC_APB1RSTR1, 0x38
        .set RCC_APB1RSTR1_I2C1RST, 21
    .set RCC_AHB2ENR, 0x4C
        .set RCC_AHB2ENR_GPIOBEN, 1
        .set RCC_AHB2ENR_GPIOEEN, 4
    .set RCC_APB1ENR1, 0x58
        .set RCC_APB1ENR1_I2C1EN, 21
        .set RCC_APB1ENR1_PWREN, 28
    .set RCC_APB2ENR, 0x60
        .set RCC_APB2ENR_SAI1EN, 21
    .set RCC_CCIPR, 0x88
        .set RCC_CCIPR_I2C1SEL, 12 @ [2] I2C1 clock source selection
        .set RCC_CCIPR_SAI1SEL, 22 @ [2] SAI1 clock source selection
        .set RCC_CCIPR_CLK48SEL, 26 @ [2] USB, RNG clock source selection
    .set RCC_BDCR, 0x90
        .set RCC_BDCR_LSEON, 0
        .set RCC_BDCR_LSERDY, 1
.set FLASH, 0x40022000
    .set FLASH_ACR, 0x00
        .set FLASH_ACR_LATENCY, 0
        .set FLASH_ACR_PRFTEN,  8
.set GPIOB, 0x48000400
.set GPIOE, 0x48001000
    .set GPIOx_MODER,   0x00
        .set GPIOx_MODER_MODE0, 0 @ [2]
        .set GPIOx_MODER_MODE1, 2 @ [2]
        .set GPIOx_MODER_MODE2, 4 @ [2]
        .set GPIOx_MODER_MODE3, 6 @ [2]
        .set GPIOx_MODER_MODE4, 8 @ [2]
        .set GPIOx_MODER_MODE5, 10 @ [2]
        .set GPIOx_MODER_MODE6, 12 @ [2]
        .set GPIOx_MODER_MODE7, 14 @ [2]
        .set GPIOx_MODER_MODE8, 16 @ [2]
        .set GPIOx_MODER_MODE9, 18 @ [2]
        .set GPIOx_MODER_MODE10, 20 @ [2]
        .set GPIOx_MODER_MODE11, 22 @ [2]
        .set GPIOx_MODER_MODE12, 24 @ [2]
        .set GPIOx_MODER_MODE13, 26 @ [2]
        .set GPIOx_MODER_MODE14, 28 @ [2]
        .set GPIOx_MODER_MODE15, 30 @ [2]
    .set GPIOx_OTYPER,  0x04
        .set GPIOx_OTYPER_OT0, 0
        .set GPIOx_OTYPER_OT1, 1
        .set GPIOx_OTYPER_OT2, 2
        .set GPIOx_OTYPER_OT3, 3
        .set GPIOx_OTYPER_OT4, 4
        .set GPIOx_OTYPER_OT5, 5
        .set GPIOx_OTYPER_OT6, 6
        .set GPIOx_OTYPER_OT7, 7
        .set GPIOx_OTYPER_OT8, 8
        .set GPIOx_OTYPER_OT9, 9
        .set GPIOx_OTYPER_OT10, 10
        .set GPIOx_OTYPER_OT11, 11
        .set GPIOx_OTYPER_OT12, 12
        .set GPIOx_OTYPER_OT13, 13
        .set GPIOx_OTYPER_OT14, 14
        .set GPIOx_OTYPER_OT15, 15
    .set GPIOx_OSPEEDR, 0x08
        .set GPIOx_OSPEEDR_OSPEED0, 0 @ [2]
        .set GPIOx_OSPEEDR_OSPEED1, 2 @ [2]
        .set GPIOx_OSPEEDR_OSPEED2, 4 @ [2]
        .set GPIOx_OSPEEDR_OSPEED3, 6 @ [2]
        .set GPIOx_OSPEEDR_OSPEED4, 8 @ [2]
        .set GPIOx_OSPEEDR_OSPEED5, 10 @ [2]
        .set GPIOx_OSPEEDR_OSPEED6, 12 @ [2]
        .set GPIOx_OSPEEDR_OSPEED7, 14 @ [2]
        .set GPIOx_OSPEEDR_OSPEED8, 16 @ [2]
        .set GPIOx_OSPEEDR_OSPEED9, 18 @ [2]
        .set GPIOx_OSPEEDR_OSPEED10, 20 @ [2]
        .set GPIOx_OSPEEDR_OSPEED11, 22 @ [2]
        .set GPIOx_OSPEEDR_OSPEED12, 24 @ [2]
        .set GPIOx_OSPEEDR_OSPEED13, 26 @ [2]
        .set GPIOx_OSPEEDR_OSPEED14, 28 @ [2]
        .set GPIOx_OSPEEDR_OSPEED15, 30 @ [2]
    .set GPIOx_PUPDR,   0x0C
        .set GPIOx_PUPDR_PUPD0, 0 @ [2]
        .set GPIOx_PUPDR_PUPD1, 2 @ [2]
        .set GPIOx_PUPDR_PUPD2, 4 @ [2]
        .set GPIOx_PUPDR_PUPD3, 6 @ [2]
        .set GPIOx_PUPDR_PUPD4, 8 @ [2]
        .set GPIOx_PUPDR_PUPD5, 10 @ [2]
        .set GPIOx_PUPDR_PUPD6, 12 @ [2]
        .set GPIOx_PUPDR_PUPD7, 14 @ [2]
        .set GPIOx_PUPDR_PUPD8, 16 @ [2]
        .set GPIOx_PUPDR_PUPD9, 18 @ [2]
        .set GPIOx_PUPDR_PUPD10, 20 @ [2]
        .set GPIOx_PUPDR_PUPD11, 22 @ [2]
        .set GPIOx_PUPDR_PUPD12, 24 @ [2]
        .set GPIOx_PUPDR_PUPD13, 26 @ [2]
        .set GPIOx_PUPDR_PUPD14, 28 @ [2]
        .set GPIOx_PUPDR_PUPD15, 30 @ [2]
    .set GPIOx_ODR,     0x14
    .set GPIOx_BSRR,    0x18
        .set GPIOx_BSRR_BS0, 0
        .set GPIOx_BSRR_BS1, 1
        .set GPIOx_BSRR_BS2, 2
        .set GPIOx_BSRR_BS3, 3
        .set GPIOx_BSRR_BS4, 4
        .set GPIOx_BSRR_BS5, 5
        .set GPIOx_BSRR_BS6, 6
        .set GPIOx_BSRR_BS7, 7
        .set GPIOx_BSRR_BS8, 8
        .set GPIOx_BSRR_BS9, 9
        .set GPIOx_BSRR_BS10, 10
        .set GPIOx_BSRR_BS11, 11
        .set GPIOx_BSRR_BS12, 12
        .set GPIOx_BSRR_BS13, 13
        .set GPIOx_BSRR_BS14, 14
        .set GPIOx_BSRR_BS15, 15
        .set GPIOx_BSRR_BR0, 16
        .set GPIOx_BSRR_BR1, 17
        .set GPIOx_BSRR_BR2, 18
        .set GPIOx_BSRR_BR3, 19
        .set GPIOx_BSRR_BR4, 20
        .set GPIOx_BSRR_BR5, 21
        .set GPIOx_BSRR_BR6, 22
        .set GPIOx_BSRR_BR7, 23
        .set GPIOx_BSRR_BR8, 24
        .set GPIOx_BSRR_BR9, 25
        .set GPIOx_BSRR_BR10, 26
        .set GPIOx_BSRR_BR11, 27
        .set GPIOx_BSRR_BR12, 28
        .set GPIOx_BSRR_BR13, 29
        .set GPIOx_BSRR_BR14, 30
        .set GPIOx_BSRR_BR15, 31
    .set GPIOx_AFRL,    0x20
        .set GPIOx_AFRL_AFSEL0, 0 @ [4]
        .set GPIOx_AFRL_AFSEL1, 4 @ [4]
        .set GPIOx_AFRL_AFSEL2, 8 @ [4]
        .set GPIOx_AFRL_AFSEL3, 12 @ [4]
        .set GPIOx_AFRL_AFSEL4, 16 @ [4]
        .set GPIOx_AFRL_AFSEL5, 20 @ [4]
        .set GPIOx_AFRL_AFSEL6, 24 @ [4]
        .set GPIOx_AFRL_AFSEL7, 28 @ [4]
    .set GPIOx_BRR,     0x28
.set CS43L22, 0x94
    .set CS43L22_ID_01, 0x01
    .set CS43L22_PWR1_02, 0x02
    .set CS43L22_PWR2_04, 0x04
    .set CS43L22_CLK_05, 0x05
    .set CS43L22_ITRFC1_06, 0x06
    .set CS43L22_ZCSR_0A, 0x0A
    .set CS43L22_MISC_0E, 0x0E
    .set CS43L22_PCMA_1A, 0x1A
    .set CS43L22_PCMB_1B, 0x1B
    .set CS43L22_TONE_1F, 0x1F
    .set CS43L22_MSTVOLA_20, 0x20
    .set CS43L22_MSTVOLB_21, 0x21
    .set CS43L22_LIMITCTRL2_28, 0x28
