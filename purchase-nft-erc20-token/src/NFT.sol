// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title NFT
 * @author Esteban Pintos
 * @notice Simple NFT that can be minted by providing ERC20 tokens
 */
contract NFT is ERC721 {
    error NFT__NotEnoughBalanceToPay();
    error NFT__NotApprovedOrNotOwner();
    error NFT__TransferFailed();

    uint256 private s_totalSupply;
    uint256 private immutable i_price;
    address private immutable i_token;

    constructor(uint256 price, address token) ERC721("NFT", "NFT") {
        i_price = price;
        i_token = token;
    }

    /**
     * @notice Mint a new NFT by tranfering the price in ERC20 token
     * @notice The caller must have enough balance to pay the price
     * @dev Contract must be approved to transfer the ERC20 token
     */
    function mint() public {
        if (ERC20(i_token).balanceOf(msg.sender) < i_price) {
            revert NFT__NotEnoughBalanceToPay();
        }
        (bool success) = ERC20(i_token).transferFrom(msg.sender, address(this), i_price);
        if (!success) {
            revert NFT__TransferFailed();
        }
        uint256 tokenId = s_totalSupply;
        s_totalSupply += 1;
        _mint(msg.sender, tokenId);
    }

    /**
     * @notice Burn the NFT.
     * @notice The caller must be the owner or have been approved
     * @notice Burning the NFT does not return the ERC20 token
     * @param tokenId  The id of the NFT to burn
     */
    function burn(uint256 tokenId) public {
        if (getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender) {
            revert NFT__NotApprovedOrNotOwner();
        }
        _burn(tokenId);
    }

    /**
     * @notice Get the ERC20 price of the NFT
     */
    function getPrice() public view returns (uint256) {
        return i_price;
    }

    /**
     * @notice Get the ERC20 token used to pay the NFT
     */
    function getToken() public view returns (address) {
        return i_token;
    }

    /**
     * @notice Get the total supply of NFTs minted
     * @notice This is the total number of NFTs minted, not the total number of NFTs in existence, since burning the NFT
     * does not decrease this number
     */
    function getTotalSupply() public view returns (uint256) {
        return s_totalSupply;
    }
}
