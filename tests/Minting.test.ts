import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber } from 'ethers'
import type { HydraERC20, PRHydraERC20, HydraTreasury, MockERC20, Minting } from '../typechain-types'


function getRoundInfo(info: [BigNumber, BigNumber, BigNumber]) {
  return [info[0].toNumber(), info[1].toNumber(), info[2].toNumber()]
}

describe("Minting", async () => {
  let hydr: HydraERC20
  let prhydr: PRHydraERC20

  let vault: SignerWithAddress
  let alan: SignerWithAddress

  let treasury: HydraTreasury

  let dai: MockERC20
  let frax: MockERC20

  let minting: Minting


  before(async () => {
    [vault, alan] = await ethers.getSigners();
    const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
    hydr = await HydraTokenFactory.deploy()

    const PRHydraERC20 = await ethers.getContractFactory("PRHydraERC20")
    prhydr = await PRHydraERC20.deploy() as PRHydraERC20

    const TreasuryFactory = await ethers.getContractFactory("HydraTreasury")
    treasury = await TreasuryFactory.deploy(vault.address, hydr.address) as HydraTreasury

    const MockERC20Factory = await ethers.getContractFactory("MockERC20")
    dai = await MockERC20Factory.deploy("Dai Stablecoin", "DAI")
    frax = await MockERC20Factory.deploy("Frax Stablecoin", "FRAX")

    await dai.mint(alan.address, "1000000000000000000000")
    await frax.mint(alan.address, "1000000000000000000000")

    await treasury.addCoinToWhitelist(dai.address)
    await treasury.addCoinToWhitelist(frax.address)

    const Minting = await ethers.getContractFactory("Minting")
    minting = await Minting.deploy(treasury.address, prhydr.address) as Minting

    await dai.connect(alan).approve(minting.address, "1000000000000000000000")
    await frax.connect(alan).approve(minting.address, "1000000000000000000000")
  });

  describe("activate and update", async () => {

    it("should be able to get the current round info", async () => {
      const [id, start, end] = getRoundInfo(await minting.getRoundInfo())
      expect(id).to.equal(0);
      expect(start).to.equal(0);
      expect(end).to.equal(0);
    })

    it("should be able activate the timer", async () => {
      await minting.activate();

      const activated = await minting.activated()
      expect(activated).to.equal(true);

      const [id, start, end] = getRoundInfo(await minting.getRoundInfo())

      expect(id).to.equal(1);
      expect(start).to.be.gt(0);
      expect(end).to.be.gt(0);

      const rewardSize = await minting.rewardSize();
      expect(rewardSize).to.equal(50);

      const winnerAddrsLength = await minting.winnerAddrsLengths(1)
      expect(winnerAddrsLength).to.equal(50);
    })

    it("should be able get Minting Hydr Amount", async () => {
      const amount = "1000000000000000000" // 10 ^ 18
      const hydrAmount = await minting.getMintingHydrAmount(amount)
      expect(hydrAmount).to.equal(amount);
    })

    it("should mint", async () => {
      const amount = "1000000000000000000" // 10 ^ 18
      await minting.connect(alan).mintHYDR(amount, dai.address, amount);

      expect((await dai.balanceOf(alan.address)).toString()).to.equal("999000000000000000000");

      expect(await hydr.balanceOf(alan.address)).to.equal(amount)

      expect((await minting.plyrRnds(alan.address, 1)).isEligibleForPrize).to.equal(true)
      expect((await minting.plyrRnds(alan.address, 1)).minted.toString()).to.equal(amount)
      expect((await minting.plyrRnds(alan.address, 1)).prize.toString()).to.equal(amount)

      expect((await minting.mintPrice()).toString()).to.equal("1000010000");

      // no reward
      expect((await minting.getReward(alan.address, 1)).toString()).to.equal("0");
    })

    it("should get reward", async () => {
      const [id, start, end] = getRoundInfo(await minting.getRoundInfo())

      await ethers.provider.send("evm_setNextBlockTimestamp", [end + 1])
      await ethers.provider.send("evm_mine", []) // this one will have 2021-07-01 12:00 AM as its timestamp, no matter what the previous block has

      const amount = "1000000000000000000" // 10 ^ 18
      await minting.connect(alan).mintHYDR("0", dai.address, amount);

      expect((await dai.balanceOf(alan.address)).toString()).to.equal("998000000000000000000");

      expect((await hydr.balanceOf(alan.address)).toString()).to.equal("2000000000000000000")

      expect((await minting.mintPrice()).toString()).to.equal("1000010000");

      // there is some reward
      expect((await minting.getReward(alan.address, 1)).toString()).to.equal("1000000000000000000");
      await minting.connect(alan).claimReward(1);
      expect((await minting.getReward(alan.address, 1)).toString()).to.equal("0");
      expect((await prhydr.balanceOf(alan.address)).toString()).to.equal("1000000000000000000");
    })

  })

})