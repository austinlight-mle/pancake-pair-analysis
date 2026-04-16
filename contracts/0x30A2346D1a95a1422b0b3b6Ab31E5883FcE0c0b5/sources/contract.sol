/**
 *Submitted for verification at BscScan.com on 2025-09-19
*/

/**
 *Submitted for verification at BscScan.com on 2025-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SupTokenAlpha {
    mapping(address => uint256) private balances_;
    mapping(address => mapping(address => uint256)) private allowed_;
    uint256 private total_;
    string public token_name;
    string public token_symbol;
    uint8 public constant token_decimals = 18;

    event Transfer(address indexed src, address indexed dst, uint256 val);
    event Approval(address indexed from, address indexed to, uint256 val);

    constructor(string memory n, string memory s, uint256 supply) {
        token_name = n;
        token_symbol = s;
        total_ = supply * 10 ** token_decimals;
        balances_[msg.sender] = total_;
        emit Transfer(address(0), msg.sender, total_);
    }

    function name() external view returns (string memory) {
        return token_name;
    }

    function symbol() external view returns (string memory) {
        return token_symbol;
    }

    function decimals() external pure returns (uint8) {
        return token_decimals;
    }

    function totalSupply() external view returns (uint256) {
        return total_;
    }

    function balanceOf(address acc) public view returns (uint256) {
        return balances_[acc];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed_[owner][spender];
    }

    function transfer(address recipient, uint256 amt) public returns (bool) {
        require(balances_[msg.sender] >= amt, "Insufficient");
        balances_[msg.sender] -= amt;
        balances_[recipient] += amt;
        emit Transfer(msg.sender, recipient, amt);
        return true;
    }

    function approve(address spender, uint256 amt) public returns (bool) {
        allowed_[msg.sender][spender] = amt;
        emit Approval(msg.sender, spender, amt);
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) public returns (bool) {
        require(balances_[from] >= amt, "Insufficient");
        require(allowed_[from][msg.sender] >= amt, "Not allowed");
        balances_[from] -= amt;
        balances_[to] += amt;
        allowed_[from][msg.sender] -= amt;
        emit Transfer(from, to, amt);
        return true;
    }
}