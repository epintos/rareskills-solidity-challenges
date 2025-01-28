// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IFundraiser } from "./interfaces/IFundraiser.sol";

contract FundraiserContract is IFundraiser {
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
     * @inheritdoc IFundraiser
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

    /**
     * @notice Deposit ETH to a fundraiser
     * @notice Cannot deposit after deadline has passed
     * @notice Creator cannot deposit
     * @param fundraiserId Fundraiser id
     */
    function deposit(uint256 fundraiserId) external payable {
        if (msg.value == 0) {
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
        s_donators[fundraiserId][msg.sender] += msg.value;
        s_fundraisers[fundraiserId].amountRaised += msg.value;
        emit Deposited(msg.sender, fundraiserId, msg.value);
    }

    /**
     * @inheritdoc IFundraiser
     */
    function createFundraiser(uint256 goal, uint256 deadline) external override returns (uint256 fundraiserId) {
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
            state: FundraiserState.CREATED
        });
        s_fundraiserQuantity++;
        emit FundraiserCreated(msg.sender, fundraiserId, goal, deadline);
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
        (bool success,) = msg.sender.call{ value: fundraiser.amountRaised }("");
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
        (bool success,) = msg.sender.call{ value: amountDonated }("");
        if (!success) {
            revert FundraiserContract__WithdrawalFailed();
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
