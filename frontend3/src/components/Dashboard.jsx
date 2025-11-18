/*// src/components/Dashboard.jsx
import React from 'react';
import { TrendingUp, Users, DollarSign, Activity } from 'lucide-react';

export default function Dashboard() {
  const stats = [
    {
      icon: DollarSign,
      label: 'Ingresos',
      value: '$45,231',
      change: '+12%',
      positive: true,
    },
    {
      icon: Users,
      label: 'Usuarios',
      value: '1,284',
      change: '+8%',
      positive: true,
    },
    {
      icon: Activity,
      label: 'Actividad',
      value: '642',
      change: '-3%',
      positive: false,
    },
    {
      icon: TrendingUp,
      label: 'Crecimiento',
      value: '28.5%',
      change: '+4%',
      positive: true,
    },
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-primary mb-2">Dashboard</h1>
        <p className="text-secondary">Bienvenido a tu panel de control.</p>
      </div>      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {stats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div
              key={index}
              className="bg-secondary border border-theme rounded-xl p-6 hover:shadow-lg transition-shadow"
            >
              <div className="flex items-center justify-between mb-4">
                <div className="p-3 bg-accent bg-opacity-10 rounded-lg">
                  <Icon size={24} className="text-accent" />
                </div>
                <span className={`text-sm font-medium ${stat.positive ? 'text-green-500' : 'text-red-500'}`}>
                  {stat.change}
                </span>
              </div>
              <p className="text-secondary text-sm mb-1">{stat.label}</p>
              <p className="text-primary text-2xl font-bold">{stat.value}</p>
            </div>
          );
        })}
      </div>
      
      <div className="bg-secondary border border-theme rounded-xl p-6">
        <h2 className="text-xl font-semibold text-primary mb-4">Información</h2>
        <p className="text-secondary mb-4">
          Este es un dashboard de ejemplo. Puedes cambiar el tema desde la sección de Configuración.
        </p>
        <div className="space-y-2">
          <p className="text-tertiary text-sm">✓ Tema Claro / Oscuro / Personalizado</p>
          <p className="text-tertiary text-sm">✓ Menú responsive para dispositivos móviles</p>
          <p className="text-tertiary text-sm">✓ Persistencia de preferencias con localStorage</p>
          <p className="text-tertiary text-sm">✓ Transiciones suaves entre temas</p>
        </div>
      </div>
    </div>
  );
}*/
// src/components/Dashboard.jsx
import React, { useState, useEffect } from 'react';
import { Box, DollarSign, Users, Building2, Loader } from 'lucide-react';
// Asumo que estas funciones existen en tu dataService y devuelven todos los items
import { getActivosFijos, getEmpleados, getDepartamentos } from '../api/dataService'; 
import { useNotification } from '../context/NotificacionContext';
import { useAuth } from '../context/AuthContext'; // Para personalizar el saludo

/**
 * Componente de tarjeta de estadística reutilizable.
 * Removimos la lógica de 'change' ya que ahora mostramos totales reales.
 */
function StatCard({ icon: Icon, label, value }) {
  return (
    <div className="bg-secondary border border-theme rounded-xl p-6 hover:shadow-lg transition-shadow animate-in fade-in">
      <div className="flex items-center justify-between mb-4">
        <div className="p-3 bg-accent bg-opacity-10 rounded-lg">
          <Icon size={24} className="text-accent" />
        </div>
      </div>
      <p className="text-secondary text-sm mb-1">{label}</p>
      <p className="text-primary text-2xl font-bold">{value}</p>
    </div>
  );
}

// --- Componente Principal del Dashboard ---
export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const { showNotification } = useNotification();
  const { user } = useAuth(); // Obtenemos el usuario para un saludo

  useEffect(() => {
    const fetchAllStats = async () => {
      try {
        // Hacemos todas las peticiones en paralelo para mayor eficiencia
        const [activosData, empleadosData, deparData] = await Promise.all([
          getActivosFijos(),
          getEmpleados(),
          getDepartamentos()
        ]);

        // Procesamos los datos (basado en tu DepartamentosList.jsx,
        // asumimos que la data puede ser un array o un objeto {results: [...]})
        const activos = activosData.results || activosData || [];
        const empleados = empleadosData.results || empleadosData || [];
        const departamentos = deparData.results || deparData || [];

        // Calculamos el valor total de activos
        const totalValorActivos = activos.reduce(
          (sum, activo) => sum + parseFloat(activo.valor_actual || 0),
          0
        );

        // Guardamos las estadísticas calculadas en el estado
        setStats({
          totalActivos: activos.length,
          valorActivos: totalValorActivos,
          totalEmpleados: empleados.length,
          totalDepartamentos: departamentos.length,
        });

      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
        showNotification('Error al cargar las estadísticas del dashboard', 'error');
        setStats({ error: true }); // Marcamos un estado de error
      } finally {
        setLoading(false);
      }
    };

    fetchAllStats();
  }, [showNotification]); // El effect se ejecuta solo una vez

  
  // --- Lógica de Renderizado ---

  // 1. Muestra un 'loader' mientras se cargan los datos
  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Loader className="animate-spin text-accent w-10 h-10" />
      </div>
    );
  }

  // 2. Muestra un error si la carga falló
  if (!stats || stats.error) {
    return (
      <div className="text-center text-red-500">
        <h1 className="text-2xl font-bold">Error al cargar el Dashboard</h1>
        <p>No se pudieron obtener las estadísticas. Inténtalo de nuevo más tarde.</p>
      </div>
    );
  }
  
  // 3. Si todo es exitoso, formatea y muestra los datos
  const formattedStats = [
    {
      icon: Box, // Icono para Activos
      label: 'Total de Activos Fijos',
      value: stats.totalActivos,
    },
    {
      icon: DollarSign,
      label: 'Valor Total de Activos (Bs.)',
      // Formatea el número como moneda
      value: stats.valorActivos.toLocaleString('es-BO', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }),
    },
    {
      icon: Users,
      label: 'Total de Empleados',
      value: stats.totalEmpleados,
    },
    {
      icon: Building2, // Icono para Departamentos (del Sidebar)
      label: 'Total de Departamentos',
      value: stats.totalDepartamentos,
    },
  ];

  return (
    <div>
      {/* --- Encabezado Personalizado --- */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-primary mb-2">
          ¡Hola, {user?.username || 'usuario'}!
        </h1>
        <p className="text-secondary">Bienvenido a tu panel de control.</p>
      </div>

      {/* --- Grid de Estadísticas Reales --- */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {formattedStats.map((stat) => (
          <StatCard
            key={stat.label}
            icon={stat.icon}
            label={stat.label}
            value={stat.value}
          />
        ))}
      </div>

      {/* --- Tarjeta de Información (la mantenemos) --- */}
      <div className="bg-secondary border border-theme rounded-xl p-6">
        <h2 className="text-xl font-semibold text-primary mb-4">Información del Sistema</h2>
        <p className="text-secondary mb-4">
          Este es tu panel principal. Puedes cambiar el tema desde la sección de Configuración.
        </p>
        <div className="space-y-2">
          <p className="text-tertiary text-sm">✓ Tema Claro / Oscuro / Personalizado</p>
          <p className="text-tertiary text-sm">✓ Menú responsive para dispositivos móviles</p>
          <p className="text-tertiary text-sm">✓ Persistencia de preferencias con localStorage</p>
        </div>
      </div>
    </div>
  );
}