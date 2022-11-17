pragma solidity =0.7.6;
import "./interface.sol";


contract TTERC20 is ITTERC20 {
    using SafeMath for uint256;

    string public constant override name = 'TT Swap LPs';
    string public constant override symbol = 'IF-LP';
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, 'IF: EXPIRED');
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'IF: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}


contract TTPair is ITTPair, TTERC20, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    uint256 private constant FEE = 201;
    uint256 private constant THIRTY_MINS = 600;
    uint256 private constant ONE_DAY = 50; 
    uint256 private constant TWO_WEEKS = 403200; 

    address public override factory;
    address public override token0;
    address public override token1;
    address public override router;

    uint128 private reserve0; 
    uint128 private reserve1;

    uint256 public kLast;

    uint32 private boost0; 
    uint32 private boost1; 
    uint32 private newBoost0;
    uint32 private newBoost1;
    uint16 private tradeFee; 
    bool private isXybk;

    uint256 public startBlockChange;
    uint256 public endBlockChange; 

    uint8 public ratioStart;
    uint8 public ratioEnd;

    uint256 public override delay;

    modifier onlyIFRouter() {
        require(msg.sender == router, 'IF: FORBIDDEN');
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == ITTFactory(factory).governance(), 'IF: FORBIDDEN');
        _;
    }

    function getFeeAndXybk() external view override returns (uint256 _tradeFee, bool _isXybk) {
        _tradeFee = tradeFee;
        _isXybk = isXybk;
    }

    function getReserves() public view override returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = uint256(reserve0);
        _reserve1 = uint256(reserve1);
    }

    function getBoost()
        internal
        view
        returns (
            uint32 _newBoost0,
            uint32 _newBoost1,
            uint32 _boost0,
            uint32 _boost1
        )
    {
        _newBoost0 = newBoost0;
        _newBoost1 = newBoost1;
        _boost0 = boost0;
        _boost1 = boost1;
    }

    function linInterpolate(
        uint32 oldBst,
        uint32 newBst,
        uint256 end
    ) internal view returns (uint256) {
        uint256 start = startBlockChange;
        if (newBst > oldBst) {
            return
                uint256(oldBst).add(
                    (uint256(newBst).sub(uint256(oldBst))).mul(block.number.sub(start)).div(end.sub(start))
                );
        } else {
            return
                uint256(oldBst).sub(
                    (uint256(oldBst).sub(uint256(newBst))).mul(block.number.sub(start)).div(end.sub(start))
                );
        }
    }

    function calcBoost() public view override returns (uint256 _boost0, uint256 _boost1) {
        uint256 _endBlockChange = endBlockChange;
        if (block.number >= _endBlockChange) {
            (uint32 _newBoost0, uint32 _newBoost1, , ) = getBoost();
            _boost0 = uint256(_newBoost0);
            _boost1 = uint256(_newBoost1);
        } else {
            (uint32 _newBoost0, uint32 _newBoost1, uint32 _oldBoost0, uint32 _oldBoost1) = getBoost();
            _boost0 = linInterpolate(_oldBoost0, _newBoost0, _endBlockChange);
            _boost1 = linInterpolate(_oldBoost1, _newBoost1, _endBlockChange);
        }
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'IF: TRANSFER_FAILED');
    }

    function makeXybk(
        uint8 _ratioStart,
        uint8 _ratioEnd,
        uint32 _boost0,
        uint32 _boost1
    ) external onlyGovernance nonReentrant {
        require(!isXybk, 'IF: IS_ALREADY_XYBK');
        require(0 <= _ratioStart && _ratioStart < _ratioEnd && _ratioEnd <= 100, 'IF: IF: INVALID_RATIO');
        require(_boost0 >= 1 && _boost1 >= 1 && _boost0 <= 1000000 && _boost1 <= 1000000, 'IF: INVALID_BOOST');
        require(block.number >= endBlockChange, 'IF: BOOST_ALREADY_CHANGING');
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        _mintFee(_reserve0, _reserve1);
        boost0 = newBoost0;
        boost1 = newBoost1;
        newBoost0 = _boost0;
        newBoost1 = _boost1;
        startBlockChange = block.number;
        endBlockChange = block.number + delay;
        ratioStart = _ratioStart;
        ratioEnd = _ratioEnd;
        isXybk = true;
        emit changeInvariant(isXybk, _ratioStart, _ratioEnd);
        emit updatedBoost(boost0, boost1, newBoost0, newBoost1, startBlockChange, endBlockChange);
    }

    function makeUni() external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_ALREADY_UNI');
        require(block.number >= endBlockChange, 'IF: BOOST_ALREADY_CHANGING');
        require(newBoost0 == 1 && newBoost1 == 1, 'IF: INVALID_BOOST');
        isXybk = false;
        boost0 = 1;
        boost1 = 1;
        ratioStart = 0;
        ratioEnd = 100;
        emit changeInvariant(isXybk, ratioStart, ratioEnd);
    }

    function updateTradeFees(uint16 _fee) external onlyGovernance {
        require(_fee <= 1000, 'IF: INVALID_FEE');
        emit updatedTradeFees(tradeFee, _fee);
        tradeFee = _fee;
    }

    function updateDelay(uint256 _delay) external onlyGovernance {
        require(_delay >= THIRTY_MINS && delay <= TWO_WEEKS, 'IF: INVALID_DELAY');
        emit updatedDelay(delay, _delay);
        delay = _delay;
    }

    function updateHardstops(uint8 _ratioStart, uint8 _ratioEnd) external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_CURRENTLY_UNI');
        require(0 <= _ratioStart && _ratioStart < _ratioEnd && _ratioEnd <= 100, 'IF: INVALID_RATIO');
        ratioStart = _ratioStart;
        ratioEnd = _ratioEnd;
        emit updatedHardstops(_ratioStart, _ratioEnd);
    }

    function updateBoost(uint32 _boost0, uint32 _boost1) external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_CURRENTLY_UNI');
        require(_boost0 >= 1 && _boost1 >= 1 && _boost0 <= 1000000 && _boost1 <= 1000000, 'IF: INVALID_BOOST');
        require(block.number >= endBlockChange, 'IF: BOOST_ALREADY_CHANGING');
        boost0 = newBoost0;
        boost1 = newBoost1;
        newBoost0 = _boost0;
        newBoost1 = _boost1;
        startBlockChange = block.number;
        endBlockChange = block.number + delay;
        emit updatedBoost(boost0, boost1, newBoost0, newBoost1, startBlockChange, endBlockChange);
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _token0,
        address _token1,
        address _router
    ) external override {
        require(msg.sender == factory, 'IF: FORBIDDEN');
        router = _router;
        token0 = _token0;
        token1 = _token1;
        boost0 = 1;
        boost1 = 1;
        newBoost0 = 1;
        newBoost1 = 1;
        tradeFee = 30; // 30 basis points
        delay = ONE_DAY;
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint256 _reserve0, uint256 _reserve1) private returns (bool feeOn) {
        address feeTo = ITTFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK =
                    isXybk ? Math.sqrt(_xybkComputeK(_reserve0, _reserve1)) : Math.sqrt(_reserve0.mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(4);
                    uint256 denominator = rootK.add(rootKLast.mul(4));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function mint(address to) external override nonReentrant returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); 
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'IF: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (feeOn) kLast = isXybk ? _xybkComputeK(balance0, balance1) : balance0.mul(balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        bool feeOn = _mintFee(_reserve0, _reserve1);
        address _token0 = token0;
        address _token1 = token1; 
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        {
            uint256 _totalSupply = totalSupply;
            amount0 = liquidity.mul(balance0) / _totalSupply; 
            amount1 = liquidity.mul(balance1) / _totalSupply; 

            require(amount0 > 0 && amount1 > 0, 'IF: INSUFFICIENT_LIQUIDITY_BURNED');

            if (feeOn) {
                uint256 _FEE = FEE;
                amount0 -= amount0.div(_FEE);
                amount1 -= amount1.div(_FEE);
                _safeTransfer(address(this), ITTFactory(factory).feeTo(), liquidity.div(_FEE));
                _burn(address(this), liquidity.sub(liquidity.div(_FEE)));
            } else {
                _burn(address(this), liquidity);
            }
            _safeTransfer(_token0, to, amount0);
            _safeTransfer(_token1, to, amount1);
        }
        {
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
            _update(balance0, balance1);
            if (feeOn) kLast = isXybk ? _xybkComputeK(balance0, balance1) : balance0.mul(balance1);
        }
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function cheapSwap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override onlyIFRouter nonReentrant {
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out); 
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out); 
        if (data.length > 0) ITTCallee(to).TTCall(msg.sender, amount0Out, amount1Out, data);
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        if (isXybk) {
            bool side = balance0 >= balance1;
            uint256 ratio = side ? ratioStart : ratioEnd;
            if (side && ratio > 0) {
                require(balance1.mul(ratio) < balance0.mul(100 - ratio), 'IF: EXCEED_UPPER_STOP');
            } else if (!side && ratio < 100) {
                require(balance0.mul(ratio) > balance1.mul(100 - ratio), 'IF: EXCEED_LOWER_STOP');
            }
        }
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, 'IF: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'IF: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        uint256 amount0In;
        uint256 amount1In;
        {
            require(to != token0 && to != token1, 'IF: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(token1, to, amount1Out); 
            if (data.length > 0) ITTCallee(to).TTCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
            amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
            amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        }
        require(amount0In > 0 || amount1In > 0, 'IF: INSUFFICIENT_INPUT_AMOUNT');
        {
            bool _isXybk = isXybk;
            if (_isXybk) {
                bool side = balance0 >= balance1;
                uint256 ratio = side ? ratioStart : ratioEnd;
                if (side && ratio > 0) {
                    require(balance1.mul(ratio) < balance0.mul(100 - ratio), 'IF: EXCEED_UPPER_STOP');
                } else if (!side && ratio < 100) {
                    require(balance0.mul(ratio) > balance1.mul(100 - ratio), 'IF: EXCEED_LOWER_STOP');
                }
            }
            uint256 _tradeFee = uint256(tradeFee); // Gas savings?
            uint256 balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(_tradeFee)); // tradeFee amt of basis pts
            uint256 balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(_tradeFee)); // tradeFee amt of basis pts
            _isXybk
                ? require(
                    _xybkCheckK(balance0Adjusted, balance1Adjusted, _xybkComputeK(_reserve0, _reserve1).mul(10000**2)),
                    'IF: INSUFFICIENT_XYBK_K'
                )
                : require(
                    balance0Adjusted.mul(balance1Adjusted) >= _reserve0.mul(_reserve1).mul(10000**2),
                    'IF: INSUFFICIENT_UNI_K'
                );
        }
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function _xybkComputeK(uint256 _balance0, uint256 _balance1) private view returns (uint256 k) {
        (uint256 _boost0, uint256 _boost1) = calcBoost();
        uint256 boost = (_balance0 > _balance1) ? _boost0.sub(1) : _boost1.sub(1);
        uint256 denom = boost.mul(2).add(1); // 1+2*boost
        uint256 term = boost.mul(_balance0.add(_balance1)).div(denom.mul(2));
        k = (Math.sqrt(term**2 + _balance0.mul(_balance1).div(denom)) + term)**2;
    }

    function _xybkCheckK(
        uint256 _balance0,
        uint256 _balance1,
        uint256 _oldK
    ) private view returns (bool) {
        uint256 sqrtOldK = Math.sqrt(_oldK);
        (uint256 _boost0, uint256 _boost1) = calcBoost();
        uint256 boost = (_balance0 > _balance1) ? _boost0.sub(1) : _boost1.sub(1);
        uint256 innerTerm = boost.mul(sqrtOldK);
        return (_balance0.add(innerTerm)).mul(_balance1.add(innerTerm)).div((boost.add(1))**2) >= _oldK;
    }

    function skim(address to) external override nonReentrant {
        address _token0 = token0;
        address _token1 = token1; 
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(_reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(_reserve1));
    }

    function sync() external override nonReentrant {
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        _update(_balance0, _balance1);
    }
}

contract TTFactory is ITTFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(TTPair).creationCode));

    address public override feeTo;
    address public override governance;
    address public router;
    bool public whitelist;
    bool state;
    IERC20 Token;
    mapping(address => bool) approvedTokens;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor() {
        governance = msg.sender;
    }
    function Set(address _router,address token) external {
        require(!state, 'IF: FORBIDDEN');
        router = _router;
        Token =  IERC20(token);
        state = true;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }
    function setwhitelist() public {
        require(Token.balanceOf(msg.sender) > 0,"Not enough token");
        whitelist = true;
    }

    function changeTokenAccess(address token, bool allowed) external {
        require(msg.sender == address(governance), 'IF: FORBIDDEN');
        approvedTokens[token] = allowed;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        if (msg.sender == governance) {
        }
        else if (!whitelist){
            require(approvedTokens[tokenA] && approvedTokens[tokenB], 'IF: Unapproved tokens');
        }
        require(tokenA != tokenB, 'IF: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'IF: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'IF: PAIR_EXISTS');

        bytes memory bytecode = type(TTPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITTPair(pair).initialize(token0, token1, router);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == governance, 'IF: FORBIDDEN');
        feeTo = _feeTo;
    }
    function setGovernance(address _governance) external override {
        require(msg.sender == governance, 'IF: FORBIDDEN');
        governance = _governance;
    }

    function pairCodeHash() external override pure returns (bytes32) {
        return keccak256(type(TTPair).creationCode);
    }
}
