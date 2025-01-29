// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FundraiserContract
 * @author Esteban Pintos
 * @notice Contract that allows users to create a Fundraiser with a goal and deadline for donators to contribute with
 * funds.
 * @notice If the goal is met, then the creator can withdraw the funds. If the goal is not met, then the donators can
 * withdraw their funds.
 * @notice This is a generic contract that can support both ETH and ERC20 tokens.
 * @notice ERC20FundaierContract and ETHFundraiserContract are contracts that inherit from this contract and implement
 * the deposit and createFundraiser function for their respective tokens.
 */
contract FundraiserContract {
    /// ERRORS
    error FundraiserContract__DeadlineCannotBeInThePast();
    error FundraiserContract__GoalCannotBeZero();
    error FundraiserContract__DepositCannotBeZero();
    error FundraiserContract__FundraiserDoesNotExist();
    error FundraiserContract__CannotDepositAfterDeadline();
    error FundraiserContract__CannotWithdrawBeforeDeadline();
    error FundraiserContract__CreatorCannotWithdrawGoalNotMet();
    error FundraiserContract__DonatorCannotWithdrawGoalMet();
    error FundraiserContract__NoAmountLeftToWithdraw();
    error FundraiserContract__WithdrawalFailed();
    error FundraiserContract__CreatorAlreadyPaid();
    error FundraiserContract__CreatorCannotDeposit();
    error FundraiserContract__CannotBeTokenWithZeroAddress();

    enum FundraiserState {
        NOT_CREATED,
        CREATED,
        CREATOR_PAID
    }

    // TYPE DECLARATIONS
    struct Fundraiser {
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        address creator;
        FundraiserState state;
        address token; // 0x0 for ETH
    }

    /// STATE VARIABLES
    mapping(uint256 fundraiserId => Fundraiser fundraiser) private s_fundraisers;
    mapping(uint256 fundraiserId => mapping(address donator => uint256 amountDonated)) private s_donators;
    uint256 private s_fundraiserQuantity;

    /// EVENTS
    event FundraiserCreated(address indexed creator, uint256 fundraiserId, uint256 goal, uint256 deadline);
    event Deposited(address indexed donator, uint256 fundraiserId, uint256 amount);
    event Withdrawn(address indexed caller, uint256 fundraiserId);

    /// FUNCTIONS
    // EXTERNAL FUNCTIONS
    /**
     * @notice Creator of the fundraiser can withdraw funds if goal is met and deadline is passed.
     * @notice If the goal is not met, everyone can withdraw their funds.
     * @notice If the goal is met, only the creator can withdraw the funds.
     * @notice Donator will withdraw all tokens funds
     * @param fundraiserId Fundraiser id
     */
    function withdraw(uint256 fundraiserId) external {
        Fundraiser memory fundraiser = s_fundraisers[fundraiserId];

        if (fundraiser.state == FundraiserState.NOT_CREATED) {
            revert FundraiserContract__FundraiserDoesNotExist();
        }

        if (block.timestamp < fundraiser.deadline) {
            revert FundraiserContract__CannotWithdrawBeforeDeadline();
        }

        if (fundraiser.creator == msg.sender) {
            _withdrawCreator(fundraiserId);
        } else {
            _withdrawDonator(fundraiserId);
        }
        emit Withdrawn(msg.sender, fundraiserId);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Withdraw funds for the creator of the Fundraiser
     * @param fundraiserId Fundraiser id
     */
    function _withdrawCreator(uint256 fundraiserId) internal {
        Fundraiser memory fundraiser = s_fundraisers[fundraiserId];

        if (fundraiser.state == FundraiserState.CREATOR_PAID) {
            revert FundraiserContract__CreatorAlreadyPaid();
        }
        if (fundraiser.amountRaised < fundraiser.goal) {
            revert FundraiserContract__CreatorCannotWithdrawGoalNotMet();
        }

        s_fundraisers[fundraiserId].state = FundraiserState.CREATOR_PAID;
        bool success;
        if (fundraiser.token == address(0)) {
            (success,) = msg.sender.call{ value: fundraiser.amountRaised }("");
        } else {
            (success) = ERC20(fundraiser.token).transfer(msg.sender, fundraiser.amountRaised);
        }
        if (!success) {
            revert FundraiserContract__WithdrawalFailed();
        }
    }

    /**
     * @notice Withdraw funds for the donator of the Fundraiser if the goal is not met
     * @param fundraiserId Fundraiser id
     */
    function _withdrawDonator(uint256 fundraiserId) internal {
        Fundraiser memory fundraiser = s_fundraisers[fundraiserId];
        if (fundraiser.amountRaised >= fundraiser.goal) {
            revert FundraiserContract__DonatorCannotWithdrawGoalMet();
        }

        uint256 amountDonated = s_donators[fundraiserId][msg.sender];
        if (amountDonated == 0) {
            revert FundraiserContract__NoAmountLeftToWithdraw();
        }
        delete s_donators[fundraiserId][msg.sender];
        bool success;
        if (fundraiser.token == address(0)) {
            (success,) = msg.sender.call{ value: amountDonated }("");
        } else {
            (success) = ERC20(fundraiser.token).transfer(msg.sender, amountDonated);
        }
        if (!success) {
            revert FundraiserContract__WithdrawalFailed();
        }
    }

    /**
     * @notice Deposit ETH to a fundraiser
     * @notice Cannot deposit after deadline has passed
     * @notice Creator cannot deposit
     * @param fundraiserId Fundraiser id
     */
    function _deposit(uint256 fundraiserId, uint256 amount) internal {
        _validateDeposit(fundraiserId, amount);
        s_donators[fundraiserId][msg.sender] += amount;
        s_fundraisers[fundraiserId].amountRaised += amount;
        if (s_fundraisers[fundraiserId].token != address(0)) {
            ERC20(s_fundraisers[fundraiserId].token).transferFrom(msg.sender, address(this), amount);
        }
        emit Deposited(msg.sender, fundraiserId, amount);
    }

    function _createFundraiser(uint256 goal, uint256 deadline, address token) internal returns (uint256 fundraiserId) {
        if (deadline < block.timestamp) {
            revert FundraiserContract__DeadlineCannotBeInThePast();
        }

        if (goal == 0) {
            revert FundraiserContract__GoalCannotBeZero();
        }

        fundraiserId = s_fundraiserQuantity;
        s_fundraisers[fundraiserId] = Fundraiser({
            goal: goal,
            deadline: deadline,
            amountRaised: 0,
            creator: msg.sender,
            state: FundraiserState.CREATED,
            token: token
        });
        s_fundraiserQuantity++;
        emit FundraiserCreated(msg.sender, fundraiserId, goal, deadline);
    }

    function _validateDeposit(uint256 fundraiserId, uint256 amount) internal view {
        if (amount == 0) {
            revert FundraiserContract__DepositCannotBeZero();
        }

        Fundraiser memory fundraiser = s_fundraisers[fundraiserId];

        if (fundraiser.state == FundraiserState.NOT_CREATED) {
            revert FundraiserContract__FundraiserDoesNotExist();
        }
        if (block.timestamp >= fundraiser.deadline) {
            revert FundraiserContract__CannotDepositAfterDeadline();
        }
        if (msg.sender == fundraiser.creator) {
            revert FundraiserContract__CreatorCannotDeposit();
        }
    }

    // EXTERNAL VIEW FUNCTIONS
    /**
     * @notice Get fundraiser details
     * @param fundraiserId Fundraiser id
     */
    function getFundraiser(uint256 fundraiserId) external view returns (Fundraiser memory fundraiser) {
        return s_fundraisers[fundraiserId];
    }

    /**
     * @notice Get the number of fundraisers
     * @return fundraiserQuantity Number of fundraisers
     */
    function getFundraiserQuantity() external view returns (uint256) {
        return s_fundraiserQuantity;
    }

    /**
     * @notice Get the amount donated by a donator to a fundraiser
     * @param fundraiserId Fundraiser id
     * @param donator Donator address
     * @return amountDonated Amount donated by the donator
     */
    function getDonatorAmount(uint256 fundraiserId, address donator) external view returns (uint256) {
        return s_donators[fundraiserId][donator];
    }
}
