// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IToken {
    function tranferFrom(address from, address to, uint256 amount) external returns(bool);
    function getBalance(address wallet) external view returns(uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract DDSwapStake {
    address ddTokenAddress;

    mapping(address => uint256) private addressStakeAmount;

    constructor(address _ddTokenAddress) {
        ddTokenAddress = _ddTokenAddress;
    }

    event Stake(address _user, uint256 _amount);
    event TakeStakeBack(address _user, uint256 _amount);

    function stakeDDToken(uint256 _amount) public returns(bool) {
        IToken token = IToken(ddTokenAddress);

        uint256 allowanceAmount = token.allowance(msg.sender, address(this));
        require(allowanceAmount >= _amount, "Allowance is not enough");

        uint256 userBalance = token.getBalance(msg.sender);
        require(userBalance >= _amount, "Balance is not enough");

        token.tranferFrom(msg.sender, address(this), _amount);
        addressStakeAmount[msg.sender] += _amount;

        emit Stake(msg.sender, _amount);

        return true;
    }

    function takeStakeBack(uint256 _amount) public returns(bool) {
        IToken token = IToken(ddTokenAddress);

        require(addressStakeAmount[msg.sender] >= _amount, "Balance is not enough");

        token.transfer(msg.sender, _amount);

        addressStakeAmount[msg.sender] -= _amount;

        emit TakeStakeBack(msg.sender, _amount);

        return true;
    }

    function getStake(address _user) public view returns(uint256) {
        return addressStakeAmount[_user];
    }
}
