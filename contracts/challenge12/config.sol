pragma solidity =0.7.6;
import "./interface.sol";
import "./router.sol";
import "./Factory.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 is Ownable, IERC20 {
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface ICallee {
    function ICall(address sender, uint amount) external;
}
interface Ifactory{
    function createPair(address tokenA, address tokenB) external  returns (address pair);
    function Set(address _router,address token) external;
}
interface Ipair{
    function mint(address to) external returns (uint256 liquidity); 
    function getReserves() external view returns (uint256, uint256);
    function sync() external;

}
interface IIERC20{
    function mint(address account, uint256 amount) external;
}

contract Token is ERC20{
    constructor() ERC20("USDT", "USDT") {
    }
    function mint(address account,uint256 amount) public {
        require(msg.sender == _owner,"Not owner");
        _mint(account, 500000);
    }
}

contract DEX is ERC20,ReentrancyGuard{
    address public pair;
    address public USDTADDRESS;
    address public FactoryADDRESS;
    address public RouterADDRESS;
    uint256 public oldReserves;
    bool public flag;
    bool public state;
    event sendflag(address indexed from);
    string greeting;

    TTFactory Factory = new TTFactory();
    TTRouter02 Router = new TTRouter02(address(Factory));
    Token USDT = new Token();
    constructor(string memory _greeting) ERC20("TTtoken", "TTtoken") {
        Factory.Set(address(Router),address(this));
        _mint(address(this),100000000);
        USDTADDRESS = address(USDT);
        FactoryADDRESS = address(Factory);
        RouterADDRESS = address(Router);
        greeting = _greeting;
    }

    function init() public {
        require(state == false);
        pair = Factory.createPair(address(this),USDTADDRESS);
        _mint(pair, 500000);
        _mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8,100000000);
        IIERC20(USDTADDRESS).mint(pair,500000);
        Ipair(pair).sync();
        (uint256 tokena, uint256 tokenb) = Ipair(pair).getReserves();
        oldReserves = tokena + tokenb;
        state = true; 
    }
    function flash(uint amount,address to) public nonReentrant {
        require(amount <= balanceOf(address(this)));
        require(state == true);
        uint256 feeamount = amount * 50 / 100;
        uint256 totolamount = balanceOf(address(this));
        this.transfer(pair,feeamount);
        this.transfer(to,amount-feeamount);
        ICallee(to).ICall(msg.sender, amount);
        require(balanceOf(address(this)) >= totolamount);  
    }
    function Setflag() public{
        require(state == true);
        (uint256 tokena, uint256 tokenb) = Ipair(pair).getReserves();
        uint256 newReserves = tokena + tokenb;
        require(newReserves <= oldReserves *6/10);
        flag = true;
        emit sendflag(tx.origin);
    }
}