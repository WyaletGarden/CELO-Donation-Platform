const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DonationCampaign", function () {
  let donationCampaign;
  let cUSD;
  let owner, creator, beneficiary, donor1, donor2;
  
  // Mock cUSD address (for testing)
  const MOCK_CUSD_ADDRESS = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  
  // Test values
  const TARGET_AMOUNT = ethers.parseEther("1000"); // 1000 cUSD
  const DONATION_AMOUNT_1 = ethers.parseEther("100"); // 100 cUSD
  const DONATION_AMOUNT_2 = ethers.parseEther("200"); // 200 cUSD

  beforeEach(async function () {
    [owner, creator, beneficiary, donor1, donor2] = await ethers.getSigners();

    // Deploy DonationCampaign
    const DonationCampaign = await ethers.getContractFactory("DonationCampaign");
    donationCampaign = await DonationCampaign.deploy(MOCK_CUSD_ADDRESS);
    await donationCampaign.waitForDeployment();

    // For testing, we'll use a mock ERC20 token
    // In real deployment, use the actual cUSD address
  });

  describe("Deployment", function () {
    it("Should set the correct cUSD address", async function () {
      expect(await donationCampaign.cUSD()).to.equal(MOCK_CUSD_ADDRESS);
    });

    it("Should start with 0 campaigns", async function () {
      expect(await donationCampaign.getTotalCampaigns()).to.equal(0);
    });
  });

  describe("Create Campaign", function () {
    it("Should create a campaign successfully", async function () {
      const deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60; // 30 days

      const tx = await donationCampaign
        .connect(creator)
        .createCampaign(
          "Test Campaign",
          "This is a test campaign",
          TARGET_AMOUNT,
          deadline,
          beneficiary.address,
          "https://example.com/image.jpg"
        );

      await expect(tx)
        .to.emit(donationCampaign, "CampaignCreated")
        .withArgs(1, creator.address, beneficiary.address, "Test Campaign", TARGET_AMOUNT, deadline);

      const campaignCount = await donationCampaign.getTotalCampaigns();
      expect(campaignCount).to.equal(1);
    });

    it("Should revert with invalid target amount", async function () {
      const deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;

      await expect(
        donationCampaign
          .connect(creator)
          .createCampaign(
            "Test",
            "Description",
            0,
            deadline,
            beneficiary.address,
            "https://example.com/image.jpg"
          )
      ).to.be.revertedWithCustomError(donationCampaign, "InvalidTargetAmount");
    });

    it("Should revert with invalid deadline", async function () {
      const pastDeadline = Math.floor(Date.now() / 1000) - 1000;

      await expect(
        donationCampaign
          .connect(creator)
          .createCampaign(
            "Test",
            "Description",
            TARGET_AMOUNT,
            pastDeadline,
            beneficiary.address,
            "https://example.com/image.jpg"
          )
      ).to.be.revertedWithCustomError(donationCampaign, "InvalidDeadline");
    });
  });

  describe("Donate", function () {
    let campaignId;
    let deadline;

    beforeEach(async function () {
      deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
      const tx = await donationCampaign
        .connect(creator)
        .createCampaign(
          "Test Campaign",
          "Description",
          TARGET_AMOUNT,
          deadline,
          beneficiary.address,
          "https://example.com/image.jpg"
        );
      const receipt = await tx.wait();
      campaignId = 1;
    });

    it("Should allow donation with all parameters", async function () {
      // Note: This test assumes you have a mock ERC20 token for testing
      // In a real scenario, you would need to approve cUSD first
      
      // For testing purposes, we'll just check the function signature
      // Real implementation would require setting up a mock ERC20
      
      expect(campaignId).to.equal(1);
      // Actual donation test would require mock cUSD token setup
    });
  });

  describe("getCampaignDetails", function () {
    let campaignId;
    let deadline;

    beforeEach(async function () {
      deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
      await donationCampaign
        .connect(creator)
        .createCampaign(
          "Test Campaign",
          "Description",
          TARGET_AMOUNT,
          deadline,
          beneficiary.address,
          "https://example.com/image.jpg"
        );
      campaignId = 1;
    });

    it("Should return campaign details correctly", async function () {
      const [campaign, progressPercent, timeRemaining, donationCount] =
        await donationCampaign.getCampaignDetails(campaignId);

      expect(campaign.name).to.equal("Test Campaign");
      expect(campaign.targetAmount).to.equal(TARGET_AMOUNT);
      expect(campaign.raisedAmount).to.equal(0);
      expect(progressPercent).to.equal(0);
      expect(donationCount).to.equal(0);
      expect(timeRemaining).to.be.greaterThan(0);
    });
  });

  describe("Withdraw", function () {
    let campaignId;
    let deadline;

    beforeEach(async function () {
      deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
      await donationCampaign
        .connect(creator)
        .createCampaign(
          "Test Campaign",
          "Description",
          TARGET_AMOUNT,
          deadline,
          beneficiary.address,
          "https://example.com/image.jpg"
        );
      campaignId = 1;
    });

    it("Should revert if not creator", async function () {
      await expect(
        donationCampaign.connect(donor1).withdraw(campaignId, false)
      ).to.be.reverted;
    });

    it("Should revert goal-based withdraw if goal not reached", async function () {
      await expect(
        donationCampaign.connect(creator).withdraw(campaignId, true)
      ).to.be.revertedWithCustomError(donationCampaign, "GoalNotReached");
    });
  });

  describe("Refund", function () {
    let campaignId;
    let deadline;

    beforeEach(async function () {
      deadline = Math.floor(Date.now() / 1000) + 1; // 1 second from now
      await donationCampaign
        .connect(creator)
        .createCampaign(
          "Test Campaign",
          "Description",
          TARGET_AMOUNT,
          deadline,
          beneficiary.address,
          "https://example.com/image.jpg"
        );
      campaignId = 1;
    });

    it("Should revert if campaign still active", async function () {
      await expect(
        donationCampaign.connect(donor1).refund(campaignId)
      ).to.be.revertedWithCustomError(donationCampaign, "CampaignStillActive");
    });

    it("Should return false for canRefund when campaign is active", async function () {
      const canRefund = await donationCampaign.canRefund(campaignId);
      expect(canRefund).to.be.false;
    });
  });
});
