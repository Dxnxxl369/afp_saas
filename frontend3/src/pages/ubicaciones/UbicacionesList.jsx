// src/pages/ubicaciones/UbicacionesList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { MapPin, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getUbicaciones, createUbicacion, updateUbicacion, deleteUbicacion } from '../../api/dataService'; // Asumimos que ya creaste estas funciones
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
import { usePermissions } from '../../hooks/usePermissions'; 

// --- Componentes de ayuda del Formulario ---
const FormInput = ({ label, ...props }) => (
    <div className="flex flex-col">
        <label className="text-sm font-medium text-secondary mb-1.5">{label}</label>
        <input {...props} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
    </div>
);

// --- Formulario de Ubicación ---
const UbicacionForm = ({ ubicacion, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(ubicacion?.nombre || '');
    const [direccion, setDireccion] = useState(ubicacion?.direccion || '');
    const [detalle, setDetalle] = useState(ubicacion?.detalle || '');

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ nombre, direccion, detalle });
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <FormInput label="Nombre" value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Ej: Edificio Central, Piso 3" required />
            <FormInput label="Dirección (Opcional)" value={direccion} onChange={(e) => setDireccion(e.target.value)} placeholder="Ej: Av. Principal #123" />
            <FormInput label="Detalle (Opcional)" value={detalle} onChange={(e) => setDetalle(e.target.value)} placeholder="Ej: Oficina de Contabilidad" />

            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};


// --- Componente Principal de la Lista ---
export default function UbicacionesList() {
    const [ubicaciones, setUbicaciones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingUbicacion, setEditingUbicacion] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); 
    const canManage = !loadingPermissions && hasPermission('manage_ubicacion');


    const fetchUbicaciones = async () => {
        try {
            setLoading(true);
            const data = await getUbicaciones();
            setUbicaciones(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener ubicaciones:", error); 
            showNotification('Error al cargar las ubicaciones','error');
        } finally { 
            setLoading(false); 
        }
    };

    useEffect(() => { fetchUbicaciones(); }, []);

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingUbicacion(null);
    };

    const handleSave = async (data) => {
        try {
            if (editingUbicacion) {
                await updateUbicacion(editingUbicacion.id, data);
                showNotification('Ubicación actualizada con éxito');
            } else {                
                await createUbicacion(data);
                showNotification('Ubicación creada con éxito');
            }
            fetchUbicaciones();
            handleCloseModal();
        } catch (error) { 
            console.error("Error al guardar:", error.response?.data || error); 
            showNotification('Error al guardar la ubicación', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar esta ubicación?')) {
            try {
                await deleteUbicacion(id);
                showNotification('Ubicación eliminada con éxito');
                fetchUbicaciones();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar la ubicación','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Ubicaciones</h1>
                        <p className="text-secondary">Gestiona las ubicaciones físicas de los activos.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingUbicacion(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nueva Ubicación
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    ubicaciones.length === 0 ? <p className="text-center text-tertiary py-12">No hay ubicaciones para mostrar.</p> :
                    ubicaciones.map((item, index) => (
                        <motion.div
                            key={item.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <MapPin className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{item.nombre}</p>
                                <p className="text-sm text-secondary">{item.direccion || 'Sin dirección'}</p>
                            </div>
                            <div className="flex-1">
                                <p className="text-sm text-primary">{item.detalle || 'Sin detalles'}</p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingUbicacion(item); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(item.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingUbicacion ? "Editar Ubicación" : "Nueva Ubicación"}>
                <UbicacionForm ubicacion={editingUbicacion} onSave={handleSave} onCancel={handleCloseModal} />
            </Modal>
        </>
    );
}