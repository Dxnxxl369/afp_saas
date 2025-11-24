// src/context/ThemeContext.jsx
import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
// Importamos updateUserTheme de AuthContext
import { useAuth } from './AuthContext';
import { updateMyThemePreferences } from '../api/dataService';

const ThemeContext = createContext();

export const ThemeProvider = ({ children }) => {
    // Obtenemos updateUserTheme junto con user y authLoading
    const { user, loading: authLoading, updateUserTheme } = useAuth(); // <-- Obtener updateUserTheme

    const [theme, setThemeState] = useState('dark');
    const [customColor, setCustomColorState] = useState('#6366F1');
    const [glowEnabled, setGlowEnabledState] = useState(false);
    const [themeLoaded, setThemeLoaded] = useState(false);

    // --- Efecto para cargar/resetear preferencias (Sin cambios) ---
    useEffect(() => {
        // ... (lógica existente para cargar desde 'user' o resetear) ...
        console.log("ThemeContext Effect: authLoading=", authLoading, "user=", user);
        if (authLoading) {
            console.log("ThemeContext: Waiting for auth context...");
            setThemeLoaded(false);
            return;
        }
        if (user) {
            console.log("ThemeContext: User found, loading preferences:", user);
            setThemeState(user.theme_preference || 'dark');
            setCustomColorState(user.theme_custom_color || '#6366F1');
            setGlowEnabledState(user.theme_glow_enabled || false);
        } else {
            console.log("ThemeContext: No user, resetting to defaults.");
            setThemeState('dark');
            setCustomColorState('#6366F1');
            setGlowEnabledState(false);
        }
        setThemeLoaded(true);
    }, [user, authLoading]);

    // --- Función Debounced para guardar en el backend ---
    const savePreferencesToServer = useCallback(debounce(async (prefsToSave) => {
        if (!user) {
             console.log("ThemeContext: Skipping save (no user).");
             return;
        }
        try {
            console.log("ThemeContext: Saving preferences to server (debounced):", prefsToSave);
            // Llamamos a la API para guardar en la BD
            const response = await updateMyThemePreferences(prefsToSave);
            console.log("ThemeContext: Preferences saved successfully. API Response:", response);

            // --- [NUEVO] Actualizar AuthContext ---
            // Si la API tuvo éxito, llamamos a updateUserTheme
            // con los datos actualizados que devolvió la API (response)
            // o con los datos que intentamos guardar (prefsToSave)
            updateUserTheme(response || prefsToSave);
            // --- [FIN DE NUEVO CÓDIGO] ---

        } catch (error) {
            const errorData = error.response?.data;
            const errorStatus = error.response?.status;
            console.error(`ThemeContext: Error saving theme preferences (Status: ${errorStatus}):`, errorData || error.message);
        }
    // Añadimos updateUserTheme a las dependencias de useCallback
    }, 1000), [user, updateUserTheme]); // <-- Depende de user y updateUserTheme

    // --- Efecto para aplicar el tema al DOM (Sin cambios) ---
    useEffect(() => {
        // ... (lógica existente para aplicar al DOM) ...
        if (!themeLoaded) return;
        console.log(`ThemeContext: Applying DOM theme - Theme: ${theme}, Color: ${customColor}, Glow: ${glowEnabled}`);
        const root = document.documentElement;
        root.setAttribute('data-theme', theme);
        root.setAttribute('data-glow', String(glowEnabled));
        if (theme === 'custom') {
            root.style.setProperty('--color-custom', customColor);
        } else {
            root.style.removeProperty('--color-custom');
        }
    }, [theme, customColor, glowEnabled, themeLoaded]);

    // --- Funciones 'set' (Sin cambios, siguen llamando a savePreferencesToServer) ---
    const setTheme = (newTheme) => {
        console.log("ThemeContext: setTheme called with:", newTheme);
        setThemeState(newTheme);
        savePreferencesToServer({ theme_preference: newTheme });
    };
    const setCustomColor = (newColor) => {
        console.log("ThemeContext: setCustomColor called with:", newColor);
        setCustomColorState(newColor);
        savePreferencesToServer({ theme_custom_color: newColor });
    };
    const setGlowEnabled = (isEnabled) => {
        console.log("ThemeContext: setGlowEnabled called with:", isEnabled);
        setGlowEnabledState(isEnabled);
        savePreferencesToServer({ theme_glow_enabled: isEnabled });
    };

    // --- Renderizado Condicional (Sin cambios) ---
    if (!themeLoaded) {
         console.log("ThemeContext: Theme not loaded yet, rendering null.");
        return null;
    }

    // --- Provider (Sin cambios) ---
    console.log("ThemeContext: Rendering provider.");
    return (
        <ThemeContext.Provider value={{ theme, setTheme, customColor, setCustomColor, glowEnabled, setGlowEnabled }}>
            {children}
        </ThemeContext.Provider>
    );
};

export const useTheme = () => {
    const context = useContext(ThemeContext);
    if (!context) {
        throw new Error('useTheme debe usarse dentro de ThemeProvider');
    }
    return context;
};

// --- Helper Debounce ---
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}