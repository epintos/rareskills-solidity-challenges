// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { NFTSwappingContract } from "src/NFTSwappingContract.sol";
import { Token_ERC721 } from "@openzeppelin/lib/forge-std/test/mocks/MockERC721.t.sol";

contract NFTSwappingContractTest is Test {
    NFTSwappingContract nftSwappingContract;
    address USER_1 = makeAddr("USER_1");
    address USER_2 = makeAddr("USER_2");
    Token_ERC721 nft1;
    Token_ERC721 nft2;
    uint256 constant NFT_1_TOKEN_ID = 0;
    uint256 constant NFT_2_TOKEN_ID = 0;
    uint256 constant SWAP_ID = 0;

    event SwapAgreementCreated(uint256 indexed swapId, address indexed firstNFTOwner);
    event Deposited(uint256 indexed swapId, address indexed owner, address nftAddress, uint256 nftTokenId);
    event Withdrawn(uint256 indexed swapId, address indexed owner);
    event SwapComplete(uint256 indexed swapId, address indexed user);

    function setUp() public {
        nftSwappingContract = new NFTSwappingContract();
        nft1 = new Token_ERC721("NFT1", "NFT1");
        nft1.mint(USER_1, NFT_1_TOKEN_ID);
        nft2 = new Token_ERC721("NFT2", "NFT2");
        nft2.mint(USER_2, NFT_2_TOKEN_ID);
    }

    // Helper functions
    function createSwapAndMakeDeposit() public returns (uint256 swapId) {
        vm.startPrank(USER_1);
        swapId = nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        nft1.approve(address(nftSwappingContract), NFT_1_TOKEN_ID);
        nftSwappingContract.depositNFT(swapId, address(nft1), NFT_1_TOKEN_ID);
        vm.stopPrank();
    }

    function makesDeposit(address user, uint256 swapId, Token_ERC721 nft, uint256 tokenId) public {
        vm.startPrank(user);
        nft.approve(address(nftSwappingContract), tokenId);
        nftSwappingContract.depositNFT(swapId, address(nft), tokenId);
        vm.stopPrank();
    }

    // createSwapAgreement

    function testCreateSwapAgreementRevertsIfAddressIsZero() public {
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__CannotBeZeroAddress.selector);
        nftSwappingContract.createSwapAgreement(address(0), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__CannotBeZeroAddress.selector);
        nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(0), NFT_2_TOKEN_ID);
    }

    function testCreateSwapAgreementCreatesAgreement() public {
        vm.prank(USER_1);
        uint256 swapId =
            nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);

        NFTSwappingContract.SwapAgreement memory swap = nftSwappingContract.getSwapAgreement(swapId);
        assertEq(swap.firstNFTAddress, address(nft1));
        assertEq(swap.firstNFTTokenId, NFT_1_TOKEN_ID);
        assertEq(swap.secondNFTAddress, address(nft2));
        assertEq(swap.secondNFTTokenId, NFT_2_TOKEN_ID);
        assertEq(swap.firstNFTOwner, USER_1);
        assertEq(swap.secondNFTOwner, address(0));
        assertEq(swap.firstNFTDeposited, false);
        assertEq(swap.secondNFTDeposited, false);
        assert(swap.state == NFTSwappingContract.SwapState.CREATED);
    }

    function testCreateSwapAgreementEmitsEvent() public {
        vm.startPrank(USER_1);
        vm.expectEmit(true, true, false, false, address(nftSwappingContract));
        emit SwapAgreementCreated(SWAP_ID, USER_1);
        nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        vm.stopPrank();
    }

    // depositNFT
    function testDepositNFTRevertsIfSwapIdDoesNotExist() public {
        vm.prank(USER_1);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__SwapDoesNotExist.selector);
        nftSwappingContract.depositNFT(SWAP_ID, address(nft1), NFT_1_TOKEN_ID);
    }

    function testDepositNFTRevertsIfNotInCreateState() public {
        uint256 swapId = createSwapAndMakeDeposit();

        vm.startPrank(USER_2);
        nft2.approve(address(nftSwappingContract), NFT_2_TOKEN_ID);
        nftSwappingContract.depositNFT(swapId, address(nft2), NFT_2_TOKEN_ID);

        // Deposits again
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__SwapNotInCreatedState.selector);
        nftSwappingContract.depositNFT(swapId, address(nft2), NFT_2_TOKEN_ID);
        vm.stopPrank();
    }

    function testDepositUpdatesSwapAgreementCorrectly() public {
        uint256 swapId = createSwapAndMakeDeposit();
        assertEq(nftSwappingContract.getSwapAgreement(swapId).firstNFTDeposited, true);
        makesDeposit(USER_2, swapId, nft2, NFT_2_TOKEN_ID);
        NFTSwappingContract.SwapAgreement memory swap = nftSwappingContract.getSwapAgreement(swapId);
        assertEq(swap.secondNFTDeposited, true);
        assertEq(swap.secondNFTOwner, USER_2);
        assert(swap.state == NFTSwappingContract.SwapState.DEPOSITED);
    }

    function testDepositLocksNFT() public {
        createSwapAndMakeDeposit();
        assertEq(nft1.ownerOf(NFT_1_TOKEN_ID), address(nftSwappingContract));
    }

    function testDepositEmitsEvent() public {
        vm.startPrank(USER_1);
        uint256 swapId =
            nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        nft1.approve(address(nftSwappingContract), NFT_1_TOKEN_ID);
        vm.expectEmit(true, true, false, false, address(nftSwappingContract));
        emit Deposited(swapId, USER_1, address(nft1), NFT_1_TOKEN_ID);
        nftSwappingContract.depositNFT(swapId, address(nft1), NFT_1_TOKEN_ID);
        vm.stopPrank();
    }

    // withdrawNFT
    function testWithdrawNFTRevertsIfSwapIdDoesNotExist() public {
        vm.prank(USER_1);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__SwapDoesNotExist.selector);
        nftSwappingContract.withdrawNFT(SWAP_ID);
    }

    function testWithdrawNFTRevertsIfNFTIsNotDeposited() public {
        vm.startPrank(USER_1);
        uint256 swapId =
            nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__NFTNotDeposited.selector);
        nftSwappingContract.withdrawNFT(swapId);
        vm.stopPrank();

        vm.startPrank(USER_2);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__NFTNotDeposited.selector);
        nftSwappingContract.withdrawNFT(swapId);
        vm.stopPrank();

        vm.startPrank(USER_2);
        nft2.approve(address(nftSwappingContract), NFT_2_TOKEN_ID);
        nftSwappingContract.depositNFT(swapId, address(nft2), NFT_2_TOKEN_ID);
        nftSwappingContract.withdrawNFT(swapId);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__NFTNotDeposited.selector);
        nftSwappingContract.withdrawNFT(swapId);
        vm.stopPrank();
    }

    function testWithdrawNFTUpdatesTheSwapAgreement() public {
        uint256 swapId = createSwapAndMakeDeposit();
        vm.prank(USER_1);
        nftSwappingContract.withdrawNFT(swapId);

        NFTSwappingContract.SwapAgreement memory swap = nftSwappingContract.getSwapAgreement(swapId);
        assertEq(swap.firstNFTDeposited, false);
        assert(swap.state == NFTSwappingContract.SwapState.CREATED);
        assertEq(nft1.ownerOf(NFT_1_TOKEN_ID), USER_1);

        makesDeposit(USER_2, swapId, nft2, NFT_2_TOKEN_ID);
        vm.prank(USER_2);
        nftSwappingContract.withdrawNFT(swapId);

        swap = nftSwappingContract.getSwapAgreement(swapId);
        assertEq(swap.secondNFTDeposited, false);
        assert(swap.state == NFTSwappingContract.SwapState.CREATED);
        assertEq(nft2.ownerOf(NFT_2_TOKEN_ID), USER_2);
        vm.stopPrank();
    }

    function testWithdrawNFTEmitsEvent() public {
        uint256 swapId = createSwapAndMakeDeposit();

        vm.prank(USER_1);
        vm.expectEmit(true, true, false, false, address(nftSwappingContract));
        emit Withdrawn(swapId, USER_1);
        nftSwappingContract.withdrawNFT(swapId);
    }

    // swap
    function testSwapRevertsIfSwapIdDoesNotExist() public {
        vm.prank(USER_1);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__SwapDoesNotExist.selector);
        nftSwappingContract.swap(SWAP_ID);
    }

    function testSwapRevertsIfDepositsAreNotComplete() public {
        vm.startPrank(USER_1);
        uint256 swapId =
            nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__DepositsArePending.selector);
        nftSwappingContract.swap(swapId);
        vm.stopPrank();
    }

    function testSwapRevertsIfSomeoneElseMakesSwap() public {
        uint256 swapId = createSwapAndMakeDeposit();
        makesDeposit(USER_2, swapId, nft2, NFT_2_TOKEN_ID);

        vm.prank(makeAddr("USER_3"));
        vm.expectRevert(NFTSwappingContract.NFTSwappingContract__UserIsNotPartOfTheSwap.selector);
        nftSwappingContract.swap(swapId);
    }

    function testSwapMakesSwap() public {
        uint256 swapId = createSwapAndMakeDeposit();
        makesDeposit(USER_2, swapId, nft2, NFT_2_TOKEN_ID);

        vm.prank(USER_2);
        vm.expectEmit(true, true, false, false, address(nftSwappingContract));
        emit SwapComplete(swapId, USER_2);
        nftSwappingContract.swap(swapId);
        assert(nftSwappingContract.getSwapAgreement(swapId).state == NFTSwappingContract.SwapState.NONE);
        assertEq(nft1.ownerOf(NFT_1_TOKEN_ID), USER_2);
        assertEq(nft2.ownerOf(NFT_2_TOKEN_ID), USER_1);
        vm.stopPrank();
    }
}
