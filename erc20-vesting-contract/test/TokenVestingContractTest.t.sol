// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { TokenVestingContract } from "src/TokenVestingContract.sol";

contract TokenVestingContractTest is Test {
    TokenVestingContract tokenVestingContract;
    address PAYER = makeAddr("PAYER");
    address RECEIVER = makeAddr("RECEIVER");
    ERC20Mock token;
    uint256 constant PAYER_INITIAL_TOKEN_BALANCE = 100 ether;
    uint256 constant DAYS_TO_VEST_ALL_TOKENS = 10;

    event Deposit(address indexed payer, address indexed user, uint256 amount, uint256 withdrawRate);
    event Withdraw(address indexed payer, address indexed user, uint256 amountWithdraw, uint256 tokensLeftToWithdraw);

    function setUp() public {
        token = new ERC20Mock();
        tokenVestingContract = new TokenVestingContract();

        token.mint(PAYER, PAYER_INITIAL_TOKEN_BALANCE);
    }

    function depositRandomAmount(
        uint256 amount,
        uint256 daysToVestAllTokens,
        uint256 timePassed
    )
        public
        returns (uint256, uint256, uint256)
    {
        amount = bound(amount, 1e5, PAYER_INITIAL_TOKEN_BALANCE);
        daysToVestAllTokens = bound(daysToVestAllTokens, 5, 365 * 5);
        timePassed = bound(timePassed, 1, daysToVestAllTokens / 2);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, daysToVestAllTokens);
        vm.stopPrank();
        return (amount, daysToVestAllTokens, timePassed);
    }

    // deposit
    function testDepositAmountCannotBeZero() public {
        vm.prank(PAYER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__AmountCannotBeZero.selector);
        tokenVestingContract.deposit(address(token), RECEIVER, 0, DAYS_TO_VEST_ALL_TOKENS);
    }

    function testDepositTokenAdressCannotBeZero() public {
        vm.prank(PAYER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__AddressCanotBeZero.selector);
        tokenVestingContract.deposit(address(0), RECEIVER, 1 ether, DAYS_TO_VEST_ALL_TOKENS);
    }

    function testDepositFailsIfAgreementAlreadyExists(uint256 amount) public {
        amount = bound(amount, 1, PAYER_INITIAL_TOKEN_BALANCE);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, DAYS_TO_VEST_ALL_TOKENS);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__UserAlreadyHasAgreement.selector);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, DAYS_TO_VEST_ALL_TOKENS);
        vm.stopPrank();
    }

    function testDepositCreatesAgreement(uint256 amount) public {
        (amount,,) = depositRandomAmount(amount, DAYS_TO_VEST_ALL_TOKENS, 0);

        assertEq(token.balanceOf(address(tokenVestingContract)), amount);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).initialTotalTokensInWei, amount);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).tokensWithdrawnInWei, 0);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).startTimestamp, block.timestamp);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).vestingDays, DAYS_TO_VEST_ALL_TOKENS);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).token, address(token));
    }

    function testDepositEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, PAYER_INITIAL_TOKEN_BALANCE);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        vm.expectEmit(true, true, false, false, address(tokenVestingContract));
        emit Deposit(PAYER, RECEIVER, amount, DAYS_TO_VEST_ALL_TOKENS);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, DAYS_TO_VEST_ALL_TOKENS);
        vm.stopPrank();
    }

    // withdraw
    function testWithdrawFailsIfNoAgreementExists() public {
        vm.prank(PAYER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__UserDoesNotHaveAgreement.selector);
        tokenVestingContract.withdraw(RECEIVER);
    }

    function testWithdrawFailsIfNoTokensHaveVestedSinceLastWithdraw(uint256 amount) public {
        (amount,,) = depositRandomAmount(amount, DAYS_TO_VEST_ALL_TOKENS, 0);

        vm.prank(RECEIVER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__NotEnoughtTimeHasPassedToWithdraw.selector);
        tokenVestingContract.withdraw(PAYER);
    }

    function testWithdrawTranfersTheCorrectVestedAmount(
        uint256 amount,
        uint256 daysToVestAllTokens,
        uint256 timePassed
    )
        public
    {
        (amount, daysToVestAllTokens, timePassed) = depositRandomAmount(amount, daysToVestAllTokens, timePassed);

        vm.warp(block.timestamp + timePassed * 1 days);
        uint256 vestedAmount = tokenVestingContract.getTokensToWithdraw(PAYER, RECEIVER);
        uint256 initialBalance = token.balanceOf(RECEIVER);
        vm.startPrank(RECEIVER);
        tokenVestingContract.withdraw(PAYER);
        vm.stopPrank();

        uint256 balance = token.balanceOf(RECEIVER);
        TokenVestingContract.VestingAgreement memory agreement = tokenVestingContract.getAgreement(PAYER, RECEIVER);
        assertEq(agreement.tokensWithdrawnInWei, vestedAmount);
        assertEq(balance, initialBalance + vestedAmount);
    }

    function testWithdrawEmitsEvent(uint256 amount, uint256 daysToVestAllTokens, uint256 timePassed) public {
        (amount, daysToVestAllTokens, timePassed) = depositRandomAmount(amount, daysToVestAllTokens, timePassed);

        vm.warp(block.timestamp + timePassed * 1 days);
        uint256 vestedAmount = tokenVestingContract.getTokensToWithdraw(PAYER, RECEIVER);
        TokenVestingContract.VestingAgreement memory agreement = tokenVestingContract.getAgreement(PAYER, RECEIVER);
        vm.startPrank(RECEIVER);
        vm.expectEmit(true, true, false, false, address(tokenVestingContract));
        emit Withdraw(PAYER, RECEIVER, vestedAmount, agreement.initialTotalTokensInWei - vestedAmount);
        tokenVestingContract.withdraw(PAYER);
        vm.stopPrank();
    }

    function testWithdrawRemovesAgreementAfterWithdrawIsComplete(
        uint256 amount,
        uint256 daysToVestAllTokens,
        uint256 timePassed
    )
        public
    {
        (amount, daysToVestAllTokens, timePassed) = depositRandomAmount(amount, daysToVestAllTokens, timePassed);

        vm.warp(block.timestamp + daysToVestAllTokens * 1 days);
        vm.prank(RECEIVER);
        tokenVestingContract.withdraw(PAYER);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).token, address(0));

        vm.prank(RECEIVER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__UserDoesNotHaveAgreement.selector);
        tokenVestingContract.withdraw(PAYER);
    }

    // getTokensToWithdraw
    function testGetTokensToWithdraw() public {
        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), 1 ether);
        tokenVestingContract.deposit(address(token), RECEIVER, 1 ether, 10);
        vm.stopPrank();

        uint256 vestedAmount = tokenVestingContract.getTokensToWithdraw(PAYER, RECEIVER);
        assertEq(vestedAmount, 0);

        vm.warp(block.timestamp + 5 days);
        vestedAmount = tokenVestingContract.getTokensToWithdraw(PAYER, RECEIVER);
        vm.prank(RECEIVER);
        tokenVestingContract.withdraw(PAYER);
        assertEq(vestedAmount, 1 ether / 2);

        vm.warp(block.timestamp + 5 days);
        vestedAmount = tokenVestingContract.getTokensToWithdraw(PAYER, RECEIVER);
        assertEq(vestedAmount, 1 ether / 2);
    }
}
