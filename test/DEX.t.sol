// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Exchange} from "../src/DEX.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Exploit{
  Exchange exchange;
  
  event amountReceived(uint256);

  constructor(address _exchange) {
    exchange = Exchange(_exchange);
  }

  receive() payable external {
    exchange.addLiquidity{value:1 ether}(1_000);
    emit amountReceived(msg.value);
  }
}

contract ExchangeTest is Test {
  ERC20Mock token;
  Exchange exchange;
  Exploit exploit;
  address owner = makeAddr('owner');
  address userA = makeAddr('userA');
  address userB = makeAddr('userB');
  address exploitAddress;

  function setUp() public {
    vm.startPrank(owner);
    vm.deal(owner, 100 ether);
    vm.deal(userA, 100 ether);
    vm.deal(userB, 100 ether);

    token = new ERC20Mock();
    exchange = new Exchange(address(token));
    exploit = new Exploit(address(exchange));
    exploitAddress = address(exploit);
    vm.deal(exploitAddress, 100 ether);

    uint256 amount = 1_00_00_00_00_00_00_00_000;
    
    token.mint(userA, amount);
    token.mint(userB, amount);
    token.mint(exploitAddress, amount);
    vm.stopPrank();

    vm.prank(userA);
    token.approve(address(exchange), amount);

    vm.prank(userB);
    token.approve(address(exchange), amount);
    
    vm.prank(exploitAddress);
    token.approve(address(exchange), amount);
    
  }

  function testAddLiquidity() public {
    vm.prank(userA);
    exchange.addLiquidity{value: 1 ether}(1_00_000);
  }

  function testRemoveLiquidity() public {
    testAddLiquidity();
    vm.prank(userA);
    exchange.removeLiquidity(250000000000000000);
  }

  function testFailExploit() public {
    vm.startPrank(exploitAddress);
    exchange.addLiquidity{value: 1 ether}(1_00_000);
    exchange.removeLiquidity(25);
    vm.stopPrank();
  }
}