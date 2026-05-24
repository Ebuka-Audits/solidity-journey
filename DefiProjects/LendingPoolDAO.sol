// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ownable.sol";

interface ILendingPool {
    function updateInterestRate(uint256 _newRate) external;
    function injectLiquidity(uint256 _amount) external;
}

contract LendingPoolGovernment is Ownable {

    ILendingPool public lendingPool;

    event ProposalCreated(uint id, address proposedBy);
    event Voted(uint id, address voter, bool yesVote);
    event ProposalExecuted(uint id);

    enum ProposalType { LiquidityInjection, RateChange }
    enum Status { Pending, Accepted, Rejected }

    mapping(address => bool) isMember;
    mapping(uint => mapping(address => bool)) hasVoted;
    mapping(uint => bool) hasExecuted;

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

    constructor(address _address) {
        lendingPool = ILendingPool(_address);
    }

    function registerMember() public {
        require(!isMember[msg.sender], "Already a Member!");
        isMember[msg.sender] = true;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _type,
        uint256 _value
    ) public {
        require(isMember[msg.sender], "Not a Member!");
        require(bytes(_title).length > 5 && bytes(_description).length > 0 && _value > 0, "Invalid fields");
        proposals.push(Proposal(
            _title,
            _description,
            _type,
            Status.Pending,
            msg.sender,
            _value,
            0,
            0,
            block.timestamp + 1 days
        ));
        uint256 id = proposals.length - 1;
        emit ProposalCreated(id, msg.sender);
    }

    function vote(bool _yesVote, uint256 _id) public {
        require(isMember[msg.sender], "Not A Member");
        require(_id < proposals.length, "Proposal Does Not Exist");
        require(!hasVoted[_id][msg.sender], "Already Voted");
        require(block.timestamp < proposals[_id].deadline, "Voting Period Has Ended");
        if (_yesVote == true) {
            proposals[_id].yesVotes++;
        } else {
            proposals[_id].noVotes++;
        }
        hasVoted[_id][msg.sender] = true;
        emit Voted(_id, msg.sender, _yesVote);
    }

    function executeProposal(uint256 _id) public {
        require(_id < proposals.length, "Proposal Does Not Exist");
        require(block.timestamp >= proposals[_id].deadline, "Voting Is Ongoing");
        require(!hasExecuted[_id], "Proposal Already Executed");
        if (proposals[_id].yesVotes > proposals[_id].noVotes) {
            proposals[_id].status = Status.Accepted;
            if (proposals[_id].proposalType == ProposalType.RateChange) {
                lendingPool.updateInterestRate(proposals[_id].proposalValue);
            } else {
                lendingPool.injectLiquidity(proposals[_id].proposalValue);
            }
        } else {
            proposals[_id].status = Status.Rejected;
        }
        hasExecuted[_id] = true;
        emit ProposalExecuted(_id);
    }
}