# CryptoTigers

Project setup taken from the excellent Solidity template by [paulrberg](https://github.com/PaulRBerg/solidity-template)

### Introduction

This project will give engineers a stronger working knowledge of web3. It involves developing a smart contract in Solidity and deploying it to a test network. We will be working with an NFT contract along the lines of CryptoPunks (see https://github.com/larvalabs/cryptopunks/blob/master/contracts/CryptoPunksMarket.sol).

### Prerequisites

This project is designed for experienced software engineers who are in the early stages of learning web3. You will be writing code in Solidity, but to get the most out of it you should already be very comfortable writing applications and tests in at least one other language. You should also have some prior knowledge of Solidity. Having previously completed the first CryptoZombies Solidity Path (https://cryptozombies.io/solidity) would be ideal. All the coding for the project is in Solidity, but the contract deployment and tests make use of JavaScript and NPM. Previous experience of these, or at least the ability to Google your way out of trouble, will help a lot.

### Setup

```
yarn install
npx hardhat compile
npx hardhat test
```

This project uses [husky](https://www.npmjs.com/package/husky) to setup git commit hooks, so that whenever you make a commit it will automatically format all js/ts/sol files. However, in order for this to work you must be using a version of node >=0.14.12.0 (see [this explanation](https://stackoverflow.com/questions/63317051/node9511-experimentalwarning-the-esm-module-loader-is-experimental)).

To install a newer version, install [nvm](https://github.com/nvm-sh/nvm#installing-and-updating) (which you should be using anyway!) and then install a sufficiently recent version of node.js, e.g.

`nvm install v16.13.0`


### Hardhat

Using a proper development environment like Hardhat is essential for web3 development. You can check out their quickstart guide to install it and learn how to test with it:

https://hardhat.org/tutorial/

### Quick tip!

When debugging contract code, HardHat's console logging facility becomes incredibly useful. At the top of the contract, after the line

```
pragma solidity 0.8.2;
```

- add the line

```
import "hardhat/console.sol";
```

- You can now add `console.log` calls on your contracts as follows:

```
console.log("artist address is %s, owner of token 0 address is %s", artist, tigerOwners[0]);
```

- This will print the output when you run your tests, making debugging a hundred times easier!

### Resources

- You will need to do your own research to complete the project. Some useful sources of information include
  - https://docs.soliditylang.org/
  - https://solidity-by-example.org/

### Tasks

1. Take a look at the provided file `contracts/TigerBasicNFT.sol`, which contains most of the implementation of a smart contract for trading in an imaginary Tiger NFT token. The contract keeps track of who owns each token. It also tracks which Tiger tokens are currently for sale and allows participants to buy them with suitable offers. All payments are in Ether. The first task is to extend this contract to provide some missing functionality:
   - The contract holds all the Ether it receives from the sale of Tiger tokens. This Ether is held on behalf of the sellers and the contract keeps a record of how much is held on behalf of each seller address in the field `pendingWithdrawals`. `pendingWithdrawals` maps addresses to the amount of Ether held for each address. However as the contract stands there is no way for the owner of an address to transfer their Ether out of the Tiger NFT contract.
     - Add a `withdrawFunds` function which allows users to claim the Ether held on their behalf by moving it from the contract's address to their own address.
     - Extend the provided test file `tests/TigerBasicNFT.js` to add tests for your new code
   - We would like the artist to receive a royalty payment of 5% on each resale of the tokens.
     - Extend the contract to automatically deduct a 5% artist's fee from all token sales and make this available to the artist via the `withdrawFunds` function.
     - Extend the tests to cover this
   - The contract should also take a 1% fee for itself.
     - Extend the contract to automatically deduct a 1% service fee from all token sales and make this available for transfer to the adddress from which the contract was deployed. Movement of these fees to the contract deployer's address should also be performed via the `withdrawFunds` function.
     - Extend the tests to cover this
2. Once you have completed the project you will be provided with the file `contracts/TigerNFT.sol` which implements all the previously listed requirements.

### Acknowledgements

The contracts are based on the original CryptoPunks:

- https://github.com/larvalabs/cryptopunks/blob/master/contracts/CryptoPunksMarket.sol

They also incorporate some ideas and code from the OpenZeppelin ERC721Enumerable contract:

- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol
- https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#ERC721Enumerable
