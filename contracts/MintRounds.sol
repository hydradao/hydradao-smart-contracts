pragma solidity ^0.8.0;

import './RewardArray.sol';
import './Treasury.sol';
import './FOMOTimer.sol';
// Reward Hydra that represents right to mint at floor
import './PHydra.sol'; 

// treasury must give permission to this contract to call mintHYDR

// data structure for reward array element
struct RewardWinner {
    address winnerAddr;
    uint amountPHYDR;
}

struct MintSettings {
    uint slope;
    uint startingMintPrice;
    uint maxMintPrice;
    uint maxMintAmount;
    uint amountPrizeHYDR;
    bool prizeEnabled;
}

struct RoundInfo {  // info about ongoing round
    uint currentMintPrice;
}

contract MintRounds {

    uint mintedHYDR;
    address public treasuryGuardian;

    HydraTreasury treasury;

    RewardArray rewardArray;
    FOMOTimer fomoTimer;

    MintSettings mintSettings;
    MintSettings newMintSettings;

    uint roundID;
    bool isRoundActive;
    bool roundsHalted;
    bool newMint;  // flag whether new mint settings have been written

    mapping(uint => MintSettings) public settingsRecords;   // delete records when claimed
    mapping(uint => address[]) public rewardsRecords;

    // msg.sender must be treasury guardian for mint access
    constructor(
        uint _rewardArraySize,
        uint _maxRoundAmount
    ) {
        treasuryGuardian = msg.sender;
        rewardArray = new RewardArray(_rewardArraySize);
        fomoTimer = new FOMOTimer();
        isRoundActive = false;
        roundID = 0;
    }

    modifier onlyGuardian() {
        require(msg.sender == treasuryGuardian);
        _;
    }

    modifier roundActive() {
        require(isRoundActive, "NO ROUND ACTIVE");
        _;
    }

    // Mint settings implemented at start of next round
    // Future versions may change round parameters during round
    function setMintSettings(
        MintSettings memory _mintSettings
    ) external {
        newMintSettings = _mintSettings;
    }

    function startRoundTimer() private {
        require(!roundsHalted, "MINT ROUNDS HALTED");
        require(!isRoundActive, "ROUND ALREADY ACTIVE");

        roundID++;
        fomoTimer.activateTimer(roundID);
        isRoundActive = true;
    }

    function startNewRound() public onlyGuardian {
        // reset parameters for new round
        if (newMint) {
            mintSettings = newMintSettings;
            newMint = false;
        }
        startRoundTimer();
    }

    // function setRoundActive() external onlyGuardian {
    //     roundsHalted = false;
    //     isRoundActive = true;
    // }

    // function stopRounds() public onlyGuardian {
    //     roundsHalted = true;
    // }

    // function setRoundInactive() public onlyGuardian {
    //     roundsHalted = true;
    //     isRoundActive = false;
    // }

    // Mint prHYDRA to those in reward array.
    function distributeReward() private {
        RewardWinner[] memory rewardWinners = rewardArray.getRewardWinners();
        for (uint i = 0; i < rewardWinners.length; i++) {
            mintPHYDRA(rewardWinners[i].winnerAddr, rewardWinners[i].amountPHYDR);
        }
        rewardArray.resetRewardWinners();
    }

    function isRoundOver() public returns(bool) {
        // Ask FOMO timer if round is over
    }

    function getPurchasePrice(uint _amountHYDR) public view returns(uint purchasePrice) {
        uint cmp = RoundInfo.currentMintPrice;
        uint slope = mintSettings.slope;

        purchasePrice = _amountHYDR * (cmp + (_amountHYDR ** 2) * slope / 2);  // area under supply vs price
    }

    function getTokenValue(address _token, uint _amount) public view returns(uint) {
        return _amount;
    }

    function mintHYDR(
        uint _amountHYDR, 
        uint _maxPurchasePrice, 
        address _token, 
        uint _amountForDeposit
    ) external {
        uint purchasePrice = getPurchasePrice(_amountHYDR);
        require(purchasePrice <= _maxPurchasePrice, "PURCHASE PRICE EXCEEDED MAXIMUM");
        
        require(purchasePrice <= getTokenValue(_token, _amountForDeposit), "INSUFFICIENT BALANCE");
        // mint from treasury
        treasury.mintHYDR(_amountHYDR, purchasePrice, _token, _amountForDeposit, msg.sender);

        // if round is over, reset mint parameters, distribute rewards

        // any time elapsed since previous round finished carries into current round
    }

}