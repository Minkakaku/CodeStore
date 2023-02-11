library(Seurat)
library(ggforce)
library(ggplot2)
library(SeuratDisk)
library(ggpubr)
library(patchwork)


Idents(adult_S) <- adult_S$seurat_clusters
Idents(aged_S) <- aged_S$seurat_clusters
My_levels <- c("1", "2")
Idents(adult_S) <- factor(Idents(adult_S), levels = My_levels)
Idents(aged_S) <- factor(Idents(aged_S), levels = My_levels)
## remove the x-axis text and tick
## plot.margin to adjust the white space between each plot.
## ... pass any arguments to VlnPlot in Seurat
modify_vlnplot <- function(obj,
                           feature,
                           pt.size = 0,
                           plot.margin = unit(c(-0.75, 0, -0.75, 0), "cm"),
                           ...) {
  p <- VlnPlot(obj, features = feature, pt.size = pt.size, ...) +
    xlab("") + ylab(feature) + ggtitle("") +
    theme(
      legend.position = "none",
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.title.y = element_text(size = rel(1), angle = 0),
      axis.text.y = element_text(size = rel(1)),
      plot.margin = plot.margin
    ) #+ rotate_x_text()
  return(p)
}

## extract the max value of the y axis
extract_max <- function(p) {
  ymax <- max(ggplot_build(p)$layout$panel_scales_y[[1]]$range$range)
  return(ceiling(ymax))
}


## main function
StackedVlnPlot <- function(obj, features,
                           pt.size = 0,
                           plot.margin = unit(c(-0.75, 0, -0.75, 0), "cm"),
                           ...) {
  plot_list <- purrr::map(features, function(x) modify_vlnplot(obj = obj, feature = x, ...))

  # Add back x-axis title to bottom plot. patchwork is going to support this?
  # rotate_x_text() 转置横坐标的字体，ggpubr 包，在这里添加才会只出现一次横坐标，不会出现多个横坐标
  plot_list[[length(plot_list)]] <- plot_list[[length(plot_list)]] +
    theme(axis.text.x = element_text(), axis.ticks.x = element_line())

  # change the y-axis tick to only max value
  ymaxs <- purrr::map_dbl(plot_list, extract_max)
  plot_list <- purrr::map2(plot_list, ymaxs, function(x, y) {
    x +
      scale_y_continuous(breaks = c(y)) +
      expand_limits(y = y)
  })

  p <- patchwork::wrap_plots(plotlist = plot_list, ncol = 1)
  return(p)
}

# call function
features <- c("CD4", "VEGFA", "HAVCR2", "CD8A", "CD8B", "GNLY", "GZMA", "GZMB", "GZMH", "FOXP3")

vlnplt1 <- StackedVlnPlot(obj = adult_S, features = features, idents = c(1, 2))
vlnplt2 <- StackedVlnPlot(obj = aged_S, features = features, idents = c(1, 2))
ggsave(filename = "12adult_Svlnplot.tiff", height = 18, width = 5, plot = vlnplt1)
ggsave(filename = "12aged_Svlnplot.tiff", height = 18, width = 5, plot = vlnplt2)
