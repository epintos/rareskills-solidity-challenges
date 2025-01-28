// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IFundraiser } from "src/interfaces/IFundraiser.sol";
import { FundraiserContract } from "src/FundraiserContract.sol";
import { Test, console2 } from "forge-std/Test.sol";

contract FundraiserContractTest is Test {
    FundraiserContract fundraiserContract;
    address CREATOR = makeAddr("CREATOR");
    address DONATOR = makeAddr("DONATOR");
    uint256 constant GOAL = 10 ether;
    uint256 constant DEADLINE = 5 days;

    event FundraiserCreated(address indexed creator, uint256 fundraiserId, uint256 goal, uint256 deadline);

    function setUp() public {
        fundraiserContract = new FundraiserContract();
    }

    // createFundraiser
    function testCreateFundraiserRevetsIfDeadlineIsInThePast() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__DeadlineCannotBeInThePast.selector);
        fundraiserContract.createFundraiser(GOAL, block.timestamp - 1);
    }

    function testCreateFundraiserRevetsIfGoalIsZero() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__GoalCannotBeZero.selector);
        fundraiserContract.createFundraiser(0, block.timestamp + DEADLINE);
    }

    function testCreateFundraiserCreatesTheFundraiser() public {
        vm.prank(CREATOR);
        uint256 fundraiserId = fundraiserContract.createFundraiser(GOAL, block.timestamp + DEADLINE);
        FundraiserContract.Fundraiser memory fundraiser = fundraiserContract.getFundraiser(fundraiserId);
        assertEq(fundraiser.goal, GOAL);
        assertEq(fundraiser.deadline, block.timestamp + DEADLINE);
        assertEq(fundraiser.amountRaised, 0);
        assertEq(fundraiser.creator, CREATOR);
        assertEq(fundraiser.goalMet, false);
        assertEq(fundraiser.creatorPaid, false);
        assertEq(fundraiserContract.getFundraiserQuantity(), 1);
    }

    function testCreateFundraiserEmitsEvent() public {
        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit FundraiserCreated(CREATOR, 0, GOAL, block.timestamp + DEADLINE);
        fundraiserContract.createFundraiser(GOAL, block.timestamp + DEADLINE);
    }
}
