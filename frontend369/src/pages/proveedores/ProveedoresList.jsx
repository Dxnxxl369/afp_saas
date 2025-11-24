// src/pages/proveedores/ProveedoresList.jsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Truck, Plus, Edit, Trash2, Loader } from 'lucide-react';
import { getProveedores, createProveedor, updateProveedor, deleteProveedor } from '../../api/dataService'; // Asumimos que ya creaste estas funciones
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

// --- Formulario de Proveedor ---
const ProveedorForm = ({ proveedor, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        nombre: proveedor?.nombre || '',
        nit: proveedor?.nit || '',
        email: proveedor?.email || '',
        telefono: proveedor?.telefono || '',
        pais: proveedor?.pais || '',
        direccion: proveedor?.direccion || '',
        estado: proveedor?.estado || 'activo',
    });

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave(formData);
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-2">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormInput label="Nombre del Proveedor" name="nombre" value={formData.nombre} onChange={handleChange} required />
                <FormInput label="NIT" name="nit" value={formData.nit} onChange={handleChange} required />
                <FormInput label="Email (Opcional)" name="email" type="email" value={formData.email} onChange={handleChange} />
                <FormInput label="Teléfono (Opcional)" name="telefono" value={formData.telefono} onChange={handleChange} />
                <FormInput label="País (Opcional)" name="pais" value={formData.pais} onChange={handleChange} />
                <FormInput label="Dirección (Opcional)" name="direccion" value={formData.direccion} onChange={handleChange} />
            </div>
            
            <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};


// --- Componente Principal de la Lista ---
export default function ProveedoresList() {
    const [proveedores, setProveedores] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingProveedor, setEditingProveedor] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); 
    const canManage = !loadingPermissions && hasPermission('manage_proveedor');


    const fetchProveedores = async () => {
        try {
            setLoading(true);
            const data = await getProveedores();
            setProveedores(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener proveedores:", error); 
            showNotification('Error al cargar los proveedores','error');
        } finally { 
            setLoading(false); 
        }
    };

    useEffect(() => { fetchProveedores(); }, []);

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingProveedor(null);
    };

    const handleSave = async (data) => {
        try {
            if (editingProveedor) {
                await updateProveedor(editingProveedor.id, data);
                showNotification('Proveedor actualizado con éxito');
            } else {                
                await createProveedor(data);
                showNotification('Proveedor creado con éxito');
            }
            fetchProveedores();
            handleCloseModal();
        } catch (error) { 
            console.error("Error al guardar:", error.response?.data || error); 
            showNotification('Error al guardar el proveedor', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar este proveedor?')) {
            try {
                await deleteProveedor(id);
                showNotification('Proveedor eliminado con éxito');
                fetchProveedores();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar el proveedor','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Proveedores</h1>
                        <p className="text-secondary">Gestiona los proveedores de activos y servicios.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingProveedor(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo Proveedor
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    proveedores.length === 0 ? <p className="text-center text-tertiary py-12">No hay proveedores para mostrar.</p> :
                    proveedores.map((item, index) => (
                        <motion.div
                            key={item.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <Truck className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{item.nombre}</p>
                                <p className="text-sm text-secondary">NIT: {item.nit}</p>
                            </div>
                            <div className="flex-1">
                                <p className="text-sm text-primary">{item.email || 'Sin email'}</p>
                                <p className="text-sm text-secondary">{item.telefono || 'Sin teléfono'}</p>
                            </div>
                            <div className="flex-1">
                                <p className="text-sm text-primary">{item.pais || 'Sin país'}</p>
                                <p className="text-sm text-secondary">{item.direccion || 'Sin dirección'}</p>
                            </div>
                            {canManage && (    
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingProveedor(item); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(item.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingProveedor ? "Editar Proveedor" : "Nuevo Proveedor"}>
                <ProveedorForm proveedor={editingProveedor} onSave={handleSave} onCancel={handleCloseModal} />
            </Modal>
        </>
    );
}