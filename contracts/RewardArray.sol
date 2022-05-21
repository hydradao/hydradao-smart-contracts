pragma solidity ^0.8.0;

struct RewardWinner {
    address winnerAddr;
    uint amountPHYDR;
}

contract RewardArray {

    uint public bufferSize;
    uint public currIndex;

    RewardWinner[] public bufferArray;
    address public controller;

    constructor(uint _bufferSize) {
        bufferSize = _bufferSize;
        bufferArray = new RewardWinner[](_bufferSize);
        currIndex = 0;
        controller = msg.sender;
    }

    modifier onlyAuth() {
        require(controller == msg.sender);
        _;
    }

    function resetRewardWinners() private {
        delete bufferArray;
        bufferArray = new RewardWinner[](bufferSize);
        currIndex = 0;
    }

    function appendAddress(address _rewardWinner, uint _amountPHYDR) external onlyAuth {
        bufferArray[currIndex].winnerAddr = _rewardWinner;
        bufferArray[currIndex].amountPHYDR = _amountPHYDR;
        currIndex = (currIndex + 1) % bufferSize;
    }

    function getRewardWinners() external view onlyAuth returns(RewardWinner[] memory) {
        return bufferArray;
    }

    function changeRewardSize(uint8 _newRewardSize) external onlyAuth {
        bufferSize = _newRewardSize;
        resetRewardWinners();
    }

    function getRewardSize() external view returns(uint) {
        return bufferSize;
    }
    
}