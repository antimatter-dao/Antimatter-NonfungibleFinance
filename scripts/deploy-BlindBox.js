const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("BlindBox");
    const name = "Antimatter Locker";
    const symbol = "Locker";
    const baseURI = "https://nftapi.antimatter.finance/app/getBlindBoxMetadata/";
    const matter = '0x9b99cca871be05119b2012fd4474731dd653febe';
    const drawDeposit = ethers.utils.parseEther('1000');
    const claimDelay = 4*30*86400;
    const contract = await upgrades.deployProxy(Contract, [
        name, symbol, baseURI, matter, drawDeposit, claimDelay
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
