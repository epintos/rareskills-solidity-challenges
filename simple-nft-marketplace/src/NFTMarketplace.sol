// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { console2 } from "forge-std/Script.sol";

/**
 * @title NFTMarketplace
 * @author Esteban Pintos
 * @notice Contract that allows a user to sell an NFT and another user to buy it.
 * @notice The NFT ownership is not given to this contract, but the seller gives approval to this contract to transfer
 * the NFT on their behalf if a sale is complete.
 */
contract NFTMarketplace {
    /// ERRORS
    error NFTMarketPlace__DeadlineCannotBeInThePast();
    error NFTMarketPlace__PriceCannotBeZero();
    error NFTMarketPlace__SaleDoesNotExist();
    error NFTMarketPlace__SaleHasExpired();
    error NFTMarketPlace__PaymentAmoutIsTooLow();
    error NFTMarketPlace__SellerCannotBuyOwnNFT();
    error NFTMarketPlace__PaymentToSellerFailed();
    error NFTMarketPlace__OnlySellerCanCancelSale();
    error NFTMarketPlace__SellerMustApproveTransfer();

    /// TYPE DECLARATIONS
    struct Sale {
        bool exists;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        uint256 expirationTimestamp;
        address seller;
    }

    /// STATE VARIABLES
    mapping(uint256 saleId => Sale sale) private s_sales;
    uint256 private s_nextSaleId;

    /// EVENTS
    event SaleCreated(uint256 indexed saleId, address indexed seller);
    event SaleCompleted(uint256 indexed saleId, address indexed seller, uint256 price);
    event SaleCanceled(uint256 indexed saleId, address indexed seller);

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS
    /**
     * @notice Creates a new NFT sale.
     * @notice The seller must approve this contract to transfer the NFT on their behalf before calling this function.
     * @param nftAddress The address of the NFT contract
     * @param tokenId The ID of the NFT
     * @param price The price of the NFT
     * @param expirationTimestamp The timestamp when the sale will expire
     * @return saleId The ID of the sale
     * @notice Known issue: The seller could try to sell the same NFT twice. As an improvement, we could add a mapping
     * of the seller's NFTs to check if the NFT is already for sale.
     */
    function sell(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 expirationTimestamp
    )
        external
        returns (uint256 saleId)
    {
        if (expirationTimestamp <= block.timestamp) {
            revert NFTMarketPlace__DeadlineCannotBeInThePast();
        }

        if (price == 0) {
            revert NFTMarketPlace__PriceCannotBeZero();
        }

        saleId = s_nextSaleId;
        s_sales[saleId] = Sale({
            exists: true,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            expirationTimestamp: expirationTimestamp,
            seller: msg.sender
        });
        s_nextSaleId++;
        if (IERC721(nftAddress).getApproved(tokenId) != address(this)) {
            revert NFTMarketPlace__SellerMustApproveTransfer();
        }
        emit SaleCreated(saleId, msg.sender);
    }

    /**
     * @notice Allows a user to buy an NFT that is for sale
     * @notice The sale will fail if the seller doesn't have the NFT anymore
     * @param saleId The ID of the sale
     */
    function buy(uint256 saleId) external payable {
        Sale memory sale = s_sales[saleId];
        if (!sale.exists) {
            revert NFTMarketPlace__SaleDoesNotExist();
        }
        if (sale.expirationTimestamp < block.timestamp) {
            revert NFTMarketPlace__SaleHasExpired();
        }
        if (msg.value < sale.price) {
            revert NFTMarketPlace__PaymentAmoutIsTooLow();
        }
        if (msg.sender == sale.seller) {
            revert NFTMarketPlace__SellerCannotBuyOwnNFT();
        }
        address nftAddress = sale.nftAddress;
        address seller = sale.seller;
        uint256 tokenId = sale.tokenId;
        delete s_sales[saleId];

        IERC721(nftAddress).transferFrom(seller, msg.sender, tokenId);
        (bool success,) = payable(seller).call{ value: msg.value }("");
        if (!success) {
            revert NFTMarketPlace__PaymentToSellerFailed();
        }
        emit SaleCompleted(saleId, sale.seller, msg.value);
    }

    /**
     * @notice Cancels a sale at any time
     * @param saleId The ID of the sale
     */
    function cancel(uint256 saleId) external {
        Sale memory sale = s_sales[saleId];
        if (!sale.exists) {
            revert NFTMarketPlace__SaleDoesNotExist();
        }
        if (msg.sender != sale.seller) {
            revert NFTMarketPlace__OnlySellerCanCancelSale();
        }
        address nftAddress = sale.nftAddress;
        uint256 tokenId = sale.tokenId;
        delete s_sales[saleId];
        IERC721(nftAddress).approve(address(0), tokenId);
        emit SaleCanceled(saleId, msg.sender);
    }

    // EXTERNAL VIEW FUNCTIONS
    /**
     * @notice Returns the sale information
     * @param saleId The ID of the sale
     * @return sale The sale information
     */
    function getSale(uint256 saleId) external view returns (Sale memory) {
        return s_sales[saleId];
    }

    /**
     * @notice Returns the next sale ID
     * @return The next sale ID
     *
     */
    function getNextSaleId() external view returns (uint256) {
        return s_nextSaleId;
    }
}
