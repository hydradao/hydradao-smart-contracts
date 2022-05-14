pragma solidity ^0.8.0;

import './HydraERC20.sol';
import './RewardArray.sol';
// import './interfaces/IERC20.sol';

struct TreasurySettings {
    uint slope;
    uint currentMintPrice;  
    uint maxMintPrice;  
}

contract HydraTreasury {

    address public controller;

    address[] public coinList;
    mapping(address => bool) coinStatus;    // whitelist status

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint public totalReserves;

    HydraERC20 public hydraToken;
    RewardArray public rewardArray;

    TreasurySettings treasurySettings;

    constructor(address _controller, 
        uint _slope, 
        uint _initialHydraSupply,
        uint _maxMintPrice) 
    {
        controller = _controller;
        treasurySettings.slope = _slope;    // Our f(x)
        treasurySettings.maxMintPrice = _maxMintPrice;
        hydraToken = new HydraERC20(_initialHydraSupply, _controller);
        rewardArray = new RewardArray(50);
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function addCoinToWhitelist(IERC20 _token) external onlyController {
        require(!coinStatus[address(_token)], "COIN ALREADY WHITELISTED");
        coinList.push(address(_token));
        coinStatus[address(_token)] = true;
    }

    function removeCoinFromWhitelist(IERC20 _token) external onlyController {
        coinStatus[address(_token)] = false;
    }

    function addToTreasury(IERC20 _token, uint _amountToDeposit) public {
        require(coinStatus[address(_token)], "TOKEN NOT ACCEPTED BY TREASURY");
        require(_token.transferFrom(msg.sender, address(this), _amountToDeposit), "TRANSACTION FAILED");
    }

    function getWhitelistedCoins() external view returns(address[] memory whitelistedCoins) {
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) { 
                whitelistedCoins[i] = coinList[i];
            }
        }
        return whitelistedCoins;
    }

    function getTokenValue(address _token, uint _amount) public view returns(uint) {
        // get token value for asset deposited
    }

    function getTreasuryFloor() public returns(uint reserves) {
        // get value of all coins in treasury and return
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) { 
                reserves += getTokenValue(coinList[i], IERC20(coinList[i]).balanceOf(address(this)));
            }
        }
        totalReserves = reserves;
    }

    function isRoundOver() internal returns(bool) {
        // Check if FOMO timer has expired. If yes, return true, else false.
        // Can also add other conditional(s) 
    }

    function distributeReward() internal {
        // Distribute rewards (prHYDRA) to last X minters
        // See RewardArray.sol
    }

    function resetMintRound() internal {
        // Start new mint round
        // Reset timer, mint starting price, and other necessary parameters
    }

    function getPurchasePrice(uint _amountHYDR) public view returns(uint purchasePrice) {
        uint cmp = treasurySettings.currentMintPrice;
        uint slope = treasurySettings.slope;

        purchasePrice = _amountHYDR * (cmp + (_amountHYDR ** 2) * slope / 2);  // area under supply vs price
    }

    function mintHYDR(uint _amountHYDR, uint _maxPurchasePrice, IERC20 _token, uint _amountForDeposit) external {
        uint purchasePrice = getPurchasePrice(_amountHYDR);
        require(purchasePrice <= _maxPurchasePrice, "MAX PURCHASE PRICE EXCEEDED");
        require(purchasePrice <= _amountForDeposit, "INSUFFICIENT BALANCE");

        // is it possible for the current mint price to have changed before add to
        addToTreasury(_token, _amountForDeposit);
        hydraToken.mint(msg.sender, _amountHYDR);

        treasurySettings.currentMintPrice = treasurySettings.slope * _amountHYDR;

        // If round is over, distribute rewards and reset mint settings
        if (isRoundOver()) distributeReward();
    }

}