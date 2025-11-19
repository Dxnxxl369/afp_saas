# backend/api/management/commands/poblar.py

import os
import random
import uuid
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from api.models import (
    ActivoFijo, CategoriaActivo, Departamento, Empleado, Empresa, Estado,
    PartidaPresupuestaria, PeriodoPresupuestario, Permisos, Proveedor,
    Roles, Suscripcion, Ubicacion, Cargo
)
from django.contrib.auth.models import User

# --- Datos para la configuración de cada empresa ---
COMPANY_DATA = [
    {
        'name': 'TechSolutions Basic',
        'nit': '123456789',
        'plan': 'basico',
        'max_users': 15,
        'max_activos': 100,
    },
    {
        'name': 'Innovatech Pro',
        'nit': '987654321',
        'plan': 'profesional',
        'max_users': 40,
        'max_activos': 350,
    },
    {
        'name': 'GlobalCorp Enterprise',
        'nit': '112233445',
        'plan': 'empresarial',
        'max_users': 9999, # Ilimitado
        'max_activos': 99999, # Ilimitado
    },
]

# --- Clases de datos maestros de ejemplo ---
DEPARTAMENTOS = ['IT', 'Recursos Humanos', 'Ventas', 'Marketing', 'Finanzas', 'Logística']
CATEGORIAS = ['Computadoras', 'Mobiliario', 'Vehículos', 'Maquinaria', 'Software', 'Equipos de Oficina']
ESTADOS = ['Activo', 'En Reparación', 'En Almacén', 'Obsoleto']
UBICACIONES = ['Oficina Central', 'Almacén Principal', 'Sucursal Norte', 'Sucursal Sur', 'Sala de Servidores']
PROVEEDORES = [
    {'nombre': 'Proveedor Tech SA', 'nit': '1111111', 'email': 'contacto@tech.com'},
    {'nombre': 'Muebles Express', 'nit': '2222222', 'email': 'ventas@muebles.com'},
    {'nombre': 'Autos del Sur', 'nit': '3333333', 'email': 'info@autos.com'},
]
CARGOS = ['Gerente', 'Jefe de Departamento', 'Analista', 'Técnico', 'Vendedor', 'Asistente']

class Command(BaseCommand):
    help = 'Pobla la base de datos con datos de ejemplo para varias empresas, incluyendo límites de suscripción.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--no-clear',
            action='store_true',
            help='No eliminar los datos existentes antes de poblar.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Iniciando proceso de poblado de la base de datos...'))

        if not options['no_clear']:
            self.stdout.write(self.style.WARNING('Eliminando datos existentes (Empresas, Usuarios, Activos, etc.)...'))
            self._clear_data()
            self.stdout.write(self.style.SUCCESS('Datos existentes eliminados.'))

        all_permissions = list(Permisos.objects.all()) # Obtener todos los permisos una sola vez
        if not all_permissions:
            self.stdout.write(self.style.ERROR('¡ERROR! No se encontraron permisos en la base de datos. Por favor, asegúrese de ejecutar "python manage.py create_permissions" primero.'))
            return
            
        created_companies_info = []

        for company_data in COMPANY_DATA:
            self.stdout.write(self.style.NOTICE(f'\n--- Creando datos para la empresa: {company_data["name"]} ({company_data["plan"].upper()}) '))
            
            # --- 1. Crear Empresa ---
            empresa = Empresa.objects.create(
                nombre=company_data['name'],
                nit=company_data['nit'],
                direccion=f"Calle Falsa 123, {company_data['name']}",
                telefono=f"7{random.randint(0, 9999999)}",
                email=f"info@{company_data['name'].replace(' ', '').lower()}.com"
            )
            self.stdout.write(self.style.SUCCESS(f'Empresa "{empresa.nombre}" creada.'))

            # --- 2. Crear Suscripción ---
            max_users = company_data['max_users']
            max_activos = company_data['max_activos']
            Suscripcion.objects.create(
                empresa=empresa,
                plan=company_data['plan'],
                estado='activa',
                fecha_inicio=timezone.now().date(),
                fecha_fin=timezone.now().date() + timedelta(days=365),
                max_usuarios=max_users,
                max_activos=max_activos
            )
            self.stdout.write(self.style.SUCCESS(f'Suscripción "{company_data["plan"]}" creada para {empresa.nombre}.'))

            # --- 3. Crear Rol Admin y asignarle todos los permisos ---
            rol_admin, _ = Roles.objects.get_or_create(empresa=empresa, nombre='Admin')
            rol_admin.permisos.set(all_permissions)
            self.stdout.write(self.style.SUCCESS(f'Rol "Admin" creado y permisos asignados para {empresa.nombre}.'))

            # --- 4. Crear Admin User y Empleado ---
            base_admin_username = f"admin_{empresa.nombre.replace(' ', '').lower()[:10]}"
            admin_username = base_admin_username
            counter = 0
            while User.objects.filter(username=admin_username).exists():
                counter += 1
                admin_username = f"{base_admin_username}{counter}"
            
            admin_user = User.objects.create_user(
                username=admin_username,
                password='empresa123',
                first_name='Admin',
                last_name=empresa.nombre.split(' ')[0],
                email=f"{admin_username}@{empresa.nombre.replace(' ', '').lower()}.com",
                is_staff=False # IMPORTANTE: NO es staff de Django, es admin de la empresa
            )
            empleado_admin = Empleado.objects.create(
                usuario=admin_user,
                empresa=empresa,
                ci=f"{random.randint(1000000, 9999999)}",
                apellido_p='Principal',
                apellido_m='Empresa',
                direccion='Av. Siempre Viva 742',
                telefono=f"7{random.randint(0, 9999999)}",
            )
            empleado_admin.roles.add(rol_admin)
            self.stdout.write(self.style.SUCCESS(f'Usuario Admin "{admin_user.username}" creado (Pass: empresa123).'))
            
            created_companies_info.append({
                'company_name': empresa.nombre,
                'admin_username': admin_user.username,
                'password': 'empresa123'
            })

            # --- 5. Crear Datos Maestros para la empresa ---
            master_data = self._create_master_data(empresa)
            self.stdout.write(self.style.SUCCESS('Datos maestros (Departamentos, Categorías, etc.) creados.'))

            # --- 6. Crear Empleados adicionales (N-2) ---
            num_users_to_create = max(0, min(max_users - 2, 5 if max_users == 9999 else max_users - 2)) # Min 0, Max 5 si ilimitado
            for i in range(num_users_to_create):
                base_user_username = f"user{i+1}_{empresa.nombre.replace(' ', '').lower()[:5]}"
                user_username = base_user_username
                user_counter = 0
                while User.objects.filter(username=user_username).exists():
                    user_counter += 1
                    user_username = f"{base_user_username}{user_counter}"

                user_user = User.objects.create_user(
                    username=user_username,
                    password='empresa123',
                    first_name=f'Usuario{i+1}',
                    last_name=f'de {empresa.nombre.split(" ")[0]}',
                    email=f"{user_username}@{empresa.nombre.replace(' ', '').lower()}.com"
                )
                empleado = Empleado.objects.create(
                    usuario=user_user,
                    empresa=empresa,
                    ci=f"{random.randint(1000000, 9999999)}",
                    apellido_p=f'Apellido{i+1}',
                    apellido_m=f'Materno{i+1}',
                    direccion=f'Calle {i+1} de {empresa.nombre}',
                    telefono=f"7{random.randint(0, 9999999)}",
                    cargo=random.choice(master_data['cargos']),
                    departamento=random.choice(master_data['departamentos']),
                )
                # Asignar un rol básico si existe
                rol_empleado, created = Roles.objects.get_or_create(empresa=empresa, nombre='Empleado Básico')
                if created: # Si lo acaba de crear, asignarle permisos de vista
                    rol_empleado.permisos.set([p for p in all_permissions if p.nombre.startswith('view_')])
                empleado.roles.add(rol_empleado)
            self.stdout.write(self.style.SUCCESS(f'Creados {num_users_to_create} empleados adicionales.'))

            # --- 7. Crear Activos Fijos (N-2) ---
            num_assets_to_create = max(0, min(max_activos - 2, 10 if max_activos == 99999 else max_activos - 2)) # Min 0, Max 10 si ilimitado
            for i in range(num_assets_to_create):
                base_codigo_interno = f"ACT-{empresa.nombre[:3].upper()}-{random.randint(1000, 9999)}"
                codigo_interno = base_codigo_interno
                code_counter = 0
                while ActivoFijo.objects.filter(empresa=empresa, codigo_interno=codigo_interno).exists():
                    code_counter += 1
                    codigo_interno = f"{base_codigo_interno}-{code_counter}"
                
                ActivoFijo.objects.create(
                    empresa=empresa,
                    nombre=f"Activo {i+1} - {random.choice(CATEGORIAS)}",
                    codigo_interno=codigo_interno,
                    fecha_adquisicion=timezone.now().date() - timedelta(days=random.randint(30, 1000)),
                    valor_actual=round(random.uniform(500.0, 50000.0), 2),
                    vida_util=random.randint(1, 10),
                    departamento=random.choice(master_data['departamentos']),
                    categoria=random.choice(master_data['categorias']),
                    estado=random.choice(master_data['estados']),
                    ubicacion=random.choice(master_data['ubicaciones']),
                    proveedor=random.choice(master_data['proveedores']),
                )
            self.stdout.write(self.style.SUCCESS(f'Creados {num_assets_to_create} activos fijos.'))
            
            # --- 8. Crear Periodo y Partidas Presupuestarias ---
            periodo = PeriodoPresupuestario.objects.create(
                empresa=empresa,
                nombre=f"Presupuesto Anual {timezone.now().year}",
                fecha_inicio=timezone.now().replace(month=1, day=1).date(),
                fecha_fin=timezone.now().replace(month=12, day=31).date(),
                estado='ACTIVO'
            )
            self.stdout.write(self.style.SUCCESS(f'Periodo presupuestario "{periodo.nombre}" creado.'))
            for i in range(3): # 3 partidas por periodo
                PartidaPresupuestaria.objects.create(
                    periodo=periodo,
                    departamento=random.choice(master_data['departamentos']),
                    nombre=f"Partida {i+1} - {random.choice(['Operaciones', 'Inversión', 'Mantenimiento'])}",
                    codigo=f"PART-{random.randint(100, 999)}",
                    monto_asignado=round(random.uniform(10000.0, 100000.0), 2)
                )
            self.stdout.write(self.style.SUCCESS('Partidas presupuestarias creadas.'))


        self.stdout.write(self.style.SUCCESS('\nProceso de poblado completado con éxito para todas las empresas.'))
        self.stdout.write(self.style.SUCCESS('--- Información de acceso ---'))
        for info in created_companies_info:
            self.stdout.write(self.style.SUCCESS(f'Empresa: {info["company_name"]}, Admin User: {info["admin_username"]}, Contraseña: {info["password"]}'))

    def _clear_data(self):
        # Eliminar en orden para evitar problemas de FK
        Empleado.objects.all().delete()
        User.objects.all().delete() # Esto eliminará usuarios, incluyendo admins
        ActivoFijo.objects.all().delete()
        PartidaPresupuestaria.objects.all().delete()
        PeriodoPresupuestario.objects.all().delete()
        Suscripcion.objects.all().delete()
        Roles.objects.all().delete()
        Departamento.objects.all().delete()
        CategoriaActivo.objects.all().delete()
        Estado.objects.all().delete()
        Ubicacion.objects.all().delete()
        Proveedor.objects.all().delete()
        Empresa.objects.all().delete()

    def _create_master_data(self, empresa):
        # Asegurarse de que al menos un item de cada tipo exista
        departamentos = [Departamento.objects.get_or_create(empresa=empresa, nombre=d)[0] for d in DEPARTAMENTOS]
        categorias = [CategoriaActivo.objects.get_or_create(empresa=empresa, nombre=c)[0] for c in CATEGORIAS]
        estados = [Estado.objects.get_or_create(empresa=empresa, nombre=e)[0] for e in ESTADOS]
        ubicaciones = [Ubicacion.objects.get_or_create(empresa=empresa, nombre=u)[0] for u in UBICACIONES]
        proveedores = []
        for p_data in PROVEEDORES:
            prov, created = Proveedor.objects.get_or_create(empresa=empresa, nit=p_data['nit'], defaults={'nombre': p_data['nombre'], 'email': p_data['email']})
            proveedores.append(prov)
        
        cargos = [Cargo.objects.get_or_create(empresa=empresa, nombre=c)[0] for c in CARGOS]
        
        return {
            'departamentos': departamentos,
            'categorias': categorias,
            'estados': estados,
            'ubicaciones': ubicaciones,
            'proveedores': proveedores,
            'cargos': cargos,
        }
