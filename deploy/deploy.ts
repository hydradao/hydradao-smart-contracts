import { utils, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import type { HydraERC20, PRHydraERC20, HydraTreasury, MockERC20, Minting } from '../typechain-types'

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(hre);

  // Initialize the wallet.
  const wallet = new Wallet("0x0b123d4a85ec0b94cffcc9bdbdb1c3af9f1f62113ba135eb0540a31db4afce61");

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);

  // Deposit some funds to L2 in order to be able to perform L2 transactions.
  const depositAmount = ethers.utils.parseEther("0.045");
  const depositHandle = await deployer.zkWallet.deposit({
    to: deployer.zkWallet.address,
    token: utils.ETH_ADDRESS,
    amount: depositAmount,
  });

  // Wait until the deposit is processed on zkSync
  await depositHandle.wait();

  const HydraTokenFactory = await deployer.loadArtifact("HydraERC20")
  const hydr = await deployer.deploy(HydraTokenFactory, [])

  const PRHydraERC20 = await deployer.loadArtifact("PRHydraERC20")
  const prhydr = await deployer.deploy(PRHydraERC20, []) as PRHydraERC20

  const TreasuryFactory = await deployer.loadArtifact("HydraTreasury")
  const treasury = await deployer.deploy(TreasuryFactory, [deployer.zkWallet.address, hydr.address])

  const MockERC20Factory = await deployer.loadArtifact("MockERC20")
  const dai = await deployer.deploy(MockERC20Factory, ["DAI Stablecoin", "DAI"])
  const usdc = await deployer.deploy(MockERC20Factory, ["USDC Stablecoin", "USDC"])

  await dai.mint(deployer.zkWallet.address, "1000000000000000000000000")
  await usdc.mint(deployer.zkWallet.address, "1000000000000000000000000")

  await treasury.addCoinToWhitelist(dai.address)
  await treasury.addCoinToWhitelist(usdc.address)

  const Minting = await deployer.loadArtifact("Minting")
  const minting = await deployer.deploy(Minting, [treasury.address, prhydr.address]) as Minting

  // await dai.connect(deployer).approve(minting.address, "1000000000000000000000")
  // await usdc.connect(deployer).approve(minting.address, "1000000000000000000000")

  console.log(`HYDRA_TREASURY_ADDRESS: "${treasury.address}",`);
  console.log(`HYDRA_MINTING_ADDRESS: "${minting.address}",`);
  console.log(`HYDR_ADDRESS: "${hydr.address}",`);
  console.log(`PRHYDR_ADDRESS: "${prhydr.address}",`);
  console.log(`DAI_ADDRESS: "${dai.address}",`);
  console.log(`USDC_ADDRESS: "${usdc.address}",`);
}