// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";
import { SkillsCoin } from "src/SkillsCoin.sol";

contract SkillsCoinTest is Test {
    SkillsCoin skillsCoin;
    address USER = makeAddr("USER");
    uint256 INITIAL_USER_BALANCE = 10 ether;

    function setUp() public {
        skillsCoin = new SkillsCoin();
        vm.deal(USER, INITIAL_USER_BALANCE);
    }

    // mint
    function testMintCanBeCalledByAnyUser(uint256 amountToMint) public {
        amountToMint = bound(amountToMint, 1, type(uint96).max);
        uint256 userInitialBalance = skillsCoin.balanceOf(USER);
        vm.prank(USER);
        skillsCoin.mint(amountToMint);
        uint256 userBalance = skillsCoin.balanceOf(USER);
        assertEq(userBalance, userInitialBalance + amountToMint);
    }

    // burn
    function testBurnCanBeCalledByAnyUser(uint256 amountToMint) public {
        amountToMint = bound(amountToMint, 1, type(uint96).max);
        uint256 userInitialBalance = skillsCoin.balanceOf(USER);
        vm.prank(USER);
        skillsCoin.mint(amountToMint);
        vm.prank(USER);
        skillsCoin.burn(amountToMint);
        uint256 userBalance = skillsCoin.balanceOf(USER);
        assertEq(userBalance, userInitialBalance);
    }
}
