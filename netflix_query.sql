CREATE SCHEMA netflix;
CREATE TABLE netflix_table
(
  show_id VARCHAR(6),
  type VARCHAR(10),
  title VARCHAR(150),
  director VARCHAR(208),
  casting VARCHAR(1000),
  country VARCHAR(150),
  date_added VARCHAR(50),
  release_year INT,
  rating VARCHAR(10),
  duration VARCHAR(15),
  listed_in VARCHAR(80),
  description VARCHAR(250)
);

select * from netflix_table;

--1. Count the number of Movies vs TV Shows

select 
type,
count(*) as total_content
from netflix_table
group by type;

--2. Find the most common rating(highest) for movies and TV shows
--order:subquery-group by-agg(count)-window fn -where in outer
select
  type, 
  rating
from(
select 
    type,
    rating,
    count(*) as cnt,
    rank() over(partition by type order by cnt DESC) as ranking
from netflix_table
group by 1,2
) as t1
where 
  ranking = 1;

--3. List all movies released in a specific year (e.g., 2020)

select *
from netflix_table
where type = 'Movie' and release_year = 2020;

--4. Find the top 5 countries with the most content on Netflix

select 
UNNEST(STRING_TO_ARRAY(country,','))as new_country,
count(show_id) as total_content
from netflix_table
group by 1
order by 2 desc
limit 5;

--5. Identify the longest movie

Select * from netflix_table
where type = 'Movie'and duration =(select Max(duration) from netflix_table);

--6. Find content added in the last 5 years
-- convert string to date_added
/*
select *,
TO_DATE(date_added,'MONTH DD,YYYY')
from netflix_table*/

select *
from netflix_table
where 
  TO_DATE(date_added,'MONTH DD,YYYY') >= current_date-INTERVAL '5 YEARS';

/*--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
order of execu :subquery *(must to be given in subquery as to need type in main query) - where - order--*/

select 
type,
director1
from (
  select
  *,
  UNNEST(STRING_TO_ARRAY(director,',')) as director1 
  from netflix_table)
where director1 ='Rajiv Chilaka'
order by type;

select
UNNEST(STRING_TO_ARRAY(director,',')) as director1 ,
type
from netflix_table
where UNNEST(STRING_TO_ARRAY(director,','))  = 'Rajiv Chilaka'
group by 1


--8. List all TV shows with more than 5 seasons

select
type,
concat(duration1,'seasons') as seasons
from
  (
  select *,
  CAST(REGEXP_SUBSTR(duration,'[0-9]+') as INT) as duration1
  from netflix_table
  ) as t1
where type = 'TV Show' and duration1 >= 5
order by duration1

/*
select
*
from netflix_table
where type = 'TV Show'
and
SPLIT_PART(duration,'',1)::numeric > 5
*/

--9. Count the number of content items in each genre
-- group la u can give any fn its not like where clause

select 
count(show_id) as total_count,
UNNEST(STRING_TO_ARRAY(listed_in,',')) as genre
from netflix_table
group by 2


/*10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!
*/

select 

AVG(total_count) as avg_Per_year
from(
    select 
    UNNEST(STRING_TO_ARRAY(country,',')) as INDIA_COUNTRY,
    release_year,
    count(show_id) as total_count
    from netflix_table
    group by 1,2
    order by 3 desc)
 as t1


--11. List all movies that are documentaries
if listed_in had International,documentaries this will be in output

    select *
    from netflix_table
    where type = 'Movie' and listed_in ILIKE '%Documentaries%';


/* select *
from netflix_table
where listed_in ILIKE "%documentaries%" */

--12. Find all content without a director

select *
from netflix_table
where director is NULL;

--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

select 
casting,
count(*) as total
from netflix_table
where casting ILIKE '%Salman Khan%' and release_year >= EXTRACT(year from current_date) - 10
group by casting
order by 2 desc;

select *,
casting
from netflix_table
where casting ILIKE '%Salman Khan%' and release_year > EXTRACT(year from current_date) - 10

--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

select 
    UNNEST(STRING_TO_ARRAY(casting,',')) as actor,
    count(*) as total
from netflix_table
where country ilike '%INDIA%'
group by 1
order by 2 desc
limit 10;


/*15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/
with items as (
  select *,
  case
    when
      description ilike '%kill%'
      or description ilike '%violence%' then 'BAD_CONTENT'
      ELSE 'GOOD_CONTENT'
      end as Category
    from netflix_table)

select 
Category,
count(*) as total
from items 
group by Category
order by 2