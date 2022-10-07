## code to prepare `DATASET` dataset goes here


#load("shape_courseulles.rda")

shape_courseulles <- contour_courseulles

usethis::use_data(shape_courseulles, overwrite = TRUE)
usethis::use_r("shape_courseulles")
