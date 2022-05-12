pragma solidity ^0.8.13;

contract RewardArray {

    event RewardWinners(address[] rewardWinners);

    uint public bufferSize;
    uint public currIndex;

    address[] public bufferArray;
    address public controller;

    constructor(uint _bufferSize) {
        bufferSize = _bufferSize;
        bufferArray = new address[](_bufferSize);
        currIndex = 0;
        controller = msg.sender;
    }

    modifier onlyAuth() {
        require(controller == msg.sender);
        _;
    }

    modifier resetRewardWinners() {
        _;
        eraseArray();
    }

    function eraseArray() private {
        delete bufferArray;
        bufferArray = new address[](bufferSize);
        currIndex = 0;
    }

    function appendAddress(address _rewardWinner) external onlyAuth {
        bufferArray[currIndex] = _rewardWinner;
        currIndex = (currIndex + 1) % bufferSize;
    }

    function getRewardWinners() external onlyAuth resetRewardWinners returns(address[] memory) {
        emit RewardWinners(bufferArray);
        return bufferArray;
    }

    function changeRewardSize(uint8 _newRewardSize) external onlyAuth {
        bufferSize = _newRewardSize;
        eraseArray();
    }

    function getRewardSize() external view returns(uint) {
        return bufferSize;
    }
    
}