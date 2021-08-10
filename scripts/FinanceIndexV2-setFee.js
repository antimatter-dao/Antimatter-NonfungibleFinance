const { ethers, upgrades } = require("hardhat");

async function main() {
    const proxyAddress = '0xD12D12AaCad77D54421A2c2AD723e259Bf390488';
    const contract = await ethers.getContractAt("FinanceIndexV2", proxyAddress);
    const fee = ethers.utils.parseEther('0.005');
    const tx = await contract.setFee(fee);
    console.log(tx);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
