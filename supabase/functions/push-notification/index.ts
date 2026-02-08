import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// Usamos 'npm:' para máxima compatibilidad al desplegar
import { createClient } from "npm:@supabase/supabase-js@2";
import admin from "npm:firebase-admin@11";

// ⚠️ CREDENCIALES
const serviceAccount = {
  "type": "service_account",
  "project_id": "arrendaoco-fad79",
  "private_key_id": "f46574eab517261d4b9965a89f9b9749a14983c7",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCrpLq1IJq6mZwW\nXTnKbYRvpVD0aSOJ74ajnnfDRecsUdQJmzqoj5rXx7MZjMjCym5IyqOF1jVFTvZx\njqAx7l80m01MODOWETmOjRs7hWEkvmmb7CxZVoz90SIZW8bgZog12B1aIKWJdiQM\nADvCy+3uC4NBHRojMK9CEdLtEKmB3J+dLeGJ2loaOMj3ao9HxSXRkLlydN9n8zkD\nCJ0gvSfGsMhvlT23ffiHMXymGuF2FbA5J6Ig+J/5lCampWEtgr8+WLSGsrr/6/ib\nzz4tlnSR1fcXa8pquviQ/1TfzGY668OLRY/uV9Hx1SA/dymC14t2PDbYcO3sbQpl\nyoahpJrDAgMBAAECggEAQh9oqeRQlzgb8GWjoL8F+PinsjBat4WlyZx/qKNiRimT\n1MuPEmaYES5maZ5ZrOjNCY++5Q07YmLj/6UhQ3sABEUbxxQTk2k5Uhg7+HcOkFgm\nWSHnh9cW46TQTRKVD9eP+6Yw0IqpGsZ/ZnwkiYuEMmMPAmOSsSHNMlepeRglJNhW\nxpV3SHiaIrvE0roji9co3H3vMUBEn2f1xDtA9C4V4exg9MJBKerCufbo8i0BuXEP\nmvSxCvcGKv/1CJFhGN74MNHtTkcKHxmMvgYkJnP5GYvLyxB3OltwhhnH3N9UwSBi\n0xNOBMSUoJVqG5tbruVqOxGJV6ggIyF8LhMXYFRN4QKBgQDSh+TSgCEn2lqLExCJ\n7SAqdq4MgW0Kw9bmLxBYLGhAnqhk2NENhyCsvQYGyCtfHfXuDIF4a8vKe9JNpg5R\nSyM/TICgBUptbHQR2ElDoBFX5v4Ci21C9obj97I4mBVk1JLjU7CjMM95a8MRyPHW\nLj7vSnuiOvAsAl3gYIZpXfE+kQKBgQDQtseirKQcBQSA+NWfXjTecJY0STOn/RTm\nQk+kbTKo/8uaHpZL1A1jRCU0fqHEp3M1bv2raNy3yAUdaQvbGp4xk4CC5+B/E8VU\npz6c59Lt8qzTwY9vLlVUg8gLxqnWbsg2KFSEA/z1uDtWvUgowDLqoL9zal+NOaaH\nOFkEntSWEwKBgQCHdQZGZkhu8vAk4XxXsilrCPdNdozpSz5e1lNG2DOvuCWS1WoU\nsSfV3L0e6fX1+jn9EzDOgVUbD/YtHbXCmnywQpHT4/OSWiCIRshE6Z2fGDHBA2Km\nniYGUZ3rCfdh6+Aiwfs51LL5ZduZ+teXPiQiJKNNq2xSdKdgMdrpupb48QKBgBQW\nw7hgrZsU0I4pZUZlpukSJSL7OMGelnhjQY8uA4ZIuKwo7YZ27qLzWDFpTuDCzVAD\nUt9AxJ3b3sIp7j40na1f6SqwbudMW93+CwTHO4IzrXbkVo35A7WSyZp4kLhXCWZN\nE3VxfNOZ2/xJU7y4Yy46MrNFNdU+C01QmyDauNOJAoGBAKYZfbNz7428YVE1dXwi\nYEBVEeSkqw3so8qyjTAzO3+l+G0EpOUfYPMtstUOChNZkdw896IhlLL9L5mzzJd1\nZPdDlfeG7OS5S+ajT8zRTz+9J53iO+9Eb0x7sZkhKVLEoH32g98FSxaLGU66rBVU\n/8aoibo4tEH/Ena8Xee04LxM\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@arrendaoco-fad79.iam.gserviceaccount.com",
  "client_id": "106859607222156673622",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40arrendaoco-fad79.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
} as admin.ServiceAccount;

// Inicializar Firebase
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (e) {
    console.error("Error inicializando firebase:", e);
  }
}

console.log("Función Edge 'push-notification' inicializada!");

serve(async (req) => {
  try {
    const { record } = await req.json();

    const usuarioDestinoId = record.usuario_id;
    const titulo = record.titulo || "Nueva notificación";
    const cuerpo = record.mensaje || "Tienes un nuevo mensaje";

    if (!usuarioDestinoId) {
      return new Response("Falta ID de usuario para enviar", { status: 400 });
    }

    // Usar variables de entorno de Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseAnonKey);

    // Buscar token del usuario
    const { data: userData, error } = await supabase
      .from('usuarios')
      .select('fcm_token')
      .eq('id', usuarioDestinoId)
      .single();

    if (error || !userData || !userData.fcm_token) {
      console.log(`El usuario ${usuarioDestinoId} no tiene token FCM registrado.`);
      return new Response("Usuario sin token FCM", { status: 200 });
    }

    const fcmToken = userData.fcm_token;

    // Enviar notificación a través de Firebase (FCM)
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: titulo,
        body: cuerpo,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        usuario_id: String(usuarioDestinoId),
        tipo: record.tipo || 'general',
      },
      android: {
        priority: "high",
        notification: {
          priority: 'max',
          channelId: 'arrendaoco_high_importance'
        }
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true
          }
        }
      }
    });

    console.log("¡Notificación enviada con éxito!");

    return new Response(JSON.stringify({ success: true, mensaje: "Enviado correctamente" }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error general:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});