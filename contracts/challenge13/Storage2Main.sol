import "./ERC20.sol";
import "./Pair.sol";
import "./Storage2.sol";

pragma solidity ^0.8.0;
contract Storage2Main {
 

MyToken public tokena;   
MyToken public tokenb;
MdexPair public pair;
Storage2 public storage2;

 event SendFlag();
    constructor(){
        tokena = new MyToken();
        tokenb = new MyToken();
        pair = new MdexPair();

        storage2 = new Storage2();
        


        pair.initialize(address(tokena),address(tokenb));

        
        

        tokena.setpair(pair);
        tokenb.setpair(pair);

        tokena.recharge ();
        tokenb.recharge ();
        storage2.setToken(address(tokena));
    }

    function isComplete() public  {
        require(storage2.Complete() == msg.sender);
        emit SendFlag();
    }


}