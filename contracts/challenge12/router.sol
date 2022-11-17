pragma solidity =0.7.6;

import "./interface.sol";

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma experimental ABIEncoderV2;

contract TTRouter02 is ITTRouter02, ReentrancyGuard {
    using SafeMath for uint256;

    address public immutable override factory;
    bytes32 immutable pairCodeHash;
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'TTRouter: EXPIRED');
        _;
    }
    constructor(address _factory) {
        factory = _factory;
        pairCodeHash = ITTFactory(_factory).pairCodeHash();
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        if (ITTFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ITTFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB, ) = getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal =  _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'TTRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'TTRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        nonReentrant
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ITTPair(pair).mint(to);
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) private ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(factory, tokenA, tokenB);
        ITTPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = ITTPair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'TTRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'TTRouter: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB) {
        return _removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override nonReentrant returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        ITTPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = _removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            ITTPair(pairFor(factory, input, output)).cheapSwap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TTRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'TTRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual override returns (uint256 amountB) {
        return _quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view override returns (uint256) {
        return getAmountOut(amountIn, tokenIn, tokenOut, factory);
    }

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view override returns (uint256) {
        return getAmountIn(amountOut, tokenIn, tokenOut, factory);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return getAmountsIn(factory, amountOut, path);
    }
        function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TTLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TTLibrary: ZERO_ADDRESS');
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        pairCodeHash // init code hash
                        // de353d433fa966b87b4bc7c1e4c8035e23fd1ae8b9908cc103a0403d4abfbe13 in prod
                    )
                )
            )
        );
    }
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            address pair
        )
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pair = pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = ITTPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }   
    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'TTLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TTLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function calcArtiLiquidityTerm(uint256 _boost, uint256 _sqrtK) internal pure returns (uint256) {
        return (_boost - 1).mul(_sqrtK);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, 'TTLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountInPostFee;
        address pair;
        bool isMatch;
        {
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
            require(reserveIn > 0 && reserveOut > 0, 'TTLibrary: INSUFFICIENT_LIQUIDITY');
        }
        uint256 artiLiqTerm;
        bool isXybk;
        {
            uint256 fee;
            (fee, isXybk) = ITTPair(pair).getFeeAndXybk();
            amountInPostFee = amountIn.mul(10000 - fee);
        }

        if (isXybk) {
            (uint256 boost0, uint256 boost1) = ITTPair(pair).calcBoost();
            uint256 sqrtK = xybkComputeSqrtK(isMatch, reserveIn, reserveOut, boost0, boost1);
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                if (reserveIn < sqrtK && boost0 != boost1) {
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub((sqrtK.sub(reserveIn)).mul(10000));
                    reserveIn = sqrtK;
                    reserveOut = sqrtK;
                }
            } else {
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
    }

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, 'TTLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 artiLiqTerm;
        uint256 fee;
        bool isMatch;
        {
            bool isXybk;
            uint256 boost0;
            uint256 boost1;
            {
                (address token0, ) = sortTokens(tokenIn, tokenOut);
                isMatch = token0 == tokenOut;
            }
            {
                address pair;
                (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
                require(reserveIn > 0 && reserveOut > 0, 'TTLibrary: INSUFFICIENT_LIQUIDITY');
                (fee, isXybk) = ITTPair(pair).getFeeAndXybk();
                (boost0, boost1) = ITTPair(pair).calcBoost();
            }
            if (isXybk) {
                uint256 sqrtK = xybkComputeSqrtK(isMatch, reserveOut, reserveIn, boost0, boost1);
                if (reserveOut.sub(amountOut) >= sqrtK) {
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                } else {
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
                    if (reserveOut > sqrtK && boost0 != boost1) {
                        amountIn = sqrtK.sub(reserveIn).mul(10000).div(10000 - fee);
                        amountOut = amountOut.sub(reserveOut.sub(sqrtK));
                        reserveOut = sqrtK;
                        reserveIn = sqrtK;
                    }
                }
            }
        }
        uint256 numerator = (reserveIn.add(artiLiqTerm)).mul(amountOut).mul(10000);
        uint256 denominator = (reserveOut.add(artiLiqTerm)).sub(amountOut).mul(10000 - fee);
        amountIn = amountIn.add((numerator / denominator).add(1));
    }

    function getAmountOutFeeOnTransfer(
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256, uint256) {
        uint256 reserveIn;
        uint256 reserveOut;
        address pair;
        bool isMatch;
        {
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut); // Should be reserve0/1 but reuse variables to save stack
            require(reserveIn > 0 && reserveOut > 0, 'TTLibrary: INSUFFICIENT_LIQUIDITY');
        }
        uint256 amountOut;
        uint256 artiLiqTerm;
        uint256 amountInPostFee;
        bool isXybk;
        {
            uint256 fee;
            uint256 balanceIn = IERC20(tokenIn).balanceOf(address(pair));
            require(balanceIn > reserveIn, 'TTLibrary: INSUFFICIENT_INPUT_AMOUNT');
            (fee, isXybk) = ITTPair(pair).getFeeAndXybk();
            amountInPostFee = (balanceIn.sub(reserveIn)).mul(10000 - fee);
        }
        if (isXybk) {
            (uint256 boost0, uint256 boost1) = ITTPair(pair).calcBoost();
            uint256 sqrtK = xybkComputeSqrtK(isMatch, reserveIn, reserveOut, boost0, boost1);
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                if (reserveIn < sqrtK && boost0 != boost1) {
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub(sqrtK.sub(reserveIn));
                    reserveOut = sqrtK;
                    reserveIn = sqrtK;
                }
            } else {
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
        return isMatch ? (uint256(0), amountOut) : (amountOut, uint256(0));
    }
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'TTLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(amounts[i], path[i], path[i + 1], factory);
        }
    }
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'TTLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(amounts[i], path[i - 1], path[i], factory);
        }
    }
    function xybkComputeSqrtK(
        bool isMatch,
        uint256 x, // if isMatch, x == token0
        uint256 y,
        uint256 boost0,
        uint256 boost1
    ) internal pure returns (uint256) {
        uint256 boost = isMatch ? ((x > y) ? boost0.sub(1) : boost1.sub(1)) : ((y > x) ? boost0.sub(1) : boost1.sub(1));
        uint256 denom = boost.mul(2).add(1); // 1+2*boost
        uint256 term = boost.mul(x.add(y)).div(denom.mul(2)); // boost*(x+y)/(2+4*boost)
        return Math.sqrt(term**2 + x.mul(y).div(denom)) + term;
    }
}
