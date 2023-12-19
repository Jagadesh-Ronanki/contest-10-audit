# Q. StakingContract - Findings Report

- ## Medium Risk Findings
    - [M-01. `claimInterest` violates CEI pattern makes it vulnerable for reentrancy for malicious tokens](#M-01)
- ## Informational Findings
    - [Inf-01. `transferFrom` may silently fail](#Inf-01)



## <a id='M-01'></a>M-01. `claimInterest` violates CEI pattern makes it vulnerable for reentrancy for malicious tokens

### Vulnerability Summary
`claimInterest` function transfers interest amt calculated from `getAccruedInterest` which calculates interest based on difference between timestamps.  

```solidity
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
```

Interest calculation is dependent on `stakes[user]` but the claimInterest transfers token first and then updates the timestamp.

```solidity
  function claimInterest() public {
    ...
    stakingToken.transfer(msg.sender,inrest); // Interaction
    stakes[msg.sender].timestamp = block.timestamp; // Effects
  }
```

### Impact

If the staking token is ERC777 or any malicious token. It leads to reentrancy in claimInterest function which can drain the contract balance.

### Recommended Mitigation

Add a function that allows owner to transfer funds from contract.

```solidity
  function claimInterest() public {
    ...
    stakes[msg.sender].timestamp = block.timestamp; // Effects
    stakingToken.transfer(msg.sender,inrest); // Interaction
  }
```

## <a id='Inf-01'></a>Inf-01. `transferFrom` may silently fail leads inconsistency in the state of contract

### Vulnerability Summary

Stake function uses `transferFrom` to transfer tokens from sender to the contract. But it may fail silently with out revert which leads to inconsistency in state variables `totalStaked`, `stakes`.

```solidity
  function stake(uint256 amount) external {
    ...
    // @audit transfer from may silently fail
    stakingToken.transferFrom(msg.sender,address(this),amount);
    totalStaked += amount; 
    t.amt = amount;
    stakes[msg.sender] = t;
  }
```

### Recommended Mitigation

transferFrom returns a boolean value. Add a check for successful transaction.

```solidity
  function stake(uint256 amount) external {
    ...
    bool success = stakingToken.transferFrom(msg.sender,address(this),amount);
    require(success, "transferring tokens failed");
    ...
  }
```