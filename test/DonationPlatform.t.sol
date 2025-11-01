// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DonationPlatform} from "../src/DonationPlatform.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DonationPlatformTest is Test {
    DonationPlatform public donationPlatform;
    
    // Mock cUSD token address (will use a mock in tests)
    address public mockCUSD;
    address public campaignCreator = address(1);
    address public donor1 = address(2);
    address public donor2 = address(3);
    address public donor3 = address(4);
    
    // Mock ERC20 for testing
    MockERC20 public cUSD;
    
    uint256 constant GOAL = 1000 * 10**18; // 1000 cUSD
    uint256 constant DONATION_AMOUNT = 100 * 10**18; // 100 cUSD
    
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goal,
        uint256 deadline
    );
    
    event DonationReceived(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        uint256 timestamp
    );
    
    event GoalReached(
        uint256 indexed campaignId,
        uint256 raised,
        uint256 timestamp
    );

    function setUp() public {
        // Deploy mock cUSD token
        cUSD = new MockERC20("Celo Dollar", "cUSD", 18);
        mockCUSD = address(cUSD);
        
        // Deploy donation platform
        donationPlatform = new DonationPlatform(mockCUSD);
        
        // Give test accounts cUSD
        cUSD.mint(campaignCreator, 10000 * 10**18);
        cUSD.mint(donor1, 10000 * 10**18);
        cUSD.mint(donor2, 10000 * 10**18);
        cUSD.mint(donor3, 10000 * 10**18);
    }

    function test_CreateCampaign() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        
        vm.expectEmit(true, true, false, false);
        emit CampaignCreated(1, campaignCreator, "Test Campaign", GOAL, deadline);
        
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "This is a test campaign",
            GOAL,
            deadline
        );
        
        assertEq(campaignId, 1);
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.creator, campaignCreator);
        assertEq(campaign.goal, GOAL);
        assertEq(campaign.raised, 0);
        assertEq(campaign.active, true);
        assertEq(campaign.goalReached, false);
        assertEq(campaign.disbursed, false);
    }

    function test_DonateToCampaign() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        
        // Approve and donate
        vm.prank(donor1);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT);
        
        vm.prank(donor1);
        vm.expectEmit(true, true, false, false);
        emit DonationReceived(campaignId, donor1, DONATION_AMOUNT, block.timestamp);
        
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.raised, DONATION_AMOUNT);
        assertEq(campaign.donorCount, 1);
        assertEq(donationPlatform.getDonationByDonor(campaignId, donor1), DONATION_AMOUNT);
    }

    function test_MultipleDonations() public {
        vm.startPrank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        vm.stopPrank();
        
        // First donation
        vm.startPrank(donor1);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT * 10); // Approve enough
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
        vm.stopPrank();
        
        // Second donation from different donor
        vm.startPrank(donor2);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT * 10);
        donationPlatform.donate(campaignId, DONATION_AMOUNT * 2);
        vm.stopPrank();
        
        // Third donation from first donor again
        vm.startPrank(donor1);
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
        vm.stopPrank();
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.raised, DONATION_AMOUNT * 4);
        assertEq(campaign.donorCount, 2); // Only 2 unique donors
        assertEq(donationPlatform.getDonationByDonor(campaignId, donor1), DONATION_AMOUNT * 2);
        assertEq(donationPlatform.getDonationByDonor(campaignId, donor2), DONATION_AMOUNT * 2);
    }

    function test_GoalReached() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        
        // Donate until goal is reached
        uint256 amount = GOAL / 10; // 10% each time
        
        for (uint i = 0; i < 10; i++) {
            address donor = address(uint160(100 + i));
            cUSD.mint(donor, amount);
            vm.prank(donor);
            cUSD.approve(address(donationPlatform), amount);
            vm.prank(donor);
            
            if (i == 9) {
                vm.expectEmit(true, false, false, false);
                emit GoalReached(campaignId, GOAL, block.timestamp);
            }
            
            donationPlatform.donate(campaignId, amount);
        }
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.goalReached, true);
        assertEq(campaign.raised, GOAL);
    }

    function test_AutoDisburse() public {
        vm.startPrank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        vm.stopPrank();
        
        // Reach goal
        vm.startPrank(donor1);
        cUSD.approve(address(donationPlatform), GOAL);
        donationPlatform.donate(campaignId, GOAL);
        vm.stopPrank();
        
        // Auto disburse
        uint256 creatorBalanceBefore = cUSD.balanceOf(campaignCreator);
        donationPlatform.autoDisburse(campaignId);
        uint256 creatorBalanceAfter = cUSD.balanceOf(campaignCreator);
        
        assertEq(creatorBalanceAfter - creatorBalanceBefore, GOAL);
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.disbursed, true);
        assertEq(campaign.active, false);
    }

    function test_ManualDisburse() public {
        vm.startPrank(campaignCreator);
        uint256 deadline = block.timestamp + 1 days; // Short deadline
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        vm.stopPrank();
        
        // Donate some amount (not reaching goal)
        vm.startPrank(donor1);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT);
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
        vm.stopPrank();
        
        // Fast forward past deadline
        vm.warp(deadline + 1);
        
        // Manual disburse by creator
        uint256 creatorBalanceBefore = cUSD.balanceOf(campaignCreator);
        vm.prank(campaignCreator);
        donationPlatform.manualDisburse(campaignId);
        uint256 creatorBalanceAfter = cUSD.balanceOf(campaignCreator);
        
        assertEq(creatorBalanceAfter - creatorBalanceBefore, DONATION_AMOUNT);
        
        DonationPlatform.Campaign memory campaign = donationPlatform.getCampaign(campaignId);
        assertEq(campaign.disbursed, true);
        assertEq(campaign.active, false);
    }

    function test_RevertDonateToEndedCampaign() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 1 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        
        // Fast forward past deadline
        vm.warp(deadline + 1);
        
        vm.prank(donor1);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT);
        vm.expectRevert(DonationPlatform.CampaignHasEnded.selector);
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
    }

    function test_RevertDonateZeroAmount() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        
        vm.prank(donor1);
        cUSD.approve(address(donationPlatform), 0);
        vm.expectRevert(DonationPlatform.ZeroAmount.selector);
        donationPlatform.donate(campaignId, 0);
    }

    function test_RevertAutoDisburseBeforeGoal() public {
        vm.startPrank(campaignCreator);
        uint256 deadline = block.timestamp + 30 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        vm.stopPrank();
        
        // Donate less than goal
        vm.startPrank(donor1);
        cUSD.approve(address(donationPlatform), DONATION_AMOUNT);
        donationPlatform.donate(campaignId, DONATION_AMOUNT);
        vm.stopPrank();
        
        vm.expectRevert(DonationPlatform.GoalNotReached.selector);
        donationPlatform.autoDisburse(campaignId);
    }

    function test_RevertManualDisburseByNonCreator() public {
        vm.prank(campaignCreator);
        uint256 deadline = block.timestamp + 1 days;
        uint256 campaignId = donationPlatform.createCampaign(
            "Test Campaign",
            "Description",
            GOAL,
            deadline
        );
        
        vm.warp(deadline + 1);
        
        vm.prank(donor1);
        vm.expectRevert(DonationPlatform.OnlyCreator.selector);
        donationPlatform.manualDisburse(campaignId);
    }
}

// Mock ERC20 token for testing
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[from] >= amount, "Insufficient balance");
        
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}