//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//import contract
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IERC20.sol";

contract TokenStaking is Ownable, ReentrancyGuard, Initializable {
    // Struct to store the User Details
    struct User {
        uint256 stakeAmount; //stake amount
        uint256 rewardAmount; //reward amount
        uint256 lastStakeTime; //last stake timestamp
        uint256 lastRewardCalculationTime; //last reward calculation timestamp
        uint256 rewardsClaimedSoFar; //sum of rewards claimed so far

    }

    uint256 _minimumStakingAmount; 
    uint256 _maxStakeTokenLimit; //max staking token limit
    uint256 _stakeEndDate; //end data of program
    uint256 _stakeStartDate; // start date
    uint256 _totalStakedTokens; //total no of token that are stake
    uint256 _totalUsers; //total no of users
    uint256 _stakeDays; // staking days
    uint256 _earlyUnstakeFeePercentage; //early unstake fee percentage
    bool _isStakingPaused; //staking status

    address private _tokenAddress; // Token contract address

    uint256 _apyRate; //apy rate gor percentage of reward

    uint256 public constant PERCENTAGE_DENOMINATOR = 1000;
    uint256 public constant APY_RATE_CHANGE_THRESHOLD = 10;

    //user address => User
    mapping(address => User) private _users;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);
    event EarlyUnStakeFee(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    modifier whenTreasuryHasBalance(uint256 amount) {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= amount,
            "TokenStaking : insufficient funds in the treasury"
        );
        _;
        
    }

    function initialize(
        address owner_,
        address tokenAddress_,
        uint256 apyRate_,
        uint256 minimumStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) public virtual initializer {
        _TokenStaking_init_unchained(
            owner_,
            tokenAddress_,
            apyRate_,
            minimumStakingAmount_,
            maxStakeTokenLimit_,
            stakeStartDate_,
            stakeEndDate_,
            stakeDays_,
            earlyUnstakeFeePercentage_
        );
    }

    function _TokenStaking_init_unchained(
        address owner_,
        address tokenAddress_,
        uint256 apyRate_,
        uint256 minimumStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) internal onlyInitializing {
        require(_apyRate <= 10000, "Tokenstaking: apy rate should be less than 10000");
        require(stakeDays_ > 0, "Tokenstaking: stake days must be non-zero");
        require(tokenAddress_ != address(0), "Tokenstaking: token address cannot be 0 address");
        require(stakeStartDate_ < stakeEndDate_, "TokenStaking: start date must be less than end date");

        _transferOwnership(owner_);
        _tokenAddress = tokenAddress_;
        _apyRate = apyRate_;
        _minimumStakingAmount = minimumStakingAmount_;
        _maxStakeTokenLimit = maxStakeTokenLimit_;
        _stakeStartDate = stakeStartDate_;
        _stakeEndDate = stakeEndDate_;
        _stakeDays = stakeDays_ * 1 days;
        _earlyUnstakeFeePercentage =  earlyUnstakeFeePercentage_;

    }
    // View Method Start

    /**
     * @notice This function is used to get the minimum staking amount
     */
    function getMinimumStakingAmount() external view returns (uint256) {
        return _minimumStakingAmount;
        
    }

    /**
     * @notice This function is used to get the maxmimum staking token limit for program
     */
    function getMaxStakingTokenLimit() external view returns (uint256) {
        return _maxStakeTokenLimit;
        
    }

    /**
     * @notice This function is used to get the  staking start date for program
     */
    function getTotalStakedTokens() external view returns (uint256) {
        return _totalStakedTokens;
    }

    /**
     * @notice This function is used to get the totsl no of users
     */
    function getTotalUsers() external view returns (uint256) {
        return _totalUsers;
    }

    /**
     * @notice This function is used to get stake days
     */
    function getStakedays() external view returns (uint256) {
        return _stakeDays;
    }

    /**
     * @notice This function is used to get the early unstake fee percentage
     */
    function getEarlyUnstakeFeePercentage() external view returns (uint256) {
        return _earlyUnstakeFeePercentage;
    }

    /**
     * @notice This function is used to get staking status
     */
    function getStakingStaus() external view returns (bool) {
        return _isStakingPaused;
    }

    /**
     * @notice This function is used to get the current apy rate
     * @return Current apy rate
     */
    function gtAPY() external view returns (uint256) {
        return _apyRate;
    }

    /**
     * @notice This function is used to get the msg.sender estimated reward amount
     * @return msg.sender estimated reward amount
     */
    function getUserEstimatedRewards() external view returns (uint256) {
        (uint256 amount, ) = _getUserEstimatedRewards(msg.sender);
        return _users[msg.sender].rewardAmount + amount;
    }

    /**
     * @notice This function is used to get the withdrawable amount from contract 
     */
    function getWithdrawableAmount() external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this)) - _totalStakedTokens;
    }

    /**
     * @notice This function is used to get the User Details
     * @param userAddress User address to get details of
     * @return User Struct
     */
    function getUser(address userAddress) external view returns (User memory) {
        return _users[userAddress];
    }

    /**
     * @notice This function is used to get to check if user is stakeholder
     * @param _user Address of the user to check
     * @return True if user is stakeholder, false otherwise
     */
    function isStakeHolder(address _user ) external view returns (bool) {
        return _users[_user].stakeAmount != 0;
    }

    /* View Methods End */

    /* Owner Methods Start */

    /**
     * @notice This function is used to get the update minimum staking amount
     */
    function updateMinimumStakingAmount(uint256 newAmount) external onlyOwner {
        _minimumStakingAmount = newAmount;
    }

    /**
     * @notice This function is used to get the update maxmimum staking amount
     */
    function updateMaximumStakingAmount(uint256 newAmount) external onlyOwner {
        _maxStakeTokenLimit = newAmount;
    }

    /**
     * @notice This function is used  to staking end date
     */
    function updateStakingEndDate(uint256 newDate) external onlyOwner {
        _stakeEndDate = newDate;
    }

    /**
     * @notice This function is used to early unstake fee percentage
     */
    function updateEarlyUnstakeFeePercentage(uint256 newPercentage) external onlyOwner {
        _earlyUnstakeFeePercentage = newPercentage;
    }

    /**
     * @notice stake tokens for specific user
     * @dev This function can be used to stake tokens for specific user
     * 
     * @param amount the amount to stake
     * @param user users address
     */
    function stakeForUser(uint256 amount, address user) external onlyOwner nonReentrant {
        _stakeTokens(amount, user);
    }

    /**
     * @notice enable/disable staking
     * @dev This functions can be used to toogle staking status
     */
    function toggleStakingStatus() external onlyOwner {
        _isStakingPaused = !_isStakingPaused;
    }

    /**
     * @notice Withdraw the specified amount if possible
     * 
     * @dev This function can be used to withdraw the available tokens
     * with this contract to the caller
     * 
     * @param amount the amount withdraw
     */
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(this.getWithdrawableAmount() >= amount, "TokenStaking not enough withdrawable tokens");
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    /* Owner Methods End */
    /* USer method start */

    /**
     * @notice This function is used to stake tokens
     * @param _amount Amount of tokens to be staked
     */
    function stake(uint256 _amount) external nonReentrant {
        _stakeTokens(_amount, msg.sender);
    }

    function _stakeTokens(uint256 _amount, address user_) private {
        require(!_isStakingPaused, "TokenStaking: staking is paused");

        uint256 currentTime = getCurrentTime();
        require(currentTime > _stakeStartDate, "TokenStaking: staking not started yet");
        require(_totalStakedTokens + _amount <= _maxStakeTokenLimit, "TokenStaking: max staking token Limit reached");
        require(_amount > 0, "TokenStaking: stake amount must be non-zero");
        require(
            _amount >= _minimumStakingAmount,
            "TokenStaking: stake amount  must be greater than minimum amount allowed"
        );

        if (_users[user_].stakeAmount != 0) {
            _calculateReward(user_);

        } else {
            _users[user_].lastRewardCalculationTime = currentTime;
            _totalUsers += 1;
        }

        _users[user_].stakeAmount += _amount;
        _users[user_].lastStakeTime = currentTime;

        _totalStakedTokens += _amount;

        require(
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
            "TokenStaking: failed to transfer tokens"
        );
        emit Stake(user_, _amount);

        
    }

    /**
     * @notice This function used to unstake tokens
     * @param _amount Amount of tokens to be unstaked
     */
    function unstake(uint256 _amount) external nonReentrant whenTreasuryHasBalance(_amount) {
        address user = msg.sender;

        require(_amount != 0, "TokenStaking: amount should be non-zero");
        require(this.isStakeHolder(user), "TokenStaking: not a stakeholder");
        require(_users[user].stakeAmount >= _amount, "TokenStaking: not enough stake to unstake");

        //Calculate Users rewards until now
        _calculateReward(user);
        uint256 feeEarlyUnstake;

        if (getCurrentTime() <= _users[user].lastStakeTime + _stakeDays) {
            feeEarlyUnstake = ((_amount * _earlyUnstakeFeePercentage) / PERCENTAGE_DENOMINATOR);
            emit EarlyUnStakeFee(user, feeEarlyUnstake);
        }

        uint256 amountToUnstake = _amount - feeEarlyUnstake;
        _users[user].stakeAmount -= _amount;
        _totalStakedTokens -= _amount;

        if (_users[user].stakeAmount == 0) {
            // delete _users[user];
            _totalUsers -= 1;
        }

        require(IERC20(_tokenAddress).transfer(user, amountToUnstake), "TokenStaking: failed to transfer");
        emit UnStake(user, _amount);
    }

    /**
     * @notice This function is used to claim users rewards
     */
    function claimReward() external nonReentrant whenTreasuryHasBalance(_users[msg.sender].rewardAmount) {
        _calculateReward(msg.sender);
        uint256 rewardAmount = _users[msg.sender].rewardAmount;

        require(rewardAmount >0,  "TokenStaking: no reward to claim");

        require(IERC20(_tokenAddress).transfer(msg.sender, rewardAmount), "TokenStaking: failed to transfer");

        _users[msg.sender].rewardAmount = 0;
        _users[msg.sender].rewardsClaimedSoFar += rewardAmount;

        emit ClaimReward(msg.sender,rewardAmount);
    }

    /* User Methods End */

    /* Private Helper Methods Start */

    /**
     * @notice This function is used to calculate the rewards for user
     * @param _user Address of the user
     */
    function _calculateReward(address _user) private  {
        (uint256 userReward, uint256 currentTime) = _getUserEstimatedRewards(_user);

        _users[_user].rewardAmount += userReward;
        _users[_user].lastRewardCalculationTime = currentTime;

    }

    /**
     * @notice This function is used to get estimated reward s for user
     * @param _user Address of the user
     * @return Estimated reward s for user
     */
    function _getUserEstimatedRewards(address _user) private view returns (uint256, uint256 ){
        uint256 userReward;
        uint256 userTimestamp = _users[_user].lastRewardCalculationTime;

        uint256 currentTime= getCurrentTime();

        if (currentTime > _users[_user].lastStakeTime + _stakeDays) {
            currentTime = _users[_user].lastStakeTime + _stakeDays;
        }

        uint256 totalStakedTime = currentTime - userTimestamp;

        userReward += ((totalStakedTime * _users[_user].stakeAmount * _apyRate) / 365 days) / 
        PERCENTAGE_DENOMINATOR;

        return (userReward, currentTime);
    }

    function getCurrentTime() internal view virtual returns (uint256){
        return block.timestamp ;
    }   
}