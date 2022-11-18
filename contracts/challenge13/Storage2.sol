import "./StorageSlot.sol";
import "./ERC20.sol";
pragma solidity ^0.8.0;


contract Storage2 {
    IERC20 public token;
    address public aaaaa;
    uint256 public constant VERSION = 1;

    address public admin;

    // Gas deposits ledger for user

    mapping(address => uint256) public gasDeposits;

    event SetLogicContract(bytes32 key, address oldAddress, address newAddress);

    event DepositedGas(address account, uint256 amount);

    event WithdrewGas(address account, uint256 amount);
    event SendFlag();
    error ZeroValue();

    error ZeroAmount();
    error NoAccess(bytes32 roleid, address account);
    error UnknownError();

    /// @dev Initializer to be used after creation, instead of constructor

    constructor() {
        admin = msg.sender;

    }

    function setToken(address a) public {
        require(admin == msg.sender);
        IERC20 _token = IERC20(a);
        token = _token;
    }

    function Complete() public returns (address)  {
        return admin;
    }

    function depositGas(address account, uint256 amount) public {
        if (amount == 0) revert ZeroValue();

        // The deposited ETH is added to the contract's balance

        // update gasFeeDeposit

        gasDeposits[account] = gasDeposits[account] + amount;

        token.transferFrom(msg.sender, address(this), amount);

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

        token.transfer(msg.sender, withdrawAmount);

        // emit event

        emit WithdrewGas(msg.sender, withdrawAmount);
    }

    function _delegateCall(
        bytes memory delegateCallData,
        address delegateContract
    ) internal returns (bool success, bytes memory returndata) {
        (success, returndata) = delegateContract.delegatecall(delegateCallData);

        if (success) {
            return (success, returndata);
        } else {
            // Look for revert reason and bubble it up if present

            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)

                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert UnknownError();
            }
        }
    }

    function excute(bytes32 condition) external returns (bytes memory _output) {

        address conditionContract = StorageSlot.getAddressSlot(condition).value;

        bytes memory delegateCall = abi.encodeWithSignature(
            "evaluate(uint256,bytes,bytes,address)",
            uint256(0),
            "",
            "",
            address(0)
        );

        (bool success, bytes memory returndata) = _delegateCall(
            delegateCall,
            conditionContract
        );
    }
}
