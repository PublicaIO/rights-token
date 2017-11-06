var PebbleToken = artifacts.require("PebbleToken");
var SafeRightsToken = artifacts.require("SafeRightsToken");

module.exports = function(deployer) {
  deployer.deploy(PebbleToken);
  deployer.deploy(SafeRightsToken);  
};
