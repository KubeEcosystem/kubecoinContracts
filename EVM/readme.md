# KubeCoin Contract

This is a Solidity smart contract for a token called KubeCoin. The contract is built using OpenZeppelin's contract library and is compatible with OpenZeppelin Contracts version 5.0.0 and later.

## License

This contract is licensed under the MIT License.

## Contract Details

KubeCoin is an ERC20 token that also implements the ERC20Burnable, ERC20Pausable, AccessControl, and ERC20Permit extensions from OpenZeppelin. This means that the token can be burned, its transfer can be paused, and it has access control and permit functionality.

### Constructor

The constructor takes two arguments: `defaultAdmin` and `pauser`. The `defaultAdmin` is granted the default admin role, and the `pauser` is granted the `PAUSER_ROLE`, which is a custom role defined in the contract. The contract also mints 480,000,000 KubeCoin tokens and assigns them to the contract deployer.

### Pause and Unpause Functionality

The `pause` and `unpause` functions allow the contract to be paused and unpaused, respectively. These functions can only be called by an account that has the `PAUSER_ROLE`.

### Update Function

The `_update` function is an internal function that is called whenever the contract's state is updated. This function is an override of the `_update` function in the ERC20 and ERC20Pausable contracts.

## Dependencies

This contract depends on the following OpenZeppelin contracts:

- ERC20
- ERC20Burnable
- ERC20Pausable
- AccessControl
- ERC20Permit

These contracts are imported from the `@openzeppelin/contracts@5.0.2` package.

## Prerequisites

Solidity version 0.8.20 or later
