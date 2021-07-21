select * from coviddeaths;
select * from covidvaccinations;

--Select data that we are going to use (till 18-07-2021)
select loc, rec_date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1,2;

--Looking at total_cases vs total_deaths in India
select loc, rec_date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from coviddeaths
where loc = 'India'
order by 1,2;

--Looking at total_cases vs population
--What % of population got covid
select loc, rec_date, population, total_cases, (total_cases/population)*100 as infection_rate
from coviddeaths
where loc = 'India'
order by 1,2;

--Looking at countries with highest infection rate compared to population
select loc, population, max(total_cases) as highest_infection_count, max((total_cases/population)*100) as highest_infection_rate
from coviddeaths
group by loc,population
order by highest_infection_rate desc;

--Countries with highest death count per population
select loc, max(total_deaths) as total_death_count
from coviddeaths
where continent is not NULL --To remove entries where loc is a continent
group by loc
order by total_death_count desc;

--Showing the continents with the highest death count
select continent, max(total_deaths) as total_death_count
from coviddeaths
where continent is not NULL
group by continent
order by total_death_count desc;

--Global Numbers(Total cases, total deaths)
select rec_date,sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as death_percentage
from coviddeaths
where continent is not null
group by rec_date
order by 1,2;

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as death_percentage
from coviddeaths
where continent is not null;

--Total Population vs Vaccination
select dea.continent, dea.loc, dea.rec_date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.loc order by dea.loc, dea.rec_date) as rolling_count_people_vaccinated -- Adds the new_vac of the consecutive rows. Every time we get to a new loc, the sum resets
from coviddeaths as dea
join covidvaccinations as vac
on dea.loc = vac.loc
and dea.rec_date = vac.rec_date
where dea.continent is not NULL --and vac.new_vaccinations is not NULL
order by 2,3;

--Using CTE
With PopvsVac(continent, loc, rec_date, population, new_vaccinations, rolling_count_people_vaccinated)
as
(
select dea.continent, dea.loc, dea.rec_date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.loc order by dea.loc, dea.rec_date) as rolling_count_people_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
on dea.loc = vac.loc
and dea.rec_date = vac.rec_date
where dea.continent is not NULL and vac.new_vaccinations is not NULL 
)
select *, (rolling_count_people_vaccinated/population)*100 as rolling_percent
from PopvsVac

--Temp Table(run each separately)
drop table if exists percent_population_vaccinated

create table percent_population_vaccinated
( continent varchar(30),
  loc varchar(255),
  rec_date date,
  population float,
  new_vaccinations float,
  rolling_count_people_vaccinated float
)

Insert into percent_population_vaccinated
select dea.continent, dea.loc, dea.rec_date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.loc order by dea.loc, dea.rec_date) as rolling_count_people_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
on dea.loc = vac.loc
and dea.rec_date = vac.rec_date
where dea.continent is not NULL and vac.new_vaccinations is not NULL 

select *, (rolling_count_people_vaccinated/population)*100 as rolling_percent
from percent_population_vaccinated

--Creating view to store data
drop table if exists percent_population_vaccinated
create view percent_population_vaccinated as
select dea.continent, dea.loc, dea.rec_date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.loc order by dea.loc, dea.rec_date) as rolling_count_people_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
on dea.loc = vac.loc
and dea.rec_date = vac.rec_date
where dea.continent is not NULL and vac.new_vaccinations is not NULL 

select * from percent_population_vaccinated;
