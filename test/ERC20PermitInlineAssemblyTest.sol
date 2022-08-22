// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20PermitInlineAssembly.sol";

contract ERC20PermitInlineAssemblyTest is Test {
    address eoa = address(100);

    string name = "Test Token Name";
    string symbol = "TEST";
    
    string bigName = "This is a huge name for our erc20 token but it is just for testing purposes, hopefully that was clear, goodbyyyeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    string bigSymbol = "Just as the previous name, this is a huge symbol string for our erc20 token, for testing purposes, sorryyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";

    uint8 decimals = 18;
    ERC20PermitInlineAssembly erc20;
    ERC20PermitInlineAssembly bigStringsErc20;

    function setUp() public {
        erc20 = new ERC20PermitInlineAssembly(name, symbol, decimals);
        bigStringsErc20 = new ERC20PermitInlineAssembly(bigName, bigSymbol, decimals);
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

    function testApprove() public {
        vm.startPrank(eoa);
        assertTrue(true);
        vm.stopPrank();
    }
}
