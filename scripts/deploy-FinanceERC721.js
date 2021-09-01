const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceERC721");
    const contract = await upgrades.deployProxy(Contract, [
        "Antimatter Locker", "Locker", "https://nftapi.antimatter.finance/app/getMetadata"
    ], 'initialize');
    await contract.deployed();

    console.log("FinanceERC721 deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
