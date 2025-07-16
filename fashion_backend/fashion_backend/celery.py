import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fashion_backend.settings')
app = Celery('fashion_backend')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
