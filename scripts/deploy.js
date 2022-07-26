const hre = require("hardhat");

async function main() {

  const [deployer, alice, bob] = await ethers.getSigners();
  const OBSIDIANTOKEN = await hre.ethers.getContractFactory("ObsidianToken");
  const obsidianToken = await OBSIDIANTOKEN.deploy(1000000);

  const LAVATOKEN = await hre.ethers.getContractFactory("LavaToken");
  const lavaToken = await LAVATOKEN.deploy(1000000);

  const RUBYPOOL = await hre.ethers.getContractFactory("RubyPool");
  const RubyPool = await RUBYPOOL.deploy(obsidianToken.address, lavaToken.address);

  //deployer somehow sends tokens to alice and bob
  await obsidianToken.transfer(alice.address, 300000)
  await lavaToken.transfer(alice.address, 500000)

  await obsidianToken.transfer(bob.address, 100000)
  await lavaToken.transfer(bob.address, 100000)

  //users approve rubyPool
  await obsidianToken.connect(alice).approve(RubyPool.address, 300000)
  await lavaToken.connect(alice).approve(RubyPool.address, 500000)

  //users add to stake
  await RubyPool.connect(alice).addStake0(300000)
  await RubyPool.connect(alice).addStake1(500000)

  //let's say bob exchanges 100000 of lava tokens

  //firstly approves rubypool
  await lavaToken.connect(bob).approve(RubyPool.address, 100000)

  //bob exchanges 100000 of LavaToken
  await RubyPool.connect(bob).exchange1to0(100000)

  //bob should get 49 916 + 100 000 of obsidian token 
  //prize = 200 lava tokens
  //alice should have 200 tokens in prize

  let bobObsidian = (await obsidianToken.balanceOf(bob.address)).toString()
  let alicePrize = (await RubyPool.prize1(alice.address)).toString()

  console.log('Bob Obsidian Balance: ', bobObsidian, ' should be 10000 + 49916')
  console.log('Alice Prize         : ', alicePrize, ' should be 200')
} 

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});