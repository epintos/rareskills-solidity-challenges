// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { StakeTogether } from "src/StakeTogether.sol";

contract StakeTogetherTest is Test {
    StakeTogether stakeTogetherContract;
    ERC20Mock erc20Token;
    uint256 constant CONTRACT_INITIAL_SUPPLY = 1_000_000;
    uint256 constant USER_INITIAL_SUPPLY = 5000;
    uint256 constant STAKING_START = 1 days;
    uint256 constant STAKING_END = 7 days + STAKING_START;
    uint256 constant REWARDS_PORTION = 20; // TODO
    address DEPLOYER = makeAddr("DEPLOYER");
    address USER = makeAddr("USER");

    /// EVENTS
    event StakingBeginDateSet(
        address indexed owner, uint256 beginDateTimestamp, uint256 endDateTimestamp, uint256 rewardsPortion
    );

    function setUp() public {
        erc20Token = new ERC20Mock();
        vm.prank(DEPLOYER);
        stakeTogetherContract = new StakeTogether(address(erc20Token));
        erc20Token.mint(address(stakeTogetherContract), CONTRACT_INITIAL_SUPPLY);
        erc20Token.mint(USER, USER_INITIAL_SUPPLY);
    }

    // constructor
    function testConstructorSetsOwner() public view {
        assertEq(address(stakeTogetherContract.owner()), DEPLOYER);
    }

    function testConstructorSetsERC20Token() public view {
        assertEq(address(stakeTogetherContract.getERC20TokenAddress()), address(erc20Token));
    }

    // setUpStaking
    function testSetUpStakingRevertsIfDatesAreInvalid() public {
        vm.prank(DEPLOYER);
        vm.expectRevert(StakeTogether.StakeTogether__EndDateCannotBeBeforeBeginDate.selector);
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_END, block.timestamp, REWARDS_PORTION);
    }

    function testSetUpStakingRevertsIfBeginDateIsInThePast() public {
        vm.prank(DEPLOYER);
        vm.expectRevert(StakeTogether.StakeTogether__BeginDateCannotBeInThePast.selector);
        stakeTogetherContract.setUpStaking(block.timestamp - 1, block.timestamp + STAKING_END, REWARDS_PORTION);
    }

    function testSetUpStakingRevertsIfInitialSupplyIsZero() public {
        erc20Token.burn(address(stakeTogetherContract), CONTRACT_INITIAL_SUPPLY);
        vm.prank(DEPLOYER);
        vm.expectRevert(StakeTogether.StakeTogether__NoTokensForRewards.selector);
        stakeTogetherContract.setUpStaking(
            block.timestamp + STAKING_START, block.timestamp + STAKING_END, REWARDS_PORTION
        );
    }

    function testSetUpStakingCreatesStaking() public {
        vm.prank(DEPLOYER);
        stakeTogetherContract.setUpStaking(
            block.timestamp + STAKING_START, block.timestamp + STAKING_END, REWARDS_PORTION
        );
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        assertEq(staking.active, true);
        assertEq(staking.amount, 0);
        assertEq(staking.beginDateTimestamp, block.timestamp + STAKING_START);
        assertEq(staking.endDateTimestamp, block.timestamp + STAKING_END);
        assertEq(staking.rewardsPortion, REWARDS_PORTION);
        assertEq(staking.initialSupply, CONTRACT_INITIAL_SUPPLY);
    }

    function testSetUpStakingEmitsEvent() public {
        vm.prank(DEPLOYER);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit StakingBeginDateSet(
            DEPLOYER, block.timestamp + STAKING_START, block.timestamp + STAKING_END, REWARDS_PORTION
        );
        stakeTogetherContract.setUpStaking(
            block.timestamp + STAKING_START, block.timestamp + STAKING_END, REWARDS_PORTION
        );
    }
}
