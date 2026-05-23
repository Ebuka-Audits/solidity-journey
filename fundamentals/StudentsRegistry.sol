pragma solidity ^0.8.0;

contract StudentRegistry {
    struct Student {
        string name;
        string nationality;
        string course;
        uint32 dob;
        uint8 level;
        uint16 gpa;
    }

    Student[] private students;

    function _registerStudent(string memory _name, string memory _nation, string memory _course, uint32 _dob, uint8 _level, uint16 _gpa) private returns (uint32) {
        students.push(Student(_name, _nation, _course, _dob, _level, _gpa));
        uint32 idHash = uint32(uint256(keccak256(abi.encodePacked(_name, _nation, _course)))) % 10 ** 8;
        uint32 id = uint32(idHash + students.length);
        return id;
    }

    function applyStudent(string memory _name, string memory _nation, string memory _course, uint32 _dob, uint8 _level, uint16 _gpa) public {
        require(_gpa >= 400, "GPA is below admission standard");
        require(_gpa <= 500, "GPA cannot exceed 5.00");
        _registerStudent(_name, _nation, _course, _dob, _level, _gpa);
    }
}
