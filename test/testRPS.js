const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

console.log('Started Test')

function assertRevert(error) {
    assert.isAbove(error.message.search('revert'), -1, 'Error containing "revert" must be returned');
}

//in case of an event we can use this function to check if the event was emitted
function assertEvent(contract, filter) {
    new Promise((resolve, reject) => {
        var event = contract[filter.event]();
        event.watch();
        event.get((error, logs) => {
            var log = _.filter(logs, filter);
            if (log.length > 0) {
                resolve(log);
            } else {
                throw Error("Failed to find filtered event for " + filter.event);
            }
        });
        event.stopWatching();
    });
}
function mineTx(tx) {
    //resolve tx promise and wait
    return Promise.resolve(tx).then(tx => tx.wait());
}



describe("RockPaperScissors", function () {
    let game, tx;
    const aliceSalt = "alice";
    const bobSalt = "bob";
    const bobSaltBytes32 = ethers.utils.formatBytes32String(bobSalt);
    const aliceSaltBytes32 = ethers.utils.formatBytes32String(aliceSalt);

    //0.1 ether
    const fee = ethers.utils.parseEther("0.1");

    const Move = {
        Rock: 0,
        Paper: 1,
        Scissors: 2,
    };
    const encryptedMove = async (m, salt) => {
        //transform salt into bytes32 to be able to use it in the contract
        const saltBytes32 = ethers.utils.formatBytes32String(salt);
        tx = await game.getHash(m, saltBytes32);
        return tx;
    };

    async function deployFactoryFixture() {
        // Get the ContractFactory and Signers here.
        const RPS = await ethers.getContractFactory('RockPaperScissors')
        let [owner, alice, bob, carol] = await ethers.getSigners();
        const gameobj = await RPS.deploy();

        await gameobj.deployed();
        game = gameobj;

        // Fixtures can return anything you consider useful for your tests
        return { RPS, owner, alice, bob, carol };
    }


    it("allows two players to enroll", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);
        /* DEPRECATED, now you need to connect instead
            tx = game.play(await encryptedMove(Move.Rock, aliceSalt), { from: alice.address, value: fee });
            tx = game.play(await encryptedMove(Move.Paper, bobSalt), { from: bob.address, value: fee });
        */
        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });

    });

    it("does not allow playing with an incorrect entrance fee", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        try {
            tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: 0 });
            await mineTx(tx);
            assert.fail();
        } catch (err) {
            assertRevert(err);
        }
    });

    it("does not allow 3 players to enroll", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);
        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);

        try {
            tx = await game.connect(carol).play(await encryptedMove(Move.Paper, ""), { value: fee });
            await mineTx(tx);
            assert.fail();
        } catch (err) {
            assertRevert(err);
        }
    });

    it("allows players to reveal their move", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);


        tx = await game.connect(alice).reveal(Move.Rock, aliceSaltBytes32);
        await mineTx(tx);
        tx = await game.connect(bob).reveal(Move.Paper, bobSaltBytes32);
        await mineTx(tx);

        const aliceMove = await game.players(0); //Rock
        const bobMove = await game.players(1); //Paper

        assert.equal(aliceMove.move, Move.Rock);
        assert.equal(bobMove.move, Move.Paper);
    });

    it("does not allow non-players to reveal their move", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);

        try {
            tx = await game.connect(carol).reveal(Move.Rock, aliceSaltBytes32);
            await mineTx(tx);
            assert.fail();
        } catch (err) {
            assertRevert(err);
        }
    });

    it("does not allow revealing the move before both players have played", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);

        try {
            tx = await game.connect(alice).reveal(Move.Rock, aliceSaltBytes32);
            await mineTx(tx);
            assert.fail();
        } catch (err) {
            assertRevert(err);
        }
    });

    it("selects the correct winner in a rock vs paper game", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);

        //tx = await game.connect(alice).reveal(Move.Rock, aliceSalt);
        tx = await game.connect(alice).reveal(Move.Rock, aliceSaltBytes32);
        await mineTx(tx);
        tx = await game.connect(bob).reveal(Move.Paper, bobSaltBytes32);
        await mineTx(tx);

        assert.equal(await game.getWinner(), bob.address);
    });

    it("selects the correct winner in a paper vs rock game", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        // reverse order than the one above
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(alice).play(await encryptedMove(Move.Rock, aliceSalt), { value: fee });
        await mineTx(tx);

        tx = await game.connect(bob).reveal(Move.Paper, bobSaltBytes32);
        await mineTx(tx);
        tx = await game.connect(alice).reveal(Move.Rock, aliceSaltBytes32);
        await mineTx(tx);

        assert.equal(await game.getWinner(), bob.address);
    });

    it("knows that paper disproves scissors", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        // reverse order than the one above
        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(alice).play(await encryptedMove(Move.Scissors, aliceSalt), { value: fee });
        await mineTx(tx);

        tx = await game.connect(bob).reveal(Move.Paper, bobSaltBytes32);
        await mineTx(tx);
        tx = await game.connect(alice).reveal(Move.Scissors, aliceSaltBytes32);
        await mineTx(tx);

        assert.equal(await game.getWinner(), alice.address);
    });

    it("can find draws", async () => {
        const { RPS, owner, alice, bob, carol } = await loadFixture(deployFactoryFixture);

        tx = await game.connect(bob).play(await encryptedMove(Move.Paper, bobSalt), { value: fee });
        await mineTx(tx);
        tx = await game.connect(alice).play(await encryptedMove(Move.Paper, aliceSalt), { value: fee });
        await mineTx(tx);

        //transfrom bobsalt in bytes32



        tx = await game.connect(bob).reveal(Move.Paper, bobSaltBytes32);
        await mineTx(tx);
        tx = await game.connect(alice).reveal(Move.Paper, aliceSaltBytes32);
        await mineTx(tx);

        assert.equal(await game.getWinner(), 0);




    });
});