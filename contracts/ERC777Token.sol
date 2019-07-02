pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC777/ERC777.sol";

contract ERC777Token is ERC777 {

    uint256 public constant initialSupply = 2 ** 256 - 1;

    constructor () public ERC777("ERC777Token", "SSST", new address[](0)) {
        _mint(msg.sender, msg.sender, initialSupply, "", "");
    }
}
