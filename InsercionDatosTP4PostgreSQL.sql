SET search_path TO esquema_grupo2;

INSERT INTO esquema_grupo2.alumno (tipo_doc_alumno, nro_doc_alumno, nombre, apellido, domicilio, nacionalidad, fecha_nacimiento, fecha_ingreso, fecha_egreso)
SELECT
    'DNI'::esquema_grupo2.tipo_documento,
    (35000000 + i)::esquema_grupo2.nro_documento,  
    'Nombre_' || i, 
    'Apellido_' || i,  
    'Av. ' || (((i - 1) / 5000)::integer + 1) || ', Nro ' || (((i - 1) % 5000) + 1) || ' , Neuquén', 
    'Argentina',  
    (DATE '1993-01-01' + FLOOR(RANDOM() * 366)::integer),
    CASE 
        WHEN i % 2 = 0 THEN '2006-03-01'::date
        ELSE '2007-03-01'::date 
    END,
    CASE 
        WHEN i % 2 = 0 THEN '2011-12-12'::date 
        ELSE '2012-12-12'::date 
    END
FROM generate_series(1, 500000) AS s(i);