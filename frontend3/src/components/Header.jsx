// src/components/Header.jsx
import React, { useState, useEffect, useCallback} from 'react';
import { Menu, X, LogOut, Bell, Check, Info, AlertTriangle, Trash2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { getNotificaciones, markNotificacionLeida, markAllNotificacionesLeidas } from '../api/dataService';
import { useNotification as useAppNotification } from '../context/NotificacionContext'; // Renombrado para evitar conflicto
import { AnimatePresence, motion } from 'framer-motion';

function NotificationBell() {
    const [isOpen, setIsOpen] = useState(false);
    const [notificaciones, setNotificaciones] = useState([]);
    const [unreadCount, setUnreadCount] = useState(0);
    const { showNotification } = useAppNotification(); // Hook de pop-up

    const fetchNotificaciones = useCallback(async () => { // <-- useCallback para memoizar
        try {
            const data = await getNotificaciones();
            const results = data.results || data || [];
            setNotificaciones(results);
            // Calcular y actualizar el contador aquí
            setUnreadCount(results.filter(n => !n.leido).length);
            console.log("Notificaciones Fetched:", results);
            console.log("Unread Count Calculated:", results.filter(n => !n.leido).length);
        } catch (error) {
            console.error("Error al cargar notificaciones:", error);
            // Resetear en caso de error podría ser útil
            setNotificaciones([]);
            setUnreadCount(0);
        }
    }, []);
    // Cargar notificaciones al montar y luego cada 1 minuto
    useEffect(() => {
        fetchNotificaciones(); // Carga inicial
        const interval = setInterval(fetchNotificaciones, 60000); // Recarga periódica
        return () => clearInterval(interval);
    }, [fetchNotificaciones]);

    const handleMarkAsRead = async (id) => {
        try {
            await markNotificacionLeida(id);
            // Actualizar estado local INMEDIATAMENTE para UI
            setNotificaciones(prev => prev.map(n => n.id === id ? { ...n, leido: true } : n));
            // Decrementar contador INMEDIATAMENTE
            setUnreadCount(prev => (prev > 0 ? prev - 1 : 0));
            // Opcional: Recargar en segundo plano para consistencia, pero sin await
            // fetchNotificaciones();
        } catch (error) {
            showNotification('Error al marcar notificación', 'error');
            // Si falla, podríamos revertir el estado o recargar
            fetchNotificaciones(); // Recargar si falla
        }
    };

    const handleMarkAllAsRead = async () => {
        try {
            await markAllNotificacionesLeidas();
            // Actualizar estado local INMEDIATAMENTE para UI
            setNotificaciones(prev => prev.map(n => ({ ...n, leido: true })));
            // Resetear contador INMEDIATAMENTE
            setUnreadCount(0);
            // Opcional: Recargar en segundo plano
            // fetchNotificaciones();
        } catch (error) {
            showNotification('Error al marcar todas', 'error');
            fetchNotificaciones(); // Recargar si falla
        }
    };
    
    const getIcon = (tipo) => {
        if (tipo === 'ADVERTENCIA') return <AlertTriangle className="text-yellow-500" size={20} />;
        if (tipo === 'ERROR') return <X className="text-red-500" size={20} />;
        return <Info className="text-blue-500" size={20} />;
    };

    //const unreadCount = notificaciones.filter(n => !n.leido).length;

    return (
        <div className="relative">
            {/* --- El Botón de la Campanita --- */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="relative p-2 hover:bg-tertiary rounded-lg transition-colors text-primary"
            >
                <Bell size={22} />
                {/* Usar el estado unreadCount */}
                {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 w-3 h-3 bg-red-500 rounded-full border-2 border-secondary" />
                )}
            </button>
            
            {/* --- El Menú Desplegable --- */}
            <AnimatePresence>
                {isOpen && (
                    <motion.div 
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -10 }}
                        className="absolute right-0 mt-2 w-80 bg-secondary border border-theme rounded-lg shadow-lg z-50 overflow-hidden"
                    >
                        <div className="p-3 flex justify-between items-center border-b border-theme">
                            <h4 className="font-semibold text-primary">Notificaciones</h4>
                            {unreadCount > 0 && (
                                <button onClick={handleMarkAllAsRead} className="text-xs text-accent font-medium hover:underline">
                                    Marcar todas como leídas
                                </button>
                            )}
                        </div>
                        
                        <div className="max-h-80 overflow-y-auto">
                            {notificaciones.length === 0 ? (
                                <p className="text-center text-secondary p-6 text-sm">No tienes notificaciones nuevas.</p>
                            ) : (
                                notificaciones.map(notif => (
                                    <div key={notif.id} className={`p-3 border-b border-theme last:border-b-0 flex gap-3 ${notif.leido ? 'opacity-60' : ''}`}>
                                        <div className="flex-shrink-0 mt-1">{getIcon(notif.tipo)}</div>
                                        <div className="flex-1">
                                            <p className="text-sm text-primary mb-1">{notif.mensaje}</p>
                                            <p className="text-xs text-tertiary">
                                                {new Date(notif.timestamp).toLocaleString()}
                                            </p>
                                        </div>
                                        {!notif.leido && (
                                            <button onClick={() => handleMarkAsRead(notif.id)} title="Marcar como leída" className="p-1 text-secondary hover:text-primary">
                                                <Check size={16} />
                                            </button>
                                        )}
                                    </div>
                                ))
                            )}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

// Función para obtener iniciales
const getInitials = (name) => {
    if (!name) return '??';
    const parts = name.split(' ');
    if (parts.length > 1) {
        return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
    return (parts[0].substring(0, 2)).toUpperCase();
};

export default function Header({ onMenuClick, sidebarOpen }) {
    const [showUserMenu, setShowUserMenu] = useState(false);
    const { user, logout } = useAuth(); // <-- 2. Obtenemos 'user' y 'logout'

    return (
        <header className="bg-secondary border-b border-theme h-16 flex items-center justify-between px-4 md:px-8">
            {/* ... (Botón de Menú) ... */}
            <button
                onClick={onMenuClick}
                className="md:hidden p-2 hover:bg-tertiary rounded-lg transition-colors text-primary"
            >
                {sidebarOpen ? <X size={24} /> : <Menu size={24} />}
            </button>

            <div className="flex-1" />

            {/* --- MENÚ DE USUARIO DINÁMICO --- */}
            <NotificationBell />
            <div className="relative">
                <button
                    onClick={() => setShowUserMenu(!showUserMenu)}
                    className="flex items-center gap-3 p-2 hover:bg-tertiary rounded-lg transition-colors"
                >
                    <div className="w-8 h-8 bg-accent rounded-full flex items-center justify-center text-white text-sm font-bold">
                        {getInitials(user?.nombre_completo)}
                    </div>
                    <span className="text-primary font-medium hidden sm:block">
                        {user?.nombre_completo || 'Cargando...'}
                    </span>
                </button>

                {/* Dropdown Menu */}
                {showUserMenu && (
                    <div 
                        className="absolute right-0 mt-2 w-56 bg-secondary border border-theme rounded-lg shadow-lg z-50"
                        onMouseLeave={() => setShowUserMenu(false)} // Opcional: cerrar al sacar el mouse
                    >
                        <div className="p-4 border-b border-theme">
                            <p className="text-primary font-medium">{user?.nombre_completo}</p>
                            <p className="text-secondary text-sm">{user?.email}</p>
                            <p className="text-xs text-accent font-semibold mt-1">{user?.empresa_nombre}</p>
                        </div>
                        <button 
                            onClick={logout}
                            className="w-full flex items-center gap-2 px-4 py-2 text-secondary hover:text-primary hover:bg-tertiary transition-colors text-left"
                        >
                            <LogOut size={18} />
                            Cerrar sesión
                        </button>
                    </div>
                )}
            </div>
            {/* --- FIN DEL MENÚ --- */}
        </header>
    );
}