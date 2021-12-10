## Interface for Single Pool AMM

Front-end interface for a single pool AMM (given pre-defined tokens which are public on Ethereum Rinkeby testnet). This interface allows you to connect with your metamask wallet to receive free testnet tokens and then trade them in a simple constant product pool. 

You are also able to deposit liquidity (in the form of the Euler and Gauss tokens) and receive LP tokens that represents your share of the total pool. You are then able to withdraw your liquidity at any point by redeeming (burning) your LP tokens and receiving your share of the liquidity pool.

### To do
- Pool.js: 
  - View pool balance
  - View LP balance
  - View LP entitlement
  - View circulating LP
  - Deposit to pool
  - Approval to spend LP
  - Withdraw from pool
- Trade.js
  - Approval to spend A
  - Swap A to B (and see price)
  - Approval to spend B
  - Swap B to A (and see price)