var PebbleToken = artifacts.require("PebbleToken");
var SafeRightsToken = artifacts.require("SafeRightsToken");

module.exports = function(deployer) {
  deployer.deploy(PebbleToken).then(function() {
    return deployer.deploy(SafeRightsToken, PebbleToken.address);
  });
};
