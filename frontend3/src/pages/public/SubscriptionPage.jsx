// src/pages/public/SubscriptionPage.jsx
import React from 'react';
import { Link } from 'react-router-dom';
import { CheckCircle, ArrowRight } from 'lucide-react';

const plans = [
    {
        name: 'Básico',
        price: '10',
        features: ['Hasta 5 usuarios', 'Hasta 50 activos', 'Todos los módulos', 'Soporte por email'],
        borderColor: 'border-cyan-500',
        shadowColor: 'shadow-cyan-500/50',
        buttonClass: 'bg-cyan-500 hover:bg-cyan-600',
    },
    {
        name: 'Profesional',
        price: '25',
        features: ['Hasta 20 usuarios', 'Hasta 200 activos', 'Reportes personalizables', 'Soporte prioritario'],
        borderColor: 'border-indigo-500',
        shadowColor: 'shadow-indigo-500/50',
        buttonClass: 'bg-indigo-500 hover:bg-indigo-600',
        isPopular: true,
    },
    {
        name: 'Empresarial',
        price: '50',
        features: ['Usuarios ilimitados', 'Activos ilimitados', 'Reportes avanzados + API', 'Soporte 24/7 dedicado'],
        borderColor: 'border-purple-500',
        shadowColor: 'shadow-purple-500/50',
        buttonClass: 'bg-purple-500 hover:bg-purple-600',
    }
];

export default function SubscriptionPage() {
    return (
        <div className="min-h-screen bg-gray-900 text-white flex flex-col items-center justify-center p-8">
            <div className="text-center mb-12">
                <h1 className="text-5xl font-bold mb-4">Elige el Plan Perfecto para tu Empresa</h1>
                <p className="text-gray-400 max-w-2xl mx-auto">
                    Escala con nosotros. Todas las herramientas que necesitas para una gestión de activos fijos impecable, sin importar el tamaño de tu negocio.
                </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-6xl">
                {plans.map((plan) => (
                    <div 
                        key={plan.name}
                        className={`relative bg-gray-800 border-2 ${plan.borderColor} rounded-2xl p-8 flex flex-col transition-all duration-300 hover:scale-105 hover:shadow-2xl ${plan.shadowColor}`}
                    >
                        {plan.isPopular && (
                            <div className="absolute top-0 -translate-y-1/2 left-1/2 -translate-x-1/2 bg-indigo-500 text-white text-sm font-bold px-4 py-1 rounded-full">
                                MÁS POPULAR
                            </div>
                        )}
                        <h2 className="text-3xl font-bold mb-2">{plan.name}</h2>
                        <p className="text-5xl font-extrabold mb-4">${plan.price}<span className="text-lg font-medium text-gray-400">/mes</span></p>
                        
                        <ul className="space-y-4 mb-8 flex-grow">
                            {plan.features.map((feature) => (
                                <li key={feature} className="flex items-center gap-3">
                                    <CheckCircle className="text-green-400 w-5 h-5 flex-shrink-0" />
                                    <span>{feature}</span>
                                </li>
                            ))}
                        </ul>

                        <Link 
                            to={`/payment?plan=${plan.name.toLowerCase()}`}
                            className={`w-full text-center font-bold py-3 px-6 rounded-lg text-white transition-transform duration-200 active:scale-95 ${plan.buttonClass}`}
                        >
                            Suscribirse <ArrowRight className="inline ml-2 w-5 h-5" />
                        </Link>
                    </div>
                ))}
            </div>
             <div className="mt-12 text-center">
                <p className="text-gray-400">¿Ya tienes una cuenta?</p>
                <Link to="/login" className="font-medium text-indigo-400 hover:text-indigo-300">
                    Inicia Sesión aquí
                </Link>
            </div>
        </div>
    );
}