// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IFundraiser } from "src/interfaces/IFundraiser.sol";
import { FundraiserContract } from "src/FundraiserContract.sol";
import { Test, console2 } from "forge-std/Test.sol";

contract FundraiserContractTest is Test {
    FundraiserContract fundraiserContract;
    address CREATOR = makeAddr("CREATOR");
    address DONATOR = makeAddr("DONATOR");
    uint256 constant GOAL_MAX = 10 ether;
    uint256 constant GOAL_MIN = 1 ether;
    uint256 constant DEADLINE_MAX = 10 days;
    uint256 constant DEADLINE_MIN = 1 days;
    uint256 constant DONATOR_INITIAL_BALANCE = 100 ether;

    event FundraiserCreated(address indexed creator, uint256 fundraiserId, uint256 goal, uint256 deadline);
    event Deposited(address indexed donator, uint256 fundraiserId, uint256 amount);

    function setUp() public {
        fundraiserContract = new FundraiserContract();
        vm.deal(DONATOR, DONATOR_INITIAL_BALANCE);
    }

    // Helper Functions
    function createFundraiser(uint256 goal, uint256 deadline) public returns (uint256, uint256, uint256) {
        goal = bound(goal, GOAL_MIN, GOAL_MAX);
        deadline = bound(deadline, DEADLINE_MIN, DEADLINE_MAX);

        vm.prank(CREATOR);
        uint256 fundraiserId = fundraiserContract.createFundraiser(goal, block.timestamp + deadline);
        return (fundraiserId, goal, deadline);
    }

    // createFundraiser
    function testCreateFundraiserRevetsIfDeadlineIsInThePast() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__DeadlineCannotBeInThePast.selector);
        fundraiserContract.createFundraiser(GOAL_MAX, block.timestamp - 1);
    }

    function testCreateFundraiserRevetsIfGoalIsZero() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__GoalCannotBeZero.selector);
        fundraiserContract.createFundraiser(0, block.timestamp + DEADLINE_MAX);
    }

    function testCreateFundraiserCreatesTheFundraiser(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(_goal, _deadline);
        FundraiserContract.Fundraiser memory fundraiser = fundraiserContract.getFundraiser(fundraiserId);
        assertEq(fundraiser.goal, goal);
        assertEq(fundraiser.deadline, block.timestamp + deadline);
        assertEq(fundraiser.amountRaised, 0);
        assertEq(fundraiser.creator, CREATOR);
        assertEq(fundraiser.goalMet, false);
        assertEq(fundraiser.creatorPaid, false);
        assertEq(fundraiserContract.getFundraiserQuantity(), 1);
    }

    function testCreateFundraiserEmitsEvent() public {
        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit FundraiserCreated(CREATOR, 0, GOAL_MAX, block.timestamp + DEADLINE_MAX);
        fundraiserContract.createFundraiser(GOAL_MAX, block.timestamp + DEADLINE_MAX);
    }

    // deposit

    function testDepositRevertsIfAmountIsZero(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__DepositCannotBeZero.selector);
        fundraiserContract.deposit{ value: 0 }(fundraiserId);
    }

    function testDepositRevetsIfFunraiserDoesNotExist() public {
        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__FundraiserDoesNotExist.selector);
        fundraiserContract.deposit{ value: GOAL_MAX }(0);
    }

    function testDepositRevertsIfDeadlineHasPassed(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        vm.warp(block.timestamp + deadline + 1);
        vm.expectRevert(FundraiserContract.FundraiserContract__CannotDepositAfterDeadline.selector);
        fundraiserContract.deposit{ value: goal }(fundraiserId);
    }

    function testDepositUpdatesState(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.prank(DONATOR);
        fundraiserContract.deposit{ value: deposit }(fundraiserId);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit);
        assertEq(fundraiserContract.getDonatorFundaisers(DONATOR)[0], fundraiserId);
        assertEq(address(fundraiserContract).balance, deposit);

        vm.prank(DONATOR);
        fundraiserContract.deposit{ value: deposit }(fundraiserId);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit * 2);
        assertEq(fundraiserContract.getDonatorFundaisers(DONATOR).length, 1);
        assertEq(address(fundraiserContract).balance, deposit * 2);
    }

    function testDepositEmitsEvent(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.prank(DONATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Deposited(DONATOR, fundraiserId, deposit);
        fundraiserContract.deposit{ value: deposit }(fundraiserId);
    }
}
