//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract CoinFlip {
    struct Player {
        address account; // address of the player, defaults to 0
        bool move; // true = heads, false = tails
    }

    struct Room {
        Player player1;
        Player player2;
        uint256 bet;
    }

    event PlayerJoined(address player, uint256 bet);
    event PlayerWon(address player, uint256 bet);

    mapping(uint256 => Room) public rooms;

    uint256 public roomcount = 0;

    uint256 public constant ENTRANCE_FEE = 0.001 ether;
    uint256 public constant MINIMUM_BET = 0.001 ether;

    function createRoom(bool HeadsorTails) public payable {
        require(msg.value >= MINIMUM_BET, "Bet must be at least 0.001 ether");
        require(msg.value > 0, "Please attach some eth to play the bet"); // is there ETH attached?
        require(
            rooms[roomcount].player1.account == address(0),
            "room not empty"
        ); // is the room empty?

        Player memory player;

        player.account = msg.sender;
        player.move = HeadsorTails;

        Room memory room;
        room.player1 = player;

        // minus the entrance fee
        room.bet = msg.value - ENTRANCE_FEE;

        rooms[roomcount] = room; //set the rrom id

        roomcount++;
        // emit event
        emit PlayerJoined(msg.sender, msg.value);
    }

    function joinRoom(uint256 roomid) public payable {
        require(
            msg.value - ENTRANCE_FEE == rooms[roomid].bet,
            "bet attached isn't the same"
        ); // is the bet the same?
        require(
            rooms[roomid].player2.account == address(0),
            "room is not empty"
        ); // is the room empty?

        Player memory player;

        player.account = msg.sender;
        player.move = !rooms[roomid].player1.move;
        rooms[roomid].player2 = player;

        // emit event
        emit PlayerJoined(msg.sender, msg.value);

        // flip the coin
        startGame(roomid);
    }

    function startGame(uint256 roomid) public {
        require(rooms[roomid].player1.account != address(0)); // is the room empty?
        require(rooms[roomid].player2.account != address(0)); // is the room empty?

        //! a little bit of randomness. Don't use this in production! Chainlink's oracle is way safer
        // this is just for demo purposes
        uint256 random = getRandomNumber();

        bool winner = random % 2 == 0 ? true : false;

        if (winner == rooms[roomid].player1.move) {
            payable(rooms[roomid].player1.account).transfer(
                rooms[roomid].bet * 2
            );
            emit PlayerWon(
                rooms[roomid].player1.account,
                rooms[roomid].bet * 2
            );
        } else {
            payable(rooms[roomid].player2.account).transfer(
                rooms[roomid].bet * 2
            );
            emit PlayerWon(
                rooms[roomid].player2.account,
                rooms[roomid].bet * 2
            );
        }
    }

    //UNSAFE FUNCTION! Sometimes, if pressed too quiclky, it will return the same number
    function getRandomNumber() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        rooms[roomcount].player1.account,
                        rooms[roomcount].player2.account
                    )
                )
            );
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRoomCount() public view returns (uint256) {
        return roomcount;
    }

    function getRoom(uint256 roomid)
        public
        view
        returns (
            address,
            bool,
            address,
            bool,
            uint256
        )
    {
        require(rooms[roomid].bet > 0, "Room does not exist");
        return (
            rooms[roomid].player1.account,
            rooms[roomid].player1.move,
            rooms[roomid].player2.account,
            rooms[roomid].player2.move,
            rooms[roomid].bet
        );
    }
}
