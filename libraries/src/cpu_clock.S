.syntax unified

@@@@@@@@@@@@
@@ Public @@
@@@@@@@@@@@@

/**
 * Goal: 80 MHz CPU clock, sourced from MSI, through PLL.
 */
.global maximise_clock_speed
.type maximise_clock_speed, %function
maximise_clock_speed:
    // Enable PWR peripheral
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, (1 << RCC_APB1ENR1_PWREN)
    str r1, [r0, RCC_APB1ENR1]

    // Set the voltage range to high performance (this is the default)
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    bic r1, (0b11 << PWR_CR1_VOS)
    orr r1, (0b01 << PWR_CR1_VOS)
    str r1, [r0, PWR_CR1]

    // Check range has set
    check_voltage_range:
    ldr r1, [r0, PWR_SR2]
    tst r1, (1 << PWR_SR2_VOSF)
    bne check_voltage_range

    // Ensure the MSI clock is currently in use. TODO: Handle when not
    ldr r0, =RCC
    ldr r1, [r0, RCC_CFGR]
    ands r2, r1, (0b11 << RCC_CFGR_SWS) @ 0b00 is MSI clock
    beq 1f
    2:
    b 2b // Error

    1:
    // Configure some CR settings
    ldr r1, [r0, RCC_CR]

    // Set MSI clock range
    bic r1, (0b1111 << RCC_CR_MSIRANGE)
    orr r1, (0b0110 << RCC_CR_MSIRANGE)

    // Disable the main PLL
    // NOTE: We are relying on PLL not being SYSCLK here
    bic r1, (1 << RCC_CR_PLLON | 1 << RCC_CR_PLLSAI1ON | 1 << RCC_CR_PLLSAI2ON)

    str r1, [r0, RCC_CR]

    check_pll_disabled:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLRDY | 1 << RCC_CR_PLLSAI1RDY | 1 << RCC_CR_PLLSAI2RDY)
    bne check_pll_disabled

    // Set MSI calibration
    ldr r1, [r0, RCC_ICSCR]
    bic r1, (0xFF << RCC_ICSCR_MSITRIM)
    str r1, [r0, RCC_ICSCR]

    // Configure the PLL clock
    ldr r1, [r0, RCC_PLLCFGR]

    // Set MSI as PLL source
    bic r1, (0b11 << RCC_PLLCFGR_PLLSRC)
    orr r1, (0b01 << RCC_PLLCFGR_PLLSRC)

    // Set PLLR = 2
    bic r1, (0b11 << RCC_PLLCFGR_PLLR)

    // Set PLLQ = 4
    bic r1, (0b11 << RCC_PLLCFGR_PLLQ)
    orr r1, (0b01 << RCC_PLLCFGR_PLLQ)

    // Set PLLP = 7
    bic r1, (1 << RCC_PLLCFGR_PLLP)

    // Set PLLN = 40
    bic r1, (0b1111111 << RCC_PLLCFGR_PLLN)
    orr r1, (0b0101000 << RCC_PLLCFGR_PLLN)

    // Set PLLM = 1
    bic r1, (0b111 << RCC_PLLCFGR_PLLM)

    str r1, [r0, RCC_PLLCFGR]

    // Enable the main PLL
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_PLLON)
    str r1, [r0, RCC_CR]

    // Enable system clock PLL
    ldr r1, [r0, RCC_PLLCFGR]
    orr r1, (1 << RCC_PLLCFGR_PLLREN)
    str r1, [r0, RCC_PLLCFGR]

    // Check the PLL is ready to turn on
    check_pll_ready:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLRDY)
    beq check_pll_ready

    // Set latency to maximum (needed for fast CPU clock) & enable prefetch (optional- Apparently helps performance)
    ldr r0, =FLASH
    ldr r1, [r0, FLASH_ACR]
    bic r1, (0b111 << FLASH_ACR_LATENCY)
    orr r1, (0b100 << FLASH_ACR_LATENCY | 1 << FLASH_ACR_PRFTEN)
    str r1, [r0, FLASH_ACR]

    // Check latency has taken effect
    check_latency:
    ldr r1, [r0, FLASH_ACR]
    and r1, (0b111 << FLASH_ACR_LATENCY)
    cmp r1, (0b100 << FLASH_ACR_LATENCY)
    bne check_latency

    // Set PLL as CPU clock source
    ldr r0, =RCC
    ldr r1, [r0, RCC_CFGR]
    orr r1, (0b11 << RCC_CFGR_SW)
    str r1, [r0, RCC_CFGR]

    // Wait for swap to take effect
    check_cpu_clock_source:
    ldr r1, [r0, RCC_CFGR]
    and r1, (0b11 << RCC_CFGR_SWS)
    cmp r1, (0b11 << RCC_CFGR_SWS)
    bne check_cpu_clock_source

    // Configure some clock prescalers
    ldr r1, [r0, RCC_CFGR]

    // Set the AHB prescaler to no division
    bic r1, (0b1111 << RCC_CFGR_HPRE)

    // Set the APB low-speed prescaler to no division
    bic r1, (0b111 << RCC_CFGR_PPRE1)

    // Set the APB high-speed prescaler to no division
    bic r1, (0b111 << RCC_CFGR_PPRE2)

    str r1, [r0, RCC_CFGR]

    bx lr
.size maximise_clock_speed, . - maximise_clock_speed


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
        .equiv I2Cx_ISR_STOPF, 5
        .equiv I2Cx_ISR_TCR, 7
        .equiv I2Cx_ISR_BUSY, 15
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
        .equiv RCC_PLLSAI1CFGR_PLLSAI1P,   17 @ [2] SAI1PLL division factor for PLLSAI1CLK (SAI1 or SAI2 clock)
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
