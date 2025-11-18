/*// src/components/Sidebar.jsx
import React from 'react';
// Asegúrate de importar TODOS los iconos que usas
import { 
    LayoutGrid, Users, Building2, Settings, FolderTree, ActivitySquare, 
    Briefcase, Box, FileText, ShieldCheck, PiggyBank, Truck, MapPin, KeyRound 
} from 'lucide-react';
import { usePermissions } from '../hooks/usePermissions';
import { useAuth } from '../context/AuthContext'; // <-- Importa useAuth

export default function Sidebar({ isOpen, onClose, currentPage, setCurrentPage }) {
  const { canAccess } = usePermissions();
  const { userIsAdmin } = useAuth(); // <-- Obtén si es SuperAdmin

  const handleNavigation = (page) => {
    setCurrentPage(page);
    onClose(); // Cierra el sidebar móvil al navegar
  };

  // Helper para renderizar solo si hay acceso
  const renderNavItemIfAllowed = (moduleName, icon, label) => {
    // Caso especial para 'Permisos': solo el SuperAdmin
    

    if (canAccess(moduleName)) {
      return (
        <NavItem
          icon={icon}
          label={label}
          isActive={currentPage === moduleName}
          onClick={() => handleNavigation(moduleName)}
        />
      );
    }
    return null;
  };

  // Creamos el contenido de la navegación una sola vez
  const navigationContent = (
    <>
      {renderNavItemIfAllowed('dashboard', <LayoutGrid size={20} />, "Dashboard")}
      {renderNavItemIfAllowed('activos_fijos', <Box size={20} />, "Activos Fijos")}
      {renderNavItemIfAllowed('departamentos', <Building2 size={20} />, "Departamentos")}
      {renderNavItemIfAllowed('cargos', <Briefcase size={20} />, "Cargos")}
      {renderNavItemIfAllowed('empleados', <Users size={20} />, "Empleados")}
      {renderNavItemIfAllowed('roles', <ShieldCheck size={20} />, "Roles")}
      {renderNavItemIfAllowed('presupuestos', <PiggyBank size={20} />, "Presupuestos")}
      {renderNavItemIfAllowed('ubicaciones', <MapPin size={20} />, "Ubicaciones")}
      {renderNavItemIfAllowed('proveedores', <Truck size={20} />, "Proveedores")}
      {renderNavItemIfAllowed('categorias', <FolderTree size={20} />, "Categorías")}
      {renderNavItemIfAllowed('estados', <ActivitySquare size={20} />, "Estados")}
      {renderNavItemIfAllowed('reportes', <FileText size={20} />, "Reportes")}
      {renderNavItemIfAllowed('permisos', <KeyRound size={20} />, "Permisos")} 
    </>
  );

  return (
    <>      
      <aside className="hidden md:flex w-64 bg-secondary border-r border-theme flex-col">
        <div className="h-16 flex items-center justify-center border-b border-theme">
          <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
        </div>
        <nav className="flex-1 px-4 py-6 space-y-2">
          {navigationContent} 
        </nav>
        <div className="px-4 py-4 border-t border-theme">          
          <NavItem
            icon={<Settings size={20} />}
            label="Configuración"
            isActive={currentPage === 'settings'}
            onClick={() => handleNavigation('settings')}
          />
        </div>
      </aside>      
      <aside
        className={`fixed left-0 top-0 w-64 h-screen bg-secondary border-r border-theme flex flex-col z-40 transform transition-transform duration-300 md:hidden ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="h-16 flex items-center justify-center border-b border-theme">
          <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
        </div>
        <nav className="flex-1 px-4 py-6 space-y-2">
          {navigationContent} 
        </nav>
        <div className="px-4 py-4 border-t border-theme">
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

// El componente NavItem no necesita cambios
function NavItem({ icon, label, isActive, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 text-left ${
        isActive
          ? 'bg-accent text-white font-medium'
          : 'text-primary hover:bg-tertiary'
      }`}
    >
      {icon}
      {label}
    </button>
  );
}*/

// src/components/Sidebar.jsx
// ... (imports)
import React from 'react';
// Asegúrate de importar TODOS los iconos que usas
import { 
    LayoutGrid, Users, Building2, Settings, FolderTree, ActivitySquare, 
    Briefcase, Box, FileText, ShieldCheck, PiggyBank, Truck, MapPin, KeyRound, Wrench, TrendingUp, TrendingDown,
    ClipboardList, ShoppingCart
} from 'lucide-react';
import { usePermissions } from '../hooks/usePermissions';
import { useAuth } from '../context/AuthContext'; // <-- Importa useAuth

export default function Sidebar({ isOpen, onClose, currentPage, setCurrentPage }) {
  const { canAccess } = usePermissions();
  const { userIsAdmin } = useAuth(); // <-- Obtén si es SuperAdmin

  const handleNavigation = (page) => {
    setCurrentPage(page);
    onClose(); // Cierra el sidebar móvil al navegar
  };

  // Helper para renderizar solo si hay acceso
  const renderNavItemIfAllowed = (moduleName, icon, label) => {
    // Caso especial para 'Permisos': solo el SuperAdmin
    

    if (canAccess(moduleName)) {
      return (
        <NavItem
          icon={icon}
          label={label}
          isActive={currentPage === moduleName}
          onClick={() => handleNavigation(moduleName)}
        />
      );
    }
    return null;
  };

  const navigationContent = (
    <>
      {renderNavItemIfAllowed('dashboard', <LayoutGrid size={20} />, "Dashboard")}
      {renderNavItemIfAllowed('empleados', <Users size={20} />, "Empleados")}
      {renderNavItemIfAllowed('cargos', <Briefcase size={20} />, "Cargos")}
      {renderNavItemIfAllowed('departamentos', <Building2 size={20} />, "Departamentos")}

      {renderNavItemIfAllowed('solicitudes_compra', <ClipboardList size={20} />, "Solicitudes de Compra")}
      {renderNavItemIfAllowed('ordenes_compra', <ShoppingCart size={20} />, "Órdenes de Compra")}
      {renderNavItemIfAllowed('activos_fijos', <Box size={20} />, "Activos Fijos")}
      {renderNavItemIfAllowed('revalorizaciones', <TrendingUp size={20} />, "Revalorización")}
      {renderNavItemIfAllowed('depreciaciones', <TrendingDown size={20} />, "Depreciación")}
      {renderNavItemIfAllowed('mantenimientos', <Wrench size={20} />, "Mantenimientos")}
      {renderNavItemIfAllowed('presupuestos', <PiggyBank size={20} />, "Presupuestos")}
      {renderNavItemIfAllowed('estados', <ActivitySquare size={20} />, "Estados")}
      {renderNavItemIfAllowed('ubicaciones', <MapPin size={20} />, "Ubicaciones")}
      {renderNavItemIfAllowed('proveedores', <Truck size={20} />, "Proveedores")}
      {renderNavItemIfAllowed('categorias', <FolderTree size={20} />, "Categorías")}      
      
      
      {renderNavItemIfAllowed('roles', <ShieldCheck size={20} />, "Roles")}
      {renderNavItemIfAllowed('permisos', <KeyRound size={20} />, "Permisos")}
      {renderNavItemIfAllowed('reportes', <FileText size={20} />, "Reportes")}
    </>
  );

  return (
    <>
      {/* --- Desktop Sidebar --- */}
      {/* The main aside container uses flex-col */}
      <aside className="hidden md:flex w-64 bg-secondary border-r border-theme flex-col h-full"> {/* Added h-full */}
        {/* Header part (Fixed top) */}
        <div className="h-16 flex items-center justify-center border-b border-theme flex-shrink-0"> {/* Added flex-shrink-0 */}
          <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
        </div>
        
        {/* Navigation part (SCROLLABLE) */}
        <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto"> {/* Added overflow-y-auto */}
          {navigationContent} 
        </nav>
        
        {/* Footer part (Fixed bottom) */}
        <div className="px-4 py-4 border-t border-theme flex-shrink-0"> {/* Added flex-shrink-0 */}
          {/* Settings NavItem */}
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
        {/* Mobile Header (Fixed top) */}
        <div className="h-16 flex items-center justify-center border-b border-theme flex-shrink-0">
          <h1 className="text-2xl font-bold text-primary">ActFijo App</h1>
        </div>
        
        {/* Mobile Navigation (SCROLLABLE) */}
        <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto"> {/* Added overflow-y-auto */}
          {navigationContent}
        </nav>
        
        {/* Mobile Footer (Fixed bottom) */}
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

function NavItem({ icon, label, isActive, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 text-left ${
        isActive
          ? 'bg-accent text-white font-medium'
          : 'text-primary hover:bg-tertiary'
      }`}
    >
      {icon}
      {label}
    </button>
  );
}