// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { NFTMarketplace } from "src/NFTMarketplace.sol";
import { Token_ERC721 } from "@openzeppelin/lib/forge-std/test/mocks/MockERC721.t.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace nftMarketplaceContract;
    address SELLER = makeAddr("SELLER");
    address BUYER = makeAddr("BUYER");
    uint256 constant BUYER_INITIAL_BALANCE = 100 ether;
    uint256 constant NFT_TOKEN_ID = 0;
    uint256 constant MAX_NFT_PRICE = 10 ether;
    uint256 constant MIN_NFT_PRICE = 1 ether;
    uint256 constant MAX_EXPIRATION_DAYS = 10 days;
    uint256 constant MIN_EXPIRATION_DAYS = 1 days;
    Token_ERC721 nft;

    /// EVENTS
    event SaleCreated(uint256 indexed saleId, address indexed seller);
    event SaleCompleted(uint256 indexed saleId, address indexed seller, uint256 price);
    event SaleCanceled(uint256 indexed saleId, address indexed seller);

    function setUp() public {
        nftMarketplaceContract = new NFTMarketplace();
        nft = new Token_ERC721("NFT1", "NFT1");
        nft.mint(SELLER, NFT_TOKEN_ID);

        vm.deal(BUYER, BUYER_INITIAL_BALANCE);
    }

    // Helper functions
    /**
     * @notice Creates a sale with random values
     * @param _price Price seed
     * @param _expirationTimestamp Expiration timestamp seed
     * @return saleId The ID of the sale
     * @return price The price of the NFT
     * @return expirationTimestamp The timestamp when the sale will expire
     */
    function createSale(
        uint256 _price,
        uint256 _expirationTimestamp
    )
        public
        returns (uint256 saleId, uint256 price, uint256 expirationTimestamp)
    {
        price = bound(_price, MIN_NFT_PRICE, MAX_NFT_PRICE);
        expirationTimestamp =
            bound(_expirationTimestamp, block.timestamp + MIN_EXPIRATION_DAYS, block.timestamp + MAX_EXPIRATION_DAYS);
        vm.startPrank(SELLER);
        nft.approve(address(nftMarketplaceContract), NFT_TOKEN_ID);
        saleId = nftMarketplaceContract.sell(address(nft), NFT_TOKEN_ID, price, expirationTimestamp);
        vm.stopPrank();
    }

    // sell
    function testSellRevertsIfDeadlineIsInThePast() public {
        vm.prank(SELLER);
        vm.expectRevert(NFTMarketplace.NFTMarketPlace__DeadlineCannotBeInThePast.selector);
        nftMarketplaceContract.sell(address(nft), NFT_TOKEN_ID, MAX_NFT_PRICE, block.timestamp - 1);
    }

    function testSellRevertsIfPriceIsZero() public {
        vm.prank(SELLER);
        vm.expectRevert(NFTMarketplace.NFTMarketPlace__PriceCannotBeZero.selector);
        nftMarketplaceContract.sell(address(nft), NFT_TOKEN_ID, 0, block.timestamp + MAX_EXPIRATION_DAYS);
    }

    function testSellerRevertsIfContractAddressIsNotApproved() public {
        vm.prank(BUYER);
        vm.expectRevert(NFTMarketplace.NFTMarketPlace__SellerMustApproveTransfer.selector);
        nftMarketplaceContract.sell(address(nft), NFT_TOKEN_ID, MIN_NFT_PRICE, block.timestamp + MAX_EXPIRATION_DAYS);
    }

    function testSellCreatesSale(uint256 _price, uint256 _expirationTimestamp) public {
        (uint256 saleId, uint256 price, uint256 expirationTimestamp) = createSale(_price, _expirationTimestamp);
        NFTMarketplace.Sale memory sale = nftMarketplaceContract.getSale(saleId);
        assertEq(sale.exists, true);
        assertEq(sale.nftAddress, address(nft));
        assertEq(sale.tokenId, NFT_TOKEN_ID);
        assertEq(sale.price, price);
        assertEq(sale.expirationTimestamp, expirationTimestamp);
        assertEq(sale.seller, SELLER);
        assertEq(nft.getApproved(NFT_TOKEN_ID), address(nftMarketplaceContract));
        assertEq(nftMarketplaceContract.getNextSaleId(), 1);
    }

    // buy

    // cancel
}
