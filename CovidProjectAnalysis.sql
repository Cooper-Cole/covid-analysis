Select *
From CovidProject..CovidDeaths
Where continent is not null

-- Select data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2

-- looking at total cases vs total deaths (%)
-- Shows the liklihood of dying if you contract Covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
Where location = 'United States'
order by 1,2

-- Looking at total cases vs. pop
-- Shows % of people who got covid
Select location, date, total_cases, population, (total_cases/population)*100 as gotCovid
From CovidProject..CovidDeaths
--Where location = 'United States'
order by 1,2

-- what countries had the highest infection rates compared to population
Select location, population, MAX(total_cases) as HighestInfectionCount, population, MAX(total_cases/population)*100 as infectionRate
From CovidProject..CovidDeaths
Group by Location, Population
--Where location = 'United States'
order by infectionRate desc

-- what countries had the highest death count per pop
-- need to cast total_deaths since varchar
Select location, MAX(cast(total_deaths as int)) as TotalDeaths
From CovidProject..CovidDeaths
-- to remove outliers like 'World'
Where continent is not null
Group by location
order by TotalDeaths desc

-- Continent exploration
-- showing continents with higest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeaths
From CovidProject..CovidDeaths
-- to remove outliers like 'World'
Where continent is null
Group by location
order by TotalDeaths desc

-- global #s
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
Where continent is not null
order by DeathPercentage desc

-- combining tables
Select *
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- total pop vs. vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER 
(Partition by dea.location order by dea.location, dea.date) as rollingPeopleVacs
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
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
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Create a view to store data for later viz
CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- views are permanent and can be selected from