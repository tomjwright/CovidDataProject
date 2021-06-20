select * 
From [CovidDataPortfolio ]..CovidDeaths
order by 3,4

--You could add continents to the queries below to perform more drill down effects for visualisation. 
--E.g. North America breaks down into Canana and USA


--Select data for use
Select location, date, total_cases, new_cases, total_deaths, population
from [CovidDataPortfolio ]..CovidDeaths
order by 1,2

--Total cases vs total deaths, if null give value of zero
--Shows percentage of death if contracting COVID in your country
Select location, population, date, new_cases, ISNULL((total_deaths/total_cases) * 100, 0) as DeathPercentage
from [CovidDataPortfolio ]..CovidDeaths
where location like '%Kingdom%' and continent is not null 
order by 1,2

--Total cases vs population
--Shows population have had covid
Select location, date, population, total_cases, (total_cases/population) * 100 as PopulationInfected
from [CovidDataPortfolio ]..CovidDeaths
where location like '%Kingdom%'
order by 1,2

--Highest infection rate per population
Select location, population, ISNULL(MAX(total_cases), 0) AS HighestInfectionRate, ISNULL(MAX((total_cases/population) * 100), 0) as PopulationInfected
from [CovidDataPortfolio ]..CovidDeaths
group by location, population
order by PopulationInfected DESC

--Death rate from covid per population and death percentage per population
--Case data as INT to ensure the correct data is being displayed due to definition issues
Select location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
from [CovidDataPortfolio ]..CovidDeaths
group by location
order by TotalDeathCount DESC

--Break data down by continent with most deaths
--select location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
--from [CovidDataPortfolio ]..CovidDeaths
--filters on continents, by filtering null values in cntinents which is all countries as these are clearly not continents
--where continent is null
--group by location
--order by 2 desc

--Break data down by continent with highest death counts
select continent, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
from [CovidDataPortfolio ]..CovidDeaths
where continent is not null
group by continent
order by 2 desc


--GLOBAL NUMBERS
Select date, sum(new_cases), sum(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(new_cases)* 100
from [CovidDataPortfolio ]..CovidDeaths
where continent is not null 
group by date
order by 1,2

select * 
from [CovidDataPortfolio ]..CovidDeaths cd
join [CovidDataPortfolio ]..CovidVaccinations cv
on cd.location = cv.location and cd.date = cv.date

--Total population vaccinated
--Sum new vaccinations (per day) and parition over the location, thus each sum is the sum of total vaccinations per location
select cd.continent, cd.location, cd.population, cd.date, cv.new_vaccinations, 
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as RollingLocationVaccinations
from [CovidDataPortfolio ]..CovidDeaths cd
JOIN [CovidDataPortfolio ]..CovidVaccinations cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
order by 2,3

--Use CTE to enable use of new column in calculation
--Number of columns in the CTE (PopVaccinated) must be the same as the below statement
WITH PopVaccinated (continent, location, population, date, new_vaccinations, RollingLocationVaccinations)
AS
(
Select cd.continent, cd.location, cd.population, cd.date, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as RollingLocationVaccinations
from [CovidDataPortfolio ]..CovidDeaths cd
JOIN [CovidDataPortfolio ]..CovidVaccinations cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
)
Select *, (RollingLocationVaccinations/population) * 100 AS VaccinatedPopulation
from PopVaccinated


--TEMPORARY TABLE
-- If you want to edit the table after exec the query you need to drop the table 
DROP Table if exists #PercentagePopVaccinated
Create table #PercentagePopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
population numeric,
date datetime,
new_vaccinations numeric,
RollingLocationVaccinations numeric
)
-- Copy selected data from CovidDeaths and CovidVacciantions tables and insert it into new table.
Insert into #PercentagePopVaccinated
Select cd.continent, cd.location, cd.population, cd.date, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as RollingLocationVaccinations
from [CovidDataPortfolio ]..CovidDeaths cd
JOIN [CovidDataPortfolio ]..CovidVaccinations cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null

--Select * from new table plus the VaccinatedPopulation
Select *, (RollingLocationVaccinations/population) * 100 AS VaccinatedPopulation
from #PercentagePopVaccinated

--Create views to visualise data later 

DROP View if exists PercentagePopVaccinatedView
GO
Create View PercentagePopVaccinatedView as
Select cd.continent, cd.location, cd.population, cd.date, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as RollingLocationVaccinations
from [CovidDataPortfolio ]..CovidDeaths cd
JOIN [CovidDataPortfolio ]..CovidVaccinations cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null

--Percentage of people with hand washing facilities vs total deaths per country 
Select distinct cv.continent, cv.location, cv.date, cv.handwashing_facilities, cd.total_deaths, cd.new_cases
from CovidVaccinations cv
LEFT JOIN [CovidDataPortfolio ]..CovidDeaths cd
ON cd.location = cv.location and cd.date = cv.date
where cv.handwashing_facilities is not null and cv.continent is not null
ORDER BY 1,2,5 desc

DROP View if exists PercentageHandWashingFacilities
GO
Create View PercentageHandWashingFacilities as 
Select distinct cv.continent, cv.location, cv.date, cv.handwashing_facilities, cd.total_deaths, cd.new_cases
from CovidVaccinations cv
LEFT JOIN [CovidDataPortfolio ]..CovidDeaths cd
ON cd.location = cv.location and cd.date = cv.date
where cv.handwashing_facilities is not null and cv.continent is not null
--ORDER BY 1,2,5 desc