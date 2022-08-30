// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/ERC20PermitInlineAssembly.sol";
import "./SigUtils.sol";

contract ERC20PermitYulTest is Test {
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
        bytes memory bytecode = hex"336000553861097a60003938604080516003556000518051601f81111561005f5760016002820201600155600184526020842060005b6001602084040181101561005c576001810160200284015181830155600181019050610035565b50505b6020811015610078576020820151600282028117600155505b6020518051601f8111156100c55760016002820201600255600286526020862060005b600160208404018110156100c257600181016020028401518183015560018101905061009b565b50505b60208110156100de576020820151600282028117600255505b61088b6100ef60003961088b6000f3fe341561000a57600080fd5b7c0100000000000000000000000000000000000000000000000000000000600035048063a9059cbb81146100ab5763095ea7b381146100d5576323b872dd81146100ff576340c10f1981146101335763d505accf81146101545763dd62ed3e81146101a7576370a0823181146101d0576318160ddd81146101ef576306fdde0381146101ff576395d89b41811461020e5763313ce567811461021d57600080fd5b6100c86100b86001610263565b6100c2600061022f565b336107b6565b6100d0610286565b610229565b6100f26100e26001610263565b6100ec600061022f565b3361085e565b6100fa610286565b610229565b61012661010c6002610263565b33610117600161022f565b610121600061022f565b610548565b61012e610286565b610229565b61014f6101406001610263565b61014a600061022f565b610587565b610229565b6101a26101616006610263565b61016b6005610263565b6101756004610263565b61017f6003610263565b6101896002610263565b610193600161022f565b61019d600061022f565b6105d9565b610229565b6101cb6101c66101b7600161022f565b6101c1600061022f565b610524565b610292565b610229565b6101ea6101e56101e0600061022f565b61050c565b610292565b610229565b6101fa600454610292565b610229565b610209600161029c565b610229565b610218600261029c565b610229565b610228600354610292565b5b50610889565b600061023a82610263565b905073ffffffffffffffffffffffffffffffffffffffff1981161561025e57600080fd5b919050565b6000602082026004016020810136101561027c57600080fd5b8035915050919050565b6102906001610292565b565b8060005260206000f35b80546001808216036102f75760026001820304826000526020600020604060005b600160208504018110156102e8578083015460208202604001526020820191506001810190506102bd565b50602060005282602052806000f35b602060005260028160ff16046020528060ff191660405260606000f35b61033f7f4e6f7420656e6f7567682066756e647300000000000000000000000000000000601061048d565b565b61036c7f4e6f7420656e6f75676820616c6c6f77616e6365000000000000000000000000601461048d565b565b6103997f4e6f74206f776e65720000000000000000000000000000000000000000000000600961048d565b565b6103c67f546f74616c20737570706c79206f766572666c6f770000000000000000000000601561048d565b565b6103f37f45524332305065726d69743a206578706972656420646561646c696e65000000601d61048d565b565b6104207f496e76616c6964207369676e6174757265202773272076616c75650000000000601b61048d565b565b61044d7f496e76616c6964207369676e6174757265000000000000000000000000000000601161048d565b565b61047a7f4164647265737320300000000000000000000000000000000000000000000000600961048d565b565b8061048a5761048961044f565b5b50565b6308c379a0600052602080528060405281606052601c608003601cfd5b8260005281817fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206000a3505050565b8260005281817f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560206000a3505050565b60008160005260056020526040600020549050919050565b60008160005260066020528260405260406000206060526040802054905092915050565b6105518161047c565b8361055c8483610524565b101561056b5761056a610341565b5b610576848483610837565b6105818483836107b6565b50505050565b33600054146105995761059861036e565b5b6105a28161047c565b6004548281018111156105b8576105b761039b565b5b8281016004556105c8838361081c565b6105d4838360006104aa565b505050565b834211156105ea576105e96103c8565b5b600154600052600180600051160361063f576002600160005103046001600052602060002060005b6001602084040181101561063757808201546020820260400152600181019050610612565b508160205250505b60016000511661066057600260005160ff160460205260005160ff19166040525b602051604020816000526007602052604060002080546001810182557f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9600052836020528460405285606052806080528660a05260c06000207fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc67f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f806000528560205281604052466060523060805260a060002061190160005280602052836040526042601e207f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a08f1115610758576107576103f5565b5b806000528c6020528d6040528e60605260206000608060006001600019fa61078357610782610422565b5b3d6000803e600051891461079a57610799610422565b5b6107a58b8b8b61085e565b505050505050505050505050505050565b816107c4576107c361044f565b5b826107ce8261050c565b10156107dd576107dc610314565b5b6107e78382610801565b6107f1838361081c565b6107fc8383836104aa565b505050565b80600052600560205260406000208054838103825550505050565b80600052600560205260406000208054838101825550505050565b80600052600660205281604052604060002060605260408020805484810382555050505050565b8060005260066020528160405260406000206060528260408020556108848383836104db565b505050565b50";
        bytes memory codeErc20 = abi.encodePacked(bytecode, abi.encode(name, symbol, decimals));
        bytes memory codeBigStringsErc20 = abi.encodePacked(bytecode, abi.encode(bigName, bigSymbol, decimals));

        // console2.logBytes(bytecode);
        // console2.logBytes(codeErc20);
        // console2.logBytes(codeBigStringsErc20);
        
        address erc20Address;
        address bigStringsErc20Address;
        assembly {
            erc20Address := create(0, add(codeErc20, 0x20), mload(codeErc20))
            if iszero(extcodesize(erc20Address)) {
                revert(0, 0)
            }
            
            bigStringsErc20Address := create(
                0,
                add(codeBigStringsErc20, 0x20),
                mload(codeBigStringsErc20)
            )
            if iszero(extcodesize(bigStringsErc20Address)) {
                revert(0, 0)
            }
        }

        // console2.logBytes32(vm.load(erc20Address, 0));
        // console2.logBytes32(vm.load(erc20Address, bytes32(uint(1))));
        // console2.logBytes32(vm.load(erc20Address, bytes32(uint(2))));
        // console2.logBytes32(vm.load(erc20Address, bytes32(uint(3))));
        // console2.logBytes32(vm.load(erc20Address, bytes32(uint(4))));

        erc20 = ERC20PermitInlineAssembly(erc20Address);
        bigStringsErc20 = ERC20PermitInlineAssembly(bigStringsErc20Address);

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
