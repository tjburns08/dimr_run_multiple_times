# Script: running umap multiple times
# Author: Tyler J Burns Phd
# Purpose: to produce a list of UMAP runs that we can work with later, 
# so we don't have to do this over and over

# Seed
set.seed(42)

# Libraries
library(dplyr)
library(tibble)
library(here)
library(umap)
library(HDCytoData)
library(Rtsne)

# Initial conditions
num_cells <- 10000
num_runs <- 100
zscore <- FALSE
dimr_choice <- "tsne" # tsne or umap

# Process data
se <- HDCytoData::Samusik_01_SE()
se <- se[sample(nrow(se), num_cells),]

cells <- se@assays@data$exprs %>% as_tibble()

surface <- colData(se) %>% 
    as_tibble() %>% 
    dplyr::filter(marker_class == "type") %>% 
    .[["marker_name"]]
cells <- cells[surface]

cells <- asinh(cells/5) %>% as_tibble()

# List of embeddings
dimr_list <- lapply(seq(num_runs), function(i) {
    set.seed(i)
    print(paste0("Iteration", " ", i))

    if(dimr_choice == "umap") {
        result <- umap::umap(cells, preserve.seed = TRUE)$layout
        colnames(result) <- c("umap1", "umap2")
    } else if(dimr_choice == "tsne") {
        result <- Rtsne::Rtsne(cells, check_duplicates = FALSE)$Y
        colnames(result) <- c("tsne1", "tsne2")
    }

    if(zscore) {
        result <- apply(result, 2, scale)
    }

    result <- as_tibble(result)
    return(result)
})

# Output
setwd(here::here("output"))

zscore_str <- if(zscore) "zscore" else "nozscore"
outfile <- paste0(dimr_choice,
                  "_runs_", num_runs,
                  "_cells_", num_cells,
                  "_scale_",
                  zscore_str,
                  ".rds")


readr::write_rds(dimr_list, outfile)
