// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 internal immutable stakingToken;
    address internal immutable owner;
    uint internal totalStaked;    
    struct stakeInfo{
        uint amt;
        uint timestamp;
    }

    mapping (address => stakeInfo) internal stakes;

    constructor(address token) {
        stakingToken = IERC20(token);
        owner = msg.sender;
    }

    // allows users to stake tokens
    function stake(uint256 amount) external {
        if(amount==0) revert();
        stakeInfo memory t = stakes[msg.sender];
        if(t.amt != 0){
            uint temp = getAccruedInterest(msg.sender);
            redeem(t.amt + temp);
            totalStaked -= stakes[msg.sender].amt;
            delete stakes[msg.sender];
        }
        t.timestamp = block.timestamp;
        // @audit transfer from may silently fail
        stakingToken.transferFrom(msg.sender,address(this),amount);
        totalStaked += amount; 
        t.amt = amount;
        stakes[msg.sender] = t;
    }

    // allows users to reedem staked tokens
    function redeem(uint256 amount) public {
        if(amount > stakes[msg.sender].amt || amount ==0) revert();
        totalStaked -= amount;
        stakes[msg.sender].amt -= amount;
        stakingToken.transfer(msg.sender,amount);
    }

    // transfers rewards to staker
    function claimInterest() public {
        uint inrest = getAccruedInterest(msg.sender);
        if(inrest == 0) revert();
        // @audit violating CEI - vulnerable to reentrancy on ERC777 / malicious tokens
        stakingToken.transfer(msg.sender,inrest);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // returns the accrued interest
    function getAccruedInterest(address user) public view returns (uint256) {
        stakeInfo memory t = stakes[user];
        if(block.timestamp - t.timestamp >= 30 days){
            return t.amt/2;
        }
        else if(block.timestamp - t.timestamp >= 7 days){
            return t.amt/10;
        }
        else if(block.timestamp - t.timestamp >= 1 days){
            return t.amt/100;
        }
        return 0;
    }

    // allows owner to collect all the staked tokens
    function sweep() external {
        if(msg.sender != owner) revert();
        stakingToken.transfer(owner,totalStaked);
        // delete stakes;
    }   
}