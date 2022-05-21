pragma solidity ^0.8.0;
import "hardhat/console.sol";

// Timer contract is created and administered by MintRounds contract
contract FomoTimer {
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
    }

    //bool roundActive;
    uint256 public rID; // ID of current

    mapping(uint256 => Round) public rounds;

    bool public activated = false;

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
        return (rID, rounds[rID].start, rounds[rID].end);
    }

    // guardian calls activateRound at start of each new round
    function activateTimer() public {
        require(activated == false, "timer already activated");

        activated = true;

        uint256 start = block.timestamp;
        uint256 end = start + rndInit_;

        rID = 1;

        rounds[1] = Round(rID, start, end);
    }

    // reset timer, announce winner, allocate tokens
    function endRoundIfItCan() public virtual returns (bool) {
        if (block.timestamp > rounds[rID].end) {
            rID++;
            rounds[rID].start = block.timestamp;
            rounds[rID].end = block.timestamp + rndInit_;
            return true;
        }
        return false;
    }

    // add more time or return if round ended
    function updateTimerIfItCan(uint256 _amount) public returns (bool) {
        if (block.timestamp <= rounds[rID].end) {
            incrementTime(_amount);
            return true;
        }
        return false;
    }

    function incrementTime(uint256 _amount) private {
        // calculate time based on number of amount bought
        uint256 _newTime = ((_amount - amountThreshold_) * rndInc_) /
            amountUnit_ +
            rounds[rID].end;

        // compare to max and set new end time
        if (_newTime < (rndMax_ + block.timestamp)) {
            rounds[rID].end = _newTime;
        } else {
            rounds[rID].end = rndMax_ + block.timestamp;
        }
    }
}
