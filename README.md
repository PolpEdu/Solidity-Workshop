# Hardhat Cheat Sheet 

## Compile a contract:
```shell
npx hardhat compile
```
This command compiles all the contracts in side the "contracts" folder

## Deploying & Testing your contract:
1. Start a local node:
```shell
npx hardhat node
```
2. Open a new terminal

3. Run tests on the contract
```shell
npx hardhat test
```
Assuming that the test script already deploys the contract for you... If not use:
```shell
npx hardhat deploy
```
