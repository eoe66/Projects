/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Егорова Ольга
 * Дата: 02.12.2024 , корректировка 05.12.2025 (задачи 2 - добавлены оконные функции ранжирования и задача 3 - добавлена агрегатная функция string_agg() )
*/

-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

with
--аномально высокие и низкие значения
confines as (
	select  
		percentile_disc(0.99) within group (order by total_area)     as total_area_perc_99,
	 	percentile_disc(0.99) within group (order by rooms)          as rooms_perc_99,
	 	percentile_disc(0.01) within group (order by ceiling_height) as ceiling_height_perc_01,
	 	percentile_disc(0.99) within group (order by ceiling_height) as ceiling_height_perc_99,
	 	percentile_disc(0.99) within group (order by balcony)        as balcony_perc_99
	from real_estate.flats
),
--id объявлений без выбросов
id_tab as (
	select id
	from   real_estate.flats
	where  total_area < (select total_area_perc_99 from confines) and
		   ( rooms < (select rooms_perc_99 from confines)  or rooms is null ) and
		   ( ceiling_height > (select ceiling_height_perc_01 from confines) and ceiling_height < (select ceiling_height_perc_99 from confines)  or ceiling_height is null ) and
		   ( balcony < (select balcony_perc_99 from confines) or balcony is null )
),
--таблица с объявлениями без выбросов
flats_new as (
	select *
	from real_estate.flats
	where id in (select * from id_tab)
),
--категоризация и доп.поле
general_tab as (
	select *,
		--категоризация по времени
		case 
			when a.days_exposition is null then '5. не продана'
			when a.days_exposition <= 30 then '1. до 1 мес'
			when a.days_exposition <= 90 then '2. до 3 мес'
			when a.days_exposition <= 180 then '3. до 6 мес'
			else '4. более 6 мес'
		end                                  as category,
		--категоризация по региону
		case
			when c.city != 'Санкт-Петербург'
			then 'Область' else c.city end   as region,
		--поле со средним чеком
		a.last_price / f.total_area          as price_square_meter
	from flats_new                      as f
	left join real_estate.advertisement as a using(id)
	left join real_estate.city          as c  using(city_id)
	left join real_estate.type          as t using(type_id)
)
select
		category as КАТЕГОРИЯ,
		region   as РЕГИОН,
		 		--показатели по объявлениям
		count(*)                                                          as ОБЪЯВЛЕНИЙ,
		round(count(*) / sum(count(*)) over(partition by region), 2)      as ДОЛЯ_В_РАЗРЕЗЕ_РЕГИОНА,
		round(count(*) / sum(count(*)) over(partition by category), 2)    as ДОЛЯ_В_РАЗРЕЗЕ_КАТЕГОРИЙ,
		round(count(*) / sum(count(*)) over(), 2)                         as ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ,
		       --доли видов недвижимости
		round(count(*) filter( where is_apartment = 1) / sum(count(*)) over(partition by category, region), 3)                    as ДОЛЯ_АПАРТ,
		round(count(*) filter( where open_plan = 1) / sum(count(*)) over(partition by category, region), 3)                       as ДОЛЯ_СТУД,
		round(count(*) filter( where is_apartment = 0 and open_plan = 0 ) / sum(count(*)) over(partition by category, region), 3) as ДОЛЯ_КВАРТ,
		      --показатели В ЦЕЛОМ О НЕДВИЖИМОСТИ
		round(avg(total_area)::numeric, 2)                                      as СР_ПЛОЩАДЬ,
		round(avg(last_price / total_area)::numeric, 2)                         as СР_ЦЕНА_КВ_М,
		percentile_disc(0.5) within group (order by rooms)                      as МЕДИАНА_КОМНАТЫ,
		percentile_disc(0.5) within group (order by floor)                      as МЕДИАНА_ЭТАЖ,
		percentile_disc(0.5) within group (order by floors_total)::integer      as МЕДИАНА_ЭТ_ДОМА,
		percentile_disc(0.5) within group (order by ceiling_height)             as МЕДИАНА_ПОТОЛОК,
		round(avg(kitchen_area)::numeric, 2)                                    as СР_ПЛОЩ_КУХНИ,
		percentile_disc(0.5) within group (order by balcony) ::integer          as МЕДИАНА_БАЛКОНЫ,
		percentile_cont(0.5) within group (order by airports_nearest)           as ДО_АЭРОПОРТА,
		percentile_disc(0.5) within group (order by parks_around3000)::integer  as КОЛ_ПАРКОВ,
		percentile_disc(0.5) within group (order by ponds_around3000)::integer  as КОЛ_ВОДОЕМОВ
from general_tab
where type = 'город'
group by category, region
order by category, region; 
----------------+---------------+----------+----------------------+------------------------+-------------------+----------+---------+----------+
--КАТЕГОРИЯ     |РЕГИОН         |ОБЪЯВЛЕНИЙ|ДОЛЯ_В_РАЗРЕЗЕ_РЕГИОНА|ДОЛЯ_В_РАЗРЕЗЕ_КАТЕГОРИЙ|ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ|ДОЛЯ_АПАРТ|ДОЛЯ_СТУД|ДОЛЯ_КВАРТ|
----------------+---------------+----------+----------------------+------------------------+-------------------+----------+---------+----------+-
--1. до 1 мес   |Область        |       397|                  0.12|                    0.15|               0.02|     0.005|    0.005|     0.990| 
--1. до 1 мес   |Санкт-Петербург|      2168|                  0.17|                    0.85|               0.14|     0.003|    0.002|     0.994| 
--2. до 3 мес   |Область        |       917|                  0.28|                    0.22|               0.06|     0.001|    0.002|     0.997| 
--2. до 3 мес   |Санкт-Петербург|      3236|                  0.25|                    0.78|               0.20|     0.001|    0.006|     0.994| 
--3. до 6 мес   |Область        |       556|                  0.17|                    0.20|               0.03|     0.002|    0.002|     0.996| 
--3. до 6 мес   |Санкт-Петербург|      2254|                  0.18|                    0.80|               0.14|     0.002|    0.002|     0.996| 
--4. более 6 мес|Область        |       890|                  0.28|                    0.20|               0.06|     0.001|    0.000|     0.999| 
--4. более 6 мес|Санкт-Петербург|      3581|                  0.28|                    0.80|               0.22|     0.002|    0.001|     0.997| 
--5. не продана |Область        |       461|                  0.14|                    0.23|               0.03|     0.004|    0.000|     0.996| 
--5. не продана |Санкт-Петербург|      1554|                  0.12|                    0.77|               0.10|     0.006|    0.000|     0.994| 
----------------+---------------+----------+----------------------+------------------------+-------------------+----------+---------+----------+
----------------+---------------+----------+------------+---------------+------------+---------------+---------------+-------------+---------------+------------+----------+------------+
--КАТЕГОРИЯ     |РЕГИОН         |СР_ПЛОЩАДЬ|СР_ЦЕНА_КВ_М|МЕДИАНА_КОМНАТЫ|МЕДИАНА_ЭТАЖ|МЕДИАНА_ЭТ_ДОМА|МЕДИАНА_ПОТОЛОК|СР_ПЛОЩ_КУХНИ|МЕДИАНА_БАЛКОНЫ|ДО_АЭРОПОРТА|КОЛ_ПАРКОВ|КОЛ_ВОДОЕМОВ|
----------------+---------------+----------+------------+---------------+------------+---------------+---------------+-------------+---------------+------------+----------+------------+
--1. до 1 мес   |Область        |     48.72|    73275.25|              2|           4|              5|           2.67|         8.96|              1|     26607.0|         1|           1|
--1. до 1 мес   |Санкт-Петербург|     54.38|   110568.88|              2|           5|             10|            2.7|        10.22|              1|     27106.0|         0|           0|
--2. до 3 мес   |Область        |     50.88|    67573.43|              2|           3|              5|            2.7|         9.07|              1|     28458.0|         0|           1|
--2. до 3 мес   |Санкт-Петербург|     56.71|   111573.24|              2|           5|             12|            2.7|        10.64|              1|     27604.0|         0|           1|
--3. до 6 мес   |Область        |     51.83|    69846.39|              2|           3|              5|            2.7|         9.05|              1|     26893.0|         1|           1|
--3. до 6 мес   |Санкт-Петербург|     60.55|   111938.92|              2|           5|             10|           2.71|        11.24|              1|     27331.5|         0|           1|
--4. более 6 мес|Область        |     55.41|    68297.22|              2|           3|              5|            2.7|         9.28|              1|     27753.0|         0|           1|
--4. более 6 мес|Санкт-Петербург|     66.15|   115457.22|              2|           5|              9|           2.75|        11.92|              1|     25816.0|         0|           1|
--5. не продана |Область        |     57.87|    73625.63|              2|           3|              5|            2.7|        10.46|              1|     26425.0|         0|           0|
--5. не продана |Санкт-Петербург|     72.03|   134632.92|              2|           5|              9|           2.78|        12.76|              2|     26434.0|         1|           1|
----------------+---------------+----------+------------+---------------+------------+---------------+---------------+-------------+---------------+------------+----------+------------+


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

with
--аномально высокие и низкие значения
confines as (
	select  
		percentile_disc(0.99) within group (order by total_area)     as total_area_perc_99,
	 	percentile_disc(0.99) within group (order by rooms)          as rooms_perc_99,
	 	percentile_disc(0.01) within group (order by ceiling_height) as ceiling_height_perc_01,
	 	percentile_disc(0.99) within group (order by ceiling_height) as ceiling_height_perc_99,
	 	percentile_disc(0.99) within group (order by balcony)        as balcony_perc_99
	from real_estate.flats
),
--id объявлений без выбросов
id_tab as (
	select id
	from   real_estate.flats
	where  total_area < (select total_area_perc_99 from confines) and
		   ( rooms < (select rooms_perc_99 from confines)  or rooms is null ) and
		   ( ceiling_height > (select ceiling_height_perc_01 from confines) and ceiling_height < (select ceiling_height_perc_99 from confines)  or ceiling_height is null ) and
		   ( balcony < (select balcony_perc_99 from confines) or balcony is null )
),
--таблица с месяцем публикации, месяцем снятия, площадью, стоимостью кв.м. (без выбросов)
general_tab_1 as (
	select  f.total_area                                                              as total_area,
			extract(month from a.first_day_exposition)                                as month_first_day_exposition ,
			extract(month from (a.first_day_exposition + a.days_exposition::integer)) as month_final_day_exposition,
			a.last_price / f.total_area                                               as price_square_meter
	from real_estate.flats              as f
	left join real_estate.advertisement as a using(id)
	where id in (select * from id_tab)
),
--присваиваем ранг, в from: добавляем имя месяца, считаем количество объявлений по месяцам с данными о средней площади
--и стоимости кв. метра для публикаций
advertisement_month_first_rank as (
	select  row_number() over()         as rank_month, *
	from  (
			select
				month_first_day_exposition,
				case month_first_day_exposition
				when 1 then 'январь'
				when 2 then 'февраль'
				when 3 then 'март'
				when 4 then 'апрель'
				when 5 then 'май'
				when 6 then 'июнь'
				when 7 then 'июль'
				when 8 then 'август'
				when 9 then 'сентябрь'
				when 10 then 'октябрь'
				when 11 then 'ноябрь'
				else 'декабрь' end      as month_name_first_day_exposition,
				count(*)                as count_first_day_exposition,
				avg(total_area)         as avg_total_area,
				avg(price_square_meter) as avg_price_square_meter
			from general_tab_1
			group by month_first_day_exposition, month_name_first_day_exposition
			order by count_first_day_exposition desc) as advertisement_month_first
),
--присваиваем ранг, в from добавляем имя месяца, считаем количество объявлений по месяцам с данными о средней площади
--и стоимости кв. метра для продаж(снятий)
advertisement_month_final_rank as (
	select row_number() over()              as rank_month, *
	from (
			select  
				month_final_day_exposition,
				case month_final_day_exposition
				when 1 then 'январь'
				when 2 then 'февраль'
				when 3 then 'март'
				when 4 then 'апрель'
				when 5 then 'май'
				when 6 then 'июнь'
				when 7 then 'июль'
				when 8 then 'август'
				when 9 then 'сентябрь'
				when 10 then 'октябрь'
				when 11 then 'ноябрь'
				when 12 then 'декабрь'
				else null end               as month_name_final_day_exposition,
					count(*)                as count_month_final_day_exposition,
					avg(total_area)         as avg_total_area,
					avg(price_square_meter) as avg_price_square_meter
			from general_tab_1
			where month_final_day_exposition is not null
			group by month_final_day_exposition, month_name_final_day_exposition
			order by count_month_final_day_exposition desc) as advertisement_month_final
),
--месяца с количеством публикаций и продаж(снятий) в порядке убывания
activity as (
	select  fir.rank_month                       as ранг,
			fir.month_name_first_day_exposition  as месяц_публикаций,
			fir.count_first_day_exposition       as колич_публикаций,
			fin.month_name_final_day_exposition  as месяц_продаж,
			fin.count_month_final_day_exposition as колич_продаж
	from advertisement_month_first_rank as fir
	left join advertisement_month_final_rank as fin using(rank_month)
 	)
------+----------------+----------------+------------+------------+
--ранг|месяц_публикаций|колич_публикаций|месяц_продаж|колич_продаж|
------+----------------+----------------+------------+------------+
 --  1|февраль         |            2106|апрель      |        1684|
  -- 2|март            |            2000|октябрь     |        1625|
  -- 3|апрель          |            1909|ноябрь      |        1572|
  -- 4|ноябрь          |            1906|январь      |        1558|
  -- 5|октябрь         |            1707|март        |        1540|
  -- 6|сентябрь        |            1602|сентябрь    |        1477|
  -- 7|июнь            |            1461|декабрь     |        1454|
  -- 8|август          |            1409|август      |        1375|
  -- 9|июль            |            1369|июль        |        1342|
  --10|декабрь         |            1351|февраль     |        1330|
  --11|январь          |            1212|июнь        |         936|
  --12|май             |            1086|май         |         901|
  ----+----------------+----------------+------------+------------+
select  fir.month_first_day_exposition                as НОМЕР_МЕСЯЦ,
		fir.month_name_first_day_exposition           as МЕСЯЦ,
		fir.count_first_day_exposition                as КОЛ_ПУБЛИКАЦИЙ,
		round(fir.avg_total_area::numeric, 2)         as СР_ПЛОЩ_ПУБЛ,
		round(fir.avg_price_square_meter::numeric, 2) as СР_СТОИМ_КВ_М_ПУБЛ,
		fin.count_month_final_day_exposition          as КОЛ_ПРОДАЖ,
		round(fin.avg_total_area::numeric, 2)         as СР_ПЛОЩ_ПРОД,
		round(fin.avg_price_square_meter::numeric, 2) as СР_СТОИМ_КВ_М_ПРОД
from advertisement_month_first_rank as fir
join advertisement_month_final_rank as fin on fir.month_first_day_exposition =  fin.month_final_day_exposition
order by НОМЕР_МЕСЯЦ;
-------------+--------+--------------+------------+------------------+----------+------------+------------------+
--НОМЕР_МЕСЯЦ|МЕСЯЦ   |КОЛ_ПУБЛИКАЦИЙ|СР_ПЛОЩ_ПУБЛ|СР_СТОИМ_КВ_М_ПУБЛ|КОЛ_ПРОДАЖ|СР_ПЛОЩ_ПРОД|СР_СТОИМ_КВ_М_ПРОД|
-------------+--------+--------------+------------+------------------+----------+------------+------------------+
--          1|январь  |          1212|       57.40|         101439.03|      1558|       56.17|          98495.62|
--          2|февраль |          2106|       58.39|         100035.76|      1330|       58.84|          99272.77|
--          3|март    |          2000|       57.61|         101469.71|      1540|       57.83|         101129.77|
--          4|апрель  |          1909|       58.45|         103100.47|      1684|       56.87|         100964.83|
--          5|май     |          1086|       57.50|          99030.27|       901|       55.75|          95988.08|
--          6|июнь    |          1461|       56.74|          98780.66|       936|       58.29|          96976.64|
--          7|июль    |          1369|       58.48|          99392.37|      1342|       57.40|          97532.15|
--          8|август  |          1409|       57.40|         100842.61|      1375|       55.50|          95198.98|
--          9|сентябрь|          1602|       59.05|         101823.87|      1477|       56.18|          99647.99|
--         10|октябрь |          1707|       57.96|          99454.86|      1625|       57.18|          99969.06|
--         11|ноябрь  |          1906|       58.44|         100370.44|      1572|       55.35|          98860.17|
--         12|декабрь |          1351|       58.98|         100070.62|      1454|       57.51|          99899.48|
-------------+--------+--------------+------------+------------------+----------+------------+------------------+



-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

with
--аномально высокие и низкие значения
confines as (
	select  
		percentile_disc(0.99) within group (order by total_area)     as total_area_perc_99,
	 	percentile_disc(0.99) within group (order by rooms)          as rooms_perc_99,
	 	percentile_disc(0.01) within group (order by ceiling_height) as ceiling_height_perc_01,
	 	percentile_disc(0.99) within group (order by ceiling_height) as ceiling_height_perc_99,
	 	percentile_disc(0.99) within group (order by balcony)        as balcony_perc_99
	from real_estate.flats
),
--id объявлений без выбросов
id_tab as (
	select id
	from   real_estate.flats
	where  total_area < (select total_area_perc_99 from confines) and
		   ( rooms < (select rooms_perc_99 from confines)  or rooms is null ) and
		   ( ceiling_height > (select ceiling_height_perc_01 from confines) and ceiling_height < (select ceiling_height_perc_99 from confines)  or ceiling_height is null ) and
		   ( balcony < (select balcony_perc_99 from confines) or balcony is null )
),
--таблица по населенным пунктам области со средней стоимостью за  кв.м.и без выбросов
general_tab as (
	select  *,
			a.last_price / f.total_area                            as price_square_meter
	from real_estate.flats              as f
	left join real_estate.advertisement as a using(id)
	left join real_estate.city          as c  using(city_id)
	left join real_estate.type          as t using(type_id)
	where id in (select * from id_tab) and c.city != 'Санкт-Петербург'
),
--для количества объявлений по населенным пунктам области найдем значение, выше которого находится 5% данных;
--в from для каждого населенного пункта считаем общее количество объявлений
confines_city as (
	select percentile_disc(0.95) within group (order by count_flats)
	from (select count(city) as count_flats from general_tab group by city) as t
),
final_table as (
select 
	city                                                                                                                as НАЗВАНИЕ,
	string_agg(distinct type, ',')                                                                                      as ТИП, 
	count(city)                                                                                                         as ОБЪЯВЛЕНИЙ,
	round(count(*) / sum(count(*)) over(), 3)                                                                           as ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ_ПО_ОБЛ,
	count(*) filter( where days_exposition is not null)                                                                 as ПРОДАННЫХ,
	round(count(*) filter( where days_exposition is not null) *1.0 / count(*) , 3)                                      as ДОЛЯ_ПРОДАННЫХ,
	count(city) - count(*) filter( where days_exposition is not null)                                                   as НЕПРОДАННЫХ,
	percentile_disc(0.5) within group (order by days_exposition) ::integer                                              as ДНЕЙ_ПУБЛИК, 
	round(count(*) filter( where is_apartment = 1) / sum(count(*)) over(partition by city), 3)                          as ДОЛЯ_АПАРТ,
	round(count(*) filter( where open_plan = 1) / sum(count(*)) over(partition by city), 3)                             as ДОЛЯ_СТУД,
	round(count(*) filter( where is_apartment = 0 and open_plan = 0 ) / sum(count(*)) over(partition by city), 3)       as ДОЛЯ_КВАРТ,
	round(avg(total_area)::numeric, 2)                                                                                  as СР_ПЛОЩАДЬ,
	round(avg(last_price / total_area)::numeric, 2)                                                                     as СР_ЦЕНА_КВ_М
from general_tab
group by city
--оставим 5% городов с самым большим количеством объявлеий
having count(city) > (select * from confines_city)
order by count(city) desc
)
select *,
	round(avg(СР_ПЛОЩАДЬ)   over(), 2)                                                                                  as СР_ПЛОЩ_ПО_ОБЛ,
	round(avg(СР_ЦЕНА_КВ_М) over (), 2)                                                                                 as СР_ЦЕНА_КВ_М_ПО_ОБЛ
from final_table
order by ДОЛЯ_ПРОДАННЫХ
; 
-----------------+-------------+----------+--------------------------+---------+--------------+-----------+-----------+----------+---------+----------+----------+------------+--------------+-------------------+
--НАЗВАНИЕ       |ТИП          |ОБЪЯВЛЕНИЙ|ДОЛЯ_ОБЪЯВЛ_ОТ_ВСЕХ_ПО_ОБЛ|ПРОДАННЫХ|ДОЛЯ_ПРОДАННЫХ|НЕПРОДАННЫХ|ДНЕЙ_ПУБЛИК|ДОЛЯ_АПАРТ|ДОЛЯ_СТУД|ДОЛЯ_КВАРТ|СР_ПЛОЩАДЬ|СР_ЦЕНА_КВ_М|СР_ПЛОЩ_ПО_ОБЛ|СР_ЦЕНА_КВ_М_ПО_ОБЛ|
-----------------+-------------+----------+--------------------------+---------+--------------+-----------+-----------+----------+---------+----------+----------+------------+--------------+-------------------+
--Мурино         |город,посёлок|       568|                     0.153|      532|         0.937|         36|         74|     0.000|    0.011|     0.989|     43.86|    85968.38|         53.06|           81019.29|
--Кудрово        |город,деревня|       463|                     0.125|      434|         0.937|         29|         73|     0.000|    0.028|     0.972|     46.20|    95420.47|         53.06|           81019.29|
--Шушары         |посёлок      |       404|                     0.109|      374|         0.926|         30|         90|     0.000|    0.000|     1.000|     53.93|    78831.93|         53.06|           81019.29|
--Всеволожск     |город        |       356|                     0.096|      305|         0.857|         51|        117|     0.003|    0.000|     0.997|     55.83|    69052.79|         53.06|           81019.29|
--Парголово      |посёлок      |       311|                     0.084|      288|         0.926|         23|         77|     0.000|    0.010|     0.990|     51.34|    90272.96|         53.06|           81019.29|
--Пушкин         |город        |       278|                     0.075|      231|         0.831|         47|        127|     0.000|    0.000|     1.000|     59.74|   104158.94|         53.06|           81019.29|
--Гатчина        |город        |       228|                     0.062|      203|         0.890|         25|         99|     0.000|    0.000|     1.000|     51.02|    69004.74|         53.06|           81019.29|
--Колпино        |город        |       227|                     0.061|      209|         0.921|         18|         80|     0.000|    0.000|     1.000|     52.55|    75211.73|         53.06|           81019.29|
--Выборг         |город        |       192|                     0.052|      168|         0.875|         24|        107|     0.010|    0.000|     0.990|     56.76|    58669.99|         53.06|           81019.29|
--Петергоф       |город        |       154|                     0.042|      136|         0.883|         18|         99|     0.006|    0.000|     0.994|     51.77|    85412.48|         53.06|           81019.29|
--Сестрорецк     |город        |       149|                     0.040|      134|         0.899|         15|        113|     0.000|    0.000|     1.000|     62.45|   103848.09|         53.06|           81019.29|
--Красное Село   |город        |       136|                     0.037|      122|         0.897|         14|        135|     0.007|    0.000|     0.993|     53.20|    71972.28|         53.06|           81019.29|
--Новое Девяткино|деревня      |       120|                     0.032|      106|         0.883|         14|         97|     0.000|    0.000|     1.000|     50.52|    76879.07|         53.06|           81019.29|
--Сертолово      |город        |       117|                     0.032|      101|         0.863|         16|         88|     0.000|    0.009|     0.991|     53.62|    69566.26|         53.06|           81019.29|
-----------------+-------------+----------+--------------------------+---------+--------------+-----------+-----------+----------+---------+----------+----------+------------+--------------+-------------------+
