// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { Test } from "forge-std/Test.sol";
import { TokenVestingContract } from "src/TokenVestingContract.sol";

contract TokenVestingContractTest is Test {
    TokenVestingContract tokenVestingContract;
    address PAYER = makeAddr("PAYER");
    address RECEIVER = makeAddr("RECEIVER");
    ERC20Mock token;
    uint256 constant PAYER_INITIAL_TOKEN_BALANCE = 100 ether;
    uint256 constant WITHDRAW_RATE = 5;

    event Deposit(address indexed payer, address indexed user, uint256 amount, uint256 withdrawRate);

    function setUp() public {
        token = new ERC20Mock();
        tokenVestingContract = new TokenVestingContract();

        token.mint(PAYER, PAYER_INITIAL_TOKEN_BALANCE);
    }

    // deposit
    function testDepositAmountCannotBeZero() public {
        vm.prank(PAYER);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__AmountCannotBeZero.selector);
        tokenVestingContract.deposit(address(token), RECEIVER, 0, WITHDRAW_RATE);
    }

    function testDepositFailsIfAgreementAlreadyExists(uint256 amount) public {
        amount = bound(amount, 1, PAYER_INITIAL_TOKEN_BALANCE);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, WITHDRAW_RATE);
        vm.expectRevert(TokenVestingContract.TokenVestingContract__UserAlreadyHasAgreement.selector);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, WITHDRAW_RATE);
        vm.stopPrank();
    }

    function testDepositCreatesAgreement(uint256 amount) public {
        amount = bound(amount, 1, PAYER_INITIAL_TOKEN_BALANCE);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, WITHDRAW_RATE);
        vm.stopPrank();

        assertEq(token.balanceOf(address(tokenVestingContract)), amount);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).initialTotalTokens, amount);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).tokensLeftToWithdraw, amount);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).lastWithdraw, block.timestamp);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).withdrawRate, WITHDRAW_RATE);
        assertEq(tokenVestingContract.getAgreement(PAYER, RECEIVER).token, address(token));
    }

    function testDepositEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, PAYER_INITIAL_TOKEN_BALANCE);

        vm.startPrank(PAYER);
        token.approve(address(tokenVestingContract), amount);
        vm.expectEmit(true, true, false, false, address(tokenVestingContract));
        emit Deposit(PAYER, RECEIVER, amount, WITHDRAW_RATE);
        tokenVestingContract.deposit(address(token), RECEIVER, amount, WITHDRAW_RATE);
        vm.stopPrank();
    }
}
