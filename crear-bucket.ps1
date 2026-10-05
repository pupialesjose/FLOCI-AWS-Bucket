<#
.SYNOPSIS
    EJERCICIO 1V2 - S3 basico contra floci (emulador local de AWS).
 
.DESCRIPTION
    Configura el AWS CLI para apuntar a floci, crea un bucket, sube un archivo,
    lo lista y lo descarga de nuevo. Con -Limpiar borra todo al final.
 
.PARAMETER Endpoint
    URL donde escucha floci. Por defecto http://localhost:4566
 
.PARAMETER Bucket
    Nombre del bucket a crear. Por defecto mi-primer-bucket.
 
.PARAMETER Limpiar
    Si se indica, elimina el objeto, el bucket y los archivos locales al terminar.
 
.EXAMPLE
    .\crear-bucket.ps1
 
.EXAMPLE
    .\crear-bucket.ps1 -Bucket demo-bucket -Limpiar
#>
param(
    [string]$Endpoint = "http://localhost:4566",
    [string]$Bucket   = "mi-bucket",
    [switch]$Limpiar
)
 
$ErrorActionPreference = "Stop"
 
# Ejecuta aws y detiene el script si el comando falla
function Invoke-Aws {
    & aws @args
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo el comando: aws $args"
    }
}
 
# --- Paso 0: apuntar el AWS CLI a floci (credenciales falsas, solo para el emulador) ---
$env:AWS_ENDPOINT_URL      = $Endpoint
$env:AWS_ACCESS_KEY_ID     = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION    = "us-east-1"
 
Write-Host "== Ejercicio 1V2: S3 con floci ==" -ForegroundColor Cyan
Write-Host "Endpoint: $Endpoint | Bucket: $Bucket"
 
# --- Paso 1: verificar que floci responde ---
Write-Host "`n[1/5] Verificando conexion con floci..." -ForegroundColor Yellow
Invoke-Aws s3 ls
 
# --- Paso 2: crear el bucket (si no existe) ---
Write-Host "`n[2/5] Creando bucket '$Bucket'..." -ForegroundColor Yellow
$existe = (& aws s3 ls) -match "\s$([regex]::Escape($Bucket))$"
if ($existe) {
    Write-Host "El bucket ya existe, se reutiliza."
} else {
    Invoke-Aws s3 mb "s3://$Bucket"
}
 
# --- Paso 3: subir un archivo ---
Write-Host "`n[3/5] Subiendo archivo..." -ForegroundColor Yellow
$archivoLocal = Join-Path $env:TEMP "prueba.txt"
"hola devops" | Out-File $archivoLocal -Encoding ascii
Invoke-Aws s3 cp $archivoLocal "s3://$Bucket/prueba.txt"
 
# --- Paso 4: listar el contenido del bucket ---
Write-Host "`n[4/5] Contenido del bucket:" -ForegroundColor Yellow
Invoke-Aws s3 ls "s3://$Bucket/" --recursive
 
# --- Paso 5: descargar el objeto y comprobar su contenido ---
Write-Host "`n[5/5] Descargando objeto..." -ForegroundColor Yellow
$archivoDescargado = Join-Path $env:TEMP "descargado.txt"
Invoke-Aws s3 cp "s3://$Bucket/prueba.txt" $archivoDescargado
Write-Host "Contenido descargado: $(Get-Content $archivoDescargado)"
 
# --- Limpieza opcional ---
if ($Limpiar) {
    Write-Host "`nLimpiando recursos..." -ForegroundColor Yellow
    Invoke-Aws s3 rm "s3://$Bucket" --recursive
    Invoke-Aws s3 rb "s3://$Bucket"
    Remove-Item $archivoLocal, $archivoDescargado -ErrorAction SilentlyContinue
    Write-Host "Recursos eliminados."
}
 
Write-Host "`nPractica completada." -ForegroundColor Green
 