// src/api/authService.js
import apiClient from './axiosConfig';

export const login = async (credentials) => {
    const response = await apiClient.post('/token/', credentials);
    return response;
};

//tegistrar una nueva empresa y su admin
export const register = async (data) => {
    // Usamos apiClient, pero este endpoint no requiere token
    const response = await apiClient.post('/register/', data);
    return response.data; // Devuelve { access, refresh, user }
};