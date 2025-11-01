// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DonationCampaign
 * @notice Nền tảng quyên góp minh bạch trên Celo blockchain
 * @dev Hỗ trợ tạo chiến dịch, quyên góp bằng cUSD, theo dõi tiến độ và rút/hoàn tiền
 */
contract DonationCampaign {
    using SafeERC20 for IERC20;

    IERC20 public immutable cUSD;

    struct Campaign {
        uint256 id;
        address creator;
        address beneficiary;      // Địa chỉ người thụ hưởng
        string name;              // Tên chiến dịch
        string description;       // Mô tả chi tiết
        string imageURL;          // URL ảnh chiến dịch
        uint256 targetAmount;     // Mục tiêu số tiền (cUSD)
        uint256 raisedAmount;    // Số tiền đã quyên góp
        uint256 deadline;        // Thời hạn (timestamp)
        uint256 donorCount;       // Số lượng người ủng hộ
        bool isActive;           // Chiến dịch còn hoạt động
        bool goalReached;        // Đã đạt mục tiêu chưa
        bool withdrawn;          // Đã rút tiền chưa
        uint256 createdAt;       // Thời điểm tạo
    }

    struct DonationInfo {
        address donor;
        uint256 amount;
        string donorName;         // Tên người quyên góp
        string message;           // Lời nhắn
        bool isAnonymous;         // Có ẩn danh không
        uint256 timestamp;
    }

    // State variables
    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => DonationInfo[]) public campaignDonations;  // campaignId => donations
    mapping(uint256 => mapping(address => uint256)) public donorContributions;  // campaignId => donor => total amount
    mapping(uint256 => mapping(address => uint256[])) public donorDonationIndices;  // campaignId => donor => donation indices

    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        address indexed beneficiary,
        string name,
        uint256 targetAmount,
        uint256 deadline
    );

    event DonationMade(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        string donorName,
        string message,
        bool isAnonymous,
        uint256 timestamp
    );

    event GoalReached(
        uint256 indexed campaignId,
        uint256 raisedAmount,
        uint256 timestamp
    );

    event Withdrawn(
        uint256 indexed campaignId,
        address indexed beneficiary,
        uint256 amount,
        bool isGoalBased,
        uint256 timestamp
    );

    event Refunded(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        uint256 timestamp
    );

    event CampaignEnded(
        uint256 indexed campaignId,
        uint256 finalAmount,
        bool goalReached
    );

    // Errors
    error CampaignNotFound();
    error CampaignHasEnded();
    error CampaignStillActive();
    error GoalNotReached();
    error AlreadyWithdrawn();
    error InvalidTargetAmount();
    error InvalidDeadline();
    error InvalidBeneficiary();
    error ZeroAmount();
    error NoContribution();
    error AlreadyRefunded();
    error TransferFailed();
    error NotCreator();

    /**
     * @param _cUSDAddress Địa chỉ contract cUSD token
     */
    constructor(address _cUSDAddress) {
        require(_cUSDAddress != address(0), "Invalid cUSD address");
        cUSD = IERC20(_cUSDAddress);
    }

    /**
     * @notice Tạo chiến dịch quyên góp mới
     * @param _name Tên chiến dịch
     * @param _description Mô tả chi tiết
     * @param _targetAmount Mục tiêu số tiền (cUSD với 18 decimals)
     * @param _deadline Thời hạn (Unix timestamp)
     * @param _beneficiary Địa chỉ người thụ hưởng
     * @param _imageURL URL ảnh chiến dịch
     * @return campaignId ID của chiến dịch vừa tạo
     */
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _deadline,
        address _beneficiary,
        string memory _imageURL
    ) external returns (uint256) {
        if (_targetAmount == 0) revert InvalidTargetAmount();
        if (_deadline <= block.timestamp) revert InvalidDeadline();
        if (_beneficiary == address(0)) revert InvalidBeneficiary();

        campaignCount++;
        uint256 campaignId = campaignCount;

        campaigns[campaignId] = Campaign({
            id: campaignId,
            creator: msg.sender,
            beneficiary: _beneficiary,
            name: _name,
            description: _description,
            imageURL: _imageURL,
            targetAmount: _targetAmount,
            raisedAmount: 0,
            deadline: _deadline,
            donorCount: 0,
            isActive: true,
            goalReached: false,
            withdrawn: false,
            createdAt: block.timestamp
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            _beneficiary,
            _name,
            _targetAmount,
            _deadline
        );

        return campaignId;
    }

    /**
     * @notice Quyên góp vào chiến dịch bằng cUSD
     * @param _campaignId ID của chiến dịch
     * @param _amount Số tiền quyên góp (cUSD với 18 decimals)
     * @param _name Tên người quyên góp
     * @param _message Lời nhắn
     * @param _isAnonymous Có ẩn danh không
     */
    function donate(
        uint256 _campaignId,
        uint256 _amount,
        string memory _name,
        string memory _message,
        bool _isAnonymous
    ) external {
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.id == 0) revert CampaignNotFound();
        if (!campaign.isActive) revert CampaignHasEnded();
        if (block.timestamp > campaign.deadline) {
            campaign.isActive = false;
            revert CampaignHasEnded();
        }
        if (_amount == 0) revert ZeroAmount();

        // Transfer cUSD from donor to contract
        cUSD.safeTransferFrom(msg.sender, address(this), _amount);

        // Update campaign state
        if (donorContributions[_campaignId][msg.sender] == 0) {
            campaign.donorCount++;
        }

        donorContributions[_campaignId][msg.sender] += _amount;
        campaign.raisedAmount += _amount;

        // Record donation
        uint256 donationIndex = campaignDonations[_campaignId].length;
        campaignDonations[_campaignId].push(DonationInfo({
            donor: _isAnonymous ? address(0) : msg.sender,
            amount: _amount,
            donorName: _name,
            message: _message,
            isAnonymous: _isAnonymous,
            timestamp: block.timestamp
        }));

        donorDonationIndices[_campaignId][msg.sender].push(donationIndex);

        emit DonationMade(
            _campaignId,
            msg.sender,
            _amount,
            _name,
            _message,
            _isAnonymous,
            block.timestamp
        );

        // Check if goal is reached
        if (campaign.raisedAmount >= campaign.targetAmount && !campaign.goalReached) {
            campaign.goalReached = true;
            emit GoalReached(_campaignId, campaign.raisedAmount, block.timestamp);
        }
    }

    /**
     * @notice Rút tiền - Manual hoặc Goal-based
     * @param _campaignId ID của chiến dịch
     * @param _isGoalBased true = chỉ rút khi đạt mục tiêu, false = rút bất cứ lúc nào
     */
    function withdraw(uint256 _campaignId, bool _isGoalBased) external {
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.id == 0) revert CampaignNotFound();
        if (msg.sender != campaign.creator) revert NotCreator();
        if (campaign.withdrawn) revert AlreadyWithdrawn();
        if (campaign.raisedAmount == 0) revert ZeroAmount();

        // Goal-based: chỉ rút khi đạt 100% mục tiêu
        if (_isGoalBased && !campaign.goalReached) {
            revert GoalNotReached();
        }

        campaign.withdrawn = true;
        campaign.isActive = false;

        uint256 amount = campaign.raisedAmount;

        // Transfer cUSD to beneficiary
        cUSD.safeTransfer(campaign.beneficiary, amount);

        emit Withdrawn(
            _campaignId,
            campaign.beneficiary,
            amount,
            _isGoalBased,
            block.timestamp
        );

        emit CampaignEnded(_campaignId, amount, campaign.goalReached);
    }

    /**
     * @notice Hoàn tiền cho donors khi chiến dịch thất bại (hết hạn nhưng chưa đạt mục tiêu)
     * @param _campaignId ID của chiến dịch
     */
    function refund(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.id == 0) revert CampaignNotFound();
        if (campaign.goalReached) revert GoalNotReached(); // Không hoàn tiền nếu đã đạt mục tiêu
        if (block.timestamp <= campaign.deadline) revert CampaignStillActive();
        if (campaign.withdrawn) revert AlreadyWithdrawn();

        uint256 contribution = donorContributions[_campaignId][msg.sender];
        if (contribution == 0) revert NoContribution();

        // Reset contribution để tránh double refund (reentrancy protection)
        donorContributions[_campaignId][msg.sender] = 0;

        // Transfer cUSD back to donor
        cUSD.safeTransfer(msg.sender, contribution);

        emit Refunded(_campaignId, msg.sender, contribution, block.timestamp);
    }

    /**
     * @notice Lấy chi tiết chiến dịch và tiến độ
     * @param _campaignId ID của chiến dịch
     * @return campaign Thông tin chiến dịch
     * @return progressPercent % hoàn thành mục tiêu (0-100)
     * @return timeRemaining Thời gian còn lại đến deadline (seconds, 0 nếu đã hết hạn)
     * @return donationCount Số lượng donations
     */
    function getCampaignDetails(uint256 _campaignId)
        external
        view
        returns (
            Campaign memory campaign,
            uint256 progressPercent,
            uint256 timeRemaining,
            uint256 donationCount
        )
    {
        Campaign storage _campaign = campaigns[_campaignId];
        if (_campaign.id == 0) revert CampaignNotFound();

        campaign = _campaign;
        uint256 _targetAmount = _campaign.targetAmount;
        uint256 _raisedAmount = _campaign.raisedAmount;
        uint256 _deadline = _campaign.deadline;

        // Tính % hoàn thành
        if (_targetAmount > 0) {
            progressPercent = (_raisedAmount * 100) / _targetAmount;
            if (progressPercent > 100) progressPercent = 100;
        } else {
            progressPercent = 0;
        }

        // Tính thời gian còn lại
        uint256 _currentTime = block.timestamp;
        if (_currentTime < _deadline) {
            timeRemaining = _deadline - _currentTime;
        } else {
            timeRemaining = 0;
        }

        donationCount = campaignDonations[_campaignId].length;
    }

    /**
     * @notice Lấy danh sách donations (ẩn địa chỉ nếu isAnonymous = true)
     * @param _campaignId ID của chiến dịch
     * @return donations Mảng thông tin donations
     */
    function getCampaignDonations(uint256 _campaignId)
        external
        view
        returns (DonationInfo[] memory donations)
    {
        if (campaigns[_campaignId].id == 0) revert CampaignNotFound();
        return campaignDonations[_campaignId];
    }

    /**
     * @notice Lấy tổng số tiền đã quyên góp của một donor
     * @param _campaignId ID của chiến dịch
     * @param _donor Địa chỉ donor
     * @return Tổng số tiền đã quyên góp
     */
    function getDonorContribution(uint256 _campaignId, address _donor)
        external
        view
        returns (uint256)
    {
        return donorContributions[_campaignId][_donor];
    }

    /**
     * @notice Lấy tổng số chiến dịch
     * @return Tổng số chiến dịch đã tạo
     */
    function getTotalCampaigns() external view returns (uint256) {
        return campaignCount;
    }

    /**
     * @notice Kiểm tra chiến dịch có thể refund không
     * @param _campaignId ID của chiến dịch
     * @return true nếu có thể refund (hết hạn và chưa đạt mục tiêu)
     */
    function canRefund(uint256 _campaignId) external view returns (bool) {
        Campaign memory campaign = campaigns[_campaignId];
        return (
            campaign.id != 0 &&
            !campaign.goalReached &&
            block.timestamp > campaign.deadline &&
            !campaign.withdrawn
        );
    }
}
