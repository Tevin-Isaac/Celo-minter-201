/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    NFT_MARKET_CONTRACT_ADDRESS:"0x6a84e7cd87d6A65303EdAA2DEcf51d8362B49636",
    NFT_CONTRACT_ADDRESS:" 0x0ccEae723EdCe35a5e3570923cCE7D0E2424434e",
    CHAIN_ID:44787
  },
  reactStrictMode: true,
  images: {
    domains: ['ipfs.infura.io'],
  },
}

module.exports = nextConfig
