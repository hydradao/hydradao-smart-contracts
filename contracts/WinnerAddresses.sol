pragma solidity ^0.8.0;
import "./FomoTimer.sol";
import "hardhat/console.sol";

contract WinnerAddresses is FomoTimer {
    event AnnounceWinners(
        uint256 roundId,
        uint256 firstIndex,
        address[] rewardWinners,
        uint256 winnersLength
    );

    uint256 public rewardSize = 50;
    uint256 public newRewardSize = 0; // if 0, no new change to reward size
    uint256 public winderAddrIndex = 0;
    address[] public rewardArray;

    mapping(uint256 => address[]) public winnerAddrsRnds;
    mapping(uint256 => uint256) public winnerAddrsLengths;
    mapping(uint256 => uint256) public winnerAddrsStartingIndex;

    function getWinnerAddrs(uint256 _rID)
        public
        view
        returns (address[] memory winnerAddrs)
    {
        winnerAddrs = new address[](winnerAddrsLengths[_rID]);
        uint256 i = winnerAddrsStartingIndex[_rID];

        if (_rID >= rID) {
            i = winderAddrIndex;
        }

        uint256 wai = 0; // index for winnerAddrs
        for (; i < winnerAddrsLengths[_rID]; i = getNextWinderIndex(i, _rID)) {
            winnerAddrs[wai] = winnerAddrsRnds[_rID][i];
            wai++;
        }
    }

    function activate() public {
        activateTimer();
        newWinnerAddrsArray();
    }

    function newWinnerAddrsArray() private {
        if (newRewardSize != 0) {
            rewardSize = newRewardSize;
            newRewardSize = 0;
        }
        winnerAddrsRnds[rID] = new address[](rewardSize);
        winnerAddrsLengths[rID] = rewardSize;
        winderAddrIndex = 0;
    }

    function endRoundIfItCan() public override returns (bool) {
        bool didRoundEnd = super.endRoundIfItCan();
        if (didRoundEnd) {
            emit AnnounceWinners(rID, winderAddrIndex, rewardArray, rewardSize);
            winnerAddrsStartingIndex[rID] = winderAddrIndex;
            newWinnerAddrsArray();
            return true;
        }
        return false;
    }

    function appendAddress(address _rewardWinner) public {
        winnerAddrsRnds[rID][winderAddrIndex] = _rewardWinner;
        winderAddrIndex = getNextWinderIndex(winderAddrIndex, rID);
    }

    function getNextWinderIndex(uint256 _winderAddrIndex, uint256 _rID)
        private
        view
        returns (uint256)
    {
        return (_winderAddrIndex + 1) % winnerAddrsLengths[_rID];
    }

    // new reward size implemented at start of next round
    function changeRewardSize(uint256 _newRewardSize) external {
        newRewardSize = _newRewardSize;
    }

    function getTheOverriddenMinter() public view returns (address) {
        return winnerAddrsRnds[rID][winderAddrIndex];
    }
}
