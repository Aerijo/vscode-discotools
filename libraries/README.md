These libraries are for the STM32L476 (VG?).

To import a library, copy the relevant file into your project. It's public interface (the global functions it provides) should be available to use anywhere; no need to import the file with `include` or similar. E.g.,
```
project_root/
  |- platformio.ini
  `- src/
    |- lib/
    | |- audio.S
    | `- clock.S
    `- main.S
```

```
@ src/main.S

.syntax unified

.global main
.type main, %function
main:
    push {lr}
    bl clock_init
    bl audio_init
    pop {pc}
.size main, . - main
```

```
@ src/lib/clock.S

.syntax unified

.global clock_init
.type clock_init, %function
clock_init:
    @ initialise clocks...
    nop
    bx lr
.size clock_init, . - clock_init
```

```
@ src/lib/audio.S

.syntax unified

.global audio_init
.type audio_init, %function
audio_init:
    @ initialise audio...
    nop
    bx lr
.size audio_init, . - audio_init
```