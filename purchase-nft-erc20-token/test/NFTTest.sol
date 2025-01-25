// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { DeployNFT } from "script/DeployNFT.s.sol";
import { Test } from "forge-std/Test.sol";
import { NFT } from "src/NFT.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract NFTTest is Test {
    NFT nftContract;
    uint256 constant NFT_PRICE = 1 ether;
    ERC20Mock tokenToPayWith;
    address USER = makeAddr("USER");

    function setUp() public {
        tokenToPayWith = new ERC20Mock();
        nftContract = new DeployNFT().run(NFT_PRICE, address(tokenToPayWith));
    }

    modifier mintedAndApprovedTokens() {
        vm.startPrank(USER);
        tokenToPayWith.mint(USER, NFT_PRICE);
        tokenToPayWith.approve(address(nftContract), NFT_PRICE);
        vm.stopPrank();
        _;
    }

    // constructor
    function testConstructorSetsPriceAndToken() public view {
        assertEq(nftContract.getPrice(), NFT_PRICE);
        assertEq(nftContract.getToken(), address(tokenToPayWith));
    }

    // mint
    function testMintFailsIfNotEnoughBalance() public {
        vm.prank(USER);
        vm.expectRevert(NFT.NFT__NotEnoughBalanceToPay.selector);
        nftContract.mint();
    }

    function testMintMintsNFTAndTransfersTokensToContract() public mintedAndApprovedTokens {
        uint256 initialUserTokenBalance = tokenToPayWith.balanceOf(USER);
        uint256 initialContractTokenBalance = tokenToPayWith.balanceOf(address(nftContract));
        vm.prank(USER);
        nftContract.mint();
        uint256 finalUserTokenBalance = tokenToPayWith.balanceOf(USER);
        uint256 finalContractTokenBalance = tokenToPayWith.balanceOf(address(nftContract));
        assertEq(finalUserTokenBalance, initialUserTokenBalance - NFT_PRICE);
        assertEq(finalContractTokenBalance, initialContractTokenBalance + NFT_PRICE);
        assertEq(nftContract.balanceOf(USER), 1);
        assertEq(nftContract.getTotalSupply(), 1);
    }

    // burn
    function testBurnFailsIfNotApprovedOrOwner() public mintedAndApprovedTokens {
        vm.prank(USER);
        nftContract.mint();
        vm.prank(makeAddr("USER2"));
        vm.expectRevert(NFT.NFT__NotApprovedOrNotOwner.selector);
        nftContract.burn(0);
    }

    function testBurnBurnsNFT() public mintedAndApprovedTokens {
        vm.startPrank(USER);
        nftContract.mint();
        nftContract.burn(0);
        vm.stopPrank();
        assertEq(nftContract.balanceOf(USER), 0);
    }
}
