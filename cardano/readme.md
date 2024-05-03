Staking Smart Contract for Token a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be
========================================================================================================================

This repository contains the Plutus smart contract code for staking the token with the asset ID `a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be`. The contract allows users to stake their tokens and earn rewards based on the chosen staking tier.

Table of Contents
-----------------

* [Contract Overview](#contract-overview)
* [Staking Tiers](#staking-tiers)
* [Validator](#validator)
* [State Machine](#state-machine)
* [Contract Endpoints](#contract-endpoints)
* [Starting the Contract](#starting-the-contract)

Contract Overview
-----------------

The staking contract is implemented using the Plutus smart contract language and follows a state machine design pattern. The contract supports staking, unstaking, and reward distribution operations.

The contract defines the following data types:

* `StakingContract`: The main data type representing the staking contract, containing information such as the owner, token asset, staking tier, stake amount, lock period, withdrawal fee, penalty rate, and active status.
* `StakeTier`: An enumeration representing the different staking tiers available (Explorer, Voyager, Believer).
* `StakeTransition`: An enumeration representing the possible state transitions for the staking contract (Stake, Withdraw).

### Staking Tiers

The contract supports three staking tiers:

1. Explorer: No specific limits.
2. Voyager: The staked amount must not exceed 5% of the total token supply.
3. Believer: The staked amount must not exceed 1,000,000 tokens.

Validator
---------

The validator function `validateStakingContract` ensures that the staking and unstaking operations are performed according to the contract rules. It checks the following conditions:

* The owner of the staking contract must be the one signing the transaction.
* The staked amount must be positive.
* The lock period must be in the future.
* The staking tier must match the contract tier.
* The stake must be made with the correct token.

State Machine
-------------

The contract uses a state machine to manage the different states of the staking process. The `stakeMachine` function initializes the state machine, and the `stakingMachineInstance` variable contains the state machine instance.

### Contract Endpoints

The contract exposes the following endpoints:

* `stake`: Allows users to stake their tokens by providing the staking contract and the desired slot.
* `withdraw`: Allows users to unstake their tokens and claim their rewards.

Starting the Contract
---------------------

To start the staking contract, use the `startStakingContract` function, which initializes the contract instance with the provided `StakingContract` data.

```haskell
startStakingContract :: StakingContract -> Contract () SMContractError (SMContractInstance StakingContractSchema StakingContract)
```

Default Instances
-----------------

The repository includes default instances for known currencies and schema definitions.

```haskell
$(mkKnownCurrencies [])
$(mkSchemaDefinitions ''StakingContractSchema)
```
