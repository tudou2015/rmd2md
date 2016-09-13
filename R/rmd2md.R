#' This R script will process all R markdown files (those with in_ext file extention,
#' .rmd by default) in the current working directory. Files with a status of
#' 'processed' will be converted to markdown (with out_ext file extention, '.markdown'
#' by default). It will change the published parameter to 'true' and change the
#' status parameter to 'publish'.
#'
#' @param path_site path to the local root storing the site files
#' @param dir_rmd directory containing R Markdown files (inputs)
#' @param dir_md directory containing markdown files (outputs)
#' @param url_images where to store/get images created from plots directory +"/" (relative to path_site)
#' @param out_ext the file extention to use for processed files.
#' @param in_ext the file extention of input files to process.
#' @param recursive should rmd files in subdirectories be processed.
#' @return nothing.
#' @author Jason Bryer <jason@bryer.org> edited by Andy South and Matthew Upson <matthew.a.upson@gmail.com>
#' @export

rmd2md <- function(
  path_site = getwd(),
  dir_rmd = "_rmd",
  dir_md = "_posts",
  #dir_images = "figures",
  url_images = "figures/",
  out_ext = '.md',
  in_ext = '.Rmd',
  recursive = FALSE
) {

  # Expand the dirs

  tryCatch({

    dir_rmd <- file.path(path_site, dir_rmd)
    dir_md <- file.path(path_site, dir_md)

    # This is a horrible hack, but knitr will not seem to find this object if it
    # is not: <<-. See
    # http://stackoverflow.com/questions/8218196/object-not-found-error-when-passing-model-formula-to-another-function

    url_images <<- file.path(path_site, url_images)

    # Check that the dirs exist

    if (!file.exists(dir_rmd)) {

      stop('Input directory: ', dir_rmd ,' does not exist!')

    }

    if (!file.exists(dir_md)) {

      stop('Output directory: ', dir_md ,' does not exist!')

    }

    if (!file.exists(url_images)) {

      stop('Figures directory: ', url_images ,' does not exist!')

    }

    # List files to be converted

    files <- list.files(
      path = dir_rmd,
      pattern = in_ext,
      ignore.case = TRUE,
      recursive = recursive
    )

    # Check that there are files in the files directory

    if (length(files)==0) {

      stop('No files in specified input directory!')

    } else {

      message(length(files), ' files found in input folder.')
      message('Checking each file and processing if status: process')
      message()

    }

    # Loop through files and convert

    for(f in files) {

      # Read content from each of the files in turn

      content <- readLines(
        file.path(dir_rmd, f)
      )

      if (parse_status(content) == 'process') {

        # This is a bit of a hack but if a line has zero length (i.e. a
        # black line), it will be removed in the resulting markdown file.
        # This will ensure that all line returns are retained.

        message(paste0('Processing ', f))

        content[nchar(content) == 0] <- ' '
        content <- change_status(content)
        content <- change_published(content)

        # This is a horrible hack, but knitr will not seem to find this object
        # if it is not: <<-

        outFile <<- file.path(
          dir_md, paste0(substr(f, 1, (nchar(f)-(nchar(in_ext)))), out_ext)
        )

        message()
        message("Writing file to:", outFile)
        message()

        # andy change to render for jekyll

        knitr::render_jekyll(highlight = "pygments")

        # render_jekyll(highlight = "prettify") #for javascript

        knitr::opts_knit$set(out.format = 'markdown')

        # andy BEWARE don't set base.dir!! it caused me problems
        # "base.dir is never used when composing the URL of the figures; it is
        # only used to save the figures to a different directory.
        # The URL of an image is always base.url + fig.path"
        # https://groups.google.com/forum/#!topic/knitr/18aXpOmsumQ

        knitr::opts_knit$set(base.url = "/")
        knitr::opts_chunk$set(fig.path = url_images)

        knitr::knit(
          text = content,
          output = outFile
        )

        figs = list.files(
          path = url_images,
          pattern = '*.jpg',
          full.names = TRUE
        )

        os <- Sys.info()['sysname']

        for (f in figs) {

          remove_exifs(os = os, fig = f)

        }

      } else {

        message("Ignoring ", f)

      }

      # Finally remove exifs from jpgs

    }


  },
  warning = function(w) {

    warning('Warning produced running rmd2md():', w)

  },
  error = function(e)  {

    stop('Error produced running rmd2md():', e)

  },
  finally = {}
  )
}


# Last thing is to remove exif tags from jpgs in figures folder
# Requires linux tool exiv2. Check system is linux first...


