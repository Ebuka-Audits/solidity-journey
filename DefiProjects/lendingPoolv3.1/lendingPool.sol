// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;
import "./ownable.sol";
import "./Reentrancyguard.sol";

contract LendingPool is Ownable, ReentrancyGuard {
    
    uint256 interestRate;
    uint256 liquidityPool;
    uint256 public constant MAX_LOAN_DURATION = 90 days;

    ///////////////////////////////////// EVENTS /////////////////////////////////////////////////
    
    event Member(address _address);
    event Borrow(address _address, uint256 _amountBorrowed);
    event Deposit(address _address, uint256 _amountDeposited);
    event Repay(address _address, uint256 _amountPaid);
    event Withdraw(address _address, uint256 _amountWithdrawn);

    
    //////////////////////////////// CONSTRUCTOR /////////////////////////////////////////////////
    
    constructor(uint256 _interestRate, uint256 _liquidutyPool) {
     require(_interestRate <= 2000 && _interestRate >= 500, "Unallowed Value");
        interestRate = _interestRate;
        liquidityPool = _liquidutyPool;
    }

    ////////////////////////////////// STRUCT ////////////////////////////////////////////////////////////

    struct Users {
        uint256 deposited;
        uint256 borrowed;
        uint256 colaterral;
        uint256 depositedAt;
        uint256 borrowedAtRate;
        uint256 borrowedAt;
    }
    
    /////////////////////////////////// MAPPINGS ///////////////////////////////////////////////////////////

    mapping(address => bool) isMember;
    mapping(address => Users) addressToUsers;
    mapping(address => bool) blockedUsers;
    mapping(address => bool) isAllowed;
    mapping(address => mapping(bytes4 => uint256)) lastAction; // ← missing

    //////////////////////// MODIFIERS //////////////////////////////

    modifier onlyMember() {
        require(isMember[msg.sender] == true, "Not A Member, Please Register");
        require(blockedUsers[msg.sender] == false, "User has been blocked");
        _;
    }

    modifier notLessThanTen(uint256 _amount) {
        require(_amount >= 10, "Amount Can't less than 10");
        _;
    }

    modifier sufficientLiquidity(uint256 _amount) {
        require(liquidityPool > (_amount + 20000), "Insufficient Liquidity");
        _;
    }

    modifier noBots() {
        require(tx.origin == msg.sender, "No Bots Or Contracts Allowed");
        _;
    }

    modifier rateLimit() {
    require(block.timestamp - lastAction[msg.sender][msg.sig] >= 1 hours, "Too Fast");
    lastAction[msg.sender][msg.sig] = block.timestamp;
    _;
    }


    //////////////////////// FUNCTIONS ///////////////////////////////

    function registerMember() external  rateLimit {
        require(isAllowed[msg.sender], "Not Approved");
        require(!isMember[msg.sender], "Already A Member");
        isMember[msg.sender] = true;
        emit Member(msg.sender);
    }

    function deposit(uint256 _amount) external nonReentrant onlyMember notLessThanTen(_amount) rateLimit {
        Users storage user = addressToUsers[msg.sender];
        user.deposited += _amount;
        liquidityPool += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function calculateColaterral(uint256 _amountToBeBorrowed) private  view notLessThanTen(_amountToBeBorrowed) returns (uint256) {
        uint256 _colatteralRequired = _amountToBeBorrowed * 2;
        return _colatteralRequired;
    }

    function addColatteral(uint256 _amount) external nonReentrant onlyMember notLessThanTen(_amount) {
        Users storage user = addressToUsers[msg.sender];
        require(user.deposited >= _amount, "Insufficient Funds");
        user.deposited -= _amount;
        user.colaterral += _amount;
    }

    function borrow(uint256 _amount) external nonReentrant onlyMember notLessThanTen(_amount) sufficientLiquidity(_amount) rateLimit {
        Users storage user = addressToUsers[msg.sender];
        require(user.borrowed == 0,"Pay Outstanding Loan");
        user.borrowedAtRate = interestRate;
        require(user.colaterral >= calculateColaterral(_amount), "Insufficient Colaterral");
        user.borrowedAt = block.timestamp;
        user.borrowed += _amount;
        liquidityPool -= _amount;
        emit Borrow(msg.sender, _amount);
    }

    function withdrawCollateral(uint256 _amount) external nonReentrant onlyMember notLessThanTen(_amount) {
        Users storage user = addressToUsers[msg.sender];
        require(user.borrowed == 0, "Pay Outstanding Debt");
        require(user.colaterral >= _amount, "Insufficient Funds");
        user.colaterral -= _amount;
        user.deposited += _amount;
    }

    function repay(uint256 _amount) external nonReentrant onlyMember notLessThanTen(_amount) {
        Users storage user = addressToUsers[msg.sender];
        require(user.borrowed > 0, "No Oustanding Debt" );
        uint256 timeElapsed = block.timestamp - user.borrowedAt;
        uint256 monthsElapsed = timeElapsed / 30 days;
        require(monthsElapsed > 0, "A Month Must Elapse Before repayment");
        uint256 interest =  (user.borrowed * user.borrowedAtRate * monthsElapsed) / 10000;
        require(_amount >= interest, "Minimum ammount payable is interest");
        uint256 afterInterestDeduction = _amount - interest;
        liquidityPool += interest;
        if(afterInterestDeduction == user.borrowed) {
            user.borrowed = 0;
            user.borrowedAt = 0;
            user.borrowedAtRate = 0;
            liquidityPool += afterInterestDeduction;
        } else if(afterInterestDeduction > user.borrowed) {
            uint256 excess = afterInterestDeduction - user.borrowed;
            user.deposited += excess;
            user.borrowed = 0;
            user.borrowedAt = 0;
            user.borrowedAtRate = 0;
            liquidityPool += afterInterestDeduction;
        } else if(afterInterestDeduction < user.borrowed) {
            user.borrowed -= afterInterestDeduction;
            liquidityPool += afterInterestDeduction;

        }
        emit Repay(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant notLessThanTen(_amount) onlyMember sufficientLiquidity(_amount) rateLimit  {
        Users storage user = addressToUsers[msg.sender];
        require(user.deposited >= _amount);
        user.deposited -= _amount;
        liquidityPool -= _amount;
        emit Withdraw(msg.sender, _amount);
    }

    function liquidate(address _user) external {
        Users storage user = addressToUsers[_user];
        require(user.borrowed > 0, "No debt");
        require(block.timestamp > user.borrowedAt + MAX_LOAN_DURATION, "Loan still healthy");
        user.colaterral = 0;
        user.borrowed = 0;
        user.borrowedAt = 0;
        user.borrowedAtRate = 0;
    }

    /////////////////////////////// ADMIN FUNCTIONS ////////////////////////////////

    function  updateInterestRate(uint256 _newRate)  external onlyOwner  {
        require(_newRate != interestRate && _newRate <= 2000 && _newRate >= 500, "Unallowed Value");
        interestRate = _newRate;
    }

    function injectLiquidity(uint256 _amount) external nonReentrant onlyOwner  {
        require(_amount >=100 && _amount <= 5000000, "Unallowed Value");
        liquidityPool += _amount;
    }

    function blockUser(address _address) external nonReentrant onlyOwner {
        require(!blockedUsers[_address], "User is already blocked");
        blockedUsers[_address] = true;
    }

    function unblockUser(address _address) external nonReentrant onlyOwner {
        require(blockedUsers[_address], "User is not blocked");
        blockedUsers[_address] = false;
    }

    function removeMember(address _address) external nonReentrant onlyOwner {
        Users storage user = addressToUsers[_address];
        require(isMember[_address], "Not A Member");
        require(user.borrowed == 0, "User has outstanding loan");
        require(user.deposited == 0, "User has Available Balance");
        require(user.colaterral == 0, "User has outstanding collateral");
        isMember[_address] = false;
        isAllowed[_address] = false;
    }

    function approveAddress(address _address) external onlyOwner {
    isAllowed[_address] = true;
    }

}
