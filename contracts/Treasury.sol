pragma solidity ^0.8.0;

import './HydraERC20.sol';
import './RewardArray.sol';

struct MintSettings {
    uint slope;
    uint initialMintPrice;
    uint currentMintPrice;
    uint maxMintPrice;  
}

contract HydraTreasury {

    /* ========== EVENTS ========== */

    event AddCoinToWhitelist(address indexed token);
    event RemoveCoinFromWhitelist(address indexed token);
    event DepositToTreasury(address indexed token, uint amountDeposited);

    /* ========== STATE VARIABLES ========== */

    address public administrator;

    address[] public coinList;
    mapping(address => bool) coinStatus;    // whitelist status

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint public totalReserves;

    HydraERC20 public hydraToken;
    RewardArray public rewardArray;

    MintSettings mintSettings;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _administrator, 
        uint _slope, 
        uint _initialHydraSupply,
        uint _maxMintPrice) 
    {
        administrator = _administrator;
        mintSettings.slope = _slope;    // Our f(x)
        mintSettings.maxMintPrice = _maxMintPrice;
        hydraToken = new HydraERC20(_initialHydraSupply, _administrator);
        rewardArray = new RewardArray(50);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        require(msg.sender == administrator);
        _;
    }

    function addCoinToWhitelist(address _token) external onlyAdmin {
        require(!coinStatus[_token], "COIN ALREADY WHITELISTED");
        coinList.push(_token);
        coinStatus[_token] = true;
        emit AddCoinToWhitelist(_token);
    }

    function removeCoinFromWhitelist(address _token) external onlyAdmin {
        coinStatus[_token] = false;
        emit RemoveCoinFromWhitelist(_token);
    }

    function getWhitelistedCoins() external view returns(address[] memory whitelistedCoins) {
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) { 
                whitelistedCoins[i] = coinList[i];
            }
        }
        return whitelistedCoins;
    }

    function addToTreasury(address _token, uint _amountToDeposit) public {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amountToDeposit), "TRANSACTION FAILED");
        emit DepositToTreasury(_token, _amountToDeposit);
    }

    function getTokenValue(address _token, uint _amount) public view returns(uint) {
        // get token value for asset deposited using oracle
    }

    // get value of all coins in treasury and return
    function getTreasuryFloor() public returns(uint reserves) {
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

    function setInitialMintPrice(uint _initialMintPrice) external onlyAdmin {
        mintSettings.initialMintPrice = _initialMintPrice;
    }

    function getPurchasePrice(uint _amountHYDR) public view returns(uint purchasePrice) {
        uint cmp = mintSettings.currentMintPrice;
        uint slope = mintSettings.slope;

        purchasePrice = _amountHYDR * (cmp + (_amountHYDR ** 2) * slope / 2);  // area under supply vs price
    }

    function mintHYDR(uint _amountHYDR, uint _maxPurchasePrice, address _token, uint _amountForDeposit) external {
        require(coinStatus[_token], "TOKEN NOT ACCEPTED BY TREASURY");

        uint purchasePrice = getPurchasePrice(_amountHYDR);
        require(purchasePrice <= _maxPurchasePrice, "MAX PURCHASE PRICE EXCEEDED");
        require(purchasePrice <= getTokenValue(_token, _amountForDeposit), "INSUFFICIENT BALANCE");

        addToTreasury(_token, _amountForDeposit);
        hydraToken.mint(msg.sender, _amountHYDR);

        mintSettings.currentMintPrice = mintSettings.slope * _amountHYDR;

        // If round is over, distribute rewards and reset mint settings
        if (isRoundOver()) {
            distributeReward();
            resetMintRound();
        }
    }

}