// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20("LPTOKEN","LPT"){
    IERC20 internal immutable token;
    uint internal v3;
    uint internal v4;
    uint internal v5;

    constructor(address _token){
        token = IERC20(_token);
    }

    /*
		 * @dev addLiquidity allows users to add liquidity to the exchange
     * @return Returns the amount of LP tokens to mint
		 */ 
    function addLiquidity(uint amountOfToken) external payable {
        uint ethBalance = address(this).balance;
        uint reservedBalance = getReserve();
        uint lpTokens;
        if(reservedBalance == 0){
            token.transferFrom(msg.sender,address(this),amountOfToken);
            lpTokens = ethBalance;
            _mint(msg.sender,lpTokens);
            v3 = lpTokens;
        }
        else{
            uint minAmountToken = (msg.value)*reservedBalance/(ethBalance-msg.value);
            if(amountOfToken < minAmountToken) revert();
            token.transferFrom(msg.sender,address(this),minAmountToken);
            uint y = (totalSupply() * msg.value) /(ethBalance-msg.value);
            _mint(msg.sender,y);
            v3 = y;
        }
    }

    /*
     * @dev removeLiquidity allows users to remove liquidity from the exchange
     * @param amountOfLPTokens - amount of LP tokens user wants to burn to get back ETH and TOKEN
     * @return Returns the amount to ETH and tokens to be returned to the user
     */
    function removeLiquidity(uint256 amountOfLPTokens) external {
        if(amountOfLPTokens == 0) revert();
        uint ethBalance = address(this).balance;
        v4 = (getReserve() * amountOfLPTokens)/totalSupply();
        v5 = (ethBalance * amountOfLPTokens)/totalSupply();
        token.transfer(msg.sender,v4 );
        payable(msg.sender).transfer(v5);
        _burn(msg.sender, amountOfLPTokens);
    }

    /**
    * @dev ethToTokenSwap allows users to swap ETH for TOKEN	
    */
    function ethToTokenSwap() external payable {
        uint tokenBalance = getReserve();
        if(msg.value==0) revert();
        if(tokenBalance==0) revert();
        uint currEth = address(this).balance - msg.value;
        uint val1 = msg.value * 99;
        uint val2 = val1 * tokenBalance;
        uint val3 = (currEth * 100) + val1 ;
        uint tokenToSend = val2/val3;
        token.transfer(msg.sender,tokenToSend);
    }

    /**
    * @dev tokenToEthSwap allows users to swap TOKEN for ETH	
    */
    function tokenToEthSwap(uint256 tokensToSwap) external {
        if(tokensToSwap==0) revert();
        if(address(this).balance==0) revert();
        uint val1 =tokensToSwap * 99;
        uint val2 = val1 * address(this).balance;
        uint val3 = (getReserve() * 100) + val1 ;
        uint ethToSend = val2/val3;
        token.transferFrom(msg.sender,address(this),tokensToSwap);
        payable(msg.sender).transfer(ethToSend);
    }

    /**
    * @dev getLPTokensToMint returns the amount of LP Tokens to be minted after addLiquidity has been called.
    * @notice Only called just after addLiquidity, if it is successful.
    * @return returns the LP Tokens to be minted to the liquidity provider 
    */
    function getLPTokensToMint() external view returns (uint256) {
        return v3;
    }

    /**
    * @dev getEthAndTokenToReturn returns the amount of ETH and Token that needs to be returned to the user when removeLiquidity is called.
    * @return returns the amount of ETH and Token to be returned to the user when removeLiquidity is called.
    * @notice only called just after removeLiquidity, if it is successful.
    */
    function getEthAndTokenToReturn() external view returns (uint256, uint256) {
        return (v5,v4);
    }
    
    /**
    * @dev getReserve returns the balanace of 'token' held by this contract
    */
    function getReserve() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getBalance(address user) external view returns (uint256){
        return balanceOf(user);
    }
}