#Week 2 Demo: "Your Map is Lying to You"

# Calculating Jutland area in 3 different CRS
# Demonstrates how projection choice affects area calculations

# Load packages ----
library(sf)
library(tidyverse)
library(geodata) # for administrative boundaries
library(tmap) # for mapping

# 1. Load Denmark administrative boundaries ----
# Level 1 = regions (includes Jutland regions)
dk_regions <- gadm(country = "DNK", level = 1, path = tempdir()) %>% 
  st_as_sf()

# Check what we have
print(dk_regions)
st_crs(dk_regions)  # Should be WGS84 (EPSG:4326)

# 2. Identify Jutland regions ----
# Jutland consists of: Nordjylland, Midtjylland, Syddanmark
# (Note: Syddanmark includes Fyn, but we'll keep for simplicity)
jutland <- dk_regions %>% 
  filter(NAME_1 %in% c("Nordjylland", "Midtjylland", "Syddanmark")) %>% 
  st_union()  # Combine into single polygon

# Quick plot to verify
plot(st_geometry(jutland), main = "Jutland", col = "lightblue")

# 3. Calculate area in THREE different CRS ----

# CRS 1: WGS84 (EPSG:4326) - Geographic CRS (lat/lon in degrees)
# This is suboptimal for area calculations but let's see what happens
jutland_wgs84 <- jutland  # Already in WGS84
area_wgs84 <- st_area(jutland_wgs84)
print(paste("Area in WGS84 (m²):", area_wgs84))

print(paste("Area in WGS84 (km²):", area_wgs84/10^6))
# Result used to be in square degrees - meaningless! But now Pebezma improved st_area() to work for LatLong data.

# CRS 2: Web Mercator (EPSG:3857) - Popular for web maps
jutland_mercator <- st_transform(jutland, crs = 3857)
area_mercator <- st_area(jutland_mercator)
area_mercator_km2 <- units::set_units(area_mercator, km^2)
print(paste("Area in Web Mercator (km²):", round(area_mercator_km2, 0)))

# CRS 3: UTM Zone 32N (EPSG:25832) - Appropriate for Denmark
jutland_utm <- st_transform(jutland, crs = 25832)
area_utm <- st_area(jutland_utm)
area_utm_km2 <- units::set_units(area_utm, km^2)
print(paste("Area in UTM 32N (km²):", round(area_utm_km2, 0)))

# 4. Compare results ----
results <- tibble(
  CRS = c("WGS84 (4326)", "Web Mercator (3857)", "UTM 32N (25832)"),
  Type = c("Geographic/Projected", "Projected", "Projected"),
  Units = c("m²", "km²", "km²"),
  Area = c(
    as.numeric(area_wgs84),
    as.numeric(area_mercator_km2),
    as.numeric(area_utm_km2)
  ),
  Appropriate = c("OK - but review the units!", "UH,OH - distorts at high latitudes", "YES - local CRS for Denmark")
)

print(results)

# Calculate % difference between Mercator and UTM
pct_diff <- ((area_mercator_km2 - area_utm_km2) / area_utm_km2) * 100
print(paste("Web Mercator overestimates by:", round(pct_diff, 1), "%"))

# 5. Visualize the three projections side-by-side (watch carefully for the shape change) ----

plot(jutland_wgs84) 
plot(jutland_mercator) 
plot(jutland_utm)



# 6. The lesson ----
# For area calculations:
# - ALWAYS use a projected CRS (meters/feet, not degrees)
# - Choose a CRS appropriate for your study area
# - UTM zones are best for regional/national analyses
# - Web Mercator is convenient but distorts area at high latitudes

# Reality check: Jutland is approximately 29,775 km²
# UTM should be closest to this!

# DISCUSSION QUESTIONS:
# 1. Why does WGS84 give such a weird number?
# 2. Why is Web Mercator different from UTM?
# 3. Which CRS would you use for calculating forest cover in Jutland?
# 4. What about mapping global shipping routes?