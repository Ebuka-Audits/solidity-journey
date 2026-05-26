// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ownable.sol";
import "./reentrancyguard.sol";


interface ILendingPool {
    function updateInterestRate(uint256 _newRate) external;
    function injectLiquidity(uint256 _amount) external;
}

contract LendingPoolGovernment is Ownable, ReentrancyGuard {

    ILendingPool public lendingPool;

    event ProposalCreated(uint256 indexed id, address indexed proposedBy);
    event Voted(uint256 indexed id, address indexed voter, bool yesVote);
    event ProposalExecuted(uint256 indexed id);

    enum ProposalType { LiquidityInjection, RateChange }
    enum Status { Pending, Accepted, Rejected }

    mapping(address => bool) public isMember; // Made public for easier frontend validation
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => bool) public hasExecuted;

    modifier onlyMember() {
    require(isMember[msg.sender], "Not A Member");
    _;
    }

    struct Proposal {
        string proposalTitle;
        string proposalDescription;
        ProposalType proposalType;
        Status status;
        address proposedBy;
        uint256 proposalValue;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
    }

    Proposal[] public proposals;

   bool public isProposalActive = false;

    constructor(address _lendingPoolAddress) {
        require(_lendingPoolAddress != address(0), "Invalid Lending Pool Address");
        lendingPool = ILendingPool(_lendingPoolAddress);
    }

    function updatePoolAddress(address _poolAddress) external onlyOwner {
        require(_poolAddress != address(0), "Invalid address");
        lendingPool = ILendingPool(_poolAddress);
    }

    function registerMember() public {
        require(!isMember[msg.sender], "Already a Member!");
        if (isProposalActive) {
            uint256 latestId = proposals.length - 1;
            require(block.timestamp >= proposals[latestId].deadline, "Proposal is Ongoing, Try Again Later");
        }
        isMember[msg.sender] = true;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _type,
        uint256 _value
    ) public onlyMember {
        require(!isProposalActive, "A Proposal is still active");
        require(bytes(_title).length > 5, "Title must be > 5 chars");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_value > 0, "Value must be greater than zero");
        
        proposals.push(Proposal({
            proposalTitle: _title,
            proposalDescription: _description,
            proposalType: _type,
            status: Status.Pending,
            proposedBy: msg.sender,
            proposalValue: _value,
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + 1 days
        }));
        isProposalActive = true;
        uint256 id = proposals.length - 1;
        emit ProposalCreated(id, msg.sender);
    }

    function vote(bool _yesVote, uint256 _id) public onlyMember {
        require(_id < proposals.length, "Proposal Does Not Exist");
        require(!hasVoted[_id][msg.sender], "Already Voted");
        require(block.timestamp < proposals[_id].deadline, "Voting Period Has Ended");
        
        if (_yesVote) {
            proposals[_id].yesVotes++;
        } else {
            proposals[_id].noVotes++;
        }
        
        hasVoted[_id][msg.sender] = true;
        emit Voted(_id, msg.sender, _yesVote);
    }

    function executeProposal(uint256 _id) public onlyMember {
        require(_id < proposals.length, "Proposal Does Not Exist");
        require(block.timestamp >= proposals[_id].deadline, "Voting Is Ongoing");
        require(!hasExecuted[_id], "Proposal Already Executed");
        
        Proposal storage proposal = proposals[_id]; // Use storage pointer to update layout easily

        // FIX: Update execution status BEFORE cross-contract interaction (CEI Pattern)
        hasExecuted[_id] = true; 
        isProposalActive = false;
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = Status.Accepted;
            
            // Execute cross-contract instruction
            if (proposal.proposalType == ProposalType.RateChange) {
                lendingPool.updateInterestRate(proposal.proposalValue);
            } else {
                lendingPool.injectLiquidity(proposal.proposalValue);
            }
        } else {
            proposal.status = Status.Rejected;
        }
        
        emit ProposalExecuted(_id);
    }
}
