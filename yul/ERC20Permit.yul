object "ERC20Permit" {
    /*
     * Storage first slots layout:
     * 0 - _owner - address
     * 1 - _name - string - content(left)+2*length(right) or 2*length+1(right)
     * 2 - _symbol - string
     * 3 - _decimals - uint8
     * 4 - _totalSupply - uint256
     * 5 - _balanceOf - mapping slot to be hashed
     * 6 - _allowance - mapping
     * 7 - _nonces - mapping
     */
    code {
        /* constructor vars:
         * - name - string
         * - symbol - string
         * - decimals - uint8
         * -> constructor arguments come after the entire bytecode:
         *      - 1st byte -> name offset - where name starts (length + content)
         *      - 2nd byte -> symbol offset
         *      - 3rd byte -> uint8 value
         */
        
        // store owner
        sstore(0, caller())

        codecopy(0, 0x097a, codesize())  // right offset hardcoded
        let fmp := codesize()

        //
        // handle decimals
        //
        let decimalsOffset := 0x40 // appears after both string offsets
        sstore(3, mload(decimalsOffset))
        
        //
        // handle name
        //
        let nameOffset := mload(0)
        let nameLength := mload(nameOffset)
        if gt(nameLength, 0x1f) {  // greater than 31 bytes
            sstore(1, add(mul(nameLength, 2), 1))  // 2*length+1 is stored in string slot
            mstore(fmp, 0x01)
            let nameStart := keccak256(fmp, 0x20)
            for 
                { let i := 0 }
                lt(i, add(div(nameLength, 0x20), 1))
                { i := add(i, 1) }
            {
                sstore(
                    add(nameStart, i),
                    mload(add(nameOffset, mul(0x20, add(i, 1))))
                )
            }
        }
        if lt(nameLength, 0x20) {
            let nameData := mload(add(nameOffset, 0x20))
            sstore(1, or(nameData, mul(nameLength, 2)))
        }

        //
        // handle symbol
        //
        let symbolOffset := mload(0x20)
        let symbolLength := mload(symbolOffset)
        if gt(symbolLength, 0x1f) {  // greater than 31 bytes
            sstore(2, add(mul(symbolLength, 2), 1))  // 2*length+1 is stored in string slot
            mstore(fmp, 0x02)
            let symbolStart := keccak256(fmp, 0x20)
            for 
                { let i := 0 }
                lt(i, add(div(symbolLength, 0x20), 1))
                { i := add(i, 1) }
            {
                sstore(
                    add(symbolStart, i),
                    mload(add(symbolOffset, mul(0x20, add(i, 1))))
                )
            }
        }
        if lt(symbolLength, 0x20) {
            let symbolData := mload(add(symbolOffset, 0x20))
            sstore(2, or(symbolData, mul(symbolLength, 2)))
        }

        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return (0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // reverts if msg.value is greater than 0
            if iszero(iszero(callvalue())) {
                revert(0, 0)
            }

            let selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)

            switch selector

            // keccak256('transfer(address,uint256)') 
            // -> 0xa9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b
            case 0xa9059cbb {
                _transfer(caller(), decodeAddress(0), decode32Bytes(1))
                returnTrue()
            }

            // keccak256('approve(address,uint256)') 
            // -> 0x095ea7b334ae44009aa867bfb386f5c3b4b443ac6f0ee573fa91c4608fbadfba
            case 0x095ea7b3 {
                _approve(caller(), decodeAddress(0), decode32Bytes(1))
                returnTrue()
            }

            // keccak256('transferFrom(address,address,uint256)') 
            // -> 0x23b872dd7302113369cda2901243429419bec145408fa8b352b3dd92b66c680b
            case 0x23b872dd {
                transferFrom(decodeAddress(0), decodeAddress(1), caller(), decode32Bytes(2))
                returnTrue()
            }

            // keccak256('mint(address,uint256)') 
            // -> 0x40c10f19c047ae7dfa66d6312b683d2ea3dfbcb4159e96b967c5f4b0a86f2842
            case 0x40c10f19 {
                mint(decodeAddress(0), decode32Bytes(1))
            }

            // keccak256('permit(address,address,uint256,uint256,uint8,bytes32,bytes32)') 
            // -> 0xd505accfee7b46ac3ce97322c21f328b64073d188137e16f7ef87f8de076b51c
            case 0xd505accf {
                permit(
                    decodeAddress(0),
                    decodeAddress(1),
                    decode32Bytes(2),
                    decode32Bytes(3),
                    decode32Bytes(4), // uint8
                    decode32Bytes(5),
                    decode32Bytes(6)
                )
            }

            // keccak256('allowance(address,address)') 
            // -> 0xdd62ed3e90e97b3d417db9c0c7522647811bafca5afc6694f143588d255fdfb4
            case 0xdd62ed3e {
                returnUint(allowance(decodeAddress(0), decodeAddress(1)))
            }

            // keccak256('balanceOf(address)') 
            // -> 0x70a08231b98ef4ca268c9cc3f6b4590e4bfec28280db06bb5d45e689f2a360be
            case 0x70a08231 {
                returnUint(balanceOf(decodeAddress(0)))
            }

            // keccak256('totalSupply()') 
            // -> 0x18160ddd7f15c72528c2f94fd8dfe3c8d5aa26e2c50c7d81f4bc7bee8d4b7932
            case 0x18160ddd {
                returnUint(sload(4))
            }

            // keccak256('name()') 
            // -> 0x06fdde0383f15d582d1a74511486c9ddf862a882fb7904b3d9fe9b8b8e58a796
            case 0x06fdde03 {
                returnString(1)
            }

            // keccak256('symbol()') 
            // -> 0x95d89b41e2f5f391a79ec54e9d87c79d6e777c63e32c28da95b4e9e4a79250ec
            case 0x95d89b41 {
                returnString(2)
            }

            // keccak256('decimals()') 
            // -> 0x313ce567add4d438edf58b94ff345d7d38c45b17dfc0f947988d7819dca364f9
            case 0x313ce567 {
                returnUint(sload(3))
            }

            default {
                revert(0, 0)  // no fallback function
            }

            /* 
             * Decode calldata functions
             */
            function decodeAddress(argPos) -> addr {
                addr := decode32Bytes(argPos)
                if iszero(iszero(and(addr, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    // checks there's no data besides the address' 20bytes
                    revert(0, 0)
                }
            }

            function decode32Bytes(argPos) -> value {
                let pos := add(0x04, mul(argPos, 0x20))  // add 4bytes of funcsig
                if lt(calldatasize(), add(pos, 0x20)) {  // no 32bytes in pos
                    revert(0, 0)
                }
                value := calldataload(pos)
            }

            /*
             * Returns
             */
            function returnTrue() {
                returnUint(1)
            }

            function returnUint(value) {
                mstore(0, value)
                return(0, 0x20)  // terminates execution, does not return to calling func
            }

            function returnString(slot) {
                let slotValue := sload(slot)
                if eq(and(slotValue, 0x01), 0x01) {  // this means string is greater than 32bytes
                    let length := div(sub(slotValue, 1), 2)
                    mstore(0, slot)
                    let start := keccak256(0, 0x20)
                    let memSize := 0x40
                    for 
                        { let i := 0 }
                        lt(i, add(div(length, 0x20), 1))
                        { i := add(i, 1) }
                    {
                        mstore(
                            add(0x40, mul(i, 0x20)),
                            sload(add(start, i))
                        )
                        memSize := add(memSize, 0x20)
                    }
                    mstore(0, 0x20) // offset
                    mstore(0x20, length) // length
                    return(0, memSize)
                }
                // if this code is reached, length < 32bytes
                mstore(0, 0x20) // store offset
                mstore(0x20, div(and(0xff, slotValue), 2)) // length
                mstore(0x40, and(not(0xff), slotValue)) // data
                return(0, 0x60)
            }

            /*
             * Errors
             */
            function revertNoBalance() {
                revertError(
                    0x10, // length("Not enough funds") = 16 bytes -> 0x10
                    0x4e6f7420656e6f7567682066756e647300000000000000000000000000000000 // "Not enough funds"
                )
            }

            function revertNoAllowance() {
                revertError(
                    0x14, // length("Not enough allowance") = 20 bytes -> 0x14
                    0x4e6f7420656e6f75676820616c6c6f77616e6365000000000000000000000000 // "Not enough allowance"
                )
            }

            function revertOnlyOwner() {
                revertError(
                    0x09, // length("Not owner") = 9 bytes -> 0x09
                    0x4e6f74206f776e65720000000000000000000000000000000000000000000000 // "Not owner"
                )
            }

            function revertSupplyOverflow() {
                revertError(
                    0x15, // length("Total supply overflow") = 21 bytes -> 0x15
                    0x546f74616c20737570706c79206f766572666c6f770000000000000000000000 // "Total supply overflow"
                )
            }

            function revertPermitDeadlineExpired() {
                revertError(
                    0x1d, // length("ERC20Permit: expired deadline") = 29 bytes -> 0x1d
                    0x45524332305065726d69743a206578706972656420646561646c696e65000000 // "ERC20Permit: expired deadline"
                )
            }

            function revertInvalidSignatureSValue() {
                revertError(
                    0x1b, // length("Invalid signature 's' value") = 27 bytes -> 0x1b
                    0x496e76616c6964207369676e6174757265202773272076616c75650000000000 // "Invalid signature 's' value"
                )
            }

            function revertInvalidSignature() {
                revertError(
                    0x11, // length("Invalid signature") = 17 bytes -> 0x11
                    0x496e76616c6964207369676e6174757265000000000000000000000000000000 // "Invalid signature"
                )
            }

            function revertZeroAddress() {
                revertError(
                    0x09, // length("Address 0") = 9 bytes -> 0x09
                    0x4164647265737320300000000000000000000000000000000000000000000000 // "Address 0"
                )
            }

            function revertIfZeroAddress(addr) {
                if iszero(addr) { revertZeroAddress() }
            }

            function revertError(errLength, errData) {
                mstore(0, 0x08c379a0)  // function selector for Error(string)
                mstore(0x20, 0x20)  // string offset
                mstore(0x40, errLength)  // length
                mstore(0x60, errData)  // data  
                revert(0x1c, sub(0x80, 0x1c))  // starts in the function selector bytes, which start at (28bytes) 
            }

            /*
             * Events
             */
            function emitTransfer(from, to, amount) {
                mstore(0, amount)
                // hash string is keccak256("Transfer(address,address,uint256)")
                log3(
                    0,
                    0x20,
                    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                    from,
                    to
                )
            }

            function emitApproval(owner, spender, amount) {
                mstore(0, amount)
                // hash string is keccak256("Approval(address,address,uint256)")
                log3(
                    0,
                    0x20,
                    0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                    owner,
                    spender
                )
            }

            /*
             * Read functions
             */
            function balanceOf(addr) -> bal {
                mstore(0, addr)
                mstore(0x20, 5)
                bal := sload(keccak256(0, 0x40))
            }

            function allowance(owner, spender) -> value {
                mstore(0, owner)
                mstore(0x20, 6)  // 6 - allowance 'base' slot

                mstore(0x40, spender)
                mstore(0x60, keccak256(0, 0x40))  // keccak --> allowancesOwnerSlot

                value := sload(keccak256(0x40, 0x40))
            }

            /*
             * Write functions
             */

            function transferFrom(from, to, spender, amount) {
                revertIfZeroAddress(from)
                if lt(allowance(from, spender), amount) {
                    revertNoAllowance()
                }
                _decreaseAllowance(from, spender, amount)
                _transfer(from, to, amount)
            }

            function mint(to, amount) {
                // require(_owner == msg.sender, "Not owner");
                if iszero(eq(sload(0), caller())) {  // 0 - owner slot
                    revertOnlyOwner() 
                }

                revertIfZeroAddress(to)

                let totalSupply := sload(4)  // 4 - totalSupply slot
                if gt(totalSupply, add(totalSupply, amount)) {  // overflow
                    revertSupplyOverflow()
                }

                sstore(4, add(totalSupply, amount)) // increase totalSupply
                _increaseBalance(to, amount)

                emitTransfer(0x00, to, amount)
            }

            function permit(
                owner,
                spender,
                value,
                deadline,
                v,
                r,
                s
            ) {
                // require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
                if gt(timestamp(), deadline) {
                    revertPermitDeadlineExpired()
                }

                //
                // STORE _name IN MEMORY TO HASH IT. 
                // keccak256(bytes(_name)) --> this is hashing only the data bytes of the string
                //
                mstore(0, sload(1)) // 1 - name slot
                if eq(and(mload(0), 0x01), 0x01) {  // this means string is greater than 32bytes
                    let length := div(sub(mload(0), 1), 2)
                    mstore(0, 1)
                    let start := keccak256(0, 0x20)
                    for 
                        { let i := 0 }
                        lt(i, add(div(length, 0x20), 1))
                        { i := add(i, 1) }
                    {
                        mstore(
                            add(0x40, mul(i, 0x20)),
                            sload(add(start, i))
                        )
                    }
                    mstore(0x20, length) // length
                }
                if iszero(and(mload(0), 0x01)) { // less than 32bytes 
                    mstore(0x20, div(and(0xff, mload(0)), 2)) // length
                    mstore(0x40, and(not(0xff), mload(0))) // data
                }

                let hashedName := keccak256(0x40, mload(0x20))  // 0x20 -> length, 0x40 -> content start

                // 
                // useNonce --> fetch current and increment storage nonce
                //
                mstore(0, owner)
                mstore(0x20, 7) // 7 - nonces slot

                let nonceSlot := keccak256(0, 0x40)
                let currentNonce := sload(nonceSlot)
                // increase nonce for next usage
                sstore(nonceSlot, add(currentNonce, 1))

                // bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
                // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
                mstore(0, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
                mstore(0x20, owner)
                mstore(0x40, spender)
                mstore(0x60, value)
                mstore(0x80, currentNonce)
                mstore(0xa0, deadline)

                let structHash := keccak256(0, 0xc0)

                // keccak256(bytes("1"))
                let hashedVersion := 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6
                // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                let typeHash := 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f

                // keccak256(abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(this)))
                mstore(0, typeHash)
                mstore(0x20, hashedName)
                mstore(0x40, hashedVersion)
                mstore(0x60, chainid())
                mstore(0x80, address())

                let domainSeparator := keccak256(0, 0xa0)

                // keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash))
                // encodePacked --> 0x1901 is immediatelly followed by domainSeparator bytes
                mstore(0, 0x1901)  // this is stored in least significant bytes
                mstore(0x20, domainSeparator)
                mstore(0x40, structHash)

                let finalHash := keccak256(0x1e, 0x42)  // starts in two least significant bytes in 0x00 32bytes word

                // checks signature malleability
                if gt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                    // revert("Invalid signature 's' value");
                    revertInvalidSignatureSValue()
                }

                // address signer = ecrecover(finalHash, v, r, s);
                // ecrecover is a hardcoded contract at address 0x01
                mstore(0, finalHash)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)

                if iszero(staticcall(not(0), 0x01, 0, 0x80, 0, 0x20)) {
                    // revert("Invalid signature");
                    revertInvalidSignature()
                }

                returndatacopy(0, 0, returndatasize())

                // require(signer == owner, "Invalid signature");
                if iszero(eq(owner, mload(0))) {
                    revertInvalidSignature()
                }

                // If code reaches this point, signature is valid
                _approve(owner, spender, value)
            }

            function _transfer(from, to, amount) {
                if iszero(to) { revertZeroAddress() }
                if lt(balanceOf(from), amount) {
                    revertNoBalance()
                }
                _decreaseBalance(from, amount)
                _increaseBalance(to, amount)
                emitTransfer(from, to, amount)
            }

            function _decreaseBalance(addr, amount) {
                mstore(0, addr)
                mstore(0x20, 5)
                let balancePos := keccak256(0, 0x40)
                let currentBalance := sload(balancePos)
                sstore(balancePos, sub(currentBalance, amount))
            }

            function _increaseBalance(addr, amount) {
                mstore(0, addr)
                mstore(0x20, 5)
                let balancePos := keccak256(0, 0x40)
                let currentBalance := sload(balancePos)
                sstore(balancePos, add(currentBalance, amount))
            }

            function _decreaseAllowance(owner, spender, amount) {
                mstore(0, owner)
                mstore(0x20, 6)  // 6 - allowance 'base' slot
                mstore(0x40, spender)
                mstore(0x60, keccak256(0, 0x40))  // keccak --> allowanceOwnerSlot

                let allowancePos := keccak256(0x40, 0x40)
                let currentAllowance := sload(allowancePos)
                sstore(allowancePos, sub(currentAllowance, amount))
            }

            function _approve(owner, spender, amount) {
                mstore(0, owner)
                mstore(0x20, 6)  // 0x20 is 32bytes, concatenates slot after owner. 6 - allowance slot
                mstore(0x40, spender)

                // slot of _allowance[owner] --> keccak256(abi.encode(owner, _allowance.slot))
                mstore(0x60, keccak256(0, 0x40))  // keccak256 of 64bytes

                // slot of _allowance[owner][spender] --> keccak256(abi.encode(spender, _allowance[owner].slot))
                sstore(keccak256(0x40, 0x40), amount)  // store in right place

                emitApproval(owner, spender, amount)
            }
        }
    }
}