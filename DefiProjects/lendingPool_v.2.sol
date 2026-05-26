// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ownable.sol";
import "./reentrancyguard.sol";

contract LendingPool is Ownable, ReentrancyGuard  {

    address public governance;

    uint256 public totalLiquidity = 0;
    uint256 public interestRate = 500; // Annual interest rate in basis points (e.g., 500 for 5%)

    struct Users {
        uint256 deposited;
        uint256 borrowed;
        uint256 timeBorrowed;
        uint256 timeDeposited;
        uint256 borrowedAtRate;
        uint256 collateral;
    }
    
    mapping(address => Users) public addressToUsers; // Made public for easier external reading

    constructor(uint256 _interestRate, address _governance) {
        interestRate = _interestRate;
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "LendingPool: Caller is not Governance DAO");
        _;
    }
    // EVENTS
    event Deposit(address indexed _user, uint256 amount);
    event Withdraw(address indexed _user, uint256 amount);
    event Borrow(address indexed _user, uint256 amount);
    event Repay(address indexed _user, uint256 amount);

    /**
     * @dev Internal function to settle and apply passive deposit interest before any balance changes.
     */
    function _applyDepositInterest() private {
        Users storage user = addressToUsers[msg.sender];
        uint256 _monthElapsed = (block.timestamp - user.timeDeposited) / 30 days;
        
        if (user.deposited > 0 && _monthElapsed > 0) {
           uint256 accruedInterest = (user.deposited * 200 * _monthElapsed) / 10000;
           user.deposited += accruedInterest;
           totalLiquidity += accruedInterest;
        }
        uint256 remainder = (block.timestamp - user.timeDeposited) % 30 days;
        user.timeDeposited = block.timestamp - remainder; // Clock resets on every deposit/withdrawal interaction
    }

    function deposit(uint256 _amount) public nonReentrant {
        _applyDepositInterest(); // 1. Calculate and distribute accrued interest first
        
        require(_amount >= 10, "Amount must be greater than 10");
        Users storage user = addressToUsers[msg.sender];
        user.deposited += _amount;
        totalLiquidity += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        _applyDepositInterest(); // 1. Calculate and distribute accrued interest first
        
        require(_amount > 0, "Amount must be more than zero");
        Users storage user = addressToUsers[msg.sender];
        require(user.deposited >= _amount, "Insufficient Balance");
        require(totalLiquidity >= _amount, "Insufficient Liquidity");
        
        user.deposited -= _amount;
        totalLiquidity -= _amount;
        emit Withdraw(msg.sender, _amount);
    }

    function addCollateral(uint256 _amount) public nonReentrant {
        _applyDepositInterest(); // 1. Calculate and distribute accrued interest first
        
        require(_amount > 0, "Amount cant be zero");
        Users storage user = addressToUsers[msg.sender];
        require(user.deposited >= _amount, "Insufficient Funds");
        
        user.deposited -= _amount;
        user.collateral += _amount;
    }

    function withdrawCollateral(uint256 _amount) public nonReentrant {
        _applyDepositInterest(); // 1. Calculate and distribute accrued interest first
        
        require(_amount > 0, "Amount must be more than zero");
        
        Users storage user = addressToUsers[msg.sender];
        require(user.collateral >= _amount, "Insufficient Funds");
        require(user.borrowed == 0, "Pay Outstanding Loan");
        
        user.collateral -= _amount;
        user.deposited += _amount;
    }

    function borrow(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Amount must be more than zero");
        require(totalLiquidity >= _amount, "Insufficient Liquidity");
        
        Users storage user = addressToUsers[msg.sender];
        require(user.borrowed == 0, "Pay Outstanding Loan");
        require(user.collateral >= (_amount * 3) / 2, "Collateral must be at least 150% of amount");
        
        user.borrowedAtRate = interestRate;
        user.borrowed += _amount;
        user.timeBorrowed = block.timestamp;
        
        totalLiquidity -= _amount;
        emit Borrow(msg.sender, _amount);
    }

    function repay(uint256 _amount) public nonReentrant {
        Users storage user = addressToUsers[msg.sender];
        require(user.borrowed > 0, "No Outstanding");
        require(_amount > 0, "Amount must be more than zero");

        uint256 timeElapsed = block.timestamp - user.timeBorrowed;
        uint256 _interestRate = user.borrowedAtRate;
        uint256 interest = (_interestRate * user.borrowed * timeElapsed) / (10000 * 365 days);
        uint256 totalOwed = user.borrowed + interest;

        if (_amount >= totalOwed) {
            uint256 excess = _amount - totalOwed;
            if (excess > 0) {
                user.deposited += excess;
            }
            user.borrowed = 0;
            user.timeBorrowed = 0;
            totalLiquidity += _amount; 
        } else if (_amount > interest) {
            uint256 principalPaid = _amount - interest;
            user.borrowed -= principalPaid;
            user.timeBorrowed = block.timestamp; 
            totalLiquidity += _amount;
        } else {
            user.borrowed = totalOwed - _amount;
            user.timeBorrowed = block.timestamp; 
            totalLiquidity += _amount;
        }

        emit Repay(msg.sender, _amount);
    }

    function updateInterestRate(uint256 _newRate) external onlyGovernance {
        require(_newRate <= 2000, "Rate cannot exceed 20%");
        interestRate = _newRate;
    }

    function injectLiquidity(uint256 _amount) external onlyGovernance {
        require(_amount > 0, "liquidity cannot be zero");
        totalLiquidity += _amount;
    }

    function setGovernance(address _newGovernance) external onlyOwner {
        require(_newGovernance != address(0), "Invalid address");
        governance = _newGovernance;
    }

    function getUser(address _userAddress) public view returns (uint256 realTimeDeposited, uint256 borrowed, uint256 totalOwedAmount) {       
        Users memory _user = addressToUsers[_userAddress];
        
        // 1. Calculate pending deposit interest for UX accuracy
        uint256 calculatedDepositBalance = _user.deposited;
        uint256 _monthElapsed = (block.timestamp - _user.timeDeposited) / 30 days;
        if (_user.deposited > 0 && _monthElapsed > 0) {
            uint256 pendingDepositInterest = (_user.deposited * 200 * _monthElapsed) / 10000;
            calculatedDepositBalance += pendingDepositInterest;
        }

        // 2. Return early if they don't have an active loan
        if (_user.borrowed == 0) {
            return (calculatedDepositBalance, 0, 0);
        }
        
        // 3. Calculate borrowing interest
        uint256 timeElapsed = block.timestamp - _user.timeBorrowed;
        uint256 interest = (_user.borrowedAtRate * _user.borrowed * timeElapsed) / (10000 * 365 days);
        
        return (calculatedDepositBalance, _user.borrowed, _user.borrowed + interest);
    }
}
