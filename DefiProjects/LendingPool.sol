// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ownable.sol";

contract LendingPool is Ownable {
    uint256 public totalLiquidity = 0;
    uint256 public interestRate = 500;

    struct Users {
        uint256 deposited;
        uint256 borrowed;
        uint256 timeBorrowed;
    }

    mapping(address => Users) addressToUsers;

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    event Deposit(address indexed _user, uint256 amount);
    event Withdraw(address indexed _user, uint256 amount);
    event Borrow(address indexed _user, uint256 amount);
    event Repay(address indexed _user, uint256 amount);

    function deposit(uint256 _amount) public {
        require(_amount >= 10, "Amount must be greater than 10");
        addressToUsers[msg.sender].deposited += _amount;
        totalLiquidity += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Amount must be more than zero");
        require(addressToUsers[msg.sender].deposited >= _amount, "Insufficient Balance");
        require(totalLiquidity >= _amount, "Insufficient Liquidity");
        addressToUsers[msg.sender].deposited -= _amount;
        totalLiquidity -= _amount;
        emit Withdraw(msg.sender, _amount);
    }

    function borrow(uint256 _amount) public {
        require(_amount > 0, "Amount must be more than zero");
        require(totalLiquidity >= _amount, "Insufficient Liquidity");
        require(addressToUsers[msg.sender].borrowed == 0, "Pay Outstanding Loan");
        addressToUsers[msg.sender].borrowed += _amount;
        addressToUsers[msg.sender].timeBorrowed = block.timestamp;
        totalLiquidity -= _amount;
        emit Borrow(msg.sender, _amount);
    }

    function repay(uint256 _amount) public {
        require(addressToUsers[msg.sender].borrowed > 0, "No Outstanding");
        require(_amount > 0, "Amount must be more than zero");
        uint256 timeElapsed = (block.timestamp - addressToUsers[msg.sender].timeBorrowed) / (365 days);
        uint256 interest = (interestRate * addressToUsers[msg.sender].borrowed * timeElapsed) / 10000;
        uint256 totalOwed = addressToUsers[msg.sender].borrowed + interest;
        addressToUsers[msg.sender].borrowed -= _amount;
        totalLiquidity += _amount;
        if (_amount >= totalOwed) {
            addressToUsers[msg.sender].timeBorrowed = 0;
            addressToUsers[msg.sender].borrowed = 0;
        }
        emit Repay(msg.sender, _amount);
    }

    function updateInterestRate(uint256 _newRate) public onlyOwner {
        interestRate = _newRate;
    }

    function injectLiquidity(uint256 _amount) public onlyOwner {
        totalLiquidity += _amount;
    }

    function getUser(address _userAddress) public view returns (uint256 deposited, uint256 borrowed, uint256 totalOwed) {
        Users memory _user = addressToUsers[_userAddress];
        if (_user.borrowed == 0) {
            return (_user.deposited, 0, 0);
        }
        uint256 timeElapsed = (block.timestamp - _user.timeBorrowed) / (365 days);
        uint256 interest = (interestRate * _user.borrowed * timeElapsed) / 10000;
        uint256 totalOwed = _user.borrowed + interest;
        return (_user.deposited, _user.borrowed, totalOwed);
    }
}
