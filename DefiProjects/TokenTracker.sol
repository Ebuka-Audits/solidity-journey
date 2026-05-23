// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ownable.sol";

contract Tracker is Ownable {
    string tokenName;
    string tokenSymbol;
    uint256 totalSupply;

    mapping(address => uint) addressToBalance;
    mapping(address => bool) hasReceived;
    address[] public holders;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _totalSupply) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        totalSupply = _totalSupply;
        addressToBalance[msg.sender] = _totalSupply;
    }

    event Transfer(address _sender, address _receiver, uint256 _amount);

    function transfer(uint _amount, address _receiver) public {
        require(addressToBalance[msg.sender] >= _amount, "Insufficient Balance");
        if (!hasReceived[_receiver]) {
            holders.push(_receiver);
            hasReceived[_receiver] = true;
        }
        addressToBalance[msg.sender] -= _amount;
        addressToBalance[_receiver] += _amount;
        emit Transfer(msg.sender, _receiver, _amount);
    }

    function getBalance(address _address) public view returns (uint) {
        return addressToBalance[_address];
    }

    function getTokenInfo() public view returns (string memory _name, string memory _symbol, uint _totalSupply) {
        return (tokenName, tokenSymbol, totalSupply);
    }

    function mint(uint256 _amount) public onlyOwner {
        require(_amount <= totalSupply / 10);
        totalSupply += _amount;
        addressToBalance[msg.sender] += _amount;
    }

    function getTopHolder() public view onlyOwner returns (address) {
        require(holders.length > 0, "No holders yet");
        uint256 highestBalance;
        address topHolder;
        for (uint256 i = 0; i < holders.length; i++) {
            if (addressToBalance[holders[i]] > highestBalance) {
                highestBalance = addressToBalance[holders[i]];
                topHolder = holders[i];
            }
        }
        return topHolder;
    }
}
