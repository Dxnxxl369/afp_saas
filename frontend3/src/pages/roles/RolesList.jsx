// src/pages/roles/RolesList.jsx
import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import { ShieldCheck, Plus, Edit, Trash2, Loader, ChevronLeft, ChevronRight } from 'lucide-react';
import { getRoles, createRol, updateRol, deleteRol, getPermisos } from '../../api/dataService';
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

const PermissionList = ({ title, permissions, onSelect, selectedPermission }) => (
    <div className="flex-1 border border-theme rounded-lg h-64 overflow-y-auto">
        <h3 className="text-sm font-semibold text-primary p-3 border-b border-theme sticky top-0 bg-secondary">{title}</h3>
        <ul className="p-1">
            {permissions.map(p => (
                <li 
                    key={p.id}
                    onClick={() => onSelect(p)}
                    // Añade title para el tooltip de descripción
                    title={p.descripcion} 
                    className={`p-2 rounded cursor-pointer text-sm hover:bg-tertiary ${selectedPermission?.id === p.id ? 'bg-accent text-white' : 'text-secondary'}`}
                >
                    {p.nombre}
                </li>
            ))}
            {permissions.length === 0 && <li className="p-2 text-xs text-tertiary text-center">Vacío</li>}
        </ul>
    </div>
);

// --- Formulario de Rol ---
const RolForm = ({ rol, onSave, onCancel }) => {
    const [nombre, setNombre] = useState(rol?.nombre || '');
    // Guardamos los IDs de los permisos asignados
    const [assignedPermissionIds, setAssignedPermissionIds] = useState(
        // CORRECCIÓN: Extrae los IDs correctamente al editar
        () => rol?.permisos?.map(p => typeof p === 'object' ? p.id : p) || [] 
    );
    
    const [allPermissions, setAllPermissions] = useState([]);
    const [loadingDeps, setLoadingDeps] = useState(true);
    const { showNotification } = useNotification();
    
    // Estados para la UI de dos listas
    const [selectedAvailable, setSelectedAvailable] = useState(null);
    const [selectedAssigned, setSelectedAssigned] = useState(null);

    // Cargar todos los permisos disponibles
    useEffect(() => {
    const loadPermisos = async () => {
        try {
            setLoadingDeps(true);
            const data = await getPermisos();
            // Check what 'data' looks like HERE
            console.log("Permisos fetched:", data); 
            setAllPermissions(data.results || data || []);
        } catch (error) {
            // Log the specific error
            console.error("Error DETALLADO al cargar permisos:", error.response?.data || error.message || error); 
            showNotification('Error al cargar la lista de permisos', 'error');
            setAllPermissions([]); // Ensure it's an empty array on error
        } finally {
            setLoadingDeps(false); // Make sure this always runs
            console.log("setLoadingDeps set to false"); // Add log here
        }
    };
    loadPermisos();
}, [showNotification]);

    // Calcular listas de disponibles y asignados (usando useMemo para eficiencia)
    const { availablePermissions, assignedPermissions } = useMemo(() => {
        const assigned = allPermissions.filter(p => assignedPermissionIds.includes(p.id));
        const available = allPermissions.filter(p => !assignedPermissionIds.includes(p.id));
        return { availablePermissions: available, assignedPermissions: assigned };
    }, [allPermissions, assignedPermissionIds]);

    // Handlers para seleccionar en las listas
    const handleSelectAvailable = (permiso) => {
        setSelectedAvailable(permiso);
        setSelectedAssigned(null); // Deselecciona en la otra lista
    };
    const handleSelectAssigned = (permiso) => {
        setSelectedAssigned(permiso);
        setSelectedAvailable(null); // Deselecciona en la otra lista
    };

    // Handlers para mover permisos entre listas
    const handleAddPermission = () => {
        if (selectedAvailable) {
            setAssignedPermissionIds(prev => [...prev, selectedAvailable.id]);
            setSelectedAvailable(null);
        }
    };
    const handleRemovePermission = () => {
        if (selectedAssigned) {
            setAssignedPermissionIds(prev => prev.filter(id => id !== selectedAssigned.id));
            setSelectedAssigned(null);
        }
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ nombre, permisos: assignedPermissionIds }); // Envía solo los IDs
    };

    if (loadingDeps) {

        return <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div>;

    }

    // --- RENDERIZADO DEL FORMULARIO CON DOS LISTAS ---
    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <FormInput label="Nombre del Rol" value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Ej: Administrador" required />
            
            <div className="flex flex-col space-y-2">
                 <label className="text-sm font-medium text-secondary">Asignar Permisos</label>
                 <div className="flex items-center gap-2">
                    {/* Lista de Permisos Disponibles */}
                    <PermissionList 
                        title="Disponibles"
                        permissions={availablePermissions}
                        onSelect={handleSelectAvailable}
                        selectedPermission={selectedAvailable}
                    />
                    
                    {/* Botones para Mover */}
                    <div className="flex flex-col gap-2">
                        <button 
                            type="button" 
                            onClick={handleAddPermission} 
                            disabled={!selectedAvailable}
                            className="p-2 bg-tertiary rounded hover:bg-accent disabled:opacity-50 disabled:cursor-not-allowed"
                            title="Añadir permiso seleccionado"
                        >
                            <ChevronRight size={20} className="text-primary"/>
                        </button>
                        <button 
                            type="button" 
                            onClick={handleRemovePermission} 
                            disabled={!selectedAssigned}
                            className="p-2 bg-tertiary rounded hover:bg-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
                            title="Quitar permiso seleccionado"
                        >
                            <ChevronLeft size={20} className="text-primary"/>
                        </button>
                    </div>

                    {/* Lista de Permisos Asignados */}
                     <PermissionList 
                        title="Asignados"
                        permissions={assignedPermissions}
                        onSelect={handleSelectAssigned}
                        selectedPermission={selectedAssigned}
                    />
                 </div>
                 <p className="text-xs text-tertiary">Haz clic en un permiso para seleccionarlo, luego usa los botones para moverlo. Pasa el cursor sobre un permiso para ver su descripción.</p>
            </div>

            {/* Botones Guardar/Cancelar */}
            <div className="flex justify-end gap-3 pt-4 border-t border-theme">
                <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-primary hover:bg-tertiary">Cancelar</button>
                <button type="submit" className="px-4 py-2 bg-accent text-white font-semibold rounded-lg hover:bg-opacity-90">Guardar</button>
            </div>
        </form>
    );
};


// --- Componente Principal de la Lista ---
export default function RolesList() {
    const [roles, setRoles] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingRol, setEditingRol] = useState(null);
    const { showNotification } = useNotification();
    const { hasPermission, loadingPermissions } = usePermissions(); 
    const canManage = !loadingPermissions && hasPermission('manage_rol');

    const fetchRoles = async () => {
        try {
            setLoading(true);
            const data = await getRoles();
            setRoles(data.results || data || []);
        } catch (error) { 
            console.error("Error al obtener roles:", error); 
            showNotification('Error al cargar los roles','error');
        } finally { 
            setLoading(false); 
        }
    };

    useEffect(() => { fetchRoles(); }, []);

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setEditingRol(null);
    };

    const handleSave = async (data) => {
        try {
            if (editingRol) {
                await updateRol(editingRol.id, data);
                showNotification('Rol actualizado con éxito');
            } else {                
                await createRol(data);
                showNotification('Rol creado con éxito');
            }
            fetchRoles();
            handleCloseModal();
        } catch (error) { 
            console.error("Error al guardar:", error.response?.data || error); 
            showNotification('Error al guardar el rol', 'error');
        }    
    };

    const handleDelete = async (id) => {
        if (window.confirm('¿Seguro que quieres eliminar este rol?')) {
            try {
                await deleteRol(id);
                showNotification('Rol eliminado con éxito');
                fetchRoles();
            } catch (error) { 
                console.error("Error al eliminar:", error); 
                showNotification('Error al eliminar el rol','error');
            }
        }
    };
    
    return (
        <>            
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                <div className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-primary mb-2">Roles</h1>
                        <p className="text-secondary">Gestiona los roles y permisos de los usuarios.</p>
                    </div>
                    {canManage && (
                        <button onClick={() => { setEditingRol(null); setIsModalOpen(true); }} className="flex items-center gap-2 bg-accent text-white font-semibold px-4 py-2 rounded-lg hover:bg-opacity-90 transition-transform active:scale-95">
                            <Plus size={20} /> Nuevo Rol
                        </button>
                    )}
                </div>
                
                <div className="bg-secondary border border-theme rounded-xl p-4">
                    {loading ? <div className="flex justify-center items-center h-48"><Loader className="animate-spin text-accent" /></div> :
                    roles.length === 0 ? <p className="text-center text-tertiary py-12">No hay roles para mostrar.</p> :
                    roles.map((rol, index) => (
                        <motion.div
                            key={rol.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            className="flex items-center p-3 border-b border-theme last:border-b-0 hover:bg-tertiary rounded-lg"
                        >
                            <div className="p-3 bg-accent bg-opacity-10 rounded-lg mr-4">
                                <ShieldCheck className="text-accent" />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-primary">{rol.nombre}</p>
                                <p className="text-sm text-secondary">
                                    {rol.permisos.length} {rol.permisos.length === 1 ? 'permiso' : 'permisos'}
                                </p>
                            </div>
                            {canManage && (
                                <div className="flex gap-2">
                                    <button onClick={() => { setEditingRol(rol); setIsModalOpen(true); }} className="p-2 text-primary hover:text-accent"><Edit size={18} /></button>
                                    <button onClick={() => handleDelete(rol.id)} className="p-2 text-primary hover:text-red-500"><Trash2 size={18} /></button>
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </motion.div>

            <Modal isOpen={isModalOpen} onClose={handleCloseModal} title={editingRol ? "Editar Rol" : "Nuevo Rol"}>
                <RolForm rol={editingRol} onSave={handleSave} onCancel={handleCloseModal} />
            </Modal>
        </>
    );
}