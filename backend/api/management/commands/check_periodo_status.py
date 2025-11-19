# backend/api/management/commands/check_periodo_status.py
from django.core.management.base import BaseCommand
from django.utils import timezone
from api.models import PeriodoPresupuestario

class Command(BaseCommand):
    help = 'Checks active budget periods and closes those whose end date has passed.'

    def handle(self, *args, **kwargs):
        self.stdout.write("Checking budget period statuses...")
        
        today = timezone.localdate() # Get today's date in local timezone

        # Find active periods whose end date is in the past
        periods_to_close = PeriodoPresupuestario.objects.filter(
            estado='ACTIVO',
            fecha_fin__lt=today # fecha_fin is less than today
        )

        if periods_to_close.exists():
            for periodo in periods_to_close:
                periodo.estado = 'CERRADO'
                periodo.save(update_fields=['estado'])
                self.stdout.write(self.style.SUCCESS(
                    f"Periodo '{periodo.nombre}' (ID: {periodo.id}) closed successfully."
                ))
            self.stdout.write(self.style.SUCCESS(
                f"Successfully closed {periods_to_close.count()} budget periods."
            ))
        else:
            self.stdout.write("No active budget periods found to close.")
