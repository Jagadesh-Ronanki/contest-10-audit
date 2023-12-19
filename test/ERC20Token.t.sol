// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Token} from "../src/ERC20Token.sol";

contract TokenTest is Test {
    Token public token;

    function setUp() public {
        vm.prank(makeAddr('owner'));
        token = new Token("DappWorld", "DWC");
    }
    
    function testToken() public {
        assertEq(token.name(), "DappWorld");
        assertEq(token.symbol(), "DWC");
    }

    function testPublicMint() public {
        address alice = makeAddr('alice');
        vm.deal(alice, 0.055 ether);

        vm.startPrank(alice);
        token.publicMint{value: 0}(1);
    
        uint256 tokenPrice = 0.055 ether;
        token.publicMint{value: tokenPrice}(10);
        
        vm.stopPrank();
    }
}
