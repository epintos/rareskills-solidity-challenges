// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { EnglishAuction } from "src/EnglishAuction.sol";
import { Token_ERC721 } from "@openzeppelin/lib/forge-std/test/mocks/MockERC721.t.sol";

contract EnglishAuctionTest is Test {
    EnglishAuction auctionContract;
    uint256 constant NFT_TOKEN_ID = 0;
    Token_ERC721 nft;
    address SELLER = makeAddr("SELLER");
    address BIDDER_1 = makeAddr("BIDDER_1");
    address BIDDER_2 = makeAddr("BIDDER_2");
    uint256 constant MAX_RESERVE_PRICE = 20 ether;
    uint256 constant MIN_RESERVE_PRICE = 1 ether;
    uint256 constant MAX_DEADLINE = 30 days;
    uint256 constant MIN_DEADLINE = 1 days;

    event Deposit(uint256 indexed auctionId, address indexed seller);

    function setUp() public {
        nft = new Token_ERC721("NFT", "NFT");
        nft.mint(SELLER, NFT_TOKEN_ID);
        auctionContract = new EnglishAuction();
    }

    // Helper Functions
    /**
     * @notice Deposit an NFT to the auction contract with a random price and deadline
     * @param _reservePrice Seed price
     * @param _deadline Seed deadline
     * @return auctionId Auction ID
     * @return reservePrice Random bound reserve price
     * @return deadline Random bound deadline
     */
    function depositNFT(
        uint256 _reservePrice,
        uint256 _deadline
    )
        public
        returns (uint256 auctionId, uint256 reservePrice, uint256 deadline)
    {
        reservePrice = bound(_reservePrice, MIN_RESERVE_PRICE, MAX_RESERVE_PRICE);
        deadline = bound(_deadline, MIN_DEADLINE, MAX_DEADLINE);
        vm.startPrank(SELLER);
        nft.approve(address(auctionContract), NFT_TOKEN_ID);
        auctionId = auctionContract.deposit(address(nft), NFT_TOKEN_ID, deadline, reservePrice);
        vm.stopPrank();
    }

    // deposit
    function testDepositRevertsIfNftAddressIsZero() public {
        vm.startPrank(SELLER);
        vm.expectRevert(EnglishAuction.EnglishAuction__AddressCannotBeZero.selector);
        auctionContract.deposit(address(0), NFT_TOKEN_ID, 0, 0);
    }

    function testDepositRevertsIfDeadlineIsInThePast() public {
        vm.startPrank(SELLER);
        vm.expectRevert(EnglishAuction.EnglishAuction__AuctionDeadlineCannotBeInThePast.selector);
        auctionContract.deposit(address(nft), NFT_TOKEN_ID, 0 days, 0);
    }

    function testDepositRevertsIfPriceIsZero() public {
        vm.startPrank(SELLER);
        vm.expectRevert(EnglishAuction.EnglishAuction__ReservePriceCannotBeZero.selector);
        auctionContract.deposit(address(nft), NFT_TOKEN_ID, 1 days, 0);
    }

    function testDepositCreatesAuction(uint256 _reservePrice, uint256 _deadline) public {
        (uint256 auctionId, uint256 reservePrice, uint256 deadline) = depositNFT(_reservePrice, _deadline);
        EnglishAuction.Auction memory auctionData = auctionContract.getAuction(auctionId);
        assertEq(auctionData.exists, true);
        assertEq(auctionData.seller, SELLER);
        assertEq(auctionData.nftAddress, address(nft));
        assertEq(auctionData.nftTokenId, NFT_TOKEN_ID);
        assertEq(auctionData.deadline, block.timestamp + deadline);
        assertEq(auctionData.reservePrice, reservePrice);
        assertEq(auctionContract.getAuctionQuantity(), 1);
    }

    function testDepositTranfersNFT(uint256 _reservePrice, uint256 _deadline) public {
        depositNFT(_reservePrice, _deadline);
        assertEq(Token_ERC721(nft).ownerOf(NFT_TOKEN_ID), address(auctionContract));
    }

    function testDepositEmitsEvent() public {
        vm.startPrank(SELLER);
        nft.approve(address(auctionContract), NFT_TOKEN_ID);
        vm.expectEmit(true, true, false, false, address(auctionContract));
        emit Deposit(0, address(SELLER));
        auctionContract.deposit(address(nft), NFT_TOKEN_ID, MAX_DEADLINE, MAX_RESERVE_PRICE);
        vm.stopPrank();
    }
}
