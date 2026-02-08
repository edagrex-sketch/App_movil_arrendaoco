# Guía de Integración Thunder Client (APIs Locales)

Hemos generado una colección de **Thunder Client** para facilitar las pruebas de tus APIs locales de Supabase (Base de datos y Edge Functions).

## 1. Requisitos Previos

Para que las APIs locales funcionen, necesitas tener corriendo Supabase en tu máquina local. Esto requiere **Docker**.

1. Asegúrate de tener Docker Desktop instalado y corriendo.
2. Inicia Supabase localmente (si no lo has hecho):
   ```bash
   npx supabase start
   ```
   *(Si tienes problemas con Docker, revisa la instalación de Docker Desktop).*

## 2. Obtener Credenciales

Cuando `npx supabase start` termine, verás un output similar a este:

```text
API URL:         http://127.0.0.1:54321
GraphQL URL:     http://127.0.0.1:54321/graphql/v1
DB URL:          postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL:      http://127.0.0.1:54323
Inbucket URL:    http://127.0.0.1:54324
anon key:        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Copia el valor de `API URL` y `anon key`.

## 3. Importar Colección en Thunder Client

1. Abre la extensión **Thunder Client** en VS Code.
2. Ve a la pestaña **Collections**.
3. Haz clic en el menú (tres líneas) > **Import**.
4. Selecciona el archivo generado: `thunder-collection_arrendaoco_local.json`.

## 4. Configurar Entorno (Environment)

Para no pegar las claves en cada petición, usa un Environment:

1. En Thunder Client, ve a la pestaña **Env**.
2. Crea un nuevo entorno llamado `Supabase Local`.
3. Añade las siguientes variables:
   - `base_url`: `http://127.0.0.1:54321` (O la que te dio el comando start)
   - `anon_key`: `PEGAR_TU_ANON_KEY_AQUI`
4. Guarda y asegúrate de que este entorno esté **activo** (estrella o check verde).

## 5. Probar Endpoints

- **Get All Properties**: Debería devolver la lista de inmuebles en tu BD local.
- **Invoke Push Notification**: Envía una petición a tu Edge Function local `push-notification`.
  - **Importante**: En el `Body` de esta petición, asegúrate de cambiar `"usuario_id": "INSERT_TARGET_USER_UUID_HERE"` por un ID de un usuario real que exista en tu tabla `usuarios` local y tenga un token FCM válido, si quieres probar el envío real.
