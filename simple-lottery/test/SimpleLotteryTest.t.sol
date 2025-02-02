// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { SimpleLottery } from "src/SimpleLottery.sol";

contract SimpleLotteryTest is Test {
    SimpleLottery simpleLottery;
    address CREATOR = makeAddr("CREATOR");
    address PARTICIPANT_1 = makeAddr("PARTICIPANT_1");
    address PARTICIPANT_2 = makeAddr("PARTICIPANT_2");
    uint256 constant INITIAL_USERS_BALANCE = 100 ether;
    uint256 constant MIN_DEADLINE = 24 hours;
    uint256 constant MAX_DEADLINE = 24 days;
    uint256 constant MIN_PICK_WINNER_DELAY = 1 hours;
    uint256 constant MAX_PICK_WINNER_DELAY = 8 hours;
    uint256 constant MIN_TICKET_PRICE = 1e8;
    uint256 constant MAX_TICKET_PRICE = 30 ether;

    /// EVENTS
    event LotteryCreated(uint256 indexed lotteryId, uint256 deadline, uint256 ticketPrice, uint256 pickWinnerDelay);
    event LotteryTicketPurchased(uint256 lotteryId, address indexed user);
    event LotteryWinnerPicked(uint256 indexed lotteryId, address indexed winner, uint256 prize);
    event LotteryPrizeClaimed(uint256 indexed lotteryId, address indexed winner, uint256 prize);

    function setUp() public {
        simpleLottery = new SimpleLottery();
        vm.deal(CREATOR, INITIAL_USERS_BALANCE);
        vm.deal(PARTICIPANT_1, INITIAL_USERS_BALANCE);
        vm.deal(PARTICIPANT_2, INITIAL_USERS_BALANCE);
    }

    // Helper Functions

    /**
     * @notice Creates a lottery with random values
     * @param _deadline deadline seed
     * @param _pickWinnerDelay delay seed
     * @param _ticketPrice price seed
     * @return deadline random deadline
     * @return pickWinnerDelay random delay
     * @return ticketPrice random price
     * @return lotteryId new lottery id
     */
    function createRandomLottery(
        uint256 _deadline,
        uint256 _pickWinnerDelay,
        uint256 _ticketPrice
    )
        public
        returns (uint256 deadline, uint256 pickWinnerDelay, uint256 ticketPrice, uint256 lotteryId)
    {
        deadline = bound(_deadline, MIN_DEADLINE, MAX_DEADLINE);
        pickWinnerDelay = bound(_pickWinnerDelay, MIN_PICK_WINNER_DELAY, MAX_PICK_WINNER_DELAY);
        ticketPrice = bound(_ticketPrice, MIN_TICKET_PRICE, MAX_TICKET_PRICE);
        vm.prank(CREATOR);
        lotteryId = simpleLottery.createLottery(deadline, pickWinnerDelay, ticketPrice);
    }

    function enterLottery(address user, uint256 lotteryId, uint256 ticketPrice) public {
        vm.prank(user);
        simpleLottery.enterLottery{ value: ticketPrice }(lotteryId);
    }

    // createLottery
    function testCreateLotteryRevertsIfDeadlineIsInThePast() public {
        vm.expectRevert(SimpleLottery.SimpleLottery__DeadlineCannotBeInThePast.selector);
        simpleLottery.createLottery(block.timestamp - 1, MIN_PICK_WINNER_DELAY, MIN_TICKET_PRICE);
    }

    function testCreateLotteryRevertsIfPriceIsZero() public {
        vm.expectRevert(SimpleLottery.SimpleLottery__TicketPriceCannotBeZero.selector);
        simpleLottery.createLottery(block.timestamp + MIN_DEADLINE, MIN_PICK_WINNER_DELAY, 0);
    }

    function testCreateLotteryRevertsIfDelayIsTooLow() public {
        vm.expectRevert(SimpleLottery.SimpleLottery__PickWinnerDelayTooShort.selector);
        simpleLottery.createLottery(block.timestamp + MIN_DEADLINE, MIN_PICK_WINNER_DELAY - 1, MIN_TICKET_PRICE - 1);
    }

    function testCreateLotteryStoresLottery(uint256 _deadline, uint256 _pickWinnerDelay, uint256 _ticketPrice) public {
        (uint256 deadline, uint256 pickWinnerDelay, uint256 ticketPrice, uint256 lotteryId) =
            createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        SimpleLottery.Lottery memory lottery = simpleLottery.getLottery(lotteryId);
        assertEq(lottery.deadline, deadline);
        assertEq(lottery.pickWinnerDelay, pickWinnerDelay);
        assertEq(lottery.ticketPrice, ticketPrice);
        assertEq(lottery.totalPrize, 0);
        assertEq(lottery.participants.length, 0);
        assertEq(
            lottery.winningBlockNumber,
            block.number + ((deadline + pickWinnerDelay - block.timestamp) / simpleLottery.getAverageBlockTime())
        );
        assertEq(lottery.winnerCannotBeClaimed, false);
        assertEq(lottery.winner, address(0));
        assertEq(lottery.exists, true);
        assertEq(lotteryId, 0);
        assertEq(simpleLottery.getNextLotteryId(), 1);
    }

    function testCreateLotteryEmitsEvent() public {
        vm.prank(CREATOR);
        vm.expectEmit(true, false, false, false, address(simpleLottery));
        emit LotteryCreated(0, block.timestamp + MIN_DEADLINE, MIN_TICKET_PRICE, MIN_PICK_WINNER_DELAY);
        simpleLottery.createLottery(block.timestamp + MIN_DEADLINE, MIN_PICK_WINNER_DELAY, MIN_TICKET_PRICE);
    }

    // enterLottery
    function testEnterLotteryRevertsIfLotteryDoesNotExist() public {
        vm.expectRevert(SimpleLottery.SimpleLottery__LotteryDoesNotExist.selector);
        simpleLottery.enterLottery(0);
    }

    function testEnterLotteryRevertsIfDeadlineReached(
        uint256 _deadline,
        uint256 _pickWinnerDelay,
        uint256 _ticketPrice
    )
        public
    {
        (uint256 deadline,,, uint256 lotteryId) = createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        vm.warp(deadline + 1);
        vm.expectRevert(SimpleLottery.SimpleLottery__LotteryDeadlineReached.selector);
        simpleLottery.enterLottery(lotteryId);
    }

    function testEnterLotteryRevertsIfInvalidTicketPrice(
        uint256 _deadline,
        uint256 _pickWinnerDelay,
        uint256 _ticketPrice
    )
        public
    {
        (,,, uint256 lotteryId) = createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        vm.expectRevert(SimpleLottery.SimpleLottery__InvalidTicketPrice.selector);
        simpleLottery.enterLottery{ value: 0 }(lotteryId);
    }

    function testEnterLotteryRevertsIfUserAlreadyBoughtTicket(
        uint256 _deadline,
        uint256 _pickWinnerDelay,
        uint256 _ticketPrice
    )
        public
    {
        (,, uint256 ticketPrice, uint256 lotteryId) = createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        enterLottery(PARTICIPANT_1, lotteryId, ticketPrice);

        vm.deal(PARTICIPANT_1, ticketPrice);
        vm.expectRevert(SimpleLottery.SimpleLottery__UserAlreadyEntered.selector);
        enterLottery(PARTICIPANT_1, lotteryId, ticketPrice);
    }

    function testEnterLotteryPurchasesTicket(
        uint256 _deadline,
        uint256 _pickWinnerDelay,
        uint256 _ticketPrice
    )
        public
    {
        (,, uint256 ticketPrice, uint256 lotteryId) = createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        enterLottery(PARTICIPANT_1, lotteryId, ticketPrice);

        SimpleLottery.Lottery memory lottery = simpleLottery.getLottery(lotteryId);
        assertEq(lottery.participants.length, 1);
        assertEq(lottery.participants[0], PARTICIPANT_1);
        assertEq(lottery.totalPrize, ticketPrice);
        assertEq(address(simpleLottery).balance, ticketPrice);
        assertEq(simpleLottery.getUserEnteredLottery(PARTICIPANT_1, lotteryId), true);
    }

    function testEnterLotteryEmitsEvent(uint256 _deadline, uint256 _pickWinnerDelay, uint256 _ticketPrice) public {
        (,, uint256 ticketPrice, uint256 lotteryId) = createRandomLottery(_deadline, _pickWinnerDelay, _ticketPrice);
        vm.expectEmit(true, false, false, false, address(simpleLottery));
        emit LotteryTicketPurchased(lotteryId, PARTICIPANT_1);
        enterLottery(PARTICIPANT_1, lotteryId, ticketPrice);
    }
}
