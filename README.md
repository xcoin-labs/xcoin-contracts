# XCoin Contracts

This repository houses the `XCoin` and `Distribution` contracts.

## XCoin

XCoin is an ERC-20 token. See [src/XCoin.sol](./src/XCoin.sol).

### Properties

```
Name: XCoin
Symbol: XCOIN
Total Supply: 10,000,000,000
```

### Deployment

```
Chain: Ethereum
Contract Name: XCoin
Contract Address: 0x54CA815817aB29c389053f47FfB6d57aEE958877
```

## Distribution

Allows users to claim tokens based on validity and availability. See [src/Distribution.sol](./src/Distribution.sol).

### Claim Conditions

```
1. One claim per address
2. Not expired (52 weeks) 
3. Valid signature (signed by contract owner)
4. Sufficient token balance 
```

### Deployment

```
Chain: Ethereum
Contract Name: Distribution
Contract Address: 0x1D3f9511ED01F7a8F0071e92C05c2BD439a91706
```

## Distribution2

Allows users to claim tokens based on validity and availability. See [src/Distribution2.sol](./src/Distribution2.sol).

### Claim Conditions

```
1. One claim per address
2. Not expired
3. Valid signature (signed by contract owner)
4. Sufficient token balance
```

### Deployment

```
Chain: Ethereum
Contract Name: Distribution2
Contract Address: 0x07e158D93f2E7c0509967243E924D8a6bf94db6e
Expiry: 2027-12-18T00:00:00Z
```

## Usage

### Requirements

You will need to install:
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh)

### Quickstart

Clones this repository and builds contracts.

```shell
git clone https://github.com/xcoin-labs/xcoin-contracts
cd xcoin-contracts
forge build
```

### Clean Build

Reinstalls dependencies and rebuilds artifacts.

```shell
make
```

### Test

Runs all tests in [test](./test).

```shell
forge test
```

### Coverage

Estimates test coverage.

```shell
forge coverage
```

### Local Node

Starts a local development node.
```shell
anvil
```

### Deploy

Deploys contracts using [script/Deploy.s.sol](./script/Deploy.s.sol).
Set `RPC_URL`, `PRIVATE_KEY` and `ETHERSCAN_API_KEY` in the environment before running this command.

```shell
make deploy
```

### Deploy2

Deploys Distribution2 contract using [script/Deploy2.s.sol](./script/Deploy2.s.sol).
Set `RPC_URL`, `PRIVATE_KEY`, `ETHERSCAN_API_KEY`, `DEPLOY2_XCOIN_ADDRESS` and `DEPLOY2_EXPIRY` in the environment before running this command.

```shell
make deploy2
```

