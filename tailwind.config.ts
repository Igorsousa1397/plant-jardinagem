import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        verde: {
          50: "#F3F8F4", 100: "#E6F1EA", 200: "#C5E0CE", 300: "#97C4A6",
          400: "#6BA67F", 500: "#45855C", 600: "#336B49", 700: "#275139",
          800: "#1E3A2B", 900: "#15281C",
        },
        salvia: "#7C8B6A",
        salviaSurface: "#EDF0E7",
        dourado: "#C2941F",
        douradoSoft: "#F6ECCF",
        papel: "#FAF8F3",
        surface: "#FFFFFF",
        surface2: "#F1EFE7",
        tinta: "#1C2620",
        tintaMuda: "#5A6660",
        linha: "#E4E2D8",
        sucesso: "#2E7D46", sucessoBg: "#E6F4EA",
        atencao: "#A9750A", atencaoBg: "#FBF1D6",
        erro: "#B5462F", erroBg: "#F8E7E1",
        info: "#3E6B6E", infoBg: "#E3EFEF",
      },
      fontFamily: {
        // Urbanist serve títulos e interface; mono só pra números.
        display: ["var(--font-ui)", "system-ui", "sans-serif"],
        sans: ["var(--font-ui)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "monospace"],
      },
      boxShadow: {
        s1: "0 1px 3px rgba(30,58,43,.10)",
        s2: "0 4px 12px rgba(30,58,43,.08), 0 2px 4px rgba(30,58,43,.06)",
        s3: "0 14px 36px rgba(30,58,43,.20)",
      },
    },
  },
  plugins: [],
};
export default config;
