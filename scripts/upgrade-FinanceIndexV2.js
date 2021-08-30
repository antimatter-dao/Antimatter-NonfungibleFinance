const {ethers, upgrades} = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndexV2");
    const proxyAddress = '0x53E416C1Bd19bAA9EE334061d900f58A12BB64e4';
    const contract = await upgrades.upgradeProxy(proxyAddress, Contract);
    console.log("FinanceIndexV2 upgraded at: ", contract.address);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
