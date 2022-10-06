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

contract RockPaperScissors {
    uint256 public constant ENTRANCE_FEE = 0.1 ether;

    enum Move {
        Rock,
        Paper,
        Scissors
    }

    mapping(bytes32 => bool) public winningPairs;

    struct Player {
        address account;
        bytes32 encryptedMove;
        Move move;
        bool revealed;
    }

    Player[] public players;

    // is there a way to make this static instead of evaluating on every deploy?
    // seems like a waste of gas
    constructor() {
        addWinningPair(Move.Scissors, Move.Paper);
        addWinningPair(Move.Paper, Move.Rock);
        addWinningPair(Move.Rock, Move.Scissors);
    }

    function addWinningPair(Move move1, Move move2) private {
        //abi.encodePacked(arg) -> produces bytes given arguments: https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#non-standard-packed-mode
        winningPairs[keccak256(abi.encodePacked(move1, move2))] = true;
    }

    function play(bytes32 encryptedMove) public payable returns (bool success) {
        require(msg.value == ENTRANCE_FEE);
        require(players.length < 2);

        Player memory player;
        player.account = msg.sender;
        player.encryptedMove = encryptedMove;

        players.push(player);

        return true;
    }

    function reveal(Move move, bytes32 salt) public returns (bool success) {
        require(players.length == 2);
        uint256 playerIndex = findPlayerIndex(msg.sender);
        require(playerIndex < 2);
        bytes32 hash = getHash(move, salt);

        require(players[playerIndex].encryptedMove == hash);

        players[playerIndex].move = move;
        players[playerIndex].revealed = true;

        return true;
    }

    function getWinner()
        public
        view
        ensureRevealed
        returns (address winningAccount)
    {
        if (players[0].move == players[1].move) {
            return address(0);
        }

        bytes32 hash = keccak256(
            abi.encodePacked(players[0].move, players[1].move)
        );

        if (winningPairs[hash]) {
            return players[0].account;
        } else {
            return players[1].account;
        }
    }

    function getPrize() public returns (bool success) {
        uint256 playerIndex = findPlayerIndex(msg.sender);
        require(playerIndex < 0);

        address winner = getWinner();

        if (winner == msg.sender) {
            payable(msg.sender).transfer(ENTRANCE_FEE * 2);
        } else if (winner == address(0)) {
            payable(msg.sender).transfer(ENTRANCE_FEE);
        }

        return true;
    }

    function findPlayerIndex(address account)
        public
        view
        returns (uint256 index)
    {
        if (players[0].account == account) {
            return 0;
        } else if (players[1].account == account) {
            return 1;
        } else {
            return 2;
        }
    }

    // A Pure Function is a function (a block of code) that always returns the same result if the same arguments are passed
    function getHash(Move move, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256(move), salt));
    }

    modifier ensureRevealed() {
        require(players[0].revealed);
        require(players[1].revealed);
        _;
    }
}
