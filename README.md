# erc20-low-level
ERC20 contracts programmed only with low level syntax (inline assembly, pure `Yul`, ...).

## ERC20PermitInlineAssembly
ERC20-Permit written only with inline assembly inside solidity functions, nothing more. Full `Foundry` testing included.

#### Challenging parts
- string storage and reading: storing strings like `_name` and returning them was surprisingly difficult, given the way strings are stored both in storage and in memory, and the way storage layout changes with the size of the string.
- permit: permit took a good amount of time, and fortunately the Foundry Book had already testing examples for it. 

## ERC20Permit.yul
ERC20-Permit written in pure `Yul`. Since we still cannot compile Yul files with `Foundry`/`ethers.rs` (see [#759](https://github.com/foundry-rs/foundry/issues/759)), I had to compile it using `solc`, and had to leave the file outside the *src* folder, otherwise `forge test` with raise compilation errors.

#### Steps to integrate a new change in the yul contract
1. Compile file:
```bash
solc --strict-assembly yul/ERC20Permit.yul --bin
```
2. Check size of bytecode. A way would be to copy-paste the hex representation to a `python` repl as a string, check its length and divide by 2, which will give you the size in bytes.
3. Put that number in the `codecopy` command in the `Yul` file, substituting the old *SIZE_BYTECODE* value:
```yul
...
codecopy(0, SIZE_BYTECODE, codesize())  // right offset hardcoded
let fmp := codesize()
...
```
4. Recompile it and copy-paste the hex representation into variable `bytecode` in *ERC20PermitYul.t.sol -> setUp()*.
5. Go ahead and ask the `Foundry` team to integrate `Yul` compilation so that this stops being a huge pain (let me know if you know of a better solution)

#### Challenging parts
- constructor arguments: it was difficult to figure out how to find the arguments in the constructor part, and also how to encode them to deploy the contract. Strings make this particularly difficult. On the upside, I finally understood why string objects come with an offset word in the calldata/constructor arguments.
- debugging yul is painful, since you don't have much inside information of the bugs, and also no console log.
Besides this, having coded the full inline assembly version first helped a lot with this, since it allowed me to be mostly just concerned with programming in Yul and not how to do the various storage/memory accesses, log events, revert error strings, etc.
Also, pure Yul allows me to organize the code and avoid repetition much better than in a full inline assembly contract.