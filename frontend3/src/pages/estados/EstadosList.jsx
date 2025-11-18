// src/pages/estados/EstadosList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ActivitySquare, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getEstados, createEstado, updateEstado, deleteEstado } from '../../api/dataService';
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
import { usePermissions } from '../../hooks/usePermissions'; 

// Formulario para Crear/Editar
const EstadoForm = ({ estado, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(estado?.nombre || '');
    const [detalle, setDetalle] = useState(estado?.detalle || '');
    const handleSubmit = (e) => { e.preventDefault(); onSave({ nombre, detalle }); };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre del Estado" required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <textarea value={detalle} onChange={(e) => setDetalle(e.target.value)} placeholder="Detalle (Opcional)" rows={3} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};

export default function EstadosList() {
    const [estados, setEstados] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingEstado, setEditingEstado] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); 
    const canManage = !loadingPermissions && hasPermission('manage_estadoactivo');

    const fetchEstados = async () => {
        try {
            setLoading(true);
            const data = await getEstados();
            setEstados(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener estados:", error); 
            showNotification('Error al cargar los estados','error');
        }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchEstados(); }, []);    

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingEstado(null);
    };

    const handleSave = async (data) => {
        try {
            if (editingEstado) {
                await updateEstado(editingEstado.id, data);
                showNotification('Estado actualizado con éxito');
            } else {                
                await createEstado(data);
                showNotification('Estado creado con éxito');
            }
            fetchEstados();
            handleCloseModal();
        } catch (error) { 
            console.error("Error al guardar:", error); 
            showNotification('Error al guardar el estado', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar este estado?')) {
            try {
                await deleteEstado(id);
                showNotification('Estado eliminado con éxito');
                fetchEstados();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar el estado','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Estados de Activos</h1>
                        <p className="text-secondary">Define los estados de los activos (Nuevo, Usado, etc.).</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingEstado(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo Estado
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    estados.length === 0 ? <p className="text-center text-tertiary py-12">No hay estados para mostrar.</p> :
                    estados.map((item, index) => (
                        <motion.div
                            key={item.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <ActivitySquare className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{item.nombre}</p>
                                <p className="text-sm text-secondary">{item.detalle || 'Sin detalles'}</p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingEstado(item); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(item.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingEstado ? "Editar Estado" : "Nuevo Estado"}>
                <EstadoForm estado={editingEstado} onSave={handleSave} onCancel={handleCloseModal} />
            </Modal>
        </>
    );
}