// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenVestingContract
 * @author Esteban Pintos
 * @notice Contract that allows a payer to create a vesting agreement with a user. The payer deposits a ERC20 token that
 * can be withdrawn by the user.
 * @notice The payer specifies when all the tokens can be withdrawn by the user and the user can withdraw the vested
 * tokens every day as long as there is at least 1 Wei to withdraw.
 * @notice Contract supports only one agreement per payer and user.
 */
contract TokenVestingContract {
    // ERRORS
    error TokenVestingContract__AmountCannotBeZero();
    error TokenVestingContract__UserAlreadyHasAgreement();
    error TokenVestingContract__TransferFailed();
    error TokenVestingContract__AddressCanotBeZero();
    error TokenVestingContract__UserDoesNotHaveAgreement();
    error TokenVestingContract__NotEnoughtTimeHasPassedToWithdraw();

    // STORE VARIABLES
    mapping(address payer => mapping(address user => VestingAgreement agreement)) public s_vestingAgreements;

    // TYPES
    struct VestingAgreement {
        uint256 initialTotalTokensInWei;
        uint256 tokensWithdrawnInWei;
        uint256 startTimestamp;
        uint256 vestingDays; // Days that need to pass to withdraw all the tokens
        address token;
    }

    // EVENTS
    event Deposit(address indexed payer, address indexed user, uint256 amountDeposited, uint256 withdrawRate);
    event Withdraw(address indexed payer, address indexed user, uint256 amountWithdraw, uint256 tokensLeftToWithdraw);

    modifier notZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert TokenVestingContract__AmountCannotBeZero();
        }
        _;
    }

    modifier tokenAddressCannotBeZero(address token) {
        if (token == address(0)) {
            revert TokenVestingContract__AddressCanotBeZero();
        }
        _;
    }

    /**
     * @notice Deposit ERC20 token to create a vesting agreement with a user.
     * @notice The payer and the user can have only one agreement at a time
     * @param token ERC20 token address
     * @param to User address
     * @param amountInWei Amount of tokens to deposit
     * @param vestingDays Days that need to pass to withdraw all the tokens
     * @dev The user must approve the contract to spend the tokens before calling this function.
     */
    function deposit(
        address token,
        address to,
        uint256 amountInWei,
        uint256 vestingDays
    )
        external
        notZeroAmount(amountInWei)
        tokenAddressCannotBeZero(token)
    {
        if (s_vestingAgreements[msg.sender][to].token != address(0)) {
            revert TokenVestingContract__UserAlreadyHasAgreement();
        }
        s_vestingAgreements[msg.sender][to] = VestingAgreement({
            initialTotalTokensInWei: amountInWei,
            tokensWithdrawnInWei: 0,
            startTimestamp: block.timestamp,
            vestingDays: vestingDays,
            token: token
        });
        emit Deposit(msg.sender, to, amountInWei, vestingDays);
        (bool success) = ERC20(token).transferFrom(msg.sender, address(this), amountInWei);
        if (!success) {
            revert TokenVestingContract__TransferFailed();
        }
    }

    /**
     * @notice Withdraw vested tokens if an agreement between the user and a payer exists.
     * @notice If all the tokens are withdrawn, the agreement is deleted.
     * @notice Will revert if not enought time has passed to withdraw at least one Wei in tokens.
     * @param payer Payer address
     */
    function withdraw(address payer) external {
        VestingAgreement memory agreement = s_vestingAgreements[payer][msg.sender];
        if (agreement.token == address(0)) {
            revert TokenVestingContract__UserDoesNotHaveAgreement();
        }

        uint256 tokensToWithdraw = _calculateTokensToWithdraw(agreement);

        if (tokensToWithdraw == 0) {
            revert TokenVestingContract__NotEnoughtTimeHasPassedToWithdraw();
        }

        uint256 tokensLeftToWithdraw = agreement.initialTotalTokensInWei - tokensToWithdraw;
        if (tokensLeftToWithdraw == 0) {
            delete s_vestingAgreements[payer][msg.sender];
        } else {
            s_vestingAgreements[payer][msg.sender].tokensWithdrawnInWei = tokensToWithdraw;
        }

        emit Withdraw(payer, msg.sender, tokensToWithdraw, tokensLeftToWithdraw);
        (bool success) = ERC20(agreement.token).transfer(msg.sender, tokensToWithdraw);
        if (!success) {
            revert TokenVestingContract__TransferFailed();
        }
    }

    /**
     * @notice Calculates the amount of token that have been vested since the last withdraw
     * @param agreement Vesting agreement between payer and user
     * @return amountToWithdrawInWei Amount of tokens that have been vested since the last withdraw
     */
    function _calculateTokensToWithdraw(VestingAgreement memory agreement)
        internal
        view
        returns (uint256 amountToWithdrawInWei)
    {
        // Example:
        // initialTotalTokensInWei = 10e18
        // vestingDays = 10
        // tokensWithdrawnInWei = 2e18 (Withdrawn on the second day)
        // elapsedTimeInDays = 5 days ago
        // tokensVestedSinceStart = (10e18 * 5) / 10 = 5e18
        // amountToWithdrawInWei = 5e18 - 2e18 = 3e18
        uint256 elapsedTimeInDays = (block.timestamp - agreement.startTimestamp) / 1 days;
        uint256 tokensVestedSinceStart = (agreement.initialTotalTokensInWei * elapsedTimeInDays) / agreement.vestingDays;
        amountToWithdrawInWei = tokensVestedSinceStart - agreement.tokensWithdrawnInWei;
    }

    /**
     * @notice Get the amount of tokens that have been vested since the last time the user did a withdraw.
     * @param payer Payer address
     * @param user User address
     */
    function getTokensToWithdraw(address payer, address user) external view returns (uint256) {
        if (s_vestingAgreements[payer][user].token == address(0)) {
            revert TokenVestingContract__UserDoesNotHaveAgreement();
        }
        return _calculateTokensToWithdraw(s_vestingAgreements[payer][user]);
    }

    function getAgreement(address payer, address user) external view returns (VestingAgreement memory) {
        return s_vestingAgreements[payer][user];
    }
}
