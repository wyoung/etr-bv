#!/usr/bin/env Rscript
########################################################################
# etr-bv.R - An ffprobe-based video bitrate viewer, using R graphics.
#
# Created 2012.09.12 by Warren Young of ETR.
#
# Copyright © 2012-2020 by ETR..., Inc. All rights reserved.
#
# This program is licensed under the terms of the MIT license, which
# should have accompanied this program in the file LICENSE.  If not,
# you can download it from https://github.com/wyoung/etr-bv
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
cat('Checking DV file', dvFile, 'streams...\n')
streams <- system2('ffprobe', args = c('-show_streams', shQuote(dvFile)),
    stdout = TRUE, stderr = NULL)
if (is.integer(attr(streams, 'status'))) stop('FR ffprobe failed')
rfr <- grep('^r_frame_rate=[1-9]+[0-9]*/[1-9]+[0-9]*$', streams,
            value = TRUE)
if (length(rfr) != 1) stop(paste('Bogus avg frame rate:', rfr))
fps = eval(parse(text = strsplit(rfr[1], '=')[[1]][2]))
if (fps < 5 || fps > 60) stop(paste('Bogus FPS:', fps))
cat('Stream FPS:', fps, '\n')

# Ask ffprobe to gather the requested DV file's frame stats
cat('Analyzing DV file', paste0(dvFile, '...'))
t <- system.time(rawStatsText <- system2('ffprobe',
    args = c('-show_frames', '-print_format', 'json', shQuote(dvFile)),
    stdout = TRUE, stderr = NULL))
if (is.integer(attr(rawStatsText, 'status'))) stop('FS ffprobe failed')
#writeLines(rawStatsText, con = paste0(dvFile, '.json'))
cat(t[3], 'seconds.\n')

# Convert the JSON output from ffprobe to a list of R structures
cat('Transforming raw file stats, stage 1...')
t <- system.time(rawStats <- fromJSON(
    paste0(rawStatsText, collapse = ''))$frames)
cat(t[3], 'seconds.\n')

# Convert that raw data structure to a data frame
cat('Transforming raw file stats, stage 2...')
t <- system.time(rawFrame <- lapply(rawStats, as.data.frame))
cat(t[3], 'seconds.\n')

# Fill in missing values within that data frame, since it is effectively
# merging multiple different object types.
cat('Transforming raw file stats, stage 3...')
t <- system.time(statFrame <- do.call("rbind.fill", rawFrame))
cat(t[3], 'seconds.\n')

# Clean up the R data frame.  The rbind.fill trick mooshes together the
# audio, video and possibly other frame type data returned by ffprobe.
# At minimum, we need to filter out all but video frames.  We could
# also drop columns we don't use, but the code below doesn't care.
cat('Transforming raw file stats, stage 4...')
t <- system.time(statFrame <- subset(statFrame, media_type == 'video'))
cat(t[3], 'seconds.\n')

# DEBUG: Create "IPBBPBB..." ordered frame for interactive examination.
#browsableFrame <- statFrame[order(statFrame$cpn),]

# Get a list of position-in-file values at the end of each window, then
# convert them to a list of relative distances.  This yields bytes/window.  
#
# The pktPositions conversion is necessary because the rbind.fill trick
# above gives us a table of factors, not a table of numbers.  For info on
# the conversion, see: http://stackoverflow.com/questions/3418128
windowSize <- 2.0       # seconds per window
cat('Distilling bit rate vector...\n')
frames <- nrow(statFrame)
pktPositions <- as.numeric(statFrame$pkt_pos)
windowPositions <- pktPositions[
  ceiling(seq(from = 0, to = frames, by = fps * windowSize))
]
bpw <- windowPositions
for (i in length(bpw):2) bpw[i] = bpw[i] - bpw[i - 1]

# Assemble summary statistics
MbitsPerSec <- function(bytesPerWin)
    bytesPerWin * 8 / 1024 / 1024 / windowSize
MbitsPerSecStr <- function(bytesPerWin)
  format(MbitsPerSec(bytesPerWin), digits = 3)
peakMbps <- MbitsPerSec(max(bpw))
stats <- paste('min =', MbitsPerSecStr(min(bpw)), 'Mbit/sec, ',
               'max =', MbitsPerSecStr(max(bpw)), 'Mbit/sec, ',
               'mean =', MbitsPerSecStr(mean(bpw)), 'Mbit/sec, ',
               'stddev =', MbitsPerSecStr(sd(bpw)), 'Mbit/sec')

# Build bit rate graph.  Use a nice bar chart if the input file is
# short enough that you can see the bars.  Fall back to a stairstep
# plot if there would be enough bars to overcrowd a bar chart.
cat('Graphing stats for', frames, 'video frames...\n')
title <- paste('Bit rate for', basename(dvFile), '\n', stats)
points <- length(bpw)
barNames <- 1:points * windowSize
mbps     <- MbitsPerSec(bpw)
chartFrame <- data.frame(brWindows = barNames, winHeights = mbps)
if (!interactive()) {
  X11()
  plot.new()
}
if (points > 100) {
  # Include 0 and next 5 Mbit/s val above peak, but go to 20 Mbit/s at least
  ymax <- ceiling(max(19, peakMbps) / 5) * 5
  p <- ggplot(chartFrame, aes(brWindows, winHeights)) +
    ggtitle(title) +
    geom_step(size = 1) +
    scale_x_continuous(name = 'Time (seconds)') +
    scale_y_continuous(name = 'Mbit/sec', limits = c(0, ymax))
  print(p)
} else {
  barplot(mbps,
          names.arg = barNames,
          xlab = 'seconds',
          ylab = 'Mbits/sec',
          ylim = c(0, floor(peakMbps * 1.1)),
          main = title,
          sub = stats)
}

# Wait for a click on the graph if we're being run as a script
if (!interactive()) locator(1)