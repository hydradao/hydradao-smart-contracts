pragma solidity ^0.8.0;

contract RewardArray {

    event RewardWinners(uint firstIndex, address[] rewardWinners);

    uint public rewardSize;
    uint public newRewardSize;  // if 0, no new change to reward size
    uint public currIndex;
    address[] public rewardArray;

    address public administrator;

    constructor(uint _rewardSize, address _administrator) {
        administrator = _administrator;
        rewardSize = _rewardSize;
        rewardArray = new address[](_rewardSize);
        currIndex = 0;
        newRewardSize = 0;
    }

    modifier onlyAuth() {
        require(administrator == msg.sender);
        _;
    }

    modifier resetRewardWinners() {
        _;
        newRewardArray();
    }

    function newRewardArray() private {
        delete rewardArray;
        if (newRewardSize != 0) {
            rewardSize = newRewardSize;
            newRewardSize = 0;
        }
        rewardArray = new address[](rewardSize);
        currIndex = 0;
    }

    function appendAddress(address _rewardWinner) external onlyAuth {
        rewardArray[currIndex] = _rewardWinner;
        currIndex = (currIndex + 1) % rewardSize;
    }

    function getRewardWinners() external onlyAuth resetRewardWinners returns(address[] memory) {
        emit RewardWinners(currIndex, rewardArray);
        return rewardArray;
    }

    // new reward size implemented at start of next round
    function changeRewardSize(uint _newRewardSize) external onlyAuth {
        newRewardSize = _newRewardSize;
    }

    function getRewardSize() external view returns(uint) {
        return rewardSize;
    }
}