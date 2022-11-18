// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Pair.sol";

contract MyToken is ERC20 {
    constructor() ERC20() {
      owner = msg.sender;
    }
    MdexPair public pair;

    address owner;

    modifier onlyOwner(){
        require(msg.sender== owner,"not owner");
        _;
    }
    mapping (address => bool) public already;
   
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function setpair(MdexPair a) public onlyOwner {
        pair = a;
    }

    function recharge () public {
        _mint(address(pair), 1000000000000000000000000000000000000000000000000);
        pair.sync();
    }

    function air() public {
        require(already[msg.sender]== false);
        _mint(msg.sender, 100);
        already[msg.sender]= true;
    }

}