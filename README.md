Introduction
~~~~~~~~~~~~
    I created the ETR Bitrate Viewer because all the free ones I could
    find were for Windows only, and closed source besides.  We used
    a few happily for years, but there came a time that I needed to
    know what was going on inside the bitrate viewer at a deep level.
    Rather than write a direct clone of one of these, we built what
    we actually needed instead, which was a short script leveraging
    existing powerful tools.

    The ETR Bitrate Viewer (etr-bv from now on) is an R script that
    sits in between the ffmpeg project's ffprobe tool, which gathers
    the raw video frame statistics the tool uses, and the powerful
    R graphics system.  If you run it inside a powerful R GUI like
    RStudio (rstudio.org) you get the ability to inspect all the raw
    and processed data that goes into the bitrate graph.  etr-bv is
    designed to run in a standalone mode, via Rscript, but we really
    recommend running it inside Rstudio instead because of the extra
    power it gives you.

    Beware, etr-bv is slow.  ffprobe spams the script with much more
    detailed statistics than it actually requires, and it has to plow
    through all that noise to assemble the results you want.  On top
    of that, the script is written in R, a slow interpreted language.

    The compensation for this is that etr-bv is highly flexible,
    discoverable, and manipulable.  If ffprobe returns the data you
    need and you can summon the R-fu to use that data, you can mold
    etr-bv to your needs of the moment.  It's only about 100 lines
    of well-commented code, and R is a fairly readable language.


Requirements
~~~~~~~~~~~~
    - R, from http://r-project.org/  We used R 2.15.1 in development,
      but it probably runs in much older versions.  We're not using
      any advanced R features.

    - The non-core R packages ggplot2, plyr, and rjson.  It's easiest
      to install these via RStudio.  If you're using stock R instead,
      type something like

        install.packages('rjson')

       Install each in turn.  There is no interdependency, so you
       can install them in any order.

    - ffprobe from the ffmpeg project, http://ffmpeg.org/  We're not
      going to tell you how to download and build this here.
      It's complex.  You might want to check your operating system's
      package repository: someone else might have done the work to
      build ready-to-use packages for you.

    We also recommend RStudio, from http://rstudio.org/  This is a much
    better R GUI than the one that comes with R, and it is still free.
    It doesn't include R itself; you still need to download that.


How To Use It via RStudio
~~~~~~~~~~~~~~~~~~~~~~~~~
    Open etr-bv.R inside RStudio, then say Ctrl-Shift-S to "source"
    the script.  It will pop up a "file open" dialog.  Point it at
    any digital video file that your ffmpeg build can understand,
    then wait for it to work.

    If you need to make etr-bv.R do something different, run it on
    the file you want to analyze, then start poking around in the
    Workspace window.  There you'll find all the data frames and
    variables the previous run created, which will help you figure
    out how to modify the script.

    In fact, sometimes you don't need to modify the script.  You can
    do ad hoc data exploration by typing R commands into the Console
    window, munching on this same data.  This is the beauty of RStudio:
    it makes incremental solution exploration easy.


How to Use It via the Command Line
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    R should be in your PATH, particularly the Rscript executable.
    With etr-bv.R in your path as well, on a Unix system you can run
    it like this:

        $ etr-bv.R some-dv-file.mov

    On Windows, you can get the same behavior via Cygwin, though it
    requires running with the X server enabled.
    
    If you want to run it on Windows from the command line without
    Cygwin, you probably have to say something like this:

        v:\> Rscript \path\to\etr-bv.R \path\to\some-dv-file.mov

    I'm not sure how well that will work.  I use the RStudio method
    almost all the time myself, so it's quite possible I've broken
    this since the last time I tested it. :)


Support
~~~~~~~
    Join the etr-bv-users Google Group via http://groups.google.com/

    The project's creator monitors that list, and responds to most
    everything that appears there.

    Patches to change the program are also welcome there.  We don't
    promise to accept every patch, but we're happy to discuss ideas.
