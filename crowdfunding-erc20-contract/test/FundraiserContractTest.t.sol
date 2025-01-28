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
    event Withdrawn(address indexed caller, uint256 fundraiserId);

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

    function testDepositRevertsIfCreatorDeposits(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal,) = createFundraiser(_goal, _deadline);
        vm.deal(CREATOR, goal);
        vm.prank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorCannotDeposit.selector);
        fundraiserContract.deposit{ value: goal }(fundraiserId);
    }

    function testDepositUpdatesState(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.startPrank(DONATOR);
        fundraiserContract.deposit{ value: deposit }(fundraiserId);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit);
        assertEq(address(fundraiserContract).balance, deposit);
        assertEq(fundraiserContract.getDonatorAmount(fundraiserId, DONATOR), deposit);

        fundraiserContract.deposit{ value: deposit }(fundraiserId);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit * 2);
        assertEq(address(fundraiserContract).balance, deposit * 2);
        assertEq(fundraiserContract.getDonatorAmount(fundraiserId, DONATOR), deposit * 2);
        vm.stopPrank();
    }

    function testDepositEmitsEvent(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.prank(DONATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Deposited(DONATOR, fundraiserId, deposit);
        fundraiserContract.deposit{ value: deposit }(fundraiserId);
    }

    // withdraw
    function testWithdrawRevertsIfFundraiserDoesNotExist() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__FundraiserDoesNotExist.selector);
        fundraiserContract.withdraw(0);
    }

    function testWithdrawRevertsIfDeadlineHasNotPassed(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,,) = createFundraiser(_goal, _deadline);
        vm.expectRevert(FundraiserContract.FundraiserContract__CannotWithdrawBeforeDeadline.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawRevertsIfCreatorAlreadyPaid(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        fundraiserContract.deposit{ value: goal }(fundraiserId);

        vm.warp(block.timestamp + deadline + 1);

        vm.startPrank(CREATOR);
        fundraiserContract.withdraw(fundraiserId);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorAlreadyPaid.selector);
        fundraiserContract.withdraw(fundraiserId);
        vm.stopPrank();
    }

    function testWithdrawForCreatorRevertsIfGoalNotMet(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,, uint256 deadline) = createFundraiser(_goal, _deadline);

        vm.warp(block.timestamp + deadline + 1);

        vm.startPrank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorCannotWithdrawGoalNotMet.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawFundsToCreator() public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(GOAL_MAX, DEADLINE_MIN);
        vm.prank(DONATOR);
        fundraiserContract.deposit{ value: goal }(fundraiserId);

        vm.warp(block.timestamp + deadline + 1);

        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Withdrawn(CREATOR, fundraiserId);
        fundraiserContract.withdraw(fundraiserId);

        assertEq(address(fundraiserContract).balance, 0);
        assert(fundraiserContract.getFundraiser(fundraiserId).state == FundraiserContract.FundraiserState.CREATOR_PAID);
        assertEq(address(CREATOR).balance, goal);
    }

    function testWithdrawRevertsForDonatorIfGoalNotMet(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        fundraiserContract.deposit{ value: goal }(fundraiserId);

        vm.warp(block.timestamp + deadline + 1);

        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__DonatorCannotWithdrawGoalMet.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawRevetsIfDonatorDoesNotHaveDonation(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,, uint256 deadline) = createFundraiser(_goal, _deadline);
        vm.warp(block.timestamp + deadline + 1);

        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__NoAmountLeftToWithdraw.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawFundsToDonator(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createFundraiser(_goal, _deadline);
        vm.startPrank(DONATOR);
        fundraiserContract.deposit{ value: goal / 2 }(fundraiserId);
        fundraiserContract.deposit{ value: goal / 2 - 1 }(fundraiserId);

        vm.warp(block.timestamp + deadline + 1);

        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Withdrawn(DONATOR, fundraiserId);
        fundraiserContract.withdraw(fundraiserId);
        vm.stopPrank();
        assertEq(address(fundraiserContract).balance, 0);
        assertEq(address(DONATOR).balance, DONATOR_INITIAL_BALANCE);
    }
}
