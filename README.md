Introduction
----

[ETR](http://etr-usa.com) created the ETR Bitrate Viewer (`etr-bv`) because we could not find an open source program that did this. Every program we're aware of that produces a bitrate graph from an MPEG TS file is closed source.

The problem that kicked this project off was that we needed to know what was going on inside the bitrate viewer at a deep level. The processed GUI output of these programs was too high-level to solve the problem we were having at the time. We decided we needed to write our own bitrate viewer in order to get access to the raw data before it got reduced to a pretty GUI presentation. If we could make it run on non-Windows platform, that would be a distinct advantage, since ETR is very much a multi-platform company.

Rather than write a direct clone of one of the existing closed-source Windows bitrate viewers, we built what we actually needed: a short script leveraging existing powerful tools.

`etr-bv` is an R script that sits in between [`ffprobe`](http://ffmpeg.org/ffprobe.html) and the powerful R graphics system. While you can run it as a script via `Rscript` and just look at the GUI output, you can also run it inside the R interactive environment — or something more powerful like [RStudio](rstudio.org) — in order to inspect all the raw and processed data that goes into the bitrate graph.


Requirements
----

-   [R](http://r-project.org/)

    We've used various versions of R 2 and 3 in development, starting with 2.15.1, but it probably runs in much older versions.  We're not using any advanced R features.

-   The non-core R packages `ggplot2`, `plyr`, and `rjson`.

    You can install them with this R command:

        install.packages(c("ggplot2", "plyr", "rjson"))
    
    You can also do this via the RStudio GUI, in the Packages panel.
    
-   ffprobe from the [FFmpeg project](http://ffmpeg.org/)

    FFmpeg is open source, but difficult to build by hand.  It is far easier to use a build someone else has provided.  There are some linked from the FFmpeg project page, or you may find a version in your operating system's package repository.


How To Use It via RStudio
----
This is the recommended way to run `etr-bv`, since it lets you inspect the data that goes into the bitrate graph. (If you just want the graph, you should probably be using a different tool.)

First you need to install R and RStudio.

Having done that, open `etr-bv.R` inside RStudio, then say Cmd/Ctrl-Shift-S to "source" the script.  It will pop up a "file open" dialog.  Point it at any digital video file that your `ffprobe` build can understand, then wait for it to work.

If you need to make `etr-bv.R` do something different, run it on the file you want to analyze, then start poking around in the Workspace window.  There you'll find all the data frames and variables the previous run created, which will help you figure out how to modify the script.

In fact, sometimes you don't need to modify the script.  You can do _ad hoc_ data exploration by typing R commands into the Console window, munching on this same data.  This is the beauty of RStudio: it makes incremental solution exploration easy.


How to Use It via the Command Line
----
On a Unix type system, you just need to put `etr-bv.R` in your `PATH`. Then, this works:

    $ etr-bv.R some-dv-file.mov

That broad category includes Cygwin, though you will need to have the optional X server installed and running for this to work. You will also need to do this with the Cygwin version of R installed; it will not work with the native Windows port.

If you want to run it on Windows without Cygwin, I recommend the RStudio option above. Running it from the standard Windows command line (whether `cmd.exe` or PowerShell) is just too painful.


Damn, Son, This Thing Is *Slow!*
----

Yup.

There are two main causes:

1.  `ffprobe` spams `etr-bv` with much more detailed statistics than it actually requires, and it has to plow through all that noise to assemble the results.

2.  The R interpreter is uncommonly slow for such a popular language. 

    (Nevertheless, we do not regret choosing R. The `etr-bv` problem is exactly the sort of thing that R was created to solve, so it fits well with the language's nature.)

The compensating value you get from this choice of tools is power. `etr-bv` is highly flexible, discoverable, and manipulable. If `ffprobe` returns the data you need and you can summon the R-fu to use that data, you can mold `etr-bv` to your needs of the moment.  It's only about 100 lines of well-commented code, and R is a fairly readable language.

Support
----
[File a GitHub issue](https://github.com/wyoung/etr-bv/issues).

Because this GitHub repo is a mirror of a privately-managed [Fossil](https://fossil-scm.org) repo, we do not accept PRs on GitHub directly, but we can turn them into patches that will get mirrored up here.
