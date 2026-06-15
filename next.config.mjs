/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    // Supabase Storage (ajuste o host do seu projeto):
    remotePatterns: [{ protocol: "https", hostname: "*.supabase.co" }],
  },
};
export default nextConfig;
