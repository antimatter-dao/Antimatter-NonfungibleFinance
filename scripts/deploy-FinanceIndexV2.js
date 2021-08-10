const { ethers, upgrades } = require("hardhat");

async function main() {
    const Contract = await ethers.getContractFactory("FinanceIndexV2");
    const uri = 'https://antimatter.finance/';
    const matter = '0x9b99cca871be05119b2012fd4474731dd653febe';
    const platform = '0x1FA4C91Fc877110bD0E93Ce1CC52a5d9801bc29d';
    const fee = ethers.utils.parseEther('0.005');
    const contract = await upgrades.deployProxy(Contract, [uri, matter, platform, fee], 'initialize');
    await contract.deployed();

    console.log("FinanceIndexV2 deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
