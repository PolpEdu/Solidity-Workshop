//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    string public name = "JEST Workshop Token";
    string public symbol = "JWT";

    // The fixed amount of tokens, stored in an unsigned integer type variable.
    uint256 public totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // Percentage FEE AMOUNT
    uint256 public feeAmount = 10;

    // A mapping is a key/value map. Here we store each account's balance.
    mapping(address => uint256) balances;

    // The Transfer event helps off-chain applications understand
    // what happens within your contract.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Mint(address indexed _to, uint256 _value);

    /**
     * Contract initialization.
     */
    constructor() {
        // The totalSupply is assigned to the transaction sender, which is the
        // account that is deploying the contract.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }


    // mint for ether
    function mint() payable external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(msg.value > 0, "Not enough ether");
        require(msg.value <= 1 ether, "Too much ether");

        // Transfer the amount.
        balances[msg.sender] += msg.value;

        // Notify off-chain applications of the transfer.
        emit Mint(msg.sender, msg.value);
    }


    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from *outside*
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        uint256 fee = amount * feeAmount / 100;
        
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount+fee, "Not enough tokens");

        // Transfer the amount.
       /*  balances[msg.sender] -= amount;
        balances[to] += amount; */

        // take the fee out
        balances[msg.sender] -= amount + fee;
        balances[to] += amount;
        balances[owner] += fee;

        // Notify off-chain applications of the transfer.
        emit Transfer(msg.sender, to, amount);
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}
