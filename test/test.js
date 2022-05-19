const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();
  const timerContractFactory = await hre.ethers.getContractFactory("Timer");
  const timerContract = await timerContractFactory.deploy();
  await timerContract.deployed();

  console.log("Contract deployed to:", timerContract.address);
  console.log("Contract deployed by:", owner.address);

  //test functions 
  let getCurrentRoundInfo;
  getCurrentRoundInfo = await timerContract.mint();
    
};

const runMain = async () => {
  try {
    await main();
    process.exit(0); // exit Node process without error
  } catch (error) {
    console.log(error);
    process.exit(1); // exit Node process while indicating 'Uncaught Fatal Exception' error
  }
  // Read more about Node exit ('process.exit(num)') status codes here: https://stackoverflow.com/a/47163396/7974948
};

runMain();