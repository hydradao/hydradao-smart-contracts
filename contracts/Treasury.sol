pragma solidity ^0.8.0;

import './HydraERC20.sol';
import './RewardArray.sol';

/*
TODO: Add events
*/
contract HydraTreasury {

    /* ========== EVENTS ========== */

    event AddCoinToWhitelist(address indexed token);
    event RemoveCoinFromWhitelist(address indexed token);
    event DepositToTreasury(address indexed token, uint amountDeposited);

    /* ========== STATE VARIABLES ========== */

    address public administrator;
    mapping(address => bool) approvedAddress;

    address[] public coinList;
    mapping(address => bool) coinStatus;    // whitelist status
    uint numWhitelistedCoins;

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint public totalReserves;

    HydraERC20 public hydraToken;
    RewardArray public rewardArray;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _administrator, 
        address _hydraToken) 
    {
        administrator = _administrator;
        hydraToken = HydraERC20(_hydraToken);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        require(msg.sender == administrator, "TREASURY ADMINISTRATOR ONLY");
        _;
    }

    // MintRounds must be whitelisted to call mint function
    modifier approvedMintAddress() {
        require(approvedAddress[msg.sender], "NOT AN APPROVED ADDRESS");
        _;
    }

    modifier validCoin(address _token) {
        require(coinStatus[_token], "TOKEN NOT ACCEPTED BY TREASURY");
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

    function getWhitelistedCoins() public view returns(address[] memory whitelistedCoins) {
        whitelistedCoins = new address[](numWhitelistedCoins);
        uint wli = 0; // index for whitelistedCoins
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) {
                whitelistedCoins[wli] = coinList[i];
                wli++;
            }
        }
    }

    function getNumWhitelist() external view returns(uint numWhitelistedCoins_) {
        numWhitelistedCoins_ = numWhitelistedCoins;
    }

    function addToTreasury(address _token, uint _amountToDeposit) public validCoin(_token) {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amountToDeposit), "TRANSACTION FAILED");
        emit DepositToTreasury(_token, _amountToDeposit);
    }

    function getTokenValue(address _token, uint _amount) public view returns(uint) {
        return _amount;
    }

    // get value of all coins in treasury and return
    function getTotalReserves() public view returns(uint reserves) {
        for (uint i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) { 
                reserves += getTokenValue(coinList[i], IERC20(coinList[i]).balanceOf(address(this)));
            }
        }
    }

    function mintHYDR(
        uint _amountHYDR, 
        address _token, 
        uint _amountForDeposit,
        address _minter
    ) external approvedMintAddress validCoin(_token) {
        
        // TODO: calculate amount of tokens to subtract
        addToTreasury(_token, _amountForDeposit);
        hydraToken.mint(_minter, _amountHYDR);
    }

}