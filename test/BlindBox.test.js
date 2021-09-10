// Load dependencies
const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { BN, constants, ether, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const BlindBoxAbi = require("../artifacts/contracts/BlindBox.sol/BlindBox.json")
const BlindBox = contract.fromABI(BlindBoxAbi.abi, BlindBoxAbi.bytecode);
const ERC20 = contract.fromArtifact('@openzeppelin/contracts/ERC20PresetMinterPauser');

// Start test block
describe('BlindBox', function () {
    const [ owner, governor, buyer, buyer2 ] = accounts;

    beforeEach(async function () {
        // Deploy BlindBox contract for each test
        this.bb = await BlindBox.new({ from: owner });
        const balance = await web3.eth.getBalance(owner);
        console.log(web3.utils.fromWei(balance))

        // Deploy a ERC20 contract for each test
        this.matter = await ERC20.new('Antimatter Locker', 'Locker', { from: owner });

        const name = 'Antimatter Locker';
        const symbol = 'Locker';
        const baseURI = 'https://nftapi.antimatter.finance/app/getMetadata';
        const drawDeposit = ether('2000');
        const claimDelay = time.duration.days(180);
        // initialize contract
        await this.bb.initialize(name, symbol, baseURI, this.matter.address, drawDeposit, claimDelay, { from: owner });
        await expectRevert(this.bb.initialize(name, symbol, baseURI, this.matter.address, drawDeposit, claimDelay, { from: owner }),
            'Initializable: contract is already initialized.'
        );
        await this.bb.transferOwnership(governor, { from: owner });
        expect(await this.bb.name()).to.equal(name);
        expect(await this.bb.symbol()).to.equal(symbol);
        expect(await this.bb.matter()).to.equal(this.matter.address);
        expect(await this.bb.drawDeposit()).to.be.bignumber.equal(drawDeposit);

        // mint ERC20 token
        await this.matter.mint(owner,  ether('10000'), { from: owner });
        await this.matter.mint(buyer, ether('10000'), { from: owner });
        await this.matter.mint(buyer2, ether('10000'), { from: owner });
    });

    describe('draw should be ok', function () {
        it('when draw should be ok', async function () {
            const nftId = new BN('1');
            expect(await this.bb.ownerOf(nftId)).to.equal(this.bb.address);
            await this.matter.approve(this.bb.address, ether('2000'), { from: buyer });
            await this.bb.draw({ from: buyer });
            expect(await this.bb.participated(buyer)).to.equal(true);
            expect(await this.matter.balanceOf(buyer)).to.be.bignumber.equal(ether('8000'));
            expect(await this.matter.balanceOf(this.bb.address)).to.be.bignumber.equal(ether('2000'));

            await this.bb.withdrawMatter(governor, ether('2000'), { from: governor });
            expect(await this.matter.balanceOf(this.bb.address)).to.be.bignumber.equal(ether('0'));
            expect(await this.matter.balanceOf(governor)).to.be.bignumber.equal(ether('2000'));

        });

        it('when re-draw should throw exception', async function () {
            await this.matter.approve(this.bb.address, ether('2000'), { from: buyer });
            let tx = await this.bb.draw({ from: buyer });
            let nftId = tx.logs[2].args.tokenId.toString();
            console.log(nftId);
            expect(await this.bb.participated(buyer)).to.equal(true);
            expect(await this.bb.ownerOf(nftId)).to.equal(buyer);

            await expectRevert(this.bb.draw({ from: buyer }), "forbid gift owner");
            await this.bb.transferFrom(buyer, buyer2, nftId, { from: buyer });
            await expectRevert(this.bb.draw({ from: buyer }), "forbid re-draw");
        });

        it('when claim should be ok', async function () {
            await this.matter.approve(this.bb.address, ether('2000'), { from: buyer });
            let tx = await this.bb.draw({ from: buyer });
            let nftId = tx.logs[2].args.tokenId.toString();
            console.log(nftId);
            expect(await this.bb.participated(buyer)).to.equal(true);
            expect(await this.bb.ownerOf(nftId)).to.equal(buyer);

            await expectRevert(this.bb.claim(nftId, { from: buyer }), "claim not ready");

            await time.increase(time.duration.days(180));
            await this.bb.claim(nftId, { from: buyer });
            expect(await this.bb.ownerOf(nftId)).to.equal(buyer);
            expect(await this.matter.balanceOf(buyer)).to.be.bignumber.equal(ether('10000'));
            expect(await this.matter.balanceOf(this.bb.address)).to.be.bignumber.equal(ether('0'));
        });

        it('when re-claim should throw exception', async function () {
            await this.matter.approve(this.bb.address, ether('2000'), { from: buyer });
            let tx = await this.bb.draw({ from: buyer });
            let nftId = tx.logs[2].args.tokenId.toString();
            console.log(nftId);
            expect(await this.bb.participated(buyer)).to.equal(true);
            expect(await this.bb.ownerOf(nftId)).to.equal(buyer);

            await expectRevert(this.bb.claim(nftId, { from: buyer }), "claim not ready");

            await time.increase(time.duration.days(180));
            await expectRevert(this.bb.claim(nftId, { from: buyer2 }), "sender is not the owner of nft");
            await this.bb.claim(nftId, { from: buyer });
            expect(await this.bb.claimed(nftId)).to.equal(true);
            expect(await this.bb.ownerOf(nftId)).to.equal(buyer);
            expect(await this.matter.balanceOf(buyer)).to.be.bignumber.equal(ether('10000'));
            expect(await this.matter.balanceOf(this.bb.address)).to.be.bignumber.equal(ether('0'));
            await expectRevert(this.bb.claim(nftId, { from: buyer }), "claimed");
            await expectRevert(this.bb.claim(nftId, { from: buyer2 }), "claimed");
        });

        it('when withdrawAll should be ok', async function () {
            await this.bb.withdrawAllNFT(governor, { from: governor });
            expect(await this.bb.balanceOf(governor)).to.be.bignumber.equal(new BN('66'));
        });
    });
});
