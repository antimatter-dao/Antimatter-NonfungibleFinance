// Load dependencies
const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { BN, constants, ether, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const FinanceERC721Abi = require("../artifacts/contracts/FinanceERC721.sol/FinanceERC721.json")
const FinanceERC721 = contract.fromABI(FinanceERC721Abi.abi, FinanceERC721Abi.bytecode);
const ERC20 = contract.fromArtifact('@openzeppelin/contracts/ERC20PresetMinterPauser');

function usd (n) {
    return ether(n).div(new BN('10').pow(new BN('12')));
}

// Start test block
describe('FinanceERC721', function () {
    const [ owner, governor, creator, buyer, buyer2 ] = accounts;

    beforeEach(async function () {
        // Deploy FinanceERC721 contract for each test
        this.f = await FinanceERC721.new({ from: owner });
        const balance = await web3.eth.getBalance(owner);
        console.log(web3.utils.fromWei(balance))

        // Deploy a ERC20 contract for each test
        this.erc20Token = await ERC20.new('Test Token', 'TST', { from: owner });
        this.erc20Token2 = await ERC20.new('Test Token', 'TST', { from: owner });

        // initialize contract
        await this.f.initialize("NFT Token", "NT", { from: owner });
        await expectRevert(this.f.initialize("NFT Token", "NT", { from: owner }), 'Initializable: contract is already initialized.');
        await this.f.transferOwnership(governor, { from: owner });

        // mint ERC20 token
        await this.erc20Token.mint(owner,  ether('10000'), { from: owner });
        await this.erc20Token.mint(this.f.address, ether('10000'), { from: owner });
        await this.erc20Token.mint(creator, ether('10000'), { from: owner });
        await this.erc20Token.mint(buyer, ether('10000'), { from: owner });
        await this.erc20Token.mint(buyer2, ether('10000'), { from: owner });

        await this.erc20Token2.mint(owner,  ether('10000'), { from: owner });
        await this.erc20Token2.mint(this.f.address, ether('10000'), { from: owner });
        await this.erc20Token2.mint(creator, ether('10000'), { from: owner });
        await this.erc20Token2.mint(buyer, ether('10000'), { from: owner });
        await this.erc20Token2.mint(buyer2, ether('10000'), { from: owner });
    });

    describe('create should be ok', function () {
        beforeEach(async function () {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address, this.erc20Token2.address];
            const underlyingAmounts = [ether('20'), ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const token2 = this.erc20Token2.address;
            const amount = ether('20');
            const claimAt = new BN('0');
            const claims = [
                [token1, ether('5'), claimAt],
                [token1, ether('8'), claimAt],
                [token2, ether('5'), claimAt],
                [token1, ether('5'), claimAt],
                [token1, ether('2'), claimAt],
                [token2, ether('15'), claimAt]
            ];

            const nftId = new BN('0');
            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await this.erc20Token2.approve(this.f.address, underlyingAmounts[1], { from: creator });
            await this.f.create(createReq, claims, { from: creator });

            const pool = await this.f.getPool(nftId);
            expect(pool.name).to.equal(name);
            expect(pool.metadata).to.equal(metadata);
            expect(pool.creator).to.equal(creator);
            expect(pool.nftAmount).to.be.bignumber.equal(new BN('1'));
            expect(pool.underlyingTokens[0]).to.equal(underlyingTokens[0]);
            expect(pool.underlyingTokens[1]).to.equal(underlyingTokens[1]);
            expect(pool.underlyingAmounts[0]).to.be.bignumber.equal(underlyingAmounts[0]);
            expect(pool.underlyingAmounts[1]).to.be.bignumber.equal(underlyingAmounts[1]);
            expect(pool.claimType).to.be.bignumber.equal(claimType);

            expect(await this.f.getClaimLength(nftId)).to.be.bignumber.equal(new BN('6'));
            for (let i = 0; i < claims.length; i++) {
                let claim = await this.f.getClaim(nftId, i);
                expect(claim.token).to.equal(claims[i][0]);
                expect(claim.amount).to.be.bignumber.equal(claims[i][1]);
                expect(claim.claimAt).to.be.bignumber.equal(claims[i][2]);
            }

            expect(await this.erc20Token.balanceOf(creator)).to.be.bignumber.equal(ether('9980'));
            expect(await this.erc20Token.balanceOf(this.f.address)).to.be.bignumber.equal(ether('10020'));
            expect(await this.f.ownerOf(nftId)).to.equal(creator);
        });

        it('when claim should be ok', async function () {
            const nftId = new BN('0');
            expect(await this.f.ownerOf(nftId)).to.equal(creator);
            await this.f.claim(nftId, { from: creator });
            await expectRevert(this.f.ownerOf(nftId), 'ERC721: owner query for nonexistent token');
            expect(await this.erc20Token.balanceOf(creator)).to.be.bignumber.equal(ether('10000'));
            expect(await this.erc20Token.balanceOf(this.f.address)).to.be.bignumber.equal(ether('10000'));
        });

        it('when re-create should be ok', async function() {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address, this.erc20Token2.address];
            const underlyingAmounts = [ether('20'), ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const token2 = this.erc20Token2.address;
            const amount = ether('20');
            const claimAt = new BN('0');
            const claims = [[token1, amount, claimAt], [token2, amount, claimAt]];

            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await this.erc20Token2.approve(this.f.address, underlyingAmounts[1], { from: creator });
            await this.f.create(createReq, claims, { from: creator });
        });

        it('when same underlying tokens should throw exception', async function() {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address, this.erc20Token.address];
            const underlyingAmounts = [ether('20'), ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const token2 = this.erc20Token.address;
            const amount = ether('10');
            const claimAt = new BN('0');
            const claims = [[token1, amount, claimAt], [token2, amount, claimAt]];

            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await this.erc20Token.approve(this.f.address, underlyingAmounts[1], { from: creator });
            await expectRevert(
                this.f.create(createReq, claims, { from: creator }),
                'duplicated token'
            );
        });

        it('when different length of tokens should throw exception 1', async function() {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address];
            const underlyingAmounts = [ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const token2 = this.erc20Token2.address;
            const amount = ether('10');
            const claimAt = new BN('0');
            const claims = [[token1, amount, claimAt], [token2, amount, claimAt]];

            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await expectRevert(
                this.f.create(createReq, claims, { from: creator }),
                'different length of tokens'
            );
        });

        it('when different length of tokens should throw exception 2', async function() {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address, this.erc20Token2.address];
            const underlyingAmounts = [ether('20'), ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const amount = ether('20');
            const claimAt = new BN('0');
            const claims = [[token1, amount, claimAt]];

            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await this.erc20Token2.approve(this.f.address, underlyingAmounts[1], { from: creator });
            await expectRevert(
                this.f.create(createReq, claims, { from: creator }),
                'different length of tokens'
            );
        });

        it('when different amount should throw exception', async function() {
            const name = "name";
            const metadata = "metadata";
            const underlyingTokens = [this.erc20Token.address, this.erc20Token2.address];
            const underlyingAmounts = [ether('20'), ether('20')];
            const claimType = new BN('0');
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts, claimType];

            const token1 = this.erc20Token.address;
            const token2 = this.erc20Token2.address;
            const amount = ether('10');
            const claimAt = new BN('0');
            const claims = [[token1, amount, claimAt], [token2, amount, claimAt]];

            await this.erc20Token.approve(this.f.address, underlyingAmounts[0], { from: creator });
            await this.erc20Token2.approve(this.f.address, underlyingAmounts[1], { from: creator });
            await expectRevert(
                this.f.create(createReq, claims, { from: creator }),
                'different amount of token'
            );
        });
    });
});
