# Smart Contracts Design

- [Smart Contracts Design](#smart-contracts-design)
  - [User Roles](#user-roles)
  - [Transaction types](#transaction-types)
    - [`Reward Allocation` by `Provider`](#reward-allocation-by-provider)
    - [`Deposit Flex` by `Staker`](#deposit-flex-by-staker)
    - [`Deposit Fix` by `Staker`](#deposit-fix-by-staker)
    - [`Withdraw` by `Staker`](#withdraw-by-staker)
    - [`Reward Withdrawal` by `Provider`](#reward-withdrawal-by-provider)
  - [UTxO types](#utxo-types)
  - [Validators](#validators)
    - [`Spend`](#spend)
  - [Proposed design specifics](#proposed-design-specifics)
    - [Flexible-period deposits](#flexible-period-deposits)
    - [Fixed-period deposits](#fixed-period-deposits)


## User Roles

In KUBE Staking Program, there are two main parties involved:

1. `Provider`: **Rewards Provider** - The entity responsible for managing and distributing the rewards to the participants of the staking program.
2. `Staker`: **Stakers (Participants)** - The users who stake their KUBE tokens in the different tiers to earn rewards.

## Transaction types

- `Reward Allocation` by `Provider`. The sequence begins with allocating rewards by Provider. Then stakers could see the allocated amount in Bank UTxOs and make a deposits, expecting to get an interest at the end.
- Deposit by `Staker`:
   - `Deposit Flex` - Make a deposit using flexible locking period. Interest could be received at withdrawal stage ([see details](#flex-spec))
   - `Deposit Fix` - Make a deposit using fixed locking period. Interest will be locked immediately at replenishment stage and guaranteed to return after deposit period. 
- `Withdraw` by `Staker`
- `Reward Withdrawal` by `Provider`. Provider are allowed to return funds back from reward UTxO(s) at any time ([see details](#flex-spec)).


### `Reward Allocation` by `Provider`

- Inputs
  - Provider UTxO: Tokens
- Outputs
  - `Bank UTxO` locked with `Spend`
    - Datum
      - Owner: Provider address
  - Change: Provider UTxO

### `Deposit Flex` by `Staker`

- Inputs
  - Staker UTxO: Tokens
- Outputs
  - `Deposit UTxO` locked with `Spend`
    - Assets
      - Tokens
    - Datum
      - Deposit start
  - Change: Staker UTxO


### `Deposit Fix` by `Staker`

- Inputs
  - Staker UTxO: Tokens
  - `Bank UTxO`: Tokens. Locked by `Spend`.
- Outputs
  - `Deposit UTxO` locked by `Spend ToDo`
    - Assets
      - Tokens
    - Datum
      - Deposit start
      - Deposit end
  - Change: Staker UTxO
  - Change: `Bank UTxO`


### `Withdraw` by `Staker`

Withdraw flexible-period deposit:

- Inputs
  - `Deposit UTxO`
  - `Bank UTxO` (interest tokens)
    - Redeemer: Withdrawal date
- Outputs
  - Staker: Tokens
  - [opt] `Bank UTxO`

Withdraw fixed-period deposit:

- Inputs
  - `Deposit UTxO`
    - Redeemer: Withdrawal date
- Outputs
  - Staker: Tokens
  - [opt] `Bank UTxO`

**Notes**:
- To unlock `Deposit UTxO` a "Withdrawal date" redeemer provided.
- `Bank UTxO` output should be added in case of penalties for early withdrawal. Otherwise staker gets all tokens from `Deposit UTxO`.


### `Reward Withdrawal` by `Provider`

- Inputs
  - `Bank UTxO`
- Outputs
  - Provider UTxO
  - Change: `Bank UTxO` (optional, in case of partial withdrawal)

## UTxO types

- `Bank UTxO` locked by `Spend`
- `Deposit UTxO` locked by `Spend`


## Validators

### `Spend`

Spend validator controls spending of `Bank UTxO` and `Deposit UTxO`.


## Proposed design specifics

### Flexible-period deposits<a name="flex-spec"></a>

Because of the following two facts:
- Provider allowed to return funds back from `Bank UTxO`s at any time
- Interest on flexible-period deposits is received at the **withdrawal stage** (and not immediately at the replenishment stage, as it happens with fixed-period deposits).

it makes possible a case when:
- There are funds in `Bank UTxO` and a stakers made flexible-period deposits
- But after some time, Provider decides to withdraw rewards pool back. 
- Stakers decides to withdraw their flexible-period deposits. But since there are no funds for rewards available, they can only get their deposit amount back without any interest. 

### Fixed-period deposits<a name="fix-spec"></a>

When making a deposit for a fixed period, the interest on the deposit is transferred to deposit UTxO immediately at the moment of making a deposit and is blocked there until the withdraw. With this logic, stakers will see the amount **really available** for rewards in `Bank UTxO` **at any time**.