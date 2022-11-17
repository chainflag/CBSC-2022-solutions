import "./ERC20.sol";
import "./Pair.sol";
import "./Storage3.sol";

pragma solidity ^0.8.0;
contract Storage3Main {
 

MyToken public tokena;   
MyToken public tokenb;
MdexPair public pair;
Storage3 public storage3;

 event SendFlag();
    constructor(){
        tokena = new MyToken();
        tokenb = new MyToken();
        pair = new MdexPair();

        storage3 = new Storage3();
        


        pair.initialize(address(tokena),address(tokenb));

        
        
        
        tokena.setpair(pair);
        tokenb.setpair(pair);

        tokena.recharge ();
        tokenb.recharge ();
        storage3.setToken(address(tokena));
    }

    function isComplete() public  {
        require(storage3.Complete() == msg.sender);
        emit SendFlag();
    }


}