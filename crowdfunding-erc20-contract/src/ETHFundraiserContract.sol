// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { FundraiserContract } from "./FundraiserContract.sol";

/**
 * @title ETHFundraiserContract
 * @author Esteban Pintos
 * @notice Contract that allows users to create a Fundraiser with a goal and deadline for donators to contribute with
 * ETH.
 * @notice If the goal is met, then the creator can withdraw the funds. If the goal is not met, then the donators can
 * withdraw their funds.
 */
contract ETHFundraiserContract is FundraiserContract {
    /**
     * @notice Creates a new fundraiser
     * @param goal Funraiser goal
     * @param deadline Fundraiser deadline
     * @return fundraiserId Fundraiser id
     */
    function createFundraiser(uint256 goal, uint256 deadline) external returns (uint256 fundraiserId) {
        fundraiserId = _createFundraiser(goal, deadline, address(0));
    }

    /**
     * @notice Deposit ETH to a fundraiser
     * @param fundraiserId Fundraiser id
     */
    function deposit(uint256 fundraiserId) external payable {
        _deposit(fundraiserId, msg.value);
    }
}
