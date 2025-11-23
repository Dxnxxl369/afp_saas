// src/components/Sidebar.jsx
import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom'; // Importar NavLink y useLocation
import { 
    LayoutGrid, Users, Building2, Settings, FolderTree, ActivitySquare, 
    Briefcase, Box, FileText, ShieldCheck, PiggyBank, Truck, MapPin, KeyRound, Wrench, TrendingUp, TrendingDown,
    ClipboardList, ShoppingCart, CreditCard, ChevronUp, ChevronDown, Trash2
} from 'lucide-react';
import { usePermissions } from '../hooks/usePermissions';

// --- Componente de enlace de navegación ---
function NavItem({ to, icon, label, isChild = false, onClick }) {
    const baseClasses = "w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 text-left";
    const childClasses = isChild ? 'text-sm' : '';

    return (
        <NavLink
            to={to}
            onClick={onClick}
            className={({ isActive }) => 
                `${baseClasses} ${childClasses} ${
                    isActive
                    ? 'bg-accent text-white font-medium'
                    : 'text-primary hover:bg-tertiary'
                }`
            }
        >
            {icon}
            {label}
        </NavLink>
    );
}

// --- Componente de enlace colapsable ---
function CollapsibleNavItem({ icon, label, children }) {
    const location = useLocation();
    const [isOpen, setIsOpen] = useState(false);

    const childPaths = React.Children.toArray(children)
        .filter(c => c && c.props.to)
        .map(c => c.props.to);
        
    const hasActiveChild = childPaths.some(path => location.pathname.startsWith(path));

    useEffect(() => {
        if (hasActiveChild) {
            setIsOpen(true);
        }
    }, [hasActiveChild]);

    return (
        <div className="space-y-1">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className={`w-full flex items-center justify-between gap-3 px-4 py-3 rounded-lg transition-all duration-200 text-left ${
                    isOpen || hasActiveChild ? 'bg-tertiary text-primary font-medium' : 'text-primary hover:bg-tertiary'
                }`}
            >
                <span className="flex items-center gap-3">
                    {icon}
                    {label}
                </span>
                {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </button>
            {isOpen && (
                <div className="pl-4 space-y-1">
                    {children}
                </div>
            )}
        </div>
    );
}

export default function Sidebar({ isOpen, onClose }) {
    const { canAccess } = usePermissions();

    // El onClick para cerrar el sidebar en móvil
    const handleMobileNav = () => {
        if (isOpen) {
            onClose();
        }
    };

    const renderNavItem = (moduleName, path, icon, label, isChild = false) => {
        if (canAccess(moduleName)) {
            return (
                <NavItem
                    to={`/app/${path}`}
                    icon={icon}
                    label={label}
                    isChild={isChild}
                    onClick={handleMobileNav}
                />
            );
        }
        return null;
    };
    
    // Contenido de navegación con rutas correctas
    const navigationContent = (
        <>
            {renderNavItem('dashboard', 'dashboard', <LayoutGrid size={20} />, "Dashboard")}
            {renderNavItem('suscripcion', 'suscripcion', <CreditCard size={20} />, "Suscripción")}
            {renderNavItem('empleados', 'empleados', <Users size={20} />, "Empleados")}
            {renderNavItem('cargos', 'cargos', <Briefcase size={20} />, "Cargos")}
            {renderNavItem('departamentos', 'departamentos', <Building2 size={20} />, "Departamentos")}
            
            <CollapsibleNavItem icon={<Box size={20} />} label="Activos">
                {renderNavItem('activos_fijos', 'activos-fijos', <Box size={20} />, "Activos Fijos", true)}
                
                <CollapsibleNavItem icon={<ShoppingCart size={20} />} label="Adquisición">
                    {renderNavItem('solicitudes_compra', 'solicitudes-compra', <ClipboardList size={20} />, "Solicitudes", true)}
                    {renderNavItem('ordenes_compra', 'ordenes-compra', <ShoppingCart size={20} />, "Órdenes", true)}
                </CollapsibleNavItem>

                {renderNavItem('revalorizaciones', 'revalorizaciones', <TrendingUp size={20} />, "Revalorización", true)}
                {renderNavItem('depreciaciones', 'depreciaciones', <TrendingDown size={20} />, "Depreciación", true)}
                {renderNavItem('disposiciones', 'disposiciones', <Trash2 size={20} />, "Disposición", true)}
                {renderNavItem('mantenimientos', 'mantenimientos', <Wrench size={20} />, "Mantenimientos", true)}
            </CollapsibleNavItem>

            {renderNavItem('presupuestos', 'presupuestos', <PiggyBank size={20} />, "Presupuestos")}
            {renderNavItem('estados', 'estados', <ActivitySquare size={20} />, "Estados")}
            {renderNavItem('ubicaciones', 'ubicaciones', <MapPin size={20} />, "Ubicaciones")}
            {renderNavItem('proveedores', 'proveedores', <Truck size={20} />, "Proveedores")}
            {renderNavItem('categorias', 'categorias', <FolderTree size={20} />, "Categorías")}      
            {renderNavItem('roles', 'roles', <ShieldCheck size={20} />, "Roles")}
            {renderNavItem('permisos', 'permisos', <KeyRound size={20} />, "Permisos")}
            {renderNavItem('reportes', 'reportes', <FileText size={20} />, "Reportes")}
        </>
    );

    return (
        <>
            {/* --- Desktop Sidebar --- */}
            <aside className="hidden md:flex w-64 bg-secondary border-r border-theme flex-col h-full">
                <div className="h-16 flex items-center justify-center border-b border-theme flex-shrink-0">
                    <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
                </div>
                <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
                    {navigationContent}
                </nav>
                <div className="px-4 py-4 border-t border-theme flex-shrink-0">
                    <NavItem
                        to="/app/settings"
                        icon={<Settings size={20} />}
                        label="Configuración"
                        onClick={handleMobileNav}
                    />
                </div>
            </aside>

            {/* --- Mobile Sidebar --- */}
            <aside
                className={`fixed left-0 top-0 w-64 h-screen bg-secondary border-r border-theme flex flex-col z-40 transform transition-transform duration-300 md:hidden ${
                isOpen ? 'translate-x-0' : '-translate-x-full'
                }`}
            >
                <div className="h-16 flex items-center justify-center border-b border-theme flex-shrink-0">
                    <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
                </div>
                <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
                    {navigationContent}
                </nav>
                <div className="px-4 py-4 border-t border-theme flex-shrink-0">
                    <NavItem
                        to="/app/settings"
                        icon={<Settings size={20} />}
                        label="Configuración"
                        onClick={handleMobileNav}
                    />
                </div>
            </aside>
        </>
    );
}

