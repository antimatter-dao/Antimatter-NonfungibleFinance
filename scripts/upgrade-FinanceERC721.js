const {ethers, upgrades} = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceERC721");
    const proxyAddress = '';
    const contract = await upgrades.upgradeProxy(proxyAddress, Contract);
    console.log("FinanceERC721 upgraded at: ", contract.address);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
