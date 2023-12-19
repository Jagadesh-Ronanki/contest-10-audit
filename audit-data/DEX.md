# Q. Exchange - Findings Report


- ## Medium Risk Findings
    - [M-01. Use call instead of transfer for ethereum native token transactions](#M-01)
    - [M-02. Accumulated ETH fees on swaps cannot be retrieved](#M-02)
- ## Informational Findings
    - [Inf-01. `transferFrom` may silently fail](#Inf-01)
    - [Inf-02. `removeLiquidity` violates CEI pattern leads to read-only reentrancy](#Inf-02)

## <a id='M-01'></a>M-01. Use call instead of transfer for ethereum native token transactions

### Vulnerability Summary
In both of the `removeLiquidity` and `tokenToEthSwap` functions, transfer() is used for native ETH withdrawal. The `transfer()` and `send()` functions forward a fixed amount of 2300 gas. Historically, it has often been recommended to use these functions for value transfers to guard against reentrancy attacks. However, the gas cost of EVM instructions may change significantly during hard forks which may break already deployed contract systems that make fixed assumptions about gas costs. For example. EIP 1884 broke several existing smart contracts due to a cost increase of the SLOAD instruction.

### Impact
The use of the deprecated transfer() function for an address will inevitably make the transaction fail when:
* The claimer smart contract does not implement a payable function.
* The claimer smart contract does implement a payable fallback which uses more than 2300 gas unit.
* The claimer smart contract implements a payable fallback function that needs less than 2300 gas units but is called through proxy, raising the call's gas usage above 2300.

### Recommended Mitigation
Use call() instead of transfer().

```solidity
payable(msg.sender).call{value: ethAmt}("");
```
## <a id='M-02'></a>M-02. Accumulated ETH fees on swaps cannot be retrieved. 

### Vulnerability Summary
ETH fees accumulated from `tokenToEthSwap()` operation are permanently frozen within the contract as there is no way designed to retrieve them.

### Impact
A permanent freeze of ETH revenue of the project.

### Recommended Mitigation

In addition to below recommendation, ensure owner doesn't pull excess ether other than collected fee.
```solidity
  /// @dev used for rescuing swap fees paid to the contract in ETH
  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: feevalue}('');
    require(sent, 'failed');
  }
```

## <a id='Inf-01'></a>Inf-01. `transferFrom` may silently fail

### Vulnerability Summary

Stake function uses `transferFrom` to transfer tokens from sender to the contract. But it may fail silently with out revert.

### Recommended Mitigation

transferFrom returns a boolean value. Implement a check for successful transaction.

```solidity
  bool success = stakingToken.transferFrom(msg.sender,address(this),amount);
  require(success, "transferring tokens failed");
```

## <a id='Inf-02'></a>Inf-02. `removeLiquidity` violates CEI pattern leads to read-only reenrtancy

### Vulnerability Summary
Implementation of `removeLiquidity` does burning of LPTokens after transferring the tokens and ether to the caller.

```solidity
function removeLiquidity(uint256 amountOfLPTokens) external {
    ...
    token.transfer(msg.sender,v4);
    payable(msg.sender).transfer(v5);
    _burn(msg.sender, amountOfLPTokens);
    ...
}
```

As stated in [Inf-01](#Inf-01) if the code is modified to use call instead of transfer, it allows caller contract to make a call to other functions.

Attack Scenario:
1. Assuming attacker provided 1 ether and 10 tokens as initial liquidity. He receives 1 ether worth lpTokens i.e., 10^18 lp tokens.
2. Attacker calls `removeLiquidity` to remove 10^18 lp tokens. 
3. As per implementation contract transfers 1 ether and 10 tokens back to attacker.
4. Since the `_burn` is being called after external call. The state of `totalSupply()` isn't modified.
5. Attacker executes `addLiquidity` in `fallback`
```solidity
  uint y = (totalSupply() * msg.value) /(ethBalance-msg.value);
  _mint(msg.sender,y);
```

As totalSupply() is higher value, attacker receives more lp tokens than expected.

### Recommended Mitigation
burn LP tokens prior external calls
```
function removeLiquidity(uint256 amountOfLPTokens) external {
    ...
    // burn lp tokens 
    _burn(msg.sender, amountOfLPTokens);
    
    // then transfer ERC20 and Ether
    token.transfer(msg.sender,v4 );
    payable(msg.sender).transfer(v5);
}
```