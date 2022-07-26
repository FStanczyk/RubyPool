// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RubyPool{

    ERC20 immutable public token0;
    ERC20 immutable public token1;
    address immutable public owner;

    //@note how much of token0/1 is in pool
    //we are holding these in local variables so nobody mess with pool prices by transfering directly to the address.
    uint256 public pool0;
    uint256 public pool1;

    //@note How much user deposited to stake of token0 and token1
    mapping(address=>uint256) public stake0;
    mapping(address=>uint256) public stake1;

    //@note array that holds all the stakers 
    address[] public staker0;
    address[] public staker1;

    //@note how much prize in fees has user to withdraw from token0 and token1
    mapping(address=>uint256) public prize0;
    mapping(address=>uint256) public prize1;

    event swap(uint256 amountIn, uint256 amountOut, string tokenIn, string tokenOut);
    event stakeAdded(uint256 amount, string token);
    event stakeRemoved(uint256 amount, string token);

    constructor(address _token0addr, address _token1addr){
        token0 = ERC20(_token0addr);
        token1 = ERC20(_token1addr);

        pool0 = 0;
        pool1 = 0;

        owner = msg.sender;
    }


    function getToken0pool() external view returns(uint256){
        return((token0).balanceOf(address(this)));
    }


    function getToken1pool() external view returns(uint256){
        return((token1).balanceOf(address(this)));
    }


    //@note exchange from token0 to token1
    function exchange0to1(uint256 _amount) external {
        require((token0).balanceOf(msg.sender)>=_amount,'Insufficient funds');
        require(_amount > 0, 'Put more than 0');

        uint256 trueAmount = _amount * 998/1000;
        uint256 prize = _amount - trueAmount;

        //@note constant product formula
        uint256 product = (pool1*trueAmount)/(pool0+trueAmount);

        (token0).transferFrom(msg.sender, address(this), _amount);
        (token1).transfer(msg.sender, product);

        distributePrize0(prize);

        emit swap(_amount, product, (token0).name(), (token1).name());
    }


    function exchange1to0(uint256 _amount) external {
        require((token1).balanceOf(msg.sender)>=_amount,'Insufficient funds');
        require(_amount > 0, 'Put more than 0');

        uint256 trueAmount = _amount * 998/1000;
        uint256 prize = _amount - trueAmount;

        //@note constant product formula
        uint256 product = (pool0*trueAmount)/(pool1+trueAmount);

        (token1).transferFrom(msg.sender, address(this), _amount);
        (token0).transfer(msg.sender, product);

        distributePrize1(prize);

        emit swap(_amount, product, (token1).name(), (token0).name());
    }


    function addStake0(uint256 _amount) external {
        require((token0).balanceOf(msg.sender)>=_amount,'Insufficient funds');
        require(_amount > 0, 'Put more than 0');

        uint256 balanceBefore = (token0).balanceOf(address(this));

        //@note send _amount to pool0 from msg.sender
        (token0).transferFrom(msg.sender, address(this), _amount);

        pool0 += _amount;
        stake0[msg.sender] +=_amount;
        staker0.push(msg.sender);

        assert((token0).balanceOf(address(this))==balanceBefore+_amount);

        emit stakeAdded(_amount, (token0).name());
    }


    function addStake1(uint256 _amount) external {
        require((token1).balanceOf(msg.sender)>=_amount,'Insufficient funds');
        require(_amount > 0, 'Put more than 0');

        uint256 balanceBefore = (token1).balanceOf(address(this));

        //@note send _amount to pool0 from msg.sender
        (token1).transferFrom(msg.sender, address(this), _amount);

        pool1 += _amount;
        stake1[msg.sender] +=_amount;
        staker1.push(msg.sender);

        assert((token1).balanceOf(address(this))==balanceBefore+_amount);

        emit stakeAdded(_amount, (token1).name());
    }


    function removeStake0(uint256 _amount) external {
        require(stake0[msg.sender]>= _amount, "Not enaugh staking");
        require(_amount > 0, 'Remove more than 0');

        uint256 balanceBefore = (token0).balanceOf(address(this));

        //@note rubyPool sends _amount of stake to the staker
        (token0).transfer(msg.sender, _amount);

        pool0 -= _amount;
        stake0[msg.sender]-=_amount;

        assert((token0).balanceOf(address(this))==balanceBefore-_amount);

        emit stakeRemoved(_amount, (token0).name());
    }


    function removeStake1(uint256 _amount) external {
        require(stake1[msg.sender]>= _amount, "Not enaugh staking");
        require(_amount > 0, 'Remove more than 0');

        uint256 balanceBefore = (token1).balanceOf(address(this));

        //@note rubyPool sends _amount of stake to the staker
        (token1).transfer(msg.sender, _amount);

        pool1 -= _amount;
        stake1[msg.sender]-=_amount;

        assert((token1).balanceOf(address(this))==balanceBefore-_amount);

        emit stakeRemoved(_amount, (token1).name());
    }


    function distributePrize0(uint256 _amount) private {
        for(uint i=0; i<staker0.length; i++){

            //@note calculate the prize for the staker
            uint256 prize = stake0[staker0[i]] / pool0 * _amount;

            prize0[staker0[i]] += prize;
        }
    }



    function distributePrize1(uint256 _amount) private {
        for(uint i=0; i<staker0.length; i++){

            //@note calculate the prize for the staker
            uint256 prize = stake1[staker1[i]] / pool1 * _amount;

            prize1[staker1[i]] += prize;
        }
    }


    function withdrawPrize0() external {

        require(prize0[msg.sender]>0 , "You have no prize to withdraw");

        uint256 prize = prize0[msg.sender];
        prize0[msg.sender] = 0;

        (token0).transfer(msg.sender, prize);
        
    }


    function withdrawPrize1() external {

        require(prize1[msg.sender]>0 , "You have no prize to withdraw");  

        uint256 prize = prize1[msg.sender];
        prize1[msg.sender] = 0;

        (token1).transfer(msg.sender, prize);
    
    }


    //@note since this function might cost a lot of gas owner might only call this function only 
    //when it will take too much gasto distribute prize. 
    //@question Is this a likely scenario? Do we need this function?
    function deleteZeroStakers() external {
        require(msg.sender == owner, "only owner");

        for(uint i = 0; i < staker0.length; i++) {

            if (stake0[staker0[i]] ==  0) {

                for(uint j = i; j< staker0.length; j++){
                    staker0[j] = staker0[j+1];
                }
                staker0.pop();
            }

        }
    }
}