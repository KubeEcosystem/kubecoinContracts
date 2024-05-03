# Staking20Base Contract

This is a Solidity smart contract for a staking platform . The contract is built using OpenZeppelin's contract library and is licensed under the Apache-2.0 License.

## Contract Details

Staking20Base is an ERC20 staking contract that allows users to stake their tokens and earn rewards in the form of another ERC20 token. The contract is an extension of the `ContractMetadata`, `Multicall`, `Ownable`, and `Staking20` contracts from OpenZeppelin.

### Constructor

The constructor takes the following arguments:

- `_timeUnit`: the time unit for staking
- `_defaultAdmin`: the default admin address
- `_rewardRatioNumerator`: the numerator of the reward ratio
- `_rewardRatioDenominator`: the denominator of the reward ratio
- `_stakingToken`: the address of the staking token
- `_rewardToken`: the address of the reward token
- `_nativeTokenWrapper`: the address of the native token wrapper

The constructor sets the `rewardToken` address, sets up the owner, sets the staking condition, and checks that the reward token and staking token are not the same.

### Receive Function

The `receive` function allows the contract to receive ether to unwrap native tokens. It requires that the caller is the native token wrapper.

### Deposit and Withdraw Reward Tokens

The `depositRewardTokens` and `withdrawRewardTokens` functions allow the admin to deposit and withdraw excess reward tokens, respectively. These functions can be overridden for custom logic.

### Get Reward Token Balance

The `getRewardTokenBalance` function returns the total amount of reward tokens available in the staking contract.

### Mint Rewards

The `_mintRewards` function mints ERC20 rewards to the staker. It requires that there are enough reward tokens, deducts the rewards from the reward token balance, and transfers the rewards to the staker. This function can be overridden for custom logic.

### Other Internal Functions

The `_depositRewardTokens` and `_withdrawRewardTokens` functions are internal versions of the `depositRewardTokens` and `withdrawRewardTokens` functions, respectively. These functions include additional logic to handle the transfer of tokens and updates to the reward token balance.

The `_canSetStakeConditions`, `_canSetContractURI`, and `_canSetOwner` functions return whether the caller is authorized to set staking conditions, contract metadata, and the owner, respectively. These functions can be overridden for custom logic.

## Dependencies

This contract depends on the following OpenZeppelin contracts:

- ContractMetadata
- Multicall
- Ownable
- Staking20

It also depends on the `CurrencyTransferLib` library.
