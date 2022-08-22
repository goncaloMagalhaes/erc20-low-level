// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console2.sol";

/**
    NOTE on strings: STRING STORAGE CHECK between <32bytes and >=32bytes, according to docs:
    "In particular: if the data is at most 31 bytes long, the elements are stored 
    in the higher-order bytes (left aligned) and the lowest-order byte stores the 
    value length * 2. For byte arrays that store data which is 32 or more bytes long, 
    the main slot p stores length * 2 + 1 and the data is stored as usual in keccak256(p). 
    This means that you can distinguish a short array from a long array by checking 
    if the lowest bit is set: short (not set) and long (set)."

    NOTE on mappings: The value corresponding to a mapping key k is located at keccak256(h(k) . p) 
    where . is concatenation and h is a function that is applied to the 
    key depending on its type:
    - for value types, h pads the value to 32 bytes in the same way as when storing the value in memory.
    - for strings and byte arrays, h(k) is just the unpadded data.
 */

contract ERC20PermitInlineAssembly {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    constructor(string memory __name, string memory __symbol, uint8 __decimals) {
        assembly {
            // Strings in memory: 1 slot for offset, 1 slot for length, data...
            let fmp := mload(0x40)

            // _name
            let nameLength := mload(__name)
            if gt(nameLength, 0x1f) {  // greater than 31 bytes
                sstore(_name.slot, add(mul(nameLength, 2), 1))  // 2*length+1 is stored in string slot
                mstore(fmp, _name.slot)
                let nameStart := keccak256(fmp, 0x20)
                for 
                    { let i := 0 }
                    lt(i, add(div(nameLength, 0x20), 1))
                    { i := add(i, 1) }
                {
                    sstore(
                        add(nameStart, i),
                        mload(add(__name, mul(0x20, add(i, 1))))
                    )
                }
            }
            if lt(nameLength, 0x20) {
                let nameData := mload(add(__name, 0x20))
                sstore(_name.slot, or(nameData, mul(nameLength, 2)))
            }
            
            // _symbol
            let symbolLength := mload(__symbol)
            if gt(symbolLength, 0x1f) {  // greater than 31 bytes
                sstore(_symbol.slot, add(mul(symbolLength, 2), 1))  // 2*length+1 is stored in string slot
                mstore(fmp, _symbol.slot)
                let symbolStart := keccak256(fmp, 0x20)
                for 
                    { let i := 0 }
                    lt(i, add(div(symbolLength, 0x20), 1))
                    { i := add(i, 1) }
                {
                    sstore(
                        add(symbolStart, i),
                        mload(add(__symbol, mul(0x20, add(i, 1))))
                    )
                }
            }
            if lt(symbolLength, 0x20) {
                let symbolData := mload(add(__symbol, 0x20))
                sstore(_symbol.slot, or(symbolData, mul(symbolLength, 2)))
            }

            // _decimals
            sstore(_decimals.slot, __decimals)  // easy stuff, contrary to strings...
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function name() public view returns (string memory) {
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, sload(_name.slot))
            if eq(and(mload(fmp), 0x01), 0x01) {  // this means string is greater than 32bytes
                let length := div(sub(mload(fmp), 1), 2)
                mstore(fmp, _name.slot)
                let start := keccak256(fmp, 0x20)
                let memSize := 0x40
                for 
                    { let i := 0 }
                    lt(i, add(div(length, 0x20), 1))
                    { i := add(i, 1) }
                {
                    mstore(
                        add(fmp, add(0x40, mul(i, 0x20))),
                        sload(add(start, i))
                    )
                    memSize := add(memSize, 0x20)
                }
                mstore(fmp, 0x20) // offset
                mstore(add(fmp, 0x20), length) // length
                return(fmp, memSize)
            }
            // if this code is reached, length < 32bytes
            let memSlot := add(fmp, 0x20)
            mstore(memSlot, 0x20) // store offset
            mstore(add(memSlot, 0x20), div(and(0xff, mload(fmp)), 2)) // length
            mstore(add(memSlot, 0x40), and(not(0xff), mload(fmp))) // data
            return(memSlot, 0x60)
        }
    }

    function symbol() public view returns (string memory) {
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, sload(_symbol.slot))
            if eq(and(mload(fmp), 0x01), 0x01) {  // this means string is greater than 32bytes
                let length := div(sub(mload(fmp), 1), 2)
                mstore(fmp, _symbol.slot)
                let start := keccak256(fmp, 0x20)
                let memSize := 0x40
                for 
                    { let i := 0 }
                    lt(i, add(div(length, 0x20), 1))
                    { i := add(i, 1) }
                {
                    mstore(
                        add(fmp, add(0x40, mul(i, 0x20))),
                        sload(add(start, i))
                    )
                    memSize := add(memSize, 0x20)
                }
                mstore(fmp, 0x20) // offset
                mstore(add(fmp, 0x20), length) // length
                return(fmp, memSize)
            }
            // if this code is reached, length < 32bytes
            let memSlot := add(fmp, 0x20)
            mstore(memSlot, 0x20) // store offset
            mstore(add(memSlot, 0x20), div(and(0xff, mload(fmp)), 2)) // length
            mstore(add(memSlot, 0x40), and(not(0xff), mload(fmp))) // data
            return(memSlot, 0x60)
        }
    }

    function decimals() public view returns (uint8) {
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, sload(_decimals.slot))
            return(fmp, 0x20)
        }
    }

    function totalSupply() public view returns (uint256) {
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, sload(_totalSupply.slot))
            return(fmp, 0x20)
        }
    }

    function balanceOf(address user) public view returns (uint256) {
        assembly {
            let fmp := mload(0x40)
            
            mstore(fmp, user)
            mstore(add(fmp, 0x20), _balanceOf.slot)

            let memResultOffset := add(fmp, 0x40)
            mstore(memResultOffset, sload(keccak256(fmp, 0x40)))

            return(memResultOffset, 0x20)
        }
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        // return _allowance[owner][spender];
        assembly {
            let fmp := mload(0x40)

            mstore(fmp, owner)
            mstore(add(fmp, 0x20), _allowance.slot)
            let allowancesOwnerSlot := keccak256(fmp, 0x40)
            
            fmp := add(fmp, 0x40)
            mstore(fmp, spender)
            mstore(add(fmp, 0x20), allowancesOwnerSlot)

            let memResultOffset := add(fmp, 0x40)
            mstore(memResultOffset, sload(keccak256(fmp, 0x40)))

            return(memResultOffset, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public returns (bool) {
        assembly {
            let fmp := mload(0x40)  // 0x40 is where the free memory pointer is stored
            
            mstore(fmp, caller())  // caller() --> msg.sender
            mstore(add(fmp, 0x20), _allowance.slot)  // 0x20 is 32bytes, concatenates slot after msg.sender
            
            let spenderPointer := add(fmp, 0x40)
            mstore(spenderPointer, spender)
            // slot of _allowance[msg.sender] --> keccak256(abi.encode(msg.sender, _allowance.slot))
            mstore(add(spenderPointer, 0x20), keccak256(fmp, 0x40))  // keccak256 of 64bytes

            // slot of _allowance[msg.sender][spender] --> keccak256(abi.encode(spender, _allowance[msg.sender].slot))
            let slot := keccak256(spenderPointer, 0x40)

            sstore(slot, amount)  // store in right place

            // Emit event Approval(address indexed owner, address indexed spender, uint256 amount)
            let amountPointer := add(spenderPointer, 0x40)
            mstore(amountPointer, amount)
            // hash string is keccak256("Approval(address,address,uint256)")
            log3(
                amountPointer,
                0x20,
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                caller(),
                spender
            )

            // Return true
            let returnPointer := add(amountPointer, 0x20)
            mstore(returnPointer, 0x01)
            return(returnPointer, 0x20)
        }
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        // This is not needed, because without it it will lead to underflow error
        // require(balanceOf(msg.sender) >= amount, "Not enough funds");
        _balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 allowed = _allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) _allowance[from][msg.sender] = allowed - amount;

        _balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
