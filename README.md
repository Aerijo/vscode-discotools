# discotools README

Provides various tools relating to the discovery boards used in COMP2300.

## Features

### Current

- Show decoded instruction on hover. It treats the hovered byte as the start of the instruction.
  - Check the settings for ways to customise what is presented. Also provide a PDF viewer option & absolute path to the ARM manual to get a direct link to the documentation of a command.
- Snippet for functions (with global variant)
- Language grammar for ARM unified
  - Only an approximation; limitations of the engine mean things like respecting `\` line continuations are impossible (or at least not worth the effort).

### Planned

- Where a branch will go (either absolute or offset of PC)
- What the typed instruction might have been
- Better variable formatting