// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DigitalToken {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory n, string memory s, uint256 supply) {
        _name = n;
        _symbol = s;
        uint256 minted = supply * (10 ** decimals);
        _totalSupply = minted;
        _balances[msg.sender] = minted;
        emit Transfer(address(0), msg.sender, minted);
    }

    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function totalSupply() external view returns (uint256) { return _totalSupply; }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 a = _allowances[from][msg.sender];
        require(a >= amount, "allowance");
        unchecked { _allowances[from][msg.sender] = a - amount; }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero");
        uint256 bal = _balances[from];
        require(bal >= amount, "balance");
        unchecked {
            _balances[from] = bal - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}