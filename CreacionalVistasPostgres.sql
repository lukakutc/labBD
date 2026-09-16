
SET search_path TO esquema_grupo2;


CREATE OR REPLACE VIEW vista_local_intervenciones_recientes AS
SELECT nro_doc_alumno, tipo_doc_alumno, id_intervencion, motivo, gravedad, fecha
FROM intervencion
WHERE fecha > CURRENT_DATE - INTERVAL '2 years'
WITH LOCAL CHECK OPTION;


CREATE OR REPLACE VIEW vista_cascaded_intervenciones_recientes AS
SELECT nro_doc_alumno, tipo_doc_alumno, id_intervencion, motivo, gravedad, fecha
FROM intervencion
WHERE fecha > CURRENT_DATE - INTERVAL '2 years'
WITH CASCADED CHECK OPTION;


CREATE OR REPLACE VIEW vista_local_2_intervenciones_recientes_graves AS
SELECT *
FROM vista_local_intervenciones_recientes
WHERE gravedad IN ('Alta', 'Muy Alta')
WITH LOCAL CHECK OPTION;


CREATE OR REPLACE VIEW vista_cascaded_2_intervenciones_recientes_graves AS
SELECT *
FROM vista_cascaded_intervenciones_recientes
WHERE gravedad IN ('Alta', 'Muy Alta')
WITH CASCADED CHECK OPTION;


CREATE OR REPLACE VIEW vista_no_actualizable_alumnos_intervenidos_recientemente AS
SELECT a.nro_doc_alumno, a.tipo_doc_alumno, a.nombre, a.apellido,
       i.id_intervencion, i.motivo, i.gravedad, i.fecha
FROM alumno a
JOIN intervencion i 
  ON a.tipo_doc_alumno = i.tipo_doc_alumno 
 AND a.nro_doc_alumno = i.nro_doc_alumno
WHERE i.fecha > CURRENT_DATE - INTERVAL '2 years';
