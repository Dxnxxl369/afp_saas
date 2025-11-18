/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  plugins: [
    require('daisyui'),
  ],
  daisyui: {
    themes: [
      {
        light: {
          "primary": "#f9fafb",    // Fondo principal
          "secondary": "#ffffff",    // Fondo de tarjetas
          "accent": "#6366F1",      // Color de acento (botones, etc.)
          // Textos
          "text-primary": "#1f2937",
          "text-secondary": "#6b7280",
          "text-tertiary": "#9ca3af",
          // Borde
          "border-theme": "#e5e7eb",
        },
      },
      {
        dark: {
          "primary": "#111827",
          "secondary": "#1f2937",
          "accent": "#6366F1",
          // Textos
          "text-primary": "#f9fafb",
          "text-secondary": "#9ca3af",
          "text-tertiary": "#6b7280",
          // Borde
          "border-theme": "#374151",
        },
      },
      {
        custom: { // El tema personalizado se basa en el oscuro
          "primary": "#111827",
          "secondary": "#1f2937",
          "accent": "var(--color-custom)", // ¡Aquí usamos la variable CSS!
          "text-primary": "#f9fafb",
          "text-secondary": "#9ca3af",
          "text-tertiary": "#6b7280",
          "border-theme": "#374151",
        },
      },
    ],
  },
  theme: {
    extend: {
      colors: {
        // Colores dinámicos que cambiarán según el tema
        bg: {
          primary: 'var(--bg-primary)',
          secondary: 'var(--bg-secondary)',
          tertiary: 'var(--bg-tertiary)',
        },
        text: {
          primary: 'var(--text-primary)',
          secondary: 'var(--text-secondary)',
          tertiary: 'var(--text-tertiary)',
        },
        border: 'var(--border-color)',
        accent: 'var(--color-custom)',
      },
    },
  },
  plugins: [],
};