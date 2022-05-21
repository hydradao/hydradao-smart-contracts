import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type { FomoTimer } from '../typechain-types'
import { BigNumber } from 'ethers'


function getRoundInfo(info: [BigNumber, BigNumber, BigNumber]) {
  return [info[0].toNumber(), info[1].toNumber(), info[2].toNumber()]
}

describe("FomoTimer", async () => {

  let timer: FomoTimer
  let alan: SignerWithAddress

  before(async () => {
    [alan] = await ethers.getSigners();
    const FomoTimer = await ethers.getContractFactory("FomoTimer")
    timer = await FomoTimer.deploy() as FomoTimer
  });

  describe("activate and update", async () => {

    it("should be able to get the current round info", async () => {
      const roundInfo = await timer.getRoundInfo();
      roundInfo[0].toNumber()
      expect(roundInfo[0].toNumber()).to.equal(0);
      expect(roundInfo[1].toNumber()).to.equal(0);
      expect(roundInfo[2].toNumber()).to.equal(0);
    })

    it("should be able activate the timer", async () => {
      await timer.activateTimer();

      const activated = await timer.activated()
      expect(activated).to.equal(true);

      const roundInfo = await timer.getRoundInfo();
      expect(roundInfo[0].toNumber()).to.equal(1);
      expect(roundInfo[1].toNumber()).to.be.gt(0);
      expect(roundInfo[2].toNumber()).to.be.gt(0);
    })

    it("should be able updateTimer the timer", async () => {

      const [id, start, end] = getRoundInfo(await timer.getRoundInfo())

      await timer.updateTimerIfItCan("1000000000000000000")

      const [newId, newStart, newEnd] = getRoundInfo(await timer.getRoundInfo())
      expect(newId === id).to.equal(true);
      expect(start === newStart).to.equal(true);
      expect(end < newEnd).to.equal(true);
    })

    it("should end round if time passed the end", async () => {
      const [id, start, end] = getRoundInfo(await timer.getRoundInfo())

      await ethers.provider.send("evm_setNextBlockTimestamp", [end + 1])
      await ethers.provider.send("evm_mine", []) // this one will have 2021-07-01 12:00 AM as its timestamp, no matter what the previous block has

      await timer.endRoundIfItCan()

      const [newId, newStart, newEnd] = getRoundInfo(await timer.getRoundInfo())
      expect(newId === id + 1).to.equal(true);
      expect(newStart > end).to.equal(true);
      expect(newEnd > newStart).to.equal(true);
    })

  })

})