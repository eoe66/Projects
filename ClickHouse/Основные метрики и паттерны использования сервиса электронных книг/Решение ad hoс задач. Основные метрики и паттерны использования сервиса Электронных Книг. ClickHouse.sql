"
ЗАДАЧА 1:
Определить в каких городах сервис пользуется наибольшей популярностью:
1. Вывести топ-20 городов и регионов России по суммарному количеству прочитанных и прослушанных
часов любого контента с мобильных устройств.
2. Для каждой из платформ (iOS и Android) рассчитать длительность.
3. Из выдачи исключите федеральные округа — оставьте только города и области.
"

SELECT 
    usage_geo_id_name
    , toInt32(sum(hours)) as hours_total --общая длительность контента
    , toInt32(sumIf(hours, usage_platform_ru = 'Букмейт iOS')) as hours_ios --длительность на iOS
    , toInt32(sumIf(hours, usage_platform_ru = 'Букмейт Android')) as hours_android -- длительность на Android
FROM source_db.audition 
WHERE usage_country_name = 'Россия'  -- оставляем только Россию
    AND usage_geo_id_name NOT ILIKE '%федеральный округ%' -- исключаем федеральные округа
    AND (usage_platform_ru = 'Букмейт iOS' OR usage_platform_ru = 'Букмейт Android') -- оставляем необходимые платформы
GROUP BY usage_geo_id_name
ORDER BY hours_total DESC -- сортируем по убыванию общего времени
LIMIT 20; -- выводим топ-20


--usage_geo_id_name                      |hours_total|hours_ios|hours_android|
-----------------------------------------+-----------+---------+-------------+
--Москва                                 |      26628|     8055|        18573|
--Санкт-Петербург                        |      12537|     3793|         8744|
--Москва и Московская область            |       8248|     2411|         5836|
--Екатеринбург                           |       4817|     1493|         3324|
--Россия                                 |       4469|     1320|         3149|
--Краснодар                              |       3998|     1219|         2779|
--Новосибирск                            |       3823|     1154|         2668|
--Ростов-на-Дону                         |       3114|      963|         2150|
--Казань                                 |       2999|     1022|         1977|
--Пермь                                  |       2914|      821|         2092|
--Санкт-Петербург и Ленинградская область|       2884|      902|         1982|
--Уфа                                    |       2620|      779|         1841|
--Нижний Новгород                        |       2601|      702|         1899|
--Челябинск                              |       2585|      735|         1850|
--Красноярск                             |       2125|      685|         1440|
--Краснодарский край                     |       2083|      674|         1409|
--Воронеж                                |       1841|      551|         1289|
--Тюмень                                 |       1826|      581|         1245|
--Самара                                 |       1808|      557|         1250|
--Нижегородская область                  |       1574|      429|         1144|




"
ЗАДАЧА 2:
Определить самый популярный контент:  
1. Получить топ-5 книг по суммарному количеству прочитанных и прослушанных часов на мобильных платформах.
2. Вычислить среднее время чтения и прослушивания в зависимости от типа книги: текст или аудио.   
3. В список включать только те книги, которые используются в обоих форматах.
"

WITH books AS (
	SELECT  main_content_name
		, main_author_name
		, hours
		, IF(main_content_type = 'Audiobook', 0, 1) AS audiobook_or_boor_flg  -- audiobook - флаг 0, audiobook - флаг 1
		--определяем для каждой книги количество уникальных типов для дальнейшей фильтрации
		, count(distinct main_content_type) OVER (PARTITION BY main_content_name, main_author_name) AS count_type_flg
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book') -- оставляем необходимые типы контента
	AND (usage_platform_ru = 'Букмейт iOS' OR usage_platform_ru = 'Букмейт Android') -- оставляем необходимые платформы
)
SELECT 	main_content_name
	, main_author_name
    , round(sum(hours), 2) as hours_total --суммарное количество часов на платформах
    , round(avgIf(hours, audiobook_or_boor_flg = 1), 2) as avg_hours_book  --среднее время чтения текстовой книги
    , round(avgIf(hours, audiobook_or_boor_flg = 0), 2) as avg_hours_audiobook  --среднее время прослушивания аудиокниги
FROM books
WHERE count_type_flg = 2  --оставляем только книги представленные в двух типах book и audiobook
GROUP BY main_content_name, main_author_name
ORDER BY  hours_total DESC  -- сортируем по убыванию общего времени
LIMIT 5; --выводим топ-5


--main_content_name        |main_author_name|hours_total|avg_hours_book|avg_hours_audiobook|
---------------------------+----------------+-----------+--------------+-------------------+
--Илон Маск                |Уолтер Айзексон |    1012.93|          0.29|               0.69|
--Железное пламя           |Ребекка Яррос   |     781.16|          1.74|               1.89|
--Убийства и кексики. ...  |Питер Боланд    |     541.87|          0.68|               1.63|
--Четвертое крыло          |Ребекка Яррос   |     501.67|          1.58|               1.34|
--Земля лишних. Трилогия   |Андрей Круз     |     481.97|          2.47|               2.75|




"
ЗАДАЧА 3:
1. Составить топ-10 авторов по суммарной длительности чтения их книг на всех платформах, включая веб.
2. Для каждого автора посчитать количество уникальных текстовых книг
3. Для каждого автора посчитать посчитать среднюю длительность прослушивания их аудиокниг только на мобильных устройствах.
4. Исключить авторов, у которых нет аудиокниг.
"

WITH books AS (
SELECT  main_author_name
		, main_content_name
		, usage_platform_ru
		, hours
		, IF(main_content_type = 'Audiobook', 0, 1) AS audiobook_or_boor_flg  -- audiobook - флаг 0, audiobook - флаг 1
		--определяем для каждого автора количество аудиокниг для дальнейшей фильтрации
		, countIf(main_content_type, main_content_type = 'Audiobook') OVER (PARTITION BY main_author_name) AS count_audiobook
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book')  -- оставляем необходимые типы контента
	AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android', 'Букмейт Web')  -- оставляем необходимые платформы
)
SELECT 	main_author_name
    , round(sumIf(hours, audiobook_or_boor_flg = 1), 2) as hours_book  --суммарная длительность чтения
    , uniqExactIf(main_content_name, audiobook_or_boor_flg = 1) as uniq_book  --количество уникальных текстовых книг
    --средняя длительность прослушивания аудиокниг только на мобильных устройствах
    , round(avgIf(hours, audiobook_or_boor_flg = 0 AND  usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')), 2) as avg_hours_audiobook
FROM books
WHERE count_audiobook > 0  --оставляем только авторов с аудиокнигами 
GROUP BY main_author_name
ORDER BY hours_book DESC --сортируем по убыванию времени чтения
LIMIT 10;  --выводим топ-10


--main_author_name   |hours_book|uniq_book|avg_hours_audiobook|
---------------------+----------+---------+-------------------+
--Александра Лисина  |   1558.35|71       |               2.27|
--Дарья Донцова      |   1498.96|163      |               1.91|
--Константин Муравьёв|     834.4|24       |               2.67|
--Елена Звёздная     |    814.96|43       |               1.69|
--Сергей Лукьяненко  |    813.62|54       |               1.76|
--Робин Хобб         |    687.22|18       |               1.29|
--Виктор Пелевин     |     633.7|30       |               0.96|
--Ребекка Яррос      |     565.9|2        |               1.67|
--Татьяна Устинова   |    545.47|63       |               1.53|
--Макс Фрай          |    500.54|38       |                1.3|



"
ЗАДАЧА 4:
Подтвердить или опровергнуть предположение:
1. что среди Android-пользователей аудиокниги почти так же популярны, как тексты.
2. что среди iOS-пользователей читателей книг вдвое больше, чем слушателей, если считать по суммарной длительности сессии.  

К типу «Слушатель» отнести тех пользователей, кто преимущественно пользуется аудиокнигами.
Прослушивание книг составляет 70% и выше от суммарной длительности сессий.
К типу «Читатель» — преимущественно пользуется текстовыми книгами. Чтение книг — от 70%.
К типу «Оба» — остальные пользователи сервиса.  

Для определения основной платформы пользователя, учитывать время её использования.

Исключить пользователей, у которых нет сессий ни с книгами, ни с аудиокнигами.
"


WITH 
--объединение и фильтрация данных
books AS (
	SELECT  *
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book') -- учитываем пользователей с книжным контентом
	AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android') -- учитываем пользователей нужных платформ
),
--промежуточные расчеты и категоризация
category_users AS (
	SELECT 	puid
		, usage_platform_ru
	    , sum(hours) as hours_total  --расчет суммарного времени
	    , sumIf(hours, main_content_type='Audiobook') AS hours_audiobook  --расчет времени на прослушивание
	    , sumIf(hours, main_content_type='Book') AS hours_book  --расчет времени на чтение
	    , multiIf(
	    	hours_audiobook / hours_total >= 0.7, 'Слушатель',	hours_book / hours_total >= 0.7, 'Читатель', 'Оба'
	    	) AS category  --cегментируем пользователей
	    --в случае, если в таблице есть пользователи с двумя платформами, необходимо оставить только ту,
	    --где время использования больше. Для этого проставим ранги на основе поля hours_total
	    , ROW_NUMBER() OVER (PARTITION BY puid, usage_platform_ru ORDER BY hours_total DESC) AS rn
	FROM books
	GROUP BY puid, usage_platform_ru
)
SELECT category 
	, count(puid) AS user_total  --общее количество мобильных пользователей 
	, countIf(puid, usage_platform_ru = 'Букмейт iOS') AS count_user_ios  --количество iOS-пользователей
	, countIf(puid, usage_platform_ru = 'Букмейт Android') AS count_user_android  --количество Andriod-пользователей
FROM category_users
WHERE rn=1  --оставлеем для пользователей платформу с максимальным временем
GROUP BY category
ORDER BY  user_total DESC; 


--category |user_total|count_user_ios|count_user_android|
-----------+----------+--------------+------------------+
--Читатель |      4492|          2057|              2435|
--Слушатель|      3722|          1535|              2187|
--Оба      |       696|           296|               400|

--Среди пользователей андройд действительно примерно одинаковое количество читателей и слушателей.
--А для iOS-пользователей доля читателей больше слушателей на треть, а не в два раза как предполагалось. 



"
ЗАДАЧА 5:
Определить, существует ли связь между форматом использования приложения (прослушивание или чтение) и днём недели.
Падает ли использование аудиокниг в выходные на всех платформах, включая веб?   
"

WITH 
--объединение и фильтрация данных
books AS (
SELECT  hours
		, main_content_type
		, toDayOfWeek(toDate(msk_business_dt_str)) AS day_of_week --определяем номер дня недели
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book') -- учитываем пользователей с книжным контентом
	AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android', 'Букмейт Web') -- учитываем пользователей нужных платформ
	),
-- агрегация по дням недели
hours_per_days AS (
	SELECT main_content_type
		, day_of_week
		, sum(hours) AS hours_per_day
	FROM books
	GROUP BY day_of_week, main_content_type
)
SELECT
	main_content_type
	, round(avgIf(hours_per_day, day_of_week < 6)) AS avg_hours_weekday -- среднее время по будням
	, round(avgIf(hours_per_day, day_of_week >= 6)) AS avg_hours_weekend --среднее время по выходным
	, round(100 * (avg_hours_weekend / avg_hours_weekday - 1), 1) AS diff_percent --процентная разница
FROM hours_per_days
GROUP BY main_content_type


--main_content_type|avg_hours_weekday|avg_hours_weekend|diff_percent|
-------------------+-----------------+-----------------+------------+
--Book             |          11444.0|          10838.0|        -5.3|
--Audiobook        |          20559.0|          16961.0|       -17.5|

--Для каждого формата наблюдаем снижение активности использования в выходные. Однако для аудиоформата это снижение более выраженное



"
ЗАДАЧА 6:
Подтвердить или опровергнуть предположение, что больший процент пользователей iOS используют последнюю
версию приложения.
"

WITH 
--объединение и фильтрация данных
books AS (
	SELECT  puid, usage_platform_ru, app_version -- оставляем нужные поля
		--последняя версия для кажждой платформы
		, max(app_version) OVER(PARTITION BY usage_platform_ru) AS final_app_version_platform
		--последняя версия пользователя
		, max(app_version) OVER(PARTITION BY puid, usage_platform_ru) AS final_app_version_user 
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book') -- учитываем пользователей с книжным контентом
	AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android') -- учитываем пользователей нужных платформ
),
--процент пользователей для каждой версии и платформы
version_platform AS (
	SELECT usage_platform_ru
		, final_app_version_platform
		, final_app_version_user
		-- количество пользователей для каждой версии
		, uniq(puid) AS count_user 
		--количество пользователей для каждой платформы
		, sum(count_user) OVER(PARTITION BY usage_platform_ru) AS count_user_in_platform 
		, round(100 * count_user / count_user_in_platform, 2) AS percent_users
	FROM books
	--оставляем запись с последней версией платформы для каждого  пользователя
	WHERE app_version = final_app_version_user 
	GROUP BY  usage_platform_ru
		, final_app_version_platform
		, final_app_version_user
)
SELECT usage_platform_ru, percent_users 
FROM version_platform
WHERE final_app_version_platform = final_app_version_user -- оставляем записи с последними версиями


--usage_platform_ru|percent_users|
-------------------+-------------+
--Букмейт iOS      |         1.85|
--Букмейт Android  |        29.11|

--Больший процент пользователей Andriod используют последнюю версию приложения, а не iOS как предполагалось




"
ЗАДАЧА 7:
Проверить предположение о том, что пользователи iOS чаще обновляют приложение,
рассчитав метрику update_rate, которая покажет среднюю частоту обновлений на пользователя.

Фактом обновления считать изменение версии у каждого пользователя. 
Любое изменение возможно только в сторону более новой версии.
"

WITH 
--объединение и фильтрация данных
books AS (
	SELECT  
		-- оставляем нужные поля
		puid, usage_platform_ru, app_version 
		-- число обновлений равно числу версий минус 1
		, uniqExact(app_version) OVER (PARTITION BY puid, usage_platform_ru) - 1  AS count_update 
	FROM source_db.audition a
	LEFT JOIN source_db.content c USING (main_content_id)
	WHERE main_content_type IN ('Audiobook', 'Book') -- учитываем пользователей с книжным контентом
	AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android') -- учитываем пользователей нужных платформ
),
--агрегируем данные
count_update_users AS (
	SELECT puid, usage_platform_ru, count_update
	FROM books
	GROUP BY ALL 
)
SELECT usage_platform_ru
	--метрика update_rate = суммарное число обновлений на платформе / количество пользователей на платформе
	, round(sum(count_update) / count(puid), 2) AS update_rate
FROM count_update_users
GROUP BY usage_platform_ru;


--usage_platform_ru|update_rate|
-------------------+-----------+
--Букмейт iOS      |       2.07|
--Букмейт Android  |       2.67|

--Пользователи Android чаще обновляют приложение



"
ЗАДАЧА 8:
Найти количество книг с тегом «Магия».
"

SELECT count(distinct main_content_name) AS uniq_magical_books_in_catalog
	, count(main_content_name) AS magical_books_in_catalog
FROM source_db.content
WHERE has(published_topic_title_list, 'Магия') == 1
;


--uniq_magical_books_in_catalog|magical_books_in_catalog|
-------------------------------+------------------------+
--                           40|                      46|

--В каталоге 40 уникальных книг имеющих тег Магия. Общее число книг с тегом Магия - 46.



"
ЗАДАЧА 9:
Найти количнество книги со словом «магия» в названии, для которых не проставлен тег «Магия». 
При этом не учитывать книги с тегом «Художественная литература».
"

SELECT
	count(distinct main_content_name) AS uniq_magical_books
	, count( main_content_name) AS count_magical_books
FROM source_db.content
WHERE main_content_name ILIKE '%магия%'
AND has(published_topic_title_list, 'Магия') == 0
AND has(published_topic_title_list, 'Художественная литература') == 0
;


--uniq_magical_books|count_magical_books|
--------------------+-------------------+
--47                |49                 |

--Для 49 книг не проставлен тег Магия. Из них 47 имеют уникальные названия



"ЗАДАЧА 10:
Посчитать среднее количество категорий у книг с тегом «Магия» и среднее количество категорий у книг в каталоге в целом."

SELECT 
	--cреднее количество категорий у книг в каталоге в целом
	round(avg(length(published_topic_title_list)), 2) AS avg_category
	--среднее количество категорий у книг с тегом Магия
	, round(avgIf(length(published_topic_title_list), has(published_topic_title_list, 'Магия') == 1), 2)  AS avg_category_magical_books
FROM source_db.content;


--avg_category|avg_category_magical_books|
--------------+--------------------------+
--        3.77|                      3.22|



"
ЗАДАЧА 11:
Найти страну и платформу, для которых в данных видна аномалия, а именно некорректно записывается длина пользовательской сессии.
"

SELECT usage_country_name
    , usage_platform_ru
    -- коэффициент вариации = стандартное отклонение / среднее 
    , round(stddevSamp(hours_sessions_long) / avg(hours_sessions_long), 2) AS coeff_variation
FROM source_db.audition
WHERE usage_platform_ru = 'Букмейт iOS' OR usage_platform_ru = 'Букмейт Android'
GROUP BY usage_country_name, usage_platform_ru
--чем выше коэффициент вариации, тем более подозрительно с точки зрения анализа распределены данные
ORDER BY coeff_variation DESC  --сортируем в порядке убывания коэффициента вариации
LIMIT 1; --выводим первое значение
    

--usage_country_name|usage_platform_ru|coeff_variation|
--------------------+-----------------+---------------+
--Латвия            |Букмейт Android  |            7.8|
