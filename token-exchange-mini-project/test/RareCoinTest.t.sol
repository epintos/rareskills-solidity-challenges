// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { SkillsCoin } from "src/SkillsCoin.sol";
import { RareCoin } from "src/RareCoin.sol";

contract RareCoinTest is Test {
    SkillsCoin skillsCoin;
    RareCoin rareCoin;
    address USER = makeAddr("USER");
    uint256 INITIAL_USER_BALANCE = 10 ether;
    uint256 INITIAL_SKILL_COIN_BALANCE = 1 ether;

    function setUp() public {
        skillsCoin = new SkillsCoin();
        rareCoin = new RareCoin(address(skillsCoin));
        vm.deal(USER, INITIAL_USER_BALANCE);

        vm.prank(USER);
        skillsCoin.mint(INITIAL_SKILL_COIN_BALANCE);
    }

    // trade
    function testTradeTransfersSkillsCoinToRareCoin(uint256 amountToTrade) public {
        amountToTrade = bound(amountToTrade, 0, INITIAL_SKILL_COIN_BALANCE);
        uint256 userInitialSkillsCoinBalance = skillsCoin.balanceOf(USER);
        uint256 userInitialRareCoinBalance = rareCoin.balanceOf(USER);
        uint256 rareCoinInitialSkillsCoinBalance = skillsCoin.balanceOf(address(rareCoin));
        vm.startPrank(USER);
        skillsCoin.approve(address(rareCoin), amountToTrade);
        rareCoin.trade(amountToTrade);
        vm.stopPrank();

        uint256 userSkillsCoinBalance = skillsCoin.balanceOf(USER);
        uint256 userRareCoinBalance = rareCoin.balanceOf(USER);
        uint256 rareCoinSkillsCoinBalance = skillsCoin.balanceOf(address(rareCoin));
        assertEq(userSkillsCoinBalance, userInitialSkillsCoinBalance - amountToTrade);
        assertEq(userRareCoinBalance, userInitialRareCoinBalance + amountToTrade);
        assertEq(rareCoinSkillsCoinBalance, rareCoinInitialSkillsCoinBalance + amountToTrade);
    }
}
