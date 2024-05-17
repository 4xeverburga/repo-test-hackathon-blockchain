const GanacheTesting = artifacts.require("Test");
const ResolverTesting = artifacts.require("Solver");

module.exports = function(deployer) {

    deployer.deploy(ResolverTesting);
    deployer.deploy(GanacheTesting);
};
