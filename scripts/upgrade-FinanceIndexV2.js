const {ethers, upgrades} = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndexV2");
    const proxyAddress = '';
    const contract = await upgrades.upgradeProxy(proxyAddress, Contract);
    console.log("FinanceIndexV2 upgraded at: ", contract.address);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
