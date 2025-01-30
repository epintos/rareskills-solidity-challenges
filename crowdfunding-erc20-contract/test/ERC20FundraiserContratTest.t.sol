// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20FundraiserContract } from "src/ERC20FundraiserContract.sol";
import { FundraiserContractTest } from "./FundraiserContractTest.t.sol";
import { FundraiserContract } from "src/FundraiserContract.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title ERC20FundraiserContractTest
 * @author Esteban Pintos
 * @notice Test contract for ERC20FundraiserContractTest. Most of the tests are inherited from FundraiserContractTest.
 * Helper methods are overriden to use the ERC20FundraiserContractTest contract for some specific flows.
 */
contract ERC20FundraiserContractTest is FundraiserContractTest {
    ERC20Mock token;

    function setUp() public {
        token = new ERC20Mock();
        fundraiserContract = new ERC20FundraiserContract();
        token.mint(DONATOR, DONATOR_INITIAL_BALANCE);
        vm.prank(DONATOR);
        token.approve(address(fundraiserContract), DONATOR_INITIAL_BALANCE);
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
            ERC20FundraiserContract(address(fundraiserContract)).createFundraiser(goal, deadline, address(token));
        return (fundraiserId, goal, deadline);
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function createFundraiser(uint256 goal, uint256 deadline) public override {
        ERC20FundraiserContract(address(fundraiserContract)).createFundraiser(goal, deadline, address(token));
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function makeDeposit(uint256 fundraiserId, uint256 amount) public override {
        ERC20FundraiserContract(address(fundraiserContract)).deposit(fundraiserId, amount);
    }

    /**
     * @inheritdoc FundraiserContractTest
     */
    function balanceOf(address account) public view override returns (uint256) {
        return token.balanceOf(account);
    }
}
