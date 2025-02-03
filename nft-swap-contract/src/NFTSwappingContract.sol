// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title NFTSwappingContract
 * @author Esteban Pintos
 * @notice Contract that allows two parties to swap NFTs.
 * @notice If the swap is not completed, the NFTs can be withdrawn by the owner.
 */
contract NFTSwappingContract is IERC721Receiver {
    /// ERRORS
    error NFTSwappingContract__CannotBeZeroAddress();
    error NFTSwappingContract__SwapDoesNotExist();
    error NFTSwappingContract__SwapNotInCreatedState();
    error NFTSwappingContract__ReceiverIsNotCurrentContract();
    error NFTSwappingContract__NFTCannotBeWithdrawWhileSwapping();
    error NFTSwappingContract__NFTNotDeposited();
    error NFTSwappingContract__DepositsArePending();
    error NFTSwappingContract__UserIsNotPartOfTheSwap();

    /// TYPE DECLARATIONS
    enum SwapState {
        NONE, // Placeholder for non existing Swap
        CREATED, // Swap created. Deposits are pending
        DEPOSITED // Both NFTs are deposited

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
    event SwapAgreementCreated(uint256 indexed swapId, address indexed firstNFTOwner);
    event Deposited(uint256 indexed swapId, address indexed owner, address nftAddress, uint256 nftTokenId);
    event Withdrawn(uint256 indexed swapId, address indexed owner);
    event SwapComplete(uint256 indexed swapId, address indexed user);

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
    function depositNFT(uint256 swapId, address nftAddress, uint256 nftTokenId) external {
        SwapAgreement storage swapAgreement = s_swaps[swapId];
        if (swapAgreement.state == SwapState.NONE) {
            revert NFTSwappingContract__SwapDoesNotExist();
        }
        if (swapAgreement.state != SwapState.CREATED) {
            revert NFTSwappingContract__SwapNotInCreatedState();
        }
        if (
            swapAgreement.firstNFTAddress == nftAddress && swapAgreement.firstNFTTokenId == nftTokenId
                && swapAgreement.firstNFTOwner == msg.sender
        ) {
            s_swaps[swapId].firstNFTDeposited = true;
        } else if (swapAgreement.secondNFTAddress == nftAddress && swapAgreement.secondNFTTokenId == nftTokenId) {
            s_swaps[swapId].secondNFTDeposited = true;
            s_swaps[swapId].secondNFTOwner = msg.sender;
        } else {
            revert NFTSwappingContract__SwapDoesNotExist();
        }

        if (swapAgreement.firstNFTDeposited && swapAgreement.secondNFTDeposited) {
            s_swaps[swapId].state = SwapState.DEPOSITED;
        }
        emit Deposited(swapId, msg.sender, nftAddress, nftTokenId);

        // This will fail if the msg.sender does not own the NFT
        ERC721(nftAddress).safeTransferFrom(msg.sender, address(this), nftTokenId);
    }

    /**
     * @notice Swaps the NFTs between the two parties.
     * @dev The NFTs will be transfered from the current contract to the other parties.
     * @param swapId The ID of the swap agreement.
     */
    function swap(uint256 swapId) external {
        SwapAgreement storage swapAgreement = s_swaps[swapId];
        if (swapAgreement.state == SwapState.NONE) {
            revert NFTSwappingContract__SwapDoesNotExist();
        }
        if (swapAgreement.state != SwapState.DEPOSITED) {
            revert NFTSwappingContract__DepositsArePending();
        }
        if (msg.sender != swapAgreement.firstNFTOwner && msg.sender != swapAgreement.secondNFTOwner) {
            revert NFTSwappingContract__UserIsNotPartOfTheSwap();
        }
        address firstNFTAddress = swapAgreement.firstNFTAddress;
        uint256 firstNFTTokenId = swapAgreement.firstNFTTokenId;
        address firstNFTOwner = swapAgreement.firstNFTOwner;
        address secondNFTAddress = swapAgreement.secondNFTAddress;
        uint256 secondNFTTokenId = swapAgreement.secondNFTTokenId;
        address secondNFTOwner = swapAgreement.secondNFTOwner;
        delete s_swaps[swapId];
        emit SwapComplete(swapId, msg.sender);
        ERC721(firstNFTAddress).safeTransferFrom(address(this), secondNFTOwner, firstNFTTokenId);
        ERC721(secondNFTAddress).safeTransferFrom(address(this), firstNFTOwner, secondNFTTokenId);
    }

    /**
     * @notice Withdraws a NFT from the swap agreement.
     * @notice Withdraw can only be done by the NFT owner and if the swap is not in progress.
     * @notice Withdraw will revert if a swap is in progress since it is deleted.
     * @param swapId The ID of the swap agreement.
     */
    function withdrawNFT(uint256 swapId) external {
        SwapAgreement storage swapAgreement = s_swaps[swapId];
        if (swapAgreement.state == SwapState.NONE) {
            revert NFTSwappingContract__SwapDoesNotExist();
        }
        bool firstNFTOwner = false;
        if (msg.sender == swapAgreement.firstNFTOwner) {
            if (!swapAgreement.firstNFTDeposited) {
                revert NFTSwappingContract__NFTNotDeposited();
            }
            s_swaps[swapId].firstNFTDeposited = false;
            firstNFTOwner = true;
        } else if (msg.sender == swapAgreement.secondNFTOwner) {
            // This could only happen if it was deposited and withdrawn already
            if (!swapAgreement.secondNFTDeposited) {
                revert NFTSwappingContract__NFTNotDeposited();
            }
            s_swaps[swapId].secondNFTDeposited = false;
        } else {
            revert NFTSwappingContract__NFTNotDeposited();
        }

        s_swaps[swapId].state = SwapState.CREATED;

        emit Withdrawn(swapId, msg.sender);
        if (firstNFTOwner) {
            ERC721(swapAgreement.firstNFTAddress).safeTransferFrom(
                address(this), msg.sender, swapAgreement.firstNFTTokenId
            );
        } else {
            ERC721(swapAgreement.secondNFTAddress).safeTransferFrom(
                address(this), msg.sender, swapAgreement.secondNFTTokenId
            );
        }
    }

    // EXTERNAL VIEW FUNCTIONS

    /**
     *
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(
        address operator,
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    )
        external
        view
        returns (bytes4)
    {
        if (operator != address(this)) {
            revert NFTSwappingContract__ReceiverIsNotCurrentContract();
        }
        return this.onERC721Received.selector;
    }

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
