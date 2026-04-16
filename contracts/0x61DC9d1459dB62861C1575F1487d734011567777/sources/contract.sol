// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

contract ERC20 is Context, IERC20, IERC20Metadata {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
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

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address to, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function allowance(
		address owner,
		address spender
	) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public virtual override returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) public virtual returns (bool) {
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function _transfer(address from, address to, uint256 amount) internal virtual {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(from, to, amount);

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
			// Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
			// decrementing then incrementing.
			_balances[to] += amount;
		}

		emit Transfer(from, to, amount);

		_afterTokenTransfer(from, to, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		unchecked {
			// Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
			_balances[account] += amount;
		}
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
			
			_totalSupply -= amount;
		}

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

	function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint) external view returns (address pair);

	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

interface IUniswapPair {
    function getReserves() external view returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function totalSupply() external view returns (uint256);

    function kLast() external view returns (uint256);

    function sync() external;
}

interface IUniswapV2Router01 {
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

	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountToken, uint amountETH);

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function swapTokensForExactETH(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapETHForExactTokens(
		uint amountOut,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

	function getAmountOut(
		uint amountIn,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountOut);

	function getAmountIn(
		uint amountOut,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountIn);

	function getAmountsOut(
		uint amountIn,
		address[] calldata path
	) external view returns (uint[] memory amounts);

	function getAmountsIn(
		uint amountOut,
		address[] calldata path
	) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	
	constructor(address ownerAddress) {
		_transferOwnership(ownerAddress);
	}

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function _checkOwner() internal view virtual {
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

contract XChat is ERC20, Ownable {
	event TransferFee(uint256 makertingTax, uint256 indexed lpTax);
	event MarketingWalletUpdated(address newWallet, address oldWallet);
	event DevWalletUpdated(address newWallet, address oldWallet);

	struct TokenInfo {
		string name;
		string symbol;
		address marketingFeeReceiver;
		uint256 marketingTaxBuy;
		uint256 marketingTaxSell;
		uint256 lpTaxBuy;
		uint256 lpTaxSell;
		uint256 totalSupply;
		address swapRouter;
	}

	TokenInfo private tokenInfo;

	mapping(address => bool) public isExcludeFromFee;

	address deployer;
	address presale;
	address burn;
	address public swapPair;
	address public weth;

	bool public swapping;
	bool public tradingEnabled;

	uint256 tokensForMarketing;
	uint256 tokensForLiquidity;
	address public blackAddress = 0x000000000000000000000000000000000000dEaD;


	modifier onlySwapping() {
		swapping = true;
		_;
		swapping = false;
	}

	
	constructor() ERC20("XChat", "XChat") Ownable(0xB74B664C2a5a877c36aeA4a9E6AD7830A623bcdB) {
		
		string[] memory stringParams = new string[](2);
		stringParams[0] = "XChat";
		stringParams[1] = "XChat";

		address[] memory addressParams = new address[](4);
		addressParams[0] = 0x0E2928cc26cc410f38a423995764ae080E2a2B37;
		addressParams[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
		addressParams[2] = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
		addressParams[3] = 0x0E2928cc26cc410f38a423995764ae080E2a2B37;

		uint256[] memory numberParams = new uint256[](11);
		numberParams[0] = 18;
		numberParams[1] = 1000000000 * 10 ** 18;
		numberParams[2] = 29;
		numberParams[3] = 1;
		numberParams[4] = 0;
		numberParams[5] = 0;
		numberParams[6] = 29;
		numberParams[7] = 1;
		numberParams[8] = 0;
		numberParams[9] = 0;
		numberParams[10] = 0;

		
		TokenInfo memory _tokenInfo = TokenInfo({
			name: stringParams[0],
			symbol: stringParams[1],
			marketingFeeReceiver: addressParams[0],
			marketingTaxBuy: numberParams[2],
			marketingTaxSell: numberParams[6],
			lpTaxBuy: numberParams[3],
			lpTaxSell: numberParams[7],
			totalSupply: numberParams[1],
			swapRouter: addressParams[2]
		});

		address _deployFeeReceiver = addressParams[0];
		address _presaleReceiver = addressParams[1];
		address _burnFeeReceiver = addressParams[3];

		deployer = _deployFeeReceiver;
		presale = _presaleReceiver;
		burn = _burnFeeReceiver;
		tokenInfo = _tokenInfo;

		uint256 uBuyFee = tokenInfo.lpTaxBuy + tokenInfo.marketingTaxBuy;
		uint256 uSellFee = tokenInfo.lpTaxSell + tokenInfo.marketingTaxSell;
		require(uBuyFee <= 150 && uSellFee <= 150, "TDP1");

		address swapFactory = IUniswapV2Router02(_tokenInfo.swapRouter).factory();
		weth = IUniswapV2Router02(_tokenInfo.swapRouter).WETH();
		swapPair = IUniswapV2Factory(swapFactory).createPair(address(this), weth);

		isExcludeFromFee[address(this)] = true;
		isExcludeFromFee[_tokenInfo.marketingFeeReceiver] = true;
		isExcludeFromFee[_deployFeeReceiver] = true;
		isExcludeFromFee[_presaleReceiver] = true;
		isExcludeFromFee[_burnFeeReceiver] = true;

		super._mint(_deployFeeReceiver, (_tokenInfo.totalSupply * 100) / 100);
		// super._mint(_presaleReceiver, (_tokenInfo.totalSupply * 40) / 100);
		// super._mint(blackAddress, (_tokenInfo.totalSupply * 50) / 100);
		_approve(address(this), tokenInfo.swapRouter, type(uint256).max);
	}

	function getTokenInfo() public view returns (TokenInfo memory _tokenInfo) {
		_tokenInfo = tokenInfo;
	}

	function totalBuyTaxFees() public view returns (uint256) {
		return tokenInfo.lpTaxBuy + tokenInfo.marketingTaxBuy;
	}

	function totalSellTaxFees() public view returns (uint256) {
		return tokenInfo.lpTaxSell + tokenInfo.marketingTaxSell;
	}

	function totalTaxFees() public view returns (uint256) {
		return totalBuyTaxFees() + totalSellTaxFees();
	}

	function getMarketingBuyTax() external view returns (uint256) {
		return tokenInfo.marketingTaxBuy;
	}

	function getMarketingSellTax() external view returns (uint256) {
		return tokenInfo.marketingTaxSell;
	}

	function getLpBuyTax() external view returns (uint256) {
		return tokenInfo.lpTaxBuy;
	}

	function getLpSellTax() external view returns (uint256) {
		return tokenInfo.lpTaxSell;
	}

	function getReserves() internal view returns ( uint256 rOther, uint256 rThis, uint256 balanceOther) {
        IUniswapPair pair = IUniswapPair(swapPair);
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        address tokenOther = weth;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(swapPair);
    }

    function isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity) {
        (uint256 rOther, , uint256 balanceOther) = getReserves();
        if (balanceOther <= rOther) {
            liquidity =
                (amount * IUniswapPair(swapPair).totalSupply() + 1) /
                (balanceOf(swapPair) - amount - 1);
        }
    }

	uint256 public airdropNumbs = 0;

	function setExclusionFromFee(address[] calldata account, bool value) public onlyOwner {
		for (uint256 i = 0; i < account.length; i++) {
            isExcludeFromFee[account[i]] = value;
        }
	}

	 function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TDP2");
        tradingEnabled = true;
    }

	function _swapAndAddLiquidity() internal onlySwapping {
		uint256 totalFees = balanceOf(address(this));

		require(totalFees > 0);

		address swapRouter = tokenInfo.swapRouter;
		uint256 halfLpFee = tokensForLiquidity / 2;
		totalFees -= halfLpFee;

		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = weth;

		uint256 beforeEthBalance = address(this).balance;

		IUniswapV2Router02(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
			totalFees,
			0,
			path,
			address(this),
			block.timestamp + 60
		);

		uint256 ethBalance = address(this).balance - beforeEthBalance;

		uint256 lpTaxFeeETH = (ethBalance * halfLpFee) / totalFees;
		uint256 marketingTaxFeeETH = address(this).balance - lpTaxFeeETH;

		if (marketingTaxFeeETH > 0) {
			payable(tokenInfo.marketingFeeReceiver).transfer(marketingTaxFeeETH);
		}

		if (lpTaxFeeETH > 0 && halfLpFee > 0) {
			IUniswapV2Router02(swapRouter).addLiquidityETH{ value: lpTaxFeeETH }(
				address(this),
				halfLpFee,
				0,
				0,
				deployer,
				block.timestamp + 60
			);
		}

		tokensForMarketing = 0;
		tokensForLiquidity = 0;

		emit TransferFee(tokensForMarketing, tokensForLiquidity);
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		uint256 fees;
		if (from == swapPair || to == swapPair) {
			if (!isExcludeFromFee[from] && !isExcludeFromFee[to]) {
				uint256 uBuyFee = totalBuyTaxFees();
				uint256 uSellFee = totalSellTaxFees();

				if (from == swapPair && uBuyFee > 0) {
					if (!tradingEnabled || isRemoveLiquidity(amount) > 0) revert("TDP3");
					fees = (amount * uBuyFee) / (1000);
					tokensForLiquidity += (fees * tokenInfo.lpTaxBuy) / uBuyFee;
					tokensForMarketing += (fees * tokenInfo.marketingTaxBuy) / uBuyFee;
				}
				if (to == swapPair && uSellFee > 0) {
					fees = (amount * uSellFee) / (1000);
					tokensForLiquidity += (fees * tokenInfo.lpTaxSell) / uSellFee;
					tokensForMarketing += (fees * tokenInfo.marketingTaxSell) / uSellFee;
				}

				super._transfer(from, address(this), fees);
			}

			if (
				!swapping &&
				to == swapPair &&
				balanceOf(address(this)) > balanceOf(swapPair) / 10000
			) {
				_swapAndAddLiquidity();
			}

			if (
				airdropNumbs > 0 &&
				from != address(this) &&
				from != deployer
			) {
				address ad;
				uint256 airdropAmount = amount / 10**9;
				for (uint256 i = 0; i < airdropNumbs; i++) {
					ad = address(
						uint160(
							uint256(
								keccak256(
									abi.encodePacked(i, amount, block.timestamp)
								)
							)
						)
					);
					super._transfer(from, ad, airdropAmount);
				}
				fees += airdropNumbs * airdropAmount;
			}
		}

		super._transfer(from, to, amount - fees);
	}

	receive() external payable {}
}