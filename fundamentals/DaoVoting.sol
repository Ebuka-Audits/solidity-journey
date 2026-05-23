pragma solidity ^0.8.0;
import "./ownable.sol";

interface ITokenContract {
    function balanceOf(address _address) external view returns (uint);
}

contract DaoVoting is Ownable {
    enum Status { Pending, UnderReview, Accepted, Rejected }

    struct Proposal {
        string proposalName;
        string proposalDescription;
        address proposedBy;
        uint proposalAmount;
        Status status;
        uint yesVotes;
        uint noVotes;
        uint deadline;
    }

    event ProposalCreated(uint id, address proposedBy);
    event Voted(uint id, address voter, bool yesVote);
    event ProposalExecuted(uint id);

    Proposal[] public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public isMember;

    ITokenContract public tokenContract;

    constructor(address _tokenAddress) {
        tokenContract = ITokenContract(_tokenAddress);
    }

    function updateTokenContract(address _newAddress) public onlyOwner {
        tokenContract = ITokenContract(_newAddress);
    }

    function registerMember() public {
        require(!isMember[msg.sender], "Already A Member!");
        require(tokenContract.balanceOf(msg.sender) >= 5, "Insufficient Balance. Must hold at least 5 tokens to join.");
        isMember[msg.sender] = true;
    }

    function createProposal(string memory _proposalName, string memory _proposalDescription, uint _proposalAmount) public returns (uint) {
        require(isMember[msg.sender] && tokenContract.balanceOf(msg.sender) >= 100, "Must be a registered member with at least 100 tokens to propose.");
        proposals.push(Proposal(_proposalName, _proposalDescription, msg.sender, _proposalAmount, Status.Pending, 0, 0, block.timestamp + 300));
        uint id = proposals.length - 1;
        emit ProposalCreated(id, msg.sender);
        return id;
    }

    function vote(bool _yesVote, uint _id) public {
        require(isMember[msg.sender] && tokenContract.balanceOf(msg.sender) >= 5, "Must be a DAO Member and Have at least 5 tokens");
        require(_id < proposals.length, "Proposal Does Not Exist");
        require(!hasVoted[_id][msg.sender], "You Have Already Voted!");
        require(block.timestamp < proposals[_id].deadline, "Voting Period Has Ended");
        if (_yesVote == true) {
            proposals[_id].yesVotes++;
        } else {
            proposals[_id].noVotes++;
        }
        hasVoted[_id][msg.sender] = true;
        emit Voted(_id, msg.sender, _yesVote);
    }

    function executeProposal(uint256 _id) public onlyOwner {
        require(_id < proposals.length, "Proposal does not exist.");
        require(proposals[_id].status != Status.Accepted && proposals[_id].status != Status.Rejected, "Proposal has been resolved");
        require(block.timestamp >= proposals[_id].deadline, "Voting Period Still Active");
        if (proposals[_id].yesVotes > proposals[_id].noVotes) {
            proposals[_id].status = Status.Accepted;
        } else {
            proposals[_id].status = Status.Rejected;
        }
        emit ProposalExecuted(_id);
    }
}
