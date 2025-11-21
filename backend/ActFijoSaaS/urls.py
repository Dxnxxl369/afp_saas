# ActFijoSaaS/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings # NUEVO: Importar settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')), # Incluye las URLs de tu app 'api'
]

# Sirve los archivos de MEDIA (fotos subidas) SOLO en modo DEBUG (DEBUG=True)
if settings.DEBUG: # NUEVO: Descomentar este bloque
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)