// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTSwappingContract {
    function createSwap(
        address firstNFTAddress,
        uint256 firstNFTTokenId,
        address secondNFTAddress,
        uint256 secondNFTTokenId
    )
        external
        returns (uint256 swapId)
    { }

    function depositNFT(uint256 swapId, address nftAddress, uint256 nftTokenId) external { }

    function swap(uint256 swapId) external { }

    function withdrawNFT(uint256 swapId) external { }

    function deleteSwap(uint256 swapId) external { }
}
