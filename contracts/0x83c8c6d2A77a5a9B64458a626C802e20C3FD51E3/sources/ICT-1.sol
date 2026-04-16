// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.31;

interface IPancakeFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
interface IPancakeRouter02 {
    function factory() external view returns (address);
    function WETH() external view returns (address);
}
interface IBEP20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address internal _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_msgSender() == _owner, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NXC is IBEP20, Ownable {

    string private _name = "Nexa Chain"; 
    string private _symbol = "NXC"; 
    uint8 private constant _decimal = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public buyFee = 0;
    uint256 public sellFee = 0;
    address public teamWallet = 0xaE5a5e02C67f31bC2B69cDE899B4978CcD7Eb800;

    mapping(address => bool) private _isExcludedFromFee;

    bool public tradingEnabled = false;

    IPancakeRouter02 public pancakeV2Router;
    address public pancakeV2Pair;
    mapping(address => bool) public isLiquidityPair;

    constructor() {
        pancakeV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        address pair = IPancakeFactory(pancakeV2Router.factory()).createPair(
            address(this),
            pancakeV2Router.WETH()
        );
        pancakeV2Pair = pair;
        isLiquidityPair[pair] = true;

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;

        uint256 supply = 10_000_000_000 * (10 ** uint256(_decimal));
        _mint(_owner, supply);
    }


    function name() external view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external pure override returns (uint8) {
        return _decimal;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        uint256 cur = _allowances[from][_msgSender()];
        require(cur >= amount, "BEP20: insufficient allowance");
        unchecked {
            _allowances[from][_msgSender()] = cur - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "BEP20: Trading is already enabled");
        tradingEnabled = true;
    }

    function includeAndExcludeFromFee(
        address account,
        bool isExcluded
    ) external onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setLiquidityPair(address pair, bool value) external onlyOwner {
        require(pair != address(0), "BEP20: Pair Address cannot be zero");
        isLiquidityPair[pair] = value;
        if (value && pancakeV2Pair == address(0)) {
            pancakeV2Pair = pair;
        }
    }

    function setBuyAndsellFee(uint256 buy, uint256 sell) external onlyOwner {
        require(buy <= 100 && sell <= 100, "Fee is >100");
        buyFee = buy;
        sellFee = sell;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "BEP20: zero address");
         require(amount > 0, "BEP20: amount=0");

        if (!tradingEnabled) {
            require(
                from == _owner ||
                    to == _owner ||
                    from == address(this) ||
                    to == address(this) ||
                    from == address(pancakeV2Router) ||
                    to == address(pancakeV2Router) ||
                    from == pancakeV2Pair ||
                    to == pancakeV2Pair,
                "BEP20: Trading not enabled"
            );
            _basicTransfer(from, to, amount);
            return;
        }

        bool feeTrue = !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to] &&
            (isLiquidityPair[from] || isLiquidityPair[to]);

        if (!feeTrue) {
            _basicTransfer(from, to, amount);
            return;
        }

        uint256 fee;
        if (isLiquidityPair[from] && buyFee > 0)
            fee = (amount * buyFee) / 100; // buy
        else if (isLiquidityPair[to] && sellFee > 0)
            fee = (amount * sellFee) / 100; // sell

        if (fee > 0) {
            uint256 remaining = amount - fee;
            _deb(from, amount);
            _cre(teamWallet, fee);
            _cre(to, remaining);
            emit Transfer(from, teamWallet, fee);
            emit Transfer(from, to, remaining);
        } else {
            _basicTransfer(from, to, amount);
        }
    }

    function _basicTransfer(address from, address to, uint256 amount) private {
        _deb(from, amount);
        _cre(to, amount);
        emit Transfer(from, to, amount);
    }
    function _deb(address from, uint256 amount) private {
        uint256 bal = _balances[from];
        require(bal >= amount, "BEP20: balance");
        unchecked {
            _balances[from] = bal - amount;
        }
    }
    function _cre(address to, uint256 amount) private {
        unchecked {
            _balances[to] += amount;
        }
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(address own, address spen, uint256 amount) internal {
        require(own != address(0) && spen != address(0), "BEP20: approve to zero address");
        _allowances[own][spen] = amount;
        emit Approval(own, spen, amount);
    }
}
