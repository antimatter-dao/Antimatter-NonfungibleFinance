const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("BlindBox");
    const matter = '0x9b99cca871be05119b2012fd4474731dd653febe';
    const nftGift = '';
    const drawFee = ethers.utils.parseEther('2000');
    const contract = await upgrades.deployProxy(Contract, [
        matter, nftGift, drawFee,
    ], 'initialize');
    await contract.deployed();

    console.log("BlindBox deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
