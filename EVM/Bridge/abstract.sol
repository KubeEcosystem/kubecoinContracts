// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface.sol";
import "./library.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @dev The sender is not authorized to perform the action
    error ContractMetadataUnauthorized();

    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert ContractMetadataUnauthorized();
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
contract Multicall is IMulticall {
    /**
     *  @notice Receives and executes a batch of function calls on this contract.
     *  @dev Receives and executes a batch of function calls on this contract.
     *
     *  @param data The bytes data that makes up the batch of function calls to execute.
     *  @return results The bytes data that makes up the result of the batch of function calls executed.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        address sender = _msgSender();
        bool isForwarder = msg.sender != sender;
        for (uint256 i = 0; i < data.length; i++) {
            if (isForwarder) {
                results[i] = Address.functionDelegateCall(address(this), abi.encodePacked(data[i], sender));
            } else {
                results[i] = Address.functionDelegateCall(address(this), data[i]);
            }
        }
        return results;
    }

    /// @notice Returns the sender in the given execution context.
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev The sender is not authorized to perform the action
    error OwnableUnauthorized();

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OwnableUnauthorized();
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert OwnableUnauthorized();
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Staking20 is ReentrancyGuard, IStaking20 {
    /*///////////////////////////////////////////////////////////////
                            State variables / Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the native token wrapper contract.
    address internal immutable nativeTokenWrapper;

    ///@dev Address of ERC20 contract -- staked tokens belong to this contract.
    address public immutable stakingToken;

    /// @dev Decimals of staking token.
    uint16 public immutable stakingTokenDecimals;

    /// @dev Decimals of reward token.
    uint16 public immutable rewardTokenDecimals;

    ///@dev Next staking condition Id. Tracks number of conditon updates so far.
    uint64 private nextConditionId;

    /// @dev Total amount of tokens staked in the contract.
    uint256 public stakingTokenBalance;

    /// @dev List of accounts that have staked that token-id.
    address[] public stakersArray;

    ///@dev Mapping staker address to Staker struct. See {struct IStaking20.Staker}.
    mapping(address => Staker) public stakers;

    ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
    mapping(uint256 => StakingCondition) private stakingConditions;

    constructor(
        address _nativeTokenWrapper,
        address _stakingToken,
        uint16 _stakingTokenDecimals,
        uint16 _rewardTokenDecimals
    ) ReentrancyGuard() {
        require(_stakingToken != address(0) && _nativeTokenWrapper != address(0), "address 0");
        require(_stakingTokenDecimals != 0 && _rewardTokenDecimals != 0, "decimals 0");

        nativeTokenWrapper = _nativeTokenWrapper;
        stakingToken = _stakingToken;
        stakingTokenDecimals = _stakingTokenDecimals;
        rewardTokenDecimals = _rewardTokenDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC20 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to stake.
     */
    function stake(uint256 _amount) external payable nonReentrant {
        _stake(_amount);
    }

    /**
     *  @notice    Withdraw staked ERC20 tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to withdraw.
     */
    function withdraw(uint256 _amount) external nonReentrant {
        _withdraw(_amount);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     */
    function claimRewards() external nonReentrant {
        _claimRewards();
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint80 _timeUnit) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        StakingCondition memory condition = stakingConditions[nextConditionId - 1];
        require(_timeUnit != condition.timeUnit, "Time-unit unchanged.");

        _setStakingCondition(_timeUnit, condition.rewardRatioNumerator, condition.rewardRatioDenominator);

        emit UpdatedTimeUnit(condition.timeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as (numerator/denominator) rewards per second/per day/etc based on time-unit.
     *
     *           For e.g., ratio of 1/20 would mean 1 reward token for every 20 tokens staked.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _numerator    Reward ratio numerator.
     *  @param _denominator  Reward ratio denominator.
     */
    function setRewardRatio(uint256 _numerator, uint256 _denominator) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        StakingCondition memory condition = stakingConditions[nextConditionId - 1];
        require(
            _numerator != condition.rewardRatioNumerator || _denominator != condition.rewardRatioDenominator,
            "Reward ratio unchanged."
        );
        _setStakingCondition(condition.timeUnit, _numerator, _denominator);

        emit UpdatedRewardRatio(
            condition.rewardRatioNumerator,
            _numerator,
            condition.rewardRatioDenominator,
            _denominator
        );
    }

    /**
     *  @notice View amount staked and rewards for a user.
     *
     *  @param _staker          Address for which to calculated rewards.
     *  @return _tokensStaked   Amount of tokens staked.
     *  @return _rewards        Available reward amount.
     */
    function getStakeInfo(address _staker) external view virtual returns (uint256 _tokensStaked, uint256 _rewards) {
        _tokensStaked = stakers[_staker].amountStaked;
        _rewards = _availableRewards(_staker);
    }

    function getTimeUnit() public view returns (uint256 _timeUnit) {
        _timeUnit = stakingConditions[nextConditionId - 1].timeUnit;
    }

    function getRewardRatio() public view returns (uint256 _numerator, uint256 _denominator) {
        _numerator = stakingConditions[nextConditionId - 1].rewardRatioNumerator;
        _denominator = stakingConditions[nextConditionId - 1].rewardRatioDenominator;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Staking logic. Override to add custom logic.
    function _stake(uint256 _amount) internal virtual {
        require(_amount != 0, "Staking 0 tokens");

        address _stakingToken;
        if (stakingToken == CurrencyTransferLib.NATIVE_TOKEN) {
            _stakingToken = nativeTokenWrapper;
        } else {
            require(msg.value == 0, "Value not 0");
            _stakingToken = stakingToken;
        }

        if (stakers[_stakeMsgSender()].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(_stakeMsgSender());
        } else {
            stakersArray.push(_stakeMsgSender());
            stakers[_stakeMsgSender()].timeOfLastUpdate = uint80(block.timestamp);
            stakers[_stakeMsgSender()].conditionIdOflastUpdate = nextConditionId - 1;
        }

        uint256 balanceBefore = IERC20(_stakingToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            stakingToken,
            _stakeMsgSender(),
            address(this),
            _amount,
            nativeTokenWrapper
        );
        uint256 actualAmount = IERC20(_stakingToken).balanceOf(address(this)) - balanceBefore;

        stakers[_stakeMsgSender()].amountStaked += actualAmount;
        stakingTokenBalance += actualAmount;

        emit TokensStaked(_stakeMsgSender(), actualAmount);
    }

    /// @dev Withdraw logic. Override to add custom logic.
    function _withdraw(uint256 _amount) internal virtual {
        uint256 _amountStaked = stakers[_stakeMsgSender()].amountStaked;
        require(_amount != 0, "Withdrawing 0 tokens");
        require(_amountStaked >= _amount, "Withdrawing more than staked");

        _updateUnclaimedRewardsForStaker(_stakeMsgSender());

        if (_amountStaked == _amount) {
            address[] memory _stakersArray = stakersArray;
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == _stakeMsgSender()) {
                    stakersArray[i] = _stakersArray[_stakersArray.length - 1];
                    stakersArray.pop();
                    break;
                }
            }
        }
        stakers[_stakeMsgSender()].amountStaked -= _amount;
        stakingTokenBalance -= _amount;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            stakingToken,
            address(this),
            _stakeMsgSender(),
            _amount,
            nativeTokenWrapper
        );

        emit TokensWithdrawn(_stakeMsgSender(), _amount);
    }

    /// @dev Logic for claiming rewards. Override to add custom logic.
    function _claimRewards() internal virtual {
        uint256 rewards = stakers[_stakeMsgSender()].unclaimedRewards + _calculateRewards(_stakeMsgSender());

        require(rewards != 0, "No rewards");

        stakers[_stakeMsgSender()].timeOfLastUpdate = uint80(block.timestamp);
        stakers[_stakeMsgSender()].unclaimedRewards = 0;
        stakers[_stakeMsgSender()].conditionIdOflastUpdate = nextConditionId - 1;

        _mintRewards(_stakeMsgSender(), rewards);

        emit RewardsClaimed(_stakeMsgSender(), rewards);
    }

    /// @dev View available rewards for a user.
    function _availableRewards(address _staker) internal view virtual returns (uint256 _rewards) {
        if (stakers[_staker].amountStaked == 0) {
            _rewards = stakers[_staker].unclaimedRewards;
        } else {
            _rewards = stakers[_staker].unclaimedRewards + _calculateRewards(_staker);
        }
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(address _staker) internal virtual {
        uint256 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = uint80(block.timestamp);
        stakers[_staker].conditionIdOflastUpdate = nextConditionId - 1;
    }

    /// @dev Set staking conditions.
    function _setStakingCondition(uint80 _timeUnit, uint256 _numerator, uint256 _denominator) internal virtual {
        require(_denominator != 0, "divide by 0");
        require(_timeUnit != 0, "time-unit can't be 0");
        uint256 conditionId = nextConditionId;
        nextConditionId += 1;

        stakingConditions[conditionId] = StakingCondition({
            timeUnit: _timeUnit,
            rewardRatioNumerator: _numerator,
            rewardRatioDenominator: _denominator,
            startTimestamp: uint80(block.timestamp),
            endTimestamp: 0
        });

        if (conditionId > 0) {
            stakingConditions[conditionId - 1].endTimestamp = uint80(block.timestamp);
        }
    }

    /// @dev Calculate rewards for a staker.
    function _calculateRewards(address _staker) internal view virtual returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];

        uint256 _stakerConditionId = staker.conditionIdOflastUpdate;
        uint256 _nextConditionId = nextConditionId;

        for (uint256 i = _stakerConditionId; i < _nextConditionId; i += 1) {
            StakingCondition memory condition = stakingConditions[i];

            uint256 startTime = i != _stakerConditionId ? condition.startTimestamp : staker.timeOfLastUpdate;
            uint256 endTime = condition.endTimestamp != 0 ? condition.endTimestamp : block.timestamp;

            (bool noOverflowProduct, uint256 rewardsProduct) = SafeMath.tryMul(
                (endTime - startTime) * staker.amountStaked,
                condition.rewardRatioNumerator
            );
            (bool noOverflowSum, uint256 rewardsSum) = SafeMath.tryAdd(
                _rewards,
                (rewardsProduct / condition.timeUnit) / condition.rewardRatioDenominator
            );

            _rewards = noOverflowProduct && noOverflowSum ? rewardsSum : _rewards;
        }

        (, _rewards) = SafeMath.tryMul(_rewards, 10 ** rewardTokenDecimals);

        _rewards /= (10 ** stakingTokenDecimals);
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender -- support ERC2771.
    function _stakeMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
        Virtual functions to be implemented in derived contract
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice View total rewards available in the staking contract.
     *
     */
    function getRewardTokenBalance() external view virtual returns (uint256 _rewardsAvailableInContract);

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     *  For example, override as below to mint ERC20 rewards:
     *
     * ```
     *  function _mintRewards(address _staker, uint256 _rewards) internal override {
     *
     *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
     *
     *  }
     * ```
     */
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;

    /**
     *  @dev    Returns whether staking restrictions can be set in given execution context.
     *          Must override.
     *
     *
     *  For example, override as below to restrict access to admin:
     *
     * ```
     *  function _canSetStakeConditions() internal override {
     *
     *      return msg.sender == adminAddress;
     *
     *  }
     * ```
     */
    function _canSetStakeConditions() internal view virtual returns (bool);
}

abstract contract Locking20 is ReentrancyGuard, ILocking20 {
    /*///////////////////////////////////////////////////////////////
                            Lock variables / Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the native token wrapper contract.
    address internal immutable nativeTokenWrapper;

    ///@dev Address of ERC20 contract -- locked tokens belong to this contract.
    address public immutable lockingToken;

    /// @dev Decimals of locking token.
    uint16 public immutable lockingTokenDecimals;

    /// @dev Total amount of tokens locked in the contract.
    uint256 public lockingTokenBalance;

    /// @dev List of accounts that have locked that token-id.
    address[] public usersArray;

    ///@dev Mapping user address to User struct. See {struct ILocking20.User}.
    mapping(address => User) public users;

    constructor(
        address _nativeTokenWrapper,
        address _lockingToken,
        uint16 _lockingTokenDecimals
    ) ReentrancyGuard() {
        require(_lockingToken != address(0) && _nativeTokenWrapper != address(0), "address 0");
        require(_lockingTokenDecimals != 0, "decimals 0");

        nativeTokenWrapper = _nativeTokenWrapper;
        lockingToken = _lockingToken;
        lockingTokenDecimals = _lockingTokenDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

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
    function unlock(uint256 _amount) external nonReentrant {
        _unlock(_amount);
    }

    /**
     *  @notice View amount staked and rewards for a user.
     *
     *  @param _user            Address of the lock.
     *  @return _tokensLocked   Amount of tokens locked.
     */
    function getLockInfo(address _user) external view virtual returns (uint256 _tokensLocked) {
        _tokensLocked = users[_user].amountLocked;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Locking logic. Override to add custom logic.
    function _lock(uint256 _amount) internal virtual {
        require(_amount != 0, "Locking 0 tokens");

        address _lockingToken;
        if (lockingToken == CurrencyTransferLib.NATIVE_TOKEN) {
            _lockingToken = nativeTokenWrapper;
        } else {
            require(msg.value == 0, "Value not 0");
            _lockingToken = lockingToken;
        }

        uint256 balanceBefore = IERC20(_lockingToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            lockingToken,
            _lockMsgSender(),
            address(this),
            _amount,
            nativeTokenWrapper
        );
        uint256 actualAmount = IERC20(_lockingToken).balanceOf(address(this)) - balanceBefore;

        users[_lockMsgSender()].amountLocked += actualAmount;
        lockingTokenBalance += actualAmount;

        emit TokensLocked(_lockMsgSender(), actualAmount);
    }

    /// @dev Withdraw logic. Override to add custom logic.
    function _unlock(uint256 _amount) internal virtual {
        uint256 _amountLocked = users[_lockMsgSender()].amountLocked;
        require(_amount != 0, "Withdrawing 0 tokens");
        require(_amountLocked >= _amount, "Withdrawing more than locked");

        if (_amountLocked == _amount) {
            address[] memory _usersArray = usersArray;
            for (uint256 i = 0; i < _usersArray.length; ++i) {
                if (_usersArray[i] == _lockMsgSender()) {
                    usersArray[i] = _usersArray[_usersArray.length - 1];
                    usersArray.pop();
                    break;
                }
            }
        }
        users[_lockMsgSender()].amountLocked -= _amount;
        lockingTokenBalance -= _amount;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            lockingToken,
            address(this),
            _lockMsgSender(),
            _amount,
            nativeTokenWrapper
        );

        emit TokensLocked(_lockMsgSender(), _amount);
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender -- support ERC2771.
    function _lockMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
        Virtual functions to be implemented in derived contract
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice View total tokens available in the locking contract.
     *
     */
    function getContractTokenBalance() external view virtual returns (uint256 _tokenAvailableInContract);
}
