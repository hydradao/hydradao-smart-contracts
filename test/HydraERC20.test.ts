import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type { HydraERC20 } from '../typechain-types'

describe("HydraERC20", function () {

    let token: HydraERC20
    let vault: SignerWithAddress
    let alan: SignerWithAddress
    let andrew: SignerWithAddress

    const initialSupply = 100

    beforeEach(async() => {
        [vault, andrew, alan] = await ethers.getSigners();
        const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
        token = await HydraTokenFactory.deploy(initialSupply, vault.address)
        await token.deployed()
    });

    it("creates an ERC20 token", async() => {
        expect(await token.balanceOf(vault.address)).to.equal(initialSupply)
    })

    describe("Mint", () => {
        it("increases balance of minter", async() => {
            const amountToMint = 1
            token.mint(andrew.address, amountToMint)
            expect(await token.balanceOf(andrew.address)).to.equal(amountToMint)
        });
    
        it("must be done by vault", async() => {
            await expect(token.connect(andrew).mint(alan.address, 1))
            .to.be.reverted
        })
    })
  });