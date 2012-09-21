#!/bin/env Rscript
########################################################################
# etr-bv.R - An ffprobe-based video bitrate viewer, using R graphics.
#
# Created 2012.09.12 by Warren Young of ETR.
#
# Copyright © 2012 by ETR..., Inc. All rights reserved.
#
# This program is licensed under the terms of the MIT license, which
# should have accompanied this program in the file LICENSE.  If not,
# you can download it from https://code.google.com/p/etr-bv/
########################################################################

require(ggplot2)
require(lattice)
require(plyr)
require(rjson)


# Pick the DV file to examine
dvFile <- NULL
if (length(args) > 0) {
  args <- commandArgs(trailingOnly = TRUE)
  dvFile <- args[1]
}
if (is.null(dvFile) || !file.exists(dvFile)) {
  if (interactive()) 
    dvFile <- file.choose()
  else
    stop("usage: etr-bv.R <dvfile>")
}

# Examine file to determine frame rate
cat('Analyzing DV file', dvFile, '...\n')
streams <- system2('ffprobe', args = c('-show_streams', dvFile),
    stdout = TRUE, stderr = NULL)
if (is.integer(attr(streams, 'status'))) stop('FR ffprobe failed')
rfr <- grep('^r_frame_rate=[1-9]+[0-9]*/[1-9]+[0-9]*$', streams,
            value = TRUE)
if (length(rfr) != 1) stop(paste('Bogus avg frame rate:', rfr))
fps = eval(parse(text = strsplit(rfr[1], '=')[[1]][2]))
if (fps < 5 || fps > 60) stop(paste('Bogus FPS:', fps))
cat('Stream FPS:', fps, '\n')

# Ask ffprobe to gather its frame stats, then convert it to an R data
# frame for convenient manipulation.
rawStatsText <- system2('ffprobe',
    args = c('-show_frames', '-print_format', 'json', dvFile),
    stdout = TRUE, stderr = NULL)
if (is.integer(attr(rawStatsText, 'status'))) stop('FS ffprobe failed')
writeLines(rawStatsText, con = paste0(dvFile, '.json'))
rawStats <- fromJSON(paste0(rawStatsText, collapse = ''))$frames
statFrame <-do.call("rbind.fill", lapply(rawStats, as.data.frame))

# Clean up the R data frame.  The rbind.fill trick mooshes together the
# audio, video and possibly other frame type data returned by ffprobe.
# At minimum, we need to filter out all but video frames.  We could
# also drop columns we don't use, but the code below doesn't care.
statFrame <- subset(statFrame, media_type == 'video')

# DEBUG: Create "IPBBPBB..." ordered frame for interactive examination.
#browsableFrame <- statFrame[order(statFrame$cpn),]

# Get a list of position-in-file values at each second, then convert
# them to a list of relative distances.  This effectively gets us bytes
# per second at 1-second resolution across the file.  The pktPositions
# conversion is necessary because the rbind.fill trick above gives us
# a table of factors, not a table of numbers.  For the conversion from
# factors to numbers, see: http://stackoverflow.com/questions/3418128
frames <- nrow(statFrame)
pktPositions <- as.numeric(levels(statFrame$pkt_pos))[statFrame$pkt_pos]
secondPositions <- pktPositions[
  ceiling(seq(from = 0, to = frames, by = fps))
]
bps <- secondPositions
for (i in length(bps):2) bps[i] = bps[i] - bps[i - 1]

# Build bit rate graph.  Use a nice bar chart if the input file is
# short enough that you can see the bars.  Fall back to a stairstep
# plot if there would be enough bars to overcrowd a bar chart.
cat('Graphing stats for', frames, 'video frames...\n')
MbitsPerSec <- function(bytesPerSec) bytesPerSec * 8 / 1024 / 1024
MbitsPerSecStr <- function(bytesPerSec)
  format(MbitsPerSec(bytesPerSec), digits = 3)
points <- length(bps)
chartFrame <- data.frame(
  seconds = 1:points,
  mbps = MbitsPerSec(bps))
peakMbps = MbitsPerSec(max(bps))
if (!interactive()) X11()
plot.new()
if (points > 100) {
  #plot(chartFrame, type = 's')
  stats <- paste('min =', MbitsPerSecStr(min(bps)), 'Mbit/sec, ',
                 'max =', MbitsPerSecStr(max(bps)), 'Mbit/sec, ',
                 'mean =', MbitsPerSecStr(mean(bps)), 'Mbit/sec, ',
                 'stddev =', MbitsPerSecStr(sd(bps)), 'Mbit/sec')
  ggplot(chartFrame, aes(seconds, mbps)) +
    ggtitle(paste('Bit rate for', basename(dvFile), '\n', stats)) +
    geom_step(size = 1) +
    scale_x_continuous(name = 'Time') +
    scale_y_continuous(name = 'Mbit/sec',
                       # include 0 and next 5 Mbit/s val above peak
                       limits = c(0, ceiling(peakMbps / 5) * 5))
} else {
  barchart(mbps ~ seconds, chartFrame,
           horizontal = FALSE,
           ylab = 'Mbits/sec',
           panel = function(...) {
             panel.grid(v = FALSE)
             panel.barchart(...)
           })
}
if (!interactive()) {
  # wait for click on graph to exit
  locator(1)
  dev.off()
}
