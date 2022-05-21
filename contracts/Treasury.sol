pragma solidity ^0.8.0;

import "./HydraERC20.sol";
import "hardhat/console.sol";

contract HydraTreasury {
    /* ========== EVENTS ========== */

    event AddCoinToWhitelist(address indexed token);
    event RemoveCoinFromWhitelist(address indexed token);
    event DepositToTreasury(address indexed token, uint256 amountDeposited);

    /* ========== STATE VARIABLES ========== */

    address public administrator;
    mapping(address => bool) approvedAddress;

    address[] public coinList;
    mapping(address => bool) coinStatus; // whitelist status
    uint256 numWhitelistedCoins;

    address[] public lastMinters;
    uint8 public numRewardedAddresses; // how many addresses rewarded at end of each round

    uint256 public totalReserves;

    HydraERC20 public hydraToken;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _administrator, address _hydraToken) {
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

    function getWhitelistedCoins()
        public
        view
        returns (address[] memory whitelistedCoins)
    {
        whitelistedCoins = new address[](numWhitelistedCoins);
        uint256 wli = 0; // index for whitelistedCoins
        for (uint256 i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) {
                whitelistedCoins[wli] = coinList[i];
                wli++;
            }
        }
    }

    function getNumWhitelist()
        external
        view
        returns (uint256 numWhitelistedCoins_)
    {
        numWhitelistedCoins_ = numWhitelistedCoins;
    }

    function getTokenValue(address _token, uint256 _amount)
        public
        pure
        returns (uint256)
    {
        return _amount;
    }

    // get value of all coins in treasury and return
    function getTotalReserves() public view returns (uint256 reserves) {
        for (uint256 i = 0; i < coinList.length; i++) {
            if (coinStatus[coinList[i]]) {
                reserves += getTokenValue(
                    coinList[i],
                    IERC20(coinList[i]).balanceOf(address(this))
                );
            }
        }
    }

    function getFloorPrice() public view returns (uint256) {
        return (getTotalReserves() * 10**9) / hydraToken.totalSupply();
    }

    function mintHYDR(uint256 _amountHYDR, address _minter) external {
        // TODO: calculate amount of tokens to subtract
        hydraToken.mint(_minter, _amountHYDR);
    }
}
