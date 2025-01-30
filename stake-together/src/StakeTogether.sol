// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console2 } from "forge-std/Script.sol";

/**
 * @title StakeTogether
 * @author Esteban Pintos
 * @notice A contract to stake an ERC20 token and earn rewards.
 * @notice The owner of the contract can start a staking period, set the rewards portion and the duration of the staking
 * period.
 * @notice Users can stake an ERC20 before the staking period begins and unstake it after the staking period ends.
 * @notice Rewards will start counting when the staking period starts.
 */
contract StakeTogether is Ownable {
    /// ERRORS
    error StakeTogether__EndDateCannotBeBeforeBeginDate();
    error StakeTogether__BeginDateCannotBeInThePast();
    error StakeTogether__NoTokensForRewards();

    /// TYPE DECLARATIONS
    struct Staking {
        bool active;
        uint256 amount;
        uint256 beginDateTimestamp;
        uint256 endDateTimestamp;
        uint256 rewardsPortion;
        uint256 initialSupply;
    }

    /// STATE VARIABLES
    IERC20 private immutable i_erc20Token;
    Staking private s_staking;
    mapping(address user => uint256 amount) private s_stakedAmounts;

    /// EVENTS
    event StakingBeginDateSet(
        address indexed owner, uint256 beginDateTimestamp, uint256 endDateTimestamp, uint256 rewardsPortion
    );

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
     * @param rewardsPortion The portion of the rewards that will be distributed among the stakers.
     */
    function setUpStaking(
        uint256 beginDateTimestamp,
        uint256 endDateTimestamp,
        uint256 rewardsPortion
    )
        external
        onlyOwner
    {
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
            rewardsPortion: rewardsPortion,
            initialSupply: initialSupply
        });
        emit StakingBeginDateSet(msg.sender, beginDateTimestamp, endDateTimestamp, rewardsPortion);
    }

    /**
     * @notice Stakes an amount of ERC20 tokens.
     * @notice User can stake an amount of ERC20 tokens before the staking period begins, but rewards will start
     * counting
     * when the staking period starts.
     * @param amount The amount of ERC20 tokens to stake.
     */
    function stake(uint256 amount) external { }

    /**
     * @notice Unstakes all the amount of ERC20 tokens that the user has staked with the rewards.
     * @notice User can unstake the amount of ERC20 tokens after the staking period ends.
     */
    function unstake() external { }

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
    function getStakingAmount(address user) external view returns (uint256) {
        return s_stakedAmounts[user];
    }

    // /**
    //  * @notice Returns the current rewards of the user.
    //  * @param user The address of the user.
    //  */
    // function getCurrentRewards(address user) external view returns (uint256) {
    //     return 0; // TODO
    // }
}
