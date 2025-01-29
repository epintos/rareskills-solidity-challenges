// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ETHFundraiserContract } from "src/ETHFundraiserContract.sol";
import { FundraiserContract } from "src/FundraiserContract.sol";
import { FundraiserContractTest } from "./FundraiserContractTest.t.sol";
import { Test, console2 } from "forge-std/Test.sol";

/**
 * @title ETHFundraiserContractTest
 * @author Esteban Pintos
 * @notice Test contract for ETHFundraiserContract. Most of the tests are inherited from FundraiserContractTest. Helper
 * methods are overriden to use the ETHFundraiserContract contract for some specific flows.
 */
contract ETHFundraiserContractTest is FundraiserContractTest {
    function setUp() public {
        fundraiserContract = new ETHFundraiserContract();
        vm.deal(DONATOR, DONATOR_INITIAL_BALANCE);
    }

    // Overriden Helper Functions
    /**
     * @inheritdoc FundraiserContractTest
     */
    function createRandomFundraiser(
        uint256 goal,
        uint256 deadline
    )
        public
        override
        returns (uint256, uint256, uint256)
    {
        goal = bound(goal, GOAL_MIN, GOAL_MAX);
        deadline = bound(deadline, DEADLINE_MIN, DEADLINE_MAX);

        vm.prank(CREATOR);
        uint256 fundraiserId =
            ETHFundraiserContract(address(fundraiserContract)).createFundraiser(goal, block.timestamp + deadline);
        return (fundraiserId, goal, deadline);
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function createFundraiser(uint256 goal, uint256 deadline) public override {
        ETHFundraiserContract(address(fundraiserContract)).createFundraiser(goal, deadline);
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function makeDeposit(uint256 fundraiserId, uint256 amount) public override {
        ETHFundraiserContract(address(fundraiserContract)).deposit{ value: amount }(fundraiserId);
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function balanceOf(address account) public view override returns (uint256) {
        return account.balance;
    }
}
