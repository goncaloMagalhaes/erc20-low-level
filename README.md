# erc20-low-level
ERC20 contracts programmed only with low level syntax (inline assembly, pure Yul, ...).

## ERC20PermitInlineAssembly
ERC20-Permit written only with inline assembly inside solidity functions, nothing more. Full Foundry testing included.

#### Challenging parts
- string storage and reading: storing strings like `_name` and returning them was surprisingly difficult, given the way strings are stored both in storage and in memory, and the way storage layout changes with the size of the string.
- permit: permit took a good amount of time, and fortunately the Foundry Book had already testing examples for it. 
