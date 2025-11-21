# management/commands/create_permissions.py
from django.core.management.base import BaseCommand
from django.db import transaction
from api.models import Permisos

# --- [EDITADO] LISTA DE PERMISOS A CREAR ---
PERMISSIONS_LIST = [
    # General
    ('view_dashboard', 'Ver el Dashboard principal'),
    
    # Activos Fijos
    ('view_activofijo', 'Ver la lista de activos fijos'),
    ('manage_activofijo', 'Crear, editar y eliminar activos fijos'),
    ('assign_activofijo', 'Asignar activos fijos a empleados/ubicaciones'),
    
    # Organización
    ('view_departamento', 'Ver la lista de departamentos'),
    ('manage_departamento', 'Crear, editar y eliminar departamentos'),
    ('view_cargo', 'Ver la lista de cargos'),
    ('manage_cargo', 'Crear, editar y eliminar cargos'),
    ('view_empleado', 'Ver la lista de empleados'),
    ('manage_empleado', 'Crear, editar y eliminar empleados'),
    
    # Roles y Permisos
    ('view_rol', 'Ver la lista de roles de la empresa'),
    ('manage_rol', 'Crear, editar y eliminar roles (y asignar permisos)'),
    ('view_permiso', 'Ver la lista de permisos globales (para asignar a roles)'),
    
    # Finanzas
    ('view_presupuesto', 'Ver períodos, partidas y movimientos del presupuesto'),
    ('manage_presupuesto', 'Gestionar períodos y partidas presupuestarias (crear, editar, etc.)'),
    
    # Configuración Activos
    ('view_ubicacion', 'Ver la lista de ubicaciones'),
    ('manage_ubicacion', 'Crear, editar y eliminar ubicaciones'),
    ('view_proveedor', 'Ver la lista de proveedores'),
    ('manage_proveedor', 'Crear, editar y eliminar proveedores'),
    ('view_categoriaactivo', 'Ver las categorías de activos'),
    ('manage_categoriaactivo', 'Crear, editar y eliminar categorías de activos'),
    ('view_estadoactivo', 'Ver los estados de activos'),
    ('manage_estadoactivo', 'Crear, editar y eliminar estados de activos'),
    
    # Reportes
    ('view_reporte', 'Acceder a la sección de reportes y generar vistas previas'),
    ('export_reporte', 'Exportar reportes a PDF/Excel'),
    ('view_custom_reports', 'Ver reportes personalizados y avanzados'),

    # --- [NUEVO] Permisos de Revalorización ---
    ('view_revalorizacion', 'Ver el historial de revalorizaciones de activos'),
    ('manage_revalorizacion', 'Ejecutar el proceso de revalorización de activos'),

    # --- [NUEVO] Permisos de Depreciación ---
    ('view_depreciacion', 'Ver el historial de depreciaciones de activos'),
    ('manage_depreciacion', 'Ejecutar el proceso de depreciación de activos'),

    # --- [NUEVO] Permisos de Disposición ---
    ('view_disposicion', 'Ver el historial de disposición de activos'),
    ('manage_disposicion', 'Ejecutar el proceso de disposición de activos'),
    
    # --- [NUEVO] Flujo de Adquisición ---
    ('view_solicitud_compra', 'Ver la lista de solicitudes de compra'),
    ('manage_solicitud_compra', 'Crear y editar solicitudes de compra'),
    ('approve_solicitud_compra', 'Aprobar o rechazar solicitudes de compra'),
    ('view_orden_compra', 'Ver la lista de órdenes de compra'),
    ('manage_orden_compra', 'Crear y editar órdenes de compra a partir de solicitudes aprobadas'),
    ('receive_orden_compra', 'Registrar la recepción de activos desde una orden de compra'),

    # --- [NUEVO] Permisos de Mantenimiento ---
    ('view_mantenimiento', 'Ver la lista de mantenimientos'),
    ('manage_mantenimiento', 'Crear, editar y gestionar mantenimientos'),
    ('update_assigned_mantenimiento', 'Actualizar estado/notas de mantenimientos asignados (Empleado)'), # <-- NUEVO
    
    
    # --- [NUEVO] Permisos de Suscripción ---
    ('view_suscripcion', 'Ver el plan de suscripción actual de la empresa'),
    ('manage_suscripcion', 'Cambiar o actualizar el plan de suscripción (Admin)'),
    
    # Sistema
    ('view_log', 'Ver la bitácora de acciones'),
    ('manage_settings', 'Acceder a la configuración general del sistema'),
    
    # Permiso obsoleto de tu seed_data (lo elimino)
    # ('manage_permiso', 'Crear, editar, eliminar permisos globales (SOLO SUPERADMIN)'),
]

class Command(BaseCommand):
    help = 'Crea o actualiza los permisos globales definidos en PERMISSIONS_LIST.'

    @transaction.atomic(using='default') 
    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.NOTICE('Verificando y creando permisos globales...'))
        
        created_count = 0
        updated_count = 0
        skipped_count = 0
        
        perm_names_in_list = {p[0] for p in PERMISSIONS_LIST}

        # Borrar permisos obsoletos que ya no están en la lista
        obsolete_perms = Permisos.objects.exclude(nombre__in=perm_names_in_list)
        delete_count = obsolete_perms.count()
        if delete_count > 0:
            obsolete_perms.delete()
            self.stdout.write(self.style.WARNING(f'  Eliminados {delete_count} permisos obsoletos.'))

        # Crear o actualizar permisos de la lista
        for perm_name, perm_desc in PERMISSIONS_LIST:
            permission, created = Permisos.objects.get_or_create(
                nombre=perm_name,
                defaults={'descripcion': perm_desc}
            )
            
            if created:
                self.stdout.write(self.style.SUCCESS(f'  Creado: {perm_name}'))
                created_count += 1
            elif permission.descripcion != perm_desc:
                permission.descripcion = perm_desc
                permission.save()
                self.stdout.write(self.style.WARNING(f'  Actualizado desc: {perm_name}'))
                updated_count += 1
            else:
                skipped_count += 1

        self.stdout.write(self.style.SUCCESS(f'\nProceso completado.'))
        self.stdout.write(f'  Creados: {created_count}')
        self.stdout.write(f'  Actualizados: {updated_count}')
        self.stdout.write(f'  Omitidos (sin cambios): {skipped_count}')