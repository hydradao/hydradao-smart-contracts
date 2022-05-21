import { ethers } from "hardhat";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber } from 'ethers'
import type { HydraERC20, PRHydraERC20, HydraTreasury, MockERC20, Minting } from '../typechain-types'

const kevin = "0x05f15A393e8f2da4756316b439ee9104F2A6f2b8";

async function main() {
  let hydr: HydraERC20
  let prhydr: PRHydraERC20

  let treasury: HydraTreasury

  let dai: MockERC20
  let usdc: MockERC20

  let minting: Minting

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
  hydr = await HydraTokenFactory.deploy()

  const PRHydraERC20 = await ethers.getContractFactory("PRHydraERC20")
  prhydr = await PRHydraERC20.deploy() as PRHydraERC20

  const TreasuryFactory = await ethers.getContractFactory("HydraTreasury")
  treasury = await TreasuryFactory.deploy(deployer.address, hydr.address) as HydraTreasury

  const MockERC20Factory = await ethers.getContractFactory("MockERC20")
  dai = await MockERC20Factory.deploy("DAI Stablecoin", "DAI")
  usdc = await MockERC20Factory.deploy("USDC Stablecoin", "USDC")

  await dai.mint(deployer.address, "1000000000000000000000000")
  await usdc.mint(deployer.address, "1000000000000000000000000")

  await dai.mint(kevin, "1000000000000000000000000")
  await usdc.mint(kevin, "1000000000000000000000000")

  await treasury.addCoinToWhitelist(dai.address)
  await treasury.addCoinToWhitelist(usdc.address)

  const Minting = await ethers.getContractFactory("Minting")
  minting = await Minting.deploy(treasury.address, prhydr.address) as Minting

  // await dai.connect(deployer).approve(minting.address, "1000000000000000000000")
  // await usdc.connect(deployer).approve(minting.address, "1000000000000000000000")

  console.log("hydr: ", hydr.address);
  console.log("prhydr: " + prhydr.address);
  console.log("treasury: " + treasury.address);
  console.log("dai: " + dai.address);
  console.log("usdc: " + usdc.address);
  console.log("minting: " + minting.address);
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
