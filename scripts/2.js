const { expect } = require("chai");
const { ethers } = require("hardhat");

async function deploy(deployer) {
  const SVip = await ethers.getContractFactory("SVip", deployer);
  const svip = await SVip.deploy();
  console.log("SVip contract:", svip.address);

  await expect(await svip.numOfFree()).to.equal(0);
  return svip;
}

async function exploit(attacker, target) {
  const SVipSolution = await ethers.getContractFactory(
    "SVipSolution",
    attacker
  );
  const solution = await SVipSolution.deploy(target);
  console.log("Solution contract:", solution.address);

  try {
    await solution.connect(attacker).isComplete();
  } catch (error) {
    console.log("Before: isComplete():", error.toString());
  }

  await solution.connect(attacker).exploit();
  console.log(
    "After: isComplete():",
    await solution.connect(attacker).isComplete()
  );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let svip = await deploy(deployer);

  await exploit(attacker, svip.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
