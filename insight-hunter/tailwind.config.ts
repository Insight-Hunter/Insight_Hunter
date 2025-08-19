import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        orange: {
          600: "#ea580c", // Tailwind default
          700: "#c2410c"
        }
      }
    },
  },
  plugins: [],
};
export default config;
