
/*
DROP TABLE IF EXISTS se_notifica_calificacion;
DROP TABLE IF EXISTS se_notifica_intervencion;
DROP TABLE IF EXISTS asiste;
DROP TABLE IF EXISTS se_enmarca_en;
DROP TABLE IF EXISTS participa;
DROP TABLE IF EXISTS contrata;
DROP TABLE IF EXISTS acompaña;
DROP TABLE IF EXISTS padece;
DROP TABLE IF EXISTS corresponde_a;
DROP TABLE IF EXISTS pertenece;
DROP TABLE IF EXISTS calificacion;
DROP TABLE IF EXISTS intervencion;
DROP TABLE IF EXISTS ocupa;
DROP TABLE IF EXISTS acompaña_salida;
DROP TABLE IF EXISTS lugar;
DROP TABLE IF EXISTS dictado;
DROP TABLE IF EXISTS materia;
DROP TABLE IF EXISTS coordina;
DROP TABLE IF EXISTS acompañante_terapeutico;
DROP TABLE IF EXISTS condicion_de_salud;
DROP TABLE IF EXISTS tutor;
DROP TABLE IF EXISTS curso;
DROP TABLE IF EXISTS tipo;
DROP TABLE IF EXISTS cargo;
DROP TABLE IF EXISTS empresa_transporte;
DROP TABLE IF EXISTS salida;
DROP TABLE IF EXISTS area_academica;
DROP TABLE IF EXISTS asesor_pedagogico;
DROP TABLE IF EXISTS personal_docente;
DROP TABLE IF EXISTS alumno;
*/


CREATE TABLE alumno (
    tipo_doc_alumno VARCHAR(5) CHECK (tipo_doc_alumno IN ('DNI', 'LE', 'LC')),
    nro_doc_alumno INT CHECK (nro_doc_alumno > 999999 AND nro_doc_alumno < 100000000),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento DATE NOT NULL,
    fecha_ingreso DATE NOT NULL CHECK (fecha_ingreso > '1970-01-01'),
    fecha_egreso DATE CHECK (fecha_egreso > '1970-01-01'),
    PRIMARY KEY (tipo_doc_alumno, nro_doc_alumno)
);

CREATE TABLE personal_docente (
    tipo_doc_docente VARCHAR(5) CHECK (tipo_doc_docente IN ('DNI', 'LE', 'LC')),
    nro_doc_docente INT CHECK (nro_doc_docente > 999999 AND nro_doc_docente < 100000000),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento DATE NOT NULL CHECK (fecha_nacimiento > '1926-01-01'),
    titulo_habilitante VARCHAR(100) NOT NULL,
    telefono VARCHAR(25),
    email VARCHAR(50),
    fecha_ingreso DATE NOT NULL CHECK (fecha_ingreso > '1970-01-01'),
    PRIMARY KEY (tipo_doc_docente, nro_doc_docente)
);

CREATE TABLE asesor_pedagogico (
    tipo_doc_pedagogico VARCHAR(5) CHECK (tipo_doc_pedagogico IN ('DNI', 'LE', 'LC')),
    nro_doc_pedagogico INT CHECK (nro_doc_pedagogico > 999999 AND nro_doc_pedagogico < 100000000),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento DATE NOT NULL CHECK (fecha_nacimiento > '1926-01-01'),
    titulo_habilitante VARCHAR(100) NOT NULL,
    telefono VARCHAR(25),
    email VARCHAR(50),
    fecha_ingreso DATE NOT NULL CHECK (fecha_ingreso > '1970-01-01'),
    matricula VARCHAR(20) NOT NULL UNIQUE,
    PRIMARY KEY (tipo_doc_pedagogico, nro_doc_pedagogico)
);

CREATE TABLE area_academica (
    id_area_academica SERIAL,
    nombre_area VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    PRIMARY KEY (id_area_academica)
);

CREATE TABLE salida (
    numero_salida SERIAL,
    descripcion VARCHAR(255),
    fecha_inicio DATETIME,
    fecha_fin DATETIME,
    PRIMARY KEY (numero_salida)
);

CREATE TABLE empresa_transporte (
    cuit VARCHAR(20),
    direccion VARCHAR(255),
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(25),
    email VARCHAR(50),
    PRIMARY KEY (cuit)
);

CREATE TABLE cargo (
    id_cargo INT,
    nombre_cargo VARCHAR(100) NOT NULL,
    cantidad_horas INT NOT NULL,
    descripcion_cargo VARCHAR(255),
    PRIMARY KEY (id_cargo)
);

CREATE TABLE tipo (
    id_tipo INT,
    descripcion VARCHAR(50),
    PRIMARY KEY (id_tipo)
);

CREATE TABLE curso (
    seccion VARCHAR(20),
    turno VARCHAR(20),
    anio_academico INT CHECK (anio_academico > 0 AND anio_academico < 6),
    PRIMARY KEY (seccion, turno, anio_academico)
);

CREATE TABLE tutor (
    email VARCHAR(100),
    telefono VARCHAR(25) NOT NULL,
    parentesco VARCHAR(50),
    fecha_nacimiento DATE CHECK (fecha_nacimiento > '1926-01-01'),
    nro_doc INT CHECK (nro_doc > 999999 AND nro_doc < 100000000),
    tipo_doc VARCHAR(5) CHECK (tipo_doc IN ('DNI', 'LE', 'LC')),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(255),
    PRIMARY KEY (tipo_doc, nro_doc)
);

CREATE TABLE condicion_de_salud (
    id_condicion SERIAL,
    descripcion VARCHAR(255),
    PRIMARY KEY (id_condicion)
);

CREATE TABLE acompañante_terapeutico (
    tipo_doc VARCHAR(5) CHECK (tipo_doc IN ('DNI', 'LE', 'LC')),
    nro_doc INT CHECK (nro_doc > 999999 AND nro_doc < 100000000),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(255),
    fecha_nacimiento DATE CHECK (fecha_nacimiento > '1926-01-01'),
    telefono VARCHAR(25),
    email VARCHAR(100),
    matricula VARCHAR(50) NOT NULL UNIQUE,
    titulo_habilitante VARCHAR(150),
    PRIMARY KEY (tipo_doc, nro_doc)
);


CREATE TABLE coordina (
    id_area_academica BIGINT UNSIGNED,
    nro_doc_docente INT,
    tipo_doc_docente VARCHAR(5),
    PRIMARY KEY (id_area_academica, nro_doc_docente, tipo_doc_docente),
    CONSTRAINT fk_coordina_area FOREIGN KEY (id_area_academica)
        REFERENCES area_academica(id_area_academica) ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_coordina_docente FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(tipo_doc_docente, nro_doc_docente) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE materia (
    id_materia SERIAL,
    nombre VARCHAR(50) NOT NULL,
    anio_academico INT NOT NULL CHECK (anio_academico > 0 AND anio_academico < 6),
    descripcion VARCHAR(255),
    id_area_academica BIGINT UNSIGNED,
    PRIMARY KEY (id_materia),
    CONSTRAINT fk_materia_area FOREIGN KEY (id_area_academica)
        REFERENCES area_academica(id_area_academica) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE lugar (
    numero_salida BIGINT UNSIGNED,
    lugar VARCHAR(150),
    PRIMARY KEY (numero_salida, lugar),
    CONSTRAINT fk_lugar_salida FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE acompaña_salida (
    tipo_doc_docente VARCHAR(5),
    nro_doc_docente INT,
    numero_salida BIGINT UNSIGNED,
    PRIMARY KEY (tipo_doc_docente, nro_doc_docente, numero_salida),
    CONSTRAINT fk_acomp_salida_docente FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(tipo_doc_docente, nro_doc_docente) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_acomp_salida_salida FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ocupa (

    fecha_ini DATE NOT NULL CHECK (fecha_ini > '1970-01-01'),
    tipo_doc_docente VARCHAR(5),
    nro_doc_docente INT,
    id_cargo INT,
    fecha_fin DATE CHECK (fecha_fin > '1970-01-01'),
    PRIMARY KEY (tipo_doc_docente, nro_doc_docente, id_cargo),
    CONSTRAINT fk_ocupa_docente FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(tipo_doc_docente, nro_doc_docente) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ocupa_cargo FOREIGN KEY (id_cargo)
        REFERENCES cargo(id_cargo) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE intervencion (
    id_intervencion SERIAL,
    motivo VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255),
    fecha DATE NOT NULL CHECK (fecha > '1970-01-01'),
    gravedad VARCHAR(50),
    tipo_doc_asesor VARCHAR(5),
    nro_doc_asesor INT,
    tipo_doc_alumno VARCHAR(5),
    nro_doc_alumno INT,
    PRIMARY KEY (id_intervencion),
    CONSTRAINT fk_intervencion_asesor FOREIGN KEY (tipo_doc_asesor, nro_doc_asesor)
        REFERENCES asesor_pedagogico(tipo_doc_pedagogico, nro_doc_pedagogico) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_intervencion_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE calificacion (
    id_calificacion INT,
    fecha DATE NOT NULL,
    id_tipo INT NOT NULL,
    nota INT,
    PRIMARY KEY (id_calificacion),
    CONSTRAINT fk_calif_tipo FOREIGN KEY (id_tipo)
        REFERENCES tipo(id_tipo) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE pertenece (
    ciclo_lectivo VARCHAR(20),
    tipo_doc_alumno VARCHAR(5),
    nro_doc_alumno INT,
    seccion VARCHAR(20),
    turno VARCHAR(20),
    anio_academico INT,
    PRIMARY KEY (ciclo_lectivo, tipo_doc_alumno, nro_doc_alumno, seccion, turno, anio_academico),
    CONSTRAINT fk_pertenece_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pertenece_curso FOREIGN KEY (seccion, turno, anio_academico)
        REFERENCES curso(seccion, turno, anio_academico) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE corresponde_a (
    tipo_doc_tutor VARCHAR(5),
    nro_doc_tutor INT,
    tipo_doc_alumno VARCHAR(5),
    nro_doc_alumno INT,
    PRIMARY KEY (tipo_doc_tutor, nro_doc_tutor, tipo_doc_alumno, nro_doc_alumno),
    CONSTRAINT fk_corresponde_tutor FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_corresponde_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE padece (
    id_condicion BIGINT UNSIGNED,
    nro_doc_alumno INT,
    tipo_doc_alumno VARCHAR(5),
    PRIMARY KEY (id_condicion, tipo_doc_alumno, nro_doc_alumno),
    CONSTRAINT fk_padece_condicion_de_salud FOREIGN KEY (id_condicion)
        REFERENCES condicion_de_salud(id_condicion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_padece_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE acompaña (
    fecha_inicio DATE CHECK (fecha_inicio > '1970-01-01'),
    tipo_doc_ayudante VARCHAR(5),
    nro_doc_ayudante INT,
    tipo_doc_alumno VARCHAR(5),
    nro_doc_alumno INT,
    fecha_fin DATE CHECK (fecha_fin > '1970-01-01'),
    PRIMARY KEY (fecha_inicio, tipo_doc_ayudante, nro_doc_ayudante, tipo_doc_alumno, nro_doc_alumno),
    CONSTRAINT fk_acompaña_terapeuta FOREIGN KEY (tipo_doc_ayudante, nro_doc_ayudante)
        REFERENCES acompañante_terapeutico(tipo_doc, nro_doc) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_acompaña_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE contrata (
    numero_salida BIGINT UNSIGNED,
    cuit_empresa_transporte VARCHAR(20),
    cant_vehiculos INT,
    -- Fix: en el encabezado figuraba "costo_total" pero faltaba en el CREATE TABLE.
    costo_total DECIMAL(12,2),
    PRIMARY KEY (numero_salida, cuit_empresa_transporte),
    CONSTRAINT fk_transporte FOREIGN KEY (cuit_empresa_transporte)
        REFERENCES empresa_transporte(cuit) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_numero_salida FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE participa (
    tipo_doc_alumno VARCHAR(5),
    nro_doc_alumno INT,
    numero_salida BIGINT UNSIGNED,
    PRIMARY KEY (tipo_doc_alumno, nro_doc_alumno, numero_salida),
    CONSTRAINT fk_participa_salida FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_participa_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON DELETE CASCADE ON UPDATE CASCADE
);



CREATE TABLE dictado (
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(2),
    turno VARCHAR(20),
    id_materia BIGINT UNSIGNED,
    tipo_doc_docente VARCHAR(5),
    nro_doc_docente INT,
    PRIMARY KEY (ciclo_lectivo, seccion, turno, id_materia),
    CONSTRAINT fk_dictado_materia FOREIGN KEY (id_materia)
        REFERENCES materia(id_materia) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_dictado_docente FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(tipo_doc_docente, nro_doc_docente) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE se_enmarca_en (
    numero_salida BIGINT UNSIGNED,
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(2),
    turno VARCHAR(20),
    id_materia BIGINT UNSIGNED,
    PRIMARY KEY (numero_salida, ciclo_lectivo, seccion, turno, id_materia),
    CONSTRAINT fk_se_enmarca_salida FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_se_enmarca_id_materia FOREIGN KEY (ciclo_lectivo, seccion, turno, id_materia)
        REFERENCES dictado(ciclo_lectivo, seccion, turno, id_materia) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE asiste (
    nro_doc_alumno INT,
    tipo_doc_alumno VARCHAR(5),
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(2),
    turno VARCHAR(20),
    id_materia BIGINT UNSIGNED,
    id_calificacion INT,
    PRIMARY KEY (id_calificacion),
    CONSTRAINT fk_asiste_alumno FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asiste_dictado FOREIGN KEY (ciclo_lectivo, seccion, turno, id_materia)
        REFERENCES dictado(ciclo_lectivo, seccion, turno, id_materia) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asiste_calificacion FOREIGN KEY (id_calificacion)
        REFERENCES calificacion(id_calificacion) ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE se_notifica_intervencion (
    tipo_doc_tutor VARCHAR(5),
    nro_doc_tutor INT,
    id_intervencion BIGINT UNSIGNED,
    PRIMARY KEY (tipo_doc_tutor, nro_doc_tutor, id_intervencion),
    CONSTRAINT fk_notif_int_tutor FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_notif_int_intervencion FOREIGN KEY (id_intervencion)
        REFERENCES intervencion(id_intervencion) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE se_notifica_calificacion (
    tipo_doc_tutor VARCHAR(5),
    nro_doc_tutor INT,
    id_calificacion INT,
    PRIMARY KEY (tipo_doc_tutor, nro_doc_tutor, id_calificacion),
    CONSTRAINT fk_notif_calif_tutor FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_notif_calif_calificacion FOREIGN KEY (id_calificacion)
        REFERENCES calificacion(id_calificacion) ON DELETE RESTRICT ON UPDATE CASCADE
);
