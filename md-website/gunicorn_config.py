import os
from multiprocessing import cpu_count

workers = 2
max_requests = 100

ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
if ENVIRONMENT != "local":
    workers = cpu_count() * 2 + 1
    max_requests = 1000

bind = f"0.0.0.0:{os.getenv('PORT', '8500')}"
loglevel = "info"
accesslog = "-"
errorlog = "-"
