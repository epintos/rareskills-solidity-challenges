// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { console2 } from "forge-std/Script.sol";

/**
 * @title SimpleLottery
 * @author Esteban Pintos
 * @notice Lottery that allows users to purchase lottery tickets and enter the lottery. Once the lottery deadline is
 * reached, the lottery is closed and a winner is selected after a certain delay to make sure a good amount of blocks
 * are mined.
 * @notice The winner can claim the prize within 256 blocks, otherwise, everyone can get their tickets back.
 * @notice The lottery random number will be based on the blockhash of the block number after the delay (winning block
 * number). If the winner takes more than 256 blocks to claim the prize, the blockhash won't be readable anymore so the
 * winner number won't be able to be calculated. This could be improved by using something like Chainlink VRF.
 * @notice Known issue: For simplicity the winning block number is estimated using the Ethereum average block time
 * which is a constant value in the contract. The estimation might not be accurate and winner block might be off by a
 * few blocks.
 */
contract SimpleLottery {
    /// ERRORS
    error SimpleLottery__DeadlineCannotBeInThePast();
    error SimpleLottery__TicketPriceCannotBeZero();
    error SimpleLottery__PickWinnerDelayTooShort();
    error SimpleLottery__LotteryDoesNotExist();
    error SimpleLottery__LotteryDeadlineReached();
    error SimpleLottery__InvalidTicketPrice();
    error SimpleLottery__UserAlreadyEntered();
    error SimpleLottery__LotteryWinnerCannotBePickedYet();
    error SimpleLottery__LotteryHasNoParticipants();
    error SimpleLottery__WinnerCannotBePickedAnymore();
    error SimpleLottery__TransferFailed();
    error SimpleLottery__OnlyWinnerCanWithdrawThePrize();
    error SimpleLottery__WinnerAlreadyPaid();
    error SimpleLottery__CannotGetRefund();
    error SimpleLottery__WinnerHasNotBeenPickedYet();
    error SimpleLottery__UserDoesNotHaveTicketToRefund();

    /// TYPE DECLARATIONS
    struct Lottery {
        bool exists;
        uint256 deadline;
        uint256 totalPrize;
        uint256 ticketPrice;
        uint256 pickWinnerDelay;
        address[] participants;
        uint256 winningBlockNumber;
        bool winnerPaid;
    }

    /// STATE VARIABLES
    mapping(uint256 lotteryId => Lottery lottery) private s_lotteries;
    mapping(address user => mapping(uint256 lotteryId => bool entered)) private s_userLotteries;
    uint256 private s_nextLotteryId;
    uint256 private constant WITHDRAW_BLOCKS_DEADLINE = 256;
    uint256 private constant MIN_WINNER_PICK_DELAY = 1 hours;
    uint256 private constant AVERAGE_BLOCK_TIME = 12 seconds;

    /// EVENTS
    event LotteryCreated(uint256 indexed lotteryId, uint256 deadline, uint256 ticketPrice, uint256 pickWinnerDelay);
    event LotteryTicketPurchased(uint256 lotteryId, address indexed user);
    event LotteryPrizeClaimed(uint256 indexed lotteryId, address indexed winner, uint256 prize);
    event LotteryTicketRefunded(uint256 indexed lotteryId, address indexed user);

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS

    /**
     * @notice Creates a new lottery with the given parameters.
     * @param deadline The deadline to enter the lottery.
     * @param pickWinnerDelay The delay to pick the winner after the deadline. The blockhash of the block number after
     * @param ticketPrice The price of each ticket.
     * this
     * will be used to pick the winning number. The block number is estimated using the average block time.
     * @return lotteryId The id of the created lottery.
     */
    function createLottery(
        uint256 deadline,
        uint256 pickWinnerDelay,
        uint256 ticketPrice
    )
        external
        returns (uint256 lotteryId)
    {
        if (deadline < block.timestamp) {
            revert SimpleLottery__DeadlineCannotBeInThePast();
        }

        if (ticketPrice == 0) {
            revert SimpleLottery__TicketPriceCannotBeZero();
        }

        if (pickWinnerDelay < MIN_WINNER_PICK_DELAY) {
            revert SimpleLottery__PickWinnerDelayTooShort();
        }
        lotteryId = s_nextLotteryId;
        s_lotteries[lotteryId] = Lottery({
            exists: true,
            deadline: deadline,
            totalPrize: 0,
            ticketPrice: ticketPrice,
            pickWinnerDelay: pickWinnerDelay,
            participants: new address[](0),
            winningBlockNumber: block.number + ((deadline + pickWinnerDelay - block.timestamp) / AVERAGE_BLOCK_TIME),
            winnerPaid: false
        });
        s_nextLotteryId++;
        emit LotteryCreated(lotteryId, deadline, ticketPrice, pickWinnerDelay);
    }

    /**
     * @notice Allows a user to enter a lottery by sending the required amount of ether.
     * @notice Users can only buy one ticket.
     * @param lotteryId The id of the lottery to enter.
     */
    function enterLottery(uint256 lotteryId) external payable {
        Lottery storage lottery = s_lotteries[lotteryId];

        if (!lottery.exists) {
            revert SimpleLottery__LotteryDoesNotExist();
        }

        if (block.timestamp > lottery.deadline) {
            revert SimpleLottery__LotteryDeadlineReached();
        }

        if (msg.value != lottery.ticketPrice) {
            revert SimpleLottery__InvalidTicketPrice();
        }

        if (s_userLotteries[msg.sender][lotteryId]) {
            revert SimpleLottery__UserAlreadyEntered();
        }

        s_userLotteries[msg.sender][lotteryId] = true;
        lottery.participants.push(msg.sender);
        lottery.totalPrize += msg.value;
        emit LotteryTicketPurchased(lotteryId, msg.sender);
    }

    /**
     * @notice Allows a user to withdraw the price of a lottery.
     * @notice The winner is picked even if the winner is not the one calling this function.
     * @notice Only the winner can withdraw the price.
     * @notice The user can only withdraw the price if the lottery has ended and the delay to pick the winner has
     * passed.
     * @notice The winner needs to withdraw the price within 256 blocks, otherwise, everyone can get their tickets back.
     * @notice Known issue: The lottery struct could be deleted after the winner withdraws the prize
     * @param lotteryId The id of the lottery to withdraw the price from.
     */
    function withdrawPrize(uint256 lotteryId) external {
        Lottery storage lottery = s_lotteries[lotteryId];
        if (!lottery.exists) {
            revert SimpleLottery__LotteryDoesNotExist();
        }

        if (block.timestamp < lottery.deadline + lottery.pickWinnerDelay) {
            revert SimpleLottery__LotteryWinnerCannotBePickedYet();
        }

        if (block.number == lottery.winningBlockNumber) {
            revert SimpleLottery__LotteryWinnerCannotBePickedYet();
        }

        if (lottery.participants.length == 0) {
            revert SimpleLottery__LotteryHasNoParticipants();
        }

        if (lottery.winnerPaid) {
            revert SimpleLottery__WinnerAlreadyPaid();
        }

        bytes32 blockhashNumber = blockhash(lottery.winningBlockNumber);

        // 256 blocks have passed since the winner block was mined
        // Winner cannot be picked anymore since the blockhash is not readable anymore
        if (blockhashNumber == bytes32(0)) {
            revert SimpleLottery__WinnerCannotBePickedAnymore();
        }
        uint256 winningNumber = uint256(blockhashNumber) % lottery.participants.length;
        address winner = lottery.participants[winningNumber];

        if (msg.sender != winner) {
            revert SimpleLottery__OnlyWinnerCanWithdrawThePrize();
        }

        s_lotteries[lotteryId].winnerPaid = true;
        emit LotteryPrizeClaimed(lotteryId, winner, lottery.totalPrize);
        (bool success,) = payable(winner).call{ value: lottery.totalPrize }("");
        if (!success) {
            revert SimpleLottery__TransferFailed();
        }
    }

    /**
     * @notice Refunds the tickets of a lottery if the winner hasn't claimed the prize within 256 blocks.
     * @param lotteryId The id of the lottery to refund the tickets from.
     */
    function refundTickets(uint256 lotteryId) external {
        Lottery storage lottery = s_lotteries[lotteryId];
        if (!lottery.exists) {
            revert SimpleLottery__LotteryDoesNotExist();
        }

        if (lottery.winnerPaid) {
            revert SimpleLottery__CannotGetRefund();
        }

        if (block.timestamp < lottery.deadline + lottery.pickWinnerDelay) {
            revert SimpleLottery__WinnerHasNotBeenPickedYet();
        }

        // Winner can still read lottery.winningBlockNumber + 1
        if (block.number < lottery.winningBlockNumber + 2) {
            revert SimpleLottery__WinnerHasNotBeenPickedYet();
        }

        if (s_userLotteries[msg.sender][lotteryId] == false) {
            revert SimpleLottery__UserDoesNotHaveTicketToRefund();
        }

        s_userLotteries[msg.sender][lotteryId] = false;
        emit LotteryTicketRefunded(lotteryId, msg.sender);
        (bool success,) = payable(msg.sender).call{ value: lottery.ticketPrice }("");
        if (!success) {
            revert SimpleLottery__TransferFailed();
        }
    }

    // EXTERNAL VIEW FUNCTIONS
    /**
     * @notice Returns the lottery with the given id.
     * @param lotteryId The id of the lottery to return.
     * @return lottery The lottery with the given id.
     */
    function getLottery(uint256 lotteryId) external view returns (Lottery memory) {
        return s_lotteries[lotteryId];
    }

    /**
     * @notice Returns true if the user has entered the lottery with the given id.
     * @param user The address of the user to check if has entered the lottery.
     * @param lotteryId The id of the lottery to check the tickets from.
     * @return True if the user has entered the lottery with the given id.
     */
    function getUserEnteredLottery(address user, uint256 lotteryId) external view returns (bool) {
        return s_userLotteries[user][lotteryId];
    }

    /**
     * @notice Returns the id of the next lottery.
     * @return lotteryId The id of the next lottery.
     */
    function getNextLotteryId() external view returns (uint256 lotteryId) {
        return s_nextLotteryId;
    }

    /**
     * @notice Returns the deadline to withdraw the price of a lottery.
     * @return deadline The deadline to withdraw the price of a lottery.
     */
    function getWithdrawBlocksDeadline() external pure returns (uint256 deadline) {
        return WITHDRAW_BLOCKS_DEADLINE;
    }

    /**
     * @notice Returns the average block time in the network.
     * @return averageBlockTime The average block time in the network.
     */
    function getAverageBlockTime() external pure returns (uint256 averageBlockTime) {
        return AVERAGE_BLOCK_TIME;
    }
}
