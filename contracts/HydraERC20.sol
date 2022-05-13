pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HydraERC20 is ERC20 {

    address public vault;   // treasury vault

    mapping(address => bool) isMinter;

    constructor(uint _initialSupply, address _vault) ERC20("Hydra", "HYDR") {
        _mint(_vault, _initialSupply);
        vault = _vault;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "FORBIDDEN");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyVault returns (bool) {
        _mint(_to, _amount);
        return true;
    }
}