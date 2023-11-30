/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- DEATHS

SELECT *
FROM portfolio_project.coviddeaths_2
ORDER BY 3,4

-- Starting data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project.coviddeaths_2
ORDER BY 1,2	

-- Looking at Total Cases vs Total Deaths 
-- Shows the likelihood of dying if you contract covid in various countries

SELECT location, date, total_cases, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolio_project.coviddeaths_2
ORDER BY 1,2

-- Looking at total cases vs population 
-- What percent of the population got covid?

SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
FROM portfolio_project.coviddeaths_2
ORDER BY 1,2

-- Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM portfolio_project.coviddeaths_2
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Showing countries with highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM portfolio_project.coviddeaths_2
GROUP BY location
ORDER BY total_death_count DESC


-- BREAKDOWN BY CONTINENT

-- Showing continents with highest death counts

SELECT continent, MAX(total_deaths) AS total_death_count
FROM portfolio_project.coviddeaths_2
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM portfolio_project.coviddeaths_2
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total death percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths)  AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM portfolio_project.coviddeaths_2
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- VACCINATIONS

SELECT *
FROM portfolio_project.covidvaccinations
ORDER BY 3,4

-- Total population vs vaccinations
-- Shows Percentage of Population that has recieved at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations)
FROM portfolio_project.coviddeaths_2 AS dea
JOIN portfolio_project.covidvaccinations AS vac

-- Using CTE to perform calculation on PARTITION BY in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM portfolio_project.coviddeaths_2 AS dea
JOIN portfolio_project.covidvaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac

-- Using Temp Table to perform calculation on PARTITION BY in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM portfolio_project.coviddeaths_2 AS dea
JOIN portfolio_project.covidvaccinations AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
-- WHERE dea.continent IS NOT NULL 
-- ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
