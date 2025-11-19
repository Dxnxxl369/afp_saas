// src/components/Sidebar.jsx
import React, { useState, useEffect } from 'react'; // Added useState, useEffect
import { 
    LayoutGrid, Users, Building2, Settings, FolderTree, ActivitySquare, 
    Briefcase, Box, FileText, ShieldCheck, PiggyBank, Truck, MapPin, KeyRound, Wrench, TrendingUp, TrendingDown,
    ClipboardList, ShoppingCart, CreditCard, ChevronUp, ChevronDown, Trash2 // Added ChevronUp, ChevronDown, Trash2
} from 'lucide-react';
import { usePermissions } from '../hooks/usePermissions';
import { useAuth } from '../context/AuthContext';

// New CollapsibleNavItem component
function CollapsibleNavItem({ icon, label, children, currentPage, handleNavigation }) {
    const [isOpen, setIsOpen] = useState(false); // State to manage collapse

    // Determine if any child is active to keep parent open
    const hasActiveChild = React.Children.toArray(children).some(child => 
        child && child.props && child.props.isActive
    );

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
                <div className="pl-4 space-y-1"> {/* Adjusted padding for nested items */}
                    {children}
                </div>
            )}
        </div>
    );
}

export default function Sidebar({ isOpen, onClose, currentPage, setCurrentPage }) {
  const { canAccess } = usePermissions();
  const { userIsAdmin } = useAuth();

  const handleNavigation = (page) => {
    setCurrentPage(page);
    onClose(); // Cierra el sidebar móvil al navegar
  };

  // Helper para renderizar solo si hay acceso
  const renderNavItem = (moduleName, icon, label, isChild = false) => {
    if (canAccess(moduleName)) {
      return (
        <NavItem
          icon={icon}
          label={label}
          isActive={currentPage === moduleName}
          onClick={() => handleNavigation(moduleName)}
          isChild={isChild} // Add isChild prop for styling if needed
        />
      );
    }
    return null;
  };

  const navigationContent = (
    <>
      {renderNavItem('dashboard', <LayoutGrid size={20} />, "Dashboard")}
      {renderNavItem('suscripcion', <CreditCard size={20} />, "Suscripción")}
      {renderNavItem('empleados', <Users size={20} />, "Empleados")}
      {renderNavItem('cargos', <Briefcase size={20} />, "Cargos")}
      {renderNavItem('departamentos', <Building2 size={20} />, "Departamentos")}
      
      {/* --- Activos Category --- */}
      <CollapsibleNavItem 
          icon={<Box size={20} />} 
          label="Activos" 
          currentPage={currentPage} 
          handleNavigation={handleNavigation}
      >
          {renderNavItem('activos_fijos', <Box size={20} />, "Activos Fijos", true)}
          
          {/* --- Adquisicion Sub-Category --- */}
          <CollapsibleNavItem 
              icon={<ShoppingCart size={20} />} 
              label="Adquisición" 
              currentPage={currentPage} 
              handleNavigation={handleNavigation}
          >
              {renderNavItem('solicitudes_compra', <ClipboardList size={20} />, "Solicitudes de Compra", true)}
              {renderNavItem('ordenes_compra', <ShoppingCart size={20} />, "Órdenes de Compra", true)}
          </CollapsibleNavItem>

          {renderNavItem('revalorizaciones', <TrendingUp size={20} />, "Revalorización", true)}
          {renderNavItem('depreciaciones', <TrendingDown size={20} />, "Depreciación", true)}
          {renderNavItem('disposiciones', <Trash2 size={20} />, "Disposición", true)} {/* NEW */}
          {renderNavItem('mantenimientos', <Wrench size={20} />, "Mantenimientos", true)}
      </CollapsibleNavItem>

      {renderNavItem('presupuestos', <PiggyBank size={20} />, "Presupuestos")}
      {renderNavItem('estados', <ActivitySquare size={20} />, "Estados")}
      {renderNavItem('ubicaciones', <MapPin size={20} />, "Ubicaciones")}
      {renderNavItem('proveedores', <Truck size={20} />, "Proveedores")}
      {renderNavItem('categorias', <FolderTree size={20} />, "Categorías")}      
      {renderNavItem('roles', <ShieldCheck size={20} />, "Roles")}
      {renderNavItem('permisos', <KeyRound size={20} />, "Permisos")}
      {renderNavItem('reportes', <FileText size={20} />, "Reportes")}
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
            icon={<Settings size={20} />}
            label="Configuración"
            isActive={currentPage === 'settings'}
            onClick={() => handleNavigation('settings')}
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
            icon={<Settings size={20} />}
            label="Configuración"
            isActive={currentPage === 'settings'}
            onClick={() => handleNavigation('settings')}
          />
        </div>
      </aside>
    </>
  );
}

function NavItem({ icon, label, isActive, onClick, isChild = false }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 text-left ${
        isActive
          ? 'bg-accent text-white font-medium'
          : 'text-primary hover:bg-tertiary'
      } ${isChild ? 'text-sm' : ''}`} // Smaller font for children
    >
      {icon}
      {label}
    </button>
  );
}
