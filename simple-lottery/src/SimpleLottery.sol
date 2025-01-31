// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

/**
 * @title SimpleLottery
 * @author Esteban Pintos
 * @notice Lottery that allows users to purchase lottery tickets and enter the lottery. Once the lottery deadline is
 * reached, the lottery is closed and a winner is selected after a certain delay to make sure a good amount of blocks
 * are minted.
 * @notice The winner can claim the prize within 256 blocks, otherwise, everyone can get their tickets back.
 * @notice The lottery random number will be based on the blockhash of the block after the pick winner delay. If the
 * winners takes more than 256 blocks to claim the prize, the blockhash won't be readable anymore so the winner won't be
 * able to be calculated. This could be improvsed by using something like Chainlink VRF.
 */
contract SimpleLottery {
    /// ERRORS

    /// TYPE DECLARATIONS

    /// STATE VARIABLES
    struct Lottery {
        bool exists;
        uint256 deadline;
        uint256 totalPrize;
        uint256 ticketPrice;
        uint256 pickWinnerDelay;
        address[] participants;
    }

    mapping(uint256 lotteryId => Lottery lottery) private s_lotteries;
    mapping(address user => mapping(uint256 lotteryId => uint256 ticketsAmount)) private s_userLotteries;
    uint256 private s_nextLotteryId;
    uint256 private constant WITHDRAW_BLOCKS_DEADLINE = 256;
    uint256 private constant MIN_WINNER_PICK_DELAY = 1 hours;

    /// EVENTS

    /// MODIFIERS

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS

    /**
     * @notice Creates a new lottery with the given parameters.
     * @param deadline The deadline to enter the lottery.
     * @param ticketPrice The price of each ticket.
     * @param pickWinnerDelay The delay to pick the winner after the deadline. The blockhash of the block after this
     * will be used to pick the winning number;
     * @return lotteryId The id of the created lottery.
     */
    function createLottery(
        uint256 deadline,
        uint256 ticketPrice,
        uint256 pickWinnerDelay
    )
        external
        returns (uint256 lotteryId)
    { }

    /**
     * @notice Allows a user to enter a lottery by sending the required amount of ether.
     * @param lotteryId The id of the lottery to enter.
     */
    function enterLottery(uint256 lotteryId) external payable { }

    /**
     * @notice Allows a user to withdraw the price of a lottery.
     * @notice The user can only withdraw the price if the lottery has ended and the delay to pick the winner has
     * passed.
     * @notice The winner needs to withdraw the price within 256 blocks, otherwise, everyone can get their tickets back.
     * @param lotteryId The id of the lottery to withdraw the price from.
     */
    function withdrawPrice(uint256 lotteryId) external { }

    /**
     * @notice Refunds the tickets of a lottery if the winner hasn't claimed the prize within 256 blocks.
     * @param lotteryId The id of the lottery to refund the tickets from.
     */
    function refundTickets(uint256 lotteryId) external { }

    // EXTERNAL VIEW FUNCTIONS
    /**
     * @notice Returns the lottery with the given id.
     * @param lotteryId The id of the lottery to return.
     * @return lottery The lottery with the given id.
     */
    function getLottery(uint256 lotteryId) external view returns (Lottery memory) { }

    /**
     * @notice Returns the amount of tickets a user has in a lottery.
     * @param lotteryId The id of the lottery to check the tickets from.
     */
    function getUserLotteryTicketsAmount(uint256 lotteryId) external view returns (uint256 ticketsAmount) { }

    /**
     * @notice Returns the id of the next lottery.
     * @return lotteryId The id of the next lottery.
     */
    function getNextLotteryId() external view returns (uint256 lotteryId) { }

    /**
     * @notice Returns the deadline to withdraw the price of a lottery.
     * @return deadline The deadline to withdraw the price of a lottery.
     */
    function getWithdrawBlocksDeadline() external pure returns (uint256 deadline) { }
}
