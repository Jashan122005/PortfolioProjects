Select *
From CovidPortfolio..CovidMaut
where continent <> null
order by 3,4

Select *
From CovidPortfolio..CovidVaccine
order by 3,4

--Select data that we are going to use

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidPortfolio..CovidMaut
where continent <> null
order by 1,2

--Looking at total cases vs total deaths
--shows the likelihood if you contract covid in country
Select Location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)* 100 AS DeathRate
From CovidPortfolio..CovidMaut
where location like '%india%'
and continent <> null
order by 1,2

--Looking at total cases vs population
--Shows what percentage of population got covid
Select Location, date, population, total_cases, CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0) * 100 AS DeathPercentage
From CovidPortfolio..CovidMaut
where location like '%india%'
and continent <> null
order by 1,2

--Looking at countries with highest infection rate compared to population
Select Location, population, MAX(total_cases) as HIghestInfecetionCount, MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS PercentagePopulationInfected
From CovidPortfolio..CovidMaut
--where location like '%india%'
where continent <> null
Group by Location, population
order by PercentagePopulationInfected desc

--Showing Countries with Highest Death Count per Population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolio..CovidMaut
--where location like '%india%'
where continent <> ''
Group by Location
order by TotalDeathCount desc

--Lets break things by continent 

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolio..CovidMaut
where continent <> ''
Group by continent
order by TotalDeathCount desc

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolio..CovidMaut
where continent = ''
Group by location
order by TotalDeathCount desc

--Showing ontinents with highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolio..CovidMaut
where continent <> ''
Group by continent
order by TotalDeathCount desc

--Global Numbers

SELECT date, SUM(CAST(new_cases AS FLOAT)) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM CovidPortfolio..CovidMaut
-- WHERE location LIKE '%india%' 
WHERE continent <> ''
GROUP BY date
ORDER BY 1,2 

SELECT SUM(CAST(new_cases AS FLOAT)) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM CovidPortfolio..CovidMaut
-- WHERE location LIKE '%india%' 
WHERE continent <> ''
--GROUP BY date
ORDER BY 1,2 

--Looking at total population vs vaccination
--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT dea.continent, dea.location, 
        dea.date, CAST(dea.population AS FLOAT) AS Population, 
        vac.new_vaccinations, SUM(CONVERT(FLOAT, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidPortfolio..CovidMaut dea
    JOIN CovidPortfolio..CovidVaccine vac
    ON  dea.location = vac.location 
	AND dea.date = vac.date
    WHERE dea.continent <> ''
)
SELECT *, 
CASE 
           WHEN Population IS NULL OR Population = 0 THEN NULL
           ELSE (RollingPeopleVaccinated / Population) * 100 
       END AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;


-- TEMP TABLE 

IF OBJECT_ID('tempdb..#PercentagePopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentagePopulationVaccinated;

Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, TRY_CONVERT(DATETIME, dea.date) AS Date
, TRY_CONVERT(FLOAT, dea.population) AS Population, 
    TRY_CONVERT(FLOAT, vac.new_vaccinations) AS new_vaccinations, SUM(TRY_CONVERT(FLOAT, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidPortfolio..CovidMaut dea
    JOIN CovidPortfolio..CovidVaccine vac
    ON  dea.location = vac.location 
	AND dea.date = vac.date
    --WHERE dea.continent <> '' 
    WHERE TRY_CONVERT(FLOAT, dea.population) IS NOT NULL
    AND TRY_CONVERT(FLOAT, vac.new_vaccinations) IS NOT NULL;

SELECT *, 
CASE 
           WHEN Population IS NULL OR Population = 0 THEN NULL
           ELSE (RollingPeopleVaccinated / Population) * 100 
       END AS VaccinationPercentage
FROM #PercentagePopulationVaccinated
DROP TABLE #PercentagePopulationVaccinated;

--Creating view to store data for later visualizations

USE CovidPortfolio; -- Switch to the intended database
GO
Create view PercentagePopulationVaccinated as
SELECT dea.continent, dea.location, TRY_CONVERT(DATETIME, dea.date) AS Date
, TRY_CONVERT(FLOAT, dea.population) AS Population, 
    TRY_CONVERT(FLOAT, vac.new_vaccinations) AS new_vaccinations, SUM(TRY_CONVERT(FLOAT, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidPortfolio..CovidMaut dea
    JOIN CovidPortfolio..CovidVaccine vac
    ON  dea.location = vac.location 
	AND dea.date = vac.date
    WHERE dea.continent <> '' 
    AND TRY_CONVERT(FLOAT, dea.population) IS NOT NULL
    AND TRY_CONVERT(FLOAT, vac.new_vaccinations) IS NOT NULL;
	--order by 2,3

	Select *
	From PercentagePopulationVaccinated


