-- Script
-- Jonathan Bosch

-- Parcial 2
-- Motor de Base de datos: PostgreSQL 16.x

-- ***********************************
-- Abastecimiento de imagen en Docker
-- ***********************************
 
-- Descargar la imagen
docker pull postgres:latest

-- Crear el contenedor
docker run --name examen2-DB -e POSTGRES_PASSWORD=unaClav3 -d -p 5432:5432 postgres:latest

-- ****************************************
-- Creación de base de datos y usuarios
-- ****************************************

-- Conectarse al motor de base de datos (postgres)
psql -U postgres

-- Con usuario Root:

-- crear el esquema la base de datos
create database lluviasantioquia_db;

-- Conectarse a la base de datos
\c lluviasantioquia_db;

-- revocación de privilegios al usuario public
revoke all on database lluviasantioquia_db from public;
revoke create on schema public from public;

-- Creacion del usuario
create user lluviasantioquia_usr with encrypted password 'unaClav3';

-- Otorgamos privilegio para crear schemas
GRANT CREATE ON DATABASE lluviasantioquia_db TO lluviasantioquia_usr;

-- Privilegios de conexión
grant connect, temporary on database lluviasantioquia_db to lluviasantioquia_usr;

-- Privilegios de utilización
grant usage, create on schema public to lluviasantioquia_usr;
grant all on all tables in schema public to lluviasantioquia_usr;
grant all on all sequences in schema public to lluviasantioquia_usr;

grant usage on schema information_schema to lluviasantioquia_usr;
grant usage on schema public to lluviasantioquia_usr;

alter default privileges in schema public
grant select, insert, update, delete on tables to lluviasantioquia_usr;

alter default privileges in schema public
grant usage, select on sequences to lluviasantioquia_usr;

alter default privileges in schema public
grant update on sequences  to lluviasantioquia_usr;

-- referencia de donde me ayude con la creacion de roles y asignacion de privilegios:
-- https://www.qualoom.es/blog/administracion-usuarios-roles-postgresql/

-- *******************************
-- Creacion de tablas
-- *******************************

-- Creamos esquema inicial
create schema inicial;

-- Tabla: Municipios
create table inicial.mediciones
(
    codigo_estacion char(10) not null,
    nombre_estacion varchar(50) not null,
    codigo_sensor char(4) not null,
    nombre_sensor varchar(50) not null,
    nombre_municipio varchar(50) not null,
    nombre_departamento varchar(50) not null,
    nombre_zona_hidrografica varchar(50) not null,
    latitud float not null,
    longitud float not null,
    valor_medicion float not null,
    fecha_medicion timestamp not null
);

create table inicial.divipola
(
    codigo_departamento char(2) not null,
    nombre_departamento varchar(50) not null,
    codigo_municipio char(5) not null,
    nombre_municipio varchar(100) not null
);


--Ya teniendo muy claro las dependencias, procedemos a normalizar las tablas

-- *************************
-- Modelo de dato corregido
-- *************************
create schema corregido;

-- -----------------------
-- Tabla Sensores
-- -----------------------
create table corregido.sensores (
    id int not null generated always as identity constraint sensores_pk primary key,
    codigo_sensor char(4) not null,
    nombre_sensor varchar(50) not null,

    constraint sensores_uk unique (codigo_sensor, nombre_sensor)
);

comment on table corregido.sensores is 'Sensores utilizados para las mediciones';
comment on column corregido.sensores.id is 'id del sensor, autoincremento';
comment on column corregido.sensores.codigo_sensor is 'codigo asociado al sensor';
comment on column corregido.sensores.nombre_sensor is 'Nombre del sensor';

-- Cargamos datos desde el esquema inicial
insert into corregido.sensores (codigo_sensor, nombre_sensor)
(
    select distinct codigo_sensor, nombre_sensor
    from inicial.mediciones
    order by nombre_sensor
);


-- -----------------------
-- Tabla Departamentos
-- -----------------------

create table corregido.departamentos
(
    id int not null generated always as identity constraint departamentos_pk primary key,
    codigo_depto varchar(2) not null,
    nombre_depto char(50) not null, 

    constraint departamentos_uk unique (codigo_depto, nombre_depto) 
);

comment on table corregido.departamentos is 'Departamentos del país';
comment on column corregido.departamentos.id is 'id del departamento, autoincremento';
comment on column corregido.departamentos.codigo_depto is 'Codigo DANE asociado al departamento';
comment on column corregido.departamentos.nombre_depto is 'Nombre del departamento';

-- Cargamos datos desde el esquema inicial
insert into corregido.departamentos (codigo_depto, nombre_depto)
(
    select distinct codigo_departamento, nombre_departamento
    from inicial.divipola  
    order by nombre_departamento
);

-- -----------------------
-- Tabla Municipios
-- -----------------------

create table corregido.municipios
(
    id int not null generated always as identity constraint municipios_pk primary key,
    codigo_municipio char(5) not null,
    nombre_municipio varchar(50) not null,
    id_departamento int not null constraint municipio_departamento_fk references corregido.departamentos,

    constraint municipios_uk unique (codigo_municipio, nombre_municipio)
);

comment on table corregido.municipios is 'Municipios del pais';
comment on column corregido.municipios.id is 'id del municipio, autoincremento';
comment on column corregido.municipios.codigo_municipio is 'codigo DANE asociado al municipio';
comment on column corregido.municipios.nombre_municipio is 'nombre del municipio';
comment on column corregido.municipios.id_departamento is 'ID del departamento asociado al municipio';

-- Cargamos datos desde el esquema inicial
insert into corregido.municipios (codigo_municipio, nombre_municipio, id_departamento)
(
    select distinct codigo_municipio, nombre_municipio, d2.id
    from inicial.divipola d join corregido.departamentos d2
    on d.codigo_departamento = d2.codigo_depto
    order by nombre_municipio    
);

-- -----------------------
-- Tabla Zonas Hidrograficas
-- -----------------------

create table corregido.zonasHidrograficas (
    id int not null generated always as identity constraint zonashidrograficas_pk primary key,
    nombre_zona_hidrografica varchar(50) not null constraint zonasHidrograficas_uk unique

);

comment on table corregido.zonasHidrograficas is 'Zonas Hidrograficas';
comment on column corregido.zonasHidrograficas.id is 'ID de la zona hidrografica, autoincremento';
comment on column corregido.zonasHidrograficas.nombre_zona_hidrografica is 'Nombre de la zona hidrografica';


-- Cargamos datos desde el esquema inicial
insert into corregido.zonasHidrograficas(nombre_zona_hidrografica)
(
    select distinct nombre_zona_hidrografica 
    from inicial.mediciones m 
    order by nombre_zona_hidrografica
);

-- --------------------------------
-- PROBLEMA DE DATOS: ESTACIONES
-- LA MISMA ESTACION (El Rosario) CON 2 LATITUDES DIFERENTES
-- --------------------------------

select distinct nombre_estacion, longitud, latitud
from inicial.mediciones m 
where nombre_estacion = 'El Rosario'
--LATITUD: Estacion el rosario
--5.62583056
--5.625830556

select count(valor_medicion)
from inicial.mediciones m 
where latitud = 5.62583056
-- Registros de medicion con esta latitud: 571

select count(valor_medicion)
from inicial.mediciones m 
where latitud = 5.625830556
-- Registros de medicion con esta latitud: 57.499

--SOLUCION
-- Por lo que vemos en la consulta, hay mas registros con la latitud = 5.625830556, por lo cual vamos a tomar esa latitud
-- como la correcta, entonces vamos a asignarle esa latitud a todas las mediciones de la estacion rosario para
-- que no haya un problema a la hora de cargar los datos en la tabla estaciones (2 estaciones iguales con el mismo nombre
-- y el mismo codigo)
UPDATE inicial.mediciones
SET latitud = 5.625830556
WHERE nombre_estacion = 'El Rosario';

-- -----------------------
-- Tabla Estaciones
-- -----------------------

create table corregido.estaciones
(
    id int generated always as identity constraint estaciones_pk primary key,
    codigo_estacion char(10) not null,
    nombre_estacion varchar(50)  not null,
    latitud float not null,
    longitud float not null,
    id_municipio int not null constraint estacion_municipio_fk references corregido.municipios,
    id_zona int not null constraint estacion_zona_fk references corregido.zonasHidrograficas,

    constraint estaciones_uk unique (codigo_estacion, nombre_estacion, id_municipio, id_zona)
);

comment on table corregido.estaciones is 'Estaciones del pais';
comment on column corregido.estaciones.id is 'id de la estacion, autoincremento';
comment on column corregido.estaciones.codigo_estacion is 'codigo asociado a la estacion';
comment on column corregido.estaciones.nombre_estacion is 'nombre de la estacion';
comment on column corregido.estaciones.latitud is 'latitud en la cual se ubica la estacion';
comment on column corregido.estaciones.longitud is 'longitud en la cual se ubica la estacion';
comment on column corregido.estaciones.id_municipio is 'ID del municipio asociado a la estacion';
comment on column corregido.estaciones.id_zona is 'ID de la Zona Hidrografica asociada a la estacion';

-- Cargamos datos desde el esquema inicial
insert into corregido.estaciones (codigo_estacion, nombre_estacion, latitud, longitud, id_municipio, id_zona)
(
    select distinct codigo_estacion, nombre_estacion, latitud, longitud,  m2.id, z.id  
    from inicial.mediciones m join corregido.municipios m2
    on m.nombre_municipio = m2.nombre_municipio join corregido.zonasHidrograficas z
    on m.nombre_zona_hidrografica = z.nombre_zona_hidrografica 
    order by nombre_estacion
);


-- -----------------------
-- Tabla Mediciones
-- -----------------------
create table corregido.mediciones (
    id_estacion     int not null constraint medicion_estacion_fk references corregido.estaciones,
    id_sensor       int not null constraint medicion_sensor_fk references corregido.sensores,
    valor_medicion  float not null,
    fecha_medicion  timestamp not null,

    constraint mediciones_uk unique (id_estacion, id_sensor, fecha_medicion)
);

comment on table corregido.mediciones is 'Mediciones realizadas en las estaciones';
comment on column corregido.mediciones.id_estacion is 'id de la estacion en la cual fue tomada la medicion';
comment on column corregido.mediciones.id_sensor is 'id del sensor con el cual fue tomada la medicion';
comment on column corregido.mediciones.valor_medicion is 'valor de la medicion';
comment on column corregido.mediciones.fecha_medicion is 'fecha en la cual se tomo la medicion';

-- Cargamos datos desde el esquema inicial
insert into corregido.mediciones(id_estacion, id_sensor, valor_medicion, fecha_medicion)(
   	select e.id, s.id, m.valor_medicion, m.fecha_medicion
    from inicial.mediciones m join corregido.estaciones e
    on m.codigo_estacion = e.codigo_estacion join corregido.sensores s
    on m.codigo_sensor = s.codigo_sensor  
    order by e.id, m.fecha_medicion  
);

-- validamos que si se hayan cargado todos los registros de mediciones
-- Registros en total: 575.551
select count(valor_medicion)
from inicial.mediciones m 

-- Registros cargados en la tabla mediciones:
select count(valor_medicion)
from corregido.mediciones m;


-- *******************************
-- Creación de vistas
-- *******************************

-- ----------------------------
-- VISTA: v_info_estaciones
-- En esa vista se encuentra las estaciones con su respectivo departamento, municipio, zona hidrografica, 
-- latitud, longitud y la cantidad total de registros de medicion por estacion
-- ----------------------------
create or replace view corregido.v_info_estaciones_mediciones as (
    select 
    	e.id as id_estacion,
		e.nombre_estacion,
		d.id as id_departamento,
		d.nombre_depto,
		m.id as id_municipio,
		m.nombre_municipio,
		z.id as id_zona,
		z.nombre_zona_hidrografica,
		e.latitud,
		e.longitud,
        count (m2.valor_medicion) as TotalMediciones,
        min(valor_medicion) as ValorMinimoMedicion,
        max(valor_medicion) as ValorMaximoMedicion
		
	from corregido.estaciones e join corregido.municipios m 
	on e.id_municipio = m.id join corregido.departamentos d 
	on m.id_departamento = d.id join corregido.zonashidrograficas z 
	on e.id_zona = z.id join corregido.mediciones m2 
	on e.id = m2.id_estacion 
	group by e.id, e.nombre_estacion, d.id, d.nombre_depto, m.id, m.nombre_municipio, z.id, z.nombre_zona_hidrografica, 
	e.latitud , e.longitud 
    order by ValorMaximoMedicion desc
);

-- Verificamos que si se hayan cargado todos los registros de medicion
select sum(totalestaciones)
from corregido.v_info_estaciones_mediciones;

-- ----------------------------
-- VISTA: v_info_mediciones_enero
-- En esa vista se encuentra todas las mediciones hechas en el mes de enero con su respectiva estacion y fecha de medicion
-- ----------------------------
create or replace view corregido.v_info_mediciones_enero as(
	select id_estacion, nombre_estacion, valor_medicion, fecha_medicion
	from corregido.mediciones m join corregido.estaciones e 
	on m.id_estacion = e.id
	where extract(year from m.fecha_medicion) = 2023 and extract(month from m.fecha_medicion) = 01
);








