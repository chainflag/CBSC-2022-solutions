import "./StorageSlot.sol";

pragma solidity ^0.8.0;
contract Storage1 {
    uint256 public constant VERSION = 1;
    address public aaaaa;
    address public admin;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Gas deposits ledger for user

    mapping(address => uint256) public gasDeposits;
    event SendFlag();
    event SetLogicContract(bytes32 key, address oldAddress, address newAddress);

    event DepositedGas(address account, uint256 amount);

    event WithdrewGas(address account, uint256 amount);

    error ZeroValue();

    error ZeroAmount();
    error NoAccess(bytes32 roleid, address account);

    /// @dev Initializer to be used after creation, instead of constructor

    constructor() {
        admin = address(0);
    }

    function setLogicContract(bytes32 key, address contractAddress) external {
        // Load the slot

        StorageSlot.AddressSlot storage slot = StorageSlot.getAddressSlot(key);

        // Emit the change event

        emit SetLogicContract(key, slot.value, contractAddress);

        // Assign the new value to the slot

        slot.value = contractAddress;
    }

    function isComplete() public  {
        require(admin == msg.sender);
        require(gasDeposits[msg.sender] >= 9999999999999999999999999999999999);
        emit SendFlag();
    }

    function depositGasFor(address account) external payable {
        depositGas(account, msg.value);
    }

    function depositGas(address account, uint256 amount) internal {
        if (amount == 0) revert ZeroValue();

        // The deposited ETH is added to the contract's balance

        // update gasFeeDeposit

        gasDeposits[account] = gasDeposits[account] + amount;

        // emit event

        emit DepositedGas(account, amount);
    }

    /// @dev Lets user withdraw eth from the gas deposits

    function withdrawGas(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        // If _amount is higher than deposit, withdraw all

        uint256 withdrawAmount = amount > gasDeposits[msg.sender]
            ? gasDeposits[msg.sender]
            : amount;

        // Quietly return if there is nothing to withdraw

        if (withdrawAmount == 0) return;

        // Adjust the balance

        gasDeposits[msg.sender] = gasDeposits[msg.sender] - withdrawAmount;

        // Send the ETH to msg.sender

        payable(msg.sender).transfer(withdrawAmount);

        // emit event

        emit WithdrewGas(msg.sender, withdrawAmount);
    }

    receive() external payable {
        depositGas(msg.sender, msg.value);
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);

        _;
    }
}
