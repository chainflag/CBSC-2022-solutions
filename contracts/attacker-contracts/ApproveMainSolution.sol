pragma solidity ^0.8.0;

contract ApproveMainSolution {
    address public deploy;

    constructor() public {
        bytes memory bytecode = hex"60016000526001601fF3";

        address addr;
        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                0x00
            )
        }
        deploy = addr;
    }

    function test(address spender) public view returns (uint256) {
        return spender.code.length;
    }
}
