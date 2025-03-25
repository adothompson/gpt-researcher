/** @type {import('next').NextConfig} */
const nextConfig = {
  // Optimize memory usage
  swcMinify: true,
  poweredByHeader: false,
  reactStrictMode: true,
  // Fix CSS module issues
  webpack: (config) => {
    // Optimize chunk size
    config.optimization.splitChunks = {
      chunks: 'all',
      maxInitialRequests: 25,
      minSize: 20000,
    };
    
    return config;
  },
  // Configure image optimization
  images: {
    remotePatterns: [
      {
        hostname: 'www.google.com',
      },
      {
        hostname: 'www.google-analytics.com',
      }
    ],
    // Reduce memory usage for image optimization
    minimumCacheTTL: 60,
  },
  // Increase memory limit for Next.js
  experimental: {
    // Reduce memory usage during builds
    memoryBasedWorkersCount: true,
  },
};

export default nextConfig;
