USE escuela_neuquen;

CREATE INDEX gravedad_fecha ON intervencion (gravedad, fecha) USING BTREE; 