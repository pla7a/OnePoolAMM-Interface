// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LP is ERC20 {
    address public owner;
    uint256 lp_burned=0;

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    function change_owner(address new_owner) public onlyOwner {
        owner = new_owner;
    }

    function mint_to(address to, uint256 amt) external onlyOwner {
        _mint(to, amt);
    }

    function burn(uint256 amt) external onlyOwner {
        lp_burned += amt;
    }

    function circ_supply() public view returns (uint256){
        return (totalSupply() - lp_burned);
    }

}
