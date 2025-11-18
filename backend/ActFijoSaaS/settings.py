# ActFijoSaaS/settings.py
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-tu-clave-secreta-aqui' # ¡Cambia esto en producción!
DEBUG = True

ALLOWED_HOSTS = ['*'] # Permite todas las conexiones en desarrollo

# --- APLICACIONES INSTALADAS ---
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # --- LIBRERÍAS DE TERCEROS ---
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    # --- NUESTRA APP ---
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware', # Middleware de CORS
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'ActFijoSaaS.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ActFijoSaaS.wsgi.application'

# --- CONFIGURACIÓN DE BASE DE DATOS (POSTGRESQL) ---
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'af_saas',
        'USER': 'postgres',          # El usuario que creaste en SQL
        'PASSWORD': 'admin123', # La que definiste en SQL
        'HOST': 'localhost',
        'PORT': '5432',
    },
    'log_saas': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'log_saas', # El nombre de la BD que creaste en el Paso 1
        'USER': 'postgres',   # Puedes usar el mismo usuario por ahora
        'PASSWORD': 'admin123',
        'HOST': 'localhost',
        'PORT': '5432',
    },
    'analytics_saas': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'analytics_saas', # Asegúrate de crear esta BD en PostgreSQL
        'USER': 'postgres',
        'PASSWORD': 'admin123',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# ... (Validadores de contraseña sin cambios)

# --- CONFIGURACIÓN DE INTERNACIONALIZACIÓN ---
LANGUAGE_CODE = 'es-es'
TIME_ZONE = 'America/La_Paz'
USE_I18N = True
USE_TZ = True

# --- CONFIGURACIÓN DE ARCHIVOS ESTÁTICOS ---
DATABASE_ROUTERS = ['api.db_router.AnalyticsRouter']
STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
MEDIA_URL = '/media/'
# Ruta en el servidor donde se guardarán los archivos
MEDIA_ROOT = BASE_DIR / 'mediafiles'

...


# --- CONFIGURACIÓN DE DJANGO REST FRAMEWORK (JWT) ---
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20
}

# --- CONFIGURACIÓN DE CORS (PERMISOS PARA EL FRONTEND) ---
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173", # Para React en desarrollo
    "http://127.0.0.1:5173",
    "http://localhost:5174", # Para React en desarrollo
    "http://127.0.0.1:5174",
]
CORS_ALLOW_ALL_ORIGINS = False # Mantenlo en False por seguridad
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]
CORS_ALLOW_HEADERS = [
    "accept",
    "authorization",
    "content-type",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

SIMPLE_JWT = {
    # Duración del token de acceso (ej: 1 hora en desarrollo)
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60), 
    # Duración del token de refresco (ej: 1 día)
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1), 
    
    # --- Opciones estándar (generalmente no necesitas cambiarlas) ---
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
    "UPDATE_LAST_LOGIN": False,

    "ALGORITHM": "HS256",
    "SIGNING_KEY": SECRET_KEY, # Usa la SECRET_KEY de Django
    "VERIFYING_KEY": "",
    "AUDIENCE": None,
    "ISSUER": None,
    "JSON_ENCODER": None,
    "JWK_URL": None,
    "LEEWAY": 0,

    "AUTH_HEADER_TYPES": ("Bearer",),
    "AUTH_HEADER_NAME": "HTTP_AUTHORIZATION",
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "USER_AUTHENTICATION_RULE": "rest_framework_simplejwt.authentication.default_user_authentication_rule",

    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    "TOKEN_TYPE_CLAIM": "token_type",
    "TOKEN_USER_CLASS": "rest_framework_simplejwt.models.TokenUser",

    "JTI_CLAIM": "jti",

    "SLIDING_TOKEN_REFRESH_EXP_CLAIM": "refresh_exp",
    "SLIDING_TOKEN_LIFETIME": timedelta(minutes=5), # No relevante si no usas sliding tokens
    "SLIDING_TOKEN_REFRESH_LIFETIME": timedelta(days=1), # No relevante si no usas sliding tokens

    # --- IMPORTANTE: Apunta a tu serializer personalizado ---
    "TOKEN_OBTAIN_SERIALIZER": "api.serializers.MyTokenObtainPairSerializer", 
}

