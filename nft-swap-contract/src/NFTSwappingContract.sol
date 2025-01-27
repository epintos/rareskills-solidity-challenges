// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTSwappingContract {
    /// ERRORS
    error NFTSwappingContract__CannotBeZeroAddress();

    /// TYPE DECLARATIONS
    enum SwapState {
        CREATED, // Swap created. Deposits are pending
        DEPOSIT_COMPLETED, // Both NFTs are deposited
        IN_PROGRESS, // One of the users started the swap
        COMPLETED // Both NFTs are swapped

    }

    struct SwapAgreement {
        address firstNFTAddress;
        uint256 firstNFTTokenId;
        address secondNFTAddress;
        uint256 secondNFTTokenId;
        address firstNFTOwner;
        address secondNFTOwner;
        bool firstNFTDeposited;
        bool secondNFTDeposited;
        SwapState state;
    }

    /// STATE VARIABLES
    uint256 private s_swapQuantity = 0;
    mapping(uint256 swapId => SwapAgreement) private s_swaps;

    /// EVENTS
    event SwapAgreementCreated(uint256 indexed swapId, address firstNFTOwner);

    /// MODIFIERS
    modifier cannotBeZeroAddress(address _address) {
        if (_address == address(0)) {
            revert NFTSwappingContract__CannotBeZeroAddress();
        }
        _;
    }

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS

    /**
     * @notice Creates a NFT swap agreement between two parties.
     * @param firstNFTAddress The address of the first NFT.
     * @param firstNFTTokenId The token ID of the first NFT.
     * @param secondNFTAddress The address of the second NFT.
     * @param secondNFTTokenId The token ID of the second NFT.
     * @return swapId The ID of the swap agreement.
     */
    function createSwapAgreement(
        address firstNFTAddress,
        uint256 firstNFTTokenId,
        address secondNFTAddress,
        uint256 secondNFTTokenId
    )
        external
        cannotBeZeroAddress(firstNFTAddress)
        cannotBeZeroAddress(secondNFTAddress)
        returns (uint256 swapId)
    {
        swapId = s_swapQuantity;
        s_swaps[swapId] = SwapAgreement({
            firstNFTAddress: firstNFTAddress,
            firstNFTTokenId: firstNFTTokenId,
            secondNFTAddress: secondNFTAddress,
            secondNFTTokenId: secondNFTTokenId,
            firstNFTOwner: msg.sender,
            secondNFTOwner: address(0),
            firstNFTDeposited: false,
            secondNFTDeposited: false,
            state: SwapState.CREATED
        });
        s_swapQuantity++;
        emit SwapAgreementCreated(swapId, msg.sender);
    }

    /**
     * @notice Deposits a NFT into the swap agreement.
     * @dev The NFT will be transferred and locked in this contract.
     * @param swapId The ID of the swap agreement.
     * @param nftAddress The address of the NFT.
     * @param nftTokenId The token ID of the NFT.
     */
    function depositNFT(uint256 swapId, address nftAddress, uint256 nftTokenId) external { }

    /**
     * @notice Swaps the NFTs between the two parties.
     * @dev The NFTs will be transfered from the current contract to the other parties.
     * @param swapId The ID of the swap agreement.
     */
    function swap(uint256 swapId) external { }

    /**
     * @notice Withdraws a NFT from the swap agreement.
     * @notice Withdraw will revert if a swap is in progress.
     * @param swapId The ID of the swap agreement.
     */
    function withdrawNFT(uint256 swapId) external { }

    // EXTERNAL VIEW FUNCTIONS

    /**
     * @notice Returns the swap agreement details.
     * @param swapId The ID of the swap agreement.
     * @return swap The swap agreement details.
     */
    function getSwapAgreement(uint256 swapId) external view returns (SwapAgreement memory) {
        return s_swaps[swapId];
    }

    /**
     * @return swapQuantity The quantity of swap agreements created.
     */
    function getSwapQuantity() external view returns (uint256) {
        return s_swapQuantity;
    }
}
