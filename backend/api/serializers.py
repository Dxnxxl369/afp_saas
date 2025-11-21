# api/serializers.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth.models import User
from .permissions import check_permission, HasPermission
from .models import *
from django.db import transaction
from datetime import timedelta, datetime # <-- datetime AÑADIDO
import re # <-- re AÑADIDO
from django.db.models import Sum # <-- AÑADIDO: Importar Sum

class CurrentUserEmpresaDefault:
    requires_context = True

    def __call__(self, serializer_field):
        request = serializer_field.context['request']
        user = request.user
        if user.is_staff:
            empresa = Empresa.objects.first()
            if not empresa:
                raise serializers.ValidationError("No hay empresas registradas. El superusuario no puede crear datos.")
            return empresa
        
        if hasattr(user, 'empleado'):
            return user.empleado.empresa
        
        raise serializers.ValidationError("El usuario no está asociado a una empresa.")

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = ['id', 'nombre', 'nit']

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        try:
            empleado = user.empleado
            token['username'] = user.username
            token['email'] = user.email
            token['nombre_completo'] = f"{user.first_name} {empleado.apellido_p}"
            token['empresa_id'] = str(empleado.empresa.id)
            token['empresa_nombre'] = empleado.empresa.nombre
            token['roles'] = [rol.nombre for rol in empleado.roles.all()]             
            token['is_admin'] = user.is_staff 
            token['empleado_id'] = str(empleado.id) # <-- ID del Empleado
            token['theme_preference'] = empleado.theme_preference
            token['theme_custom_color'] = empleado.theme_custom_color
            token['theme_glow_enabled'] = empleado.theme_glow_enabled
        except Empleado.DoesNotExist:
            token['username'] = user.username
            token['email'] = user.email
            token['nombre_completo'] = user.username
            token['empresa_id'] = None
            token['empresa_nombre'] = None
            token['roles'] = []
            token['is_admin'] = user.is_staff
            token['empleado_id'] = None
            token['theme_preference'] = None
            token['theme_custom_color'] = None
            token['theme_glow_enabled'] = None
        return token

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email']

class CargoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = Cargo
        fields = '__all__'

    def validate(self, data):
        empresa = data.get('empresa')
        nombre = data.get('nombre')
        query = Cargo.objects.filter(empresa=empresa, nombre__iexact=nombre)

        if self.instance:
            query = query.exclude(pk=self.instance.pk)

        if query.exists():
            raise serializers.ValidationError({
                "nombre": f"Ya existe un cargo con el nombre '{nombre}' en la empresa '{empresa.nombre}'."
            })
            
        return data

class DepartamentoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = Departamento
        fields = '__all__'

class PermisosSerializer(serializers.ModelSerializer): # <--- MOVED HERE
    class Meta:
        model = Permisos
        fields = '__all__'

class RolesSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    permisos = serializers.PrimaryKeyRelatedField(
        many=True, 
        queryset=Permisos.objects.all(),
        required=False
    )

    class Meta:
        model = Roles
        fields = ['id', 'empresa', 'nombre', 'permisos']
        read_only_fields = ['id', 'empresa']

    def to_representation(self, instance):
        """On read, represent `permisos` as full objects."""
        representation = super().to_representation(instance)
        representation['permisos'] = PermisosSerializer(instance.permisos.all(), many=True).data
        return representation

    def create(self, validated_data):
        permisos_data = validated_data.pop('permisos', [])
        role = Roles.objects.create(**validated_data)
        if permisos_data:
            role.permisos.set(permisos_data)
        return role

    def update(self, instance, validated_data):
        permisos_data = validated_data.pop('permisos', None)
        instance = super().update(instance, validated_data)

        if permisos_data is not None:
            instance.permisos.set(permisos_data)
            
        return instance
        
class EmpleadoSerializer(serializers.ModelSerializer): # <-- [EDITADO]
    usuario = UsuarioSerializer(read_only=True)
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, style={'input_type': 'password'}, required=False) # No requerido al editar
    first_name = serializers.CharField(write_only=True)
    email = serializers.EmailField(write_only=True)
    
    roles = serializers.PrimaryKeyRelatedField(
        queryset=Roles.objects.all(), 
        many=True, 
        #write_only=True, 
        required=False
    )
    
    # --- [NUEVO] Campo de foto ---
    # DRF maneja ImageField (y FileField) automáticamente
    # Aceptará un archivo subido (multipart/form-data)
    foto_perfil = serializers.ImageField(required=False, allow_null=True)
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())

    class Meta:
        model = Empleado
        fields = [
            'id', 'usuario', 'ci', 'apellido_p', 'apellido_m', 
            'direccion', 'telefono', 'sueldo', 'cargo', 
            'departamento', 'empresa', 'foto_perfil', # <-- Añadido
            # Campos write_only
            'theme_preference', 'theme_custom_color', 'theme_glow_enabled',
            'username', 'password', 'first_name', 'email', 'roles', 
            # Campos read_only
            'cargo_nombre', 'departamento_nombre', 'roles_asignados' 
        ]      
        read_only_fields = ('usuario', 'cargo_nombre', 'departamento_nombre', 'roles_asignados')
        extra_kwargs = {
            'cargo': {'required': False, 'allow_null': True}, # <-- 'write_only: True' ELIMINADO
            'departamento': {'required': False, 'allow_null': True}, # <-- 'write_only: True' ELIMINADO
        }

    cargo_nombre = serializers.CharField(source='cargo.nombre', read_only=True, allow_null=True)
    departamento_nombre = serializers.CharField(source='departamento.nombre', read_only=True, allow_null=True)
    roles_asignados = RolesSerializer(source='roles', many=True, read_only=True)

    def create(self, validated_data):
        # ... (Tu método create está bien) ...
        # (Asegúrate de que 'foto_perfil' se pase en validated_data)
        username = validated_data.pop('username')
        password = validated_data.pop('password')
        first_name = validated_data.pop('first_name')
        email = validated_data.pop('email')
        roles_data = validated_data.pop('roles', [])
        
        user = User.objects.create_user(
            username=username, password=password, first_name=first_name,
            email=email, last_name=validated_data.get('apellido_p', ''),
            is_active=True
        )
        
        # 'foto_perfil' y el resto de campos están en validated_data
        empleado = Empleado.objects.create(usuario=user, **validated_data) 
        if roles_data:
            empleado.roles.set(roles_data)
        return empleado

    def update(self, instance, validated_data):
        # Manejar la actualización de campos de User si se proporcionan
        # (Tu EmpleadoForm.jsx los deshabilita, lo cual está bien,
        # pero esto es por si quieres añadir "editar perfil" luego)
        
        # No se puede cambiar el username, pero sí otros datos
        user = instance.usuario
        user.first_name = validated_data.get('first_name', user.first_name)
        user.email = validated_data.get('email', user.email)
        user.last_name = validated_data.get('apellido_p', user.last_name)
        
        # Cambiar contraseña solo si se proporciona una nueva
        password = validated_data.pop('password', None)
        if password:
            user.set_password(password)
        user.save()
        
        # Manejar roles
        if 'roles' in validated_data:
            roles_data = validated_data.pop('roles')
            instance.roles.set(roles_data)
            
        # Actualizar el resto de campos del empleado
        return super().update(instance, validated_data)

class ActivoFijoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    foto_activo = serializers.ImageField(required=False, allow_null=True)
    
    # --- [NUEVO] Campos de solo lectura para nombres relacionados ---
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    estado_nombre = serializers.CharField(source='estado.nombre', read_only=True)
    ubicacion_nombre = serializers.CharField(source='ubicacion.nombre', read_only=True)
    departamento_nombre = serializers.CharField(source='departamento.nombre', read_only=True, allow_null=True)
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True, allow_null=True)

    class Meta:
        model = ActivoFijo
        fields = [
            'id', 'nombre', 'codigo_interno', 'fecha_adquisicion', 
            'valor_actual', 'vida_util', 'foto_activo',
            # IDs para escritura
            'categoria', 'estado', 'ubicacion', 'departamento', 'proveedor',
            # Nombres para lectura
            'categoria_nombre', 'estado_nombre', 'ubicacion_nombre', 
            'departamento_nombre', 'proveedor_nombre',
            # Campo oculto de empresa
            'empresa', 'orden_compra',
        ]
        extra_kwargs = {
            'categoria': {'write_only': True},
            'estado': {'write_only': True},
            'ubicacion': {'write_only': True},
            'departamento': {'write_only': True},
            'proveedor': {'write_only': True},
        }

class CategoriaActivoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = CategoriaActivo
        fields = '__all__'

class EstadoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = Estado
        fields = '__all__'

class UbicacionSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = Ubicacion
        fields = '__all__'

class ProveedorSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    class Meta:
        model = Proveedor
        fields = '__all__'

# --- [NUEVO] Serializers para Módulo de Presupuesto ---

class MovimientoPresupuestarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = MovimientoPresupuestario
        fields = '__all__'
        read_only_fields = ('id', 'fecha', 'realizado_por')

class PartidaPresupuestariaSerializer(serializers.ModelSerializer):
    monto_disponible = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    departamento = DepartamentoSerializer(read_only=True)
    departamento_id = serializers.PrimaryKeyRelatedField(
        queryset=Departamento.objects.all(), source='departamento', write_only=True
    )
    periodo_id = serializers.PrimaryKeyRelatedField( # This is for WRITING
        queryset=PeriodoPresupuestario.objects.all(), source='periodo', write_only=True
    )
    periodo = serializers.StringRelatedField(read_only=True) # This is for READING

    class Meta:
        model = PartidaPresupuestaria
        fields = ('id', 'periodo', 'periodo_id', 'departamento', 'departamento_id', 'nombre', 'codigo', 'monto_asignado', 'monto_gastado', 'monto_disponible')
        read_only_fields = ('monto_gastado',)

class PeriodoPresupuestarioSerializer(serializers.ModelSerializer):
    partidas = PartidaPresupuestariaSerializer(many=True, read_only=True)
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    
    total_gastado_periodo = serializers.SerializerMethodField()
    ahorro_o_sobregasto = serializers.SerializerMethodField()

    class Meta:
        model = PeriodoPresupuestario
        fields = ('id', 'empresa', 'nombre', 'fecha_inicio', 'fecha_fin', 'estado', 'monto_total', 'partidas', 'total_gastado_periodo', 'ahorro_o_sobregasto')
        read_only_fields = ('monto_total', 'total_gastado_periodo', 'ahorro_o_sobregasto')

    def get_total_gastado_periodo(self, obj):
        # Suma el monto_gastado de todas las partidas asociadas a este período
        return obj.partidas.aggregate(Sum('monto_gastado'))['monto_gastado__sum'] or 0

    def get_ahorro_o_sobregasto(self, obj):
        total_gastado = self.get_total_gastado_periodo(obj)
        # Si monto_total no está calculado aún, o es 0, el ahorro/sobregasto es 0
        if not obj.monto_total:
            return 0
        return obj.monto_total - total_gastado


# --- Serializers para Flujo de Adquisición (Actualizado) ---
class SolicitudCompraSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    solicitante = UsuarioSerializer(read_only=True)
    departamento = DepartamentoSerializer(read_only=True)
    departamento_id = serializers.PrimaryKeyRelatedField(
        queryset=Departamento.objects.all(), source='departamento', write_only=True
    )
    decision_por = UsuarioSerializer(read_only=True)
    partida_presupuestaria = PartidaPresupuestariaSerializer(read_only=True)
    partida_presupuestaria_id = serializers.PrimaryKeyRelatedField(
        queryset=PartidaPresupuestaria.objects.all(), source='partida_presupuestaria', write_only=True, allow_null=True, required=False
    )
    force_overspend = serializers.BooleanField(write_only=True, required=False, default=False) # NEW FIELD

    class Meta:
        model = SolicitudCompra
        fields = '__all__'
        read_only_fields = ('solicitante', 'empresa', 'estado', 'fecha_decision', 'decision_por', 'motivo_rechazo')

    def create(self, validated_data):
        validated_data['solicitante'] = self.context['request'].user
        partida = validated_data.get('partida_presupuestaria')
        force_overspend = validated_data.pop('force_overspend', False) # Extract and remove from validated_data

        if partida:
            if not force_overspend and partida.monto_disponible < validated_data.get('costo_estimado', 0):
                raise serializers.ValidationError({
                    'partida_presupuestaria_id': 'El costo estimado excede el monto disponible en la partida presupuestaria. Para forzar la solicitud, envíe `force_overspend: true`.'
                })
        return super().create(validated_data)

class OrdenCompraSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    solicitud = SolicitudCompraSerializer(read_only=True)
    solicitud_id = serializers.PrimaryKeyRelatedField(
        queryset=SolicitudCompra.objects.filter(estado='APROBADA'), source='solicitud', write_only=True
    )
    proveedor = ProveedorSerializer(read_only=True)
    proveedor_id = serializers.PrimaryKeyRelatedField(
        queryset=Proveedor.objects.all(), source='proveedor', write_only=True
    )
    creado_por = UsuarioSerializer(read_only=True)
    activo_creado = ActivoFijoSerializer(read_only=True)

    class Meta:
        model = OrdenCompra
        fields = '__all__'
        read_only_fields = ('empresa', 'creado_por', 'estado', 'activo_creado')

    def create(self, validated_data):
        validated_data['creado_por'] = self.context['request'].user
        # Validar que la solicitud no tenga ya una orden de compra
        solicitud = validated_data.get('solicitud')
        if hasattr(solicitud, 'orden_compra'):
            raise serializers.ValidationError({'solicitud_id': 'Esta solicitud de compra ya tiene una orden de compra asociada.'})
        return super().create(validated_data)




class RegisterEmpresaSerializer(serializers.Serializer):
    # (Campos existentes)
    empresa_nombre = serializers.CharField(max_length=100)
    empresa_nit = serializers.CharField(max_length=20)
    admin_username = serializers.CharField(max_length=100)
    admin_password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    admin_first_name = serializers.CharField(max_length=100)
    admin_email = serializers.EmailField()
    admin_ci = serializers.CharField(max_length=20)
    admin_apellido_p = serializers.CharField(max_length=100)
    admin_apellido_m = serializers.CharField(max_length=100)
    card_number = serializers.CharField(write_only=True)
    card_expiry = serializers.CharField(write_only=True)
    card_cvc = serializers.CharField(write_only=True)
    plan = serializers.ChoiceField(choices=Suscripcion.PLAN_CHOICES, write_only=True)    

    # ... (Tus métodos validate_... están perfectos) ...
    def validate_empresa_nombre(self, value):
        if Empresa.objects.filter(nombre__iexact=value).exists():
            raise serializers.ValidationError("Ya existe una empresa con este nombre.")
        return value
        
    def validate_empresa_nit(self, value):
        if Empresa.objects.filter(nit__iexact=value).exists():
            raise serializers.ValidationError("Ya existe una empresa con este NIT.")
        return value
        
    def validate_admin_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("Este nombre de usuario ya está en uso.")
        return value

    def validate_card_number(self, value):
        if not re.match(r'^\d{16}$', value):
            raise serializers.ValidationError("El número de tarjeta debe contener exactamente 16 dígitos.")
        return value

    def validate_card_expiry(self, value):
        if not re.match(r'^(0[1-9]|1[0-2])\/\d{2}$', value):
            raise serializers.ValidationError("La fecha de expiración debe tener el formato MM/AA.")
        
        try:
            month, year_str = value.split('/') # Cambiado 'year' a 'year_str' para evitar conflicto con la función year 
            year = int(year_str) # Convertir a int
            
            # Ajustar el año a formato de 4 dígitos (ej: 23 -> 2023)
            # COMENTADO para permitir cualquier fecha FUTURA para testing
            # current_year = datetime.now().year
            # if year < (current_year % 100) - 20: # Ajuste heurístico para años recientes
            #     year += 2000
            # elif year < (current_year % 100) + 80:
            #     year += 1900
            # else:
            #     year += 2000 # Default
                
            # Deshabilita la validación de fecha de expiración para TESTING
            # last_day_of_month = (datetime(year, int(month) + 1, 1) - timedelta(days=1)).day
            # expiry_date = datetime(year, int(month), last_day_of_month)
            # if expiry_date < datetime.now():
            #     raise serializers.ValidationError("La tarjeta ha expirado.")
        except (ValueError, TypeError):
            raise serializers.ValidationError("Fecha de expiración inválida.")
        return value

    def validate_card_cvc(self, value):
        if not re.match(r'^\d{3,4}$', value):
            raise serializers.ValidationError("El CVC debe contener 3 o 4 dígitos.")
        return value

    @transaction.atomic(using='default')
    def create(self, validated_data):
        try:
            # 1. Crear la Empresa
            empresa = Empresa.objects.create(
                nombre=validated_data['empresa_nombre'],
                nit=validated_data['empresa_nit']
            )

            # 2. Crear el User (Admin)
            user = User.objects.create_user(
                username=validated_data['admin_username'],
                password=validated_data['admin_password'],
                first_name=validated_data['admin_first_name'],
                email=validated_data['admin_email'],
                last_name=validated_data['admin_apellido_p'],
                is_active=True
            )

            # 3. Crear el Empleado (Admin)
            empleado = Empleado.objects.create(
                usuario=user,
                empresa=empresa,
                ci=validated_data['admin_ci'],
                apellido_p=validated_data['admin_apellido_p'],
                apellido_m=validated_data['admin_apellido_m'],
                # Puedes añadir valores por defecto si quieres
                # cargo=Cargo.objects.get_or_create(...)[0],
            )

            # 4. Crear la Suscripción (Asegurando usar el plan validado)
            # validated_data['plan'] ya contiene el valor correcto ('basico', 'profesional', etc.)
            plan_seleccionado = validated_data['plan']
            limits = {
                'basico': {'usuarios': 15, 'activos': 100},
                'profesional': {'usuarios': 40, 'activos': 350},
                'empresarial': {'usuarios': 9999, 'activos': 99999},
            }

            # Verificamos si plan_seleccionado es una clave válida
            if plan_seleccionado not in limits:
                 # Esto no debería pasar si ChoiceField funciona, pero es una seguridad extra
                 raise serializers.ValidationError(f"Plan '{plan_seleccionado}' inválido seleccionado.")

            Suscripcion.objects.create(
                empresa=empresa,
                plan=plan_seleccionado, # Usar la variable validada
                estado='activa',
                fecha_inicio=timezone.now(),
                fecha_fin=timezone.now() + timedelta(days=30), # Suscripción de 30 días
                max_usuarios=limits[plan_seleccionado]['usuarios'],
                max_activos=limits[plan_seleccionado]['activos']
            )

            # 5. --- [NUEVO] Asignar Rol de Admin y Permisos por Defecto ---
            # Crear o obtener el rol 'Admin' para esta nueva empresa
            rol_admin, _ = Roles.objects.get_or_create(empresa=empresa, nombre='Admin')

            # Obtener todos los permisos globales para asignarlos al rol de Admin.
            # Nota: Esto asume que el comando `manage.py create_permissions` ha sido ejecutado
            # y que la tabla de Permisos está poblada.
            permisos_para_admin = Permisos.objects.all()

            # Asignar todos esos permisos al rol 'Admin' de esta empresa
            rol_admin.permisos.set(permisos_para_admin)

            # Asignar el rol 'Admin' al nuevo empleado
            empleado.roles.add(rol_admin)
            # --- [FIN DE NUEVO CÓDIGO] ---

            return user # Devolvemos el usuario para generar el token

        except Exception as e:
             # Si algo falla (ej: error al crear suscripción, rol, etc.),
             # transaction.atomic deshará todo lo anterior.
             # Lanzamos un error de validación para que el frontend lo muestre.
             print(f"ERROR en RegisterEmpresaSerializer.create: {e}") # Log para el servidor
             raise serializers.ValidationError(f"Error interno durante el registro: {e}")

class EmpleadoSimpleSerializer(serializers.ModelSerializer):
    # Anidamos info básica del usuario
    usuario = UsuarioSerializer(read_only=True)
    class Meta:
        model = Empleado
        fields = ['id', 'usuario', 'apellido_p', 'apellido_m'] # Campos necesarios para mostrar nombre
        
# --- [NUEVO] Serializers para los nuevos modelos ---

class MantenimientoFotoSerializer(serializers.ModelSerializer):
    subido_por = UsuarioSerializer(read_only=True)
    class Meta:
        model = MantenimientoFoto
        fields = ['id', 'foto', 'tipo', 'subido_por', 'fecha_creacion']


class MantenimientoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    activo = ActivoFijoSerializer(read_only=True)
    empleado_asignado = EmpleadoSimpleSerializer(read_only=True)
    creado_por = UsuarioSerializer(read_only=True) # <-- AÑADIDO
    creado_por_nombre = serializers.CharField(source='creado_por.get_full_name', read_only=True) # <-- AÑADIDO
    
    # Campos de fotos separados por tipo
    fotos_problema = serializers.SerializerMethodField()
    fotos_solucion = serializers.SerializerMethodField()

    # Campos de escritura
    activo_id = serializers.PrimaryKeyRelatedField(
        queryset=ActivoFijo.objects.all(), source='activo', write_only=True
    )
    empleado_asignado_id = serializers.PrimaryKeyRelatedField(
        queryset=Empleado.objects.all(), source='empleado_asignado', write_only=True,
        required=False, allow_null=True
    )
    fotos_nuevas = serializers.ListField(
        child=serializers.ImageField(allow_empty_file=False, use_url=False),
        write_only=True,
        required=False
    )
    fotos_a_eliminar = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False
    )

    class Meta:
        model = Mantenimiento
        fields = [
            'id', 'tipo', 'estado', 'fecha_inicio', 'fecha_fin',
            'descripcion_problema', 'notas_solucion', 'costo',
            'activo', 'empleado_asignado', 'creado_por', 'creado_por_nombre', # <-- AÑADIDO
            'fotos_problema', 'fotos_solucion',
            'activo_id', 'empleado_asignado_id',
            'fotos_nuevas', 'fotos_a_eliminar',
            'empresa',
        ]

    def get_fotos_problema(self, obj):
        fotos = obj.fotos.filter(tipo='PROBLEMA')
        return MantenimientoFotoSerializer(fotos, many=True, context=self.context).data

    def get_fotos_solucion(self, obj):
        fotos = obj.fotos.filter(tipo='SOLUCION')
        return MantenimientoFotoSerializer(fotos, many=True, context=self.context).data

    def create(self, validated_data):
        fotos_data = validated_data.pop('fotos_nuevas', [])
        user = self.context['request'].user
        mantenimiento = Mantenimiento.objects.create(**validated_data)
        for foto_data in fotos_data:
            MantenimientoFoto.objects.create(
                mantenimiento=mantenimiento, 
                foto=foto_data,
                subido_por=user,
                tipo='PROBLEMA' # Al crear, las fotos son del problema
            )
        return mantenimiento

    def update(self, instance, validated_data):
        fotos_nuevas_data = validated_data.pop('fotos_nuevas', [])
        fotos_a_eliminar_ids = validated_data.pop('fotos_a_eliminar', [])
        user = self.context['request'].user

        if fotos_a_eliminar_ids:
            # Solo el usuario que subió la foto o un admin puede borrarla
            fotos_a_borrar = MantenimientoFoto.objects.filter(id__in=fotos_a_eliminar_ids, mantenimiento=instance)
            if not user.is_staff: # Si no es admin, solo puede borrar las suyas
                fotos_a_borrar = fotos_a_borrar.filter(subido_por=user)
            fotos_a_borrar.delete()

        for foto_data in fotos_nuevas_data:
            # Al actualizar, asumimos que las fotos son de la solución
            MantenimientoFoto.objects.create(
                mantenimiento=instance, 
                foto=foto_data,
                subido_por=user,
                tipo='SOLUCION'
            )

        instance = super().update(instance, validated_data)
        return instance

class RevalorizacionActivoSerializer(serializers.ModelSerializer):
    activo = ActivoFijoSerializer(read_only=True)
    realizado_por = UsuarioSerializer(read_only=True)

    class Meta:
        model = RevalorizacionActivo
        fields = '__all__'


class DepreciacionActivoSerializer(serializers.ModelSerializer):
    activo = ActivoFijoSerializer(read_only=True)
    realizado_por = UsuarioSerializer(read_only=True)
    depreciation_type_display = serializers.CharField(source='get_depreciation_type_display', read_only=True)

    class Meta:
        model = DepreciacionActivo
        fields = '__all__'
        read_only_fields = ('depreciation_type_display',)

class DisposicionActivoSerializer(serializers.ModelSerializer):
    empresa = serializers.HiddenField(default=CurrentUserEmpresaDefault())
    activo = ActivoFijoSerializer(read_only=True)
    activo_id = serializers.PrimaryKeyRelatedField(
        queryset=ActivoFijo.objects.all(), source='activo', write_only=True
    )
    realizado_por = UsuarioSerializer(read_only=True)
    tipo_disposicion_display = serializers.CharField(source='get_tipo_disposicion_display', read_only=True)

    class Meta:
        model = DisposicionActivo
        fields = '__all__'
        read_only_fields = ('realizado_por', 'fecha_creacion', 'tipo_disposicion_display')

    def create(self, validated_data):
        validated_data['realizado_por'] = self.context['request'].user
        return super().create(validated_data)

class SuscripcionSerializer(serializers.ModelSerializer):
    plan_display = serializers.CharField(source='get_plan_display', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    
    class Meta:
        model = Suscripcion
        fields = [
            'id', 'plan', 'estado', 'fecha_inicio', 'fecha_fin', 
            'max_usuarios', 'max_activos', 'plan_display', 'estado_display'
        ]
        read_only_fields = ('empresa',)

class NotificacionSerializer(serializers.ModelSerializer):
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    
    class Meta:
        model = Notificacion
        fields = [
            'id', 'timestamp', 'mensaje', 'tipo', 'leido', 
            'url_destino', 'tipo_display'
        ]

# --- Serializer para recibir FCM token ---
class FCMTokenSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(max_length=255)

# --- Serializer de Log (Tu versión está bien) ---
class LogSerializer(serializers.ModelSerializer):
    # Definimos el usuario anidado para que se muestre info útil al LEER logs (opcional)
    # Al escribir, el backend lo asignará automáticamente.
    usuario = UsuarioSerializer(read_only=True)

    class Meta:
        model = Log
        fields = [
            'id',             # ID del log
            'timestamp',      # Fecha y hora (automático)
            'usuario',        # Info del usuario (automático)
            'ip_address',     # IP (automático)
            'tenant_id',      # ID Empresa (automático)
            'accion',         # Acción enviada por frontend (Requerido)
            'payload',        # Datos JSON enviados por frontend (Opcional)
        ]
        # Campos que el frontend NO debe enviar, los pone el backend
        read_only_fields = ('id', 'timestamp', 'usuario', 'tenant_id')
        # Hacemos payload opcional al recibir datos
        extra_kwargs = {
            'accion': {'required': True},
            'payload': {'required': False, 'allow_null': True},
        }