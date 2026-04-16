// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 number,
        address toAddress
    ) ERC20(name_, symbol_) Ownable(msg.sender) {

        _mint(toAddress, number * (10 ** 18));
        renounceOwnership();
    }

}