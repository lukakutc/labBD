SET search_path TO esquema_grupo2;

CREATE INDEX apellido ON esquema_grupo2.alumno USING HASH (apellido);

CREATE INDEX gravedad_fecha ON esquema_grupo2.intervencion USING BTREE (gravedad, fecha);