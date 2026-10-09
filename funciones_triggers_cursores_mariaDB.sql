USE escuela_neuquen;

-- 1.2.1
DELIMITER //

CREATE PROCEDURE costo_salida_por_alumno(IN p_anio INT)
BEGIN
    SELECT
        s.numero_salida as numero_salida,
        CONCAT('Descripcion de la salida: ', s.descripcion,
               ' - Fecha Inicio: ', s.fecha_inicio,
               ' - Fecha Fin: ', s.fecha_fin) as descripcion_salida_completa,
        COUNT(DISTINCT CONCAT(p.tipo_doc_alumno, p.nro_doc_alumno)) as cant_alumnos,
        c.costo_total AS costo_total_salida,
        ROUND((c.costo_total / COUNT(DISTINCT CONCAT(p.tipo_doc_alumno, p.nro_doc_alumno))), 2) as costo_por_alumno
    FROM participa p
    NATURAL JOIN salida s 
    NATURAL JOIN contrata c 
    WHERE YEAR(s.fecha_inicio) = p_anio
    GROUP BY s.numero_salida, s.descripcion, s.fecha_inicio, s.fecha_fin, c.costo_total;
END //

DELIMITER ;

-- Llamado en MariaDB
CALL costo_salida_por_alumno(2025);


-- 1.2.2
DELIMITER //

CREATE FUNCTION calcular_meses(fecha1 DATE, fecha2 DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE anio1 INT; 
    DECLARE mes1 INT;
    DECLARE anio2 INT; 
    DECLARE mes2 INT;
    
    SET anio1 = CAST(SUBSTRING(CAST(fecha1 AS CHAR), 1, 4) AS UNSIGNED);
    SET mes1  = CAST(SUBSTRING(CAST(fecha1 AS CHAR), 6, 2) AS UNSIGNED);
    SET anio2 = CAST(SUBSTRING(CAST(fecha2 AS CHAR), 1, 4) AS UNSIGNED);
    SET mes2  = CAST(SUBSTRING(CAST(fecha2 AS CHAR), 6, 2) AS UNSIGNED);
    
    RETURN ((anio2 - anio1) * 12) + (mes2 - mes1);
END //

DELIMITER ;

-- SELECT calcular_meses('2025-03-01', '2026-08-15');


-- 1.3
-- poblacional:
-- 3 docentes
INSERT INTO personal_docente
    (tipo_doc_docente, nro_doc_docente, nombre, apellido, domicilio, nacionalidad,
     fecha_nacimiento, titulo_habilitante, telefono, email, fecha_ingreso)
VALUES
('DNI', '25111222', 'Carlos',  'Benitez',  'Alberdi 450, Neuquen',  'Argentina',
 '1978-04-12', 'Profesor de Matematica', '2994123001', 'carlos.benitez@escuela.edu.ar', '2012-03-01'),
('DNI', '27333444', 'Laura',   'Quiroga',  'Mitre 820, Cipolletti', 'Argentina',
 '1981-09-30', 'Profesora de Lengua y Literatura', '2994123002', 'laura.quiroga@escuela.edu.ar', '2015-03-01'),
('DNI', '30555666', 'Federico','Sandoval', 'Lainez 310, Plottier',  'Argentina',
 '1985-01-18', 'Profesor de Historia', '2994123003', 'federico.sandoval@escuela.edu.ar', '2018-03-01');

-- Ocupan el cargo 10, con fecha_ini y fecha_fin completas
INSERT INTO ocupa (fecha_ini, tipo_doc_docente, nro_doc_docente, id_cargo, fecha_fin)
VALUES
('2012-03-01', 'DNI', '25111222', 10, '2019-12-20'),
('2015-03-01', 'DNI', '27333444', 10, '2022-07-15'),
('2018-03-01', 'DNI', '30555666', 10, '2024-11-29');


SELECT p.nombre, p.apellido, o.fecha_ini, o.fecha_fin, calcular_meses(o.fecha_ini,o.fecha_fin) AS cant_meses
FROM personal_docente p NATURAL JOIN OCUPA o 
WHERE o.fecha_fin IS NOT NULL AND o.id_cargo = 10;

-- 1.4
DELIMITER //

CREATE FUNCTION calcular_meses2(fecha1 DATE, fecha2 DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE anio1 INT; 
    DECLARE mes1 INT;
    DECLARE anio2 INT; 
    DECLARE mes2 INT;
    
    IF fecha1 IS NULL OR fecha2 IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET anio1 = CAST(SUBSTRING(CAST(fecha1 AS CHAR), 1, 4) AS UNSIGNED);
    SET mes1  = CAST(SUBSTRING(CAST(fecha1 AS CHAR), 6, 2) AS UNSIGNED);
    SET anio2 = CAST(SUBSTRING(CAST(fecha2 AS CHAR), 1, 4) AS UNSIGNED);
    SET mes2  = CAST(SUBSTRING(CAST(fecha2 AS CHAR), 6, 2) AS UNSIGNED);
    
    RETURN ((anio2 - anio1) * 12) + (mes2 - mes1);
END //

DELIMITER ;



-- 1.5
DELIMITER //

CREATE FUNCTION antiguedad_cargo_profesor(
    p_tipo_doc VARCHAR(5),
    p_nro_doc INT,
    p_id_cargo INT)
RETURNS VARCHAR(100)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_ini DATE;
    DECLARE v_fecha_fin DATE;
    DECLARE v_anios INT;
    DECLARE v_meses INT;
    DECLARE v_dias INT;

    SELECT fecha_ini, COALESCE(fecha_fin, CURRENT_DATE)
    INTO v_fecha_ini, v_fecha_fin
    FROM ocupa
    WHERE tipo_doc_docente = p_tipo_doc
      AND nro_doc_docente = p_nro_doc
      AND id_cargo = p_id_cargo;

    IF v_fecha_ini IS NULL THEN
        RETURN NULL;
    END IF;

    SET v_anios = TIMESTAMPDIFF(YEAR, v_fecha_ini, v_fecha_fin);
    SET v_meses = TIMESTAMPDIFF(MONTH, v_fecha_ini, v_fecha_fin) % 12;
    SET v_dias  = DATEDIFF(v_fecha_fin,
                           DATE_ADD(DATE_ADD(v_fecha_ini, INTERVAL v_anios YEAR),
                                    INTERVAL v_meses MONTH));

    RETURN CONCAT(v_anios, ' años, ', v_meses, ' meses, ', v_dias, ' días.');
END //

DELIMITER ;



-- fin funciones --------------------------------------------------------------
-- 2.1
ALTER TABLE personal_docente 
ADD COLUMN ultimo_ciclo_lectivo VARCHAR(10),
ADD COLUMN cantidad_dictados_ciclo INT DEFAULT 0;


-- 2.2
DELIMITER //

CREATE TRIGGER trg_dictados_año
AFTER INSERT ON dictado
FOR EACH ROW
BEGIN
    DECLARE v_ciclo_actual VARCHAR(10);

    SELECT ultimo_ciclo_lectivo INTO v_ciclo_actual
    FROM personal_docente
    WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;

    IF v_ciclo_actual IS NULL OR NEW.ciclo_lectivo > v_ciclo_actual THEN
        
        UPDATE personal_docente
        SET ultimo_ciclo_lectivo = NEW.ciclo_lectivo,
            cantidad_dictados_ciclo = 1
        WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;

    ELSEIF NEW.ciclo_lectivo = v_ciclo_actual THEN
        
        UPDATE personal_docente
        SET cantidad_dictados_ciclo = cantidad_dictados_ciclo + 1
        WHERE tipo_doc_docente = NEW.tipo_doc_docente AND nro_doc_docente = NEW.nro_doc_docente;
        
    END IF;
END //

DELIMITER ;



-- 2.3
DELIMITER //

CREATE TRIGGER trg_cascada_manual_intervencion
BEFORE DELETE ON intervencion
FOR EACH ROW
BEGIN
    -- Resuelve la dependencia eliminando primero las notificaciones
    DELETE FROM se_notifica_intervencion 
    WHERE id_intervencion = OLD.id_intervencion;
END //

DELIMITER ;



-- 2.4
CREATE TABLE LOG_planillaControl (
    numero_operacion INT AUTO_INCREMENT PRIMARY KEY,
    operacion VARCHAR(10)
);



-- 2.5
-- poblacional para el ejercicio
INSERT INTO calificacion (id_calificacion, fecha, id_tipo, nota) -- ESTA LINEA INSERTA UN VALOR EN UNA SENTENCIA, ES UNA LINEA EN EL LOG
VALUES (9101, '2025-05-30', 1, 7);

INSERT INTO calificacion (id_calificacion, fecha, id_tipo, nota)
VALUES (9102, '2025-05-30', 1, 5),(9103, '2025-05-30', 1, 8), (9104, '2025-05-30', 1, 4); -- ESTA LINEA INSERTA 3 TUPLAS EN CALIFICACION, PERO EN UNA MISMA SENTENCIA. UNA SOLA LINEA DE LOG

INSERT INTO calificacion (id_calificacion, fecha, id_tipo, nota)
VALUES (9105, '2025-06-06', 1, 10); -- UNA SENTENCIA DE INSERT (CON UN SOLO INSERT) UNA LINEA DE LOG

-- PARA UPDATES LA MISMA LOGICA, UNA FILA POR SENTENCIA
UPDATE calificacion
SET nota = 9
WHERE id_calificacion = 9101;

UPDATE calificacion
SET nota = nota + 1 WHERE id_calificacion IN (9102, 9103, 9104);

UPDATE calificacion   -- no afecta ninguna fila, igual se registra
SET nota = 1 WHERE id_calificacion = 99999;

-- DELETES (3 sentencias = 3 filas DELETE en el log)
DELETE FROM calificacion
WHERE id_calificacion = 9101;

DELETE FROM calificacion
WHERE id_calificacion IN (9102, 9103, 9104);

DELETE FROM calificacion
WHERE id_calificacion = 9105;


-- ejercicio
DELIMITER //

-- inserciones
CREATE TRIGGER trg_auditoria_insert
AFTER INSERT ON calificacion
FOR EACH ROW
BEGIN
    INSERT INTO LOG_planillaControl(operacion) VALUES ('INSERT');
END //

-- actualizaciones
CREATE TRIGGER trg_auditoria_update
AFTER UPDATE ON calificacion
FOR EACH ROW
BEGIN
    INSERT INTO LOG_planillaControl(operacion) VALUES ('UPDATE');
END //

-- eliminaciones
CREATE TRIGGER trg_auditoria_delete
AFTER DELETE ON calificacion
FOR EACH ROW
BEGIN
    INSERT INTO LOG_planillaControl(operacion) VALUES ('DELETE');
END //

DELIMITER ;



-- 2.6
-- poblacional para el ejercicio
INSERT INTO curso (seccion, turno, anio_academico) VALUES ('Y', 'Tarde', 1); 
INSERT INTO curso (seccion, turno, anio_academico) VALUES ('Y', 'Noche', 2);


-- ejercicio
DELIMITER //

CREATE TRIGGER trg_control_dictado_curso_insert
BEFORE INSERT ON dictado
FOR EACH ROW
BEGIN
    DECLARE v_existe INT;

    -- Evaluamos si existe la combinación válida
    SELECT COUNT(*) INTO v_existe
    FROM materia m
    JOIN curso c ON c.anio_academico = m.anio_academico
    WHERE m.id_materia = NEW.id_materia
      AND c.seccion = NEW.seccion
      AND c.turno = NEW.turno;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existe un curso para la sección, turno y materia indicados.';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_control_dictado_curso_update
BEFORE UPDATE ON dictado
FOR EACH ROW
BEGIN
    DECLARE v_existe INT;

    SELECT COUNT(*) INTO v_existe
    FROM materia m
    JOIN curso c ON c.anio_academico = m.anio_academico
    WHERE m.id_materia = NEW.id_materia
      AND c.seccion = NEW.seccion
      AND c.turno = NEW.turno;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existe un curso para la sección, turno y materia indicados.';
    END IF;
END //

DELIMITER ;


-- prueba del ejercicio y drop del poblacional
INSERT INTO dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Tarde', 1);

INSERT INTO dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Manana', 1); 

INSERT INTO dictado (ciclo_lectivo, seccion, turno, id_materia) VALUES ('2025', 'Y', 'Noche', 1); 

UPDATE dictado SET turno = 'Noche' WHERE ciclo_lectivo = '2025' AND seccion = 'Y' AND turno = 'Tarde' AND id_materia = 1; 

DELETE FROM dictado WHERE ciclo_lectivo = '2025' AND seccion = 'Y'; 
DELETE FROM curso WHERE seccion = 'Y'; 




-- fin triggers ---------------------------------------


-- 3.1
DELIMITER //

CREATE PROCEDURE extremos_calificaciones_trimestre(
    IN p_nombre_materia VARCHAR(100),
    IN p_ciclo_lectivo VARCHAR(10),
    IN p_seccion VARCHAR(5),
    IN p_turno VARCHAR(20)
)
BEGIN
    -- Variables para la lectura iterativa
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_nota NUMERIC(5,2);

    -- Variables para retener el último valor encontrado
    DECLARE v_peor_nombre VARCHAR(100);
    DECLARE v_peor_apellido VARCHAR(100);
    DECLARE v_peor_nota NUMERIC(5,2);

    -- Variable de control para el fin del cursor
    DECLARE v_fin INT DEFAULT FALSE;

    -- Declaración del cursor (es de solo avance por defecto)
    DECLARE c_notas CURSOR FOR
        SELECT a.nombre, a.apellido, c.calificacion
        FROM materia m
        NATURAL JOIN dictado d
        NATURAL JOIN calificacion c
        NATURAL JOIN alumno a
        WHERE m.nombre = p_nombre_materia
          AND d.ciclo_lectivo = p_ciclo_lectivo
          AND d.seccion = p_seccion
          AND d.turno = p_turno
          AND c.id_tipo = 1
        ORDER BY c.calificacion DESC;

    -- Manejador de excepciones: cuando FETCH no encuentre más datos, cambia v_fin a TRUE
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;


    OPEN c_notas;

    -- 1. Intentamos atrapar la primera fila (MOVE FIRST equivalente)
    FETCH c_notas INTO v_nombre, v_apellido, v_nota;

    IF v_fin THEN
        -- Reemplazo de RAISE NOTICE de PostgreSQL
        SELECT 'No existen calificaciones cargadas para el curso y materia indicados.' AS Mensaje;
    ELSE
        SELECT CONCAT('Mejor calificación -> Alumno: ', v_nombre, ' ', v_apellido, ', Nota: ', v_nota) AS Mensaje_Mejor;

        -- Inicializamos los valores de "peor nota" por si el curso tiene un solo alumno
        SET v_peor_nombre = v_nombre;
        SET v_peor_apellido = v_apellido;
        SET v_peor_nota = v_nota;

        -- 2. Recorremos el resto del cursor para llegar al final (MOVE LAST equivalente)
        bucle_notas: LOOP
            FETCH c_notas INTO v_nombre, v_apellido, v_nota;
            
            -- Si ya no hay datos, rompemos el bucle
            IF v_fin THEN
                LEAVE bucle_notas;
            END IF;
            
            -- Si encontró datos, sobrescribimos las variables de la peor nota
            SET v_peor_nombre = v_nombre;
            SET v_peor_apellido = v_apellido;
            SET v_peor_nota = v_nota;
        END LOOP;

        SELECT CONCAT('Peor calificación -> Alumno: ', v_peor_nombre, ' ', v_peor_apellido, ', Nota: ', v_peor_nota) AS Mensaje_Peor;
    END IF;

    CLOSE c_notas;
END //

DELIMITER ;


-- 3.2
ALTER TABLE participa
ADD COLUMN costo_individual NUMERIC DEFAULT 0;

DELIMITER //

CREATE OR REPLACE PROCEDURE actualizar_costos_participacion()
BEGIN
    DECLARE v_num_salida INT;
    DECLARE v_tipo_doc VARCHAR(5);
    DECLARE v_nro_doc INT;
    
    -- Variables nuevas para separar el cálculo
    DECLARE v_costo_total DECIMAL(10,2);
    DECLARE v_cant_alumnos INT;
    DECLARE v_costo_calculado DECIMAL(10,2);
    
    DECLARE v_fin INT DEFAULT FALSE;
    
    DECLARE c_participantes CURSOR FOR 
        SELECT numero_salida, tipo_doc_alumno, nro_doc_alumno 
        FROM participa;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    OPEN c_participantes;
    
    bucle_participantes: LOOP
        FETCH c_participantes INTO v_num_salida, v_tipo_doc, v_nro_doc;
        
        IF v_fin THEN
            LEAVE bucle_participantes;
        END IF;
        
        -- 1. Extraemos el costo de la tabla contrata
        SET v_costo_total = (SELECT costo_total FROM contrata WHERE numero_salida = v_num_salida);
        
        -- 2. Contamos cuántos alumnos van a esa misma salida
        SET v_cant_alumnos = (SELECT COUNT(*) FROM participa WHERE numero_salida = v_num_salida);
        
        -- 3. Ejecutamos la división de forma segura
        IF v_costo_total IS NOT NULL AND v_cant_alumnos > 0 THEN
            SET v_costo_calculado = ROUND(v_costo_total / v_cant_alumnos, 2);
        ELSE
            SET v_costo_calculado = 0;
        END IF;
        
        -- 4. Actualizamos el registro exacto del alumno
        UPDATE participa
        SET costo_individual = v_costo_calculado
        WHERE numero_salida = v_num_salida
          AND tipo_doc_alumno = v_tipo_doc
          AND nro_doc_alumno = v_nro_doc;
          
    END LOOP;
    
    CLOSE c_participantes;
END //

DELIMITER ;



-- 3.3
DELIMITER //

CREATE PROCEDURE listar_materias_area(IN p_area VARCHAR(100))
BEGIN
    DECLARE v_nombre_area VARCHAR(100);
    DECLARE v_nombre_materia VARCHAR(100);
    DECLARE v_anio_academico INT;
    DECLARE v_fin BOOLEAN DEFAULT FALSE;
    
    DECLARE v_resultado_final TEXT DEFAULT ''; 

    DECLARE c_materias_areas CURSOR FOR
        SELECT a.nombre_area, m.nombre, m.anio_academico
        FROM area_academica a JOIN materia m ON a.id_area_academica = m.id_area_academica
        WHERE a.nombre_area LIKE CONCAT('%', p_area, '%'); 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    OPEN c_materias_areas;

    bucle: LOOP
        FETCH c_materias_areas INTO v_nombre_area, v_nombre_materia, v_anio_academico;

        IF v_fin THEN
            LEAVE bucle;
        END IF;

        -- En la variable se va acumulando el resultado
        SET v_resultado_final = CONCAT(
            v_resultado_final,
            'Área: ', v_nombre_area,
            ' | Materia: ', v_nombre_materia,
            ' | Año Academico: ', v_anio_academico,
            '\n'
        );

    END LOOP;
    CLOSE c_materias_areas;
    
    -- Para que sea todo una unica salida
    SELECT v_resultado_final AS resultado;
END //
DELIMITER ;

CALL listar_materias_area('Lengua y Literatura'); 


-- fin cursores --------------------------------


-- DROP -------------------------------
/*
DROP TRIGGER IF EXISTS trg_control_dictado_curso_insert;
DROP TRIGGER IF EXISTS trg_control_dictado_curso_update;
DROP TRIGGER IF EXISTS `trg_dictados_año`;
DROP TRIGGER IF EXISTS trg_cascada_manual_intervencion;
DROP TRIGGER IF EXISTS trg_auditoria_insert;
DROP TRIGGER IF EXISTS trg_auditoria_update;
DROP TRIGGER IF EXISTS trg_auditoria_delete;

DROP TABLE IF EXISTS LOG_planillaControl;

ALTER TABLE personal_docente
    DROP COLUMN IF EXISTS ultimo_ciclo_lectivo,
    DROP COLUMN IF EXISTS cantidad_dictados_ciclo;

ALTER TABLE participa
    DROP COLUMN IF EXISTS costo_individual;

DROP PROCEDURE IF EXISTS actualizar_costos_participacion;
DROP PROCEDURE IF EXISTS extremos_calificaciones_trimestre;
DROP PROCEDURE IF EXISTS costo_salida_por_alumno;
DROP PROCEDURE IF EXISTS listar_materias;
DROP PROCEDURE IF EXISTS listar_materias_areas;
DROP PROCEDURE IF EXISTS listar_materias_cursor;

DROP FUNCTION IF EXISTS calcular_meses;
DROP FUNCTION IF EXISTS calcular_meses2;
DROP FUNCTION IF EXISTS antiguedad_cargo_profesor;

*/

