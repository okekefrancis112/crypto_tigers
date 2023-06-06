import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { TigerBasicNFT } from "../../typechain-types/TigerBasicNFT";
import { TigerBasicNFT__factory } from "../../typechain-types/factories/TigerBasicNFT__factory";

task("deploy:TigerBasicNFT")
  .addParam("artist", "0xa63a81e3921169b5fd565d54fc84c9a359893cb2")
  .addParam("startingprice", "1")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const tigerFactory: TigerBasicNFT__factory = <TigerBasicNFT__factory>await ethers.getContractFactory("TigerBasicNFT");
    const tiger: TigerBasicNFT = <TigerBasicNFT>await tigerFactory.deploy(taskArguments.artist, ethers.utils.parseEther(taskArguments.startingprice));
    await tiger.deployed();
    console.log("TigerBasicNFT deployed to: ", tiger.address);
  });
