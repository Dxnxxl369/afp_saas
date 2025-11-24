import React, { useState } from 'react';
import { Outlet } from 'react-router-dom'; // Importar Outlet
import Sidebar from './Sidebar';
import Header from './Header';

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Ya no se necesitan currentPage, setCurrentPage ni renderContent

  return (
    <div className="flex h-screen bg-primary overflow-hidden"> 
      <Sidebar 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)}
        // Quitar currentPage y setCurrentPage
      />
      
      <div className="flex-1 flex flex-col overflow-hidden"> 
        <Header 
          onMenuClick={() => setSidebarOpen(!sidebarOpen)}
          sidebarOpen={sidebarOpen}
          // Quitar setCurrentPage
        />
        
        <main className="flex-1 overflow-y-auto p-4 md:p-8"> 
          <Outlet /> {/* Aquí se renderizarán las rutas anidadas */}
        </main>
      </div>

      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 md:hidden z-30"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}