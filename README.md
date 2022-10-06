## First create a "local" blockchain

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

## You can also try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```