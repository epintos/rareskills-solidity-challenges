// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console2 } from "forge-std/Script.sol";

/**
 * @title StakeTogether
 * @author Esteban Pintos
 * @notice A contract to stake an ERC20 token and earn rewards.
 * @notice The owner of the contract can start a staking period and set the the duration.
 * @notice Users can stake an ERC20 token before the staking period begins until 24 hours after it starts.
 * @notice Users can unstake the ERC20 token at any times but they only get rewards if they lock their tokens at least
 * one day after the staking period ends.
 * @notice Rewards will start counting when the staking period starts.
 */
contract StakeTogether is Ownable {
    /// ERRORS
    error StakeTogether__EndDateCannotBeBeforeBeginDate();
    error StakeTogether__BeginDateCannotBeInThePast();
    error StakeTogether__NoTokensForRewards();
    error StakeTogether__StakingNotActive();
    error StakeTogether__StakingPeriodEnded();
    error StakeTogether__StakingPeriodAlreadyStarted();

    /// TYPE DECLARATIONS
    struct Staking {
        bool active;
        uint256 amount;
        uint256 beginDateTimestamp;
        uint256 endDateTimestamp;
        uint256 initialSupply;
    }

    /// STATE VARIABLES
    IERC20 private immutable i_erc20Token;
    Staking private s_staking;
    mapping(address user => uint256 amount) private s_stakedAmounts;
    uint256 private constant PRECISION = 1e18;

    /// EVENTS
    event StakingBeginDateSet(address indexed owner, uint256 beginDateTimestamp, uint256 endDateTimestamp);
    event Staked(address indexed user, uint256 amount);
    event UnStaked(address indexed user, uint256 amount, uint256 rewards);

    /// FUNCTIONS

    // CONSTRUCTOR
    constructor(address erc20Token) Ownable(msg.sender) {
        i_erc20Token = IERC20(erc20Token);
    }

    // EXTERNAL FUNCTIONS
    /**
     * @notice Sets the begin date of the staking period, the duration of the staking period and the rewards portion.
     * @notice Only the owner of the contract can call this function.
     * @param beginDateTimestamp The timestamp of the begin date of the staking period.
     * @param endDateTimestamp The timestamp of the end date of the staking period.
     */
    function setUpStaking(uint256 beginDateTimestamp, uint256 endDateTimestamp) external onlyOwner {
        if (beginDateTimestamp >= endDateTimestamp) {
            revert StakeTogether__EndDateCannotBeBeforeBeginDate();
        }

        if (beginDateTimestamp <= block.timestamp) {
            revert StakeTogether__BeginDateCannotBeInThePast();
        }
        uint256 initialSupply = i_erc20Token.balanceOf(address(this));

        if (initialSupply == 0) {
            revert StakeTogether__NoTokensForRewards();
        }
        s_staking = Staking({
            active: true,
            amount: 0,
            beginDateTimestamp: beginDateTimestamp,
            endDateTimestamp: endDateTimestamp,
            initialSupply: initialSupply
        });
        emit StakingBeginDateSet(msg.sender, beginDateTimestamp, endDateTimestamp);
    }

    /**
     * @notice Stakes an amount of ERC20 tokens.
     * @notice User can stake an amount of ERC20 tokens before the staking period begins until 24 hours after it starts,
     * but rewards will start counting when the staking period starts.
     * @param amount The amount of ERC20 tokens to stake.
     */
    function stake(uint256 amount) external {
        if (!s_staking.active) {
            revert StakeTogether__StakingNotActive();
        }

        // They can stake on the same date of the beginning and ending
        if (
            block.timestamp > s_staking.beginDateTimestamp
                && (block.timestamp - s_staking.beginDateTimestamp) / 1 days >= 1
                && block.timestamp < s_staking.endDateTimestamp
        ) {
            revert StakeTogether__StakingPeriodAlreadyStarted();
        }
        if (
            block.timestamp > s_staking.endDateTimestamp && (block.timestamp - s_staking.endDateTimestamp) / 1 days >= 1
        ) {
            revert StakeTogether__StakingPeriodEnded();
        }

        s_stakedAmounts[msg.sender] += amount;
        s_staking.amount += amount;
        i_erc20Token.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Unstakes all the amount of ERC20 tokens that the user has staked with the rewards.
     * @notice User can unstake the amount of ERC20 tokens after the staking period ends.
     */
    function unstake() external {
        if (!s_staking.active) {
            revert StakeTogether__StakingNotActive();
        }

        uint256 amount = s_stakedAmounts[msg.sender];
        uint256 rewards = 0;

        if ((block.timestamp - s_staking.endDateTimestamp) / 1 days >= 1) {
            rewards = _calculateRewards(msg.sender);
        }

        i_erc20Token.transfer(msg.sender, amount + rewards);
        s_stakedAmounts[msg.sender] = 0;
        emit UnStaked(msg.sender, amount, rewards);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Calculates the staking rewards of the user.
     * @param user The address of the user.
     */
    function _calculateRewards(address user) internal view returns (uint256 rewards) {
        if (s_staking.amount == 0) {
            return 0;
        }
        // Alice staked 5_000
        // Total staking is 25_000
        // Initial Supply is 1_000_000
        // Alice's Rewards Portion is 20% (0.2e18)
        // Rewards = 0.2e18 * 1_000_000 / 1e18 = 200_000
        uint256 userPortion = (s_stakedAmounts[user] * PRECISION) / s_staking.amount; // 20% as 0.2e18
        rewards = (userPortion * s_staking.initialSupply) / PRECISION; // 200_000
    }

    // EXTERNAL VIEW FUNCTIONS

    /**
     * @notice Returns the ERC20 token address.
     */
    function getERC20TokenAddress() external view returns (address) {
        return address(i_erc20Token);
    }

    /**
     * @notice Returns the staking information.
     */
    function getStaking() external view returns (Staking memory) {
        return s_staking;
    }

    /**
     * @notice Returns the amount of ERC20 tokens that the user has staked.
     * @param user The address of the user.
     */
    function getUserStakingAmount(address user) external view returns (uint256) {
        return s_stakedAmounts[user];
    }

    /**
     * @notice Returns the current rewards of the user.
     * @notice Rewards can change if users withdraw tokens before the staking period ends.
     * @param user The address of the user.
     */
    function getCurrentRewards(address user) external view returns (uint256) {
        return _calculateRewards(user);
    }
}
