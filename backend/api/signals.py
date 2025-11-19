# backend/api/signals.py
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import PartidaPresupuestaria, PeriodoPresupuestario
from django.db.models import Sum

@receiver(post_save, sender=PartidaPresupuestaria)
@receiver(post_delete, sender=PartidaPresupuestaria)
def update_periodo_monto_total(sender, instance, **kwargs):
    """
    Actualiza el monto_total del PeriodoPresupuestario cuando una PartidaPresupuestaria
    asociada es guardada o eliminada.
    """
    periodo = instance.periodo
    # Sumar todos los monto_asignado de las partidas de este período
    total_asignado = periodo.partidas.aggregate(Sum('monto_asignado'))['monto_asignado__sum'] or 0
    periodo.monto_total = total_asignado
    periodo.save(update_fields=['monto_total'])
