
--ЗАДАНИЕ №1
В каких городах больше одного аэропорта?

select city -- вывожу город
from airports a -- из таблицы аэропорты
group by city -- группирую по городу
having count(airport_code) > 1;  -- фильтрую до нужного требования 



--ЗАДАНИЕ №2
В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

В решении обязательно должно быть использовано - Подзапрос

select distinct a.airport_name 
from airports a  
join flights f on a.airport_code = f.departure_airport 
where f.aircraft_code = (
select a.aircraft_code 
from aircrafts a 
order by a."range" desc limit 1);


--ЗАДАНИЕ №3
Вывести 10 рейсов с максимальным временем задержки вылета.

В решении обязательно должно быть использовано - Оператор LIMIT

select f.flight_id, f.actual_departure - f.scheduled_departure "Задержка рейса" -- Вывожу id рейса и задержку 
from flights f -- из таблицы рейсы
where f.actual_departure is not null -- фильтрую реальныое время вылета не должно равнятся нулю 
order by f.actual_departure - f.scheduled_departure desc -- сортирую задержку по убыванию 
limit 10; -- ограниченное количество 10 


--ЗАДАНИЕ №4
Были ли брони, по которым не были получены посадочные талоны?

В решении обязательно должно быть использовано - Верный тип JOIN

select 
case when count(b.book_ref) > 0 then 'Yes'-- показать условные выражения количество записей в номере бронирования больше 0 показать да
else 'No'-- если есть 0 показать no
end "Брони без посадочного талона", -- вывести столбец с названием
count(b.book_ref) as "Количество" -- вывести количество записей
from bookings b -- из таблицы бронирования
join tickets t on t.book_ref = b.book_ref -- Присоединию из таблицы билеты номер бронирования
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- Присоединяю из таблицы посадочные талоны номер билета
where bp.boarding_no is null; -- фильтрую по номеру посадочного талона, чтобы проверить брони, по которым не было получено посадочных талонов


5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

- Оконная функция
- Подзапросы или/и cte

Честно говоря в ответе не совсем уверен, опирался на логику запросов. 

with boarded as (
select f.flight_id, f.flight_no, f.aircraft_code, departure_airport, f.scheduled_departure, f.actual_departure,
count(bp.boarding_no) boarded_count 
from flights f 
join boarding_passes bp on bp.flight_id = f.flight_id 
where f.actual_departure is not null
group by f.flight_id 
),
max_seats_by_aircraft as(
	select s.aircraft_code,
		count(s.seat_no) max_seats
	from seats s 
	group by s.aircraft_code 
)
select b.flight_no as "номер рейса" , b.boarded_count as "Количество посадочных талонов", m.max_seats - b.boarded_count free_seats, 
round((m.max_seats - b.boarded_count) / m.max_seats :: dec, 2) * 100 free_seats_percent,
sum(b.boarded_count) over (partition by (b.departure_airport, b.actual_departure::date) order by b.actual_departure) "Накопительный итог"
from boarded b 
join max_seats_by_aircraft m on m.aircraft_code = b.aircraft_code;



--ЗАДАНИЕ №6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- В решении обязательно должно быть использовано - Подзапрос или окно
- Оператор ROUND


select a.model as "Модель самолета", -- Вывожу столбец типы самолетов
count(f.flight_id) as "Кол-во рейсов", -- подсчитываю количество рейсов
round(count(f.flight_id) / -- применяю округление дробей
(select count(f.flight_id) -- подзапрос количество количество рейсов
from flights f -- из таблицы рейсы 
where f.actual_departure is not null) -- применяю фильтр на столбец фактическое время вылета
::dec * 100, 4) as "Процент от общего числа" -- применяю тип данных decimal
from aircrafts a -- из таблицы самолеты
join flights f on f.aircraft_code = a.aircraft_code -- присоединяю из таблицы рейсы код самолета
where f.actual_departure is not null -- фильтрую фактическое время вылета, чтобы не было равно нулю 
group by a.model; -- группирую по типу(модели) самолета

Николай, если баллов не хватит поясните пожалуйста какие данные мне нужно подтянуть в этом задании.
Спасибо!) 

--ЗАДАНИЕ №8
--Между какими городами нет прямых рейсов?
-- В решении обязательно должно быть использован 
- Декартово произведение в предложении FROM
- Самостоятельно созданные представления (если облачное подключение, то без представления)
- Оператор EXCEPT

create view not_cross as -- Создаю представление, так как локальное соединение 
select distinct a.city departure_city, a2.city arrival_city  -- показать уникальные значения город отправления, город прибытия
from flights f -- из таблицы рейсы
join airports a on f.departure_airport = a.airport_code -- присоединяю из таблицы аэропорт код аэропорта приравниваю к городу отправления
join airports a2 on f.arrival_airport = a2.airport_code; -- присоединяю из таблицы аэропорт код аэропорта и приравнваю к городу прибытия
select distinct  a.city departure_city, a2.city arrival_city -- показать уникальное значение город отправления, город прибытия
from airports a, airports a2 -- из таблицы аэропорты 
where a.city <> a2.city -- фильтрую чтобы города были не ровны между собой оператором <>
except -- с помощью этого операторы получаю то, что требовалось в задании, использую возвращаемые запросы из первого запросы, которые не возвращаются вторым
select * from not_cross -- из представления 


--ЗАДАНИЕ №9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы 
В решении обязательно должно быть использован - Оператор RADIANS или использование sind/cosd
- CASE 








select distinct ad.airport_name as "Город отправления",aa.airport_name as "Город прибытия",a."range" "Дальность", -- Вывожу Уникальные названия городов отправления и прибытия, добавляю дальность 
round((acos(sind(ad.latitude) * sind(aa.latitude) + cosd(ad.latitude) * cosd(aa.latitude) * cosd(ad.longitude - aa.longitude)) * 6371)::dec, 2) "Рассотояние между аэропортами",	-- Вычисляю расстояние между аэропортами по формуле в прикрепленных материалах	
case when -- добавляю условнное выражение, чтобы проверить долетит ли до места прибытия с установленной максимальной дальностью
a."range" < -- устанавливаю диапозон 
radians (acos(sind(ad.latitude) * sind(aa.latitude) + cosd(ad.latitude) * cosd(aa.latitude) * cosd(ad.longitude - aa.longitude)) * 6371) -- вычисляю условия долетит ди до точки при максимальной дальности по формуле в прикрепленных материалах
then 'Нет' -- Если условие не выполнилось показать нет
else 'Да' -- если условия выполнилось тогда показать да
end "Долетит до аэропотрта с установленной максимальной дальностью?" -- Вывожу столбец
from flights f -- из таблицы рейсы
join airports ad on f.departure_airport = ad.airport_code -- Условное соединения аэропорт отправления с кодом аэропорта
join airports aa on f.arrival_airport = aa.airport_code -- Условное соединение аэропорт прибытия с кодом аэропорта
join aircrafts a on a.aircraft_code = f.aircraft_code  -- Условное соединение кодов аэропортов  