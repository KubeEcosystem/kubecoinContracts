
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./abstract.sol";

contract TokenLock is Ownable, ReentrancyGuard, Locking20{
    using SafeERC20 for IERC20;
    /// @dev Total amount of reward tokens in the contract.
    uint256 private contractTokenBalance;


    mapping(address => uint256) public lockedBalances;

    constructor(
        address nativeTokenWrapper,
        address lockingToken,
        uint16 lockingTokenDecimals,
        address _defaultAdmin
        ) 
            Locking20(nativeTokenWrapper, lockingToken, lockingTokenDecimals)
        {    
        _setupOwner(_defaultAdmin);
    }

    /// @notice View total rewards available in the staking contract.
    function getContractTokenBalance() external view virtual override returns (uint256) {
        return contractTokenBalance;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
