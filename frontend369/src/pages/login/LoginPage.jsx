// src/pages/login/LoginPage.jsx
import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom'; // <-- 1. Importar useNavigate y Link
import { useAuth } from '../../context/AuthContext';
import { LogIn, Loader } from 'lucide-react';

export default function LoginPage() {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(false);
    
    const { login } = useAuth();
    const navigate = useNavigate(); // <-- 2. Inicializar el hook

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            // 3. Llamar a la función de login (que ya funcionaba)
            await login(username, password);
            
            // 4. --- ¡LA SOLUCIÓN! ---
            // Redirigir al dashboard principal después del login exitoso
            navigate('/app'); 

        } catch (err) {
            console.error("Error de login:", err);
            setError('Usuario o contraseña incorrectos. Por favor, intente de nuevo.');
            setLoading(false);
        }
        // No ponemos setLoading(false) aquí, porque la navegación desmontará el componente
    };

    return (
        // Usamos el diseño oscuro de las páginas públicas
        <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center p-4">
            <div className="w-full max-w-md bg-gray-800 border border-theme rounded-2xl p-8 shadow-2xl shadow-indigo-500/30">
                <div className="text-center mb-8">
                    <LogIn className="mx-auto w-12 h-12 text-indigo-400 mb-4" />
                    <h1 className="text-3xl font-bold">Iniciar Sesión</h1>
                    <p className="text-gray-400">Accede a tu panel de control</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label htmlFor="username" className="block text-sm font-medium text-gray-300 mb-1">Username</label>
                        <input 
                            type="text" 
                            id="username"
                            value={username} 
                            onChange={(e) => setUsername(e.target.value)} 
                            required 
                            className="w-full bg-gray-700 border-gray-600 rounded-lg p-3 focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                            autoComplete="username"
                        />
                    </div>
                    <div>
                        <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-1">Password</label>
                        <input 
                            type="password" 
                            id="password"
                            value={password} 
                            onChange={(e) => setPassword(e.target.value)} 
                            required 
                            className="w-full bg-gray-700 border-gray-600 rounded-lg p-3 focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                            autoComplete="current-password"
                        />
                    </div>

                    {error && (
                        <p className="text-red-400 text-sm text-center">{error}</p>
                    )}

                    <button 
                        type="submit" 
                        disabled={loading} 
                        className="w-full flex justify-center items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 rounded-lg transition-transform active:scale-95 disabled:opacity-50"
                    >
                        {loading ? <Loader className="animate-spin" /> : 'Entrar'}
                    </button>
                </form>
                
                <div className="mt-6 text-center">
                    <p className="text-gray-400 text-sm">¿No tienes una cuenta?</p>
                    <Link to="/subscribe" className="font-medium text-indigo-400 hover:text-indigo-300 text-sm">
                        Suscríbete aquí
                    </Link>
                </div>
            </div>
        </div>
    );
}