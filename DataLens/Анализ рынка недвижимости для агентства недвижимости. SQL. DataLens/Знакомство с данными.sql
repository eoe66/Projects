--====================================================================================================================================================================================
--Знакомство с данными таблицы advertisement
/* Выводы: всего 23650 объявлений;
		   дата начала размещения 2014-11-27, дата  размещения последнего объявления 2019-05-03;
		   всего 1618 дней = 4 years 5 mons 6 days;
		   есть пропуски в поле days_exposition, значит объект не продан, их количество 3180 объявлений ( т.е. 13,45% от всех объявлений);
		   минимальная длительность размещения объявления 1 день, максимальная 1580 (для проданных объектов);
           большая часть не проданных объявлений приходится на 2019 г, т.е. "свежие" объявления - 1796 шт., меньше всего на 2014 года - 18 шт.;
           минимальная стоимость квартиры 12.190 руб, максимальная 763.000.000 руб      
*/
--====================================================================================================================================================================================
/*Таблица advertisement (объявления):
 * id                    номер объявления,
 * first_day_exposition  первый день размещения
 * days_exposition       дней размещения объявления
 * last_price            последняя цена продажи*/

/*Первые 10 строк таблицы*/
select *
from real_estate.advertisement
limit 10;
----+--------------------+---------------+----------+
--id|first_day_exposition|days_exposition|last_price|
----+--------------------+---------------+----------+
-- 0|          2019-03-07|               |  13000000|
-- 1|          2018-12-04|           81.0| 3350000.0|
-- 2|          2015-08-20|          558.0| 5196000.0|
-- 3|          2015-07-24|          424.0|  64900000|
-- 4|          2018-06-19|          121.0|  10000000|
-- 5|          2018-09-10|           55.0| 2890000.0|
-- 6|          2017-11-02|          155.0| 3700000.0|
-- 7|          2019-04-18|               | 7915000.0|
-- 8|          2018-05-23|          189.0| 2900000.0|
-- 9|          2017-02-26|          289.0| 5400000.0|
----+--------------------+---------------+----------+


/*Количество непроданных квартир (разбивка по годам; пропуски в поле days_exposition), общее количество и доля  */
select  count(*) filter( where days_exposition is null and date_part('year', first_day_exposition) = '2014' )  as count_2014,
		count(*) filter( where days_exposition is null and date_part('year', first_day_exposition) = '2015' )  as count_2015,
		count(*) filter( where days_exposition is null and  date_part('year', first_day_exposition) = '2016' ) as count_2016,
		count(*) filter( where days_exposition is null and date_part('year', first_day_exposition) = '2017' )  as count_2017,
		count(*) filter( where days_exposition is null and date_part('year', first_day_exposition) = '2018' )  as count_2018,
		count(*) filter( where days_exposition is null and date_part('year', first_day_exposition) = '2019' )  as count_2019,
		count(*) filter( where days_exposition is null)                                                        as total_count,
		round((count(*) filter( where days_exposition is null)) * 1.0 / count(*), 4)                           as доля_непроданных,
		1 - round((count(*) filter( where days_exposition is null)) * 1.0 / count(*), 4)                       as доля_проданных
from real_estate.advertisement
;
--
------------+----------+----------+----------+----------+----------+-----------+-----------------+--------------+
--count_2014|count_2015|count_2016|count_2017|count_2018|count_2019|total_count|доля_непроданных |доля_проданных|
------------+----------+----------+----------+----------+----------+-----------+-----------------+--------------+
--        18|        70|        67|       271|       958|      1796|       3180|           0.1345|        0.8655|
------------+----------+----------+----------+----------+----------+-----------+-----------------+--------------+


/*Описательная статистика*/
select  count(*)                                                                                                as count_advertisement,
		min(first_day_exposition)                                                                               as min_first_day_exposition,
		max(first_day_exposition)                                                                               as max_first_day_exposition,
		max(first_day_exposition) - min(first_day_exposition)                                                   as day_exposition,
		age(max(first_day_exposition), min(first_day_exposition))                                               as period_exposition,
		min(days_exposition) filter (where days_exposition is not null)                                         as min_days_exposition,
		max(days_exposition) filter (where days_exposition is not null)                                         as max_days_exposition,
		avg(days_exposition) filter (where days_exposition is not null)                                         as avg_days_exposition,
		percentile_cont(0.5) within group (order by days_exposition) filter (where days_exposition is not null) as perc_days_exposition,
		stddev(days_exposition) filter (where days_exposition is not null)                                      as stddev_days_exposition,
		min(last_price)                                                                                         as min_last_price,
		max(last_price)                                                                                         as max_last_price,
		avg(last_price)                                                                                         as avg_last_price,
		percentile_cont(0.5) within group (order by last_price)                                                 as perc_last_price,
		stddev(last_price)                                                                                      as stddev_last_price
from real_estate.advertisement
;
---------------------+------------------------+------------------------+--------------+---------------------+
--count_advertisement|min_first_day_exposition|max_first_day_exposition|day_exposition|period_exposition    |
---------------------+------------------------+------------------------+--------------+---------------------+
--              23650|              2014-11-27|              2019-05-03|          1618|4 years 5 mons 6 days|
---------------------+------------------------+------------------------+--------------+---------------------+
--
---------------------+-------------------+-------------------+--------------------+----------------------+         
--min_days_exposition|max_days_exposition|avg_days_exposition|perc_days_exposition|stddev_days_exposition|
---------------------+-------------------+-------------------+--------------------+----------------------+
--                1.0|             1580.0|  180.7531998045921|                95.0|    219.77791556230014|
---------------------+-------------------+-------------------+--------------------+----------------------+
--
----------------+--------------+-----------------+---------------+------------------+
--min_last_price|max_last_price|avg_last_price   |perc_last_price|stddev_last_price |
----------------+--------------+-----------------+---------------+------------------+
--       12190.0|     763000000|6541126.897928119|      4650000.0|10896399.175037924|
----------------+--------------+-----------------+---------------+------------------+


/*Самый длинный срок продажи недвижимости в годах, месяцах и днях*/
select  city, type, first_day_exposition, days_exposition, age(first_day_exposition + days_exposition::integer, first_day_exposition)
from real_estate.advertisement
join real_estate.flats    as f using(id)
join real_estate.city          as c using(city_id)
join real_estate.type          as t using(type_id)
where days_exposition is not null and type = 'город'
order by days_exposition desc
limit 1
;
--среди всех объявлений
-----------------+-------+--------------------+---------------+----------------------+
--city           |type   |first_day_exposition|days_exposition|age                   |
-----------------+-------+--------------------+---------------+----------------------+
--Новое Девяткино|деревня|          2014-12-15|         1580.0|4 years 3 mons 29 days|
-----------------+-------+--------------------+---------------+----------------------+
--среди городов
-----------------+-----+--------------------+---------------+----------------------+
--city           |type |first_day_exposition|days_exposition|age                   |
-----------------+-----+--------------------+---------------+----------------------+
--Санкт-Петербург|город|          2014-12-09|         1572.0|4 years 3 mons 21 days|
-----------------+-----+--------------------+---------------+----------------------+

/*Самый короткий срок продажи недвижимости в годах, месяцах и днях*/
select  city, type, first_day_exposition, days_exposition, age(first_day_exposition + days_exposition::integer, first_day_exposition)
from real_estate.advertisement
join real_estate.flats    as f using(id)
join real_estate.city          as c using(city_id)
join real_estate.type          as t using(type_id)
where days_exposition is not null and type = 'город'
order by days_exposition
limit 1
;
-----------------+-----+--------------------+---------------+-----+
--city           |type |first_day_exposition|days_exposition|age  |
-----------------+-----+--------------------+---------------+-----+
--Санкт-Петербург|город|          2019-05-01|            1.0|1 day|
-----------------+-----+--------------------+---------------+-----+



--====================================================================================================================================================================================
--Знакомство с данными таблицы city 
--====================================================================================================================================================================================
/*Таблица city (города):
 * city_id      идентификатор города
 * city         город
*/

/*Первые 5 строк таблицы и общее количество населенных пунктов*/
select *,
	count(*) over() as total_count_city
from real_estate.city
limit 5;
/*Всего в базе представлена информация о 305 населенных пунктах*/
---------+------------+----------------+
--city_id|city        |total_count_city|
---------+------------+----------------+
--GOET   |Бокситогорск|             305|
--H8WO   |Волосово    |             305|
--S4Y8   |Волхов      |             305|
--Y04Q   |Всеволожск  |             305|
--0SI2   |Выборг      |             305|
---------+------------+----------------+


--====================================================================================================================================================================================
--Знакомство с данными таблицы type 
--====================================================================================================================================================================================
/*Таблица type (тип):
 * type_id      идентификатор типа
 * type         тип
*/

/*Первые 5 строк таблицы и количество типов*/
select *,
	count(*) over() as total_count_type
from real_estate.type
limit 5;
/*Всего 10 типов населенных пунктов*/
---------+------------------+----------------+
--type_id|type              |total_count_type|
---------+------------------+----------------+
--F8EM   |город             |              10|
--LVBX   |городской посёлок |              10|
--9N9J   |деревня           |              10|
--CW5N   |коттеджный посёлок|              10|
--IZIQ   |посёлок           |              10|
---------+------------------+----------------+


--====================================================================================================================================================================================
--Знакомство с данными таблицы flats 
--
/*Выводы по результатам:
 *	В таблице flats 23650 строк
 *	В таблице flats есть 16 объектов недвижимости с одинаковыми характеристиками (разные id), однако у них различные даты публикации, сроки активности и стоимости.
 *	Поле total_area: нет пропусков и нулевых значений; минимальное значение 12, максимальное 900; среднее (60,33) значительны выше медианы (52,0),
 *					 необходимо ограничить выборку сверху - 99 перцентиль равен 197,9	
 *  Поле rooms: нет пропусков, есть 197 нулевых знаений; минимальное значение (без 0) 1, максимальное 19 - многовато; среднее (2,07) очень близко к медиане (2,0); есть аномально высокие и низкие
 * 				значения; необходимо ограничить выборку сверху -  99 перцентиль равен 5,0	 
 *  Поле ceiling_height: есть 9160 пропусков, нет нулевых значений; минимальное значение 1, максимальное 100; среднее (2,77) несколько выше чем медиана (2,65); есть аномально высокие 
 *                       и низкие значения; необходимо ограничить выборку снизу - 01 перцентиль равен 2,5 и сверху -  99 перцентиль равен 3,82.
 * 						 У 145 объектов аномально высокие значения высоты потолка, а у 73 - аномально низкие. У некоторых объектов вероятно ошибка в разрядах, например указано 27м,
 *                       вероятно должно быть 2,7м. Перед фильтрацией можно откорректировать значения,чтобы сохранить больше объектов в выборке.
 *  Поле floors_total: есть 86 пропусков, нет нулевых значений; минимальное значение 1, максимальное 60; среднее (10,68) сильно выше медианы (2,0);
 * 				       99 перцентиль равен 26.
 *  Поле living_area:  есть 1898 пропусков, нет нулевых значений; минимальное значение 2, максимальное 409,7; среднее (34,45) несколько выше медианы (30,0); 01 перцентиль равен 13,0;
 * 					    99 перцентиль равен 120,0; 
 *  Поле floor:        нет пропусков и нулевых значений; минимальное значение 1, максимальное 33;  среднее (5,89) немного выше медианы (4,0); 99 перцентиль равен 23,0	
 *  Поле is_apartment: пропусков нет; доля апартаментов от всех объектов составляет 0,21%
 *  ! Поле balcony:    нет пропусков, 3725 нулевых значений; минимальное значение 0, максимальное 5 - слишком много; среднее (1,15) незначительно выше медианы (1,0);
 *  Поле kitchen_area: есть 2269 пропусков, нет нулевых значений; минимальное значение 1,3, максимальное 112; среднее (10.57) несколько выше медианы (9,1); 
 *  Поле living_area:  есть 1898 пропусков, нет нулевых значений; минимальное значение 2, максимальное 409,7; среднее (34,45) несколько выше медианы (30,0); есть аномально высокие и низкие
 * 				       значения; 01 перцентиль равен 13,0 ; 99 перцентиль равен 120,0;
 *  Поле open_plan: пропусков нет; доля студий от всех объектов составляет 0,28%; у 5 студий указано количество комнат более 1 - вероятно это зоны, а 59 указано количество комнат 0 - странно
 *  Поле airports_nearest: пропусков нет, одно нулевой значение; минимальное значение 6450 (без учета нулевого), максимальное 84869; среднее (28803,23), очень большой разброс данных (78419),
 *                         медиана ниже среднего (28803,23); 99 перцентиль равен 58514,75;  
 *  Поле parks_around3000: 5510 пропусков, 10080 нулей и 8060 ненулевых значений; минимальное значение 1 (без учета нулей), максимальное 3; парк или есть или его нет, поэтому пропуски необходимо
 *                         заменить нулевыми значениями
 *  Поле ponds_around3000: 5510 пропусков, 9055 нулей и 9085 ненулевых значений; минимальное значение 1 (без учета нулей), максимальное 3; водоем или есть или его нет, поэтому пропуски необходимо
 *                         заменить нулевыми значениями
 * 
 *  Стоимость квартиры:  минимальное значение 12.190 (вероятно оно указано в тысячах), максимальное значение 763.000.000; среднее 6.541.126,90 значительно выше медианы 4.650.000,0;
 *                       есть аномально высокие и низкие значения; необходимо внести корректировку минимального значения и ограничить выборку снизу и сверху.
 *  Средняя цена за квадратный метр: минимальное значение 111,83, максимальное значение 1.907.500; среднее 99.432,25 несколько выше медианы 95.000,0;
 *                                   есть аномально высокие и низкие значения; необходимо внести корректировку минимального значения
 */
--====================================================================================================================================================================================

/*
 * Таблица flats (квартиры):
 * id                  идентификатор объявления
 * city_id             идентификатор города
 * type_id             идентификатор типа
 * total_area          общая площадь
 * rooms               количество комнат
 * ceiling_height      высота потолка
 * floors_total        всего этажей
 * living_area         жилая площадь
 * floor               этаж расположения квартиры
 * is_apartment        апартаменты
 * open_plan           открытая планировка
 * kitchen_area        площадь кухни
 * balcony             количество балконов
 * airports_nearest    расстояние до ближайшего аэропорта
 * parks_around3000    количество парков вблизи 3000м
 * ponds_around3000    количество водоемов вблизи 3000м
*/

/*Количество строк в таблице*/
select count(*)
from real_estate.flats;
-------+
--count|
-------+
--23650|
-------+


/*Проверка на наличие неявных дубликатов: количество дубликатов по всем полям кроме id найдено 16 штук*/
with
t1 as (
	select  count(*) as count_flats, city_id, type_id, total_area, rooms, ceiling_height, floors_total, living_area, floor, is_apartment, open_plan,
			kitchen_area, balcony, airports_nearest, parks_around3000, ponds_around3000
	from real_estate.flats
	group by    city_id, type_id, total_area, rooms, ceiling_height, floors_total, living_area, floor, is_apartment, open_plan,
				kitchen_area, balcony, airports_nearest, parks_around3000, ponds_around3000
	having count(*) > 1
)
select count(*)  from t1;
-------+
--count|
-------+
--   16|
-------+

/*Проверка на наличие неявных дубликатов после объедиения двух таблиц flats и advertisement: количество дубликатов по всем полям (в том числе по дате публикации,
 *  периоду публикации и стоимости) кроме id*/
with
t1 as (
	select  count(*) as count_flats, city_id, type_id, total_area, rooms, ceiling_height, floors_total, living_area, floor, is_apartment, open_plan,
			kitchen_area, balcony, airports_nearest, parks_around3000, ponds_around3000, /*a.first_day_exposition, a.days_exposition ,*/ a.last_price
	from real_estate.flats
	join real_estate.advertisement as a using(id)
	group by    city_id, type_id, total_area, rooms, ceiling_height, floors_total, living_area, floor, is_apartment, open_plan,
				kitchen_area, balcony, airports_nearest, parks_around3000, ponds_around3000, a.first_day_exposition, a.days_exposition, a.last_price
	having count(*) > 1
)
select count(*)  from t1;
-------+
--count|
-------+
--    0|
-------+


/*Первые 10 строк таблицы*/
select *
from real_estate.flats
limit 10;
-- 
----+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id|city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
----+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
-- 0|6X8I   |F8EM   |     108.0|    3|           2.7|        16.0|       51.0|    8|           0|        0|        25.0|       |         18863.0|             1.0|             2.0|
-- 1|FMVZ   |IZIQ   |      40.4|    1|              |        11.0|       18.6|    1|           0|        0|        11.0|    2.0|         12817.0|             0.0|             0.0|
-- 2|6X8I   |F8EM   |      56.0|    2|              |         5.0|       34.3|    4|           0|        0|         8.3|    0.0|         21741.0|             1.0|             2.0|
-- 3|6X8I   |F8EM   |     159.0|    3|              |        14.0|           |    9|           0|        0|            |    0.0|         28098.0|             2.0|             3.0|
-- 4|6X8I   |F8EM   |     100.0|    2|          3.03|        14.0|       32.0|   13|           0|        0|        41.0|       |         31856.0|             2.0|             1.0|
----+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+



/***   Статистика по полю total_area   ***/
select  count(*) filter (where total_area is null)               as total_area_is_null,
		count(*) filter (where total_area = 0)                   as total_area_zero,
        min(total_area) filter (where total_area != 0)           as min_total_area,
		max(total_area)                                          as max_total_area,
		round(avg(total_area)::numeric, 2)                       as avg_total_area,
		percentile_cont(0.5) within group (order by total_area)  as perc_total_area,
		stddev(total_area)                                       as stddev_total_area,
		percentile_cont(0.01) within group (order by total_area) as _01_perc_total_area,
		percentile_cont(0.25) within group (order by total_area) as _25_perc_total_area,
		percentile_cont(0.75) within group (order by total_area) as _75_perc_total_area,
		percentile_disc(0.99) within group (order by total_area) as _99_perc_total_area
from real_estate.flats;
--
--------------------+---------------+--------------+--------------+--------------+---------------+------------------+-------------------+-------------------+-------------------+-------------------+
--total_area_is_null|total_area_zero|min_total_area|max_total_area|avg_total_area|perc_total_area|stddev_total_area |_01_perc_total_area|_25_perc_total_area|_75_perc_total_area|_99_perc_total_area|
--------------------+---------------+--------------+--------------+--------------+---------------+------------------+-------------------+-------------------+-------------------+-------------------+
--                 0|              0|          12.0|         900.0|         60.33|           52.0|35.661808081814364|  25.17450017929077|               40.0|  69.69999694824219|              197.9|
--------------------+---------------+--------------+--------------+--------------+---------------+------------------+-------------------+-------------------+-------------------+-------------------+


/*ТОП-10 квартир с самой большой площадью: квартира 900кв.м. - это реальная квартира бизнес-класса на ул. Кораблестроителей. Это 3-х этажная квартира - пентхаус в 25-этажном доме*/
select  *
from real_estate.flats
order by  total_area desc
limit 10;
--
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--19540|6X8I   |F8EM   |     900.0|   12|           2.8|        25.0|      409.7|   25|           0|        0|       112.0|       |         30706.0|             0.0|             2.0|
--12859|6X8I   |F8EM   |     631.2|    7|           3.9|         4.0|      322.3|    4|           0|        0|        19.5|    1.0|         25707.0|             0.0|             2.0|
-- 3117|6X8I   |F8EM   |     631.0|    7|              |         5.0|           |    5|           0|        0|        60.0|       |         25707.0|             0.0|             2.0|
--15651|6X8I   |F8EM   |     618.0|    7|           3.4|         7.0|      258.0|    5|           0|        0|        70.0|       |         32440.0|             0.0|             2.0|
-- 5358|6X8I   |F8EM   |     590.0|   15|           3.5|         6.0|      409.0|    3|           0|        0|       100.0|       |         24447.0|             1.0|             0.0|
-- 4237|6X8I   |F8EM   |     517.0|    7|              |         4.0|      332.0|    3|           0|        0|        22.0|       |         22835.0|             2.0|             2.0|
-- 8018|6X8I   |F8EM   |     507.0|    5|          4.45|         7.0|      301.5|    7|           1|        0|        45.5|    1.0|                |             2.0|             0.0|
--15016|6X8I   |F8EM   |     500.0|    4|           3.2|         7.0|           |    7|           0|        0|            |    0.0|         33058.0|             3.0|             3.0|
-- 5893|6X8I   |F8EM   |     500.0|    6|              |         7.0|           |    7|           0|        0|        40.0|    0.0|         32440.0|             0.0|             2.0|
--12401|6X8I   |F8EM   |     495.0|    7|          4.65|         7.0|      347.5|    7|           0|        0|        25.0|    0.0|                |             2.0|             0.0|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+

/*ТОП-10 квартир с самой маленькой площадью: миниквартира с площадью 12 кв.м.*/
select  *
from real_estate.flats
order by  total_area
limit 10;
/*
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--19904|6X8I   |F8EM   |      12.0|    1|          2.55|         5.0|       10.0|    2|           0|        0|            |       |         21314.0|             1.0|             2.0|
--17961|6X8I   |F8EM   |      13.0|    1|           2.6|         9.0|           |    1|           0|        0|            |       |         14350.0|             0.0|             1.0|
--19546|6X8I   |F8EM   |      13.0|    1|           3.4|         5.0|           |    2|           0|        0|            |       |         24915.0|             1.0|             0.0|
--19807|6X8I   |F8EM   |      13.0|    1|              |         5.0|       10.0|    3|           0|        0|            |       |         21302.0|             1.0|             3.0|
--19558|6X8I   |F8EM   |      13.2|    1|              |         5.0|           |    1|           0|        0|            |       |         19891.0|             1.0|             1.0|
--19642|6X8I   |F8EM   |      14.0|    1|              |         5.0|       11.0|    1|           0|        0|         2.0|       |          9898.0|             0.0|             0.0|
--12040|PJ2I   |F8EM   |      15.0|    1|           2.5|         5.0|           |    1|           0|        0|            |       |                |                |                |
--16949|6X8I   |F8EM   |      15.0|    1|           2.7|         9.0|           |    1|           0|        0|            |       |         51048.0|             0.0|             1.0|
-- 8886|6X8I   |F8EM   |      15.5|    0|              |         5.0|       10.0|    2|           0|        0|            |       |         24326.0|             0.0|             1.0|
-- 9412|6X8I   |F8EM   |      16.0|    0|              |         6.0|       13.0|    1|           0|        1|            |       |         20735.0|             2.0|             3.0|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
*/


/***   Статистика по полю rooms  ***/
select  count(*) filter (where rooms is null)               as rooms_is_null,
		count(*) filter (where rooms = 0)                   as rooms_zero,
		min(rooms) filter (where rooms != 0)                as min_rooms,
		max(rooms)                                          as max_rooms,
		round((avg(rooms))::numeric, 2)                     as avg_rooms,
		percentile_cont(0.5) within group (order by rooms)  as perc_rooms,
		stddev(rooms)                                       as stddev_rooms,
		percentile_cont(0.01) within group (order by rooms) as _01_perc_rooms,
		percentile_cont(0.25) within group (order by rooms) as _25_perc_rooms,
		percentile_cont(0.75) within group (order by rooms) as _75_perc_rooms,
		percentile_cont(0.99) within group (order by rooms) as _99_perc_rooms
from real_estate.flats;
--
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+
--rooms_is_null|rooms_zero|min_rooms|max_rooms|avg_rooms|perc_rooms|stddev_rooms      |_01_perc_rooms|_25_perc_rooms|_75_perc_rooms|_99_perc_rooms|
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+
--            0|       197|        1|       19|     2.07|       2.0|1.0786203731683835|           1.0|           1.0|           3.0|           5.0|
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+
--


/***   Статистика по полю ceiling_height   ***/
select  count(*) filter (where ceiling_height is null)               as ceiling_height_is_null,
		count(*) filter (where ceiling_height = 0)                   as ceiling_height_0,
		min(ceiling_height) filter (where ceiling_height != 0)       as min_ceiling_height,
		max(ceiling_height)                                          as max_ceiling_height,
		round(avg(ceiling_height::numeric), 2)                       as avg_ceiling_height,
		percentile_cont(0.5) within group (order by ceiling_height)  as perc_ceiling_height,
		stddev(ceiling_height)                                       as stddev_ceiling_height,
		percentile_cont(0.01) within group (order by ceiling_height) as perc_ceiling_height,
		percentile_cont(0.25) within group (order by ceiling_height) as perc_ceiling_height,
		percentile_cont(0.75) within group (order by ceiling_height) as perc_ceiling_height,
		percentile_cont(0.99) within group (order by ceiling_height) as perc_ceiling_height
from real_estate.flats;
--
------------------------+----------------+------------------+------------------+------------------+-------------------+---------------------+-------------------+-------------------+-------------------+-------------------+
--ceiling_height_is_null|ceiling_height_0|min_ceiling_height|max_ceiling_height|avg_ceiling_height|perc_ceiling_height|stddev_ceiling_height|perc_ceiling_height|perc_ceiling_height|perc_ceiling_height|perc_ceiling_height|
------------------------+----------------+------------------+------------------+------------------+-------------------+---------------------+-------------------+-------------------+-------------------+-------------------+
--                  9160|               0|               1.0|             100.0|              2.77| 2.6500000953674316|      1.2615932936359|                2.5| 2.5199999809265137|  2.799999952316284|  3.821099932193762|
------------------------+----------------+------------------+------------------+------------------+-------------------+---------------------+-------------------+-------------------+-------------------+-------------------+
--

/*ТОП-10 квартир с самыми высокими потолками: для некоторых значений, например 27, вероятно ошибка в разрядах*/
select  *
from real_estate.flats
where ceiling_height is not null
order by ceiling_height desc
limit 10;
--
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--22869|6X8I   |F8EM   |      25.0|    1|         100.0|         5.0|       14.0|    5|           1|        0|        11.0|    5.0|         34963.0|             1.0|             3.0|
--22336|6X8I   |F8EM   |      92.4|    2|          32.0|         6.0|       55.5|    5|           0|        0|        16.5|    4.0|         18838.0|             0.0|             3.0|
-- 3148|S4Y8   |F8EM   |      75.0|    3|          32.0|         3.0|       53.0|    2|           0|        0|         8.0|       |                |                |                |
--21377|6X8I   |F8EM   |      42.0|    1|          27.5|        24.0|       37.7|   19|           0|        0|        11.0|    2.0|         42742.0|             0.0|             0.0|
-- 5246|K8HL   |9N9J   |      54.0|    2|          27.0|         5.0|       30.0|    3|           0|        0|         9.0|    2.0|                |                |                |
--21824|K9HS   |LVBX   |      44.0|    2|          27.0|         2.0|       38.0|    2|           0|        0|         8.6|    2.0|                |                |                |
--20478|6X8I   |F8EM   |      45.0|    1|          27.0|         4.0|       22.0|    2|           0|        0|        10.0|    1.0|         18975.0|             0.0|             3.0|
-- 5807|6X8I   |F8EM   |      80.0|    2|          27.0|        36.0|       41.0|   13|           0|        0|        12.0|    5.0|         18732.0|             0.0|             3.0|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--

/*Сколько объектов имеют аномально высокие потолки*/
select count(*) 
from real_estate.flats
where ceiling_height > (select percentile_cont(0.99) within group (order by ceiling_height) from real_estate.flats);
--
-------+
--count|
-------+
--  145|
-------+
--

/*Сколько объектов имеют аномально низкие потолки*/
select count(*) 
from real_estate.flats
where ceiling_height < (select percentile_cont(0.01) within group (order by ceiling_height) from real_estate.flats);
--
-------+
--count|
-------+
--   73|
-------+
--


/***   Статистика по полю floors_total   ***/
select  count(*) filter (where floors_total is null)               as floors_total_is_null,
		count(*) filter (where floors_total = 0)                   as floors_total_zero,
		min(floors_total) filter (where floors_total != 0)         as min_floors_total,
		max(floors_total)                                          as max_floors_total,
		round((avg(floors_total))::numeric, 2)                     as avg_floors_total,
		percentile_cont(0.5) within group (order by rooms)         as perc_floors_total,
		stddev(floors_total)                                       as stddev_rooms,
		percentile_cont(0.01) within group (order by floors_total) as _01_perc_floors_total,
		percentile_cont(0.25) within group (order by floors_total) as _25_perc_floors_total,
		percentile_cont(0.75) within group (order by floors_total) as _75_perc_floors_total,
		percentile_cont(0.99) within group (order by floors_total) as _99_perc_floors_total
from real_estate.flats;
--
----------------------+-----------------+----------------+----------------+----------------+-----------------+-----------------+---------------------+---------------------+---------------------+---------------------+
--floors_total_is_null|floors_total_zero|min_floors_total|max_floors_total|avg_floors_total|perc_floors_total|stddev_rooms     |_01_perc_floors_total|_25_perc_floors_total|_75_perc_floors_total|_99_perc_floors_total|
----------------------+-----------------+----------------+----------------+----------------+-----------------+-----------------+---------------------+---------------------+---------------------+---------------------+
--                  85|                0|             1.0|            60.0|           10.68|              2.0|6.594823458352339|                  2.0|                  5.0|                 16.0|                 26.0|
----------------------+-----------------+----------------+----------------+----------------+-----------------+-----------------+---------------------+---------------------+---------------------+---------------------+
--


/***   Статистика по полю  living_area   ***/
select  count(*) filter (where living_area is null)               as living_area_is_null,
		count(*) filter (where living_area = 0)                   as living_area_0,
		min(living_area) filter (where living_area != 0)          as min_living_area,
		max(living_area)                                          as max_living_area,
		round(avg(living_area)::numeric, 2)                       as avg_living_area,
		percentile_cont(0.5) within group (order by  living_area) as perc_living_area,
		stddev(living_area)                                       as stddev_living_area,
		percentile_cont(0.01) within group (order by living_area) as _01_perc_living_area,
		percentile_cont(0.25) within group (order by living_area) as _25_perc_living_area,
		percentile_cont(0.75) within group (order by living_area) as _75_perc_living_area,
		percentile_cont(0.99) within group (order by living_area) as _99_perc_living_area
from real_estate.flats
;
--
-----------------------+-------------+---------------+---------------+---------------+----------------+------------------+--------------------+--------------------+--------------------+--------------------+
----living_area_is_null|living_area_0|min_living_area|max_living_area|avg_living_area|perc_living_area|stddev_living_area|_01_perc_living_area|_25_perc_living_area|_75_perc_living_area|_99_perc_living_area|
-----------------------+-------------+---------------+---------------+---------------+----------------+------------------+--------------------+--------------------+--------------------+--------------------+
--                 1898|            0|            2.0|          409.7|          34.45|            30.0|22.037664451284158|                13.0|  18.600000381469727|   42.29999923706055|               120.0|
-----------------------+-------------+---------------+---------------+---------------+----------------+------------------+--------------------+--------------------+--------------------+--------------------+
--

/*ТОП-5 самых больших значений жилой плошади: на первом месте квартира бизнес-класса*/
select  *
from real_estate.flats
where living_area is not null
order by living_area desc
limit 5;
--
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--19540|6X8I   |F8EM   |     900.0|   12|           2.8|        25.0|      409.7|   25|           0|        0|       112.0|       |         30706.0|             0.0|             2.0|
-- 5358|6X8I   |F8EM   |     590.0|   15|           3.5|         6.0|      409.0|    3|           0|        0|       100.0|       |         24447.0|             1.0|             0.0|
--12401|6X8I   |F8EM   |     495.0|    7|          4.65|         7.0|      347.5|    7|           0|        0|        25.0|    0.0|                |             2.0|             0.0|
-- 4237|6X8I   |F8EM   |     517.0|    7|              |         4.0|      332.0|    3|           0|        0|        22.0|       |         22835.0|             2.0|             2.0|
--12859|6X8I   |F8EM   |     631.2|    7|           3.9|         4.0|      322.3|    4|           0|        0|        19.5|    1.0|         25707.0|             0.0|             2.0|

/*ТОП-5 самых маленьких значений жилой площади*/
select  *
from real_estate.flats
order by living_area
limit 5;
--
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--13915|6X8I   |F8EM   |      52.0|    2|           3.0|         6.0|        2.0|    2|           0|        0|         9.0|       |         32453.0|             0.0|             1.0|
--21758|187Y   |IZIQ   |      23.0|    0|              |        24.0|        2.0|   22|           0|        0|            |       |                |                |                |
-- 3242|6X8I   |F8EM   |      41.0|    1|              |        17.0|        3.0|   17|           0|        0|        11.0|       |         19272.0|             0.0|             0.0|
--23574|6X8I   |F8EM   |     139.0|    3|           3.0|         8.0|        3.0|    8|           0|        0|        16.0|    1.0|         33255.0|             1.0|             3.0|
--17582|6X8I   |F8EM   |      22.0|    0|              |        25.0|        5.0|    8|           0|        0|            |    2.0|         22735.0|             1.0|             1.0|



/***   Статистика по полю  floors   ***/
select  count(*) filter (where floor is null)               as floor_is_null,
		count(*) filter (where floor = 0)                   as floor_zero,
		min(floor) filter (where floor != 0)                as min_floor,
		max(floor)                                          as max_floor,
		round(avg(floor)::numeric, 2)                       as avg_floor,
		percentile_cont(0.5) within group (order by floor)  as perc_floor,
		stddev(floor)                                       as stddev_floor,
		percentile_cont(0.01) within group (order by floor) as _01_perc_floor,
		percentile_cont(0.25) within group (order by floor) as _25_perc_floor,
		percentile_cont(0.75) within group (order by floor) as _75_perc_floor,
		percentile_cont(0.99) within group (order by floor) as _99_perc_floor
from real_estate.flats;
--
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+
--floor_is_null|floor_zero|min_floor|max_floor|avg_floor|perc_floor|stddev_floor      |_01_perc_floor|_25_perc_floor|_75_perc_floor|_99_perc_floor|
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+
--            0|         0|        1|       33|     5.89|       4.0|4.8833170623627659|           1.0|           2.0|           8.0|          23.0|
---------------+----------+---------+---------+---------+----------+------------------+--------------+--------------+--------------+--------------+



/***   Статистика по полю balcony  ***/
select  count(balcony) filter (where balcony is null )        as count_balcony_is_null, 
		count(balcony) filter (where balcony = 0 )            as count_balcony_zero,
		min(balcony) filter (where balcony != 0 )             as min_balcony,
		max(balcony)                                          as max_balcony,
		round(avg(balcony)::numeric, 2)                       as avg_balcony,
		percentile_cont(0.5) within group (order by balcony)  as perc_balcony,
		stddev(balcony)                                       as stddev_balcony,
		percentile_cont(0.01) within group (order by balcony) as _01_perc_floor,
		percentile_cont(0.25) within group (order by balcony) as _25_perc_floor,
		percentile_cont(0.75) within group (order by balcony) as _75_perc_floor,
		percentile_cont(0.99) within group (order by balcony) as _99_perc_floor
from real_estate.flats;
--
--count_balcony_is_null|count_balcony_zero|min_balcony|max_balcony|avg_balcony|perc_balcony|stddev_balcony    |_01_perc_floor|_25_perc_floor|_75_perc_floor|_99_perc_floor|
-----------------------+------------------+-----------+-----------+-----------+------------+------------------+--------------+--------------+--------------+--------------+
--                    0|              3725|        1.0|        5.0|       1.15|         1.0|1.0711686116269614|           0.0|           0.0|           2.0|           5.0|


/***   Статистика по полю kitchen_area   ***/
select  count(*) filter (where kitchen_area is null)               as  kitchen_area_is_null,
		count(*) filter (where kitchen_area = 0)                   as  kitchen_area_zero,
		min(kitchen_area)                                          as min_kitchen_area,
		max(kitchen_area)                                          as max_kitchen_area,
		round(avg(kitchen_area)::numeric, 2)                       as avg_kitchen_area,
		percentile_cont(0.5) within group (order by kitchen_area)  as perc_kitchen_area,
		stddev(kitchen_area)                                       as stddev_kitchen_area,
		percentile_cont(0.01) within group (order by kitchen_area) as _01_perc,
		percentile_cont(0.25) within group (order by kitchen_area) as _25_perc,
		percentile_cont(0.75) within group (order by kitchen_area) as _75_perc,
		percentile_cont(0.99) within group (order by kitchen_area) as _99_perc
from real_estate.flats;
--
--kitchen_area_is_null|kitchen_area_zero|min_kitchen_area|max_kitchen_area|avg_kitchen_area|perc_kitchen_area|stddev_kitchen_area|_01_perc|_25_perc|_75_perc|_99_perc         |
----------------------+-----------------+----------------+----------------+----------------+-----------------+-------------------+--------+--------+--------+-----------------+
--                2269|                0|             1.3|           112.0|           10.57|9.100000381469727|   5.90175263480589|     5.0|     7.0|    12.0|35.05999908447269|


/***   Статистика по полю is_apartment   ***/
select	count(*) filter (where is_apartment is null)                                                        as  is_apartment_is_null,
		count(*) filter (where is_apartment = 0)                                                            as  is_apartment_0,
		count(*) filter (where is_apartment = 1)                                                            as  is_apartment_1,
		round(count(*) filter (where is_apartment = 1) * 1.0 / count(*) filter (where is_apartment = 0), 4) as share
from real_estate.flats;
--
----------------------+--------------+--------------+------+
--is_apartment_is_null|is_apartment_0|is_apartment_1|share |
----------------------+--------------+--------------+------+
--                   0|         23600|            50|0.0021|		
----------------------+--------------+--------------+------+
		

/***   Статистика по полю  open_plan   ***/
select  count(*) filter (where open_plan = 0)                                                         as  open_plan_0,
		count(*) filter (where open_plan = 1)                                                         as  open_plan_1,
		round(count(*) filter (where open_plan = 1) * 1.0 / count(*) filter (where open_plan = 0), 4) as share,
		count(*) filter (where open_plan is null)                                                     as  open_plan_is_null
from real_estate.flats;
--
-------------+-----------+------+-----------------+
--open_plan_0|open_plan_1|share |open_plan_is_null|
-------------+-----------+------+-----------------+
--      23583|         67|0.0028|                0|
-------------+-----------+------+-----------------+
--

/*У 5 студий указано количество комнат более 1, вероятно это количество зон*/
select  *
from real_estate.flats
where open_plan = 1 and rooms > 1
order by rooms  desc;
--
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--id   |city_id|type_id|total_area|rooms|ceiling_height|floors_total|living_area|floor|is_apartment|open_plan|kitchen_area|balcony|airports_nearest|parks_around3000|ponds_around3000|
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+
--17783|6X8I   |F8EM   |     157.0|    5|              |        11.0|           |    5|           0|        1|            |    0.0|         28399.0|             2.0|             3.0|
--19796|6X8I   |F8EM   |      97.2|    4|          3.35|         5.0|       71.3|    2|           0|        1|            |    0.0|         24559.0|             0.0|             0.0|
-- 8861|6X8I   |F8EM   |      64.5|    3|           3.0|         5.0|       48.0|    2|           0|        1|            |    0.0|         20040.0|             2.0|             2.0|
--14017|FJEG   |F8EM   |      59.0|    3|           2.5|         9.0|       37.6|    3|           0|        1|            |    1.0|         27820.0|             0.0|             1.0|
--12760|T0TI   |F8EM   |      51.0|    2|           2.5|        12.0|       30.0|   10|           0|        1|            |    2.0|                |                |                |
-------+-------+-------+----------+-----+--------------+------------+-----------+-----+------------+---------+------------+-------+----------------+----------------+----------------+

/*У 59 студий указано количество комнат 0*/
select  count(*)
from real_estate.flats
where open_plan = 1 and rooms = 0;
--
-------+
--count|
-------+
--   59|
-------+
--


/***   Статистика по полю airports_nearest   ***/
select  count(airports_nearest) filter (where airports_nearest is null ) as _is_null,
		count(airports_nearest) filter (where airports_nearest = 0 )     as count_airports_nearest_zero,
		min(airports_nearest) filter (where airports_nearest != 0 )      as min_airports_nearest,
		max(airports_nearest)                                            as max_airports_nearest,
		round(avg(airports_nearest)::numeric, 2)                         as avg_airports_nearest,
		percentile_cont(0.5) within group (order by airports_nearest)    as perc_airports_nearest,
		stddev(airports_nearest)                                         as stddev_airports_nearest,
		percentile_cont(0.01) within group (order by airports_nearest)   as _01_perc,
		percentile_cont(0.25) within group (order by airports_nearest)   as _25_perc,
		percentile_cont(0.75) within group (order by airports_nearest)   as _75_perc,
		percentile_cont(0.99) within group (order by airports_nearest)   as _99_perc
from real_estate.flats;
--
----------+---------------------------+--------------------+--------------------+--------------------+---------------------+-----------------------+--------+--------+--------+-----------------+
--_is_null|count_airports_nearest_zero|min_airports_nearest|max_airports_nearest|avg_airports_nearest|perc_airports_nearest|stddev_airports_nearest|_01_perc|_25_perc|_75_perc|_99_perc         |
----------+---------------------------+--------------------+--------------------+--------------------+---------------------+-----------------------+--------+--------+--------+-----------------+
--       0|                          1|              6450.0|             84869.0|            28803.23|              26756.5|     12637.314144179325| 9412.15|18575.75| 37294.0|58514.74999999992|
----------+---------------------------+--------------------+--------------------+--------------------+---------------------+-----------------------+--------+--------+--------+-----------------+



/***   Статистика по полю parks_around3000   ***/
select  count(*) filter (where parks_around3000 is null)              as parks_around3000_is_null,
		count(*) filter (where parks_around3000 = 0)                  as parks_around3000_zero,
		count(*) filter (where parks_around3000 != 0)                 as parks_around3000,
		min(parks_around3000) filter (where parks_around3000 != 0 ),
		max(parks_around3000),
		round(avg(parks_around3000)::numeric, 2)                      as avg_parks_around3000,
		percentile_cont(0.5) within group (order by parks_around3000) as perc_parks_around3000,
		stddev(parks_around3000)                                      as stddev_parks_around3000
from real_estate.flats;
--
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+
--parks_around3000_is_null|parks_around3000_zero|parks_around3000|min|max|avg_parks_around3000|perc_parks_around3000|stddev_parks_around3000|
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+
--                    5510|                10080|            8060|1.0|3.0|                0.61|                  0.0|     0.8020031466729134|
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+



/***   Статистика по полю ponds_around3000   ***/
select  count(*) filter (where ponds_around3000 is null)              as ponds_around3000_is_null,
		count(*) filter (where ponds_around3000 = 0)                  as ponds_around3000_zero,
		count(*) filter (where ponds_around3000 > 0)                  as ponds_around3000,
		min(ponds_around3000) filter (where ponds_around3000 != 0 ),
		max(ponds_around3000),
		round(avg(ponds_around3000)::numeric, 2)                      as avg_ponds_around3000,
		percentile_cont(0.5) within group (order by ponds_around3000) as perc_ponds_around3000,
		stddev(ponds_around3000)                                      as stddev_ponds_around3000
from real_estate.flats;
/--
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+
--ponds_around3000_is_null|ponds_around3000_zero|ponds_around3000|min|max|avg_ponds_around3000|perc_ponds_around3000|stddev_ponds_around3000|
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+
--                    5510|                 9055|            9085|1.0|3.0|                0.77|                  1.0|     0.9379480962831459|
--------------------------+---------------------+----------------+---+---+--------------------+---------------------+-----------------------+




/***   Стоимость квартир и стоимость за кв.метр. Объединение 2х таблиц для расчета средней стоимости кв.м.   ***/
select  min(a.last_price) as min_price,
		max(a.last_price) as max_price,
		round(avg(a.last_price)::numeric, 2)                                      as avg_price,
		percentile_cont(0.5) within group (order by a.last_price)                 as perc_price,
		percentile_cont(0.01) within group (order by a.last_price)                as _01_perc_price,
		percentile_cont(0.25) within group (order by a.last_price)                as _25_perc_price,
		percentile_cont(0.75) within group (order by a.last_price)                as _75_perc_price,
		percentile_cont(0.99) within group (order by a.last_price)                as _99_perc_price,
		min(a.last_price / f.total_area)                                          as min_price_sq_meter,
		max(a.last_price / f.total_area)                                          as max_price_sq_meter,
		round(avg(a.last_price / f.total_area)::numeric, 2)                       as avg_price_sq_meter,
		percentile_cont(0.5) within group (order by a.last_price / f.total_area)  as perc_price_sq_meter,
		percentile_cont(0.01) within group (order by a.last_price / f.total_area) as _01_perc_price_sq_meter,
		percentile_cont(0.25) within group (order by a.last_price / f.total_area) as _25_perc_price_sq_meter,
		percentile_cont(0.75) within group (order by a.last_price / f.total_area) as _75_perc_price_sq_meter,
		percentile_cont(0.99) within group (order by a.last_price / f.total_area) as _99_perc_price_sq_meter
from real_estate.advertisement as a
join real_estate.flats         as f using(id);
/*Средние значения сильно отличаются от медианных. */
-----------+---------+----------+----------+--------------+--------------+--------------+--------------+
--min_price|max_price|avg_price |perc_price|_01_perc_price|_25_perc_price|_75_perc_price|_99_perc_price|
-----------+---------+----------+----------+--------------+--------------+--------------+--------------+
--  12190.0|763000000|6541126.90| 4650000.0|     1000000.0|     3400000.0|     6799000.0|      36000000|
-----------+---------+----------+----------+--------------+--------------+--------------+--------------+
--
--------------------+------------------+------------------+-------------------+-----------------------+-----------------------+-----------------------+-----------------------+
--min_price_sq_meter|max_price_sq_meter|avg_price_sq_meter|perc_price_sq_meter|_01_perc_price_sq_meter|_25_perc_price_sq_meter|_75_perc_price_sq_meter|_99_perc_price_sq_meter|
--------------------+------------------+------------------+-------------------+-----------------------+-----------------------+-----------------------+-----------------------+
--         111.83486|         1907500.0|          99432.25|            95000.0|      23200.90478515625|        76614.970703125|       114274.158203125|      267234.2390624986|  
--------------------+------------------+------------------+-------------------+-----------------------+-----------------------+-----------------------+-----------------------+


/*Распределение объявлений по типам населенных пунктов и регионам
 * На города приходится 84.6% объявлений, из них 18.13% на города области и 66.47% на Санкт-Петербург. На третьем месте по числу объявлений - поселоки 8.85%*/
with 
--категоризация по региону
city_region as
	(select *, case when city != 'Санкт-Петербург' then 'Область' else city end as region
	from real_estate.city
	)
select  t.type as ТИП, cr.region as РЕГИОН,
		count(*)                                                          as ОБЪЯВЛЕНИЙ,
		round(count(*) / sum(count(*)) over(partition by cr.region), 4)   as ДОЛЯ_ОБЪЯВЛ_В_РАЗРЕЗЕ_РЕГИОНА,
		round(count(*) / sum(count(*)) over(), 4)                         as ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ
from real_estate.flats 
left join real_estate.type as t using(type_id) 
left join city_region      as cr using(city_id)
group by ТИП, РЕГИОН
order by ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ;
--
-------------------------------------------+---------------+----------+-----------------------------+-------------------+
--ТИП                                      |РЕГИОН         |ОБЪЯВЛЕНИЙ|ДОЛЯ_ОБЪЯВЛ_В_РАЗРЕЗЕ_РЕГИОНА|ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ|
-------------------------------------------+---------------+----------+-----------------------------+-------------------+
--садоводческое некоммерческое товарищество|Область        |         1|                       0.0001|             0.0000|
--коттеджный посёлок                       |Область        |         3|                       0.0004|             0.0001|
--садовое товарищество                     |Область        |         4|                       0.0005|             0.0002|
--посёлок при железнодорожной станции      |Область        |        15|                       0.0019|             0.0006|
--село                                     |Область        |        32|                       0.0040|             0.0014|
--городской посёлок                        |Область        |       187|                       0.0236|             0.0079|
--посёлок городского типа                  |Область        |       363|                       0.0458|             0.0153|
--деревня                                  |Область        |       945|                       0.1192|             0.0400|
--посёлок                                  |Область        |      2092|                       0.2638|             0.0885|
--город                                    |Область        |      4287|                       0.5407|             0.1813|
--город                                    |Санкт-Петербург|     15721|                       1.0000|             0.6647|
-------------------------------------------+---------------+----------+-----------------------------+-------------------+


/*Сегменты рынка с коротким и длинным сроками активности объявлений*/
with 
--категоризация по региону
city_region as
	(select *, case when city != 'Санкт-Петербург' then 'Область' else city end as region
	from real_estate.city
	),
--категоризация по сроку активности объявления
tab1 as (
	select  case  when a.days_exposition is null then '5. не продана'
				  when a.days_exposition <= 30 then '1. до 1 мес'
				  when a.days_exposition <= 90 then '2. до 3 мес'
				  when a.days_exposition <= 180 then '3. до 6 мес'
				  else '4. более 6 мес'
			end       as КАТЕГОРИЯ,
			cr.region as РЕГИОН,
			t.type    as ТИП, 
			count(*)  as ОБЪЯВЛЕНИЙ
	from real_estate.flats 
	left join real_estate.advertisement as a using(id)
	left join real_estate.type          as t using(type_id) 
	left join city_region               as cr using(city_id)
	group by КАТЕГОРИЯ, РЕГИОН, ТИП
	)
select  *,	round(ОБЪЯВЛЕНИЙ / sum(ОБЪЯВЛЕНИЙ) over(partition by КАТЕГОРИЯ), 4) as ДОЛЯ
from tab1
where КАТЕГОРИЯ = '1. до 1 мес' or КАТЕГОРИЯ = '4. более 6 мес'
group by КАТЕГОРИЯ, РЕГИОН, ТИП, ОБЪЯВЛЕНИЙ
order by КАТЕГОРИЯ, ОБЪЯВЛЕНИЙ desc;
--
--КАТЕГОРИЯ     |РЕГИОН         |ТИП                                |ОБЪЯВЛЕНИЙ|ДОЛЯ  |
----------------+---------------+-----------------------------------+----------+------+
--1. до 1 мес   |Санкт-Петербург|город                              |      2678|0.7174|
--1. до 1 мес   |Область        |город                              |       553|0.1481|
--1. до 1 мес   |Область        |посёлок                            |       349|0.0935|
--...................................................................................
--4. более 6 мес|Санкт-Петербург|город                              |      4286|0.6661|
--4. более 6 мес|Область        |город                              |      1165|0.1811|
--4. более 6 мес|Область        |посёлок                            |       539|0.0838|
--..................................................................................
