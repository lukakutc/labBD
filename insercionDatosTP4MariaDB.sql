USE escuela_neuquen;

INSERT INTO alumno (
    tipo_doc_alumno,
    nro_doc_alumno,
    nombre,
    apellido,
    domicilio,
    nacionalidad,
    fecha_nacimiento,
    fecha_ingreso,
    fecha_egreso
)
SELECT
    'DNI',
    35000000 + s.seq,
    CONCAT('Nombre_', s.seq),
    CONCAT('Apellido_', s.seq),
    CONCAT(
        'Av. ',
        FLOOR((s.seq - 1) / 5000) + 1,
        ', Nro ',
        MOD(s.seq - 1, 5000) + 1,
        ' , Neuquén'
    ),
    'Argentina',
    DATE_ADD(
        '1993-01-01',
        INTERVAL FLOOR(RAND() * 366) DAY
    ),
    IF(
        MOD(s.seq, 2) = 0,
        '2006-03-01',
        '2007-03-01'
    ),
    IF(
        MOD(s.seq, 2) = 0,
        '2011-12-12',
        '2012-12-12'
    )
FROM seq_1_to_500000 AS s;
