// Load dependencies
const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { BN, constants, ether, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');

const FinanceIndexAbi = require("../artifacts/contracts/FinanceIndexV2.sol/FinanceIndexV2.json")
const FinanceIndex = contract.fromABI(FinanceIndexAbi.abi, FinanceIndexAbi.bytecode);
const ERC20 = contract.fromArtifact('@openzeppelin/contracts/ERC20PresetMinterPauser');

const WETH = contract.fromArtifact(require('path').resolve('test/WETH9'));
const UniswapV2Factory = contract.fromArtifact(require('path').resolve('test/UniswapV2Factory'));
const UniswapV2Router02 = contract.fromArtifact(require('path').resolve('test/UniswapV2Router02'));

// Start test block
describe('Index', function () {
    const [ owner, platform, creator, buyer, buyer2 ] = accounts;

    beforeEach(async function () {
        // Deploy contract for each test
        this.f = await FinanceIndex.new({ from: owner });

        // Deploy a ERC20 contract for each test
        this.token1 = await ERC20.new('Test Token', 'TST1', { from: owner });
        this.token2 = await ERC20.new('Test Token', 'TST2', { from: owner });
        this.matter = await ERC20.new('MATTER Token', 'MATTER', { from: owner });

        // initialize contract
        const uri = 'https://nft.token';
        const fee = ether('0.05');
        await this.f.initialize(uri, this.matter.address, platform, fee, { from: owner });
        await expectRevert(
            this.f.initialize(uri, this.matter.address, platform, fee, { from: owner }),
            'Initializable: contract is already initialized.'
        );
        expect(await this.f.uri(0)).to.equal(uri);
        expect(await this.f.matter()).to.equal(this.matter.address);
        expect(await this.f.platform()).to.equal(platform);
        expect(await this.f.fee()).to.be.bignumber.equal(fee);

        // mint ERC20 token
        await this.matter.mint(owner,  ether('10000'), { from: owner });
        await this.token1.mint(owner, ether('10000'), { from: owner });
        await this.token1.mint(buyer, ether('10000'), { from: owner });
        await this.token1.mint(buyer2, ether('10000'), { from: owner });
        await this.token2.mint(owner, ether('10000'), { from: owner });
        await this.token2.mint(buyer, ether('10000'), { from: owner });
        await this.token2.mint(buyer2, ether('10000'), { from: owner });

        // Deploy a uniswap contract for each test
        this.weth = await WETH.new();
        this.uniswapV2Factory = await UniswapV2Factory.new(owner, { from: owner });
        this.uniswapV2Router02 = await UniswapV2Router02.new(this.uniswapV2Factory.address, this.weth.address, { from: owner });

        expect(await this.f.router()).to.equal('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
        await this.f.setUniswapV2Router(this.uniswapV2Router02.address, { from: owner });
        expect(await this.f.router()).to.equal(this.uniswapV2Router02.address);
        expect(await this.f.factory()).to.equal('0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f');
        await this.f.setUniswapV2Factory(this.uniswapV2Factory.address, { from: owner });
        expect(await this.f.factory()).to.equal(this.uniswapV2Factory.address);

        let amountTokenDesired = ether('10000');
        let amountETHDesired = ether('100');
        let amountTokenMin = ether('1');
        let amountETHMin = ether('1');
        const to = owner;
        const deadline = (await time.latest()).add(time.duration.minutes(20));
        await this.uniswapV2Factory.createPair(this.weth.address, this.token1.address, { from: owner });
        await this.token1.approve(this.uniswapV2Router02.address, amountTokenDesired, { from: owner });
        await this.uniswapV2Router02.addLiquidityETH(
            this.token1.address, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline,
            { from: owner, value: amountETHDesired }
        );

        await this.uniswapV2Factory.createPair(this.weth.address, this.token2.address, { from: owner });
        await this.token2.approve(this.uniswapV2Router02.address, amountTokenDesired, { from: owner });
        await this.uniswapV2Router02.addLiquidityETH(
            this.token2.address, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline,
            { from: owner, value: amountETHDesired }
        );

        await this.uniswapV2Factory.createPair(this.weth.address, this.matter.address, { from: owner });
        await this.matter.approve(this.uniswapV2Router02.address, amountTokenDesired, { from: owner });
        await this.uniswapV2Router02.addLiquidityETH(
            this.matter.address, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline,
            { from: owner, value: amountETHDesired }
        );
    });

    describe("createIndex token1/token2", function () {
        beforeEach(async function () {
            const name = 'test index';
            const metadata = 'test metadata';
            const underlyingTokens = [
                this.token1.address,
                this.token2.address
            ];
            const underlyingAmounts = [
                ether('100'),
                ether('100')
            ];
            const createReq = [name, metadata, underlyingTokens, underlyingAmounts];
            await this.f.createIndex(createReq, { from: creator });
            const nftId = 0;
            expect(await this.f.nextNftId()).to.be.bignumber.equal(new BN('1'));
            const index = await this.f.getIndex(nftId);
            expect(index.name).to.equal(name);
            expect(index.metadata).to.equal(metadata);
            expect(index.creator).to.equal(creator);
            expect(index.underlyingTokens[0]).to.equal(underlyingTokens[0]);
            expect(index.underlyingAmounts[0]).to.be.bignumber.equal(underlyingAmounts[0]);
            expect(index.underlyingTokens[1]).to.equal(underlyingTokens[1]);
            expect(index.underlyingAmounts[1]).to.be.bignumber.equal(underlyingAmounts[1]);
        });

        it('when mint/burn should be ok', async function () {
            const nftId = 0;
            const nftAmount = new BN('10');
            const amountInMaxs = [ether('30'), ether('50')];
            let beforeBuyer = await web3.eth.getBalance(buyer);
            await this.f.mint(nftId, nftAmount, amountInMaxs, { from: buyer, value: ether('70'), gasPrice: 100e9 });
            let afterBuyer = await web3.eth.getBalance(buyer);
            console.log(`Buyer gas fee: ${web3.utils.fromWei(new BN(beforeBuyer).sub(new BN(afterBuyer)))}`);
            expect(await this.f.balanceOf(buyer, nftId)).to.be.bignumber.equal(nftAmount);
            expect(await this.token1.balanceOf(this.f.address)).to.be.bignumber.equal(ether('1000'));
            expect(await this.token2.balanceOf(this.f.address)).to.be.bignumber.equal(ether('1000'));

            const amountOutMins = [ether('0'), ether('0')];
            await this.f.setApprovalForAll(this.f.address, true, { from: buyer });
            beforeBuyer = await web3.eth.getBalance(buyer);
            await this.f.burn(nftId, nftAmount, amountOutMins, { from: buyer, gasPrice: 100e9 });
            afterBuyer = await web3.eth.getBalance(buyer);
            console.log(`Buyer gas fee burn: ${web3.utils.fromWei(new BN(beforeBuyer).sub(new BN(afterBuyer)))}`);
            expect(await this.f.balanceOf(buyer, nftId)).to.be.bignumber.equal(new BN('0'));
            expect(await this.token1.balanceOf(this.f.address)).to.be.bignumber.equal(ether('0'));
            expect(await this.token2.balanceOf(this.f.address)).to.be.bignumber.equal(ether('0'));

            expect(await web3.eth.getBalance(platform)).to.be.bignumber.equal(ether('1000000.025'));
            expect(await this.f.creatorTotalFee(creator)).to.be.bignumber.equal(ether('0.025'));
            expect(await this.f.creatorClaimedFee(creator)).to.be.bignumber.equal(ether('0'));
            await this.f.creatorClaim({from: creator});
            expect(await this.matter.balanceOf(creator)).to.be.bignumber.equal(ether('2.491878899184378293'));
            expect(await this.f.creatorTotalFee(creator)).to.be.bignumber.equal(ether('0.025'));
            expect(await this.f.creatorClaimedFee(creator)).to.be.bignumber.equal(ether('0.025'));
        });

        it('when mint/burn index not exists should throw exception', async function () {
            const nftId = 1;
            const nftAmount = new BN('10');
            const amountInMaxs = [ether('30'), ether('50')];
            await expectRevert(
                this.f.mint(nftId, nftAmount, amountInMaxs, { from: buyer, value: ether('100') }),
                'index not exists'
            );

            const amountOutMins = [ether('0'), ether('0')];
            await expectRevert(
                this.f.burn(nftId, nftAmount, amountOutMins, { from: buyer }),
                'index not exists'
            );
        });
    });

    it('when setURI should be ok', async function () {
        const uri = 'https://antimatter.finance/';
        await expectRevert(
            this.f.setURI(uri, { from: buyer }),
            'Ownable: caller is not the owner'
        );

        await this.f.setURI(uri, { from: owner });

        console.log(this.f.address);
        console.log(await this.f.uri(0));
    });
});
