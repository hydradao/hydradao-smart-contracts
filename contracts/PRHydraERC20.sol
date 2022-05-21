pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PRHydraERC20 is ERC20 {
    constructor() ERC20("prHydra", "PRHYDR") {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
