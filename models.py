# api/models.py
import uuid
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

# --- [NUEVO] Funciones para rutas de subida de archivos (Aislamiento de Tenants) ---

def upload_path_perfil(instance, filename):
    """
    Guarda la foto de perfil en una carpeta específica del tenant.
    Ruta: /media/tenant_<empresa_id>/fotos_perfil/<filename>
    """
    return f'tenant_{instance.empresa.id}/fotos_perfil/{filename}'

def upload_path_activo(instance, filename):
    """
    Guarda la foto del activo en una carpeta específica del tenant.
    Ruta: /media/tenant_<empresa_id>/fotos_activos/<filename>
    """
    return f'tenant_{instance.empresa.id}/fotos_activos/{filename}'

# --- Modelos de Negocio (Base de datos: 'af_saas') ---

class Empresa(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=100, unique=True)
    nit = models.CharField(max_length=20, unique=True)
    direccion = models.CharField(max_length=255, blank=True)
    telefono = models.CharField(max_length=20, blank=True)
    email = models.EmailField(max_length=100, blank=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    def __str__(self): return self.nombre

class Departamento(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='departamentos')
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    class Meta: unique_together = ('empresa', 'nombre')
    def __str__(self): return f"{self.nombre} ({self.empresa.nombre})"

class Permisos(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=100, unique=True)
    descripcion = models.TextField()
    def __str__(self): return self.nombre

class Roles(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='roles')
    nombre = models.CharField(max_length=100)
    permisos = models.ManyToManyField(Permisos, blank=True)
    class Meta: unique_together = ('empresa', 'nombre')
    def __str__(self): return f"{self.nombre} ({self.empresa.nombre})"

class Cargo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='cargos')
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    class Meta: unique_together = ('empresa', 'nombre')
    def __str__(self): return f"{self.nombre} ({self.empresa.nombre})"

class Empleado(models.Model): # <-- [EDITADO]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.OneToOneField(User, on_delete=models.CASCADE)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='empleados')
    ci = models.CharField(max_length=20)
    apellido_p = models.CharField(max_length=100)
    apellido_m = models.CharField(max_length=100)
    direccion = models.CharField(max_length=255, blank=True)
    telefono = models.CharField(max_length=20, blank=True)
    sueldo = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    cargo = models.ForeignKey(Cargo, on_delete=models.SET_NULL, null=True, blank=True)
    departamento = models.ForeignKey(Departamento, on_delete=models.SET_NULL, null=True, blank=True)
    roles = models.ManyToManyField(Roles, blank=True)
    
    # --- [NUEVO] Campo de foto de perfil opcional ---
    foto_perfil = models.ImageField(upload_to=upload_path_perfil, null=True, blank=True)

    theme_preference = models.CharField(
        max_length=10,
        blank=True,         # Puede estar vacío
        null=True,          # Puede ser nulo en la BD
        default='dark'      # Valor por defecto si no se especifica
    )
    # Guardamos el color hexadecimal si el tema es 'custom'
    theme_custom_color = models.CharField(
        max_length=7,       # Formato '#RRGGBB'
        blank=True,
        null=True,
        default='#6366F1'   # Color índigo por defecto
    )
    # Guardamos si el efecto glow está activado
    theme_glow_enabled = models.BooleanField(default=False)
    # --- [FIN DE NUEVOS CAMPOS] ---

    def __str__(self):
        return f"{self.usuario.first_name} {self.apellido_p}"

class ActivoFijo(models.Model): # <-- [EDITADO]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='activos_fijos')
    nombre = models.CharField(max_length=100)
    codigo_interno = models.CharField(max_length=50)
    fecha_adquisicion = models.DateField()
    valor_actual = models.DecimalField(max_digits=12, decimal_places=2)
    vida_util = models.IntegerField() # En años
    departamento = models.ForeignKey(
        Departamento,
        on_delete=models.SET_NULL, # Si se borra el depto, el campo queda nulo
        null=True,    # Permite valores nulos en la BD
        blank=True,   # Permite que esté vacío en formularios
        related_name='activos' # Permite buscar activos desde un depto
    )
    categoria = models.ForeignKey('CategoriaActivo', on_delete=models.PROTECT)
    estado = models.ForeignKey('Estado', on_delete=models.PROTECT) # Ej: "En Uso", "En Mantenimiento", "De Baja"
    ubicacion = models.ForeignKey('Ubicacion', on_delete=models.PROTECT)
    proveedor = models.ForeignKey('Proveedor', on_delete=models.SET_NULL, null=True, blank=True)
    
    # --- [NUEVO] Campo de foto de activo opcional ---
    foto_activo = models.ImageField(upload_to=upload_path_activo, null=True, blank=True)
    
    class Meta: unique_together = ('empresa', 'codigo_interno')
    def __str__(self): return self.nombre

class CategoriaActivo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='categorias_activos')
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    def __str__(self): return self.nombre

class Estado(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='estados_activos')
    nombre = models.CharField(max_length=50) # Ej: "En Uso", "En Reparación", "Obsoleto"
    detalle = models.TextField(blank=True, null=True)
    def __str__(self): return self.nombre

class Ubicacion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='ubicaciones')
    nombre = models.CharField(max_length=100)
    direccion = models.CharField(max_length=255, blank=True, null=True)
    detalle = models.TextField(blank=True, null=True)
    def __str__(self): return self.nombre

class Proveedor(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='proveedores')
    nombre = models.CharField(max_length=100)
    nit = models.CharField(max_length=20)
    email = models.EmailField(max_length=100, blank=True, null=True)
    telefono = models.CharField(max_length=20, blank=True, null=True)
    pais = models.CharField(max_length=50, blank=True)
    direccion = models.CharField(max_length=255, blank=True, null=True)
    estado = models.CharField(max_length=20, default='activo')
    def __str__(self): return self.nombre

class Presupuesto(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='presupuestos')
    departamento = models.ForeignKey(Departamento, on_delete=models.CASCADE)
    monto = models.DecimalField(max_digits=15, decimal_places=2)
    fecha = models.DateField()
    descripcion = models.TextField(blank=True, null=True)
    def __str__(self): return f"Presupuesto {self.departamento.nombre} - {self.fecha}"

# --- [NUEVO] Modelo de Mantenimiento (Base de datos: 'af_saas') ---
class Mantenimiento(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='mantenimientos')
    activo = models.ForeignKey(ActivoFijo, on_delete=models.CASCADE, related_name='mantenimientos')
    empleado_asignado = models.ForeignKey(Empleado, on_delete=models.SET_NULL, null=True, blank=True, related_name='mantenimientos_asignados')
    
    TIPO_CHOICES = [('PREVENTIVO', 'Preventivo'), ('CORRECTIVO', 'Correctivo')]
    ESTADO_CHOICES = [('PENDIENTE', 'Pendiente'), ('EN_PROGRESO', 'En Progreso'), ('COMPLETADO', 'Completado')]
    
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='CORRECTIVO')
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='PENDIENTE')
    
    fecha_inicio = models.DateTimeField(auto_now_add=True)
    fecha_fin = models.DateTimeField(null=True, blank=True)
    descripcion_problema = models.TextField()
    notas_solucion = models.TextField(blank=True, null=True)
    costo = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    def __str__(self):
        return f"{self.get_tipo_display()} - {self.activo.nombre} ({self.get_estado_display()})"

# --- [NUEVO] Modelo de Suscripción (Base de datos: 'af_saas') ---
class Suscripcion(models.Model):
    PLAN_CHOICES = [
        ('basico', 'Básico'),
        ('profesional', 'Profesional'),
        ('empresarial', 'Empresarial'),
    ]
    ESTADO_CHOICES = [
        ('activa', 'Activa'),
        ('vencida', 'Vencida'),
        ('cancelada', 'Cancelada'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.OneToOneField(Empresa, on_delete=models.CASCADE, related_name='suscripcion')
    
    plan = models.CharField(max_length=20, choices=PLAN_CHOICES, default='basico')
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activa')
    
    fecha_inicio = models.DateField(default=timezone.now)
    fecha_fin = models.DateField() # Se calculará al crear
    
    # Límites del plan
    max_usuarios = models.PositiveIntegerField(default=5)
    max_activos = models.PositiveIntegerField(default=50)

    def __str__(self):
        return f"Suscripción {self.get_plan_display()} de {self.empresa.nombre} ({self.get_estado_display()})"

# --- [NUEVO] Modelo de Revalorización (Base de datos: 'af_saas') ---
class RevalorizacionActivo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='revalorizaciones')
    activo = models.ForeignKey(ActivoFijo, on_delete=models.CASCADE, related_name='revalorizaciones')
    
    fecha = models.DateTimeField(auto_now_add=True)
    valor_anterior = models.DecimalField(max_digits=12, decimal_places=2)
    valor_nuevo = models.DecimalField(max_digits=12, decimal_places=2)
    factor_aplicado = models.DecimalField(max_digits=10, decimal_places=6)
    notas = models.TextField(blank=True, null=True)
    
    realizado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        ordering = ['-fecha']

    def __str__(self):
        return f"Revalorización de {self.activo.nombre} en {self.fecha.strftime('%Y-%m-%d')}"


# --- [NUEVO] Modelo de Depreciación (Base de datos: 'af_saas') ---
class DepreciacionActivo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='depreciaciones')
    activo = models.ForeignKey(ActivoFijo, on_delete=models.CASCADE, related_name='depreciaciones')
    
    fecha = models.DateTimeField(auto_now_add=True)
    valor_anterior = models.DecimalField(max_digits=12, decimal_places=2)
    valor_nuevo = models.DecimalField(max_digits=12, decimal_places=2)
    monto_depreciado = models.DecimalField(max_digits=12, decimal_places=2)
    notas = models.TextField(blank=True, null=True)
    
    realizado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        ordering = ['-fecha']

    def __str__(self):
        return f"Depreciación de {self.activo.nombre} en {self.fecha.strftime('%Y-%m-%d')}"


# --- [NUEVO] Modelo de Notificación (Base de datos: 'af_saas') ---
class Notificacion(models.Model):
    TIPO_CHOICES = [
        ('ADVERTENCIA', 'Advertencia'),
        ('INFO', 'Info'),
        ('ERROR', 'Error'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    destinatario = models.ForeignKey(
        User,
        on_delete=models.CASCADE, # Si se borra el usuario, se borran sus notificaciones
        related_name='notificaciones'
    )
    #empresa = model.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='notificaciones')
    
    timestamp = models.DateTimeField(auto_now_add=True)
    mensaje = models.TextField()
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='INFO')
    leido = models.BooleanField(default=False)
    url_destino = models.CharField(max_length=255, blank=True, null=True) # Ej: '/app/suscripcion'

    class Meta:
        ordering = ['leido', '-timestamp']

    def __str__(self):
        return f"[{self.get_tipo_display()}] para {self.destinatario.username} (Leído: {self.leido})"

# --- Modelo de Log/Bitácora (Base de datos: 'log_saas') ---
class Log(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    usuario = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_constraint=False # No crea llave foránea entre bases de datos
    )
    ip_address = models.GenericIPAddressField()
    accion = models.CharField(max_length=255) # ej: "CREATE: ActivoFijo, ID: xxx"
    tenant_id = models.UUIDField(null=True, blank=True, db_index=True) # Guarda el ID de la empresa
    payload = models.JSONField(null=True, blank=True) # Guarda los datos de la petición
    
    class Meta:
        # Nombre explícito de la tabla en la base de datos 'log_saas'
        db_table = 'log_bitacora'

# --- [NUEVO] Modelo de Predicción de Mantenimiento (Base de datos: 'analytics_saas') ---
class PrediccionMantenimiento(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    tenant_id = models.UUIDField(db_index=True) # ID de la Empresa
    activo_id = models.UUIDField(db_index=True) # ID del ActivoFijo
    
    probabilidad_fallo = models.FloatField() # Probabilidad de fallo (0.0 a 1.0)
    dias_restantes_sugeridos = models.IntegerField(null=True, blank=True)
    razon = models.TextField(blank=True) # Explicación de la IA
    
    class Meta:
        ordering = ['-timestamp']
        db_table = 'prediccion_mantenimiento' # Nombre para la BD 'analytics_saas'

# --- [NUEVO] Modelo de Predicción de Presupuesto (Base de datos: 'analytics_saas') ---
class PrediccionPresupuesto(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    tenant_id = models.UUIDField(db_index=True) # ID de la Empresa
    departamento_id = models.UUIDField(db_index=True) # ID del Departamento
    
    monto_sugerido = models.DecimalField(max_digits=15, decimal_places=2)
    monto_anterior = models.DecimalField(max_digits=15, decimal_places=2)
    porcentaje_cambio = models.FloatField()
    razon = models.TextField(blank=True) # Explicación de la IA
    
    class Meta:
        ordering = ['-timestamp']
        db_table = 'prediccion_presupuesto' # Nombre para la BD 'analytics_saas'