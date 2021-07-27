const {ethers, upgrades} = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndexV2");
    const proxyAddress = '0x0A6318AB6B0C414679c0eB6a97035f4a3ef98606';
    const contract = await upgrades.upgradeProxy(proxyAddress, Contract);
    console.log("FinanceIndexV2 upgraded at: ", contract.address);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
