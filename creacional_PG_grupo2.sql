-- CREACIONAL - ESQUEMA GRUPO 2
-- PostgreSQL / pgAdmin

DROP SCHEMA IF EXISTS esquema_grupo2 CASCADE;
CREATE SCHEMA esquema_grupo2;

SET search_path TO esquema_grupo2;



CREATE DOMAIN tipo_documento AS VARCHAR(5)
    CHECK (VALUE IN ('DNI', 'LE', 'LC'));

CREATE DOMAIN anio_academico AS INT
    CHECK (VALUE > 0 AND VALUE < 6);

CREATE DOMAIN nro_documento AS INT
    CHECK (VALUE > 999999 AND VALUE < 100000000);

CREATE DOMAIN fecha_nacimiento AS DATE
    CHECK (VALUE > DATE '1926-01-01');

CREATE DOMAIN fecha AS DATE
    CHECK (VALUE > DATE '1970-01-01');




CREATE TABLE alumno (
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento fecha_nacimiento NOT NULL,
    fecha_ingreso fecha NOT NULL,
    fecha_egreso fecha,
    PRIMARY KEY (tipo_doc_alumno, nro_doc_alumno)
);


CREATE TABLE personal_docente (
    tipo_doc_docente tipo_documento,
    nro_doc_docente nro_documento,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento fecha_nacimiento NOT NULL,
    titulo_habilitante VARCHAR(100) NOT NULL,
    telefono VARCHAR(25),
    email VARCHAR(50),
    fecha_ingreso fecha NOT NULL,
    PRIMARY KEY (tipo_doc_docente, nro_doc_docente)
);


CREATE TABLE asesor_pedagogico (
    tipo_doc_pedagogico tipo_documento,
    nro_doc_pedagogico nro_documento,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100),
    nacionalidad VARCHAR(50),
    fecha_nacimiento fecha_nacimiento NOT NULL,
    titulo_habilitante VARCHAR(100) NOT NULL,
    telefono VARCHAR(25),
    email VARCHAR(50),
    fecha_ingreso fecha NOT NULL,
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
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
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


CREATE TABLE curso (
    seccion VARCHAR(20),
    turno VARCHAR(20),
    anio_academico anio_academico,
    PRIMARY KEY (seccion, turno, anio_academico)
);


CREATE TABLE tutor (
    email VARCHAR(100),
    telefono VARCHAR(25) NOT NULL,
    parentesco VARCHAR(50),
    fecha_nacimiento fecha_nacimiento,
    nro_doc nro_documento,
    tipo_doc tipo_documento,
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
    tipo_doc tipo_documento,
    nro_doc nro_documento,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    domicilio VARCHAR(255),
    fecha_nacimiento fecha_nacimiento,
    telefono VARCHAR(25),
    email VARCHAR(100),
    matricula VARCHAR(50) NOT NULL UNIQUE,
    titulo_habilitante VARCHAR(150),
    PRIMARY KEY (tipo_doc, nro_doc)
);


CREATE TABLE tipo (
    id_tipo INT,
    descripcion VARCHAR(50),
    PRIMARY KEY (id_tipo)
);


CREATE TABLE materia (
    id_materia SERIAL,
    nombre VARCHAR(50) NOT NULL,
    anio_academico anio_academico NOT NULL,
    descripcion VARCHAR(255),
    id_area_academica INT DEFAULT -1,
    PRIMARY KEY (id_materia),
    CONSTRAINT fk_materia_area
        FOREIGN KEY (id_area_academica)
        REFERENCES area_academica(id_area_academica)
        ON UPDATE CASCADE
        ON DELETE SET DEFAULT
);


CREATE TABLE calificacion (
    id_calificacion INT,
    fecha DATE NOT NULL,
    id_tipo INT NOT NULL,
    nota INT,
    PRIMARY KEY (id_calificacion),
    CONSTRAINT fk_calif_tipo
        FOREIGN KEY (id_tipo)
        REFERENCES tipo(id_tipo)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE coordina (
    id_area_academica INT,
    nro_doc_docente nro_documento,
    tipo_doc_docente tipo_documento,
    PRIMARY KEY (
        id_area_academica,
        nro_doc_docente,
        tipo_doc_docente
    ),
    CONSTRAINT fk_coordina_area
        FOREIGN KEY (id_area_academica)
        REFERENCES area_academica(id_area_academica)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_coordina_docente
        FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(
            tipo_doc_docente,
            nro_doc_docente
        )
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE dictado (
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(2),
    turno VARCHAR(20),
    id_materia INT,
    tipo_doc_docente tipo_documento,
    nro_doc_docente nro_documento,
    PRIMARY KEY (
        ciclo_lectivo,
        seccion,
        turno,
        id_materia
    ),
    CONSTRAINT fk_dictado_materia
        FOREIGN KEY (id_materia)
        REFERENCES materia(id_materia)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_dictado_docente
        FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(
            tipo_doc_docente,
            nro_doc_docente
        )
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE lugar (
    numero_salida INT,
    lugar VARCHAR(150),
    PRIMARY KEY (numero_salida, lugar),
    CONSTRAINT fk_lugar_salida
        FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE se_enmarca_en (
    numero_salida INT,
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(20),
    turno VARCHAR(20),
    id_materia INT,
    PRIMARY KEY (
        numero_salida,
        ciclo_lectivo,
        seccion,
        turno,
        id_materia
    ),
    CONSTRAINT fk_se_enmarca_salida
        FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_se_enmarca_id_materia
        FOREIGN KEY (
            ciclo_lectivo,
            seccion,
            turno,
            id_materia
        )
        REFERENCES dictado(
            ciclo_lectivo,
            seccion,
            turno,
            id_materia
        )
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE participa (
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    numero_salida INT,
    PRIMARY KEY (
        tipo_doc_alumno,
        nro_doc_alumno,
        numero_salida
    ),
    CONSTRAINT fk_participa_salida
        FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_participa_salida_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE acompaña_salida (
    tipo_doc_docente tipo_documento,
    nro_doc_docente nro_documento,
    numero_salida INT,
    PRIMARY KEY (
        tipo_doc_docente,
        nro_doc_docente,
        numero_salida
    ),
    CONSTRAINT fk_acomp_salida_docente
        FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(
            tipo_doc_docente,
            nro_doc_docente
        )
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_acomp_salida_salida
        FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


CREATE TABLE ocupa (
    fecha_ini fecha NOT NULL,
    tipo_doc_docente tipo_documento,
    nro_doc_docente nro_documento,
    id_cargo INT,
    fecha_fin fecha,
    PRIMARY KEY (
        tipo_doc_docente,
        nro_doc_docente,
        id_cargo
    ),
    CONSTRAINT fk_ocupa_docente
        FOREIGN KEY (tipo_doc_docente, nro_doc_docente)
        REFERENCES personal_docente(
            tipo_doc_docente,
            nro_doc_docente
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ocupa_cargo
        FOREIGN KEY (id_cargo)
        REFERENCES cargo(id_cargo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE intervencion (
    id_intervencion SERIAL,
    motivo VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255),
    fecha fecha NOT NULL,
    gravedad VARCHAR(50),
    tipo_doc_asesor tipo_documento,
    nro_doc_asesor nro_documento,
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    PRIMARY KEY (id_intervencion),
    CONSTRAINT fk_intervencion_asesor
        FOREIGN KEY (tipo_doc_asesor, nro_doc_asesor)
        REFERENCES asesor_pedagogico(
            tipo_doc_pedagogico,
            nro_doc_pedagogico
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_intervencion_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(
            tipo_doc_alumno,
            nro_doc_alumno
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE asiste (
    nro_doc_alumno nro_documento,
    tipo_doc_alumno tipo_documento,
    ciclo_lectivo VARCHAR(10),
    seccion VARCHAR(2),
    turno VARCHAR(20),
    id_materia INT,
    id_calificacion INT,
    PRIMARY KEY (id_calificacion),
    CONSTRAINT fk_asiste_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(
            tipo_doc_alumno,
            nro_doc_alumno
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_asiste_dictado
        FOREIGN KEY (
            ciclo_lectivo,
            seccion,
            turno,
            id_materia
        )
        REFERENCES dictado(
            ciclo_lectivo,
            seccion,
            turno,
            id_materia
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_asiste_calificacion
        FOREIGN KEY (id_calificacion)
        REFERENCES calificacion(id_calificacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE pertenece (
    ciclo_lectivo VARCHAR(20),
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    seccion VARCHAR(20),
    turno VARCHAR(20),
    anio_academico anio_academico,
    PRIMARY KEY (
        ciclo_lectivo,
        tipo_doc_alumno,
        nro_doc_alumno,
        seccion,
        turno,
        anio_academico
    ),
    CONSTRAINT fk_pertenece_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(
            tipo_doc_alumno,
            nro_doc_alumno
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_pertenece_curso
        FOREIGN KEY (seccion, turno, anio_academico)
        REFERENCES curso(
            seccion,
            turno,
            anio_academico
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE corresponde_a (
    tipo_doc_tutor tipo_documento,
    nro_doc_tutor nro_documento,
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    PRIMARY KEY (
        tipo_doc_tutor,
        nro_doc_tutor,
        tipo_doc_alumno,
        nro_doc_alumno
    ),
    CONSTRAINT fk_corresponde_tutor
        FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_corresponde_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(tipo_doc_alumno, nro_doc_alumno)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE se_notifica_intervencion (
    tipo_doc_tutor tipo_documento,
    nro_doc_tutor nro_documento,
    id_intervencion INT,
    PRIMARY KEY (
        tipo_doc_tutor,
        nro_doc_tutor,
        id_intervencion
    ),
    CONSTRAINT fk_notif_int_tutor
        FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_notif_int_intervencion
        FOREIGN KEY (id_intervencion)
        REFERENCES intervencion(id_intervencion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE padece (
    id_condicion INT,
    nro_doc_alumno nro_documento,
    tipo_doc_alumno tipo_documento,
    PRIMARY KEY (
        id_condicion,
        tipo_doc_alumno,
        nro_doc_alumno
    ),
    CONSTRAINT fk_padece_condicion_de_salud
        FOREIGN KEY (id_condicion)
        REFERENCES condicion_de_salud(id_condicion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_padece_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(
            tipo_doc_alumno,
            nro_doc_alumno
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE acompaña (
    fecha_inicio fecha,
    tipo_doc_ayudante tipo_documento,
    nro_doc_ayudante nro_documento,
    tipo_doc_alumno tipo_documento,
    nro_doc_alumno nro_documento,
    fecha_fin fecha,
    PRIMARY KEY (
        fecha_inicio,
        tipo_doc_ayudante,
        nro_doc_ayudante,
        tipo_doc_alumno,
        nro_doc_alumno
    ),
    CONSTRAINT fk_acompaña_terapeuta
        FOREIGN KEY (tipo_doc_ayudante, nro_doc_ayudante)
        REFERENCES acompañante_terapeutico(
            tipo_doc,
            nro_doc
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_acompaña_alumno
        FOREIGN KEY (tipo_doc_alumno, nro_doc_alumno)
        REFERENCES alumno(
            tipo_doc_alumno,
            nro_doc_alumno
        )
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE se_notifica_calificacion (
    tipo_doc_tutor tipo_documento,
    nro_doc_tutor nro_documento,
    id_calificacion INT,
    PRIMARY KEY (
        tipo_doc_tutor,
        nro_doc_tutor,
        id_calificacion
    ),
    CONSTRAINT fk_notif_calif_tutor
        FOREIGN KEY (tipo_doc_tutor, nro_doc_tutor)
        REFERENCES tutor(tipo_doc, nro_doc)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_notif_calif_calificacion
        FOREIGN KEY (id_calificacion)
        REFERENCES calificacion(id_calificacion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE contrata (
    numero_salida INT,
    cuit_empresa_transporte VARCHAR(20),
    cant_vehiculos INT,
    costo_total NUMERIC,
    PRIMARY KEY (
        numero_salida,
        cuit_empresa_transporte
    ),
    CONSTRAINT fk_transporte
        FOREIGN KEY (cuit_empresa_transporte)
        REFERENCES empresa_transporte(cuit)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_numero_salida
        FOREIGN KEY (numero_salida)
        REFERENCES salida(numero_salida)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
