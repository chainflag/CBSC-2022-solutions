pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./contracts/token/ERC20/ERC20.sol";
import "./contracts/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
interface IMdexFactory {

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function feeToRate() external view returns (uint256);

    function initCodeHash() external view returns (bytes32);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;

    function setInitCodeHash(bytes32) external;

    function sortTokens(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1);

    function pairFor(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function getReserves(address tokenA, address tokenB)
        external
        view
        returns (uint256 reserveA, uint256 reserveB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IMdexPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function price(address token, uint256 baseDecimal)
        external
        view
        returns (uint256);

    function initialize(address, address) external;
}

interface IMdexRouter {
    function factory() external pure returns (address);

    function WHT() external pure returns (address);

    function swapMining() external pure returns (address);

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
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract USDT is ERC20, Ownable {
    constructor() ERC20("USDT", "USDT") {}

    function mint(address addr, uint256 num) public onlyOwner {
        _mint(addr, num);
    }
}

contract QuintConventionalPool is Ownable {
    using SafeMath for uint256;
    address public distributor;
    IMdexPair public liquidityPair;

    IERC20 public token;

    uint256 public totalStakedToken;
    uint256 public totalStakedLp;
    uint256 public totalWithdrawanToken;
    uint256 public totalWithdrawanLp;
    uint256 public uniqueStakers;
    uint256 public totalTokenStakers;
    uint256 public totalLpStakers;

    uint256 public tokenReward1 = 3e5;
    uint256 public tokenReward2 = 25e12;
    uint256 public lpReward1 = 3e7;
    uint256 public lpReward2 = 25e3;
    uint256 public rewardDivider = 1e12;
    uint256 public minToken = 100e18;
    uint256 public minLp = 1e16;
    uint256 public withdrawDuration = 1 days;
    uint256 public withdrawTaxPercent = 90;
    uint256 public startime;
 
    struct TokenStake {
        uint256 amount;
        uint256 time;
        uint256 reward;
        uint256 startTime;
    }

    struct LpStake {
        uint256 lpAmount;
        uint256 amount;
        uint256 time;
        uint256 reward;
        uint256 startTime;
    }

    struct User {
        bool isExists;
        uint256 stakeCount;
        uint256 totalStakedToken;
        uint256 totalStakedLp;
        uint256 totalWithdrawanToken;
        uint256 totalWithdrawanLp;
    }

    mapping(address => User) users;
    mapping(address => TokenStake) tokenStakeRecord;
    mapping(address => LpStake) lpStakeRecord;

    event STAKE(address Staker, uint256 amount);
    event CLAIM(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);
    event RESTAKE(address staker, uint256 amount);
    event flag(string result,address challenger);
    constructor() Ownable() {}

    function SetAddress(address pair, address distributortoken)
        public
        onlyOwner
    {
        startime=block.timestamp;
        liquidityPair = IMdexPair(pair);
        token = IERC20(distributortoken);
        distributor = distributortoken;
    }

    function stake(uint256 _amount, uint256 _index) public {
        require(_index < 2, "Invalid index");
        if (!users[msg.sender].isExists) {
            users[msg.sender].isExists = true;
            uniqueStakers++;
        }
        uint256 preReward;
        if (_index == 0) {
            require(_amount >= minToken, "stake more than min amount");
            token.transferFrom(msg.sender, address(this), _amount);
            preReward = calculateTokenReward(msg.sender);
            if (preReward > 0) {
                _amount = _amount.add(preReward);
                token.transferFrom(distributor, address(this), preReward);
            }
            stakeToken(msg.sender, _amount);
            tokenStakeRecord[msg.sender].startTime = block.timestamp;
            totalTokenStakers++;
        } else {
            require(_amount >= minLp, "stake more than min amount");
            liquidityPair.transferFrom(msg.sender, address(this), _amount);
            preReward = calculateLpReward(msg.sender);
            if (preReward > 0) {
                token.transferFrom(distributor, address(this), preReward);
                stakeToken(msg.sender, preReward);
            }
            stakeLp(msg.sender, _amount);
            lpStakeRecord[msg.sender].startTime = block.timestamp;
            totalLpStakers++;
        }

        emit STAKE(msg.sender, _amount);
    }

    function reStake(uint256 _index) public {
        require(_index < 2, "Invalid index");
        uint256 preReward;
        if (_index == 0) {
            preReward = calculateTokenReward(msg.sender);
            if (preReward > 0) {
                token.transferFrom(distributor, address(this), preReward);
                stakeToken(msg.sender, preReward);
            }
        } else {
            preReward = calculateLpReward(msg.sender);
            if (preReward > 0) {
                token.transferFrom(distributor, address(this), preReward);
                stakeToken(msg.sender, preReward);
            }
        }

        emit RESTAKE(msg.sender, preReward);
    }

    function stakeToken(address _user, uint256 _amount) private {
        User storage user = users[_user];
        TokenStake storage userStake = tokenStakeRecord[_user];
        userStake.amount = userStake.amount.add(_amount);
        userStake.time = block.timestamp;
        user.stakeCount++;
        user.totalStakedToken = user.totalStakedToken.add(_amount);
        totalStakedToken = totalStakedToken.add(_amount);
    }

    function stakeLp(address _user, uint256 _amount) private {
        User storage user = users[_user];
        LpStake storage userStake = lpStakeRecord[_user];
        userStake.lpAmount = userStake.lpAmount.add(_amount);
        userStake.amount = userStake.amount.add(getTokenForLP(_amount));
        userStake.time = block.timestamp;
        user.stakeCount++;
        user.totalStakedLp = user.totalStakedLp.add(_amount);
        totalStakedLp = totalStakedLp.add(_amount);
    }

    function claim(uint256 _index) public {
        require(_index < 2, "Invalid index");
        User storage user = users[msg.sender];
        uint256 preReward;
        if (_index == 0) {
            preReward = calculateTokenReward(msg.sender);
            require(preReward > 0, "no reward yet");
            TokenStake storage userStake = tokenStakeRecord[msg.sender];
            token.transferFrom(distributor, msg.sender, preReward);
            userStake.time = block.timestamp;
            userStake.reward = userStake.reward.add(preReward);
            user.totalWithdrawanToken = user.totalWithdrawanToken.add(
                preReward
            );
        } else {
            preReward = calculateLpReward(msg.sender);
            require(preReward > 0, "no reward yet");
            LpStake storage userStake = lpStakeRecord[msg.sender];
            token.transferFrom(distributor, msg.sender, preReward);
            userStake.time = block.timestamp;
            userStake.reward = userStake.reward.add(preReward);
        }
        totalWithdrawanToken = totalWithdrawanToken.add(preReward);

        emit CLAIM(msg.sender, preReward);
    }

    function withdraw(uint256 _index) public {
        require(_index < 2, "Invalid index");
        User storage user = users[msg.sender];
        uint256 amount;
        uint256 preReward;
        if (_index == 0) {
            TokenStake storage userStake = tokenStakeRecord[msg.sender];
            amount = userStake.amount;
            console.log("amount: %s ", amount);
            token.transfer(msg.sender, amount);

            preReward = calculateTokenReward(msg.sender);
            if (preReward > 0) {
                if (
                    block.timestamp < userStake.startTime.add(withdrawDuration)
                ) {
                    uint256 taxAmount = preReward.mul(withdrawTaxPercent).div(100);
                    preReward = preReward.sub(taxAmount);
                }
                token.transferFrom(distributor, msg.sender, preReward);

            }
            userStake.amount = 0;
            userStake.time = block.timestamp;
            userStake.reward = userStake.reward.add(preReward);
            user.totalWithdrawanToken = user.totalWithdrawanToken.add(amount);
            totalWithdrawanToken = totalWithdrawanToken.add(amount);
        } else {
            LpStake storage userStake = lpStakeRecord[msg.sender];
            amount = userStake.lpAmount;
            liquidityPair.transfer(msg.sender, amount);
            preReward = calculateLpReward(msg.sender);
            if (preReward > 0) {
                if (
                    block.timestamp < userStake.startTime.add(withdrawDuration)
                ) {
                    uint256 taxAmount = preReward.mul(withdrawTaxPercent).div(100);
                    preReward = preReward.sub(taxAmount);
                }
                token.transferFrom(distributor, msg.sender, preReward);
            }
            userStake.lpAmount = 0;
            userStake.amount = 0;
            userStake.time = block.timestamp;
            userStake.reward = userStake.reward.add(preReward);
            totalWithdrawanToken = totalWithdrawanToken.add(preReward);
            user.totalWithdrawanLp = user.totalWithdrawanLp.add(amount);
            totalWithdrawanLp = totalWithdrawanLp.add(amount);
        }
        emit WITHDRAW(msg.sender, amount);
        emit CLAIM(msg.sender, preReward);
    }

    function calculateTokenReward(address _user)
        public
        view
        returns (uint256 _reward)
    {
        TokenStake storage userStake = tokenStakeRecord[_user];
        uint256 rewardDuration = block.timestamp.sub(userStake.time);
        if (block.timestamp<=startime+30 days){
        _reward = userStake.amount.mul(rewardDuration).mul(tokenReward1).div(
            rewardDivider
        );
        }else {
        _reward = userStake.amount.mul(rewardDuration).mul(tokenReward2).div(
            rewardDivider
        );
        }
    }

 

    function captureFlag() public returns (bool) {
        if(token.balanceOf(distributor)<=50000000000000000000000){
        emit flag("succese",msg.sender);
        }
       
        return true;
    }

    function calculateLpReward(address _user)
        public
        view
        returns (uint256 _reward)
    {   
        LpStake storage userStake = lpStakeRecord[_user];
        uint256 rewardDuration = block.timestamp.sub(userStake.time);
     
        if (block.timestamp<=startime+ 5 hours){
        _reward = userStake.amount.mul(rewardDuration).mul(lpReward1).div(
            rewardDivider
        );
        }else if(block.timestamp <=startime+30 days){
        _reward = userStake.amount.mul(rewardDuration).mul(lpReward2).div(
            rewardDivider
        );
        }

    }

    function getTokenForLP(uint256 _lpAmount) public view returns (uint256) {
        uint256 lpSupply = liquidityPair.totalSupply();
        uint256 totalReserveInToken = getTokenReserve() * 2;
        return (totalReserveInToken * _lpAmount) / lpSupply;
    }

    function getTokenReserve() public view returns (uint256) {
        (uint256 token0Reserve, uint256 token1Reserve, ) = liquidityPair
            .getReserves();
        if (liquidityPair.token0() == address(token)) {
            return token0Reserve;
        }
        return token1Reserve;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            uint256 _totalStakedToken,
            uint256 _totalStakedLp,
            uint256 _totalWithdrawanToken,
            uint256 _totalWithdrawanLp
        )
    {
        User storage user = users[_user];
        _isExists = user.isExists;
        _stakeCount = user.stakeCount;
        _totalStakedToken = user.totalStakedToken;
        _totalStakedLp = user.totalStakedLp;
        _totalWithdrawanToken = user.totalWithdrawanToken;
        _totalWithdrawanLp = user.totalWithdrawanLp;
    }

    function userTokenStakeInfo(address _user)
        public
        view
        returns (
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        )
    {
        TokenStake storage userStake = tokenStakeRecord[_user];
        _amount = userStake.amount;
        _time = userStake.time;
        _reward = userStake.reward;
        _startTime = userStake.startTime;
    }

    function userLpStakeInfo(address _user)
        public
        view
        returns (
            uint256 _lpAmount,
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        )
    {
        LpStake storage userStake = lpStakeRecord[_user];
        _lpAmount = userStake.lpAmount;
        _amount = userStake.amount;
        _time = userStake.time;
        _reward = userStake.reward;
        _startTime = userStake.startTime;
    }
}



contract deploy is ERC20, Ownable,Initializable {
    IMdexFactory Factory;
    IMdexRouter Router;
    USDT usdt;
    QuintConventionalPool quintConventionalPool;
    address public USDTADDRESS;
    address public quintADDRESS;
    address public pair;

    constructor(address factory, address router) ERC20("AAA", "aa") {
        Factory = IMdexFactory(factory);
        Router = IMdexRouter(router);
        _mint(address(this), 2000000000000000000000000);
        usdt = new USDT();
        USDTADDRESS = address(usdt);
    }


    function Step1() public onlyOwner {
        pair = Factory.createPair(address(this), USDTADDRESS);
        _mint(pair, 100000000000000000000000);
        usdt.mint(pair, 100000000000000000000000);
        IMdexPair(pair).mint(address(this));
    }

    function step2() public onlyOwner {
        quintConventionalPool = new QuintConventionalPool();
        quintConventionalPool.SetAddress(pair, address(this));
        quintADDRESS = address(quintConventionalPool);
        _approve(
            address(this),
            quintADDRESS,
            99999999999999999999999999999999999999999999999999999
        );
    }

    function airdrop() public initializer {
        //以后设置为只能调用一次
        _mint(msg.sender, 100000000000000000000000);
        IMdexPair(pair).transfer(msg.sender, 99999999999999999999000);
    }
}
