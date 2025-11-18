// src/pages/reportes/ReportesPage.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { FileText, FileDown, Loader, Filter } from 'lucide-react';
import { getUbicaciones, getReporteActivosPreview, downloadReporteActivos } from '../../api/dataService';
import { useNotification } from '../../context/NotificacionContext';

// --- Componentes de ayuda del Formulario ---
const FormInput = ({ label, ...props }) => (
    <div className="flex flex-col flex-1">
        <label className="text-sm font-medium text-secondary mb-1.5">{label}</label>
        <input {...props} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
    </div>
);
const FormSelect = ({ label, children, ...props }) => (
    <div className="flex flex-col flex-1">
        <label className="text-sm font-medium text-secondary mb-1.5">{label}</label>
        <select {...props} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent appearance-none">
            {children}
        </select>
    </div>
);
// --- Fin de Componentes de ayuda ---

export default function ReportesPage() {
    // Estados para la lógica principal
    const [loadingPreview, setLoadingPreview] = useState(false); // Para el botón de vista previa
    const [loadingExport, setLoadingExport] = useState(false); // Para los botones de exportar
    const [initialLoading, setInitialLoading] = useState(true); // Para la carga inicial de filtros

    // Estados para los filtros
    const [ubicaciones, setUbicaciones] = useState([]); // O departamentos si prefieres
    const [selectedUbicacion, setSelectedUbicacion] = useState(''); // O selectedDepto
    const [fechaMin, setFechaMin] = useState('');
    const [fechaMax, setFechaMax] = useState('');
    
    // Estado para los resultados de la vista previa
    const [resultados, setResultados] = useState(null); // Inicia como null
    
    const { showNotification } = useNotification();

    // Cargar dependencias (ubicaciones o departamentos) al montar
    useEffect(() => {
        let isMounted = true; 
        setInitialLoading(true); 

        const loadDependencies = async () => {
            try {
                // Cambia esto si prefieres filtrar por departamento
                const data = await getUbicaciones(); 
                if (isMounted) {
                    setUbicaciones(data.results || data || []);
                }
            } catch (error) {
                console.error("Error al cargar dependencias del reporte:", error);
                if (isMounted) {
                    showNotification('Error al cargar opciones de filtro', 'error');
                }
            } finally {
                if (isMounted) {
                    setInitialLoading(false); 
                }
            }
        };

        loadDependencies();

        return () => {
            isMounted = false; // Cleanup
        };
        // Dependencias: Solo se ejecuta una vez al montar
    }, [showNotification]); 

    // Función helper para construir los parámetros de la API
    const buildParams = () => {
        const params = {};
        // Cambia esto si usas departamento
        if (selectedUbicacion) params.ubicacion_id = selectedUbicacion; 
        if (fechaMin) params.fecha_min = fechaMin;
        if (fechaMax) params.fecha_max = fechaMax;
        return params;
    };

    // Handler para generar la vista previa
    const handleGenerarReporte = async () => {
        setLoadingPreview(true); // Activa el loader del botón
        setResultados(null); // Limpia resultados previos
        try {
            const params = buildParams();
            const data = await getReporteActivosPreview(params);
            setResultados(data || []); // Asegura que sea un array
            if (!data || data.length === 0) {
                showNotification('No se encontraron resultados con esos filtros');
            }
        } catch (error) {
            console.error("Error al generar reporte:", error);
            showNotification('Error al generar el reporte', 'error');
            setResultados([]); // Muestra tabla vacía en caso de error
        } finally {
            setLoadingPreview(false); // Desactiva el loader del botón
        }
    };

    // Handler para exportar (PDF o Excel)
    const handleExportar = async (format) => {
        // Solo exportar si hay resultados
        if (!resultados || resultados.length === 0) {
            showNotification('Primero genera una vista previa con resultados.', 'error');
            return;
        }
        
        setLoadingExport(true); // Activa el loader de los botones de exportar
        try {
            const params = { ...buildParams(), format };
            await downloadReporteActivos(params);
            // La notificación de éxito la maneja la función download si todo va bien
        } catch (error) {
            console.error("Error al exportar:", error);
            showNotification('Error al exportar el reporte', 'error');
        } finally {
            setLoadingExport(false); // Desactiva el loader de exportar
        }
    };

    // --- RENDERIZADO INICIAL CON LOADER ---
    // Muestra un loader mientras se cargan las ubicaciones/departamentos
    if (initialLoading) {
        return (
            <div className="flex justify-center items-center h-64">
                <Loader className="animate-spin text-accent w-10 h-10" />
            </div>
        );
    }
    // --- FIN ---

    // --- Renderizado principal de la página ---
    return (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
            {/* --- Encabezado --- */}
            <div className="mb-8">
                <h1 className="text-4xl font-bold text-primary mb-2">Reportes</h1>
                <p className="text-secondary">Genera reportes filtrados de los activos fijos.</p>
            </div>
            
            {/* --- Panel de Filtros --- */}
            <div className="bg-secondary border border-theme rounded-xl p-6 mb-8">
                <h2 className="text-xl font-semibold text-primary mb-4 flex items-center gap-2"><Filter size={20} /> Opciones de Reporte</h2>
                <div className="flex flex-col md:flex-row gap-4 mb-4">
                    {/* Cambia label y options si usas departamentos */}
                    <FormSelect label="Ubicación" value={selectedUbicacion} onChange={(e) => setSelectedUbicacion(e.target.value)}>
                        <option value="">-- Todas --</option>
                        {/* Cambia 'ubicaciones' a 'departamentos' si es necesario */}
                        {ubicaciones.map(u => <option key={u.id} value={u.id}>{u.nombre}</option>)}
                    </FormSelect>
                    <FormInput label="Fecha Adquisición (Desde)" type="date" value={fechaMin} onChange={(e) => setFechaMin(e.target.value)} max={fechaMax || undefined} /> {/* Evita fecha min > max */}
                    <FormInput label="Fecha Adquisición (Hasta)" type="date" value={fechaMax} onChange={(e) => setFechaMax(e.target.value)} min={fechaMin || undefined} /> {/* Evita fecha max < min */}
                </div>
                <button 
                    onClick={handleGenerarReporte} 
                    disabled={loadingPreview} // Usa el estado correcto
                    className="flex items-center justify-center gap-2 w-full md:w-auto bg-accent text-white font-semibold px-6 py-3 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95 disabled:opacity-50"
                >
                    {loadingPreview ? <Loader className="animate-spin" /> : <FileText size={20} />}
                    Generar Vista Previa
                </button>
            </div>

            {/* --- Panel de Resultados --- */}
            {/* Solo se muestra si 'resultados' no es null */}
            {resultados !== null && (
                <div className="bg-secondary border border-theme rounded-xl p-6 animate-in fade-in">
                    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-4">
                        <h2 className="text-xl font-semibold text-primary">Resultados ({resultados.length})</h2>
                        {/* Muestra botones solo si hay resultados */}
                        {resultados.length > 0 && (
                            <div className="flex gap-3">
                                <button onClick={() => handleExportar('pdf')} disabled={loadingExport} className="flex items-center gap-2 text-sm bg-tertiary text-primary px-4 py-2 rounded-lg hover:bg-opacity-80 disabled:opacity-50">
                                    {loadingExport ? <Loader className="animate-spin w-4 h-4" /> : <FileDown size={16} />} PDF
                                </button>
                                <button onClick={() => handleExportar('excel')} disabled={loadingExport} className="flex items-center gap-2 text-sm bg-tertiary text-primary px-4 py-2 rounded-lg hover:bg-opacity-80 disabled:opacity-50">
                                    {loadingExport ? <Loader className="animate-spin w-4 h-4" /> : <FileDown size={16} />} Excel
                                </button>
                            </div>
                        )}
                    </div>
                    
                    {/* --- Tabla de Vista Previa --- */}
                    {resultados.length > 0 ? (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left">
                                <thead className="border-b border-theme">
                                    <tr className="text-secondary text-sm">
                                        <th className="py-2 pr-4">Nombre</th>
                                        <th className="py-2 px-4">Ubicación</th> 
                                        <th className="py-2 px-4">Fecha Adq.</th>
                                        <th className="py-2 pl-4 text-right">Valor (Bs.)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {resultados.map(activo => (
                                        <tr key={activo.id} className="border-b border-theme last:border-b-0">
                                            <td className="py-3 pr-4 text-primary font-medium">{activo.nombre}</td>
                                            {/* Asegúrate que el backend envía 'ubicacion__nombre' */}
                                            <td className="py-3 px-4 text-secondary">{activo.ubicacion__nombre || 'N/A'}</td> 
                                            <td className="py-3 px-4 text-secondary">{activo.fecha_adquisicion}</td>
                                            <td className="py-3 pl-4 text-primary text-right font-mono">{parseFloat(activo.valor_actual).toFixed(2)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                     ) : (
                         // Mensaje si no hay resultados pero se generó el reporte
                         <p className="text-center text-tertiary py-8">No se encontraron activos con los filtros seleccionados.</p>
                     )}
                </div>
            )}
        </motion.div>
    );
}