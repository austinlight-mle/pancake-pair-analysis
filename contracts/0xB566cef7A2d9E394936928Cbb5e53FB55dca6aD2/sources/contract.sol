// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DigitalToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) private allowances_;
    mapping(address => uint256) private balances_;

    uint256 private total_;
    string private nm;
    string private sm;
    uint8 public constant decimals = 18;

    constructor(string memory name_, string memory symbol_, uint256 supply_) {
        nm = name_;
        sm = symbol_;
        unchecked {
            uint256 t = supply_ * (10 ** decimals);
            total_ = t;
            balances_[msg.sender] = t;
            emit Transfer(address(0), msg.sender, t);
        }
    }

    function name() external view returns (string memory) { return nm; }
    function symbol() external view returns (string memory) { return sm; }
    function totalSupply() external view returns (uint256) { return total_; }
    function balanceOf(address a) public view returns (uint256) { return balances_[a]; }
    function allowance(address o, address s) public view returns (uint256) { return allowances_[o][s]; }

    function transfer(address to, uint256 v) public returns (bool) {
        _transfer(msg.sender, to, v);
        return true;
    }

    function approve(address s, uint256 v) public returns (bool) {
        _approve(msg.sender, s, v);
        return true;
    }

    function transferFrom(address f, address t, uint256 v) public returns (bool) {
        uint256 a = allowances_[f][msg.sender];
        require(a >= v, "allow");
        unchecked { allowances_[f][msg.sender] = a - v; }
        _transfer(f, t, v);
        return true;
    }

    function _transfer(address f, address t, uint256 v) internal {
        require(f != address(0) && t != address(0), "0addr");
        uint256 b = balances_[f];
        require(b >= v, "bal");
        unchecked { balances_[f] = b - v; balances_[t] += v; }
        emit Transfer(f, t, v);
    }

    function _approve(address o, address s, uint256 v) internal {
        require(o != address(0) && s != address(0), "0addr");
        allowances_[o][s] = v;
        emit Approval(o, s, v);
    }
}