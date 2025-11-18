// src/pages/categorias/CategoriasActivosList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { FolderTree, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getCategoriasActivos, createCategoriaActivo, updateCategoriaActivo, deleteCategoriaActivo } from '../../api/dataService';
import Modal from '../../components/Modal';
import { useNotification } from '../../context/NotificacionContext';
import { usePermissions } from '../../hooks/usePermissions'; 

// Formulario para Crear/Editar
const CategoriaForm = ({ categoria, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(categoria?.nombre || '');
    const [descripcion, setDescripcion] = useState(categoria?.descripcion || '');
    const handleSubmit = (e) => { e.preventDefault(); onSave({ nombre, descripcion }); };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre de la Categoría" required className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <textarea value={descripcion} onChange={(e) => setDescripcion(e.target.value)} placeholder="Descripción (Opcional)" rows={3} className="w-full p-3 bg-tertiary rounded-lg text-primary focus:outline-none focus:ring-2 focus:ring-accent" />
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};

export default function CategoriasActivosList() {
    const [categorias, setCategorias] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCategoria, setEditingCategoria] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); 
    const canManage = !loadingPermissions && hasPermission('manage_categoriaactivo');

    const fetchCategorias = async () => {
        try {
            setLoading(true);
            const data = await getCategoriasActivos();
            setCategorias(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener categorías:", error); 
            showNotification('Error al cargar las categorías','error');
        }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchCategorias(); }, []);    

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingCategoria(null);
    };

    const handleSave = async (data) => {
        try {
            if (editingCategoria) {
                await updateCategoriaActivo(editingCategoria.id, data);
                showNotification('Categoría actualizada con éxito');
            } else {                
                await createCategoriaActivo(data);
                showNotification('Categoría creada con éxito');
            }
            fetchCategorias();
            handleCloseModal();
        } catch (error) { 
            console.error("Error al guardar:", error); 
            showNotification('Error al guardar la categoría', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar esta categoría?')) {
            try {
                await deleteCategoriaActivo(id);
                showNotification('Categoría eliminada con éxito');
                fetchCategorias();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar la categoría','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Categorías de Activos</h1>
                        <p className="text-secondary">Organiza los tipos de activos fijos.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingCategoria(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nueva Categoría
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    categorias.length === 0 ? <p className="text-center text-tertiary py-12">No hay categorías para mostrar.</p> :
                    categorias.map((item, index) => (
                        <motion.div
                            key={item.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <FolderTree className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{item.nombre}</p>
                                <p className="text-sm text-secondary">{item.descripcion || 'Sin descripción'}</p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingCategoria(item); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(item.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingCategoria ? "Editar Categoría" : "Nueva Categoría"}>
                <CategoriaForm categoria={editingCategoria} onSave={handleSave} onCancel={handleCloseModal} />
            </Modal>
        </>
    );
}