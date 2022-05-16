pragma solidity ^0.8.0;

import './HydraERC20.sol';
import './RewardArray.sol';
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// can use enumerableset for token whitelist

struct MintSettings {
    uint slope;
    uint initialMintPrice;
    uint currentMintPrice;
    uint maxMintPrice;  
}

// struct Coin {
//     bool whitelisted;
//     address coinAddress;
// }

contract HydraTreasury {

    /* ========== EVENTS ========== */

    event AddCoinToWhitelist(address indexed token);
    event RemoveCoinFromWhitelist(address indexed token);
    event DepositToTreasury(address indexed token, uint amountDeposited);

    /* ========== STATE VARIABLES ========== */

    address public administrator;

    address[] public coinList;
    mapping(address => bool) coinStatus;    // whitelist status
    uint numWhitelistedCoins;

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint public totalReserves;

    HydraERC20 public hydraToken;
    RewardArray public rewardArray;

    MintSettings mintSettings;
    MintSettings newRoundMintSettings;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _administrator, 
        address _hydraToken,
        // uint _slope,
        // uint _maxMintPrice,
        uint _rewardArrayLength) 
    {
        administrator = _administrator;
        // mintSettings.slope = _slope;    // Our f(x)
        // mintSettings.maxMintPrice = _maxMintPrice;
        hydraToken = HydraERC20(_hydraToken);
        rewardArray = new RewardArray(_rewardArrayLength);
        numWhitelistedCoins = 0;
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
        numWhitelistedCoins++;
        emit AddCoinToWhitelist(_token);
    }

    function removeCoinFromWhitelist(address _token) external onlyAdmin {
        require(coinStatus[_token], "COIN NOT ON WHITELIST");
        coinStatus[_token] = false;
        numWhitelistedCoins--;
        emit RemoveCoinFromWhitelist(_token);
    }

    function getWhitelistedCoins() external view returns(address[] memory whitelistedCoins) {
        whitelistedCoins = new address[](numWhitelistedCoins);
        uint wli = 0; // index for whitelistedCoins
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) {
                whitelistedCoins[wli] = coinList[i];
                wli++;
            }
        }
    }

    function addToTreasury(address _token, uint _amountToDeposit) public {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amountToDeposit), "TRANSACTION FAILED");
        emit DepositToTreasury(_token, _amountToDeposit);
    }

    function getTokenValue(address _token, uint _amount) public pure returns(uint tokenValue) {
        // get token value for asset deposited using oracle
        return 1;
    }

    // get value of all coins in treasury and return
    function getTotalReserves() public returns(uint reserves) {
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) { 
                reserves += getTokenValue(coinList[i], IERC20(coinList[i]).balanceOf(address(this)));
            }
        }
        totalReserves = reserves;
    }

    // Move this into smart contract controlling rounds
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