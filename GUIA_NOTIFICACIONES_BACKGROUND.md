
# 🔔 Activar Notificaciones Push Reales (Tipo WhatsApp) con Supabase y Firebase

Como agente de IA, he configurado tu aplicación Flutter para que esté lista para recibir notificaciones en segundo plano, también conocidas como notificaciones background ("tipo WhatsApp").

Sin embargo, para que **Supabase** (tu base de datos) pueda "despertar" el teléfono a través de **Google Firebase (FCM)**, necesitas desplegar un pequeño código en tu nube de Supabase.

Por favor, sigue estos pasos:

## 1. Obtener Credenciales de Firebase

1.  Ve a tu **Consola de Firebase** > Configuración del proyecto > **Cuentas de servicio**.
2.  Haz clic en **Generar nueva clave privada**.
3.  Se descargará un archivo `.json`. Guárdalo, lo usaremos pronto.

## 2. Crear Función en Supabase (Edge Function)

Si tienes la CLI de Supabase instalada, puedes hacerlo localmente. Si no, usa el dashboard (si está disponible para Edge Functions) o sigue la guía de Supabase. La función debe llamarse `push-notification`.

El código de la función (`index.ts`) debe ser este:

```typescript
// index.ts para Supabase Edge Function: push-notification

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as admin from "https://esm.sh/firebase-admin@11.10.1";

// ⚠️ PEGA AQUÍ EL CONTENIDO DE TU JSON DE FIREBASE (Service Account)
const serviceAccount = {
  "type": "service_account",
  "project_id": "TU_PROJECT_ID",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY----- ...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
};

// Inicializar Firebase Admin una sola vez
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

serve(async (req) => {
  try {
    const { record } = await req.json(); // Supabase envía el registro insertado aquí

    // 1. Obtener el ID del usuario destino desde la notificación insertada
    const usuarioDestinoId = record.usuario_id;
    const titulo = record.titulo;
    const cuerpo = record.mensaje;

    if (!usuarioDestinoId) {
        return new Response("No user ID", { status: 400 });
    }

    // 2. Buscar el token FCM de ese usuario en tu base de datos
    // Nota: Necesitas la URL y KEY de tu Supabase pasadas como variables de entorno o hardcodeadas
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    
    // Hacemos una petición simple a tu BD para obtener el token del usuario
    const userQuery = await fetch(`${supabaseUrl}/rest/v1/usuarios?id=eq.${usuarioDestinoId}&select=fcm_token`, {
        headers: {
            "apikey": supabaseKey,
            "Authorization": `Bearer ${supabaseKey}`
        }
    });
    
    const userData = await userQuery.json();
    const fcmToken = userData[0]?.fcm_token;

    if (!fcmToken) {
        return new Response("User has no FCM Token", { status: 200 });
    }

    // 3. Enviar la notificación a través de Firebase
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: titulo,
        body: cuerpo,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK", // Para que Flutter la abra
        usuario_id: String(usuarioDestinoId),
        tipo: record.tipo
      },
      android: {
          priority: "high", // Importante para despertar
      },
      apns: {
          payload: {
              aps: {
                  contentAvailable: true, // Para iOS background wake
              }
          }
      }
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
```

## 3. Crear Webhook en Supabase

Esta es la parte mágica que conecta la BD con la función anterior:

1.  Ve a tu **Supabase Dashboard** > **Database** > **Webhooks**.
2.  Crea un nuevo Webhook llamado: `enviar-push`.
3.  **Table**: Selecciona `notificaciones`.
4.  **Events**: Marca solo `INSERT`.
5.  **Type**: Selecciona `HTTP Request` (o Supabase Edge Function si te aparece).
6.  **URL**: Pega la URL de tu función desplegada (ej: `https://<ref>.supabase.co/functions/v1/push-notification`).
7.  **Method**: `POST`.
8.  En **Headers**, añade: `Authorization: Bearer <TU_SERVICE_ROLE_KEY>`.

---

¡Eso es todo! Con esto configurado:
1.  Tu App Flutter inserta en la tabla `notificaciones`.
2.  El Webhook de Supabase se dispara y llama a tu Edge Function.
3.  Tu Edge Function busca el token del usuario y llama a Firebase.
4.  Firebase despierta el teléfono del usuario con la notificación.
