import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, log, read } = deployments;
  const { deployer } = await getNamedAccounts();

  const res = await deploy("FHEWeightTrend", {
    from: deployer,
    // ⬇️ укажи FQN: путь к файлу и имя контракта
    contract: "contracts/FHEWeightTrend.sol:FHEWeightTrend",
    args: [],
    log: true,
  });

  log(`✅ FHEWeightTrend deployed at: ${res.address}`);

  try {
    const v: string = await read("FHEWeightTrend", "version");
    log(`ℹ️ version(): ${v}`);
  } catch (e) {
    log(`(warn) version() read failed: ${(e as Error).message}`);
  }
};

export default func;
func.id = "deploy_PrivateProfitDistributor";
func.tags = ["PrivateProfitDistributor"];
