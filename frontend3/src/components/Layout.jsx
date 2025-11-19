import React, { useState } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';
import DashboardPage from '../pages/dashboard/DashboardPage';
import Settings from './Settings';
import DepartamentosList from '../pages/departamentos/DepartamentosList';
import ActivosFijosList from '../pages/activos/ActivosFijosList';
import CargosList from '../pages/cargos/CargosList';
import EmpleadosList from '../pages/empleados/EmpleadosList';
import RolesList from '../pages/roles/RolesList';
import PeriodosPresupuestariosList from '../pages/presupuesto/PeriodosPresupuestariosList';
import PartidasPresupuestariasList from '../pages/presupuesto/PartidasPresupuestariasList';
import UbicacionesList from '../pages/ubicaciones/UbicacionesList';
import ProveedoresList from '../pages/proveedores/ProveedoresList';
import CategoriasActivosList from '../pages/categorias/CategoriasActivosList';
import EstadosList from '../pages/estados/EstadosList';
import ReportesPage from '../pages/reportes/ReportesPage';
import PermisosList from '../pages/permisos/PermisosList';
import MantenimientoList from '../pages/mantenimiento/MantenimientoList';
import RevalorizacionPage from '../pages/revalorizacion/RevalorizacionPage';
import DepreciacionPage from '../pages/depreciacion/DepreciacionPage';
import SolicitudesCompraList from '../pages/solicitudes_compra/SolicitudesCompraList';
import OrdenesCompraList from '../pages/ordenes_compra/OrdenesCompraList';
import SuscripcionPage from '../pages/suscripcion/SuscripcionPage';
import DisposicionList from '../pages/disposicion/DisposicionList'; // NEW IMPORT

export default function Layout() {
  const [currentPage, _setCurrentPage] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [viewingPeriodo, setViewingPeriodo] = useState(null); // Nuevo estado para el detalle

  // Wrapper para resetear la vista de detalle al cambiar de módulo
  const setCurrentPage = (page) => {
    _setCurrentPage(page);
    setViewingPeriodo(null); // Resetea la vista de detalle
  };

  const renderContent = () => {
    if (currentPage === 'presupuestos') {
      if (viewingPeriodo) {
        return <PartidasPresupuestariasList periodo={viewingPeriodo} onBack={() => setViewingPeriodo(null)} />;
      }
      return <PeriodosPresupuestariosList onSelectPeriodo={(periodo) => setViewingPeriodo(periodo)} />;
    }

    // El resto de las páginas
    const pages = {
      dashboard: <DashboardPage />,
      departamentos: <DepartamentosList />,
      activos_fijos: <ActivosFijosList />,
      mantenimientos: <MantenimientoList />,
      revalorizaciones: <RevalorizacionPage />,
      depreciaciones: <DepreciacionPage />,
      disposiciones: <DisposicionList />, // NEW PAGE
      solicitudes_compra: <SolicitudesCompraList />,
      ordenes_compra: <OrdenesCompraList />,
      cargos: <CargosList />,
      empleados: <EmpleadosList />,
      roles: <RolesList />,
      ubicaciones: <UbicacionesList />,
      proveedores: <ProveedoresList />,
      categorias: <CategoriasActivosList />,
      estados: <EstadosList />,
      reportes: <ReportesPage />,
      permisos: <PermisosList />,
      suscripcion: <SuscripcionPage />,
      settings: <Settings />,
    };
    return pages[currentPage] || <DashboardPage />;
  };
  
  return (
    // Main container takes full height and prevents outer scroll
    <div className="flex h-screen bg-primary overflow-hidden"> 
      {/* Sidebar component */}
      <Sidebar 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)}
        currentPage={currentPage}
        setCurrentPage={setCurrentPage}
      />
      
      {/* Main content area */}
      <div className="flex-1 flex flex-col overflow-hidden"> 
        {/* Header (should NOT scroll) */}
        <Header 
          onMenuClick={() => setSidebarOpen(!sidebarOpen)}
          sidebarOpen={sidebarOpen}
        />
        
        {/* Main content (THIS part should scroll independently) */}
        <main className="flex-1 overflow-y-auto p-4 md:p-8"> 
          {renderContent()}
        </main>
      </div>

      {/* Mobile overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 md:hidden z-30"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}