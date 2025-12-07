-- INSTRUCCIONES:
-- 1. Ve a tu proyecto de Supabase -> SQL Editor (icono de hoja de papel/consola en la izquierda).
-- 2. Crea una "New Query".
-- 3. Copia y pega TODO este código y dale a "RUN".

-- 1. Asegurar políticas de lectura pública (cualquiera puede ver las fotos)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'inmuebles' );

-- 2. Permitir subir archivos (INSERT) a cualquier usuario (autenticado o anónimo)
-- Esto arregla el error 403 "new row violates row-level security policy"
DROP POLICY IF EXISTS "Allow Uploads" ON storage.objects;
CREATE POLICY "Allow Uploads"
ON storage.objects FOR INSERT
TO public
WITH CHECK ( bucket_id = 'inmuebles' );

-- 3. Permitir actualizar y borrar archivos (UPDATE, DELETE)
DROP POLICY IF EXISTS "Allow Full Access" ON storage.objects;
CREATE POLICY "Allow Full Access"
ON storage.objects FOR ALL
TO public
USING ( bucket_id = 'inmuebles' );

-- NOTA:
-- Asegúrate también de que el bucket se llame exactamente 'inmuebles'
-- y que esté marcado como "Public Bucket" en la configuración del Storage.
