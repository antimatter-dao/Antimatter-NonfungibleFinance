const { ethers, upgrades } = require("hardhat");

async function main() {
    const proxyAddress = '0x1ED84e14c0717314B805B1369c241d3598BA57Cb';
    const contract = await ethers.getContractAt("FinanceERC721", proxyAddress);
    // const uri = "https://nftapi.antimatter.finance/app/getMetadata";
    // const tx = await contract.setBaseURI(uri);
    // console.log(tx);

    const tokenUri = await contract.tokenURI(0);
    console.log(tokenUri)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
