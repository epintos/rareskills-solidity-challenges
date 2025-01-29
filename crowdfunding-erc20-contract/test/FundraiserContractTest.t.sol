// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { FundraiserContract } from "src/FundraiserContract.sol";
import { Test, console2 } from "forge-std/Test.sol";

/**
 * @title FundraiserContractTest
 * @author Esteban Pintos
 * @notice Since both ETHFundraiserContract and ERC20FundraiserContract are very similar, this contract tests the common
 * functionality between them. To avoid duplication, helper functions need to be overriden in the child contracts.
 */
abstract contract FundraiserContractTest is Test {
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

    // Helper Functions
    /**
     * @notice Creates Fundarise with random goal and deadline
     * @dev CREATOR is pranked
     * @param goal seed goal
     * @param deadline seed deadline
     * @return fundraiserId Created fundraiser id
     * @return goal Created fundraiser goal
     * @return deadline Created fundraiser deadline
     */
    function createRandomFundraiser(
        uint256 goal,
        uint256 deadline
    )
        public
        virtual
        returns (uint256, uint256, uint256);

    /**
     * @notice Creates a fundraiser with the given goal and deadline
     * @dev CREATOR is not pranked
     * @param goal The fundraiser goal
     * @param deadline The fundraiser deadline including the current timestamp
     */
    function createFundraiser(uint256 goal, uint256 deadline) public virtual;

    /**
     * @notice Makes a deposit to the fundraiser
     * @dev DONATOR is pranked
     * @param amount The amount to deposit
     * @param fundraiserId The fundraiser id
     */
    function makeDeposit(uint256 amount, uint256 fundraiserId) public virtual;

    /**
     * @notice Returns the balance of the account
     * @param account The account address
     */
    function balanceOf(address account) public view virtual returns (uint256);

    // createFundraiser
    function testCreateFundraiserRevertsIfDeadlineIsInThePast() public {
        vm.prank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__DeadlineCannotBeInThePast.selector);
        createFundraiser(GOAL_MAX, block.timestamp - 1);
    }

    function testCreateFundraiserRevertsIfGoalIsZero() public {
        vm.prank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__GoalCannotBeZero.selector);
        createFundraiser(0, block.timestamp + DEADLINE_MAX);
    }

    function testCreateFundraiserCreatesTheFundraiser(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        FundraiserContract.Fundraiser memory fundraiser = fundraiserContract.getFundraiser(fundraiserId);
        assertEq(fundraiser.goal, goal);
        assertEq(fundraiser.deadline, block.timestamp + deadline);
        assertEq(fundraiser.amountRaised, 0);
        assertEq(fundraiser.creator, CREATOR);
        assertEq(fundraiserContract.getFundraiserQuantity(), 1);
    }

    function testcreateFundraiserEmitsEvent() public {
        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit FundraiserCreated(CREATOR, 0, GOAL_MAX, block.timestamp + DEADLINE_MAX);
        createFundraiser(GOAL_MAX, block.timestamp + DEADLINE_MAX);
    }

    // deposit
    function testDepositRevertsIfAmountIsZero(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,,) = createRandomFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__DepositCannotBeZero.selector);
        makeDeposit(fundraiserId, 0);
    }

    function testDepositRevetsIfFunraiserDoesNotExist() public {
        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__FundraiserDoesNotExist.selector);
        makeDeposit(0, GOAL_MAX);
    }

    function testDepositRevertsIfDeadlineHasPassed(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        vm.warp(block.timestamp + deadline + 1);
        vm.expectRevert(FundraiserContract.FundraiserContract__CannotDepositAfterDeadline.selector);
        makeDeposit(fundraiserId, goal);
    }

    function testDepositRevertsIfCreatorDeposits(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal,) = createRandomFundraiser(_goal, _deadline);
        vm.deal(CREATOR, goal);
        vm.prank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorCannotDeposit.selector);
        makeDeposit(fundraiserId, goal);
    }

    function testDepositEmitsEvent(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createRandomFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.prank(DONATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Deposited(DONATOR, fundraiserId, deposit);
        makeDeposit(fundraiserId, deposit);
    }

    function testDepositUpdatesState(uint256 _goal, uint256 _deadline, uint256 deposit) public {
        (uint256 fundraiserId,,) = createRandomFundraiser(_goal, _deadline);
        deposit = bound(deposit, GOAL_MIN, (GOAL_MAX - 1) / 2);
        vm.startPrank(DONATOR);
        makeDeposit(fundraiserId, deposit);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit);
        assertEq(balanceOf(address(fundraiserContract)), deposit);
        assertEq(fundraiserContract.getDonatorAmount(fundraiserId, DONATOR), deposit);

        makeDeposit(fundraiserId, deposit);
        assertEq(fundraiserContract.getFundraiser(fundraiserId).amountRaised, deposit * 2);
        assertEq(balanceOf(address(fundraiserContract)), deposit * 2);
        assertEq(fundraiserContract.getDonatorAmount(fundraiserId, DONATOR), deposit * 2);
        vm.stopPrank();
    }

    // withdraw
    function testWithdrawRevertsIfFundraiserDoesNotExist() public {
        vm.expectRevert(FundraiserContract.FundraiserContract__FundraiserDoesNotExist.selector);
        fundraiserContract.withdraw(0);
    }

    function testWithdrawRevertsIfDeadlineHasNotPassed(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,,) = createRandomFundraiser(_goal, _deadline);
        vm.expectRevert(FundraiserContract.FundraiserContract__CannotWithdrawBeforeDeadline.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawRevertsIfCreatorAlreadyPaid(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        makeDeposit(fundraiserId, goal);

        vm.warp(block.timestamp + deadline + 1);

        vm.startPrank(CREATOR);
        fundraiserContract.withdraw(fundraiserId);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorAlreadyPaid.selector);
        fundraiserContract.withdraw(fundraiserId);
        vm.stopPrank();
    }

    function testWithdrawForCreatorRevertsIfGoalNotMet(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,, uint256 deadline) = createRandomFundraiser(_goal, _deadline);

        vm.warp(block.timestamp + deadline + 1);

        vm.startPrank(CREATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__CreatorCannotWithdrawGoalNotMet.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawRevertsForDonatorIfGoalNotMet(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        vm.prank(DONATOR);
        makeDeposit(fundraiserId, goal);

        vm.warp(block.timestamp + deadline + 1);

        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__DonatorCannotWithdrawGoalMet.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawRevetsIfDonatorDoesNotHaveDonation(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId,, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        vm.warp(block.timestamp + deadline + 1);

        vm.prank(DONATOR);
        vm.expectRevert(FundraiserContract.FundraiserContract__NoAmountLeftToWithdraw.selector);
        fundraiserContract.withdraw(fundraiserId);
    }

    function testWithdrawFundsToDonator(uint256 _goal, uint256 _deadline) public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(_goal, _deadline);
        vm.startPrank(DONATOR);
        makeDeposit(fundraiserId, goal / 2);
        makeDeposit(fundraiserId, goal / 2 - 1);

        vm.warp(block.timestamp + deadline + 1);

        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Withdrawn(DONATOR, fundraiserId);
        fundraiserContract.withdraw(fundraiserId);
        vm.stopPrank();
        assertEq(balanceOf(address(fundraiserContract)), 0);
        assertEq(balanceOf(address(DONATOR)), DONATOR_INITIAL_BALANCE);
    }

    function testWithdrawFundsToCreator() public {
        (uint256 fundraiserId, uint256 goal, uint256 deadline) = createRandomFundraiser(GOAL_MAX, DEADLINE_MIN);
        vm.prank(DONATOR);
        makeDeposit(fundraiserId, goal);

        vm.warp(block.timestamp + deadline + 1);

        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(fundraiserContract));
        emit Withdrawn(CREATOR, fundraiserId);
        fundraiserContract.withdraw(fundraiserId);

        assertEq(balanceOf(address(fundraiserContract)), 0);
        assert(fundraiserContract.getFundraiser(fundraiserId).state == FundraiserContract.FundraiserState.CREATOR_PAID);
        assertEq(balanceOf(address(CREATOR)), goal);
    }
}
