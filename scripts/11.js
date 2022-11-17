const { ethers } = require("hardhat");

async function deploy(deployer) {
  const FakeWETH = await ethers.getContractFactory("fakeWETH", deployer);
  const fakeWETH = await FakeWETH.deploy();
  console.log("fakeWETH contract:", fakeWETH.address);
  const Demo = await ethers.getContractFactory("Demo", deployer);
  const fiveEther = ethers.utils.parseEther("5");
  const demo = await Demo.deploy({ value: fiveEther });
  console.log("Demo contract:", demo.address);

  return demo;
}

async function exploit(attacker, target) {
  console.log("Before: Complete():", await target.isCompleted());
  const FakeWETHSolution = await ethers.getContractFactory(
    "FakeWETHSolution",
    attacker
  );
  const solution = await FakeWETHSolution.deploy(target.address);
  console.log("Solution contract:", solution.address);
  console.log("After: Complete():", await target.isCompleted());
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let demo = await deploy(deployer);

  await exploit(attacker, demo);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
