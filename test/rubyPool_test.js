const {expect} = require('chai');

describe('RubyPool', ()=>{
    let RUBYPOOL, RubyPool, deployer, alice, bob;
    let OBSIDIANTOKEN, obsidianToken, LAVATOKEN, lavaToken
    let bobInitObs, bobInitLava
    let aliceInitObs, aliceInitLava
    beforeEach(async ()=>{

        [deployer, alice, bob] = await ethers.getSigners();
        OBSIDIANTOKEN = await ethers.getContractFactory("ObsidianToken");
        obsidianToken = await OBSIDIANTOKEN.deploy(1000000);
      
        LAVATOKEN = await ethers.getContractFactory("LavaToken");
        lavaToken = await LAVATOKEN.deploy(1000000);
      
        RUBYPOOL = await ethers.getContractFactory("RubyPool");
        RubyPool = await RUBYPOOL.deploy(obsidianToken.address, lavaToken.address);

        obsidianToken.transfer(alice.address, 300000)
        lavaToken.transfer(alice.address, 500000)
      
        obsidianToken.transfer(bob.address, 100000)
        lavaToken.transfer(bob.address, 100000)

        bobInitObs = 100000
        bobInitLava = 100000
        aliceInitObs = 300000
        aliceInitLava = 500000

        obsidianToken.connect(alice).approve(RubyPool.address, 300000)
        lavaToken.connect(alice).approve(RubyPool.address, 500000)

        obsidianToken.connect(bob).approve(RubyPool.address, 100000)
        lavaToken.connect(bob).approve(RubyPool.address, 100000)
        
    })

    describe("Users stake calculation", ()=> {

        it('should add staker to staker list',async ()=> {
            await RubyPool.connect(alice).addStake0(100000)
            await RubyPool.connect(alice).addStake1(500000)

            expect(await (RubyPool.staker0(0))).to.be.equal(alice.address)
            expect(await (RubyPool.staker1(0))).to.be.equal(alice.address)
            
        })


        it('should calculate correct stake amount add', async () => {
            expect(await(RubyPool.stake0(alice.address))).to.equal(0)
            expect(await(RubyPool.stake1(alice.address))).to.equal(0)

            await RubyPool.connect(alice).addStake0(100000)
            await RubyPool.connect(alice).addStake1(500000)

            expect(await(RubyPool.stake0(alice.address))).to.equal(100000)
            expect(await(RubyPool.stake1(alice.address))).to.equal(500000)

            await RubyPool.connect(alice).addStake0(200000)

            expect(await(RubyPool.stake0(alice.address))).to.equal(300000)
        })

        it('should calculate correct stake amount remove', async () => {
            expect(await(RubyPool.stake0(alice.address))).to.equal(0)

            await RubyPool.connect(alice).addStake0(300000)

            await RubyPool.connect(alice).removeStake0(200000)

            expect(await(RubyPool.stake0(alice.address))).to.equal(100000)
        })

    })

    describe('Exchange calculation correctness',()=>{
        it('should correctly exchange tokens', async ()=>{
            await RubyPool.connect(alice).addStake0(300000)
            await RubyPool.connect(alice).addStake1(500000)
            await RubyPool.connect(bob).exchange1to0(100000)

            let AMOUNTAFTERFEE = Math.floor(998/1000 * 100000)
            let EXCHANGEPRODUCT = Math.floor((300000*AMOUNTAFTERFEE)/(AMOUNTAFTERFEE+500000))
            
            expect(await(obsidianToken.balanceOf(bob.address))).to.equal(bobInitObs+EXCHANGEPRODUCT)

            //FORMULA: (pool0*trueAmount)/(pool1+trueAmount)
        })

        it('should distribute prize', async () => {
            await RubyPool.connect(alice).addStake0(300000)
            await RubyPool.connect(alice).addStake1(500000)
            await RubyPool.connect(bob).exchange1to0(100000)

            let AMOUNTAFTERFEE = Math.floor(998/1000 * 100000)
            let PRIZE = 100000 - AMOUNTAFTERFEE

            //we know that alice is the only staker so she should get 100%of the prize
            expect(await(RubyPool.prize1(alice.address))).to.be.equal(PRIZE)
        })

        it('should allow to withdraw prize', async () => {
            await RubyPool.connect(alice).addStake0(300000)
            await RubyPool.connect(alice).addStake1(500000)
            await RubyPool.connect(bob).exchange1to0(100000)

            let alicePrize = (await RubyPool.prize1(alice.address))

            
            //we know that alice is the only staker so she should get 100%of the prize
           
            await RubyPool.connect(alice).withdrawPrize1()

            expect(await (lavaToken.balanceOf(alice.address))).to.equal(alicePrize)
        })
    })
})