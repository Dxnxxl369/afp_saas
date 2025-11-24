// src/pages/cargos/CargosList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Briefcase, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getCargos, createCargo, updateCargo, deleteCargo } from '../../api/dataService';
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
import { usePermissions } from '../../hooks/usePermissions';

// Formulario para Crear/Editar
const CargoForm = ({ cargo, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(cargo?.nombre || '');
    const [descripcion, setDescripcion] = useState(cargo?.descripcion || '');
    const handleSubmit = (e) => { e.preventDefault(); onSave({ nombre, descripcion }); };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre del Cargo" required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <textarea value={descripcion} onChange={(e) => setDescripcion(e.target.value)} placeholder="Descripción (Opcional)" rows={3} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};

export default function CargosList() {
    const [cargos, setCargos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCargo, setEditingCargo] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); // <-- Use hook
    const canManage = !loadingPermissions && hasPermission('manage_cargo'); // <-- Check permission

    const fetchCargos = async () => {
        try {
            setLoading(true);
            const data = await getCargos();
            setCargos(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener cargos:", error); 
            showNotification('Error al cargar los cargos','error');
        }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchCargos(); }, []);    

    const handleSave = async (data) => {
        try {
            if (editingCargo) {
                await updateCargo(editingCargo.id, data);
                showNotification('Cargo actualizado con éxito');
            } else {                
                await createCargo(data);
                showNotification('Cargo creado con éxito');
            }
            fetchCargos();
            setIsModalOpen(false);
        } catch (error) { 
            console.error("Error al guardar:", error); 
            showNotification('Error al guardar el cargo', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar este cargo?')) {
            try {
                await deleteCargo(id);
                showNotification('Cargo eliminado con éxito');
                fetchCargos();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar el cargo','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Cargos</h1>
                        <p className="text-secondary">Gestiona los puestos de trabajo de la empresa.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingCargo(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    cargos.length === 0 ? <p className="text-center text-tertiary py-12">No hay cargos para mostrar.</p> :
                    cargos.map((cargo, index) => (
                        <motion.div
                            key={cargo.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <Briefcase className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{cargo.nombre}</p>
                                <p className="text-sm text-secondary">{cargo.descripcion || 'Sin descripción'}</p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingCargo(cargo); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(cargo.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingCargo ? "Editar Cargo" : "Nuevo Cargo"}>
                <CargoForm cargo={editingCargo} onSave={handleSave} onCancel={() => setIsModalOpen(false)} />
            </Modal>
        </>
    );
}