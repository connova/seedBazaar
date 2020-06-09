// SPDX-License-Identifier: MIT

const seedBazaar = artifacts.require('../contracts/seedBazaar');
const BigNumber = require("bignumber.js")
const truffleAssert = require("truffle-assertions");

contract("seedBazaar", (accounts) => {

    let seedBazaarInstance;
    
    let bazaarOwner = accounts[0]
    let balancebazaarOwner = 1;
    let seedOwner = accounts[1];
    let seedOwnerAmount = 1;
    let seedId = 0;



    before(async() => {
        seedBazaarInstance = await seedBazaar.deployed();
        const bazaarOwnerFromContract = await seedBazaarInstance.bazaarOwner.call();
        assert.equal(bazaarOwnerFromContract, bazaarOwner, "Bazaar owner is not as expected")
    })

    it("testing balanceOf()", async () => {
        const balanceInBazaar = seedBazaarInstance.balanceOf.call(seedOwner);
        assert.equal(balanceInBazaar, balanceSeedOwner, "Balance of account not as expected");
    })

    it("testing ownerOf()", async () => {
        const seedOwnerInBazaar = seedBazaarInstance.ownerOf.call(seedId);
        assert.equal(seedOwnerInBazaar, seedOwner, "Seed Owner is not as expected");
    })

    it("testing _transfer()", async () => {
        senderOldBalanceFromContract = await seedBazaarInstance.balanceOf(bazaarOwner);
        const tx = await seedBazaarInstance._transfer(bazaarOwner, seedOwner, seedOwnerAmount);
        
        const seedOwnerBalance = seedOwnerAmount;

        const seedOwnerBalanceFromContract = await seedBazaarInstance.balanceOf(seedOwner);
        const senderBalanceFromContract = await seedBazaarInstance.balanceOf(bazaarOwner);
        
        const senderExpectedBalance = web3.utils
        .toBN(senderOldBalanceFromContract)
        .sub(web3.utils.toBN(seedOwnerAmount));
        assert(senderBalanceFromContract.isEqualTo(
                (senderExpectedBalance)
            )
        );
        truffleAssert.eventEmitted(tx, "Transfer", (obj) => {
            return (
                obj.from === bazaarOwner &&
                obj.to === seedOwner &&
                seedOwnerAmount.isEqualTo(obj.value))
        });
        });
        assert(
            seedOwnerBalance.isEqualTo(seedOwnerBalanceFromContract),
            "The receipient's balance is not as expected"
        );
    });

    it("testing transferFrom()", async () => {
        const oldSeedOwnerBalance = await seedBazaarInstance.balanceOf.call(seedOwner);
        const approveTx = await seedBazaarInstance.approve(
            seedOwner,
            seedId
        );
        truffleAssert.eventEmitted(approveTx, "Approval", (obj) => {
            return (
                obj.from === bazaarOwner,
                obj.to === seedOwner,
                obj.seedId === seedId
            );
        })
        const allowanceFromContract = await seedBazaarInstance.getApproved.call(seedId);
        assert(
            (seedOwnerAmount).isEqualTo(allowanceFromContract),
            "The Allowance is not as expected"
            );
        const transferFromTx = await seedBazaarInstance.transferFrom(
            bazaarOwner,
            seedOwner,
            seedId
        );
        truffleAssert.evenEmitted(transferFromTx, "Transfer", (obj) => {
            return (
                obj.from === bazaarOwner,
                obj.to === seedOwner,
                obj.seedId === seedId
            );
        });
        const seedOwnerBalance = await seedBazaarInstance.balanceOf(seedOwner);
        assert(seedOwnerAmount.isEqualTo(seedOwnerBalance),
        "The balance is not as expected")
    })