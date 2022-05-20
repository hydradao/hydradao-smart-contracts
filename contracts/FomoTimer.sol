pragma solidity ^0.8.0;

// Timer contract is created and administered by MintRounds contract
contract FOMOTimer {

    uint256 private constant rndInit_ = 1 hours; // round timer starts at this
    uint256 private constant rndInc_ = 30 seconds; // every full unit purchased adds this much to the timer
    uint256 private constant rndMax_ = 24 hours; // max length a round timer can be
    uint256 private constant amountUnit_ = 1000000000000000000; // amount / amountUnit_ = how many rndInc_ will be added to the timer
    uint256 private constant amountThreshold_ = 0; // amount has to be larger than the amountThreshold for the timer inc

    // Round Info
    struct Round {
        uint256 roundID; // RoundID created by MintRounds
        uint256 start; // The block that this round started
        uint256 end; // The end block
        bool active; // is round over
    }

    //bool roundActive;
    uint256 public currRoundID; // ID of current 

    mapping(uint256 => Round) public rounds;

    address public guardian;  // FOMOTimer administered by MintRounds contract

    constructor() {
        guardian = msg.sender;
    }

    modifier isGuardian() {
        require(msg.sender == guardian, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev returns all current round info needed for front end     
     * @return round id
     * @return time round ends
     * @return time round started
     */
    function getRoundInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            currRoundID,
            rounds[currRoundID].end, 
            rounds[currRoundID].start 
        );
    }

    // guardian calls activateRound at start of each new round
    function activateRound(uint _roundID) public isGuardian {
        uint start = block.timestamp;
        uint end = start + rndInit_;
        bool active = true;

        currRoundID = _roundID;

        rounds[_roundID] = Round(_roundID, start, end, active);
    }

    function endRound() private {
        rounds[currRoundID].active = false;
    }
  
    // add more time or return if round ended
    function updateTimer(uint _roundID, uint256 _amount) public isGuardian returns (bool) {
        if (
            block.timestamp > rounds[_roundID].start &&
            (block.timestamp < rounds[_roundID].end)
        ) {
            incrementTime(_amount);
            return false;
        } else {
            endRound();
            return true;
        }
    }

    function incrementTime(uint256 _amount) private {
        // calculate time based on number of amount bought
        uint256 _newTime = ((_amount - amountThreshold_) /
            ((amountUnit_ * rndInc_) + rounds[currRoundID].end));

        // compare to max and set new end time
        if (_newTime < (rndMax_ + block.timestamp)) {
            rounds[currRoundID].end = _newTime;
        } else {
            rounds[currRoundID].end = rndMax_ + block.timestamp;
        }
    }
}
