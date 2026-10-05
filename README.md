# Ejercicio 1V2: S3 básico con floci

Práctica de aprendizaje AWS para DevOps. Todo se ejecuta **localmente** con [floci](https://floci.io), un emulador de AWS, así que no requiere cuenta de AWS ni genera costos.

## Objetivo

Entender qué es un bucket de S3 y operar con él desde la línea de comandos: crearlo, subir un archivo, listarlo y descargarlo.

## Conceptos

| Concepto | Qué es |
|---|---|
| **S3** | Servicio de AWS para almacenar archivos |
| **Bucket** | Contenedor con nombre único donde se guardan los objetos |
| **Objeto** | Un archivo guardado en un bucket |
| **Key** | Nombre completo de un objeto (por ejemplo `logs/prueba.txt`). Las "carpetas" son solo prefijos dentro de la key |
| **Endpoint** | Dirección a la que el AWS CLI envía las peticiones. Aquí apunta a floci en vez de a AWS real |

## Requisitos

- Windows 11 con PowerShell
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) en ejecución
- [AWS CLI v2](https://aws.amazon.com/cli/) (`winget install Amazon.AWSCLI`)
- floci corriendo en `localhost:4566`

## Cómo ejecutarlo

1. Levanta floci (si no lo tienes corriendo):

   ```powershell
   docker run -d -p 4566:4566 --name floci floci/floci:latest
   ```

2. Ejecuta el script desde esta carpeta:

   ```powershell
   .\crear-bucket.ps1
   ```

   Si PowerShell bloquea la ejecución de scripts:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

### Parámetros opcionales

```powershell
.\crear-bucket.ps1 -Bucket demo-bucket   # otro nombre de bucket
.\crear-bucket.ps1 -Endpoint http://localhost:4566
.\crear-bucket.ps1 -Limpiar              # borra todo al terminar
```

## Qué hace el script

1. Configura variables de entorno para que el AWS CLI apunte a floci (con credenciales de prueba).
2. Verifica la conexión con `aws s3 ls`.
3. Crea el bucket con `aws s3 mb` (si no existe).
4. Sube un archivo con `aws s3 cp`.
5. Lista el contenido del bucket.
6. Descarga el objeto y muestra su contenido.

## Flujo

### Arquitectura

El AWS CLI no habla con AWS real: el endpoint lo redirige a floci, que corre en local.

```
┌──────────────────┐                       ┌─────────────────────────┐
│  PowerShell      │   AWS_ENDPOINT_URL    │  floci                  │
│  + AWS CLI       │ ────────────────────► │  (emulador de AWS)      │
│  crear-bucket.ps1│ ◄──────────────────── │  puerto 4566            │
└──────────────────┘                       └─────────────────────────┘
```

### Pasos del script

```
PASO 0 ─ Configurar el entorno
  AWS_ENDPOINT_URL = http://localhost:4566
  AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY = test
            │
            ▼
PASO 1 ─ Verificar conexión
  aws s3 ls  ──►  floci responde (lista vacía = OK)
            │
            ▼
PASO 2 ─ Crear bucket
  aws s3 mb s3://mi-primer-bucket
            │
            ▼
PASO 3 ─ Subir archivo
  "hola devops"
        │
        ▼
   prueba.txt ── aws s3 cp ──►  S3 Bucket
                                 └── prueba.txt
            │
            ▼
PASO 4 ─ Listar contenido
  aws s3 ls --recursive  ──►  verificamos que prueba.txt existe
            │
            ▼
PASO 5 ─ Descargar y comprobar
  S3/prueba.txt ── aws s3 cp ──► descargado.txt ── Get-Content ──► "hola devops"
            │
            ▼
OPCIONAL (-Limpiar)
  aws s3 rm --recursive ──► aws s3 rb ──► Remove-Item
```

## Problemas frecuentes

**`InvalidAccessKeyId ... does not exist in our records`**
El AWS CLI está hablando con AWS real, no con floci. Falta configurar `AWS_ENDPOINT_URL` en esa ventana de PowerShell (las variables `$env:` solo duran mientras la ventana está abierta). Ejecutar el script las configura automáticamente.

**`aws s3 ls` no muestra nada**
Es lo esperado si todavía no hay buckets.

**No conecta con `localhost:4566`**
Comprueba con `docker ps` que el contenedor de floci está corriendo y publicando el puerto 4566.

## Seguridad

Las credenciales `test` / `test` son valores falsos que solo sirven para floci. Nunca subas credenciales reales de AWS al repositorio.

## Siguiente práctica

IAM: crear un usuario y una política de solo lectura sobre un bucket.
