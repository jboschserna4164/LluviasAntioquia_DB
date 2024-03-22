-- *****************************************
-- Consultas
-- *****************************************
-- Rango de fechas (01/01/2023 00:00:00  -  31-12-2023 23:40:00)



-- ******************************************************************************************************
-- PREGUNTA 1: Cuál era el valor de la medición para todas las estaciones el día 9 de marzo de 
-- 2023 a las 11:00 am? 
-- ******************************************************************************************************
-- ESQUEMA INICIAL:
select nombre_estacion , valor_medicion, fecha_medicion  
from inicial.mediciones
where fecha_medicion = '2023-03-09 11:00:00.000'

--ESQUEMA CORREGIDO: 
select nombre_estacion , valor_medicion , fecha_medicion 
from corregido.mediciones m join corregido.estaciones e
on m.id_estacion = e.id 
where fecha_medicion = '2023-03-09 11:00:00.000'




-- ******************************************************************************************************
-- PREGUNTA 2: En el mes de Enero cual fue el valor de medicion mas alto de cada estacion y en que fecha
-- se tomo esa medicion
-- ******************************************************************************************************
-- ESQUEMA INICIAL: 
with maximos_mediciones as (
	select codigo_estacion, max(valor_medicion) as maximo
	from inicial.mediciones
	where extract (year from fecha_medicion) = 2023 and extract (month from fecha_medicion) = 1
	group by codigo_estacion	
), mediciones_maximas as (
	select m.nombre_estacion, m.codigo_estacion, m.valor_medicion, m.fecha_medicion, 
	row_number() over (partition by m.codigo_estacion order by m.valor_medicion desc) as rn
	from inicial.mediciones m join maximos_mediciones mm 
	on m.codigo_estacion = mm.codigo_estacion and m.valor_medicion = mm.maximo
	where extract (year from fecha_medicion) = 2023 and extract (month from fecha_medicion) = 1
)
select nombre_estacion, codigo_estacion, valor_medicion as max_valor_medicion, fecha_medicion 
from mediciones_maximas 
where rn = 1
order by max_valor_medicion desc;

-- ESQUEMA CORREGIDO: 
-- Encuentra el valor máximo de la medición para cada estación
with maximos_mediciones as (
    select id_estacion, max(valor_medicion) as max_valor_medicion
    from corregido.v_info_mediciones_enero
    group by id_estacion
),
-- Une la tabla de v_info_mediciones_enero con maximos_mediciones para obtener 
-- los detalles completos de la medición más alta de cada estación, incluida su fecha, 
-- y asigna un número de fila a cada fila dentro de cada partición de estación.
mediciones_maximas as (
    select m.id_estacion, m.nombre_estacion, m.valor_medicion, m.fecha_medicion,
    row_number() over (partition by m.id_estacion order by m.valor_medicion desc) as rn
    from corregido.v_info_mediciones_enero m
    join maximos_mediciones mm on m.id_estacion = mm.id_estacion and m.valor_medicion = mm.max_valor_medicion
)
-- selecciona el ID de la estación, el valor máximo de la medición y la fecha en 
-- que se tomó ese valor máximo, donde el número de fila es igual a 1, lo que significa que es la medición 
-- más alta para cada estación.
select mm.id_estacion, mm.nombre_estacion, mm.valor_medicion as max_valor_medicion, mm.fecha_medicion as fecha_max_valor
from mediciones_maximas mm
where mm.rn = 1
order by max_valor_medicion desc;




-- ******************************************************************************************************
-- PREGUNTA 3: Cuántos municipios diferentes de Antioquia registraron una precipitación superior a 15 mm en el mes
-- de julio de 2023?
-- ******************************************************************************************************
--ESQUEMA INICIAL: 
select distinct nombre_municipio
from inicial.mediciones m 
where nombre_departamento = 'Antioquia' and extract (year from fecha_medicion) = 2023
and extract (month from fecha_medicion) = 07 and valor_medicion > 15

--ESQUEMA CORREGIDO: 
select distinct nombre_municipio 
from corregido.mediciones m join corregido.estaciones e 
on m.id_estacion = e.id join corregido.municipios m2 
on e.id_municipio = m2.id 
where m2.id_departamento = 1 and extract (year from fecha_medicion) = 2023
and extract (month from fecha_medicion) = 07 and valor_medicion > 15




-- ******************************************************************************************************
-- PREGUNTA 4: ¿Cuál fue la estacion con la precipitación promedio más alta en el mes de agosto de 2023 
-- entre el municipio de Puerto Berrío, Valdivia y Cocorná?
-- ******************************************************************************************************
--ESQUEMA INICIAL: 
select nombre_municipio, nombre_estacion, avg(valor_medicion) as promedio
from inicial.mediciones m 
where extract (year from fecha_medicion) = 2023 and extract (month from fecha_medicion) = 08 
and (nombre_municipio = 'Puerto Berrío' or nombre_municipio = 'Valdivia' or nombre_municipio = 'Cocorná')
group by nombre_municipio, nombre_estacion 
order by promedio desc
limit 1

--ESQUEMA CORREGIDO:   
select nombre_municipio, nombre_estacion, avg(valor_medicion) as promedio
from corregido.mediciones m join corregido.estaciones e 
on m.id_estacion = e.id join corregido.municipios m2 
on e.id_municipio = m2.id 
where extract (year from fecha_medicion) = 2023 and extract (month from fecha_medicion) = 08 
and (nombre_municipio = 'Puerto Berrío' or nombre_municipio = 'Valdivia' or nombre_municipio = 'Cocorná')
group by nombre_municipio, nombre_estacion 
order by promedio desc
limit 1



-- ******************************************************************************************************
-- PREGUNTA 5: ¿Cuántos municipios diferentes de Antioquia registraron una precipitación entre 1 mm y 5mm en el mes
-- de febrero de 2023?
-- ******************************************************************************************************
--ESQUEMA INICIAL: 
select distinct nombre_municipio
from inicial.mediciones m 
where nombre_departamento = 'Antioquia' and extract (year from fecha_medicion) = 2023
and extract (month from fecha_medicion) = 02 and valor_medicion between 1 and 5

--ESQUEMA CORREGIDO: 
select distinct nombre_municipio 
from corregido.mediciones m join corregido.estaciones e 
on m.id_estacion = e.id join corregido.municipios m2 
on e.id_municipio = m2.id 
where m2.id_departamento = 1 and extract (year from fecha_medicion) = 2023
and extract (month from fecha_medicion) = 02 and valor_medicion between 1 and 5