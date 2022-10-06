// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*
One of the major dangers of calling external contracts is that they can take over the control flow, and make changes to your data that the calling function wasn't expecting. This class of bugs can take many forms, and both of the major bugs that led to the DAO's collapse were bugs of this sort.
*/
/* The first version of this bug to be noticed involved functions that could be called repeatedly, before the first invocation of the function was finished. This may cause the different invocations of the function to interact in destructive ways. */
contract Reentrancy {
    mapping(address => uint256) private userBalances;

    //imagine two people calling this same function at the same time without some sort of a lock?

    function withdrawBalance() public {
        uint256 amountToWithdraw = userBalances[msg.sender];
        (bool success, ) = msg.sender.call{value: amountToWithdraw}(""); // At this point, the caller's code is executed, and can call withdrawBalance again
        require(success);
        userBalances[msg.sender] = 0;
    }
}
