// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20PermitInlineAssembly.sol";
import "./SigUtils.sol";

contract ERC20PermitInlineAssemblyTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint256 eoaPrivateKey;
    address eoa;
    uint256 permitSpenderPrivateKey;
    address permitSpender;

    string name = "Test Token Name";
    string symbol = "TEST";
    
    string bigName = "This is a huge name for our erc20 token but it is just for testing purposes, hopefully that was clear, goodbyyyeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    string bigSymbol = "Just as the previous name, this is a huge symbol string for our erc20 token, for testing purposes, sorryyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";

    uint8 decimals = 18;
    ERC20PermitInlineAssembly erc20;
    ERC20PermitInlineAssembly bigStringsErc20;

    SigUtils internal sigUtils;

    uint amountMintEoa = 1 ether;
    uint amountMintTestContract = 2 ether;

    function _erc20DomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(erc20.name()));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        return keccak256(abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(erc20)));
    } 

    function setUp() public {
        erc20 = new ERC20PermitInlineAssembly(name, symbol, decimals);
        bigStringsErc20 = new ERC20PermitInlineAssembly(bigName, bigSymbol, decimals);

        sigUtils = new SigUtils(_erc20DomainSeparator());

        eoaPrivateKey = 0xA11CE;
        permitSpenderPrivateKey = 0xB0B;

        eoa = vm.addr(eoaPrivateKey);
        permitSpender = vm.addr(permitSpenderPrivateKey);

        erc20.mint(eoa, amountMintEoa);
        erc20.mint(address(this), amountMintTestContract);
    }

    function testMetadataIsInitialized() public {
        assertEq(erc20.name(), name);
        assertEq(erc20.symbol(), symbol);
        assertEq(erc20.decimals(), decimals);
    }

    function testMetadataIsInitializedWithBigStrings() public {
        assertEq(bigStringsErc20.name(), bigName);
        assertEq(bigStringsErc20.symbol(), bigSymbol);
        assertEq(bigStringsErc20.decimals(), decimals);
    }

    function testTotalSupplyReturns() public {
        assertEq(erc20.totalSupply(), amountMintEoa + amountMintTestContract);
    }

    function testBalanceOfReturns() public {
        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(address(this)), amountMintTestContract);
    }

    function testApprove() public {
        address otherUser = address(200);
        vm.startPrank(eoa);
        
        vm.expectEmit(true, true, false, true);
        emit Approval(eoa, otherUser, amountMintEoa);
        
        erc20.approve(otherUser, amountMintEoa);

        assertEq(erc20.allowance(eoa, otherUser), amountMintEoa);

        vm.stopPrank();
    }

    function testTransferSuccess() public {
        address otherUser = address(200);
        uint amountTransfer = 1 gwei;
        vm.startPrank(eoa);

        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(eoa, otherUser, amountTransfer);
        
        erc20.transfer(otherUser, amountTransfer);

        assertEq(erc20.balanceOf(eoa), amountMintEoa - amountTransfer);
        assertEq(erc20.balanceOf(otherUser), amountTransfer);

        vm.stopPrank();
    }

    function testTransferUnderflow() public {
        address otherUser = address(200);
        uint amountTransfer = 1 gwei + amountMintEoa;
        vm.startPrank(eoa);

        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);
        
        vm.expectRevert("Not enough funds");        
        erc20.transfer(otherUser, amountTransfer);

        // balances should remain the same
        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);

        vm.stopPrank();
    }

    function testTransferFromSuccess() public {
        address spender = address(200);
        address otherUser = address(300);
        uint amountTransfer = 1 gwei;

        //
        // add allowance
        //
        vm.startPrank(eoa);

        vm.expectEmit(true, true, false, true);
        emit Approval(eoa, spender, amountMintEoa);
        
        erc20.approve(spender, amountMintEoa);

        assertEq(erc20.allowance(eoa, spender), amountMintEoa);

        vm.stopPrank();

        //
        // use transferFrom
        // 
        vm.startPrank(spender);

        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(eoa, otherUser, amountTransfer);
        
        erc20.transferFrom(eoa, otherUser, amountTransfer);

        assertEq(erc20.balanceOf(eoa), amountMintEoa - amountTransfer);
        assertEq(erc20.balanceOf(otherUser), amountTransfer);

        // check allowance change
        assertEq(erc20.allowance(eoa, spender), amountMintEoa - amountTransfer);

        vm.stopPrank();
    }

    
    function testTransferFromReverts() public {
        address spender = address(200);
        address otherUser = address(300);
        uint amountTransfer = 1 gwei + amountMintEoa;

        //
        // Try transfering with no allowance
        //
        vm.startPrank(spender);

        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);
        
        vm.expectRevert("Not enough allowance");        
        erc20.transferFrom(eoa, otherUser, amountTransfer);

        // balances should remain the same
        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);

        vm.stopPrank();

        //
        // add allowance
        //
        vm.startPrank(eoa);

        vm.expectEmit(true, true, false, true);
        emit Approval(eoa, spender, amountTransfer);
        
        erc20.approve(spender, amountTransfer);

        assertEq(erc20.allowance(eoa, spender), amountTransfer);

        vm.stopPrank();

        //
        // Try transfering more than eoa ballance
        // 
        vm.startPrank(spender);
        
        vm.expectRevert("Not enough funds");        
        erc20.transferFrom(eoa, otherUser, amountTransfer);

        // balances should remain the same
        assertEq(erc20.balanceOf(eoa), amountMintEoa);
        assertEq(erc20.balanceOf(otherUser), 0);

        vm.stopPrank();
        vm.stopPrank();
    }

    function testMintReverts() public {
        //
        // Try as not owner
        //
        vm.startPrank(eoa);
        vm.expectRevert("Not owner");        
        erc20.mint(eoa, 1 ether);
        vm.stopPrank();

        //
        // Try minting to overflow
        //
        vm.expectRevert("Total supply overflow");        
        erc20.mint(eoa, type(uint).max - 1 gwei);
    }

    function testPermitSuccess() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);

        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(erc20.allowance(eoa, permitSpender), amountMintEoa);
    }

    function testRevertExpiredPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);

        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline

        vm.expectRevert("ERC20Permit: expired deadline");
        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );
    }

    function testRevertInvalidSigner() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(permitSpenderPrivateKey, digest); // spender signs owner's approval

        vm.expectRevert("Invalid signature");
        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );
    }

    function testRevertInvalidNonce() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 1, // owner nonce stored on-chain is 0
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);

        vm.expectRevert("Invalid signature");
        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );
    }

    function testRevertSignatureReplay() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eoa,
            spender: permitSpender,
            value: amountMintEoa,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaPrivateKey, digest);

        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        vm.expectRevert("Invalid signature");
        erc20.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );
    }
}
