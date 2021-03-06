create_environment <- function(packages, sources,
                               env=new.env(parent=.GlobalEnv)) {
  load_packages(packages)
  for (file in sources) {
    do_source(file, env, chdir=TRUE, keep.source=FALSE)
  }
  env
}

## An alternative here is to trace some of the connection code, but
## that might be harder.  The issue here is that we're going to be
## missing things like csv files, configuration files, etc, that might
## determine the state of the system.  I don't think that there's much
## we can do about that though.  For cases where we're running locally
## it'll be fine.
create_environment2 <- function(packages, sources, env, global) {
  load_packages(packages)
  source_files <- character(0)
  for (file in sources) {
    source_files <- c(
      source_files,
      do_source(file, env, chdir=TRUE, keep.source=FALSE,
                source_fun=sys_source))
    if (global) {
      do_source(file, .GlobalEnv, chdir=TRUE, keep.source=FALSE,
                source_fun=sys_source)
    }
  }
  source_files
}

load_packages <- function(packages) {
  for (p in packages) {
    library(p, character.only=TRUE, quietly=TRUE)
  }
}

do_source <- function(file, ..., source_fun=sys.source) {
  catch_source <- function(e) {
    stop(sprintf("while sourcing %s:\n%s", file, e$message),
         call.=FALSE)
  }
  tryCatch(source_fun(file, ...), error=catch_source)
}

envirs_list <- function(con, keys) {
  as.character(con$HKEYS(keys$envirs_contents))
}

envirs_contents <- function(con, keys, envir_ids=NULL) {
  dat <- from_redis_hash(con, keys$envirs_contents, envir_ids)
  nok <- vlapply(dat, is.na)
  if (any(nok)) {
    stop(sprintf("Environment %s not found",
                 paste(sprintf("'%s'", envir_ids[nok]), collapse=", ")))
  }
  lapply(dat, string_to_object)
}
