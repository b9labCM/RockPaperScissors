var Owned = artifacts.require("./Owned.sol");
var Stoppable = artifacts.require("./Stoppable.sol");
var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

module.exports = function(deployer) {
  deployer.deploy(Owned);
  deployer.deploy(Stoppable);
  deployer.link(Owned, Stoppable, RockPaperScissors);
  //deployer.autolink();
  deployer.deploy(RockPaperScissors);
};
