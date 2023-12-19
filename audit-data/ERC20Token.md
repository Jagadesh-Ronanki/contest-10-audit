# Q. ERC20Token - Findings Report

- ## High Risk Findings
    - [H-01. Permanent lock of funds](#H-01)

## <a id='H-01'></a>H-01. Permanent lock of funds in Token contract

publicMint is an payable function (i.e receive ether to the contract). But there is no way to take out funds from the contract leads to permanent locking of funds.

```solidity
  function publicMint(uint256 amount) external payable onlyNotBlacklisted{
      ...
  }
```

## Recommended Mitigation

Add a function that allows owner to transfer funds from contract.

```solidity
  function claimFunds(address _to) payable external onlyOwner {
    require(_to != address(0), "can't transfer to address(0)");

    uint256 amt = address(this).balance;
    (bool success, )payable(_to).call{value: amt}("");

    require(success, "funds transfer failed");

    emit FundsClaimed(_to, amt);
  }
```

