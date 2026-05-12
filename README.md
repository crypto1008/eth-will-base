# ETH Will Contract on Base

A smart contract that lets you lock ETH and assign beneficiaries 
who can claim their share after a set date or inactivity period.

## Contract Address
0x1e3Adbf935D0c386Ee63b21528eB19Df9610694B

## View on Basescan
https://basescan.org/address/0x1e3Adbf935D0c386Ee63b21528eB19Df9610694B

## Features
- Lock ETH for beneficiaries
- Set unlock date up to 1 year
- Dead mans switch via check-in system
- Cancel and reclaim ETH anytime
- Multiple beneficiaries with custom share percentages

## Built With
- Solidity 0.8.20
- Hardhat
- OpenZeppelin
- Base Mainnet

## Setup
npm install
npx hardhat compile
npx hardhat test

## Deploy
npx hardhat run scripts/deploy.js --network base
