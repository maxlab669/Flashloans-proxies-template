const { PriceServiceConnection} =  require("@pythnetwork/pyth-common-js");
const { Buffer } =  require("buffer");

class EvmPriceServiceConnection extends PriceServiceConnection {
  async getPriceFeedsUpdateData(priceIds) {
    const latestVaas = await this.getLatestVaas(priceIds);
    return latestVaas.map(
      (vaa) => "0x" + Buffer.from(vaa, "base64").toString("hex")
    );
  }
}

async function run() {
  const args = process.argv.slice(2);
  const id = args[0];

  const connection = new EvmPriceServiceConnection("https://xc-mainnet.pyth.network");

  const priceIds = [id];
  // const priceFeeds = await connection.getLatestPriceFeeds(priceIds);
  const updateData = await connection.getPriceFeedsUpdateData(priceIds);
  console.log(updateData[0]);
}

run();