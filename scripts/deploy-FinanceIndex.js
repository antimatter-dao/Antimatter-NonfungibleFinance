const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndex");
    const uri = '';
    const platform = '';
    const fee = ''; // 0.05 ether
    const contract = await upgrades.deployProxy(Contract, [uri, platform, fee], 'initialize');
    await contract.deployed();

    console.log("FinanceIndex deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
