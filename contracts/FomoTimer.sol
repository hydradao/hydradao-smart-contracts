// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Timer {
    uint256 private rID_ = 0;

    uint256 private constant rndInit_ = 1 hours; // round timer starts at this
    uint256 private constant rndInc_ = 30 seconds; // every full unit purchased adds this much to the timer
    uint256 private constant rndMax_ = 24 hours; // max length a round timer can be
    uint256 private constant amountUnit_ = 1000000000000000000; // amount / amountUnit_ = how many rndInc_ will be added to the timer
    uint256 private constant amountThreshold_ = 0; // amount has to be larger than the amountThreshold for the timer inc

    // skeleton
    struct Round {
        uint256 start; // The block that this round started
        uint256 end; // The end block
        uint256 hydr; // totoal hydr has been minted
        bool ended; // has round end function been ran
    }

    mapping(uint256 => Round) public round_;

    /**
     * @dev returns all current round info needed for front end     
     * @return round id
     * @return total hydr for round
     * @return time round ends
     * @return time round started
     */
    function getCurrentRoundInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            rID_, //1
            round_[rID_].hydr, //2
            round_[rID_].end, //3
            round_[rID_].start //4
        );
    }

    bool public activated_ = false;

    function activate() public {
        // can only be ran once
        require(activated_ == false, "Timer already activated");

        // activate the contract
        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].start = block.timestamp;
        round_[1].end = block.timestamp + rndInit_;
    }

  
    // returns if this round ends
    function mint(uint256 _amount) public returns (bool) {
        if (
            block.timestamp > round_[rID_].start &&
            (block.timestamp <= round_[rID_].end)
        ) {
            round_[rID_].hydr += _amount;
            updateTimer(_amount);
            return false;
        } else {
            round_[rID_].ended = true;
            endRound();
            return true;
        }
    }

    function updateTimer(uint256 _amount) private {
        // calculate time based on number of amount bought
        uint256 _newTime = ((_amount - amountThreshold_) /
            ((amountUnit_ * rndInc_) + round_[rID_].end));

        // compare to max and set new end time
        if (_newTime < (rndMax_) + (block.timestamp))
            round_[rID_].end = _newTime;
        else round_[rID_].end = rndMax_ + (block.timestamp);
    }

    // reset timer
    function endRound() private {
        rID_++;
        round_[rID_].start = block.timestamp;
        round_[rID_].end = block.timestamp + rndInit_;
    }
}
