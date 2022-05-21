import { ethers } from "hardhat";
import { expect } from "chai"
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type { HydraERC20 } from '../typechain-types'

describe("HydraERC20", function () {

    let token: HydraERC20
    let vault: SignerWithAddress
    let alan: SignerWithAddress
    let andrew: SignerWithAddress

    before(async () => {
        [vault, andrew, alan] = await ethers.getSigners();
        const HydraTokenFactory = await ethers.getContractFactory("HydraERC20")
        token = await HydraTokenFactory.deploy()
    });

    describe("Mint", () => {
        it("increases balance of minter", async () => {
            const amountToMint = 1
            token.mint(andrew.address, amountToMint)
            expect(await token.balanceOf(andrew.address)).to.equal(amountToMint)
        });

    })
});