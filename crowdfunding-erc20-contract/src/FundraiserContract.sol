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

    enum FundraiserState {
        NOT_CREATED,
        CREATED,
        GOAL_MET
    }

    // TYPE DECLARATIONS
    struct Fundraiser {
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        address creator;
        bool goalMet;
        bool creatorPaid;
        FundraiserState state;
    }

    /// STATE VARIABLES
    mapping(uint256 fundraiserId => Fundraiser fundraiser) private s_fundraisers;
    mapping(uint256 fundraiserId => mapping(address donator => uint256 amountDonated)) private s_donators;
    mapping(address donator => uint256[] fundraiserIds) private s_donatorFundraiserIds;
    uint256 private s_fundraiserQuantity;

    /// EVENTS
    event FundraiserCreated(address indexed creator, uint256 fundraiserId, uint256 goal, uint256 deadline);
    event Deposited(address indexed donator, uint256 fundraiserId, uint256 amount);

    /// FUNCTIONS
    // EXTERNAL FUNCTIONS

    /**
     * @notice Deposit ETH to a fundraiser
     * @notice Cannot deposit after deadline has passed
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
        if (s_donators[fundraiserId][msg.sender] == 0) {
            s_donatorFundraiserIds[msg.sender].push(fundraiserId);
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
            goalMet: false,
            creatorPaid: false,
            state: FundraiserState.CREATED
        });
        s_fundraiserQuantity++;
        emit FundraiserCreated(msg.sender, fundraiserId, goal, deadline);
    }

    // EXTERNAL VIEW FUNCTIONS
    function getFundraiser(uint256 fundraiserId) external view returns (Fundraiser memory fundraiser) {
        return s_fundraisers[fundraiserId];
    }

    function getFundraiserQuantity() external view returns (uint256) {
        return s_fundraiserQuantity;
    }

    function getDonatorFundaisers(address donator) external view returns (uint256[] memory) {
        return s_donatorFundraiserIds[donator];
    }
}
