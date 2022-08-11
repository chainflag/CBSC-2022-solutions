// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./interface.sol";
import "./Masterchef.sol";

contract Governance {
    bool public Flag;
    address public  ValidatorOwner;
    mapping (address => uint256) public validatorVotes;
    mapping (address => bool) public VotingStatus;
    event Sendflag(bool Flag);
    MasterChef public masterChef = new MasterChef();
    string greeting;
    constructor (string memory _greeting) public {
        greeting = _greeting;
    }
    modifier onlyValidatorOwner() {
        require(msg.sender == ValidatorOwner, "Governance: only validator owner");
        _;
    }
    function vote(address validator) public {
        require(masterChef.owner() == msg.sender);
        require(!VotingStatus[msg.sender]);
        VotingStatus[msg.sender] = true;
        uint balances = masterChef.balanceOf(msg.sender);
        validatorVotes[validator] += balances;
    }
    function setValidator() public {
        uint256 votingSupply = masterChef.totalSupply() * 2 / 3;
        require(validatorVotes[msg.sender] >= votingSupply);
        ValidatorOwner = msg.sender;
    }

    function setflag() public onlyValidatorOwner {
        Flag = true;
        emit Sendflag(Flag);
    }
}