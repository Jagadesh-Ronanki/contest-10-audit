// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Implement the ERC-20 smart contract.
contract Token {
    address immutable private owner;
    string private _name;
    string private _symbol;
    mapping (address => uint) private balance;
    mapping (address => bool) private isBlackListed;
    uint private tokens;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory name_, string memory symbol_) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
    }
    
    modifier onlyNotBlacklisted{
        require(isBlackListed[msg.sender] == false);
        _;
    }

    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }

    function mint(address _to, uint256 _amount) external onlyOwner{
        require(isBlackListed[_to]==false);
        balance[_to] += _amount;
        tokens += _amount;
    }

    function burn(uint256 amount) onlyNotBlacklisted public{
        balance[msg.sender] -= amount;
        tokens -= amount;
    }

    function batchMint(address[] calldata _to, uint256[] calldata _amounts) external onlyOwner{
        uint temp = _to.length;
        if((_to.length != _amounts.length )|| temp==0 || _to.length==0) revert();
        for(uint i;i<temp;i++){
            balance[_to[i]] += _amounts[i];
            tokens += _amounts[i];
        }
    }

    function publicMint(uint256 amount) external payable onlyNotBlacklisted{
        if(amount == 0) revert();
        require(msg.value ==  1000000000000000 * (amount * ((2 * tokens) + (amount - 1)))/2);
        balance[msg.sender] += amount;
        tokens = tokens + amount;
    }

    function blacklistUser(address user) external onlyOwner{
        if(isBlackListed[user]) revert();
        isBlackListed[user] = true;
        tokens -= balance[user];
        balance[user] = 0;
    }

    function name() external view returns(string memory) {
        return _name;
    }
    function symbol() external view returns(string memory) {
        return _symbol;
    }
    function balanceOf(address user) external view returns(uint){
        return balance[user];
    }
    function totalSupply() external view returns (uint256){}
    function transfer(address _to, uint256 _value) external returns (bool success){}
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success){}
    function approve(address _spender, uint256 _value) external returns (bool success){}
    function allowance(address _owner, address _spender) external view returns (uint256 remaining){}

}