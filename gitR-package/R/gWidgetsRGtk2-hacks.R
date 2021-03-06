##' Get expanded rows
##'
##' Returns the paths of the rows currently expanded.
##' @param obj gTreeRGtk object
##' @return vector of paths of expanded rows
getExpandedRows <- function(obj) {
  tag(obj, "expandedRows") <- NULL
  obj@widget$MapExpandedRows(function(obj, path, action) {
    obj <- action$actualobj
    parent.iter <- tag(obj, "store")$GetIter(path)
    iter <- parent.iter$iter
    #print(tag(obj, "store")$GetStringFromIter(iter))
    ## build file key
    repoPath <- ""
    while (parent.iter$retval) {
      repoPath <- paste(tag(obj, "store")$GetValue(parent.iter$iter,
                                                   tag(obj, "iconFudge"))$value,
                        repoPath, sep="/")
      parent.iter <- tag(obj, "store")$IterParent(parent.iter$iter)
    }
    tag(obj, "expandedRows") <- c(tag(obj, "expandedRows"), sub("/$", "", repoPath))
  }, list(actualobj=obj))
  return(tag(obj, "expandedRows"))
}

##' Expand Rows
##'
##' Restore the saved expansion state.
##' @param obj gTreeRGtk object
##' @param iter iter thingy
##' @param expandedRows vector of paths to expand
##' @param root used in recursive calling of the function
expandRows <- function(obj, iter, expandedRows, root=NULL) {
  while(gtkEventsPending()) gtkMainIteration()
  continue <- TRUE
  while(continue) {
    path <- tag(obj, "store")$GetValue(iter, tag(obj, "iconFudge"))$value
    if (!is.null(root)) path <- paste(root, path, sep="/")
    if (path %in% expandedRows) {
      #cat("expand row", path, "\n")
      obj@widget$ExpandRow(tag(obj, "store")$GetPath(iter), FALSE)
      lexpandedRows <- grep(sprintf("^%s/", path), expandedRows, value=TRUE)
      if (length(lexpandedRows) > 0) {
        child.iter = tag(obj, "store")$IterChildren(iter)
        if (child.iter$retval) {
          expandRows(obj, child.iter$iter, lexpandedRows, path)
        }
      }
    }
    continue <- tag(obj, "store")$IterNext(iter)
  }
}

getOffSpringIcons <- gWidgetsRGtk2:::getOffSpringIcons
addChildren <- gWidgetsRGtk2:::addChildren
##' Update gtree
##'
##' Updates the gtree (replaces function in gtreeRGtk).
##' It does the same, but also takes care of the expanded rows
##' and updates the values displayed in the other columns.
##' @param object gTreeRGtk object
##' @param toolkit guiWidgetsToolkitRGtk2
##' @param ... (unused)
setMethod(".update",
          signature(toolkit="guiWidgetsToolkitRGtk2",object="gTreeRGtk"),
          function(object, toolkit, user.data, ...) {
            obj <- object
            ## first get a list of expanded rows
            expandedRows <- getExpandedRows(obj)
            #print(expandedRows)
            ## collapse all rows (is this needed?)
            obj@widget$CollapseAll()
            ## remove all rows
            tag(obj, "store")$Clear()
            while(gtkEventsPending()) gtkMainIteration()
            ## put in children again
            children <- tag(obj, "offspring")(c(), user.data)
            lst <- getOffSpringIcons(children, tag(obj, "hasOffspring"),
                                     tag(obj, "icon.FUN"))
            children <- lst$children
            doExpand <- lst$doExpand
            addChildren(tag(obj, "store"), children, doExpand,
                        tag(obj, "iconFudge"), parent.iter=NULL)
            ## restore expanded rows
            iter <- tag(obj, "store")$GetIterFirst()
            if (length(expandedRows) > 0 && iter$retval)
              expandRows(obj, iter$iter, expandedRows)
          })
