// src/pages/suscripcion/SuscripcionPage.jsx
import React, { useState, useEffect } from 'react';
import apiClient from '../../api/axiosConfig';
import { useAuth } from '../../context/AuthContext';
import { Loader, AlertCircle, CheckCircle, ArrowUp, Star, Shield } from 'lucide-react';

// Helper para mostrar el nombre del plan bonito
const planDetails = {
    basico: { name: 'Básico', icon: <Shield size={24} className="text-cyan-400" /> },
    profesional: { name: 'Profesional', icon: <Star size={24} className="text-indigo-400" /> },
    empresarial: { name: 'Empresarial', icon: <CheckCircle size={24} className="text-purple-400" /> }
};

const availableUpgrades = {
    basico: ['profesional', 'empresarial'],
    profesional: ['empresarial'],
    empresarial: []
};

const ProgressBar = ({ value, max, label }) => {
    const percentage = max > 0 ? (value / max) * 100 : 0;
    let colorClass = 'bg-green-500';
    if (percentage > 90) {
        colorClass = 'bg-red-500';
    } else if (percentage > 70) {
        colorClass = 'bg-yellow-500';
    }

    return (
        <div>
            <div className="flex justify-between items-center mb-1">
                <span className="text-sm font-medium text-gray-300">{label}</span>
                <span className="text-sm font-bold text-white">{value} / {max < 9999 ? max : 'Ilimitado'}</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-2.5">
                <div className={`h-2.5 rounded-full ${colorClass}`} style={{ width: `${Math.min(percentage, 100)}%` }}></div>
            </div>
        </div>
    );
};

export default function SuscripcionPage() {
    const [suscripcion, setSuscripcion] = useState(null);
    const [dashboardData, setDashboardData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [upgradeLoading, setUpgradeLoading] = useState(false);
    const { authData } = useAuth();

    const fetchData = async () => {
        setLoading(true);
        setError(null);
        try {
            // El endpoint de suscripciones devuelve una lista, tomamos el primer elemento
            const suscripcionRes = await apiClient.get('/suscripciones/');
            if (suscripcionRes.data && suscripcionRes.data.length > 0) {
                setSuscripcion(suscripcionRes.data[0]);
            } else {
                throw new Error('No se encontró información de la suscripción.');
            }

            const dashboardRes = await apiClient.get('/dashboard/');
            setDashboardData(dashboardRes.data);

        } catch (err) {
            console.error("Error fetching data:", err);
            setError('No se pudo cargar la información de la suscripción. Intente de nuevo más tarde.');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleUpgrade = async (newPlan) => {
        if (!suscripcion) return;
        setUpgradeLoading(true);
        setError(null);
        try {
            const response = await apiClient.post(`/suscripciones/${suscripcion.id}/upgrade-plan/`, { plan: newPlan });
            setSuscripcion(response.data); // Actualizar el estado con la nueva suscripción
            // Opcional: mostrar un mensaje de éxito
        } catch (err) {
            console.error("Error upgrading plan:", err.response?.data || err.message);
            setError(err.response?.data?.detail || 'Ocurrió un error al intentar mejorar el plan.');
        } finally {
            setUpgradeLoading(false);
        }
    };

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader className="animate-spin text-white" size={48} /></div>;
    }

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center h-full text-red-400">
                <AlertCircle size={48} className="mb-4" />
                <p>{error}</p>
            </div>
        );
    }

    if (!suscripcion || !dashboardData) {
        return <div className="text-center text-gray-400">No hay datos de suscripción disponibles.</div>;
    }

    const currentPlan = suscripcion.plan;
    const upgrades = availableUpgrades[currentPlan] || [];

    return (
        <div className="p-8 text-white">
            <h1 className="text-4xl font-bold mb-8">Gestión de Suscripción</h1>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Columna del Plan Actual */}
                <div className="lg:col-span-1 bg-gray-800 border border-indigo-500 rounded-2xl p-6 shadow-lg shadow-indigo-500/20">
                    <div className="flex items-center gap-4 mb-4">
                        {planDetails[currentPlan]?.icon}
                        <h2 className="text-2xl font-bold">Tu Plan Actual: {planDetails[currentPlan]?.name}</h2>
                    </div>
                    <p className="text-gray-400 mb-6">Aquí está un resumen del uso actual de tu empresa.</p>
                    <div className="space-y-6">
                        <ProgressBar label="Usuarios" value={dashboardData.total_usuarios} max={suscripcion.max_usuarios} />
                        <ProgressBar label="Activos Fijos" value={dashboardData.total_activos} max={suscripcion.max_activos} />
                    </div>
                </div>

                {/* Columna de Mejora de Plan */}
                <div className="lg:col-span-2 bg-gray-800 border border-gray-700 rounded-2xl p-6">
                    <h2 className="text-2xl font-bold mb-4">Mejora tu Plan</h2>
                    {upgrades.length > 0 ? (
                        <div className="space-y-4">
                            {upgrades.map(planKey => (
                                <div key={planKey} className="flex justify-between items-center bg-gray-700 p-4 rounded-lg">
                                    <div className="flex items-center gap-3">
                                        {planDetails[planKey]?.icon}
                                        <span className="font-semibold text-lg">{planDetails[planKey]?.name}</span>
                                    </div>
                                    <button
                                        onClick={() => handleUpgrade(planKey)}
                                        disabled={upgradeLoading}
                                        className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-lg transition-transform active:scale-95 disabled:opacity-50 flex items-center gap-2"
                                    >
                                        {upgradeLoading ? <Loader className="animate-spin" size={20} /> : <><ArrowUp size={16} /> Mejorar</>}
                                    </button>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="flex flex-col items-center justify-center h-full text-center">
                            <CheckCircle size={40} className="text-green-400 mb-4" />
                            <p className="text-xl font-semibold">¡Felicidades!</p>
                            <p className="text-gray-400">Ya te encuentras en nuestro plan más alto.</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
