/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    NFT_MARKET_CONTRACT_ADDRESS:"0xC065666d3108f877BeF3E94345aF2591d13F78ED",
    NFT_CONTRACT_ADDRESS:"0xC065666d3108f877BeF3E94345aF2591d13F78ED12",
    CHAIN_ID:3
  },
  reactStrictMode: true,
  images: {
    domains: ['ipfs.infura.io'],
  },
}

module.exports = nextConfig
