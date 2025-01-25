// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenVestingContract
 * @author Esteban Pintos
 * @notice Contract that allows a payer to create a vesting agreement with a user. The payer deposits ERC20 tokens that
 * can be withdraw by the user with a specific rate.
 */
contract TokenVestingContract {
    // ERRORS
    error TokenVestingContract__AmountCannotBeZero();
    error TokenVestingContract__UserAlreadyHasAgreement();
    error TokenVestingContract__DepositTransferFailed();

    // STORE VARIABLES
    mapping(address payer => mapping(address user => VestingAgreement agreement)) public s_vestingAgreements;

    // TYPES
    struct VestingAgreement {
        uint256 initialTotalTokens;
        uint256 tokensLeftToWithdraw;
        uint256 lastWithdraw;
        uint256 withdrawRate; // User can only withdraw 1/withdrawRate tokens over the course of withdrawRate days.
        address token;
    }

    // EVENTS
    event Deposit(address indexed payer, address indexed user, uint256 amount, uint256 withdrawRate);

    modifier notZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert TokenVestingContract__AmountCannotBeZero();
        }
        _;
    }

    /**
     * @notice Deposit ERC20 tokens to create a vesting agreement with a user.
     * @notice The payer and the user can have only one agreement at a time
     * @param token ERC20 token address
     * @param to User address
     * @param amount Amount of tokens to deposit
     * @param withdrawRate Amount of tokens that can be withdrawn per day
     * @dev The user must approve the contract to spend the tokens before calling this function.
     */
    function deposit(address token, address to, uint256 amount, uint256 withdrawRate) external notZeroAmount(amount) {
        if (s_vestingAgreements[msg.sender][to].token != address(0)) {
            revert TokenVestingContract__UserAlreadyHasAgreement();
        }
        s_vestingAgreements[msg.sender][to] = VestingAgreement({
            initialTotalTokens: amount,
            tokensLeftToWithdraw: amount,
            lastWithdraw: block.timestamp,
            withdrawRate: withdrawRate,
            token: token
        });
        (bool success) = ERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TokenVestingContract__DepositTransferFailed();
        }
        emit Deposit(msg.sender, to, amount, withdrawRate);
    }

    /**
     * @notice Withdraw tokens if an agreement between the user and a payer exists.
     * @param from Payer address
     * @param token ERC20 token address
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(address from, address token, uint256 amount) external notZeroAmount(amount) {
        // Check if the user has an agreement with amount left
        // Check amount it can be withdrawn
        // Transfer tokens to the user
        // If no amount left, delete the agreement
        // emit event
    }

    function getAgreement(address payer, address user) external view returns (VestingAgreement memory) {
        return s_vestingAgreements[payer][user];
    }
}
