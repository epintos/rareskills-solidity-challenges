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

    event SwapAgreementCreated(uint256 indexed swapId, address firstNFTOwner);

    function setUp() public {
        nftSwappingContract = new NFTSwappingContract();
        nft1 = new Token_ERC721("NFT1", "NFT1");
        nft1.mint(USER_1, NFT_1_TOKEN_ID);
        nft2 = new Token_ERC721("NFT2", "NFT2");
        nft2.mint(USER_2, NFT_2_TOKEN_ID);
    }

    // createSwapAgreement

    function testCreateSwapAgreementCreatesAgreement() public {
        vm.prank(USER_1);
        nftSwappingContract.createSwapAgreement(address(nft1), NFT_1_TOKEN_ID, address(nft2), NFT_2_TOKEN_ID);

        NFTSwappingContract.SwapAgreement memory swap = nftSwappingContract.getSwapAgreement(0);
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
}
