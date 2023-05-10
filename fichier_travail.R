rm(list=ls())

data("shape_courseulles")

library(stars)
library(dplyr)
library(units)
library(sf)
library(sismow)
library(purrr)
library(ggplot2)
library(Distance)



load(here::here("data","depth_courseulles.rda"))

# First, create a map with a gradient density from the North
map <- simulate_density(shape_obj = shape_courseulles,
                        grid_size = 2000,
                        density_type = "uniform")


map_profondeur <- map_dbl(.x = c(1:nrow(map)),
                          ~
                            st_intersection(depth_courseulles, map$geometry[.x]) %>%
                            summarize(depth = mean(depth, na.rm = TRUE)) %>%
                            st_drop_geometry() %>%
                            pull(depth)
)

map <- map %>%
  mutate(depth = map_profondeur) %>%
  mutate(density =  0.02 *depth^2 - 0.2 * depth + 1)


# Plot density function of depth
ggplot(map, aes(x=depth, y=density)) +
  geom_point(color = "#EE6C4D")

# Plot on map
ggplot() +
  geom_sf(data = map, aes(fill = depth)) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "#EDEDE9"))


ind <- simulate_ind(map_obj = map, N = 300)

# Plot
ggplot() +
  geom_sf(data = map, aes(fill = density)) +
  geom_point(data = ind, aes(x = x, y = y)) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "#EDEDE9"))


transects <- simulate_transects(shape_obj = map,
                                design = "systematic",
                                line_length = 400000,
                                design_angle = 2,
                                segmentize = TRUE,
                                seg_length = 2000)



pal <- rep(c("#98C1D9","#EE6C4D","#293241"),nrow(transects))
ggplot() +
  geom_sf(data = map, color = "#D9D9D9") +
  geom_sf(data = transects, aes(colour = seg_ID))+
  scale_colour_manual(values = pal) +
  theme(legend.position = "none",
        panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "#EDEDE9"))


obs <- simulate_obs(ind_obj = ind,
                    transect_obj = transects,
                    key = "hn",
                    g_zero = 1,
                    esw = 150)

# Plot detection probability
ggplot(obs, aes(x=distance, y=proba)) +
  geom_point(color = "#EE6C4D") +
  xlim(0,500)

# Plot on map
ggplot() +
  geom_sf(data = map, fill = "#CDDAFD", color = "#CDDAFD") +
  geom_sf(data = transects, color = "black") +
  geom_point(data=obs[obs$detected==0,], aes(x=x, y=y), shape=20, color="#051923") +
  geom_point(data=obs[obs$detected==1,], aes(x=x, y=y), shape=21, fill="#EE6C4D") +
  labs(caption = paste("Sightings = ", sum(obs$detected), sep = " ")) +
  theme(legend.position = "none",
        panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "#EDEDE9"))


out <- calculate_dsm(obs_obj = obs,
              seg_obj = transects,
              map_obj = map,
              key = 'hn',
              covar = "depth",
              formula = count ~ s(depth))


plot(out$model)
summary(out$model)

ggplot() +
  geom_sf(data = out$map_pred, aes(fill = density_pred)) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "#EDEDE9"))


out$se
out$est_mean
out$ci_2.5
out$ci_97.5
