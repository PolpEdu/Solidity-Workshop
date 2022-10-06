//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

contract PayoutSalaries {
    address public owner;
    mapping(address => uint256) public salaries;
    uint256 public totalSalaries;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addEmployee(address employeeAddress, uint256 salary)
        public
        onlyOwner
    {
        salaries[employeeAddress] = salary;
        totalSalaries += salary;
    }

    function removeEmployee(address employeeAddress) public onlyOwner {
        totalSalaries -= salaries[employeeAddress];
        delete salaries[employeeAddress];
    }

    // function called by employee to withdraw their salary
    function getPaid() public {
        require(salaries[msg.sender] > 0, "You do not work here");
        uint256 salary = salaries[msg.sender];
        (bool success, ) = msg.sender.call{value: salary}("");
        require(success, "Failed to send Ether");
    }
}
