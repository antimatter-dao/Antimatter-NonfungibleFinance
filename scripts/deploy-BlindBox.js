const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("BlindBox");
    const name = "Antimatter Locker";
    const symbol = "Locker";
    const baseURI = "https://nftapi.antimatter.finance/app/getMetadata";
    const matter = '0x9b99cca871be05119b2012fd4474731dd653febe';
    const drawFee = ethers.utils.parseEther('2000');
    const contract = await upgrades.deployProxy(Contract, [
        name, symbol, baseURI, matter, drawFee,
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
