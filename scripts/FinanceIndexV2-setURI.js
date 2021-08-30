const { ethers, upgrades } = require("hardhat");

async function main() {
    const proxyAddress = '0x53E416C1Bd19bAA9EE334061d900f58A12BB64e4';
    const contract = await ethers.getContractAt("FinanceIndexV2", proxyAddress);
    const uri = "https://nftapi.antimatter.finance/app/getMetadata";
    const tx = await contract.setURI(uri);
    console.log(tx);

    const tokenUri = await contract.uri(0);
    console.log(tokenUri)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
