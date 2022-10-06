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
        // call is a low level function to interact with other contracts.

        (bool success, ) = msg.sender.call{value: amountToWithdraw}(""); // At this point, the caller's code is executed, and can call withdrawBalance again
        require(success);
        userBalances[msg.sender] = 0;
    }
}

/*
In a typical reentrancy attack, it would be something like a withdraw function
doing msg.sender.call.value(1 ether)().
The caller (a smart contract), would then call the function again, hence the "reentrancy"
attack. In this snippet, the call doesn't seem to be doing anything useful,
but it's just there to show that the locked variables guards against reentrancy.
*/