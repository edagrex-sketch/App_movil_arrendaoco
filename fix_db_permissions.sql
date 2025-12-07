-- HABILITAR PERMISOS TOTALES PARA LA BASE DE DATOS
-- Dado que la app gestiona su propia autenticación y no usa Supabase Auth nativo,
-- necesitamos permitir que el rol público ('anon') pueda leer y escribir en todas las tablas.

-- 1. Tabla INMUEBLES
ALTER TABLE inmuebles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Inmuebles" ON inmuebles;
CREATE POLICY "Public Access Inmuebles" ON inmuebles FOR ALL USING (true) WITH CHECK (true);

-- 2. Tabla USUARIOS
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Usuarios" ON usuarios;
CREATE POLICY "Public Access Usuarios" ON usuarios FOR ALL USING (true) WITH CHECK (true);

-- 3. Tabla RENTAS
ALTER TABLE rentas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Rentas" ON rentas;
CREATE POLICY "Public Access Rentas" ON rentas FOR ALL USING (true) WITH CHECK (true);

-- 4. Tabla PAGOS_RENTA
ALTER TABLE pagos_renta ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Pagos" ON pagos_renta;
CREATE POLICY "Public Access Pagos" ON pagos_renta FOR ALL USING (true) WITH CHECK (true);

-- 5. Tabla CALENDARIO
ALTER TABLE calendario ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Calendario" ON calendario;
CREATE POLICY "Public Access Calendario" ON calendario FOR ALL USING (true) WITH CHECK (true);

-- 6. Tabla FAVORITOS
ALTER TABLE favoritos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Favoritos" ON favoritos;
CREATE POLICY "Public Access Favoritos" ON favoritos FOR ALL USING (true) WITH CHECK (true);

-- 7. Tabla RESENAS
ALTER TABLE resenas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Resenas" ON resenas;
CREATE POLICY "Public Access Resenas" ON resenas FOR ALL USING (true) WITH CHECK (true);

-- 8. Tabla NOTIFICACIONES
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Access Notificaciones" ON notificaciones;
CREATE POLICY "Public Access Notificaciones" ON notificaciones FOR ALL USING (true) WITH CHECK (true);
