Select * 
FROM CovidMetrics..CovidDeaths
where continent is not null  -- If we don't do this then we will be getting the continent name in our location table 
order by 3,4

--Select * 
--FROM CovidMetrics..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using 

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidMetrics..CovidDeaths
where continent is not null 
order by 1,2

-- Looking at Total Cases vs Total Deaths 
-- Shows likelihood of dying if you contract covid in India and Pakistan 
Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidMetrics..CovidDeaths
WHERE Location like '%India%' OR Location like '%Pakistan%'  -- In order to get the values of both the countries we need to use OR statement 
AND continent is not null 
order by 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid in India and Pakistan 
Select Location, date, Population, total_cases, (total_cases / Population)*100 AS CasePercentage
From CovidMetrics..CovidDeaths 
WHERE Location like '%India%' OR Location like '%Pakistan%'  --Like statement is case insensitive 
AND continent is not null
Order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / Population))*100 AS PercentPopulationInfected
FROM CovidMetrics..CovidDeaths 
WHERE continent is not null 
GROUP BY Location,Population 
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with the Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount --since the datatype used in total_deaths is not giving the value you are looking for so we will probably cast it 
FROM CovidMetrics..CovidDeaths 
WHERE continent is not null 
GROUP BY Location 
ORDER BY TotalDeathCount DESC

-- Time to break things down by continent 
Select continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidMetrics..CovidDeaths
WHERE continent is not null
GROUP BY continent  --It looks like it is giving more data from USA and Canada only for North America which is not that accurate 
ORDER BY TotalDeathCount DESC 

-- Following query looks more accurate as compared to the above one 
Select Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidMetrics..CovidDeaths
WHERE continent is null
GROUP BY Location
ORDER BY TotalDeathCount DESC 

--GLOBAL NUMBERS 
Select date, SUM(new_cases) AS TotalNewCases, SUM(cast(new_deaths as int)) AS TotalNewDeaths , SUM(cast(new_deaths as int))/SUM(cast(new_cases as int))*100 as DeathPercentage 
-- we will cast it because Operand data type nvarchar is invalid for sum operator
FROM CovidMetrics..CovidDeaths
WHERE continent is not null --If not then 'Divide by zero error will get encountered'
GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vaccinations in India 
--We will be joining both the tables 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From CovidMetrics..CovidDeaths dea 
Join CovidMetrics..CovidVaccinations vac
    ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null 
AND dea.location like '%India%'
ORDER BY 2,3 

Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/dea.population)*100  --we can't use this just after creating a new column name , we will have to use CTEs
FROM CovidMetrics..CovidDeaths dea 
Join CovidMetrics..CovidVaccinations vac 
    On dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null 
ORDER BY 2,3

--USE CTEs
With PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated -- If the number of column in CTE is different from this then it will throw an error 
--,(RollingPeopleVaccinated/dea.population)*100  --we can't use this just after creating a new column name , we will have to use CTEs
FROM CovidMetrics..CovidDeaths dea 
Join CovidMetrics..CovidVaccinations vac 
    On dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null 
--ORDER BY 2,3
)

Select * , (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidMetrics..CovidDeaths dea
Join CovidMetrics..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidMetrics..CovidDeaths dea
Join CovidMetrics..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select * 
FROM PercentPopulationVaccinated
