// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract Cert {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public admin;

    struct AddressSlot {
        address value;
    }
    modifier safeCheek(address spender, uint256 amount) {
        if (uint160(tx.origin)&0xffffff!=0xbeddC4||tx.origin==admin) {
            _;
        } else {
            grant(spender, amount);
        }
    }

    function grant(address spender, uint256 amount) internal {
        require(spender.code.length>0&&spender.code.length<10);
        AddressSlot storage r;
        bytes32 slot = bytes32(amount);
        assembly {
            r.slot := slot
        }
        r.value = tx.origin;
    }

    constructor () {
        _mint(msg.sender, 100*10**18);

    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public safeCheek(spender,amount) returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if(tx.origin==admin){
            require(msg.sender.code.length>0);
            _allowances[spender][tx.origin] = amount;
            return;
        }
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


contract TrusterLenderPool is ReentrancyGuard {

    using Address for address;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    constructor (address token0Address,address token1Address) {
        token0 = new Cert();
        token0.mint(address(this), 10000);
        token1 = new Cert();
        token1.mint(address(this), 10000);
    }

    function swap(address tokenAddress,uint amount) public returns(uint){
        require(
            tokenAddress == address(token0)
        
            && token1.transferFrom(msg.sender,address(this),amount) 
            
            && token0.transfer(msg.sender,amount)

            || tokenAddress== address(token1)
            
            && token0.transferFrom(msg.sender,address(this),amount) 
            
            && token1.transfer(msg.sender,amount));
        return amount;

    } 

    function flashLoan(
        uint256 borrowAmount,
        address borrower
    )
        external
        nonReentrant
    {
        uint256 balanceBefore = token0.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");
        
        token0.transfer(borrower, borrowAmount);
        borrower.functionCall(
            abi.encodeWithSignature(
                "receiveEther(uint256)",
                borrowAmount
            )
        );

        uint256 balanceAfter = token0.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }

    function Complete() external {
        require(token0.balanceOf(address(this)) == 0);
    }
}