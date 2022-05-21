import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type { HydraERC20, HydraTreasury, MockERC20 } from '../typechain-types'

describe("Treasury", async () => {
    let token: HydraERC20
    let vault: SignerWithAddress
    let alan: SignerWithAddress
    let andrew: SignerWithAddress

    let treasury: HydraTreasury
    let treasury1: HydraTreasury

    let dai: MockERC20
    let frax: MockERC20


    before(async () => {
        [vault, andrew, alan] = await ethers.getSigners();
        const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
        token = await HydraTokenFactory.deploy()

        const TreasuryFactory = await ethers.getContractFactory("HydraTreasury")
        treasury = await TreasuryFactory.deploy(vault.address, token.address) as HydraTreasury
        treasury1 = await TreasuryFactory.deploy(vault.address, token.address) as HydraTreasury

        const MockERC20Factory = await ethers.getContractFactory("MockERC20")
        dai = await MockERC20Factory.deploy("Dai Stablecoin", "DAI")
        frax = await MockERC20Factory.deploy("Frax Stablecoin", "FRAX")
    });

    describe("Asset Whitelist", async () => {

        it("should be 0 at initialization", async () => {
            expect((await treasury.getWhitelistedCoins()).length).to.equal(0)
        })

        it("should be able to add a token", async () => {
            await treasury.addCoinToWhitelist(dai.address)
            await treasury.addCoinToWhitelist(frax.address)
            expect((await treasury.getWhitelistedCoins()).length).to.equal(2)
        })

        it("should prevent token from being added twice", async () => {
            await expect(treasury.addCoinToWhitelist(dai.address))
                .to.be.reverted
        })

        it("should be able to remove a token", async () => {
            await treasury.removeCoinFromWhitelist(frax.address)
            expect((await treasury.getWhitelistedCoins()).length).to.equal(1)
        })

        it("should fail to remove if not on whitelist", async () => {
            await expect(treasury.removeCoinFromWhitelist(frax.address))
                .to.be.reverted
        })
    })

    describe("Reserves", async () => {

        let andrewSpend = 100
        let alanSpend = 200
        const initialSupply = 1000

        before(async () => {
            await dai.mint(andrew.address, initialSupply)
            await frax.mint(alan.address, initialSupply)

            await dai.connect(andrew).approve(treasury1.address, andrewSpend)
            await frax.connect(alan).approve(treasury1.address, alanSpend)

            await treasury1.addCoinToWhitelist(dai.address)
            await treasury1.addCoinToWhitelist(frax.address)
        })

        it("should be able to mint HYDR", async () => {
            await dai.connect(andrew).approve(treasury1.address, andrewSpend)
            await frax.connect(alan).approve(treasury1.address, alanSpend)

            const amountInHYDR = 100
            await treasury1.connect(andrew).mintHYDR(amountInHYDR, andrew.address)
            await treasury1.connect(alan).mintHYDR(amountInHYDR, alan.address)

            expect(await token.balanceOf(andrew.address)).to.equal(amountInHYDR)
            expect(await token.balanceOf(alan.address)).to.equal(amountInHYDR)
        })
    })

})