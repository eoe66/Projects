/*
Задача 1. Расчёт DAU
Рассчитываем ежедневное количество активных зарегистрированных клиентов (user_id) за май и июнь 2021 года в городе Саранске.
Критерием активности клиента считаем размещение заказа, что позволит оценить эффективность вовлечения клиентов в ключевую бизнес-цель — совершение покупки.
Выводими следующие поля:
log_date — дата события.
DAU — количество активных зарегистрированных клиентов.
Результат отсортируем по дате события в возрастающем порядке.
*/
select
    log_date,
    count(distinct user_id) as DAU
from
    analytics_events as ae
    join cities as c on ae.city_id = c.city_id  
where
    event = 'order' and
    city_name  = 'Саранск' and
    log_date >= '2021-05-01' and 
    log_date <= '2021-06-30' 
group by
    log_date
order by
    log_date
;
/*
Задача 2. Расчёт Conversion Rate
Определяем активность аудитории:
как часто зарегистрированные пользователи переходят к размещению заказа,
будет ли одинаковым этот показатель по дням или видны сезонные колебания в поведении пользователей.
Рассчитываем конверсию зарегистрированных пользователей за каждый день в мае и июне 2021 года для клиентов из Саранс, которые посещают приложение, в активных клиентов.
Критерием активности считаем размещение заказа.
Выводим следующие поля:
log_date — дата события.
CR — значение конверсии.
Результат отсортируем по дню активности в возрастающем порядке. Значение конверсии округлим до двух знаков после точки. 
*/
select
    log_date,
    round((count(distinct user_id) filter (where event = 'order')) * 1.0 / count(distinct user_id), 2) as CR
from
    analytics_events as ae
    join cities as c on ae.city_id = c.city_id  
where
    city_name  = 'Саранск' and
    log_date >= '2021-05-01' and 
    log_date <= '2021-06-30' 
group by
    log_date
order by
    log_date
;
/*
Задача 3. Расчёт среднего чека
Рассчитываем средний чек, то есть средний доход за одну транзакцию (заказ)  активных клиентов в Саранске в мае и в июне.
При этом учтем, что анализ производим среднего чека сервиса доставки, а не ресторанов. Поэтому в данном случае средний чек - это среднее значение комиссии со всех заказов за месяц.
Для корректного расчёта метрики вычислим общий размер комиссии и количество заказов, затем разделим сумму комиссии на количество заказов.
Выводим следующие поля:
"Месяц" — месяц события.
"Количество заказов" — количество заказов за месяц.
"Сумма комиссии" — сумма комиссии за месяц.
"Средний чек" — средняя комиссия на одну транзакцию.
Сумму комиссии и среднего чека округлим до копеек, а результат отсортируем по полю с месяцем в возрастающем порядке.
*/
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT *,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')

-- Рассчитываем средний чек и выводим необходимые поля
select
    date_trunc('month', log_date)::date as "Месяц",
    count(distinct order_id) as "Количество заказов",
    round(sum(commission_revenue::numeric) * 1.0, 2) as "Сумма комиссии",
    round((sum(commission_revenue::numeric) / count(distinct order_id)), 2) as "Средний чек" 
from orders
group by date_trunc('month', log_date)::date
order by "Месяц"

/*
Задача 4. Расчёт LTV ресторанов
Определим три ресторана из Саранска с наибольшим LTV с начала мая до конца июня.
Как правило, LTV рассчитывается для пользователя приложения. В нашем случае клиентами для сервиса доставки будут и рестораны, как и пользователи, которые делают заказы.
Рассчитаем LTV как суммарную комиссию, которая была получена от заказов в ресторане за два указанных месяца.
Выводим следующие поля:
rest_id — уникальный идентификатор ресторана.
"Название сети" — название сети, к которой принадлежит ресторан.
"Тип кухни" — тип кухни ресторана.
LTV — суммарная комиссия, которая была получена от заказов в ресторане за два месяца.
Результат отсортируем по полю LTV в убывающем порядке, округлив до копеек.
*/
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')

-- Считаем суммарную комиссию и выводим необходимые поля
select
    o.rest_id,
    p.chain as "Название сети",
    p.type as "Тип кухни",
    round(sum(commission_revenue::numeric), 2) as LTV
from orders as o
join partners as p on o.rest_id = p.rest_id and o.city_id = p.city_id
group by o.rest_id, p.chain, p.type
order by LTV desc
;    
/*
Задача 5. Расчёт LTV ресторанов — самые популярные блюда
Проанализируем данные о ресторанах и их блюдах, чтобы определить вклад самых популярных блюд из ресторанов Саранска в общий показатель LTV.
Для 2 ресторанов с наибольшим LTV выбираем 5(всего пять блюд на 2 ресторана) самых популярных блюд, то есть блюд с максимальным LTV, за весь рассматриваемый период (май-июнь).
Для каждого блюда выводим следующие поля:
"Название сети" — название сети, к которой принадлежит ресторан.
"Название блюда" — название блюда, которое оказалось популярным.
spicy — логический признак острых блюд. 1 — блюдо острое.
fish — логический признак рыбных блюд. 1 — блюдо содержит морепродукты.
meat — логический признак мясных блюд. 1 — блюдо содержит мясо.
LTV — суммарная комиссия, которая была получена от заказов блюда в ресторане за эти два месяца, округлённая до копеек.
Результаты отсортируем по значению LTV в порядке убывания. 
*/
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            analytics_events.object_id,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'), 

-- Рассчитываем два ресторана с наибольшим LTV 
top_ltv_restaurants AS
    (SELECT orders.rest_id,
            chain,
            type,
            ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
     FROM orders
     JOIN partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id
     GROUP BY 1, 2, 3
     ORDER BY LTV DESC
     LIMIT 2)

-- Выводим 5 блюд с максимальным LTV
select
    tlr.chain as "Название сети",
    d.name as "Название блюда",
    d.spicy,
    d.fish,
    d.meat,
    round(sum(commission_revenue)::numeric, 2) as LTV
from
    top_ltv_restaurants as tlr
    join orders as o on tlr.rest_id = o.rest_id
    join dishes as d on o.object_id = d.object_id
group by  tlr.chain, d.name, d.spicy, d.fish, d.meat
order by LTV desc
limit 5;

/*
Задача 6. Расчёт Retention Rate
Определим показатель возвращаемости: какой процент пользователей возвращается в приложение в течение первой недели после регистрации и в какие дни.
Для корректного расчёта недельного Retention Rate нужно, чтобы с момента первого посещения прошла хотя бы неделя. Поэтому необходимо ограничить дату первого посещения продукта,
выбрав промежуток с начала мая по 24 июня.
Retention Rate посчитаем по любой активности пользователей, а не только по факту размещения заказа.
В данных могут встречаться дубликаты по полю user_id, поэтому для корректного расчёта используйте условие log_date >= first_date.
Выводим следующие поля:
day_since_install — срок жизни пользователя в днях.
retained_users — количество пользователей, которые вернулись в приложение в конкретный день.
retention_rate — коэффициент удержания для вернувшихся пользователей по отношению к общему числу пользователей, которые установили приложение.
Результаты отсортируем по полю day_since_install в порядке возрастания. Retention Rate округлим до двух знаков после точки.
*/
-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

-- Присоединяем активных к новым и считаем количестов дней после установки
t as
    (select nu.user_id,
            first_date,
            log_date,
            log_date::date - first_date::date as day_since_install
    from new_users as nu
    join active_users as au on  nu.user_id = au.user_id
    where log_date >= first_date
    order by  nu.user_id, day_since_install)

--Количество дней после установки ограничим < 8, найдем отношение вернувшихся пользователей к общему числу пользователей
select
    day_since_install,
    count(distinct user_id) as retained_users,
    round(count(distinct user_id) * 1.0 / max(count(distinct user_id)) over (order by day_since_install), 2) as retention_rate
from t
where day_since_install < 8
group by day_since_install
order by day_since_install

/*
Задача 7. Сравнение Retention Rate по месяцам
Разделим пользователей на две когорты по месяцу первого посещения продукта и сравним Retention Rate этих когорт между собой.
Выводим следующие поля:
"Месяц" — месяц первого посещения продукта.
day_since_install — срок жизни пользователя в днях.
retained_users — количество пользователей, которые вернулись в приложение в конкретный день.
retention_rate — коэффициент удержания для вернувшихся пользователей по отношению к общему числу пользователей, которые установили приложение в день установки.
Результаты отсортируем по полям "Месяц" и day_since_install в порядке возрастания. Метрику Retention Rate округлим до двух знаков после точки.
*/
-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

-- Соединяем таблицы с новыми и активными пользователями
daily_retention AS
    (SELECT new_users.user_id,
            first_date,
            log_date::date - first_date::date AS day_since_install
     FROM new_users
     JOIN active_users ON new_users.user_id = active_users.user_id
     AND log_date >= first_date)

--Количество дней после установки ограничим < 8, найдем отношение вернувшихся пользователей к общему числу пользователей, сгруппировав по месяцу первого посещения 
SELECT
    CAST(DATE_TRUNC('month', first_date) AS date) as "Месяц",
    day_since_install,
    count(distinct user_id) as retained_users,
    round(count(distinct user_id) * 1.0 / max(count(distinct user_id)) over (partition by CAST(DATE_TRUNC('month', first_date) AS date) order by  day_since_install), 2) as retention_rate
from daily_retention
where day_since_install < 8
group by "Месяц", day_since_install

order by "Месяц", day_since_install
