## Variables de Entorno

| Variable | Efecto Observable | Verificación |
|----------|-------------------|--------------|
| HOSTS | Define hosts a probar | echo $HOSTS |
| PORTS | Puertos a verificar | echo $PORTS |
| TIMEOUT_SEC | Timeout para nc | ss -ltnp |
