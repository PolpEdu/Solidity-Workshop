//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AutoDestructable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function destroy() public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(payable(owner));
    }
}
