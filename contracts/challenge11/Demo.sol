pragma solidity 0.4.24;
import "./FakeWETH.sol";

interface FakeERC20 {
    function transfer(address recipient, uint256 amount) public returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool);

    function approve(address recipient, uint256 amount) public returns (bool);

    function balanceOf(address owner) public view returns (uint256);
}

contract Bank {
    address public owner;
    address public pendingOwner;

    struct AccountBook {
        string accountName;
        uint256 uniqueTokens;
        mapping(address => uint256) balances;
    }

    mapping(address => AccountBook[]) public accounts;

    constructor() public {
        owner = msg.sender;
    }

    function depositToken(
        uint256 accountId,
        address token,
        uint256 amount
    ) external {
        require(
            accountId <= accounts[msg.sender].length,
            "bad account"
        );

        if (accountId == accounts[msg.sender].length) {
            accounts[msg.sender].length++;
        }

        AccountBook storage account = accounts[msg.sender][accountId];
        uint256 oldBalance = account.balances[token];

        require(oldBalance + amount >= oldBalance, "overflow");

        require(
            FakeERC20(token).balanceOf(msg.sender) >= amount,
            "Not enough balance"
        );

        if (oldBalance == 0) {
            account.uniqueTokens++;
        }

        account.balances[token] += amount;

        uint256 beforeBalance = FakeERC20(token).balanceOf(address(this));
        require(
            FakeERC20(token).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );

        uint256 afterBalance = FakeERC20(token).balanceOf(address(this));

        require(
            afterBalance - beforeBalance == amount,
            "error"
        );
    }

    function withdrawToken(
        uint256 accountId,
        address token,
        uint256 amount
    ) external {
        require(
            accountId < accounts[msg.sender].length,
            "bad accounts"
        );

        AccountBook storage account = accounts[msg.sender][accountId];
        uint256 lastAccount = accounts[msg.sender].length - 1;
        uint256 oldBalance = account.balances[token];

        require(oldBalance >= amount, "underflow");
        require(
            FakeERC20(token).balanceOf(address(this)) >= amount,
            "Not enough balance"
        );

        account.balances[token] -= amount;

        if (account.balances[token] == 0) {
            account.uniqueTokens--;

            if (account.uniqueTokens == 0 && accountId == lastAccount) {
                accounts[msg.sender].length--;
            }
        }

        uint256 beforeBalance = FakeERC20(token).balanceOf(msg.sender);
        require(
            FakeERC20(token).transfer(msg.sender, amount),
            "transfer failed"
        );
        uint256 afterBalance = FakeERC20(token).balanceOf(msg.sender);
        require(
            afterBalance - beforeBalance == amount,
            "error"
        );
    }

    function setAccountName(uint256 accountId, string name) external {
        require(
            accountId < accounts[msg.sender].length,
            "bad accounts"
        );

        accounts[msg.sender][accountId].accountName = name;
    }

    function closeLastAccount() external {
        require(
            accounts[msg.sender].length > 0,
            "bad accounts"
        );

        uint256 lastAccount = accounts[msg.sender].length - 1;
        require(
            accounts[msg.sender][lastAccount].uniqueTokens == 0,
            "non-empty"
        );

        accounts[msg.sender].length--;
    }

    function getAccountInfo(uint256 accountId)
        public
        view
        returns (string, uint256)
    {
        require(
            accountId < accounts[msg.sender].length,
            "bad accounts"
        );

        return (
            accounts[msg.sender][accountId].accountName,
            accounts[msg.sender][accountId].uniqueTokens
        );
    }

    function getAccountBalance(uint256 accountId, address token)
        public
        view
        returns (uint256)
    {
        require(
            accountId < accounts[msg.sender].length,
            "bad accounts"
        );

        return accounts[msg.sender][accountId].balances[token];
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);

        pendingOwner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == pendingOwner);

        owner = pendingOwner;
        pendingOwner = address(0x00);
    }
}

//interface FakeWETH is FakeERC20 {
//    function deposit() public payable;
//}

contract Demo {

    // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 -> WETH
    // Add deployed FakeWETH contract address here
    // 0x5FbDB2315678afecb367f032d93F642f64180aa3 -> WETH
    // Use Hardhat
    fakeWETH public constant weth = fakeWETH(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    Bank public bank;

    constructor() public payable {
        require(msg.value == 5 ether);

        bank = new Bank();
        weth.deposit.value(msg.value)();
        weth.approve(address(bank), uint256(-1));
        bank.depositToken(0, address(weth), weth.balanceOf(address(this)));
    }

    function isCompleted() external view returns (bool) {
        return weth.balanceOf(address(bank)) == 0;
    }
}