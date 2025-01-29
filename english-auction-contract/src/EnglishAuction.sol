// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title EnglishAuction
 * @author Esteban Pintos
 * @notice Contract that allows Sellers to deposit an NFT and start an auction. Users can bid on the NFT and the highest
 * bid wins the auction. If the reserve price is not met after the deadline, the users can withdraw their bid. If the
 * reserve price is met, the seller can end the auction and the highest bidder gets the NFT and the seller gets the ETH.
 */
contract EnglishAuction {
    /// ERRORS

    /// TYPE DECLARATIONS

    /// STORE VARIABLES

    /// EVENTS

    /// MODIFIERS

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS

    /**
     * @notice Deposit an NFT and starts an auction
     * @param NFTAddress The address of the NFT contract
     * @param NFTTokenId The token id of the NFT
     * @param deadline The deadline of the auction
     * @param reservePrice The minium price the bidding price should reach
     * @return auctionId The id of the auction
     */
    function deposit(
        address NFTAddress,
        uint256 NFTTokenId,
        uint256 deadline,
        uint256 reservePrice
    )
        external
        returns (uint256 auctionId)
    { }

    /**
     * @notice Users can bid on an NFT by depositing ETH. The highest bid wins the auction
     * @param auctionId The id of the auction
     * @param amount The amount of ETH to bid
     */
    function bid(uint256 auctionId, uint256 amount) external payable { }

    /**
     * @notice User can withdraw a bid if the reserve price is not met after the deadline
     * @param auctionId The id of the auction
     */
    function withdraw(uint256 auctionId) external { }

    /**
     * @notice Seller can end the auction if the reserve price is met. The highest bidder gets the NFT transfered to
     * them and the seller gets the ETH of the highest bid
     * @param auctionId The id of the auction
     */
    function sellerEndAuction(uint256 auctionId) external { }

    // EXTERNAL VIEW FUNCTIONS
}
