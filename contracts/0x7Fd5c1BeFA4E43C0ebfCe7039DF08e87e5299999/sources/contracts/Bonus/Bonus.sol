// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "./ERC20.sol";
import {IERC20} from "./IERC20.sol";
import {Ownable} from "./Ownable.sol";
import {IUniswapV2Router02} from "./IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "./IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "./IUniswapV2Factory.sol";
import {Helper} from "./Helper.sol";
import {Math} from "./Math.sol";
import {Strings} from "./Strings.sol";

contract Bonus is ERC20, Ownable {
    struct TradeInfo {
        uint256 _buyCount;
        uint256 _sellCount;
    }
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public USDT;
    address public staking;
    address public marketingAddress;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;
    uint256 private constant Q112 = 2 ** 112;
    uint256 public constant MAX_TOTAL_SUPPLY = 100_000_000 ether; // 100,000,000 tokens
    uint256 public BASIS_POINTS = 1000;

    uint256 public sellBurnRate = 0; //0%
    uint256 public sellMarketingRate = 30; // 3%
    uint256 public buyBurnRate = 0; //0%
    uint256 public buyMarketingRate = 30; // 3%
    uint256 public max_sell_rate = 10; // 1%
    uint256 public max_buy_rate = 10; // 1%
    uint256 public minSellPriceBps = 950;
    uint32 public twapWindow = 10 minutes;
    uint256 public maxTradePerBlockMultiplier = 2;
    uint256 public oraclePriceCumulativeLast;
    uint32 public oracleTimestampLast;
    uint256 public twapPriceX112;
    uint256 public maxBuyValue = 10000 ether;
    uint256 public lastAutoBurnTimestamp = block.timestamp;
    uint256 public autoBurnInterval = 1 days;
    uint256 public autoBurnRate = 5; // 0.5%
    uint256 public taxRate = 150; // 15% of sell value

    bool public canAdd = false;
    bool public canRemove = false;
    bool public canAutoBurn = true;
    bool public canBuy = false;
    bool public stakingBuyInProgress;
    bool public isInitialized;
    bool private _inSwap;
    bool public shouldCheckRouter = true;

    mapping(address => bool) public feeWhitelisted;
    mapping(address => mapping(uint256 => TradeInfo)) public tradeInfoList;
    mapping(uint256 => uint256) public buyAmountPerBlock;
    mapping(uint256 => uint256) public sellAmountPerBlock;
    mapping(address => uint256) public userBuyValueList;
    mapping(address => uint256) public userSellValueList;
    mapping(address => uint256) public userSellTaxList;
    mapping(address _routerAddress => bool _routerList) public routerList;

    event TokensBurned(uint256 timestamp, uint256 amount, string _type);
    event OracleUpdated(
        uint256 priceCumulative,
        uint32 timestamp,
        uint32 timeElapsed,
        uint256 twapPriceX112,
        string twapPriceFormatted
    );
    event TradeInfoEvent(
        address txOwner,
        uint256 blockNumber,
        uint256 _buyCount,
        uint256 _sellCount
    );
    event TransferEvent(
        address txOrigin,
        address msgSender,
        address from,
        address to,
        uint256 value,
        bool _isAdd,
        bool _isRemove,
        bool _isBuy,
        bool _isSell,
        bool _isTransfer
    );

    modifier lockSwap() {
        require(!_inSwap, "in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(
        address _usdt,
        address _router,
        address _initialOwner,
        address _marketingAddress
    ) ERC20("Bonus", "Bonus") Ownable(_initialOwner) {
        require(
            _usdt != address(0) && _router != address(0),
            "USDT and router cannot be zero"
        );
        require(
            _marketingAddress != address(0),
            "Marketing address cannot be zero"
        );
        USDT = _usdt;
        marketingAddress = _marketingAddress;
        uniswapV2Router = IUniswapV2Router02(_router);
        routerList[_router] = true;
        _mint(owner(), MAX_TOTAL_SUPPLY);
        feeWhitelisted[owner()] = true;
        if (block.chainid == 56) {
            routerList[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
            routerList[0x31c2F6fcFf4F8759b3Bd5Bf0e1084A055615c768] = true;
            routerList[0xc0e6EEF914d7BB0D4e6F72bc64ed69383fDb06E4] = true;
        }
    }

    function setMaxTradeRate(
        uint256 _max_sell_rate,
        uint256 _max_buy_rate
    ) external onlyOwner {
        //BASIS_POINTS=1000
        require(
            _max_sell_rate <= 30 && _max_buy_rate <= 30,
            "Max trade rate cannot be greater than 3%"
        );
        max_sell_rate = _max_sell_rate;
        max_buy_rate = _max_buy_rate;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 300, "Tax rate cannot be greater than 30%");
        taxRate = _taxRate;
    }

    function setMaxBuyValue(uint256 _maxBuyValue) external onlyOwner {
        maxBuyValue = _maxBuyValue;
    }

    function setMinSellPriceBps(uint256 _minSellPriceBps) external onlyOwner {
        minSellPriceBps = _minSellPriceBps;
    }

    function setShouldCheckRouter(bool _shouldCheckRouter) external onlyOwner {
        shouldCheckRouter = _shouldCheckRouter;
    }

    function setrouterList(
        address _routerAddress,
        bool _routerList
    ) external onlyOwner {
        routerList[_routerAddress] = _routerList;
    }

    function setCanBuy(bool _canBuy) external {
        require(
            msg.sender == staking || msg.sender == owner(),
            "only staking or owner can set can buy"
        );
        canBuy = _canBuy;
    }

    function setCanAdd(bool _canAdd) external onlyOwner {
        canAdd = _canAdd;
    }

    function setCanRemove(bool _canRemove) external onlyOwner {
        canRemove = _canRemove;
    }

    function setCanAutoBurn(bool _canAutoBurn) external onlyOwner {
        canAutoBurn = _canAutoBurn;
    }

    function setAutoBurnInterval(uint256 _autoBurnInterval) external onlyOwner {
        uint256 minAutoBurnInterval = block.chainid == 56
            ? 24 hours
            : 5 minutes;
        require(
            _autoBurnInterval >= minAutoBurnInterval,
            string(
                abi.encodePacked(
                    "Auto burn interval cannot be less than ",
                    Strings.toString(minAutoBurnInterval)
                )
            )
        );
        autoBurnInterval = _autoBurnInterval;
    }

    function setAutoBurnRate(uint256 _autoBurnRate) external onlyOwner {
        //BASIS_POINTS=1000
        require(
            _autoBurnRate <= 10,
            "Auto burn rate cannot be greater than 1%"
        );
        autoBurnRate = _autoBurnRate;
    }

    function setMaxTradePerBlockMultiplier(
        uint256 _maxTradePerBlockMultiplier
    ) external onlyOwner {
        require(
            _maxTradePerBlockMultiplier <= 2,
            "Max trade per block multiplier cannot be greater than 2"
        );
        maxTradePerBlockMultiplier = _maxTradePerBlockMultiplier;
    }

    function setUSDT(address _USDT) external onlyOwner {
        require(_USDT != address(0), "USDT address cannot be zero");
        USDT = _USDT;
    }

    function setSellFeeRates(
        uint256 _sellBurnRate,
        uint256 _sellMarketingRate
    ) external onlyOwner {
        //BASIS_POINTS=1000
        require(
            _sellBurnRate + _sellMarketingRate <= 200,
            "Sell fee rates cannot be greater than 20%"
        );
        sellBurnRate = _sellBurnRate;
        sellMarketingRate = _sellMarketingRate;
    }

    function setBuyFeeRates(
        uint256 _buyBurnRate,
        uint256 _buyMarketingRate
    ) external onlyOwner {
        //BASIS_POINTS=1000
        require(
            _buyBurnRate + _buyMarketingRate <= 200,
            "Buy fee rates cannot be greater than 20%"
        );
        buyBurnRate = _buyBurnRate;
        buyMarketingRate = _buyMarketingRate;
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0), "Staking address cannot be zero");
        staking = _staking;
    }

    function setTwapWindow(uint32 _twapWindow) external onlyOwner {
        require(_twapWindow >= 5 minutes, "Invalid TWAP window");
        twapWindow = _twapWindow;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(
            _marketingAddress != address(0),
            "Marketing address cannot be zero"
        );
        marketingAddress = _marketingAddress;
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Pair address cannot be zero");
        uniswapV2Pair = IUniswapV2Pair(_pair);
    }

    function init() external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(address(uniswapV2Pair) != address(0), "Pair not set");
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = _currentCumulativePrices();

        oraclePriceCumulativeLast = uniswapV2Pair.token0() == USDT
            ? price1Cumulative
            : price0Cumulative;

        oracleTimestampLast = blockTimestamp;
        isInitialized = true;
    }

    function setBatchFeeWhitelisted(
        address[] memory accounts,
        bool _whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(
                account != address(0) &&
                    account != address(uniswapV2Pair) &&
                    account != staking,
                "invalid account"
            );
            feeWhitelisted[account] = _whitelisted;
        }
    }

    function getUSDTReserve() public view returns (uint112 usdtReserve) {
        try uniswapV2Pair.getReserves() returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32
        ) {
            return uniswapV2Pair.token0() == USDT ? reserve0 : reserve1;
        } catch {
            return 0;
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        return Helper.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn) {
        return Helper.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function isContract(address account) public view returns (bool) {
        return Helper.isContract(account);
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address sender = _msgSender();
        _update(sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _update(from, to, value);
        return true;
    }

    function _emitTransferEvent(
        address txOrigin,
        address msgSender,
        address from,
        address to,
        uint256 value,
        bool _isAdd,
        bool _isRemove,
        bool _isBuy,
        bool _isSell,
        bool _isTransfer
    ) internal {
        emit TransferEvent(
            txOrigin,
            msgSender,
            from,
            to,
            value,
            _isAdd,
            _isRemove,
            _isBuy,
            _isSell,
            _isTransfer
        );
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(to != address(0), "to cannot be zero");
        address txOrigin = tx.origin;
        address msgSender = msg.sender;
        bool _isAdd;
        bool _isRemove;
        bool _isBuy;
        bool _isSell;
        bool _isTransfer;
        if (from == address(0)) {
            _isTransfer = true;
            super._update(from, to, value);
            _emitTransferEvent(
                txOrigin,
                msgSender,
                from,
                to,
                value,
                _isAdd,
                _isRemove,
                _isBuy,
                _isSell,
                _isTransfer
            );
            return;
        }
        bool isWhitelisted = feeWhitelisted[from] || feeWhitelisted[to];
        if (address(uniswapV2Pair) == address(0)) {
            require(isWhitelisted, "pair not set");
            _isTransfer = true;
            super._update(from, to, value);
            _emitTransferEvent(
                txOrigin,
                msgSender,
                from,
                to,
                value,
                _isAdd,
                _isRemove,
                _isBuy,
                _isSell,
                _isTransfer
            );
            return;
        }
        require(!feeWhitelisted[address(uniswapV2Pair)], "pair is whitelisted");
        bool isPairInvolved = from == address(uniswapV2Pair) ||
            to == address(uniswapV2Pair);
        if (!isPairInvolved) {
            _isTransfer = true;
            super._update(from, to, value);
            _emitTransferEvent(
                txOrigin,
                msgSender,
                from,
                to,
                value,
                _isAdd,
                _isRemove,
                _isBuy,
                _isSell,
                _isTransfer
            );

            return;
        } else {
            _tryUpdateOracle();
        }
        if (from == address(uniswapV2Pair)) {
            require(
                msgSender == address(uniswapV2Pair),
                "only pair can transfer from pair"
            );
            uint256 liq = _isRemoveLiquidity(value, to);
            _isRemove = liq > 0;
            _isBuy = !_isRemove;
            _handleBuy(from, to, value, _isRemove, isWhitelisted);
        } else if (to == address(uniswapV2Pair)) {
            require(
                !shouldCheckRouter || routerList[msgSender],
                "only router can sell or add liquidity"
            );
            (uint256 liquidity) = _isAddLiquidity(value);
            _isAdd = liquidity > 0;
            _isSell = !_isAdd;
            _handleSell(from, to, value, _isAdd, isWhitelisted);
        } else {
            _isTransfer = true;
            super._update(from, to, value);
        }
        _emitTransferEvent(
            txOrigin,
            msgSender,
            from,
            to,
            value,
            _isAdd,
            _isRemove,
            _isBuy,
            _isSell,
            _isTransfer
        );
    }

    function _handleAutoBurn() private returns (bool) {
        if (!canAutoBurn) {
            return false;
        }
        if (address(uniswapV2Pair) == address(0)) {
            return false;
        }
        if (block.timestamp - lastAutoBurnTimestamp < autoBurnInterval) {
            return false;
        }
        uint256 balanceOfUniswapV2Pair = balanceOf(address(uniswapV2Pair));
        uint256 totalBurnAmount = balanceOf(DEAD_ADDRESS);
        uint256 autoBurnAmount = (balanceOfUniswapV2Pair * autoBurnRate) /
            BASIS_POINTS;
        if (balanceOfUniswapV2Pair - autoBurnAmount <= 100_000 ether) {
            return false;
        }
        if (totalBurnAmount + autoBurnAmount >= MAX_TOTAL_SUPPLY / 2) {
            return false;
        }
        super._update(address(uniswapV2Pair), DEAD_ADDRESS, autoBurnAmount);
        uniswapV2Pair.sync();
        lastAutoBurnTimestamp = block.timestamp;
        emit TokensBurned(block.timestamp, autoBurnAmount, "_handleAutoBurn");
        return true;
    }

    function autoBurn() external {
        require(msg.sender == staking, "only staking");
        _handleAutoBurn();
    }

    function _checkTradeLimit(
        bool _isBuy,
        bool _isSell,
        uint256 blockNumber
    ) private {
        address txOwner = tx.origin;
        if (_isBuy) {
            tradeInfoList[txOwner][blockNumber]._buyCount += 1;
        }
        if (_isSell) {
            tradeInfoList[txOwner][blockNumber]._sellCount += 1;
        }
        string memory errorMessage = string(
            abi.encodePacked(
                "trade not allowed, txOwner=",
                Strings.toHexString(txOwner),
                ", blockNumber=",
                Strings.toString(blockNumber),
                ", buyCount=",
                Strings.toString(tradeInfoList[txOwner][blockNumber]._buyCount),
                ", sellCount=",
                Strings.toString(tradeInfoList[txOwner][blockNumber]._sellCount)
            )
        );
        if (_isBuy) {
            require(
                tradeInfoList[txOwner][blockNumber]._buyCount == 1 &&
                    tradeInfoList[txOwner][blockNumber]._sellCount == 0,
                errorMessage
            );
        }
        if (_isSell) {
            require(
                tradeInfoList[txOwner][blockNumber]._buyCount == 0 &&
                    tradeInfoList[txOwner][blockNumber]._sellCount <= 2,
                errorMessage
            );
        }
        emit TradeInfoEvent(
            txOwner,
            blockNumber,
            tradeInfoList[txOwner][blockNumber]._buyCount,
            tradeInfoList[txOwner][blockNumber]._sellCount
        );
    }

    function _checkBuyValue(
        uint256 amount,
        uint256 rOther,
        uint256 rThis,
        bool _isRemove,
        address to,
        bool _isWhitelisted
    ) private {
        uint256 buyValueInUSDT = Helper.getAmountIn(amount, rOther, rThis);
        if (!_isRemove && !_isWhitelisted) {
            userBuyValueList[to] += buyValueInUSDT;
        }
        require(
            buyValueInUSDT <= maxBuyValue,
            string(
                abi.encodePacked(
                    "buy value exceeds maxBuyValue, buyValueInUSDT=",
                    Strings.toString(buyValueInUSDT),
                    ", maxBuyValue=",
                    Strings.toString(maxBuyValue)
                )
            )
        );
    }

    function _checkSingleBuyLimit(uint256 amount, uint256 rThis) private view {
        require(
            amount <= (rThis * max_buy_rate) / BASIS_POINTS,
            string(
                abi.encodePacked(
                    "buy amount too large, amount=",
                    Strings.toString(amount),
                    ", reserveThis=",
                    Strings.toString(rThis),
                    ", maxBuyRate=",
                    Strings.toString(max_buy_rate),
                    ", basisPoints=",
                    Strings.toString(BASIS_POINTS)
                )
            )
        );
    }

    function _checkBlockBuyLimit(
        uint256 blockNumber,
        uint256 amount,
        uint256 rThis
    ) private view {
        uint256 newBuyAmountPerBlock = buyAmountPerBlock[blockNumber] + amount;
        require(
            newBuyAmountPerBlock <=
                (rThis * max_buy_rate * maxTradePerBlockMultiplier) /
                    BASIS_POINTS,
            string(
                abi.encodePacked(
                    "buy amount too large per block, newBuyAmountPerBlock=",
                    Strings.toString(newBuyAmountPerBlock),
                    ", reserveThis=",
                    Strings.toString(rThis),
                    ", maxBuyRate=",
                    Strings.toString(max_buy_rate),
                    ", maxTradePerBlockMultiplier=",
                    Strings.toString(maxTradePerBlockMultiplier),
                    ", basisPoints=",
                    Strings.toString(BASIS_POINTS)
                )
            )
        );
    }

    function _handleBuy(
        address from,
        address to,
        uint256 amount,
        bool _isRemove,
        bool _isWhitelisted
    ) private {
        uint256 blockNumber = block.number;
        bool stakingPrivileged = to == staking && stakingBuyInProgress;
        bool userPrivileged = _isWhitelisted && to == tx.origin;
        bool buyPrivileged = stakingPrivileged || userPrivileged;
        if (_isRemove) {
            require(canRemove || buyPrivileged, "remove not allowed");
        } else {
            if (!canBuy) {
                require(
                    buyPrivileged,
                    string(
                        abi.encodePacked(
                            "only staking can buy when canBuy=false, to=",
                            Strings.toHexString(to),
                            ", staking=",
                            Strings.toHexString(staking)
                        )
                    )
                );
            }
        }
        (uint256 rOther, uint256 rThis, , ) = _getReserves();
        _checkBuyValue(amount, rOther, rThis, _isRemove, to, _isWhitelisted);
        if (!stakingPrivileged) {
            _checkTwapPriceX112(to);
            _checkTradeLimit(true, false, blockNumber);
        }
        if (!buyPrivileged) {
            _checkSingleBuyLimit(amount, rThis);
            _checkBlockBuyLimit(blockNumber, amount, rThis);
        }
        buyAmountPerBlock[blockNumber] += amount;
        uint256 burnFee = _isRemove ? 0 : (amount * buyBurnRate) / BASIS_POINTS;
        uint256 marketingFee = _isRemove
            ? 0
            : (amount * buyMarketingRate) / BASIS_POINTS;
        if (buyPrivileged) {
            burnFee = 0;
            marketingFee = 0;
        }
        uint256 netAmount = amount - burnFee - marketingFee;
        if (burnFee > 0) {
            super._update(from, DEAD_ADDRESS, burnFee);
            emit TokensBurned(block.timestamp, burnFee, "_handleBuy");
        }
        if (marketingFee > 0) {
            require(
                marketingAddress != address(0),
                "Marketing address cannot be zero"
            );
            super._update(from, marketingAddress, marketingFee);
        }
        super._update(from, to, netAmount);
    }

    function _checkTwapPriceX112(address _user) private view {
        if (_user == address(this)) {
            return;
        }
        if (feeWhitelisted[_user]) {
            return;
        }
        require(
            twapPriceX112 > 0,
            string(
                abi.encodePacked(
                    "TWAP not ready, twapPriceX112=",
                    Strings.toString(twapPriceX112),
                    ", twapPrice=",
                    Strings.toFixed18((twapPriceX112 * 1e18) / Q112),
                    ", oracleTimestampLast=",
                    Strings.toString(oracleTimestampLast),
                    ", currentTimestamp=",
                    Strings.toString(block.timestamp)
                )
            )
        );
    }

    function _checkSingleSellLimit(uint256 amount, uint256 rThis) private view {
        require(
            amount <= (rThis * max_sell_rate) / BASIS_POINTS,
            string(
                abi.encodePacked(
                    "sell amount too large, amount=",
                    Strings.toString(amount),
                    ", reserveThis=",
                    Strings.toString(rThis),
                    ", maxSellRate=",
                    Strings.toString(max_sell_rate),
                    ", basisPoints=",
                    Strings.toString(BASIS_POINTS)
                )
            )
        );
    }

    function _checkTwapLimit(
        uint256 netAmount,
        uint256 rThis,
        uint256 rOther
    ) private view {
        uint256 amountOut = Helper.getAmountOut(netAmount, rThis, rOther);
        uint256 execPriceX112 = (amountOut << 112) / netAmount;
        require(
            execPriceX112 * BASIS_POINTS >= (twapPriceX112 * minSellPriceBps),
            string(
                abi.encodePacked(
                    "sell price too low vs TWAP, execPriceX112=",
                    Strings.toString(execPriceX112),
                    ", execPrice=",
                    Strings.toFixed18((execPriceX112 * 1e18) / Q112),
                    ", twapPriceX112=",
                    Strings.toString(twapPriceX112),
                    ", twapPrice=",
                    Strings.toFixed18((twapPriceX112 * 1e18) / Q112),
                    ", minSellPriceBps=",
                    Strings.toString(minSellPriceBps)
                )
            )
        );
    }

    function _checkBlockSellLimit(
        uint256 blockNumber,
        uint256 amount,
        uint256 rThis
    ) private view {
        uint256 newSellAmountPerBlock = sellAmountPerBlock[blockNumber] +
            amount;
        require(
            newSellAmountPerBlock <=
                (rThis * max_sell_rate * maxTradePerBlockMultiplier) /
                    BASIS_POINTS,
            string(
                abi.encodePacked(
                    "sell amount too large per block, newSellAmountPerBlock=",
                    Strings.toString(newSellAmountPerBlock),
                    ", reserveThis=",
                    Strings.toString(rThis),
                    ", maxSellRate=",
                    Strings.toString(max_sell_rate),
                    ", maxTradePerBlockMultiplier=",
                    Strings.toString(maxTradePerBlockMultiplier),
                    ", basisPoints=",
                    Strings.toString(BASIS_POINTS)
                )
            )
        );
    }

    event SellValueEvent(
        address from,
        uint256 amount,
        uint256 SellValueInBNB,
        uint256 oldUserBuyValue,
        uint256 oldUserSellValue,
        uint256 oldUserSellTax,
        uint256 newUserBuyValue,
        uint256 newUserSellValue,
        uint256 newUserSellTax,
        uint256 taxAmount
    );

    function _checkSellValue(
        uint256 amount,
        uint256 rOther,
        uint256 rThis,
        bool _isAdd,
        address from,
        bool _isWhitelisted
    ) private returns (uint256) {
        if (from == address(this)) {
            return 0;
        }
        uint256 sellValueInUSDT = Helper.getAmountOut(amount, rThis, rOther);
        if (!_isAdd && !_isWhitelisted) {
            uint256 oldUserBuyValue = userBuyValueList[from];
            uint256 oldUserSellValue = userSellValueList[from];
            uint256 oldUserSellTax = userSellTaxList[from];
            userSellValueList[from] += sellValueInUSDT;
            if (userSellValueList[from] > userBuyValueList[from]) {
                uint256 tax = ((userSellValueList[from] -
                    userBuyValueList[from]) * taxRate) / BASIS_POINTS;
                if (tax > userSellTaxList[from]) {
                    uint256 taxValue = tax - userSellTaxList[from];
                    userSellTaxList[from] += taxValue;
                    uint256 taxAmount = (taxValue * amount) / sellValueInUSDT;
                    emit SellValueEvent(
                        from,
                        amount,
                        sellValueInUSDT,
                        oldUserBuyValue,
                        oldUserSellValue,
                        oldUserSellTax,
                        userBuyValueList[from],
                        userSellValueList[from],
                        userSellTaxList[from],
                        taxAmount
                    );
                    return taxAmount;
                }
            }
        }
        return 0;
    }

    function _handleSell(
        address from,
        address to,
        uint256 amount,
        bool _isAdd,
        bool _isWhitelisted
    ) private {
        uint256 blockNumber = block.number;
        bool stakingPrivileged = from == staking && stakingBuyInProgress;
        bool addPrivileged = _isAdd && _isWhitelisted && from == tx.origin;
        if (_isAdd) {
            require(
                canAdd || _isWhitelisted || stakingPrivileged,
                "add not allowed"
            );
        }
        if (!stakingPrivileged) {
            _checkTwapPriceX112(from);
            _checkTradeLimit(false, true, blockNumber);
        }
        uint256 burnFee = _isAdd ? 0 : (amount * sellBurnRate) / BASIS_POINTS;
        uint256 marketingFee = _isAdd
            ? 0
            : (amount * sellMarketingRate) / BASIS_POINTS;
        if (stakingPrivileged || _isWhitelisted || from == address(this)) {
            burnFee = 0;
            marketingFee = 0;
        }
        if (burnFee > 0) {
            super._update(from, DEAD_ADDRESS, burnFee);
            emit TokensBurned(block.timestamp, burnFee, "_handleSell");
        }
        if (marketingFee > 0) {
            require(
                marketingAddress != address(0),
                "Marketing address cannot be zero"
            );
            super._update(from, marketingAddress, marketingFee);
        }
        uint256 netAmount = amount - burnFee - marketingFee;
        (uint256 rOther, uint256 rThis, , ) = _getReserves();
        uint256 taxAmount = _checkSellValue(
            netAmount,
            rOther,
            rThis,
            _isAdd,
            from,
            _isWhitelisted
        );
        if (taxAmount > 0) {
            super._update(from, address(this), taxAmount);
            _swapTokensForUSDT(taxAmount);
        }
        netAmount -= taxAmount;
        if (!stakingPrivileged && !addPrivileged) {
            _checkSingleSellLimit(amount, rThis);
            _checkTwapLimit(netAmount, rThis, rOther);
            _checkBlockSellLimit(blockNumber, amount, rThis);
        }
        sellAmountPerBlock[blockNumber] += amount;
        super._update(from, to, netAmount);
    }

    function _swapTokensForUSDT(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            tokenAmount,
            path
        );
        uint256 quoteOut = amounts[1];
        uint256 amountOutMin = (quoteOut * 990) / 1000;

        (bool success, bytes memory data) = address(uniswapV2Router).call(
            abi.encodeWithSelector(
                IUniswapV2Router02
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens
                    .selector,
                tokenAmount,
                amountOutMin,
                path,
                marketingAddress,
                block.timestamp + 300
            )
        );
        if (!success) {
            revert(string(data));
        }
    }

    function _getReserves()
        public
        view
        returns (
            uint256 rOther,
            uint256 rThis,
            uint256 balanceOther,
            uint256 balanceThis
        )
    {
        (uint r0, uint256 r1, ) = uniswapV2Pair.getReserves();
        address tokenOther = USDT;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
        balanceOther = IERC20(tokenOther).balanceOf(address(uniswapV2Pair));
        balanceThis = balanceOf(address(uniswapV2Pair));
    }

    function beginStakingBuyWindow() external {
        require(msg.sender == staking, "only staking");
        require(!stakingBuyInProgress, "window already open");
        stakingBuyInProgress = true;
    }

    function endStakingBuyWindow() external {
        require(msg.sender == staking, "only staking");
        require(stakingBuyInProgress, "window not open");
        stakingBuyInProgress = false;
    }

    function _updateOracle() internal {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = _currentCumulativePrices();

        uint256 priceCumulative = uniswapV2Pair.token0() == USDT
            ? price1Cumulative
            : price0Cumulative;
        uint32 timeElapsed;
        if (oracleTimestampLast != 0) {
            timeElapsed = blockTimestamp - oracleTimestampLast;
            require(timeElapsed >= twapWindow, "TWAP window too short");

            twapPriceX112 =
                (priceCumulative - oraclePriceCumulativeLast) /
                timeElapsed;
        }

        oraclePriceCumulativeLast = priceCumulative;
        oracleTimestampLast = blockTimestamp;
        emit OracleUpdated(
            priceCumulative,
            blockTimestamp,
            timeElapsed,
            twapPriceX112,
            Strings.toFixed18((twapPriceX112 * 1e18) / Q112)
        );
    }

    function _tryUpdateOracle() internal {
        if (!isInitialized) return;
        if (address(uniswapV2Pair) == address(0)) return;
        if (block.timestamp >= oracleTimestampLast + twapWindow) {
            _updateOracle();
        }
    }

    function _currentCumulativePrices()
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = uint32(block.timestamp % 2 ** 32);
        price0Cumulative = uniswapV2Pair.price0CumulativeLast();
        price1Cumulative = uniswapV2Pair.price1CumulativeLast();

        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = uniswapV2Pair.getReserves();

        if (
            blockTimestampLast != blockTimestamp && reserve0 > 0 && reserve1 > 0
        ) {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;

            price0Cumulative +=
                ((uint256(reserve1) << 112) / uint256(reserve0)) *
                timeElapsed;

            price1Cumulative +=
                ((uint256(reserve0) << 112) / uint256(reserve1)) *
                timeElapsed;
        }
    }

    function _isAddLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (
            uint256 rOther,
            uint256 rThis,
            uint256 balanceOther,

        ) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = (amount * rOther) / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            (liquidity, ) = _calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function _calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = IUniswapV2Pair(uniswapV2Pair).totalSupply();
        address feeTo = IUniswapV2Factory(uniswapV2Router.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = IUniswapV2Pair(uniswapV2Pair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply *
                        (rootK - rootKLast) *
                        8;
                    uint256 denominator = rootK * 17 + (rootKLast * 8);
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _isRemoveLiquidity(
        uint256 amount,
        address to
    ) internal view returns (uint256) {
        (uint256 rOther, , uint256 balanceOther, ) = _getReserves();
        bool isEOA = to == tx.origin;
        if (!isEOA && to != staking) {
            return 0;
        }
        address token0 = uniswapV2Pair.token0();
        bool isRemove = token0 == USDT
            ? balanceOther < rOther
            : balanceOther == rOther;
        if (isRemove && balanceOf(address(uniswapV2Pair)) > amount) {
            uint256 liquidity = (amount *
                IUniswapV2Pair(uniswapV2Pair).totalSupply()) /
                (balanceOf(address(uniswapV2Pair)) - amount);
            return liquidity;
        } else {
            return 0;
        }
    }

    function takeToken(address _token) external {
        require(msg.sender == marketingAddress, "only marketing address");
        IERC20(_token).transfer(
            marketingAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
