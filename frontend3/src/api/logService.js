// src/api/logService.js
import apiClient from './axiosConfig'; // Asegúrate que axiosConfig está bien configurado

/**
 * Envía un registro de auditoría al backend.
 * Falla silenciosamente para no interrumpir al usuario.
 * @param {string} accion - Descripción de la acción. Ej: "CREATE: Departamento"
 * @param {object | null | undefined} [payload={}] - Datos relevantes (opcional). Se asegura que sea objeto.
 */
export const logAction = async (accion, payload = {}) => {
    // Asegurarse de que el payload sea siempre un objeto, incluso si es null/undefined
    const dataToSend = {
        accion: accion,
        payload: payload || {} // Si payload es null/undefined, enviar objeto vacío
    };

    try {
        console.log("Logging action:", dataToSend); // Log para depuración frontend
        await apiClient.post('/logs/', dataToSend); // Endpoint definido en urls.py
    } catch (error) {
        // Fallamos silenciosamente para no bloquear la UI.
        // El log es importante, pero no crítico para la operación principal.
        console.warn('Fallo al registrar la acción en la bitácora:',
           error.response?.data || error.message || error);
    }
};