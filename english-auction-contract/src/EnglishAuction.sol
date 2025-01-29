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
    error EnglishAuction__AuctionDoesNotExist();
    error EnglishAuction__AuctionDeadlineCannotBeInThePast();
    error EnglishAuction__AddressCannotBeZero();
    error EnglishAuction__ReservePriceCannotBeZero();
    error EnglishAuction__DepositLowerThanReservePrice();
    error EnglishAuction__AuctionHasEnded();
    error EnglishAuction__BidderHasAlreadyBid();
    error EnglishAuction__AuctionHasNotEnded();
    error EnglishAuction__BidderHasNotBid();
    error EnglishAuction__SenderIsNotSeller();
    error EnglishAuction__TransferFailed();
    error EnglishAuction__AuctionReservePriceNotMet();

    /// TYPE DECLARATIONS
    struct Auction {
        bool exists;
        address seller;
        address NFTAddress;
        uint256 NFTTokenId;
        uint256 deadline;
        uint256 reservePrice;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    /// STORE VARIABLES
    mapping(uint256 auctionId => Auction) public s_auctions;
    mapping(uint256 auctionId => Bid[]) public s_auctionBids;
    mapping(address bidder => mapping(uint256 auctionId => uint256 amount)) public s_bidderAuctions;

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

    /**
     * @notice Get the auction details
     * @param auctionId The id of the auction
     * @return auction The auction details
     */
    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return s_auctions[auctionId];
    }

    /**
     * @notice Get the bids of an auction
     * @param auctionId The id of the auction
     * @return bids The bids of the auction
     */
    function getAuctionBids(uint256 auctionId) external view returns (Bid[] memory) {
        return s_auctionBids[auctionId];
    }

    /**
     * @notice Get the amount a bidder has bid on an auction
     * @param auctionId The id of the auction
     * @param bidder The address of the bidder
     */
    function getBidderAmount(uint256 auctionId, address bidder) external view returns (uint256) {
        return s_bidderAuctions[bidder][auctionId];
    }
}
