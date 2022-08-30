// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    /** ownership */
    address private _owner;

    /** ERC20 metadata */
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /** ERC20 */
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    /** ERC20-Permit */
    mapping(address => uint256) private _nonces;

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

            // _owner
            sstore(_owner.slot, caller())
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
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, caller())  // caller() --> msg.sender
            mstore(add(fmp, 0x20), _balanceOf.slot)  // to have concatenation (caller . slot)

            let userBalanceSlot := keccak256(fmp, 0x40)
            let userBalance := sload(userBalanceSlot)

            // require(balanceOf(msg.sender) >= amount, "Not enough funds");
            if lt(userBalance, amount) {
                mstore(fmp, 0x08c379a0)  // function selector for Error(string)
                mstore(add(fmp, 0x20), 0x20)  // string offset
                mstore(add(fmp, 0x40), 0x10)  // length("Not enough funds") = 16 bytes -> 0x10
                mstore(add(fmp, 0x60), 0x4e6f7420656e6f7567682066756e647300000000000000000000000000000000)  // "Not enough funds"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            sstore(userBalanceSlot, sub(userBalance, amount))  // update msg.sender balance

            mstore(fmp, to)  // to change concatenation to (to . slot)
            sstore(keccak256(fmp, 0x40), amount)  // update to balance

            // Emit event Transfer(address indexed from, address indexed to, uint256 amount)
            let amountPointer := add(fmp, 0x40)
            mstore(amountPointer, amount)
            // hash string is keccak256("Transfer(address,address,uint256)")
            log3(
                amountPointer,
                0x20,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                caller(),
                to
            )

            // Return true
            let returnPointer := add(amountPointer, 0x20)
            mstore(returnPointer, 0x01)
            return(returnPointer, 0x20)
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        assembly {
            let fmp := mload(0x40)

            mstore(fmp, from)
            mstore(add(fmp, 0x20), _allowance.slot)
            let allowancesOwnerSlot := keccak256(fmp, 0x40)
            
            fmp := add(fmp, 0x40)
            mstore(fmp, caller())
            mstore(add(fmp, 0x20), allowancesOwnerSlot)

            let userAllowanceSlot := keccak256(fmp, 0x40)
            let userAllowance := sload(userAllowanceSlot)

            // require(allowance(from, msg.sender) >= amount, "Not enough allowance");
            if lt(userAllowance, amount) {  // not enough allowance, revert
                mstore(fmp, 0x08c379a0)  // function selector for Error(string)
                mstore(add(fmp, 0x20), 0x20)  // string offset
                mstore(add(fmp, 0x40), 0x14)  // length("Not enough allowance") = 20 bytes -> 0x14
                mstore(add(fmp, 0x60), 0x4e6f7420656e6f75676820616c6c6f77616e6365000000000000000000000000)  // "Not enough allowance"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            // decrease allowance
            sstore(userAllowanceSlot, sub(userAllowance, amount))            
            
            //
            // Transfer logic 
            //
            fmp := add(fmp, 0x40)

            mstore(fmp, from)
            mstore(add(fmp, 0x20), _balanceOf.slot)  // to have concatenation (from . slot)

            let fromBalanceSlot := keccak256(fmp, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            // require(balanceOf(from) >= amount, "Not enough funds");
            if lt(fromBalance, amount) {
                mstore(fmp, 0x08c379a0)  // function selector for Error(string)
                mstore(add(fmp, 0x20), 0x20)  // string offset
                mstore(add(fmp, 0x40), 0x10)  // length("Not enough funds") = 16 bytes -> 0x10
                mstore(add(fmp, 0x60), 0x4e6f7420656e6f7567682066756e647300000000000000000000000000000000)  // "Not enough funds"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            sstore(fromBalanceSlot, sub(fromBalance, amount))  // update from balance

            mstore(fmp, to)  // to change concatenation to (to . slot)
            sstore(keccak256(fmp, 0x40), amount)  // update to balance

            // Emit event Transfer(address indexed from, address indexed to, uint256 amount)
            let amountPointer := add(fmp, 0x40)
            mstore(amountPointer, amount)
            // hash string is keccak256("Transfer(address,address,uint256)")
            log3(
                amountPointer,
                0x20,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                to
            )

            // Return true
            let returnPointer := add(amountPointer, 0x20)
            mstore(returnPointer, 0x01)
            return(returnPointer, 0x20)
        }
    }

    function mint(address to, uint256 amount) external {
        assembly {
            let owner := sload(_owner.slot)
            let fmp := mload(0x40)

            // require(_owner == msg.sender, "Not owner");
            if iszero(eq(owner, caller())) {
                mstore(fmp, 0x08c379a0)  // function selector for Error(string)
                mstore(add(fmp, 0x20), 0x20)  // string offset
                mstore(add(fmp, 0x40), 0x09)  // length("Not owner") = 9 bytes -> 0x09
                mstore(add(fmp, 0x60), 0x4e6f74206f776e65720000000000000000000000000000000000000000000000)  // "Not owner"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            let totalSupplyMem := sload(_totalSupply.slot)
            if gt(totalSupplyMem, add(totalSupplyMem, amount)) {  // overflow
                mstore(fmp, 0x08c379a0)  // function selector for Error(string)
                mstore(add(fmp, 0x20), 0x20)  // string offset
                mstore(add(fmp, 0x40), 0x15)  // length("Total supply overflow") = 21 bytes -> 0x15
                mstore(add(fmp, 0x60), 0x546f74616c20737570706c79206f766572666c6f770000000000000000000000)  // "Total supply overflow"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            // increase totalSupply
            sstore(_totalSupply.slot, add(totalSupplyMem, amount))
            
            mstore(fmp, to)
            mstore(add(fmp, 0x20), _balanceOf.slot)

            let toBalanceSlot := keccak256(fmp, 0x40)
            // increase to balance
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            
            // Emit event Transfer(address indexed from, address indexed to, uint256 amount)
            let amountPointer := add(fmp, 0x40)
            mstore(amountPointer, amount)
            // hash string is keccak256("Transfer(address,address,uint256)")
            log3(
                amountPointer,
                0x20,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                0x00,
                to
            )
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        assembly {
            let fmp := mload(0x40)

            // require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
            if gt(timestamp(), deadline) {
                mstore(fmp, 0x08c379a0)
                mstore(add(fmp, 0x20), 0x20)
                mstore(add(fmp, 0x40), 0x1d)  // length("ERC20Permit: expired deadline") = 29 bytes -> 0x1d
                mstore(add(fmp, 0x60), 0x45524332305065726d69743a206578706972656420646561646c696e65000000)  // "ERC20Permit: expired deadline"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            //
            // FETCH _name TO HASH IT. 
            // keccak256(bytes(_name)) --> this is hashing only the data bytes of the string
            //
            let memNameSize
            let memNameSlot
            mstore(fmp, sload(_name.slot))
            switch and(mload(fmp), 0x01)
            case 0x01 { // string greater than 32 bytes
                let length := div(sub(mload(fmp), 1), 2)
                mstore(fmp, _name.slot)
                let start := keccak256(fmp, 0x20)
                for 
                    { let i := 0 }
                    lt(i, add(div(length, 0x20), 1))
                    { i := add(i, 1) }
                {
                    mstore(
                        add(fmp, mul(i, 0x20)),
                        sload(add(start, i))
                    )
                }
                memNameSlot := fmp
                memNameSize := length
            }
            default { // length < 32 bytes
                memNameSlot := add(fmp, 0x20)
                mstore(memNameSlot, and(not(0xff), mload(fmp))) // data
                memNameSize := div(and(0xff, mload(fmp)), 2)  // length
            }
            
            let hashedName := keccak256(memNameSlot, memNameSize)

            fmp := add(memNameSlot, mul(add(div(memNameSize, 0x20), 1), 0x20))  // advance fmp properly
            // useNonce --> fetch current and increment storage nonce
            mstore(fmp, owner)
            mstore(add(fmp, 0x20), _nonces.slot)

            let nonceSlot := keccak256(fmp, 0x40)
            let currentNonce := sload(nonceSlot)
            // increase nonce for next usage
            sstore(nonceSlot, add(currentNonce, 1))

            fmp := add(fmp, 0x40)

            // bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
            // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
            mstore(fmp, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
            mstore(add(fmp, 0x20), owner)
            mstore(add(fmp, 0x40), spender)
            mstore(add(fmp, 0x60), value)
            mstore(add(fmp, 0x80), currentNonce)
            mstore(add(fmp, 0xa0), deadline)

            let structHash := keccak256(fmp, 0xc0)

            // keccak256(bytes("1"))
            let hashedVersion := 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6
            // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
            let typeHash := 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f

            // keccak256(abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(this)))
            fmp := add(fmp, 0xc0)
            mstore(fmp, typeHash)
            mstore(add(fmp, 0x20), hashedName)
            mstore(add(fmp, 0x40), hashedVersion)
            mstore(add(fmp, 0x60), chainid())
            mstore(add(fmp, 0x80), address())

            let domainSeparator := keccak256(fmp, 0xa0)

            // keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash))
            // encodePacked --> 0x1901 is immediatelly followed by domainSeparator bytes
            fmp := add(fmp, 0xa0)
            mstore(fmp, 0x1901)  // this is stored in least significant bytes
            mstore(add(fmp, 0x20), domainSeparator)
            mstore(add(fmp, 0x40), structHash)

            let finalHash := keccak256(add(fmp, 0x1e), 0x42)  // starts in two least significant bytes in fmp 32bytes word

            fmp := add(fmp, 0x60)

            // checks signature malleability
            if gt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                // revert("Invalid signature 's' value");
                mstore(fmp, 0x08c379a0)
                mstore(add(fmp, 0x20), 0x20)
                mstore(add(fmp, 0x40), 0x1b)  // length("Invalid signature 's' value") = 27 bytes -> 0x1b
                mstore(add(fmp, 0x60), 0x496e76616c6964207369676e6174757265202773272076616c75650000000000)  // "Invalid signature 's' value"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            // address signer = ecrecover(finalHash, v, r, s);
            // ecrecover is a hardcoded contract at address 0x01
            mstore(fmp, finalHash)
            mstore(add(fmp, 0x20), v)
            mstore(add(fmp, 0x40), r)
            mstore(add(fmp, 0x60), s)
            
            if iszero(staticcall(not(0), 0x01, fmp, 0x80, fmp, 0x20)) {
                // revert("Invalid signature");
                fmp := add(fmp, 0x80)
                mstore(fmp, 0x08c379a0)
                mstore(add(fmp, 0x20), 0x20)
                mstore(add(fmp, 0x40), 0x11)  // length("Invalid signature") = 17 bytes -> 0x11
                mstore(add(fmp, 0x60), 0x496e76616c6964207369676e6174757265000000000000000000000000000000)  // "Invalid signature"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            let returnSize := returndatasize()
            fmp := add(fmp, 0x80)
            returndatacopy(fmp, 0, returnSize)

            // require(signer == owner, "Invalid signature");
            if iszero(eq(owner, mload(fmp))) {
                mstore(fmp, 0x08c379a0)
                mstore(add(fmp, 0x20), 0x20)
                mstore(add(fmp, 0x40), 0x11)  // length("Invalid signature") = 17 bytes -> 0x11
                mstore(add(fmp, 0x60), 0x496e76616c6964207369676e6174757265000000000000000000000000000000)  // "Invalid signature"
                revert(add(fmp, 0x1c), sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (fmp + 28bytes) 
            }

            // If code reaches this point, signature is valid

            //
            // approve logic
            //
            fmp := add(fmp, 0x20)
            
            mstore(fmp, owner)
            mstore(add(fmp, 0x20), _allowance.slot)  // 0x20 is 32bytes, concatenates slot after owner
            
            let spenderPointer := add(fmp, 0x40)
            mstore(spenderPointer, spender)
            mstore(add(spenderPointer, 0x20), keccak256(fmp, 0x40))

            // slot of _allowance[owner][spender] --> keccak256(abi.encode(spender, _allowance[owner].slot))
            let slot := keccak256(spenderPointer, 0x40)

            sstore(slot, value)  // store in right place

            // Emit event Approval(address indexed owner, address indexed spender, uint256 amount)
            let amountPointer := add(spenderPointer, 0x40)
            mstore(amountPointer, value)
            // hash string is keccak256("Approval(address,address,uint256)")
            log3(
                amountPointer,
                0x20,
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                owner,
                spender
            )
        }
    }
}
