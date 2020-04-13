.syntax unified

/**
 * @author Benjamin Gray
 * @license MIT
 * @version 1.0.0
 * @brief
 *   Library to configure the board clocks for maximum speed + audio support + RNG support
 *
 *   The board has several builin clocks. These clocks can be connected to various multipliers
 *   and dividers, and the resulting signals can be passed to to the various peripherals. See
 *   the STM32L476VGT6 Data Sheet 3.11 Figure 3 for a complete diagram of the connections.
 *
 *   This library is designed for
 *   - maximum performance (80 MHz system clock)
 *   - 48 kHz audio using SAI1
 *   - RNG peripheral support
 *
 *   We attempt this with:
 *   - MSI @ 48 MHz + LSE calibration
 *   - Pass this MSI directly to RNG
 *   - Divide by 6 to get 8MHz PLL VCO input
 *   - Multiply by 20 to get PLL input (160 MHz)
 *   - Divide by 2 to get 80 MHz SYSCLK
 *   - Multiply by 43 to get PLLSAI1 input (344 MHz)
 *   - Divide by 7 to get 49.142857143 MHz SAI1 input
 *   - Divide by 4 to get 12.285714286 MHz MCLK (47.991071 kHz FS freq)
 *
 *   The sample frequency is determined by the FS frequency (1:1). The FS
 *   frequency is fixed at 1/256 the master clock frequency. Therefore, the MCLK
 *   must come out to 12.288 MHz for 48 kHz sound, or 24.576 MHz for 96 kHz. The MCLK
 *   value can be SAI1 clock input divided by 1, 2, 4, 6, etc.
 *
 *   As we are using I2S, we send two 16 bit samples per frame, so the SCK frequency
 *   must be 32 times the FS frequency. This is trivially done by setting the frame size to 32.
 *
 *   The closest frequency to 48 kHz we can achieve is 47991.07142857143 kHz (8.928571428572468 Hz difference).
 *   This was verified by running a script that iterated all combinations of clock speeds.
 *
 *   This configures the MSI clock, PLL input, PLL clock, and PLLSAI1 clock to expected values. PLLSAI2 is
 *   not used.
 */


/**
 * Configures the clocks (specifically MSI + PLLs) to be usable for audio and RNG.
 *
 * Overview:
 * 1. Set voltage range to high performance (5.1.8)
 * 2. Set FLASH read access latency to highest (3.3.3)
 * 3. Set instruction prefetch (3.3.4)
 * 4. Configure the clocks
 */
.global clock_init
.type clock_init, %function
clock_init:
    @ Enable PWR peripheral
    ldr r0, =RCC
    ldr r1, [r0, RCC_APB1ENR1]
    orr r1, (1 << RCC_APB1ENR1_PWREN)
    str r1, [r0, RCC_APB1ENR1]

    @ Set voltage range to Range 1 (high performance)
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    bic r1, (0b11 << PWR_CR1_VOS)
    orr r1, (0b01 << PWR_CR1_VOS)
    str r1, [r0, PWR_CR1]

    @ Wait for change to take effect
    1:
    ldr r1, [r0, PWR_SR2]
    tst r1, (1 << PWR_SR2_VOSF)
    bne 1b

    @ Set the FLASH latency to handle an 80 MHz SYSCLK (3.3.3-1) & enable instruction prefetch (optional)
    ldr r0, =FLASH
    ldr r1, [r0, FLASH_ACR]
    bic r1, (0b111 << FLASH_ACR_LATENCY)
    orr r1, (0b100 << FLASH_ACR_LATENCY | 1 << FLASH_ACR_PRFTEN)
    str r1, [r0, FLASH_ACR]

    @ Wait for change to take effect (3.3.3-2)
    1:
    ldr r1, [r0, FLASH_ACR]
    and r1, (0b111 << FLASH_ACR_LATENCY)
    cmp r1, (0b100 << FLASH_ACR_LATENCY)
    bne 1b

    @ Turn on MSI clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_MSION)
    str r1, [r0, RCC_CR]

    @ Wait for MSI clock to be ready
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_MSIRDY)
    beq 1b

    @ Set MSI freq to 48 MHz (NOTE: Must not modify unless MSI off, or MSI ready)
    ldr r1, [r0, RCC_CR]
    bic r1, (0b1111 << RCC_CR_MSIRANGE)
    orr r1, (0b1011 << RCC_CR_MSIRANGE)
    str r1, [r0, RCC_CR]

    @ Set MSI to use RCC_CR_MSIRANGE for MSI freq
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_MSIRGSEL)
    str r1, [r0, RCC_CR]

    @ Remove write protection of backup domain (5.1.5)
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    orr r1, (1 << PWR_CR1_DBP)
    str r1, [r0, PWR_CR1]

    @ Enable LSE clock
    ldr r0, =RCC
    ldr r1, [r0, RCC_BDCR]
    orr r1, (1 << RCC_BDCR_LSEON)
    str r1, [r0, RCC_BDCR]

    @ Restore write protection of backup domain
    ldr r0, =PWR
    ldr r1, [r0, PWR_CR1]
    bic r1, (1 << PWR_CR1_DBP)
    str r1, [r0, PWR_CR1]

    @ Wait for LSE clock to stabilise
    ldr r0, =RCC
    1:
    ldr r1, [r0, RCC_BDCR]
    tst r1, (1 << RCC_BDCR_LSERDY)
    beq 1b

    @ Set MSI clock to be calibrated by LSE clock
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_MSIPLLEN)
    str r1, [r0, RCC_CR]

    @ Wait for MSI clock to be ready
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_MSIRDY)
    beq 1b

    @ Set SYSCLK to use MSI clock
    ldr r1, [r0, RCC_CFGR]
    bic r1, (0b11 << RCC_CFGR_SW)
    str r1, [r0, RCC_CFGR]

    @ Wait for change to take effect
    1:
    ldr r1, [r0, RCC_CFGR]
    and r1, (0b11 << RCC_CFGR_SWS)
    cmp r1, (0b00 << RCC_CFGR_SWS)
    bne 1b

    @ Set APB1, APB2, AHB clock divisions to not divided
    ldr r1, [r0, RCC_CFGR]
    bic r1, (0b111 << RCC_CFGR_PPRE1)
    bic r1, (0b111 << RCC_CFGR_PPRE2)
    bic r1, (0b1111 << RCC_CFGR_HPRE)
    str r1, [r0, RCC_CFGR]

    @ Disable all PLL clocks (PLL, PLLSAI1, PLLSAI2)
    ldr r1, [r0, RCC_CR]
    bic r1, (1 << RCC_CR_PLLON | 1 << RCC_CR_PLLSAI1ON | 1 << RCC_CR_PLLSAI2ON)
    str r1, [r0, RCC_CR]

    @ Wait for change to take effect
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLRDY | 1 << RCC_CR_PLLSAI1RDY | 1 << RCC_CR_PLLSAI2RDY)
    bne 1b

    @ Set PLL, PLLSAI1, and PLLSAI2 clock source to be MSI, scaled down 6x from 48 to 8 MHz
    ldr r1, [r0, RCC_PLLCFGR]
    bic r1, (0b11 << RCC_PLLCFGR_PLLSRC)
    orr r1, (0b01 << RCC_PLLCFGR_PLLSRC)
    bic r1, (0b111 << RCC_PLLCFGR_PLLM)
    orr r1, (0b101 << RCC_PLLCFGR_PLLM)
    str r1, [r0, RCC_PLLCFGR]

    @ Scale up PLL clock 20x from 8 MHz to 160 MHz
    ldr r1, [r0, RCC_PLLCFGR]
    bic r1, (0x7F << RCC_PLLCFGR_PLLN)
    orr r1, (20 << RCC_PLLCFGR_PLLN)
    str r1, [r0, RCC_PLLCFGR]

    @ Set PLL/R output to 2 division (80 MHz)
    ldr r1, [r0, RCC_PLLCFGR]
    bic r1, (0b11 << RCC_PLLCFGR_PLLR)
    str r1, [r0, RCC_PLLCFGR]

    @ Scale up PLLSAI1 clock 43x from 8 MHz to 344 MHz
    ldr r1, [r0, RCC_PLLSAI1CFGR]
    bic r1, (0x7F << RCC_PLLSAI1CFGR_PLLSAI1N)
    orr r1, (43 << RCC_PLLSAI1CFGR_PLLSAI1N)
    str r1, [r0, RCC_PLLSAI1CFGR]

    @ Set PLLSAI1/P output to 7 division (49.142857143 MHz output)
    ldr r1, [r0, RCC_PLLSAI1CFGR]
    bic r1, (0b1 << RCC_PLLSAI1CFGR_PLLSAI1P)
    str r1, [r0, RCC_PLLSAI1CFGR]

    @ Enable PLL/R (PLLCLK), disable PLL/Q and PLL/P
    ldr r1, [r0, RCC_PLLCFGR]
    orr r1, (1 << RCC_PLLCFGR_PLLREN)
    bic r1, (1 << RCC_PLLCFGR_PLLQEN)
    bic r1, (1 << RCC_PLLCFGR_PLLPEN)
    str r1, [r0, RCC_PLLCFGR]

    @ Enable PLL clock
    ldr r1, [r0, RCC_CR]
    orr r1, (1 << RCC_CR_PLLON)
    str r1, [r0, RCC_CR]

    @ Wait for PLL to be ready
    1:
    ldr r1, [r0, RCC_CR]
    tst r1, (1 << RCC_CR_PLLRDY)
    beq 1b

    @ Set SYSCLK to PLL clock (80 MHz)
    ldr r1, [r0, RCC_CFGR]
    orr r1, (0b11 << RCC_CFGR_SW)
    str r1, [r0, RCC_CFGR]

    @ Wait for change to take effect
    1:
    ldr r1, [r0, RCC_CFGR]
    and r1, (0b11 << RCC_CFGR_SWS)
    cmp r1, (0b11 << RCC_CFGR_SWS)
    bne 1b

    @ Set RNG clock source to MSI (48 MHz)
    ldr r1, [r0, RCC_CCIPR]
    orr r1, (0b11 << RCC_CCIPR_CLK48SEL)
    str r1, [r0, RCC_CCIPR]

    bx lr
.size clock_init, . - clock_init


@@@@@@@@@@@@@@@
@@ Constants @@
@@@@@@@@@@@@@@@

.set PWR, 0x40007000
    .set PWR_CR1, 0x00
        .set PWR_CR1_DBP, 8
        .set PWR_CR1_VOS, 9 @ [2] Voltage range
    .set PWR_SR2, 0x14
        .set PWR_SR2_VOSF, 10
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
