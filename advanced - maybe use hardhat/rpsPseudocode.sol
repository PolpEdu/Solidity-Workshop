//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/*
we want something like this:
player 1
play("rock");

player 2
play("paper");

winner account can call this
contract will check that sender is the winner
claimPrize();

*/

contract RockPaperScissorsMaybe {
    uint256 public constant ENTRANCE_FEE = 0.1 ether;
    address public p1; //defaults to 0x0
    address public p2; //defaults to 0x0
    string public m1;
    string public m2;

    function play(string memory _move) public payable {
        require(!finished(), "all moves set");

        if (p1 == address(0)) {
            p1 = msg.sender;
            m1 = _move;
        } else {
            require(p1 != msg.sender, "can't play both sides");

            p2 = msg.sender;
            m2 = _move;
        }
    }

    function winner() internal view returns (address) {
        require(finished(), "moves missing");
        /* 
        Thorws an error: Cant compare strings in solidity like this:
        if (
            (m1 == "rock" && m2 == "scissor") ||
            (m1 == "paper" && m2 == "rock") ||
            (m1 == "scissor" && m2 == "paper")
        ) {
            return p1;
        } else {
            return p2;
        } */

        if (
            (compareStrings(m1, "rock") && compareStrings(m2, "scissor")) ||
            (compareStrings(m1, "paper") && compareStrings(m2, "rock")) ||
            (compareStrings(m1, "scissor") && compareStrings(m2, "paper"))
        ) {
            return p1;
        } else {
            return p2;
        }
    }

    function claimReward() public {
        require(winner() == msg.sender);

        uint256 reward = address(this).balance;

        payable(msg.sender).transfer(reward);
    }

    function finished() internal view returns (bool) {
        return p2 != address(0);
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}

//WHATS WRONG WITH THIS CODE?
/*
player 1
play("rock"); // this submits a transaction

player 2 can then read existing transactions,
and spy on what player 1's move was
play("paper");

-> https://emn178.github.io/online-tools/keccak_256.html
*/

/*
player 1
plays a hash: keccack256("rock-secr3t") -> rock + salt
play("d05c2b9c8221593088d05e5603e95a65629c485c7491a5cc5d394f0b489e4308");

player 2
plays a hash: keccack256("paper-12345") -> paper + salt
play("bc12654d21eed85d6b0b3de3ef094c5c8f7c436b44ecf61f8bf01c11cc26fae2");

revealMove("rock", "-secr3t"); -> remove salt
revealMove("paper", "-12345"); -> remove salt

winner account can call this
contract will check that sender is the winner
claimPrize();

The solution is to add salt and hash the move with the salt:
function revealMove(string _move, string _password) public {
    bytes32 m = keccak256(abi.encodePacked(_move, _password));
    
    if (m1_encrypted == m) {
        m1 = _move;
    } else if (m2_encrypted == m) {
        m2 = move;
    }
}
*/
