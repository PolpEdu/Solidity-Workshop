//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SoManyVariablesWow {
  string public name;
  string private symbol;
  address owner;
  
  mapping(address => uint256)  balances;
  
  struct Item {
    address addr;
    uint id;
  }
   
  // functions that sends ether to an address
    function sendEther(address _to) public payable {
        payable(_to).transfer(msg.value);
    }


  Item[] items;
}
