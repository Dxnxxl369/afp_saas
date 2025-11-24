// src/api/axiosConfig.js
import axios from 'axios';

const apiClient = axios.create({
    baseURL: 'http://127.0.0.1:8000/api', // Reemplaza si tu backend corre en otro puerto/IP
});

export const setAuthToken = (token) => {
    if (token) {
        // Tu backend con SimpleJWT espera 'Bearer'
        apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
        delete apiClient.defaults.headers.common['Authorization'];
    }
};

export default apiClient;