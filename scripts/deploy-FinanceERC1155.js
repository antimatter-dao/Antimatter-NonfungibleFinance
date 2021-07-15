const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceERC1155");
    const uri = '';
    const contract = await upgrades.deployProxy(Contract, [uri], 'initialize');
    await contract.deployed();

    console.log("FinanceERC1155 deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
