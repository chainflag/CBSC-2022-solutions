// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;
import "./contracts/ERC20.sol";
import "./contracts/IERC20.sol";
import "./contracts/ERC20Detailed.sol";


interface Changing {
    function isOwner(address) external returns (bool);
}

contract Ownable {
    address public _owner;
    address public _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    //Locks the contract for owner for the amount of time provided
    function lock() public onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() external payable {
        require(msg.value >= 1 ether);
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract OwnerBuy is Ownable, ERC20, ERC20Detailed {
    mapping(address => bool) public status;
    mapping(address => uint256) public Times;
    mapping(address => bool) internal whiteList;
    uint256 MAXHOLD = 100;
    event finished(bool);

    constructor() public ERC20Detailed("DEMO", "DEMO", 18) {}

    function isWhite(address addr) public view returns (bool) {
        return whiteList[addr];
    }

    function setWhite(address addr) external onlyOwner returns (bool) {
        whiteList[addr] = true;
        return true;
    }

    function unsetWhite(address addr) external onlyOwner returns (bool) {
        whiteList[addr] = false;
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        if (!isWhite(recipient)) {
            require(_balances[recipient] <= MAXHOLD, "hold overflow");
        }
        emit Transfer(sender, recipient, amount);
    }

    function changestatus(address _owner) public {
        Changing tmp = Changing(msg.sender);
        if (!tmp.isOwner(_owner)) {
            status[msg.sender] = tmp.isOwner(_owner);
        }
    }

    function changeOwner() public {
        require(tx.origin != msg.sender);
        require(uint(msg.sender) & 0xffff == 0xffff);
        if (status[msg.sender] == true) {
            status[msg.sender] = false;
            _owner = msg.sender;
        }
    }

    function buy() public payable returns (bool success) {
        require(_owner == 0x220866B1A2219f40e72f5c628B65D54268cA3A9D);
        require(tx.origin != msg.sender);
        require(Times[msg.sender] == 0);
        require(_balances[msg.sender] == 0);
        require(msg.value == 1 wei);
        _balances[msg.sender] = 100;
        Times[msg.sender] = 1;
        return true;
    }

    function sell(uint256 _amount) public returns (bool success) {
        require(_amount >= 200);
        require(uint(msg.sender) & 0xffff == 0xffff);
        require(Times[msg.sender] > 0);
        require(_balances[msg.sender] >= _amount);
        require(address(this).balance >= _amount);
        msg.sender.call.gas(1000000)("");
        _transfer(msg.sender, address(this), _amount);
        Times[msg.sender] -= 1;
        return true;
    }

    function finish() public onlyOwner returns (bool) {
        require(Times[msg.sender] >= 100);
        Times[msg.sender] = 0;
        msg.sender.transfer(address(this).balance);
        emit finished(true);
        return true;
    }
}
