// src/pages/departamentos/DepartamentosList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Building2, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getDepartamentos, createDepartamento, updateDepartamento, deleteDepartamento } from '../../api/dataService';
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
import { usePermissions } from '../../hooks/usePermissions';

// Formulario para Crear/Editar
const DepartamentoForm = ({ depto, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(depto?.nombre || '');
    const [descripcion, setDescripcion] = useState(depto?.descripcion || '');
    const handleSubmit = (e) => { e.preventDefault(); onSave({ nombre, descripcion }); };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre del Departamento" required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <textarea value={descripcion} onChange={(e) => setDescripcion(e.target.value)} placeholder="Descripción (Opcional)" rows={3} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};

export default function DepartamentosList() {
    const [departamentos, setDepartamentos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingDepto, setEditingDepto] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); // <-- Use hook
    const canManage = !loadingPermissions && hasPermission('manage_departamento'); // <-- Check permission

    const fetchDepartamentos = async () => {
        try {
            setLoading(true);
            const data = await getDepartamentos();
            setDepartamentos(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener departamentos:", error); 
            showNotification('Error al cargar los datos','error');
        }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchDepartamentos(); }, []);    

    const handleSave = async (data) => {
        try {
            if (editingDepto) {
                await updateDepartamento(editingDepto.id, data);
                showNotification('Departamento actualizado con éxito');
            } else {                
                await createDepartamento(data);
                showNotification('Departamento creado con éxito');
            }
            fetchDepartamentos();
            setIsModalOpen(false);
        } catch (error) { 
            console.error("Error al guardar:", error); 
            showNotification('Error al guardar el departamento', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar este departamento?')) {
            try {
                await deleteDepartamento(id);
                showNotification('Departamento eliminado con éxito');
                fetchDepartamentos();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar el departamento','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Departamentos</h1>
                        <p className="text-secondary">Gestiona las áreas de tu empresa.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingDepto(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo
                        </button>
                    )}    
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    departamentos.length === 0 ? <p className="text-center text-tertiary py-12">No hay departamentos para mostrar.</p> :
                    departamentos.map((depto, index) => (
                        <motion.div
                            key={depto.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <Building2 className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{depto.nombre}</p>
                                <p className="text-sm text-secondary">{depto.descripcion || 'Sin descripción'}</p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingDepto(depto); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(depto.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingDepto ? "Editar Departamento" : "Nuevo Departamento"}>
                <DepartamentoForm depto={editingDepto} onSave={handleSave} onCancel={() => setIsModalOpen(false)} />
            </Modal>
        </>
    );
}