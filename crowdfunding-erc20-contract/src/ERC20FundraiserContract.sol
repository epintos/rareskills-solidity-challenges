// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { FundraiserContract } from "./FundraiserContract.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ETHFundraiserContract
 * @author Esteban Pintos
 * @notice Contract that allows users to create a Fundraiser with a goal and deadline for donators to contribute with a
 * ERC20 token defined by the creator.
 * @notice If the goal is met, then the creator can withdraw the funds. If the goal is not met, then the donators can
 * withdraw their funds.
 */
contract ERC20FundraiserContract is FundraiserContract {
    /**
     * @notice Creates a new fundraiser
     * @param goal Funraiser goal
     * @param deadline Fundraiser deadline
     * @param token ERC20 token address. Cannot be address(0)
     * @return fundraiserId Fundraiser id
     */
    function createFundraiser(uint256 goal, uint256 deadline, address token) external returns (uint256 fundraiserId) {
        if (token == address(0)) {
            revert FundraiserContract__CannotBeTokenWithZeroAddress();
        }
        fundraiserId = _createFundraiser(goal, deadline, token);
    }

    /**
     * @notice Deposit ERC20 tokens to a fundraiser. Donator must have token allowance to this contract. The token
     * address is defined in the fundraiser by the creator.
     * @param fundraiserId Fundraiser id
     * @param amount Amount to deposit
     */
    function deposit(uint256 fundraiserId, uint256 amount) external {
        _deposit(fundraiserId, amount);
    }
}
