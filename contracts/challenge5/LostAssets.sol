pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockWETH is ERC20("Wrapped ETH", "WETH") {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    /// @dev Original WETH9 implements `fallback` function instead of `receive` function due to a earlier solidity version
    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "weth: insufficient balance");

        _burn(msg.sender, wad);
        (bool success, ) = msg.sender.call{value: wad}("");
        require(success, "weth: failed");

        emit Withdrawal(msg.sender, wad);
    }
}

/// @notice Token sWETH
contract MocksWETH is ERC20Permit {
    using SafeERC20 for IERC20;

    address underlying;

    constructor(address _underlying)
        ERC20("WrappedERC20", "WERC20")
        ERC20Permit("WrappedERC20")
    {
        underlying = _underlying;
    }

    function deposit() external returns (uint256) {
        uint256 _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint256 amount) external returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function depositWithPermit(
        address target,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to
    ) external returns (uint256) {
        // permit is an alternative to the standard approve call:
        // it allows an off-chain secure signature to be used to register an allowance.
        // The permitter is approving the beneficiary to spend their money, by signing the permit request
        IERC20Permit(underlying).permit(
            target,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        IERC20(underlying).safeTransferFrom(target, address(this), value);
        return _deposit(value, to);
    }

    function _deposit(uint256 value, address to) internal returns (uint256) {
        _mint(to, value);
        return value;
    }

    /// @notice withdraw all
    function withdraw() external returns (uint256) {
        return _withdraw(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    /// @notice withdraw specified `amount`
    function withdraw(uint256 amount) external returns (uint256) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function _withdraw(
        address from,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }
}

contract LostAssets {
    MockWETH public WETH;
    MocksWETH public sWETH;

    constructor() payable {
        require(msg.value >= 1 ether, "At least 1 ether");

        WETH = new MockWETH();
        sWETH = new MocksWETH(address(WETH));

        WETH.deposit{value: msg.value}();
        // Guaranteed interchangeability of WETH and sWETH
        WETH.approve(address(sWETH), type(uint256).max);
        // sWETH.approve(address(WETH), type(uint256).max); // WETH cannot use approval
        // Deposit half of weth balance
        sWETH.deposit(msg.value / 2);
    }

    function isComplete() public view returns (bool) {
        require(WETH.balanceOf(address(this)) == 0);
        return true;
    }
}
