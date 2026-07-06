import os
import boto3
from botocore.config import Config

# ==========================================
# CONFIGURACIÓN DE CLOUDFLARE R2
# ==========================================
# Encuentras esta información en el panel de Cloudflare > R2 > Manage R2 API Tokens
ACCOUNT_ID = 'TU_ACCOUNT_ID_AQUI'
ACCESS_KEY_ID = 'TU_ACCESS_KEY_ID_AQUI'
SECRET_ACCESS_KEY = 'TU_SECRET_ACCESS_KEY_AQUI'
BUCKET_NAME = 'nombre-de-tu-bucket'

# Directorio local donde se guardarán los archivos descargados
DOWNLOAD_DIR = './descargas_bucket'
# ==========================================

def descargar_bucket():
    # 1. Crear el directorio de descargas si no existe
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)

    # 2. Inicializar el cliente S3 configurado para Cloudflare R2
    s3_client = boto3.client('s3',
        endpoint_url=f'https://{ACCOUNT_ID}.r2.cloudflarestorage.com',
        aws_access_key_id=ACCESS_KEY_ID,
        aws_secret_access_key=SECRET_ACCESS_KEY,
        config=Config(signature_version='s3v4'),
        region_name='auto' # Cloudflare R2 utiliza 'auto' como región
    )

    print(f"Conectando al bucket '{BUCKET_NAME}'...")

    try:
        # 3. Usar Paginator para manejar buckets con más de 1000 archivos
        paginator = s3_client.get_paginator('list_objects_v2')
        paginas = paginator.paginate(Bucket=BUCKET_NAME)

        archivos_descargados = 0

        for pagina in paginas:
            # Si el bucket está vacío, 'Contents' no existirá en la respuesta
            if 'Contents' not in pagina:
                print("El bucket está vacío.")
                return

            for obj in pagina['Contents']:
                file_key = obj['Key']
                
                # Opcional: Ignorar "carpetas" (objetos que terminan en /)
                if file_key.endswith('/'):
                    continue
                
                # Mantener la estructura de carpetas localmente
                ruta_local = os.path.join(DOWNLOAD_DIR, file_key)
                directorio_local = os.path.dirname(ruta_local)
                
                if not os.path.exists(directorio_local):
                    os.makedirs(directorio_local, exist_ok=True)

                print(f"Descargando: {file_key} ...", end=" ", flush=True)
                
                # Descargar el archivo
                s3_client.download_file(BUCKET_NAME, file_key, ruta_local)
                print("✓")
                archivos_descargados += 1

        print(f"\n¡Proceso completado! Se descargaron {archivos_descargados} archivos en el directorio '{DOWNLOAD_DIR}'.")

    except Exception as e:
        print(f"\nError al descargar archivos: {e}")

if __name__ == "__main__":
    descargar_bucket()
