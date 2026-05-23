pragma solidity ^0.8.0;

contract Blog {
    struct Post {
        address author;
        string title;
        string contentLink;
        uint32 dateUploaded;
    }

    mapping(uint => Post) public posts;
    uint public postCount;
    mapping(address => bool) isMember;
    mapping(uint => address) isPublisher;

    function registerMember() public {
        require(!isMember[msg.sender], "Already a member");
        isMember[msg.sender] = true;
    }

    function createPost(string memory _title, string memory _contentLink, uint32 _dateUploaded) public returns (uint) {
        require(isMember[msg.sender], "Not A Member!");
        posts[postCount] = Post(msg.sender, _title, _contentLink, _dateUploaded);
        isPublisher[postCount] = msg.sender;
        uint id = postCount;
        postCount++;
        return id;
    }

    function deletePost(uint _id) public {
        require(isPublisher[_id] == msg.sender, "Not The Publisher!");
        require(_id < postCount, "Post Not Found");
        delete posts[_id];
    }
}
