pragma solidity ^0.8.0;

contract Timer {

  uint256 private rID_ = 0;

  uint256 constant private rndInit_ = 1 hours;                // round timer starts at this
  uint256 constant private rndInc_ = 30 seconds;              // every full unit purchased adds this much to the timer
  uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
  uint256 constant private amountUnit_ = 1000000000000000000; // amount / amountUnit_ = how many rndInc_ will be added to the timer
  uint256 constant private amountThreshold_ = 0;               // amount has to be larger than the amountThreshold for the timer inc

  // skeleton
  struct Round {
    uint256 start;        // The block that this round started     
    uint256 end;          // The end block
    uint256 hydr;         // totoal hydr has been minted
    bool ended;           // has round end function been ran     
  }

  mapping (uint256 => Round) public round_;

  /**
    * @dev returns all current round info needed for front end
    * -functionhash- 0x747dff42
    * @return round id 
    * @return total hydr for round 
    * @return time round ends
    * @return time round started
    */
  function getCurrentRoundInfo()
    public
    view
    returns(uint256, uint256, uint256, uint256)
  {
    return
    (
      rID_,                           //1
      round_[rID_].hydr,              //2
      round_[rID_].end,               //3
      round_[rID_].start,             //4
    );
  }

  bool public activated_ = false;
  function activate()
    public
  {     
    // can only be ran once
    require(activated_ == false, "fomo3d already activated");
      
    // activate the contract 
    activated_ = true;
      
    // lets start first round
    rID_ = 1;
    round_[1].strt = now;
    round_[1].end = now + rndInit_;
  }

  //Starts everytime the block is reset
  // This Event will in the treasury
  // event startRound (
  //     uint _initTimer,
  //     uint _amountThreadhold,
  //     uint _amountStep,
  //     uint _blockIncreasedByAmountStep,
  //     uint _maxBlockIncreasedBy,
  //     uint _timerBlock(),
  // );

  //fired after block ends
  // This Event will in the treasury
  // event endRound (

  //     uint _initTimer,
  //     uint _amountThreadhold,
  //     uint _amountStep,
  //     uint _blockIncreasedByAmountStep,
  //     uint _maxBlockIncreasedBy,
  //     uint _timerBlock(),
  // //void _mint(amount uint)  <- will come back to this 
  // );

  // returns if this round ends
  function mint(uint256 _amount) public {
    if (now > round_[rID_].start && (now <= round_[rID_].end )) {
      round_[rID_].hydr += _amount;
      updateTimer(_amount);
      return false;
    } else {
      round_[rID_].ended = true;
      endRound(_amount);
      return true;
    }
  }

  function updateTimer(uint256 _amount)
    private
  {    
    // calculate time based on number of amount bought
    uint256 _newTime = (((_amount - amountThreshold_ ) / (amountUnit_)).mul(rndInc_)).add(round_[rID_].end);
    
    // compare to max and set new end time
    if (_newTime < (rndMax_).add(now))
      round_[rID_].end = _newTime;
    else
      round_[rID_].end = rndMax_.add(now);
  } 

	// reset timer, announce winner, allocate tokens
	function endRound(uint256 amount) private {
    rID_++;
    round_[rID_].strt = now;
    round_[rID_].end = now.add(rndInit_);
	}
}