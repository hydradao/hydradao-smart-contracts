pragma solidity ^0.8.0;

import './HydraERC20.sol';
import './RewardArray.sol';

struct TreasurySettings {
    uint slope;
    uint currentMintPrice;
    uint maxMintPrice;
}

contract HydraTreasury {

    address public controller;

    // address[] public whitelistedCoins;
    mapping(address => bool) coinStatus;

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint public totalReserves;

    HydraERC20 public hydraToken;

    TreasurySettings treasurySettings;

    constructor(address _controller, uint _slope, uint256 _initialHydraSupply) {
        controller = _controller;
        treasurySettings.slope = _slope;    // Our f(x)
        hydraToken = new HydraERC20(_initialHydraSupply);
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    modifier validCoin(address _coin) {
        require(coinStatus[_coin]);
        _;
    }

    function addCoinToWhitelist(IERC20 _token) external onlyController {
        coinStatus[address(_token)] = true;
    }

    function removeCoinFromWhitelist(IERC20 _token) external onlyController {
        coinStatus[address(_token)] = false;
    }

    function addToTreasury(IERC20 _token, uint _amountToDeposit) public {
        require(coinStatus[address(_token)], "TOKEN NOT ACCEPTED BY TREASURY");
        require(_token.transfer(address(this), _amountToDeposit), "TRANSACTION FAILED");
    }

    // function floorPrice() public view returns(uint) {
    //     return hydraToken.totalSupply() / totalReserves;
    // }

    function getHydraSupply() public view returns(uint) {
        return hydraToken.totalSupply();
    }

    function getTreasuryValue() public view returns(uint) {
        // Get value of all stablecoins
    }

    function isRoundOver() internal returns(bool) {
        // Check if FOMO timer has expired. If yes, return true, else false.
        // Can also add other conditional(s) 
    }

    function validBalance() private returns(bool) {
        // Check if msg.sender has valid balance for minting
    }

    function distributeReward() internal {
        // Distribute rewards to last X minters
        // See RewardArray.sol
    }

    function getPurchasePrice(uint _amountHYDR) public view returns(uint) {
        uint purchasePrice = 0;

        uint cmp = treasurySettings.currentMintPrice;
        uint slope = treasurySettings.slope;

        purchasePrice = _amountHYDR * (cmp + (_amountHYDR ** 2) * slope / 2);
        return purchasePrice;
    }

    function mintHYDR(uint _amountHYDR, uint maxPurchasePrice, IERC20 _token, uint _amountToDeposit) external payable {
        uint purchasePrice = getPurchasePrice(_amountHYDR);
        require(purchasePrice <= maxPurchasePrice, "MAX PURCHASE PRICE EXCEEDED");

        // Check if user has enough to pay for Hydra mint
        require(validBalance(), "USER DOES NOT HAVE VALID BALANCE");
        addToTreasury(_token, _amountToDeposit);
        hydraToken.mint(msg.sender, _amountHYDR);

        treasurySettings.currentMintPrice = treasurySettings.slope * _amountHYDR;

        // If round is over, distribute rewards and reset mint settings
    }

}