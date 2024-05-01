// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./abstract.sol";

contract TokenLock is Ownable, ReentrancyGuard, Locking20{
    using SafeERC20 for IERC20;

    uint256 private contractTokenBalance;
    address oracle;


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

    modifier onlyOracle() {
        if (msg.sender != oracle) {
            revert OwnableUnauthorized();
        }
        _;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    /**
     *  @notice    Lock ERC20 Tokens.
     *
     *  @dev       See {_lock}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to lock.
     */
    function lock(uint256 _amount) external payable nonReentrant {
        _lock(_amount);
    }

    /**
     *  @notice    Unlock locked ERC20 tokens.
     *
     *  @dev       See {_unlock}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to unlock.
     */
    function unlock(uint256 _amount) external nonReentrant onlyOracle {
        _unlock(_amount);
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
