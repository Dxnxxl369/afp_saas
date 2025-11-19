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

def upload_path_mantenimiento(instance, filename):
    """
    Guarda la foto de mantenimiento en una carpeta específica del tenant.
    Ruta: /media/tenant_<empresa_id>/fotos_mantenimientos/<filename>
    """
    return f'tenant_{instance.mantenimiento.empresa.id}/fotos_mantenimientos/{filename}'

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
    orden_compra = models.OneToOneField('OrdenCompra', on_delete=models.SET_NULL, null=True, blank=True, related_name='activo_creado')
    
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

# --- [NUEVO] Modelos para Flujo de Adquisición ---
class SolicitudCompra(models.Model):
    ESTADO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('APROBADA', 'Aprobada'),
        ('RECHAZADA', 'Rechazada'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='solicitudes_compra')
    solicitante = models.ForeignKey(User, on_delete=models.PROTECT, related_name='solicitudes_creadas')
    departamento = models.ForeignKey(Departamento, on_delete=models.PROTECT)
    descripcion = models.TextField()
    costo_estimado = models.DecimalField(max_digits=15, decimal_places=2)
    justificacion = models.TextField()
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='PENDIENTE')
    fecha_solicitud = models.DateTimeField(auto_now_add=True)
    fecha_decision = models.DateTimeField(null=True, blank=True)
    decision_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='solicitudes_decididas')
    motivo_rechazo = models.TextField(blank=True, null=True)
    partida_presupuestaria = models.ForeignKey(
        'PartidaPresupuestaria', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='solicitudes'
    )

    class Meta:
        ordering = ['-fecha_solicitud']

    def __str__(self):
        return f"Solicitud de {self.departamento.nombre} - {self.estado}"

class OrdenCompra(models.Model):
    ESTADO_CHOICES = [
        ('GENERADA', 'Generada'),
        ('ENVIADA', 'Enviada'),
        ('COMPLETADA', 'Completada'),
        ('CANCELADA', 'Cancelada'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    solicitud = models.OneToOneField(SolicitudCompra, on_delete=models.PROTECT, related_name='orden_compra')
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='ordenes_compra')
    proveedor = models.ForeignKey(Proveedor, on_delete=models.PROTECT)
    precio_final = models.DecimalField(max_digits=15, decimal_places=2)
    fecha_orden = models.DateTimeField(auto_now_add=True)
    fecha_entrega_estimada = models.DateField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='GENERADA')
    creado_por = models.ForeignKey(User, on_delete=models.PROTECT, related_name='ordenes_creadas')

    class Meta:
        ordering = ['-fecha_orden']

    def __str__(self):
        return f"Orden de Compra a {self.proveedor.nombre} - {self.estado}"


# --- [NUEVO] Modelos para Módulo de Presupuesto ---

class PeriodoPresupuestario(models.Model):
    ESTADO_CHOICES = [
        ('PLANIFICACION', 'Planificación'),
        ('ACTIVO', 'Activo'),
        ('CERRADO', 'Cerrado'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='periodos_presupuestarios')
    nombre = models.CharField(max_length=150)
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField()
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='PLANIFICACION')
    monto_total = models.DecimalField(max_digits=15, decimal_places=2, default=0, help_text="Calculado automáticamente a partir de las partidas")

    class Meta:
        unique_together = ('empresa', 'nombre')
        ordering = ['-fecha_inicio']

    def __str__(self):
        return self.nombre

class PartidaPresupuestaria(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    periodo = models.ForeignKey(PeriodoPresupuestario, on_delete=models.CASCADE, related_name='partidas')
    departamento = models.ForeignKey(Departamento, on_delete=models.CASCADE, related_name='partidas_presupuestarias')
    nombre = models.CharField(max_length=150)
    codigo = models.CharField(max_length=50, blank=True, null=True)
    monto_asignado = models.DecimalField(max_digits=15, decimal_places=2)
    monto_gastado = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    @property
    def monto_disponible(self):
        return self.monto_asignado - self.monto_gastado

    class Meta:
        unique_together = ('periodo', 'departamento', 'nombre')
        ordering = ['codigo', 'nombre']

    def __str__(self):
        return f"{self.nombre} ({self.departamento.nombre}) - {self.periodo.nombre}"

class MovimientoPresupuestario(models.Model):
    TIPO_CHOICES = [
        ('GASTO', 'Gasto'),
        ('AJUSTE_POSITIVO', 'Ajuste Positivo'),
        ('AJUSTE_NEGATIVO', 'Ajuste Negativo'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    partida = models.ForeignKey(PartidaPresupuestaria, on_delete=models.CASCADE, related_name='movimientos')
    orden_compra = models.ForeignKey(OrdenCompra, on_delete=models.SET_NULL, null=True, blank=True, related_name='movimientos_presupuestarios')
    monto = models.DecimalField(max_digits=15, decimal_places=2)
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='GASTO')
    fecha = models.DateTimeField(auto_now_add=True)
    descripcion = models.TextField()
    realizado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        ordering = ['-fecha']

    def __str__(self):
        return f"{self.get_tipo_display()} de {self.monto} en {self.partida.nombre}"


# --- Modelo de Mantenimiento (Base de datos: 'af_saas') ---
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

class MantenimientoFoto(models.Model):
    TIPO_FOTO_CHOICES = [
        ('PROBLEMA', 'Problema'),
        ('SOLUCION', 'Solución'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    mantenimiento = models.ForeignKey(Mantenimiento, related_name='fotos', on_delete=models.CASCADE)
    foto = models.ImageField(upload_to=upload_path_mantenimiento)
    subido_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='fotos_subidas')
    tipo = models.CharField(max_length=20, choices=TIPO_FOTO_CHOICES, default='PROBLEMA')
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Foto de {self.mantenimiento.id} ({self.get_tipo_display()})"

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
    DEPRECIATION_TYPE_CHOICES = [
        ('STRAIGHT_LINE', 'Línea Recta'),
        ('DECLINING_BALANCE', 'Saldo Decreciente'),
        ('UNITS_OF_PRODUCTION', 'Unidades de Producción'),
        ('MANUAL', 'Manual'), # Para la depreciación simple existente
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='depreciaciones')
    activo = models.ForeignKey(ActivoFijo, on_delete=models.CASCADE, related_name='depreciaciones')
    
    fecha = models.DateTimeField(auto_now_add=True)
    valor_anterior = models.DecimalField(max_digits=12, decimal_places=2)
    valor_nuevo = models.DecimalField(max_digits=12, decimal_places=2)
    monto_depreciado = models.DecimalField(max_digits=12, decimal_places=2)
    depreciation_type = models.CharField(max_length=20, choices=DEPRECIATION_TYPE_CHOICES, default='MANUAL') # Nuevo campo
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

# --- [NUEVO] Modelo de Disposición de Activos ---
class DisposicionActivo(models.Model):
    TIPO_DISPOSICION_CHOICES = [
        ('VENTA', 'Venta'),
        ('BAJA', 'Baja por Obsolescencia/Daño'),
        ('DONACION', 'Donación'),
        ('ROBO', 'Robo/Pérdida'),
        ('OTRO', 'Otro')
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='disposiciones_activos')
    activo = models.ForeignKey(ActivoFijo, on_delete=models.PROTECT, related_name='disposiciones') # PROTECT para mantener historial
    tipo_disposicion = models.CharField(max_length=50, choices=TIPO_DISPOSICION_CHOICES)
    fecha_disposicion = models.DateField(default=timezone.now)
    valor_venta = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    razon = models.TextField(blank=True, null=True)
    realizado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Disposición de Activo"
        verbose_name_plural = "Disposiciones de Activos"
        ordering = ['-fecha_disposicion']

    def __str__(self):
        return f"Disposición de {self.activo.nombre} ({self.get_tipo_disposicion_display()}) por {self.realizado_por.username if self.realizado_por else 'N/A'}"

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