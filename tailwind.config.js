/** @type {import('tailwindcss').Config} */
export default {
  content: ["./tmp/**/*.html", "./templates/**/*.html"],
  theme: {
    extend: {
      fontFamily: {
        sora: ["Sora", "sans-serif"],
        fraunces: ["Fraunces", "serif"]
      },
      fontSize: {
        xxs: "0.5rem"
      }
    }
  },
  plugins: []
};
