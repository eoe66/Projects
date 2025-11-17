--Чарт1 (индикатор). Общее количество активных благотворителей

--Чарт отражает количество активных благотворителей за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы.
--Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0

select count(distinct "OrderCustomerIdsMindboxId") as "Кол-во активных благотворителей"
from aif_data.order
where "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0

------------------------------------------------------------------------

--Чарт 2 (кольцевая диаграмма). Структура активных благотворителей

	--Чарт отражает доли физических и юридических лиц от общего числа активных благотворителей за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0

with
-- Проводим категоризацию каждого пользователя. По записи в поле "CustomerSex" определяем к какой категории относится благотворитель к физическому (в поле "CustomerSex" имеется запись о принадлежности к полу) или юридическому лицу (в поле "CustomerSex" нет записи о принадлежности к какому-либо полу)
category_user as (
        select distinct "OrderCustomerIdsMindboxId",
               case when "CustomerSex" is null then 'Юридические лица' else 'Физические лица' end as "Категория благотворителя"
        from aif_data.order as o
             join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId"
        where "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0
	)
-- считаем долю для каждой категории
select "Категория благотворителя",
        count(*) * 1.0 / (sum(count(*)) over()) as "Доля"
from category_user
group by "Категория благотворителя"


------------------------------------------------------------------------

--Чарт3 (линейная диаграмма). Динамика активных благотворителей по месяцам (MAU)

--1. Чарт отражает динамику активных благотворителей по месяцам за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Даты пожертвований округляем до месяца
--5. Группируем по месяцам и для каждого месяца считаем количество уникальных активных благотворителей, а таккже количество уникальных активных физических и юридических лиц. 

select
        date(date_trunc('month', "OrderFirstActionDateTimeUtc")),
        count(distinct "OrderCustomerIdsMindboxId") as "Кол-во активных благотворителей",
        count(distinct "OrderCustomerIdsMindboxId") filter (where "CustomerSex" is null ) as "Юридических лиц",
        count(distinct "OrderCustomerIdsMindboxId") filter (where "CustomerSex" is not null ) as "Физических лиц"
from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0
group by 1

------------------------------------------------------------------------

--Чарт 4 (индикатор). Количество благотворителей - физических лиц

--1. Чарт отражает количество уникальных активных благотворителей - физических лицза весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей с указанным полом ("CustomerSex" is not null)

select 
    count(distinct "OrderCustomerIdsMindboxId") as "Количество благотворителей"
from aif_data.order as o
join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid'
    and 
    "OrderTotalPrice" > 0
    and
    "CustomerSex" is not null

------------------------------------------------------------------------

--Чарт4 (таблица). Информация о пожертвованиях по когортам в зависимости от пола (мужчины и женщины)

--1. Чарт отражает среднее количество пожертвований и среднюю сумму пожертвований одного активного благотворителя по когортам (мужчины и женщины) за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей с указанным полом ("CustomerSex" is not null)
--5. Группируем по полу и находим количество транзакций для каждого пола и среднее значение транзакции

select  
    "CustomerSex" as "Пол",
    count(distinct "OrderCustomerIdsMindboxId") *  1.0 / (sum(count(distinct "OrderCustomerIdsMindboxId")) over()) as "Доля",
    round(count("OrderIdsWebsiteID") * 1.0 / count(distinct "OrderCustomerIdsMindboxId")) as "Среднее кол-во пожертвований",
    round(avg("OrderTotalPrice"), 2) as "Средняя сумма пожертвования, руб" 
from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid'
    and 
    "OrderTotalPrice" > 0
    and
    "CustomerSex" is not null
group by  "CustomerSex"

------------------------------------------------------------------------

--Чарт 5 (диаграмма). Доля благотворителей по когортам в зависимости от количества пожертвований

--1. Чарт отражает доли активных благотворителей (мужчин и женщин - физических лиц) в группах по количеству пожертвований: 1, 2-10 и более 10. Учитывается весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей с указанным полом ("CustomerSex" is not null)


with 
-- для каждого благотворителя с корректной суммой пожертвования и указанным полом считаем общее число пожертвований и общую сумму пожертвований
user_payment_tab as 
    (
    select 
        "OrderCustomerIdsMindboxId" as user_id,
        "CustomerSex" as user_sex,
        sum("OrderTotalPrice")  as sum_user_payment,
        count("OrderIdsWebsiteID") as count_user_payment_id
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0 and "CustomerSex" is not null
    group by 1, 2
    ),
--Доля благотворителей и общая сумма пожертвований в разрезе количества пожертвований и пола
count_payment_tab as 
    (
    select
        count_user_payment_id,
        user_sex,
        count(user_id) * 1.0 / (sum(count(user_id)) over ()) as share
    from user_payment_tab
    group by count_user_payment_id, user_sex
    ),
--добавляем категории по количеству пожертвований: 1 пожертвование, от 2 до 10, от 11  и более  
category_user_payment as 
    (
    select *,
        case
            when count_user_payment_id = 1 then '1 пожертвование'
            when count_user_payment_id > 10  then 'более 10 пожертвований'
            else 'от 2 до 10 пожертвований' 
            end as category 
    from count_payment_tab
    )
select
    category,
    sum(share) filter (where user_sex = 'female') as "Доля женщин",
    sum(share) filter (where user_sex = 'male') as "Доля мужчин"
from category_user_payment
group by category
order by 2 desc
------------------------------------------------------------------------

--Чарт6 (линейный). Коэффициент удержания благотворителей ФЛ по когортам

--1. Чарт отражает распределение ежемесячного Retention Rate  всех благотворителей, совершивших пожертвование в августе 2022 года (независимо от того, новые это пользователи или нет). Благотворителей оазделим по когортам в зависимости от пола благотворителей. Благотворителей, для которых нет данных пола,  исключим из расчёта. 
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0

with 
--1/ находим благотворителей активных в августе 2022 года с корректной транзакцией, на сумму больше 0 рублей  и указанным полом 
user_08_2022 as 
    (
    select 
        distinct "OrderCustomerIdsMindboxId" as id_user,
        "CustomerSex" as sex_user,
        date(date_trunc('month', "OrderFirstActionDateTimeUtc")) as month_0
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        date_trunc('month', "OrderFirstActionDateTimeUtc") = '2022-08-01'
        and 
        "OrderLineStatusIdsExternalId" = 'Paid'
        and
        "OrderTotalPrice" > 0
        and 
        "CustomerSex" is not null
    ),

--2/ находим благотворителей с указанным полом и корректными транзакциями в августе 2022 года и позже, дату транзакции округлим до месяца 
user_activity as 
    (
    select 
        "OrderCustomerIdsMindboxId" as id_user,
        date(date_trunc('month', "OrderFirstActionDateTimeUtc")) as month_activity
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        date_trunc('month', "OrderFirstActionDateTimeUtc") >= '2022-08-01'
            and
        "OrderLineStatusIdsExternalId" = 'Paid'
        and
        "OrderTotalPrice" > 0
        and 
        "CustomerSex" is not null
    ),

--3/ объединяем благотворителей активных в августе 2022 года со всеми их транзакциями в этом месяце и позже. Посчитаем для каждой транзакции сколько месяцев прошло после августа 2022
user_08_2022_and_his_activity as 
    (
    select 
        id_user,
        sex_user,
        month_0,
        month_activity,
        extract(year from age(month_activity, month_0)) * 12 + extract(month from age(month_activity, month_0)) as month_since_0
    from user_08_2022
    left join user_activity using(id_user)
    ),

--4/ Группируем по месяцам активности( поле month_since_0). Для каждой такой группы находим количество уникальных благотворителей и долю этих благотворителей от общего числа уникальных благотворителей в начальный месяц (август 2022 года) для каждой когорты (по полу поле "CustomerSex") 
retention_rate as 
    (
    select 
        month_since_0 as "Количество месяцев после РК",
        month_activity as "Месяц активности",
        count(distinct id_user) filter (where sex_user = 'female') as "Количество женщин",
        count(distinct id_user) filter (where sex_user = 'male') as "Количество мужчин",
        count(distinct id_user) filter (where sex_user = 'female') * 1.0 / max(count(distinct id_user) filter (where sex_user = 'female')) over (order by month_since_0) as "Retention Rate женщин",
        count(distinct id_user) filter (where sex_user = 'male') * 1.0 / max(count(distinct id_user) filter (where sex_user = 'male')) over (order by month_since_0) as "Retention Rate мужчин"
    from user_08_2022_and_his_activity
    group by 1, 2
    )

select *
from retention_rate
where "Количество месяцев после РК" > 0


------------------------------------------------------------------------

--Чарт 7 (индикатор) Количество благотворителей - юридических лиц

--1. Чарт отражает количество уникальных активных благотворителей - юридических лицза весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей без указанного пола ("CustomerSex" is null)

select 
    count(distinct "OrderCustomerIdsMindboxId") as "Количество благотворителей"
from aif_data.order as o
join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid'
    and 
    "OrderTotalPrice" > 0
    and
    "CustomerSex" is null

------------------------------------------------------------------------

--Чарт 8 (таблица).Информация о пожертвованиях ЮЛ

--1. Чарт отражает среднее количество пожертвований и среднюю сумму пожертвований одного активного благотворителя ЮЛ  за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей без указанного пола ("CustomerSex" is null)

select  
    round(count("OrderIdsWebsiteID") * 1.0 / count(distinct "OrderCustomerIdsMindboxId")) as "Среднее кол-во пожертвований",
    round(avg("OrderTotalPrice"), 2) as "Средняя сумма пожертвования, руб" 
from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid'
    and 
    "OrderTotalPrice" > 0
    and
    "CustomerSex" is null


------------------------------------------------------------------------

--Чарт 9 (диаграмма) Доли благотворителей - юридических лиц по количеству пожертвований

--1. Чарт отражает доли активных благотворителей (юридических лиц) в группах по количеству пожертвований: 1, 2-10 и более 10. Учитывается весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0
--4. Учитываем благотворителей без указанного полом ("CustomerSex" is null)

with 
-- для каждого благотворителя с корректной суммой пожертвования считаем общее число пожертвований и общую сумму пожертвований
user_payment_tab as 
    (
    select 
        "OrderCustomerIdsMindboxId" as user_id,
        sum("OrderTotalPrice")  as sum_user_payment,
        count("OrderIdsWebsiteID") as count_user_payment_id
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0 and  "CustomerSex" is null
    group by 1
    ),

--Доля благотворителей и общая сумма пожертвований в разрезе количества пожертвований
count_payment_tab as 
    (
    select  count_user_payment_id,
            count(user_id) * 1.0 / (sum(count(user_id)) over ()) as share
    from user_payment_tab
    group by count_user_payment_id
    ),
--добавляем категории по количеству пожертвований: 1 пожертвование, от 2 до 10, от 11  и более  
category_user_payment as (
    select *,
        case
            when count_user_payment_id = 1 then '1 пожертвование'
            when count_user_payment_id > 10  then 'более 10 пожертвований'
            else 'от 2 до 10 пожертвований' 
            end as category 
    from count_payment_tab
    )
select category,
       sum(share) as "Доля благотворителей"
from category_user_payment
group by category
order by 2 desc
------------------------------------------------------------------------

--Чарт 10 (линейная). Коэффициент удержания ЮЛ 

--1. Чарт отражает распределение ежемесячного Retention Rate  всех благотворителей, совершивших пожертвование в августе 2022 года (независимо от того, новые это пользователи или нет). Рассматриваем благотворителей, для которых нет данных пола. 
--2. Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--3. Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0


--1/ находим благотворителей ЮЛ активных в августе 2022 года с корректной транзакцией и указанным полом 
with 
user_08_2022 as 
    (
    select 
        distinct "OrderCustomerIdsMindboxId" as id_user,
        date(date_trunc('month', "OrderFirstActionDateTimeUtc")) as month_0
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        date_trunc('month', "OrderFirstActionDateTimeUtc") = '2022-08-01'
        and 
        "OrderLineStatusIdsExternalId" = 'Paid'
        and
        "OrderTotalPrice" > 0
        and 
        "CustomerSex" is null
    ),

--2/ находим благотворителей ЮЛ с корректными транзакциями в августе 2022 года и позже, дату транзакции округлим до месяца
user_activity as 
    (
    select 
        "OrderCustomerIdsMindboxId" as id_user,
        date(date_trunc('month', "OrderFirstActionDateTimeUtc")) as month_activity
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        date_trunc('month', "OrderFirstActionDateTimeUtc") >= '2022-08-01'
            and
        "OrderLineStatusIdsExternalId" = 'Paid'
        and
        "OrderTotalPrice" > 0
        and 
        "CustomerSex" is null
    ),

--3/ объединяем благотворителей активных в августе 2022 года со всеми их транзакциями в этом месяце и позже. Посчитаем для каждой транзакции сколько месяцев прошло после августа 2022
user_08_2022_and_his_activity as 
    (
    select 
        id_user,
        month_0,
        month_activity,
        extract(year from age(month_activity, month_0)) * 12 + extract(month from age(month_activity, month_0)) as month_since_0
    from user_08_2022
    left join user_activity using(id_user)
    ),

--4/ Группируем по месяцам активности( поле month_since_0). Для каждой такой группы находим количество уникальных благотворителей и долю этих благотворителей от общего числа уникальных благотворителей в начальный месяц (август 2022 года)
retention_rate as 
    (
    select 
        month_since_0 as "Количество месяцев после РК",
        month_activity as "Месяц активности",
        count(distinct id_user) as "Количество",
        count(distinct id_user)  * 1.0 / max(count(distinct id_user)) over (order by month_since_0) as "Retention Rate"
    from user_08_2022_and_his_activity
    group by 1, 2
    )

select *
from retention_rate
where "Количество месяцев после РК" > 0


------------------------------------------------------------------------
------------------------------------------------------------------------

--Чарт 11 (индикатор). Объем пожертвований

--Чарт дашборда отражает общий объем благотворительных транзакций  за весь период, представленный в данных. Учитываются пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" - идентификатор статуса позиции заказа значение 'Paid'

select
        sum("OrderTotalPrice") as "Объем пожертвований"
from aif_data.order
where "OrderLineStatusIdsExternalId" = 'Paid'

------------------------------------------------------------------------

--Чарт 12(индикатор) = чарт 1. Общее количество активных благотворителей

--Чарт отражает количество активных благотворителей за весь период, представленный в данных. Активным считаем благотворителя, который оплатил хотя бы одно пожертвование на сумму больше 0 рублей.
--Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы.
--Учитываем пожертвования, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0

select
        count(distinct "OrderCustomerIdsMindboxId") as "Кол-во активных благотворителей"
from aif_data.order
where "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0

------------------------------------------------------------------------

--Чарт 13 (индикатор)ю Количество регионов в благотворительном фонде

--1/ Учитываем регионы с пожертвованиями, которые имеют в поле "OrderLineStatusIdsExternalId" (идентификатор статуса позиции заказа) значение 'Paid', а в поле "OrderTotalPrice" значения больше 0

select
    count(distinct "CustomerAreaName") as "Количество регионов"
from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid' and "OrderTotalPrice" > 0

------------------------------------------------------------------------

--Чарт 14 (диаграмма). ТОП-10 городов по количеству благотворителей

-- Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
--Учитываем только благотворителей с корректными пожертвованиями ("OrderLineStatusIdsExternalId" = 'Paid') на сумму более 0 рублей ("OrderTotalPrice" > 0)
with 

-- Группируем по региону, находим количество благотворителей и среднее значение количества пожертвований, ранжируем регионы по количеству благотворителей
user_area as
    ( 
    select  "CustomerAreaName" as "Регион",
            count(distinct "OrderCustomerIdsMindboxId") as "Количество благотворителей",
            count("OrderTotalPrice") * 1.0 / count(distinct "OrderCustomerIdsMindboxId") as "Среднее кол-во пожертвований",
            rank() over (order by count(distinct "OrderCustomerIdsMindboxId") desc) as user_rank
    from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
        "OrderLineStatusIdsExternalId" = 'Paid'
        and
        "OrderTotalPrice" > 0
        and
        "CustomerAreaName" is not null
    group by  1
    )
 
select  "Регион",
        "Количество благотворителей",
        "Среднее кол-во пожертвований"
from user_area
where user_rank <= 10
------------------------------------------------------------------------

--Чарт 16 (диаграмма).LTV по когортам в зависимости от региона пользователя для регионов из ТОП-10

-- Чарт отражает LTV благотворителей из регионов с максимальным количеством активных благотворителей (ТОП-10) за весь период, представленный в данных.
-- Используем таблицу aif_data.order с информацией о пожертвованиях, где пожертвования обозначаются как заказы. И таблицу aif_data.id_donor с информацией о благотворителях и донорах.
-- Учитываем только благотворителей с корректными пожертвованиями ("OrderLineStatusIdsExternalId" = 'Paid') на сумму более 0 рублей ("OrderTotalPrice" > 0) 

with 
--  находим благотворителей с корректной транзакци, группируем по региону и находим количество транзакций для каждого  и среднее значение транзакции
user_area as 
    (
    select 
            "CustomerAreaName" as "Регион",
            sum("OrderTotalPrice") / count(distinct "OrderCustomerIdsMindboxId") as "LTV",
            rank() over (order by count(distinct "OrderCustomerIdsMindboxId") desc) as user_rank
    from aif_data.order as o
        join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
    where
            "OrderLineStatusIdsExternalId" = 'Paid'
            and
            "OrderTotalPrice" > 0
            and
            "CustomerAreaName" is not null
    group by  1
)

select  "Регион",
        "LTV"
from user_area
where user_rank <= 10

------------------------------------------------------------------------

--Чарт 17 (таблица). Благотворители и их пожертвования по регионам

--В таблице представлены все регионы с информацией об активных благотворителях за весь период, представленный в данных.


select 
    "CustomerAreaName" as "Регион",
    count(distinct "OrderCustomerIdsMindboxId") as "Кол-во активных благотворителей",
    count("OrderTotalPrice") as "Общее число пожертвований",
    sum("OrderTotalPrice") as "Общая сумма пожертвования, руб",
    sum("OrderTotalPrice") / count(distinct "OrderCustomerIdsMindboxId") as "LTV благотворителя, руб"
from aif_data.order as o
    join aif_data.id_donor as d on o."OrderCustomerIdsMindboxId" = d."CustomerIdsMindboxId" 
where
    "OrderLineStatusIdsExternalId" = 'Paid'
    and
    "OrderTotalPrice" > 0
    and
    "CustomerAreaName" is not null
group by 1
order by 1
------------------------------------------------------------------------


