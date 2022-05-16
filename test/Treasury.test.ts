import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type { HydraERC20, HydraTreasury, MockERC20 } from '../typechain-types'

describe.only("Treasury", () => {

    let token: HydraERC20
    let vault: SignerWithAddress
    let alan: SignerWithAddress
    let andrew: SignerWithAddress

    let treasury: HydraTreasury

    let dai: MockERC20
    let frax: MockERC20
    let usdc: MockERC20
    // usdc is 6 decimals, TODO: need to handle decimals correctly

    const initialSupply = 100

    before(async() => {
        [vault, andrew, alan] = await ethers.getSigners();
        const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
        token = await HydraTokenFactory.deploy(initialSupply, vault.address)

        const TreasuryFactory = await ethers.getContractFactory("HydraTreasury")
        treasury = await TreasuryFactory.deploy(vault.address, token.address, 50) as HydraTreasury

        const MockERC20Factory = await ethers.getContractFactory("MockERC20")
        dai = await MockERC20Factory.deploy("Dai Stablecoin", "DAI")
        frax = await MockERC20Factory.deploy("Frax Stablecoin", "FRAX")
    });

    describe("Asset Whitelist", async() => {
        
        it("should be 0 at initialization", async() => {
            expect((await treasury.getWhitelistedCoins()).length).to.equal(0)
        })

        it("should be able to add a token", async() => {
            await treasury.addCoinToWhitelist(dai.address)
            await treasury.addCoinToWhitelist(frax.address)
            expect((await treasury.getWhitelistedCoins()).length).to.equal(2)
        })

        it("should prevent token from being added twice", async() => {
            await expect(treasury.addCoinToWhitelist(dai.address))
            .to.be.reverted
        })

        it("should be able to remove a token", async() => {
            await treasury.removeCoinFromWhitelist(frax.address)
            expect((await treasury.getWhitelistedCoins()).length).to.equal(1)
        })

        it("should fail to remove if not on whitelist", async() => {
            await expect(treasury.removeCoinFromWhitelist(frax.address))
            .to.be.reverted
        })
    })
    
})