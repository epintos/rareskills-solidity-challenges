// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IFundraiser } from "./interfaces/IFundraiser.sol";

contract FundraiserContract is IFundraiser {
    /// ERRORS
    error FundraiserContract__DeadlineCannotBeInThePast();
    error FundraiserContract__GoalCannotBeZero();

    // TYPE DECLARATIONS
    struct Fundraiser {
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        address creator;
        bool goalMet;
        bool creatorPaid;
    }

    /// STATE VARIABLES
    mapping(uint256 fundraiserId => Fundraiser fundraiser) private s_fundraisers;
    mapping(uint256 fundraiserId => mapping(address donator => uint256 amountDonated)) private s_donators;
    mapping(address donator => uint256[] fundraiserIds) private s_donatorFundraiserIds;
    uint256 private s_fundraiserQuantity;

    /// EVENTS
    event FundraiserCreated(address indexed creator, uint256 fundraiserId, uint256 goal, uint256 deadline);

    /// FUNCTIONS
    // EXTERNAL FUNCTIONS

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
        s_fundraisers[fundraiserId] = Fundraiser(goal, deadline, 0, msg.sender, false, false);
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
}
