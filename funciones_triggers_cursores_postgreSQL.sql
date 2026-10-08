SET search_path TO esquema_grupo2;

-- 1.2.1
CREATE OR REPLACE FUNCTION esquema_grupo2.costo_salida_por_alumno(anio int)
RETURNS TABLE (
    numero_salida int,
    descripcion_salida_completa text,
    cant_alumnos bigint,
    costo_total_salida numeric,
    costo_por_alumno numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.numero_salida as numero_salida,
        ('Descripcion de la salida: ' || s.descripcion ||
         ' - Fecha Inicio: ' || s.fecha_inicio ||
         ' - Fecha Fin: ' || s.fecha_fin) as descripcion_salida_completa,
        COUNT(DISTINCT (p.tipo_doc_alumno, p.nro_doc_alumno)) as cant_alumnos,
        c.costo_total::numeric AS costo_total_salida,
        ROUND((c.costo_total::numeric / COUNT(DISTINCT (p.tipo_doc_alumno, p.nro_doc_alumno))), 2) as costo_por_alumno
    FROM esquema_grupo2.participa p
    NATURAL JOIN esquema_grupo2.salida s 
    NATURAL JOIN esquema_grupo2.contrata c 
    WHERE EXTRACT(YEAR FROM s.fecha_inicio) = anio
    GROUP BY s.numero_salida, s.descripcion, s.fecha_inicio, s.fecha_fin, c.costo_total;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM esquema_grupo2.costo_salida_por_alumno(2025);

--1.2.2
CREATE OR REPLACE FUNCTION calcular_meses(fecha1 date, fecha2 date)
RETURNS integer AS $$
DECLARE
    anio1 integer; 
    mes1 integer;
    anio2 integer; 
    mes2 integer;
BEGIN
    anio1 := CAST(substring(fecha1::text from 1 for 4) AS integer);
    mes1  := CAST(substring(fecha1::text from 6 for 2) AS integer);
    anio2 := CAST(substring(fecha2::text from 1 for 4) AS integer);
    mes2  := CAST(substring(fecha2::text from 6 for 2) AS integer);

    RETURN ((anio2 - anio1) * 12) + (mes2 - mes1);
END;
$$ LANGUAGE plpgsql;

--1.3
-- poblacional:
-- 3 docentes
INSERT INTO esquema_grupo2.personal_docente
    (tipo_doc_docente, nro_doc_docente, nombre, apellido, domicilio, nacionalidad,
     fecha_nacimiento, titulo_habilitante, telefono, email, fecha_ingreso)
VALUES
('DNI', '25111222', 'Carlos',  'Benitez',  'Alberdi 450, Neuquen',  'Argentina',
 '1978-04-12', 'Profesor de Matematica', '2994123001', 'carlos.benitez@escuela.edu.ar', '2012-03-01'),
('DNI', '27333444', 'Laura',   'Quiroga',  'Mitre 820, Cipolletti', 'Argentina',
 '1981-09-30', 'Profesora de Lengua y Literatura', '2994123002', 'laura.quiroga@escuela.edu.ar', '2015-03-01'),
('DNI', '30555666', 'Federico','Sandoval', 'Lainez 310, Plottier',  'Argentina',
 '1985-01-18', 'Profesor de Historia', '2994123003', 'federico.sandoval@escuela.edu.ar', '2018-03-01')
ON CONFLICT (tipo_doc_docente, nro_doc_docente) DO NOTHING;

-- Ocupan el cargo 10, con fecha_ini y fecha_fin completas
INSERT INTO esquema_grupo2.ocupa (fecha_ini, tipo_doc_docente, nro_doc_docente, id_cargo, fecha_fin)
VALUES
('2012-03-01', 'DNI', '25111222', 10, '2019-12-20'),
('2015-03-01', 'DNI', '27333444', 10, '2022-07-15'),
('2018-03-01', 'DNI', '30555666', 10, '2024-11-29');


SELECT p.nombre, p.apellido, o.fecha_ini, o.fecha_fin, calcular_meses(o.fecha_ini,o.fecha_fin) AS cant_meses
FROM personal_docente p NATURAL JOIN OCUPA o 
WHERE o.fecha_fin IS NOT NULL AND o.id_cargo = 10;

--1.4
CREATE OR REPLACE FUNCTION esquema_grupo2.calcular_meses (fecha1 date, fecha2 date)
RETURNS integer 
RETURNS NULL ON NULL INPUT 
AS $$
DECLARE
    anio1 integer; mes1 integer;
    anio2 integer; mes2 integer;
BEGIN
    anio1 := CAST(substring(fecha1::text from 1 for 4) AS integer);
    mes1  := CAST(substring(fecha1::text from 6 for 2) AS integer);
    anio2 := CAST(substring(fecha2::text from 1 for 4) AS integer);
    mes2  := CAST(substring(fecha2::text from 6 for 2) AS integer);

    RETURN ((anio2 - anio1) * 12) + (mes2 - mes1);
END;
$$ LANGUAGE plpgsql;


--1.5
CREATE OR REPLACE FUNCTION esquema_grupo2.antiguedad_cargo_profesor(
    p_tipo_doc varchar, p_nro_doc int, p_id_cargo int)
RETURNS text AS $$
DECLARE
    intervalo interval;
    anios int;
    meses int;
    dias int;
BEGIN
    SELECT age(COALESCE(fecha_fin, CURRENT_DATE), fecha_ini)
    INTO intervalo
    FROM esquema_grupo2.ocupa
    WHERE tipo_doc_docente = p_tipo_doc 
      AND nro_doc_docente = p_nro_doc 
      AND id_cargo = p_id_cargo;

    anios := extract(year from intervalo);
    meses := extract(month from intervalo);
    dias  := extract(day from intervalo);

    RETURN anios || ' años, ' || meses || ' meses, ' || dias || ' días.';
END;
$$ LANGUAGE plpgsql;

-- fin funciones --------------------------------------------------------------
--2.1
ALTER TABLE esquema_grupo2.personal_docente 
ADD COLUMN ultimo_ciclo_lectivo VARCHAR(10),
ADD COLUMN cantidad_dictados_ciclo INT DEFAULT 0;

--2.2
CREATE OR REPLACE FUNCTION esquema_grupo2.trg_actualiza_dictados()
RETURNS TRIGGER AS $$
DECLARE
    v_ciclo_actual VARCHAR(10);
BEGIN
    SELECT ultimo_ciclo_lectivo INTO v_ciclo_actual
    FROM esquema_grupo2.personal_docente
    WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;

    IF v_ciclo_actual IS NULL OR NEW.ciclo_lectivo > v_ciclo_actual THEN
        
        UPDATE esquema_grupo2.personal_docente
        SET ultimo_ciclo_lectivo = NEW.ciclo_lectivo,
            cantidad_dictados_ciclo = 1
        WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;

    ELSIF NEW.ciclo_lectivo = v_ciclo_actual THEN
        
        UPDATE esquema_grupo2.personal_docente
        SET cantidad_dictados_ciclo = cantidad_dictados_ciclo + 1
        WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;
     
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dictados_año
AFTER INSERT ON esquema_grupo2.dictado
FOR EACH ROW
EXECUTE FUNCTION esquema_grupo2.trg_actualiza_dictados();


--2.3
CREATE OR REPLACE FUNCTION trg_delete_intervencion()
RETURNS TRIGGER AS $$
BEGIN
    -- Resuelve la dependencia eliminando primero las notificaciones
    DELETE FROM  se_notifica_intervencion 
    WHERE id_intervencion = OLD.id_intervencion;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cascada_manual_intervencion
BEFORE DELETE ON intervencion
FOR EACH ROW
EXECUTE FUNCTION trg_delete_intervencion();


--2.4
CREATE TABLE LOG_planillaControl (
numero_operacion  SERIAL PRIMARY KEY,
operacion varchar(10)
);


--2.5
--poblacional para el ejercicio
INSERT INTO esquema_grupo2.calificacion (id_calificacion, fecha, id_tipo, nota) --ESTA LINEA INSERTA UN VALOR EN UNA SENTENCIA, ES UNA LINEA EN EL LOG
VALUES (9101, '2025-05-30', 1, 7);

INSERT INTO esquema_grupo2.calificacion (id_calificacion, fecha, id_tipo, nota)
VALUES (9102, '2025-05-30', 1, 5),(9103, '2025-05-30', 1, 8), (9104, '2025-05-30', 1, 4); --ESTA LINEA INSERTA 3 TUPLAS EN CALIFICACION, PERO EN UNA MISMA SENTENCIA. UNA SOLA LINEA DE LOG

INSERT INTO esquema_grupo2.calificacion (id_calificacion, fecha, id_tipo, nota)
VALUES (9105, '2025-06-06', 1, 10); --UNA SENTENCIA DE INSERT (CON UN SOLO INSERT) UNA LINEA DE LOG

--PARA UPDATES LA MISMA LOGICA, UNA FILA POR SENTENCIA
UPDATE esquema_grupo2.calificacion
SET nota = 9
WHERE id_calificacion = 9101;

UPDATE esquema_grupo2.calificacion
SET nota = nota + 1 WHERE id_calificacion IN (9102, 9103, 9104);

UPDATE esquema_grupo2.calificacion   -- no afecta ninguna fila, igual se registra
SET nota = 1 WHERE id_calificacion = 99999;

-- DELETES (3 sentencias = 3 filas DELETE en el log)
DELETE FROM esquema_grupo2.calificacion
WHERE id_calificacion = 9101;

DELETE FROM esquema_grupo2.calificacion
WHERE id_calificacion IN (9102, 9103, 9104);

DELETE FROM esquema_grupo2.calificacion
WHERE id_calificacion = 9105;


--ejercicio
CREATE OR REPLACE FUNCTION esquema_grupo2.trg_auditoria_calificacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Se inserta directamente el valor de la variable  TG_OP
    INSERT INTO esquema_grupo2.LOG_planillaControl(operacion) 
    VALUES (TG_OP);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_auditoria_stmt
AFTER INSERT OR UPDATE OR DELETE ON esquema_grupo2.calificacion
FOR EACH STATEMENT
EXECUTE FUNCTION esquema_grupo2.trg_auditoria_calificacion();


--2.6
--poblacional para el ejercicio
INSERT INTO esquema_grupo2.curso (seccion, turno, anio_academico) VALUES ('Y', 'Tarde', 1); 
INSERT INTO esquema_grupo2.curso (seccion, turno, anio_academico) VALUES ('Y', 'Noche', 2);

--ejercicio
CREATE OR REPLACE FUNCTION esquema_grupo2.trg_verificar_curso_dictado()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM esquema_grupo2.materia m
        JOIN esquema_grupo2.curso c ON c.anio_academico = m.anio_academico
        WHERE m.id_materia = NEW.id_materia
          AND c.seccion = NEW.seccion
          AND c.turno = NEW.turno
    ) THEN
        RAISE EXCEPTION 'No existe un curso (seccion %, turno %) para el  cual la materia % este destinada',
            NEW.seccion, NEW.turno, NEW.id_materia;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_control_dictado_curso
BEFORE INSERT OR UPDATE ON esquema_grupo2.dictado
FOR EACH ROW 
EXECUTE FUNCTION esquema_grupo2.trg_verificar_curso_dictado();


INSERT INTO esquema_grupo2.dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Tarde', 1);

INSERT INTO esquema_grupo2.dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Manana', 1); 

INSERT INTO esquema_grupo2.dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Noche', 1); 

UPDATE esquema_grupo2.dictado SET turno = 'Noche' WHERE ciclo_lectivo = '2025' AND seccion = 'Y' AND turno = 'Tarde' AND id_materia = 1; 

DELETE FROM esquema_grupo2.dictado WHERE ciclo_lectivo = '2025' AND seccion = 'Y'; 
DELETE FROM esquema_grupo2.curso WHERE seccion = 'Y'; 



--fin triggers ---------------------------------------


--3.1
CREATE OR REPLACE PROCEDURE esquema_grupo2.extremos_calificaciones_trimestre(
    p_id_materia INTEGER,
    p_ciclo_lectivo VARCHAR,
    p_seccion VARCHAR,
    p_turno VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR;
    v_apellido VARCHAR;
    v_nota INTEGER;

    c_notas SCROLL CURSOR FOR
        SELECT al.nombre, al.apellido, c.nota
        FROM esquema_grupo2.asiste a
        JOIN esquema_grupo2.calificacion c
          ON c.id_calificacion = a.id_calificacion
        JOIN esquema_grupo2.alumno al
          ON al.tipo_doc_alumno = a.tipo_doc_alumno
         AND al.nro_doc_alumno = a.nro_doc_alumno
        WHERE a.id_materia = p_id_materia
          AND a.ciclo_lectivo = p_ciclo_lectivo
          AND a.seccion = p_seccion
          AND a.turno = p_turno
          AND c.id_tipo = 1
          AND c.nota IS NOT NULL
        ORDER BY c.nota DESC;
BEGIN
    OPEN c_notas;

    MOVE FIRST FROM c_notas;
    FETCH RELATIVE 0 FROM c_notas INTO v_nombre, v_apellido, v_nota;

    IF FOUND THEN
        RAISE NOTICE 'Mejor calificacion -> Alumno: % %, Nota: %', v_nombre, v_apellido, v_nota;
    ELSE
        RAISE NOTICE 'No existen calificaciones cargadas para el curso y materia indicados.';
        CLOSE c_notas;
        RETURN;
    END IF;

    MOVE LAST FROM c_notas;
    FETCH RELATIVE 0 FROM c_notas INTO v_nombre, v_apellido, v_nota;

    RAISE NOTICE 'Peor calificacion -> Alumno: % %, Nota: %', v_nombre, v_apellido, v_nota;

    CLOSE c_notas;
END;
$$;

CALL esquema_grupo2.extremos_calificaciones_trimestre(1, '2025', 'Z', 'Tarde');

--3.2
ALTER TABLE esquema_grupo2.participa
ADD COLUMN costo_individual NUMERIC DEFAULT 0;

CREATE OR REPLACE PROCEDURE esquema_grupo2.actualizar_costos_participacion()
LANGUAGE plpgsql
AS $$
DECLARE
    c_participantes CURSOR FOR 
        SELECT numero_salida 
        FROM esquema_grupo2.participa 
        FOR UPDATE;
        
    v_num_salida INT;
    v_anio INT; -- Nueva variable para guardar el año
    v_costo_calculado NUMERIC;
BEGIN
    OPEN c_participantes;
    
    LOOP
        -- Extraemos el numero_salida de la fila actual
        FETCH c_participantes INTO v_num_salida;
        
        EXIT WHEN NOT FOUND;
        
        -- 1. Buscamos el año en la tabla SALIDA correspondiente a este numero_salida
        SELECT EXTRACT(YEAR FROM fecha_inicio)::INT INTO v_anio
        FROM esquema_grupo2.salida
        WHERE numero_salida = v_num_salida;
        
        -- 2. Ahora sí, le pasamos el año dinámicamente a la función
        SELECT costo_por_alumno INTO v_costo_calculado
        FROM esquema_grupo2.costo_salida_por_alumno(v_anio)
        WHERE numero_salida = v_num_salida;
        
        IF v_costo_calculado IS NULL THEN
            v_costo_calculado := 0;
        END IF;
        
        UPDATE esquema_grupo2.participa
        SET costo_individual = v_costo_calculado
        WHERE CURRENT OF c_participantes;
        
    END LOOP;
    
    CLOSE c_participantes;
END;
$$;


--3.3
CREATE OR REPLACE PROCEDURE esquema_grupo2.listar_materias(p_area VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    c_materias_areas CURSOR FOR
        SELECT a.nombre_area, m.nombre,  m.anio_academico
        FROM area_academica a JOIN materia m ON a.id_area_academica = m.id_area_academica
        WHERE a.nombre_area LIKE '%' || p_area || '%'; --esto es por si no ingresan completo el nombre, como ciencias –
    fila RECORD;
    resultado TEXT;
BEGIN
    OPEN c_materias_areas;
    LOOP
        FETCH c_materias_areas INTO fila;
        EXIT WHEN NOT FOUND;
        resultado := format(
            'Área: %s | Materia: %s | Año Académico: %s',
            fila.nombre_area,
            fila.nombre,
            fila.anio_academico
        );
        RAISE NOTICE '%', resultado;
    END LOOP;
    CLOSE c_materias_areas;
END;
$$;

CALL esquema_grupo2.listar_materias('Lengua y Literatura'); 


-- fin cursores --------------------------------


-- DROP -------------------------------
/*
-- Triggers
DROP TRIGGER IF EXISTS trg_control_dictado_curso ON esquema_grupo2.dictado;
DROP TRIGGER IF EXISTS trg_dictados_año ON esquema_grupo2.dictado;
DROP TRIGGER IF EXISTS trg_cascada_manual_intervencion ON esquema_grupo2.intervencion;
DROP TRIGGER IF EXISTS trg_auditoria_stmt ON esquema_grupo2.calificacion;

-- Funciones de trigger
DROP FUNCTION IF EXISTS esquema_grupo2.trg_verificar_curso_dictado();
DROP FUNCTION IF EXISTS esquema_grupo2.trg_actualiza_dictados();
DROP FUNCTION IF EXISTS esquema_grupo2.trg_delete_intervencion();
DROP FUNCTION IF EXISTS esquema_grupo2.trg_auditoria_calificacion();

-- Tabla de log
DROP TABLE IF EXISTS esquema_grupo2.LOG_planillaControl;
-- Revertir el ALTER TABLE
ALTER TABLE esquema_grupo2.personal_docente
    DROP COLUMN IF EXISTS ultimo_ciclo_lectivo,
    DROP COLUMN IF EXISTS cantidad_dictados_ciclo;

-- Procedimientos
DROP PROCEDURE IF EXISTS esquema_grupo2.actualizar_costos_participacion();
DROP PROCEDURE IF EXISTS esquema_grupo2.extremos_calificaciones_trimestre(integer, varchar, varchar, varchar);

-- Columna agregada a participa para el cursor FOR UPDATE
ALTER TABLE esquema_grupo2.participa
    DROP COLUMN IF EXISTS costo_individual;

-- Funciones
DROP FUNCTION IF EXISTS esquema_grupo2.costo_salida_por_alumno(int);
DROP FUNCTION IF EXISTS esquema_grupo2.calcular_meses(date, date);
DROP FUNCTION IF EXISTS esquema_grupo2.antiguedad_cargo_profesor(varchar, int, int);
*/

