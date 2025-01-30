// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title NFTMarketplace
 * @author Esteban Pintos
 * @notice Contract that allows a user to sell an NFT and another user to buy it.
 * @notice The NFT ownership is not given to this contract, but the seller gives approval to this contract to transfer
 * the NFT on their behalf if a sale is complete.
 */
contract NFTMarketplace {
    /// ERRORS

    /// TYPE DECLARATIONS

    /// STATE VARIABLES

    /// EVENTS

    /// MODIFIERS

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS
    /**
     * @notice Creates a new NFT sale where the seller gives approval to the marketplace contract to transfer the NFT on
     * their behalf if a sales is complete.
     * @param nftAddress The address of the NFT contract
     * @param tokenId The ID of the NFT
     * @param price The price of the NFT
     * @param expirationTimestamp The timestamp when the sale will expire
     * @return saleId The ID of the sale
     */
    function sell(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 expirationTimestamp
    )
        external
        returns (uint256 saleId)
    { }

    /**
     * @notice Allows a user to buy an NFT that is for sale
     * @notice The sale will fail if the seller doesn't have the NFT anymore
     * @param saleId The ID of the sale
     */
    function buy(uint256 saleId) external payable { }

    /**
     * @notice Cancels a sale at any time
     * @param saleId The ID of the sale
     */
    function cancel(uint256 saleId) external { }

    // INTERNAL FUNCTIONS

    // EXTERNAL VIEW FUNCTIONS
}
