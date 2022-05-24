import { task, subtask } from "hardhat/config";
import '@typechain/hardhat';
import * as dotenv from 'dotenv';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import glob from "glob";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD, TASK_TEST_GET_TEST_FILES } from "hardhat/builtin-tasks/task-names";
import path from "path";

dotenv.config({ path: __dirname + '/.env' });

const chainIds = {
	goerli: 5,
	hardhat: 1337,
	kovan: 42,
	mainnet: 1,
	rinkeby: 4,
	ropsten: 3,
	mumbai: 80001,
	arbitrum_rinkeby: 421611
};

const privateKey = process.env.PRIVATE_KEY ?? "NO_PRIVATE_KEY";

const alchemyApiKey = process.env.ALCHEMY_API_KEY ?? "NO_ALCHEMY_API_KEY";


function getChainConfig(network: keyof typeof chainIds): NetworkUserConfig {
	/** 
	 * 	Arbitrun Rinkeby link
		const url = `https://arb-rinkeby.g.alchemy.com/v2/${alchemyApiKey}`;
	*/

	/**
	 * Matic testnet
		const url = `https://polygon-mumbai.g.alchemy.com/v2/${alchemyApiKey}`;
	 */

	const url = `https://eth-${network}.alchemyapi.io/v2/${alchemyApiKey}`;
	return {
		accounts: [`0x${privateKey}`],
		chainId: chainIds[network],
		url,
		zksync: false,
	};
}

subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD, async (args: any, hre, runSuper) => {
	if (args.solcVersion === "0.8.5") {
		const compilerPath = path.join(__dirname, "soljson-v0.8.5-nightly.2021.5.12+commit.98e2b4e5.js");

		return {
			compilerPath,
			isSolcJs: true, // if you are using a native compiler, set this to false
			version: args.solcVersion,
			// this is used as extra information in the build-info files, but other than
			// that is not important
			longVersion: "0.8.5-nightly.2021.5.12+commit.98e2b4e5"
		}
	}

	// we just use the default subtask if the version is not 0.8.5
	return runSuper();
})

task("accounts", "Prints the list of accounts", async (args, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(await account.address);
	}
});

task(TASK_TEST_GET_TEST_FILES, async ({ testFiles }) => {
	const overriddenTestFiles = glob.sync("tests/**/*.test.ts");
	return overriddenTestFiles;
});


const config: HardhatUserConfig = {
	zksolc: {
		version: "0.1.0",
		compilerSource: "docker",
		settings: {
			compilerPath: "zksolc",
			optimizer: {
				enabled: true,
			},
			experimental: {
				dockerImage: "matterlabs/zksolc",
			},
		},
	},
	zkSyncDeploy: {
		zkSyncNetwork: "https://zksync2-testnet.zksync.dev",
		ethNetwork: "goerli", // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
	},
	// Your type-safe config goes here
	solidity: "0.8.5",
	networks: {
		hardhat: {
			zksync: true,
		},
		mainnet: getChainConfig("mainnet"),
		rinkeby: getChainConfig("rinkeby"),
		mumbai: getChainConfig("mumbai"),
		arbitrum_rinkeby: getChainConfig("arbitrum_rinkeby"),
	},
};

export default config;
