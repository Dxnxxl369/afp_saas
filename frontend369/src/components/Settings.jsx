// src/components/Settings.jsx
import React, { useState } from 'react';
import { useTheme } from '../context/ThemeContext';
import { Palette, Sparkles } from 'lucide-react';

function Toggle({ label, enabled, onChange }) {
  return (
    <label 
      onClick={onChange} // <--- ¡AQUÍ ESTÁ LA CORRECCIÓN!
      className="flex items-center justify-between cursor-pointer"
    >
      <span className="text-primary font-medium">{label}</span>
      <div
        className={`relative w-14 h-8 rounded-full p-1 transition-colors ${
          enabled ? 'bg-accent' : 'bg-tertiary'
        }`}
      >
        <div
          className={`absolute left-1 top-1 w-6 h-6 bg-white rounded-full transition-transform ${
            enabled ? 'translate-x-6' : 'translate-x-0'
          }`}
        />
      </div>
    </label>
  );
}

export default function Settings() {
  const { theme, setTheme, customColor, setCustomColor, glowEnabled, setGlowEnabled } = useTheme();
  const [colorInput, setColorInput] = useState(customColor);

  const handleColorChange = (e) => {
    const color = e.target.value;
    setColorInput(color);
    setCustomColor(color);
  };

  const predefinedColors = [
    '#6366F1', // Indigo
    '#8B5CF6', // Violet
    '#D946EF', // Fuchsia
    '#EC4899', // Pink
    '#F43F5E', // Rose
    '#F97316', // Orange
    '#EAB308', // Yellow
    '#22C55E', // Green
    '#10B981', // Emerald
    '#06B6D4', // Cyan
    '#0EA5E9', // Sky
    '#3B82F6', // Blue
  ];

  return (
    <div className="max-w-2xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-primary mb-2">Personalizar Apariencia</h1>
        <p className="text-secondary">Elige tu tema preferido y personaliza los colores.</p>
      </div>

      {/* Theme Selector */}
      <div className="bg-secondary border border-theme rounded-xl p-6 mb-6">
        <h2 className="text-xl font-semibold text-primary mb-4">Modo de Tema</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <ThemeButton
            label="Claro"
            value="light"
            isActive={theme === 'light'}
            onClick={() => setTheme('light')}
          />
          <ThemeButton
            label="Oscuro"
            value="dark"
            isActive={theme === 'dark'}
            onClick={() => setTheme('dark')}
          />
          <ThemeButton
            label="Personalizado"
            value="custom"
            isActive={theme === 'custom'}
            onClick={() => setTheme('custom')}
          />
        </div>
      </div>
      <div className="bg-secondary border border-theme rounded-xl p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
            <Sparkles size={24} className="text-accent" />
            <h2 className="text-xl font-semibold text-primary">Efectos Visuales</h2>
        </div>
        <Toggle 
          label="Activar brillo de neón"
          enabled={glowEnabled}
          onChange={() => setGlowEnabled(!glowEnabled)}
        />
        <p className="text-sm text-tertiary mt-2">
          Añade un sutil efecto de brillo a los botones y bordes de color.
        </p>
      </div>
      {/* Color Customization (shown when custom theme is selected) */}
      {theme === 'custom' && (
        <div className="bg-secondary border border-theme rounded-xl p-6 mb-6 animate-in fade-in">
          <div className="flex items-center gap-2 mb-4">
            <Palette size={24} className="text-accent" />
            <h2 className="text-xl font-semibold text-primary">Elige tu Color Primario</h2>
          </div>
          <p className="text-secondary mb-6">El color se aplica en tiempo real a toda la interfaz.</p>

          <div className="space-y-6">
            {/* Color Input */}
            <div className="flex items-center gap-4">
              <input
                type="color"
                value={colorInput}
                onChange={handleColorChange}
                className="w-16 h-16 rounded-lg cursor-pointer border-2 border-theme"
              />
              <div>
                <p className="text-primary font-medium">Color seleccionado</p>
                <p className="text-secondary font-mono text-sm">{colorInput}</p>
              </div>
            </div>

            {/* Predefined Colors */}
            <div>
              <p className="text-primary font-medium mb-3">Colores sugeridos</p>
              <div className="grid grid-cols-4 sm:grid-cols-6 gap-3">
                {predefinedColors.map((color) => (
                  <button
                    key={color}
                    onClick={() => {
                      setColorInput(color);
                      setCustomColor(color);
                    }}
                    className={`w-12 h-12 rounded-lg border-2 transition-all ${
                      colorInput === color
                        ? 'border-theme scale-110 shadow-lg'
                        : 'border-transparent hover:scale-105'
                    }`}
                    style={{ backgroundColor: color }}
                    title={color}
                  />
                ))}
              </div>
            </div>

            {/* Preview */}
            <div className="space-y-3 pt-4 border-t border-theme">
              <p className="text-primary font-medium">Vista previa</p>
              <div
                className="w-full h-20 rounded-lg border-2 border-theme transition-colors duration-300"
                style={{ backgroundColor: colorInput }}
              />
              <button
                className="w-full py-2 px-4 rounded-lg font-medium text-white transition-colors duration-300"
                style={{ backgroundColor: colorInput }}
              >
                Botón de ejemplo
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Current Theme Info */}
      <div className="bg-accent bg-opacity-10 border border-accent rounded-xl p-4">
        <p className="text-primary">
          <span className="font-semibold">Tema actual:</span> {' '}
          <span className="capitalize text-accent font-medium">
            {theme === 'custom' ? `Personalizado (${colorInput})` : theme}
          </span>
        </p>
      </div>
    </div>
  );
}

function ThemeButton({ label, value, isActive, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`px-4 py-3 rounded-lg font-medium transition-all duration-200 ${
        isActive
          ? 'bg-accent text-white shadow-lg scale-105'
          : 'bg-tertiary text-primary hover:bg-opacity-80'
      }`}
    >
      {label}
    </button>
  );
}