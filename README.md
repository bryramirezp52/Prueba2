# Instalación Nagios with Docker

## Prerrequisitos

| Recurso       | Mínimo recomendado                                |
|---------------|----------------------------------------------------|
| Host          | Ubuntu 22.04 (p.e. EC2 t2.small \| 2 vCPU \| 4 GiB RAM) |
| Docker Engine | 20.10 o superior                                   |

**Nota:** no es necesario instalar Nagios ni Apache en el host; todo se encapsula dentro del contenedor.

---

## 1 - Clonar el repositorio

```bash
git clone https://github.com/<TU-USUARIO>/Prueba2.git
cd Prueba2
```

## 2 - Construir la imagen

```bash
docker build -t nagios-prueba2:latest .
```

Esto realiza automáticamente:

- Descarga y compila Nagios Core 4.5.9.
- Instala Nagios Plugins 2.4.11 (check_ping, check_http, etc.).
- Configura credenciales para la interfaz web:
  - Usuario: duoc
  - Contraseña: duoc123
- Redirige la raíz / a /nagios/.
- Limpia la cache de paquetes para reducir tamaño.

## 3 - Ejecutar el contenedor

Publica el puerto 80 del contenedor en el puerto 8080 del host:

```bash
docker run -d \
  -p 8080:80 \
  --name nagios-test \
  nagios-prueba2:latest
```

## 4 - Acceder a la interfaz web

Abre tu navegador y accede a:

```
http://<IP_DE_TU_HOST>:8080/
```

La redirección automática te llevará a /nagios.

**Credenciales:**
- Usuario: duoc
- Contraseña: duoc123

🔐 Si estás en AWS EC2, asegúrate de que el Security Group permita tráfico entrante al puerto 8080.

## 5 - Verificación y depuración

```bash
# Ver contenedores activos
docker ps --filter name=nagios-test

# Procesos clave dentro del contenedor
docker exec -it nagios-test ps aux | grep -E "nagios|apache2"

# Logs en tiempo real
docker logs -f nagios-test
```

## 6 - Parar y eliminar (limpieza)

```bash
# Detener el contenedor
docker stop nagios-test

# Eliminar contenedor
docker rm nagios-test

# (Opcional) eliminar imagen
docker rmi nagios-prueba2:latest
```

---
