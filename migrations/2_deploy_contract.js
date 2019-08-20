var MyContract = artifacts.require("VotingPoll");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(MyContract);
};