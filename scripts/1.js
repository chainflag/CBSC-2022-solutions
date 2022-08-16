const { ethers } = require("hardhat");

async function deploy(deployer) {
  const TrusterLenderPool = await ethers.getContractFactory(
    "TrusterLenderPool",
    deployer
  );
  const trusterLenderPool = await TrusterLenderPool.deploy();
  console.log("TrusterLenderPool contract:", trusterLenderPool.address);

  return trusterLenderPool;
}

async function exploit(attacker, target) {
  const TrusterLenderPoolSolution = await ethers.getContractFactory(
    "TrusterLenderPoolSolution",
    attacker
  );
  const solution = await TrusterLenderPoolSolution.deploy(target.address);
  console.log("Solution contract:", solution.address);

  try {
    await target.connect(attacker).Complete();
  } catch (error) {
    console.log("Before: isComplete():", error.toString());
  }

  await solution.connect(attacker).exploit();
  console.log(
    "After: isComplete():",
    await target.connect(attacker).Complete()
  );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let TrusterLenderPool = await deploy(deployer);

  await exploit(attacker, TrusterLenderPool);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
