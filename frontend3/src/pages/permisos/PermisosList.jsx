// src/pages/permisos/PermisosList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { KeyRound, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getPermisos, createPermiso, updatePermiso, deletePermiso } from '../../api/dataService';
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
// Importa usePermissions en lugar de useAuth directamente para el chequeo de rol
import { usePermissions } from '../../hooks/usePermissions'; 

// --- Formulario --- (Sin cambios)
const PermisoForm = ({ permiso, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(permiso?.nombre || '');
    const [descripcion, setDescripcion] = useState(permiso?.descripcion || '');
    const handleSubmit = (e) => { e.preventDefault(); onSave({ nombre, descripcion }); };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre clave (ej: editar_activos)" required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent font-mono" />
            <textarea value={descripcion} onChange={(e) => setDescripcion(e.target.value)} placeholder="Descripción detallada" rows={3} required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};

// --- Componente Principal ---
export default function PermisosList() {
    const [permisos, setPermisos] = useState([]);
    const [loading, setLoading] = useState(true); 
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingPermiso, setEditingPermiso] = useState(null);
    const { showNotification } = useNotification();
    // Usa el hook de permisos para chequear el rol
    const { hasRole } = usePermissions(); 

    // Determina si el usuario puede gestionar (basado en el rol "Admin")
    const canManagePermissions = hasRole('Admin'); 

    // --- LÓGICA DE FETCH ---
    const fetchPermisos = async () => {
        setLoading(true); 
        try {
            const data = await getPermisos();
            setPermisos(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener permisos:", error); 
            showNotification('Error al cargar los permisos','error');
            setPermisos([]); 
        } finally { 
            setLoading(false); 
        }
    };

    // --- useEffect ---
    useEffect(() => { 
        fetchPermisos(); 
        // eslint-disable-next-line react-hooks/exhaustive-deps 
    }, []); 

    // --- LÓGICA DE MODAL ---
    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingPermiso(null);
    };

    // --- LÓGICA DE GUARDAR ---
    const handleSave = async (data) => {
        // Solo permite guardar si tiene el rol
        if (!canManagePermissions) {
             showNotification('No tienes permiso para realizar esta acción.', 'error');
             return;
        }
        try {
            if (editingPermiso) {
                await updatePermiso(editingPermiso.id, data);
                showNotification('Permiso actualizado con éxito');
            } else {                
                await createPermiso(data);
                showNotification('Permiso creado con éxito');
            }
            fetchPermisos(); 
            handleCloseModal(); 
        } catch (error) { 
            let errorMsg = 'Error al guardar el permiso';
             if (error.response?.data?.nombre) {
                 errorMsg = `Nombre: ${error.response.data.nombre[0]}`;
             } else if (error.response?.data?.detail) {
                 errorMsg = error.response.data.detail;
             }
            console.error("Error al guardar:", error.response?.data || error); 
            showNotification(errorMsg, 'error');
        }    
    };

    // --- LÓGICA DE ELIMINAR ---
    const handleDelete = async (id) => {
         // Solo permite eliminar si tiene el rol
        if (!canManagePermissions) {
             showNotification('No tienes permiso para realizar esta acción.', 'error');
             return;
        }
        if (window.confirm('¿Seguro que quieres eliminar este permiso global? Esto podría afectar a los roles que lo usan.')) {
            try {
                await deletePermiso(id);
                showNotification('Permiso eliminado con éxito');
                fetchPermisos(); 
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                 let errorMsg = 'Error al eliminar el permiso';
                 if (error.response?.data?.detail) {
                     errorMsg = error.response.data.detail;
                 } else if (error.response?.status === 403) {
                     errorMsg = 'No tienes permiso para eliminar esto.';
                 }
                showNotification(errorMsg,'error');
            }
        }
    };
    
    // --- Renderizado ---
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Permisos Globales</h1>
                        <p className="text-secondary">Define las acciones permitidas en el sistema.</p>
                    </div>
                    {/* Muestra botón si puede gestionar */}
                    {canManagePermissions && (
                        <button onClick={() => { setEditingPermiso(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo Permiso
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4 min-h-[200px]"> 
                    {loading ? (
                         <div className="flex justify-center items-center h-48">
                             <Loader className="animate-spin text-accent w-8 h-8" /> 
                         </div> 
                    ): permisos.length === 0 ? (
                         <p className="text-center text-tertiary py-12">No hay permisos definidos.</p> 
                    ): (
                         permisos.map((item, index) => (
                            <motion.div 
                                key={item.id} 
                                initial={{ opacity: 0, y: 10 }} 
                                animate={{ opacity: 1, y: 0 }} 
                                transition={{ delay: index * 0.05 }}
                                className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                            >
                                <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                    <KeyRound className="text-accent" />
                                </div>
                                <div className="flex-1">
                                    <p className="font-semibold text-primary font-mono">{item.nombre}</p>
                                    <p className="text-sm text-secondary">{item.descripcion}</p>
                                </div>
                                {/* Muestra botones si puede gestionar */}
                                {canManagePermissions && (
                                    <div className="flex gap-2 ml-auto"> 
                                        <button onClick={() => { setEditingPermiso(item); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                        <button onClick={() => handleDelete(item.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                    </div>
                                )}
                            </motion.div>
                         ))
                    )}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingPermiso ? "Editar Permiso" : "Nuevo Permiso"}>
                {/* Asegúrate de que el modal solo se renderice si puede gestionar, o deshabilita el form */}
                {canManagePermissions ? (
                     <PermisoForm permiso={editingPermiso} onSave={handleSave} onCancel={handleCloseModal} />
                ) : (
                    <p className="text-red-500 text-center">No tienes permiso para gestionar permisos.</p> 
                )}
            </Modal>
        </>
    );
}