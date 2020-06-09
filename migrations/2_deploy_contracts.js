// SPDX-License-Identifier: MIT

const seedBazaar = artifacts.require("../contracts/seedBazaar.sol");

module.exports = function(deployer) {
  deployer.deploy(seedBazaar);
}