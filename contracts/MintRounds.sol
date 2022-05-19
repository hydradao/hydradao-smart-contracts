pragma solidity ^0.8.0;

import './RewardArray.sol';

// treasury must give permission to this contract to call mintHYDR

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

    RewardArray rewardArray;
    MintSettings mintSettings;
    MintSettings newMintSettings;

    bool roundActive;
    bool newMintSettings;

    uint roundID;

    // msg.sender must be treasury guardian for mint access
    constructor(
        uint _rewardArraySize,
        uint _maxRoundAmount,
    ) {
        treasuryGuardian = msg.sender,
        rewardArray = new RewardArray(_rewardArraySize);
        roundActive = false;
    }

    modifier onlyGuardian() {
        require(msg.sender == treasuryGuardian);
        _;
    }

    modifier roundActive() {
        require(roundActive, "NO ROUND ACTIVE");
        _;
    }

    // Mint settings implemented at start of next round
    // Future versions may change round parameters during round
    function setMintSettings(
        MintSettings memory _mintSettings
    ) {
        newMintSettings = _mintSettings;
    }

    function startRoundTimer() {
        // Start FOMO timer
    }

    function resetRound() onlyGuardian {
        // reset parameters for new round
        if (newMintSettings) {
            mintSettings = newMintSettings;
        }
        startRoundTimer();
    }

    function startRounds() onlyGuardian {
        // Start rounds
        roundActive = true;

        resetRound();
    }

    function stopRounds() onlyGuardian {
        // Stop rounds
        roundActive = false;
    }

    function distributeReward() {
        // Distribute prHYDRA to those in reward array.

        // emit event with info about the mint round that just ended
        // emit event for reward array 
    }

    function isRoundOver() public returns(bool) {
        // Ask FOMO timer if round is over
    }

    function getPurchasePrice(uint _amountHYDR) public view returns(uint purchasePrice) {
        uint cmp = mintSettings.currentMintPrice;
        uint slope = mintSettings.slope;

        purchasePrice = _amountHYDR * (cmp + (_amountHYDR ** 2) * slope / 2);  // area under supply vs price
    }

    // Need a way to determine round over without depending on mintHYDR calls
    // If user tries to mint HYDR after the expiry, pay the old round and start new round
    function mintHYDR(
        uint _amountHYDR, 
        uint _maxPurchasePrice, 
        address _token, 
        uint _amountForDeposit
    ) external {
        // get purchase price

        // mint from treasury

        // if round is over, reset mint parameters, distribute rewards

        // any time elapsed since previous round finished carries into current round
    }

    function claimReward(uint _roundID) {
        // Solves the previous problem
    }

}