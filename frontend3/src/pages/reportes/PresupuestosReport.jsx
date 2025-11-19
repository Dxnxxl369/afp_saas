// frontend3/src/pages/reportes/PresupuestosReport.jsx
import React, { useState, useEffect, useMemo } from 'react'; // Added useMemo
import { motion } from 'framer-motion';
import { FileText, Loader, Filter, X, PiggyBank, TrendingUp, TrendingDown } from 'lucide-react'; // Added icons
import { useNotification } from '../../context/NotificacionContext';
import { getReportePresupuestos } from '../../api/dataService';

// Helper para formatear moneda
const formatCurrency = (value) => {
    return parseFloat(value).toFixed(2);
};

// --- Componente de Píldora de Filtro (reutilizado) ---
const FilterTag = ({ text, onRemove }) => (
    <div className="flex items-center gap-1.5 bg-accent bg-opacity-20 text-primary font-medium px-3 py-1 rounded-full animate-in fade-in">
        <span>{text}</span>
        <button onClick={onRemove} className="p-0.5 rounded-full hover:bg-accent hover:text-white">
            <X size={14} />
        </button>
    </div>
);

export default function PresupuestosReport() {
    const [loading, setLoading] = useState(false);
    const [reportData, setReportData] = useState([]);
    const [filters, setFilters] = useState([]); // Array de filtros activos
    const [filterInput, setFilterInput] = useState(''); // Input para añadir nuevos filtros
    const [activeCategoryTab, setActiveCategoryTab] = useState('all'); // 'all', 'ahorrados', 'excedidos'
    const { showNotification } = useNotification();

    const fetchReport = async (currentFilters) => {
        setLoading(true);
        try {
            // Convertir el array de filtros a un objeto de parámetros para la API
            const params = currentFilters.reduce((acc, filterString) => {
                const [key, value] = filterString.split(':');
                if (key && value) {
                    acc[key.trim()] = value.trim();
                } else if (key) {
                    // Si es un filtro simple sin :, asumimos que es un estado
                    acc['estado'] = key.trim().toUpperCase();
                }
                return acc;
            }, {});

            const data = await getReportePresupuestos(params);
            setReportData(Array.isArray(data) ? data : []); // Ensure it's always an array
            if (!data || data.length === 0) {
                showNotification('No se encontraron períodos presupuestarios con los filtros aplicados.', 'info');
            }
        } catch (error) {
            console.error("Error fetching budget report:", error);
            showNotification(error.response?.data?.detail || 'Error al cargar el reporte de presupuestos.', 'error');
            setReportData([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReport(filters);
    }, [filters]); // Refetch cuando los filtros cambian

    const handleAddFilter = (e) => {
        e.preventDefault();
        const newFilter = filterInput.trim();
        if (newFilter && !filters.includes(newFilter)) {
            setFilters([...filters, newFilter]);
            setFilterInput('');
        }
    };

    const handleRemoveFilter = (filterToRemove) => {
        setFilters(filters.filter(f => f !== filterToRemove));
    };

    const handleClearFilters = () => {
        setFilters([]);
        setFilterInput('');
    };

    // --- NUEVA LÓGICA DE CATEGORIZACIÓN Y RESUMEN ---
    const { ahorrados, excedidos, totalAhorrado, totalExcedido } = useMemo(() => {
        const ahorradosList = reportData.filter(p => parseFloat(p.ahorro_o_sobregasto) >= 0);
        const excedidosList = reportData.filter(p => parseFloat(p.ahorro_o_sobregasto) < 0);

        const totalAhorradoCalc = ahorradosList.reduce((sum, p) => sum + parseFloat(p.ahorro_o_sobregasto), 0);
        const totalExcedidoCalc = excedidosList.reduce((sum, p) => sum + parseFloat(p.ahorro_o_sobregasto), 0);

        return {
            ahorrados: ahorradosList,
            excedidos: excedidosList,
            totalAhorrado: totalAhorradoCalc,
            totalExcedido: totalExcedidoCalc,
        };
    }, [reportData]);

    const displayedReports = useMemo(() => {
        if (activeCategoryTab === 'ahorrados') return ahorrados;
        if (activeCategoryTab === 'excedidos') return excedidos;
        return reportData; // 'all'
    }, [activeCategoryTab, reportData, ahorrados, excedidos]);

    return (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
            <div className="mb-8">
                <h1 className="text-4xl font-bold text-primary mb-2">Reporte de Presupuestos</h1>
                <p className="text-secondary">Análisis de períodos presupuestarios, gastos y ahorros.</p>
            </div>

            {/* Panel de Filtros */}
            <div className="bg-secondary border border-theme rounded-xl p-6 mb-8">
                <h2 className="text-xl font-semibold text-primary mb-4 flex items-center gap-2"><Filter size={20} /> Filtros de Presupuesto</h2>
                
                <form onSubmit={handleAddFilter} className="flex gap-2 mb-4">
                    <input 
                        type="text"
                        value={filterInput}
                        onChange={(e) => setFilterInput(e.target.value)}
                        placeholder='Añade un filtro (ej: "estado:ACTIVO", "fecha_inicio_min:2024-01-01")'
                        className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent"
                    />
                    <button type="submit" className="p-3 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">
                        Añadir
                    </button>
                </form>

                <div className="flex flex-wrap gap-2 mb-6 min-h-[38px]">
                    {filters.map((filter, index) => (
                        <FilterTag key={index} text={filter} onRemove={() => handleRemoveFilter(filter)} />
                    ))}
                    {filters.length > 0 && (
                        <button 
                            onClick={handleClearFilters} 
                            className="text-sm text-secondary hover:text-red-500 underline"
                        >
                            Limpiar todos los filtros
                        </button>
                    )}
                </div>

                <button 
                    onClick={() => fetchReport(filters)} 
                    disabled={loading}
                    className="flex items-center justify-center gap-2 w-full md:w-auto bg-accent text-white font-semibold px-6 py-3 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95 disabled:opacity-50"
                >
                    {loading ? <Loader className="animate-spin" /> : <FileText size={20} />}
                    Generar Reporte
                </button>
            </div>

            {/* --- NUEVO: Resumen y Selector de Categorías --- */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                <div className="bg-secondary border border-theme rounded-xl p-4 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-primary">
                        <PiggyBank size={24} />
                        <span className="font-semibold">Total Períodos</span>
                    </div>
                    <span className="text-2xl font-bold text-accent">{reportData.length}</span>
                </div>
                <div className="bg-secondary border border-theme rounded-xl p-4 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-green-500">
                        <TrendingUp size={24} />
                        <span className="font-semibold">Total Ahorrado</span>
                    </div>
                    <span className="text-2xl font-bold text-green-500">{formatCurrency(totalAhorrado)} Bs.</span>
                </div>
                <div className="bg-secondary border border-theme rounded-xl p-4 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-red-500">
                        <TrendingDown size={24} />
                        <span className="font-semibold">Total Excedido</span>
                    </div>
                    <span className="text-2xl font-bold text-red-500">{formatCurrency(totalExcedido)} Bs.</span>
                </div>
            </div>

            <div className="bg-secondary border border-theme rounded-xl p-2 mb-8 flex flex-wrap gap-2">
                <button
                    onClick={() => setActiveCategoryTab('all')}
                    className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                        activeCategoryTab === 'all' ? 'bg-accent text-white' : 'bg-tertiary text-primary hover:bg-opacity-80'
                    }`}
                >
                    Todos ({reportData.length})
                </button>
                <button
                    onClick={() => setActiveCategoryTab('ahorrados')}
                    className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                        activeCategoryTab === 'ahorrados' ? 'bg-green-500 text-white' : 'bg-tertiary text-primary hover:bg-opacity-80'
                    }`}
                >
                    Ahorrados ({ahorrados.length})
                </button>
                <button
                    onClick={() => setActiveCategoryTab('excedidos')}
                    className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                        activeCategoryTab === 'excedidos' ? 'bg-red-500 text-white' : 'bg-tertiary text-primary hover:bg-opacity-80'
                    }`}
                >
                    Excedidos ({excedidos.length})
                </button>
            </div>

            {/* Tabla de Resultados */}
            <div className="bg-secondary border border-theme rounded-xl p-6 animate-in fade-in">
                <h2 className="text-xl font-semibold text-primary mb-4">Resultados del Reporte ({displayedReports.length})</h2>
                {loading ? (
                    <div className="flex justify-center items-center py-8">
                        <Loader className="animate-spin text-accent" size={32} />
                    </div>
                ) : displayedReports.length > 0 ? (
                    <div className="overflow-x-auto">
                        <table className="w-full text-left">
                            <thead className="border-b border-theme">
                                <tr className="text-secondary text-sm">
                                    <th className="py-2 pr-4">Período</th>
                                    <th className="py-2 px-4">Inicio</th>
                                    <th className="py-2 px-4">Fin</th>
                                    <th className="py-2 px-4">Estado</th>
                                    <th className="py-2 px-4 text-right">Asignado (Bs.)</th>
                                    <th className="py-2 px-4 text-right">Gastado (Bs.)</th>
                                    <th className="py-2 pl-4 text-right">Ahorro/Sobregasto (Bs.)</th>
                                </tr>
                            </thead>
                            <tbody>
                                {displayedReports.map(periodo => (
                                    <tr key={periodo.id} className="border-b border-theme last:border-b-0">
                                        <td className="py-3 pr-4 text-primary font-medium">{periodo.nombre}</td>
                                        <td className="py-3 px-4 text-secondary">{periodo.fecha_inicio}</td>
                                        <td className="py-3 px-4 text-secondary">{periodo.fecha_fin}</td>
                                        <td className="py-3 px-4 text-secondary">{periodo.estado}</td>
                                        <td className="py-3 px-4 text-primary text-right font-mono">{formatCurrency(periodo.monto_total)}</td>
                                        <td className="py-3 px-4 text-primary text-right font-mono">{formatCurrency(periodo.total_gastado_periodo)}</td>
                                        <td className="py-3 pl-4 text-primary text-right font-mono" style={{ color: parseFloat(periodo.ahorro_o_sobregasto) >= 0 ? 'green' : 'red' }}>
                                            {formatCurrency(periodo.ahorro_o_sobregasto)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                ) : (
                    <p className="text-center text-tertiary py-8">No hay datos de presupuestos para mostrar.</p>
                )}
            </div>
        </motion.div>
    );
}