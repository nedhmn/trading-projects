# ---------------------------------------------------------------------------- #
# File: .Rprofile
# Description: Startup script
# ---------------------------------------------------------------------------- #

# project-level cache directory
if (Sys.getenv("RENV_PATHS_CACHE") == "") {
    Sys.setenv(RENV_PATHS_CACHE = ".cache")
}

# renv activation script
if (file.exists("renv/activate.R")) {
    source("renv/activate.R")
}
