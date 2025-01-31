// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { StakeTogether } from "src/StakeTogether.sol";

contract StakeTogetherTest is Test {
    StakeTogether stakeTogetherContract;
    ERC20Mock erc20Token;
    uint256 constant CONTRACT_INITIAL_SUPPLY = 10 ether;
    uint256 constant USER_INITIAL_SUPPLY = 3 ether;
    uint256 constant STAKING_START = 1 days;
    uint256 constant STAKING_END = 7 days + STAKING_START;
    uint256 constant MININUM_STAKING_AMOUNT = 1e8;
    address DEPLOYER = makeAddr("DEPLOYER");
    address USER = makeAddr("USER");
    address USER_2 = makeAddr("USER_2");

    /// EVENTS
    event StakingBeginDateSet(address indexed owner, uint256 beginDateTimestamp, uint256 endDateTimestamp);
    event Staked(address indexed user, uint256 amount);
    event UnStaked(address indexed user, uint256 amount, uint256 rewards);

    function setUp() public {
        erc20Token = new ERC20Mock();
        vm.prank(DEPLOYER);
        stakeTogetherContract = new StakeTogether(address(erc20Token));
        erc20Token.mint(address(stakeTogetherContract), CONTRACT_INITIAL_SUPPLY);
        erc20Token.mint(USER, USER_INITIAL_SUPPLY);
        erc20Token.mint(USER_2, USER_INITIAL_SUPPLY);
    }

    modifier stakeCreated(uint256 beginDays, uint256 endDays) {
        beginDays = bound(beginDays, 1 days, 20 days); // When the stake starts
        endDays = bound(endDays, 7 days, 30 days); // How long the stake lasts
        vm.prank(DEPLOYER);
        stakeTogetherContract.setUpStaking(block.timestamp + beginDays, block.timestamp + beginDays + endDays);
        _;
    }

    modifier userStaked(uint256 amount) {
        vm.startPrank(USER);
        amount = bound(amount, MININUM_STAKING_AMOUNT, USER_INITIAL_SUPPLY);
        erc20Token.approve(address(stakeTogetherContract), amount);
        stakeTogetherContract.stake(amount);
        vm.stopPrank();
        _;
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
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_END, block.timestamp);
    }

    function testSetUpStakingRevertsIfBeginDateIsInThePast() public {
        vm.prank(DEPLOYER);
        vm.expectRevert(StakeTogether.StakeTogether__BeginDateCannotBeInThePast.selector);
        stakeTogetherContract.setUpStaking(block.timestamp - 1, block.timestamp + STAKING_END);
    }

    function testSetUpStakingRevertsIfInitialSupplyIsZero() public {
        erc20Token.burn(address(stakeTogetherContract), CONTRACT_INITIAL_SUPPLY);
        vm.prank(DEPLOYER);
        vm.expectRevert(StakeTogether.StakeTogether__NoTokensForRewards.selector);
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_START, block.timestamp + STAKING_END);
    }

    function testSetUpStakingCreatesStaking() public {
        vm.prank(DEPLOYER);
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_START, block.timestamp + STAKING_END);
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        assertEq(staking.active, true);
        assertEq(staking.amount, 0);
        assertEq(staking.beginDateTimestamp, block.timestamp + STAKING_START);
        assertEq(staking.endDateTimestamp, block.timestamp + STAKING_END);
        assertEq(staking.initialSupply, CONTRACT_INITIAL_SUPPLY);
    }

    function testSetUpStakingEmitsEvent() public {
        vm.prank(DEPLOYER);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit StakingBeginDateSet(DEPLOYER, block.timestamp + STAKING_START, block.timestamp + STAKING_END);
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_START, block.timestamp + STAKING_END);
    }

    // stake
    function testStakeRevertsIfStakingIsNotActive() public {
        vm.prank(USER);
        vm.expectRevert(StakeTogether.StakeTogether__StakingNotActive.selector);
        stakeTogetherContract.stake(0);
    }

    function testStakeRevertsIfStakesAfterStakingBeginDay(
        uint256 beginDays,
        uint256 endDays
    )
        public
        stakeCreated(beginDays, endDays)
    {
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        vm.warp(staking.beginDateTimestamp + 1 seconds);
        vm.prank(USER);
        vm.expectRevert(StakeTogether.StakeTogether__StakingPeriodAlreadyStarted.selector);
        stakeTogetherContract.stake(USER_INITIAL_SUPPLY);
    }

    function testStakeRevertsIfStakesAfterStakingLastDay(
        uint256 beginDays,
        uint256 endDays
    )
        public
        stakeCreated(beginDays, endDays)
    {
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        vm.warp(staking.endDateTimestamp + 1 seconds);
        vm.prank(USER);
        vm.expectRevert(StakeTogether.StakeTogether__StakingPeriodEnded.selector);
        stakeTogetherContract.stake(USER_INITIAL_SUPPLY);
    }

    function testStakeStakesUserAmount(
        uint256 beginDays,
        uint256 endDays,
        uint256 stakingAmount
    )
        public
        stakeCreated(beginDays, endDays)
    {
        vm.startPrank(USER);
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        stakingAmount = bound(stakingAmount, MININUM_STAKING_AMOUNT, USER_INITIAL_SUPPLY / 2);
        uint256 userInitialSupply = erc20Token.balanceOf(USER);
        erc20Token.approve(address(stakeTogetherContract), stakingAmount * 2);
        stakeTogetherContract.stake(stakingAmount);
        stakeTogetherContract.stake(stakingAmount);

        staking = stakeTogetherContract.getStaking();
        assertEq(stakeTogetherContract.getUserStakingAmount(USER), stakingAmount * 2);
        assertEq(staking.amount, stakingAmount * 2);
        assertEq(erc20Token.balanceOf(address(stakeTogetherContract)), staking.initialSupply + stakingAmount * 2);
        assertEq(erc20Token.balanceOf(USER), userInitialSupply - stakingAmount * 2);
        vm.stopPrank();
    }

    function testStakeEmitsEvent(
        uint256 beginDays,
        uint256 endDays,
        uint256 stakingAmount
    )
        public
        stakeCreated(beginDays, endDays)
    {
        vm.startPrank(USER);
        stakingAmount = bound(stakingAmount, MININUM_STAKING_AMOUNT, USER_INITIAL_SUPPLY);
        erc20Token.approve(address(stakeTogetherContract), stakingAmount);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit Staked(USER, stakingAmount);
        stakeTogetherContract.stake(stakingAmount);
        vm.stopPrank();
    }

    // unstake
    function testUnstakeRevertsIfStakingIsNotActive() public {
        vm.prank(USER);
        vm.expectRevert(StakeTogether.StakeTogether__StakingNotActive.selector);
        stakeTogetherContract.unstake();
    }

    function testUnstakeRevertsIfStakingAmountIsZero(
        uint256 beginDays,
        uint256 endDays
    )
        public
        stakeCreated(beginDays, endDays)
    {
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        vm.warp(staking.beginDateTimestamp + 1 seconds);
        vm.prank(USER);
        vm.expectRevert(StakeTogether.StakeTogether__NoStakedAmount.selector);
        stakeTogetherContract.unstake();
    }

    function testUnstakeDoesNotTransferRewardsIfUnstakedBeforeEndDate(
        uint256 beginDays,
        uint256 endDays,
        uint256 stakingAmount
    )
        public
        stakeCreated(beginDays, endDays)
        userStaked(stakingAmount)
    {
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        uint256 userInitialSupply = erc20Token.balanceOf(USER);
        uint256 contractInitialSupply = erc20Token.balanceOf(address(stakeTogetherContract));
        vm.warp(staking.endDateTimestamp - 1 seconds);
        uint256 userInitialStaking = stakeTogetherContract.getUserStakingAmount(USER);
        vm.prank(USER);
        stakeTogetherContract.unstake();

        staking = stakeTogetherContract.getStaking();
        assertEq(staking.amount, 0);
        assertEq(stakeTogetherContract.getUserStakingAmount(USER), 0);
        assertEq(erc20Token.balanceOf(USER), userInitialSupply + userInitialStaking);
        assertEq(erc20Token.balanceOf(address(stakeTogetherContract)), contractInitialSupply - userInitialStaking);
    }

    function testUnstakeEmitsEvent(
        uint256 beginDays,
        uint256 endDays,
        uint256 stakingAmount
    )
        public
        stakeCreated(beginDays, endDays)
        userStaked(stakingAmount)
    {
        uint256 userInitialStaking = stakeTogetherContract.getUserStakingAmount(USER);
        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        vm.warp(staking.endDateTimestamp - 1 seconds);
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit UnStaked(USER, userInitialStaking, 0);
        stakeTogetherContract.unstake();
    }

    // Tests challenge example
    // Alice staked 5_000
    // Total staking is 25_000
    // Initial Supply is 1_000_000
    // Alice's Rewards Portion is 20% (0.2e18)
    // Rewards = 0.2e18 * 1_000_000 / 1e18 = 200_000
    function testUnstakeTransfersRewards() public {
        erc20Token.burn(address(stakeTogetherContract), CONTRACT_INITIAL_SUPPLY);
        erc20Token.mint(address(stakeTogetherContract), 1_000_000);
        vm.prank(DEPLOYER);
        stakeTogetherContract.setUpStaking(block.timestamp + STAKING_START, block.timestamp + STAKING_END);

        vm.startPrank(USER);
        erc20Token.approve(address(stakeTogetherContract), 5000);
        stakeTogetherContract.stake(5000);
        vm.stopPrank();

        vm.startPrank(USER_2);
        erc20Token.approve(address(stakeTogetherContract), 20_000);
        stakeTogetherContract.stake(20_000);
        vm.stopPrank();

        StakeTogether.Staking memory staking = stakeTogetherContract.getStaking();
        assertEq(staking.amount, 25_000);
        assertEq(stakeTogetherContract.getUserStakingAmount(USER), 5000);
        assertEq(stakeTogetherContract.getUserStakingAmount(USER_2), 20_000);

        vm.warp(block.timestamp + STAKING_END + 1 seconds);

        uint256 userInitialSupply = erc20Token.balanceOf(USER);
        uint256 contractInitialSupply = erc20Token.balanceOf(address(stakeTogetherContract));
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit UnStaked(USER, 5000, 200_000);
        stakeTogetherContract.unstake();
        assertEq(erc20Token.balanceOf(USER), userInitialSupply + 5000 + 200_000);
        assertEq(erc20Token.balanceOf(address(stakeTogetherContract)), contractInitialSupply - 5000 - 200_000);
        assertEq(stakeTogetherContract.getUserStakingAmount(USER), 0);

        uint256 user2InitialSupply = erc20Token.balanceOf(USER_2);
        vm.prank(USER_2);
        vm.expectEmit(true, false, false, false, address(stakeTogetherContract));
        emit UnStaked(USER_2, 20_000, 800_000);
        stakeTogetherContract.unstake();
        assertEq(erc20Token.balanceOf(USER_2), user2InitialSupply + 20_000 + 800_000);
        assertEq(erc20Token.balanceOf(address(stakeTogetherContract)), 0);
        assertEq(stakeTogetherContract.getUserStakingAmount(USER_2), 0);
    }
}
