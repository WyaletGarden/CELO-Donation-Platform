// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DonationPlatform
 * @notice Nền tảng quyên góp minh bạch trên blockchain Celo
 * @dev Cho phép tổ chức/cá nhân tạo chiến dịch, nhận quyên góp bằng cUSD, và giải ngân tự động/thủ công
 */
contract DonationPlatform {
    using SafeERC20 for IERC20;

    // cUSD token addresses
    // Alfajores: 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1
    // Mainnet: 0x765DE816845861e75A25fCA122bb6898B8B1282a
    IERC20 public immutable cUSD;
    
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 goal;           // Mục tiêu quyên góp (cUSD với 18 decimals)
        uint256 raised;         // Số tiền đã quyên góp
        uint256 deadline;       // Thời hạn kết thúc (timestamp)
        bool goalReached;       // Đã đạt mục tiêu chưa
        bool disbursed;         // Đã giải ngân chưa
        bool active;            // Chiến dịch còn hoạt động
        uint256 donorCount;     // Số người quyên góp
        uint256 createdAt;      // Thời điểm tạo
    }

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    // State variables
    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Donation[]) public campaignDonations;  // campaignId => donations
    mapping(uint256 => mapping(address => uint256)) public donationsByDonor;  // campaignId => donor => amount
    
    // Events
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
    
    event FundsDisbursed(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount,
        bool automatic,
        uint256 timestamp
    );
    
    event CampaignEnded(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 finalAmount,
        bool goalReached
    );

    // Errors
    error CampaignNotFound();
    error CampaignHasEnded();
    error GoalAlreadyReached();
    error GoalNotReached();
    error ZeroAmount();
    error InvalidGoal();
    error InvalidDeadline();
    error AlreadyDisbursed();
    error TransferFailed();
    error OnlyCreator();
    error CampaignStillActive();

    /**
     * @param _cUSDAddress Địa chỉ contract cUSD token
     */
    constructor(address _cUSDAddress) {
        require(_cUSDAddress != address(0), "Invalid cUSD address");
        cUSD = IERC20(_cUSDAddress);
    }

    /**
     * @notice Tạo chiến dịch quyên góp mới
     * @param _title Tiêu đề chiến dịch
     * @param _description Mô tả chiến dịch
     * @param _goal Mục tiêu quyên góp (cUSD với 18 decimals)
     * @param _deadline Thời hạn kết thúc (Unix timestamp)
     * @return campaignId ID của chiến dịch vừa tạo
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _deadline
    ) external returns (uint256) {
        if (_goal == 0) revert InvalidGoal();
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        campaignCount++;
        uint256 campaignId = campaignCount;

        campaigns[campaignId] = Campaign({
            id: campaignId,
            creator: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            raised: 0,
            deadline: _deadline,
            goalReached: false,
            disbursed: false,
            active: true,
            donorCount: 0,
            createdAt: block.timestamp
        });

        emit CampaignCreated(campaignId, msg.sender, _title, _goal, _deadline);
        return campaignId;
    }

    /**
     * @notice Quyên góp vào chiến dịch bằng cUSD
     * @param _campaignId ID của chiến dịch
     * @param _amount Số tiền quyên góp (cUSD với 18 decimals)
     */
    function donate(uint256 _campaignId, uint256 _amount) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (campaign.id == 0) revert CampaignNotFound();
        if (!campaign.active) revert CampaignHasEnded();
        if (block.timestamp > campaign.deadline) {
            campaign.active = false;
            revert CampaignHasEnded();
        }
        if (campaign.goalReached) revert GoalAlreadyReached();
        if (_amount == 0) revert ZeroAmount();

        // Transfer cUSD from donor to contract
        cUSD.safeTransferFrom(msg.sender, address(this), _amount);

        // Update campaign state
        if (donationsByDonor[_campaignId][msg.sender] == 0) {
            campaign.donorCount++;
        }
        
        donationsByDonor[_campaignId][msg.sender] += _amount;
        campaign.raised += _amount;

        // Record donation
        campaignDonations[_campaignId].push(Donation({
            donor: msg.sender,
            amount: _amount,
            timestamp: block.timestamp
        }));

        emit DonationReceived(_campaignId, msg.sender, _amount, block.timestamp);

        // Check if goal is reached
        if (campaign.raised >= campaign.goal && !campaign.goalReached) {
            campaign.goalReached = true;
            emit GoalReached(_campaignId, campaign.raised, block.timestamp);
        }
    }

    /**
     * @notice Giải ngân tự động khi đạt mục tiêu
     * @param _campaignId ID của chiến dịch
     */
    function autoDisburse(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (campaign.id == 0) revert CampaignNotFound();
        if (campaign.disbursed) revert AlreadyDisbursed();
        if (!campaign.goalReached) revert GoalNotReached();

        campaign.disbursed = true;
        campaign.active = false;
        
        uint256 amount = campaign.raised;
        
        // Transfer cUSD to campaign creator
        cUSD.safeTransfer(campaign.creator, amount);
        
        emit FundsDisbursed(_campaignId, campaign.creator, amount, true, block.timestamp);
        emit CampaignEnded(_campaignId, campaign.creator, amount, true);
    }

    /**
     * @notice Giải ngân thủ công bởi người tạo chiến dịch
     * @param _campaignId ID của chiến dịch
     * @dev Chỉ người tạo chiến dịch mới có thể giải ngân thủ công
     */
    function manualDisburse(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (campaign.id == 0) revert CampaignNotFound();
        if (msg.sender != campaign.creator) revert OnlyCreator();
        if (campaign.disbursed) revert AlreadyDisbursed();
        if (campaign.active && block.timestamp <= campaign.deadline) revert CampaignStillActive();

        campaign.disbursed = true;
        campaign.active = false;
        
        uint256 amount = campaign.raised;
        
        // Transfer cUSD to campaign creator
        cUSD.safeTransfer(campaign.creator, amount);
        
        emit FundsDisbursed(_campaignId, campaign.creator, amount, false, block.timestamp);
        emit CampaignEnded(_campaignId, campaign.creator, amount, campaign.goalReached);
    }

    /**
     * @notice Kết thúc chiến dịch (chỉ khi đã hết hạn)
     * @param _campaignId ID của chiến dịch
     */
    function endCampaign(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (campaign.id == 0) revert CampaignNotFound();
        if (!campaign.active) revert CampaignHasEnded();
        if (block.timestamp <= campaign.deadline) revert CampaignStillActive();

        campaign.active = false;
        emit CampaignEnded(_campaignId, campaign.creator, campaign.raised, campaign.goalReached);
    }

    // ============ View Functions ============

    /**
     * @notice Lấy thông tin chiến dịch
     */
    function getCampaign(uint256 _campaignId) external view returns (Campaign memory) {
        return campaigns[_campaignId];
    }

    /**
     * @notice Lấy số tiền đã quyên góp của một donor trong chiến dịch
     */
    function getDonationByDonor(uint256 _campaignId, address _donor) 
        external 
        view 
        returns (uint256) 
    {
        return donationsByDonor[_campaignId][_donor];
    }

    /**
     * @notice Lấy tất cả các khoản quyên góp của một chiến dịch
     */
    function getCampaignDonations(uint256 _campaignId) 
        external 
        view 
        returns (Donation[] memory) 
    {
        return campaignDonations[_campaignId];
    }

    /**
     * @notice Lấy số lượng donor của một chiến dịch
     */
    function getCampaignDonorCount(uint256 _campaignId) external view returns (uint256) {
        return campaigns[_campaignId].donorCount;
    }

    /**
     * @notice Kiểm tra xem chiến dịch có đạt mục tiêu chưa
     */
    function isGoalReached(uint256 _campaignId) external view returns (bool) {
        return campaigns[_campaignId].goalReached;
    }

    /**
     * @notice Lấy tổng số chiến dịch
     */
    function getTotalCampaigns() external view returns (uint256) {
        return campaignCount;
    }
}