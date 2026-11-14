# Ethernaut — Impersonator Two

Level: https://ethernaut.openzeppelin.com/level/0x4C20884aDF68C7102a1aeb94FCD973278dD6e9a4

## Description

The goal of this level is for you to steal all the funds from the contract.

Things that might help:

- Look carefully at the 2 signatures that the owner of the contract used to lock it and set the admin.

## Project layout

- [src/ImpersonatorTwo.sol](src/ImpersonatorTwo.sol) — level contract
- [src/ImpersonatorTwoFactory.sol](src/ImpersonatorTwoFactory.sol) — level factory (instance setup + win check)
- [src/base/Level.sol](src/base/Level.sol) — Ethernaut `Level` base contract
- [NOTES.md](NOTES.md) — recon notes

## Setup

Dependencies: `forge-std` and OpenZeppelin Contracts `v4.9.6`, remapped as `openzeppelin-contracts-08/` in [remappings.txt](remappings.txt).

```shell
forge install
forge build
forge test
```
