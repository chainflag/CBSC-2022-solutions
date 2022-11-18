const { ethers } = require("hardhat");
const { address } = require("hardhat/internal/core/config/config-validation");

async function deploy(deployer) {
  const DEX = await ethers.getContractFactory("DEX", deployer);
  const dex = await DEX.deploy("dex");
  console.log("dex contract:", dex.address);

  return dex;
}

async function exploit(attacker, target) {
  await target.connect(attacker).init();
  console.log("oldReserves:", await target.oldReserves());
  // const DEX = await ethers.getContractFactory("DEX");
  const pairaddress = await target.pair();
  const TTPair = await ethers.getContractFactory("TTPair");
  const pair = await TTPair.attach(pairaddress);
  const TTRouter02 = await ethers.getContractFactory("TTRouter02");
  const ttrouter = TTRouter02.attach(await target.RouterADDRESS());
  const ERC20 = await ethers.getContractFactory(
    "contracts/challenge12/config.sol:ERC20"
  );
  const token0 = await ERC20.attach(await pair.token0());
  // console.log( await token0.balanceOf(pair.address))
  const token1 = await ERC20.attach(await pair.token1());
  // console.log( await token1.balanceOf(pair.address))
  // await target.connect(attacker).transfer(pair.address,500000)
  // await pair.connect(attacker).skim()
  // await pair.connect(attacker).swap(10,0,attacker.address,"0x")
  console.log(await pair.reserve0());
  console.log(await pair.reserve1());

  // await pair.connect(attacker).mint(attacker.address)
  // await pair.connect(attacker).burn(attacker.address)
  // await target.connect(attacker).Setflag();
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let dex = await deploy(deployer);
  console.log(attacker.address);
  await exploit(attacker, dex);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
