const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with address:", deployer.address);

  const FreelancePlatform = await ethers.getContractFactory("FreelancePlatform");
  const contract = await FreelancePlatform.deploy();

  await contract.deployed();
  console.log("FreelancePlatform deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
