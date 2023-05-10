## code to prepare `DATASET` dataset goes here


#load("shape_courseulles.rda")

shape_courseulles <- contour_courseulles

usethis::use_data(shape_courseulles, overwrite = TRUE)
usethis::use_r("shape_courseulles")



# Profondeur
r_stars <- read_stars(here::here("data","gebco_2022_n49.7_s49.2_w-1.32_e0.35.tif")) %>%
  st_as_sf() %>%
  rename(profondeur = "gebco_2022_n49.7_s49.2_w-1.32_e0.35.tif") %>%
  drop_units() %>%
  st_transform(crs=4326) %>%
  st_intersection(shape_courseulles) %>%
  st_transform(crs=2154) %>%
  mutate(profondeur = case_when(
    profondeur >= 0 ~ 'NA',
    TRUE ~ as.character(profondeur))) %>%
  mutate(profondeur = as.numeric(profondeur))


# First, create a map with a gradient density from the North
map <- simulate_density(shape_obj = shape_courseulles,
                        grid_size = 1000,
                        density_type = "uniform")


map_profondeur <- map_dbl(.x = c(1:nrow(map)),
                          ~
                            st_intersection(r_stars, map$geometry[.x]) %>%
                            summarize(profondeur = mean(profondeur, na.rm = TRUE)) %>%
                            st_drop_geometry() %>%
                            pull(profondeur)
)

depth_courseulles <- map %>%
  mutate(depth = map_profondeur) %>%
  select(depth, geometry)

usethis::use_data(depth_courseulles, overwrite = TRUE)
usethis::use_r("depth_courseulles")
