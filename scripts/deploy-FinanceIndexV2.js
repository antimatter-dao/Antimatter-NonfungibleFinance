const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndexV2");
    const uri = 'https://antimatter.finance/';
    const matter = '0x9b99cca871be05119b2012fd4474731dd653febe';
    const platform = '0x87E12f9b95583D52ca72ED4553f38683757FB978';
    const fee = '50000000000000000'; // 0.05 ether
    const contract = await upgrades.deployProxy(Contract, [uri, matter, platform, fee], 'initialize');
    await contract.deployed();

    console.log("FinanceIndex deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
