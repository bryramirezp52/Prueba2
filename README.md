# Instalación Nagios con Docker

## Prerrequisitos

| Recurso | Mínimo recomendado |
|---------|-------------------|
| Host | Ubuntu 22.04 (p.e. EC2 t2.small \| 2 vCPU \| 4 GiB RAM) |
| Docker Engine | 20.10 o superior |

**Nota:** no es necesario instalar Nagios ni Apache en el host; todo se encapsula dentro del contenedor.

## 1 - Clonar el repositorio

```bash
git clone https://github.com/<TU-USUARIO>/Prueba2.git
cd Prueba2
```

## 2 - Construir la imagen

```bash
# Etiquetamos la imagen como "nagios-prueba2:latest"
docker build -t nagios-prueba2:latest .
```

El Dockerfile ejecuta automáticamente:

- Descarga y compila Nagios Core 4.5.9 (`./configure && make && make install …`).
- Descarga y compila el paquete oficial nagios-plugins versión 2.4.11, que incluye los comandos básicos de monitoreo como `check_ping`, `check_http`, `check_disk`, entre otros.
- Crea las credenciales para la interfaz web:
  - **Usuario:** duoc
  - **Contraseña:** duoc123
- Limpia la caché de APT para reducir el tamaño final de la imagen.

## 3 - Ejecutar el contenedor

Publica el puerto 80 del contenedor en el puerto 80 del host y arráncalo en segundo plano:

```bash
docker run -d \
  -p 80:80 \
  --name nagios-test \
  nagios-prueba2:latest
```

Ahora abre tu navegador en:
```
http://<IP_DE_TU_HOST>/nagios
```

Inicia sesión con:
- **Usuario:** duoc
- **Contraseña:** duoc123

> **Nota:** Si tu servidor está en AWS EC2, asegúrate de que el Security Group permita tráfico entrante al puerto 80.

## 4 - Verificación y depuración

```bash
# Ver contenedores en ejecución
docker ps --filter name=nagios-test

# Procesos clave dentro del contenedor
docker exec -it nagios-test ps aux | grep -E "nagios|apache2"

# Logs en tiempo real
docker logs -f nagios-test
```

## 5 - Parar y eliminar (limpieza)

```bash
# Detener
docker stop nagios-test

# Eliminar contenedor
docker rm nagios-test

# (Opcional) eliminar imagen
docker rmi nagios-prueba2:latest
```


