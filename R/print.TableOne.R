##' Format and print \code{TableOne} class objects
##'
##' \code{print} method for the \code{TableOne} class objects created by \code{\link{CreateTableOne}} function.
##'
##' @param x Object returned by \code{\link{CreateTableOne}} function.
##' @param catDigits Number of digits to print for proportions. Default 1.
##' @param contDigits Number of digits to print for continuous variables. Default 2.
##' @param pDigits Number of digits to print for p-values (also used for standardized mean differences). Default 3.
##' @param quote Whether to show everything in quotes. The default is FALSE. If TRUE, everything including the row and column names are quoted so that you can copy it to Excel easily.
##' @param missing Whether to show missing data information.
##' @param explain Whether to add explanation to the variable names, i.e., (\%) is added to the variable names when percentage is shown.
##' @param printToggle Whether to print the output. If FALSE, no output is created, and a matrix is invisibly returned.
##' @param test Whether to show p-values. TRUE by default. If FALSE, only the numerical summaries are shown.
##' @param smd Whether to show standardized mean differences. FALSE by default. If there are more than one contrasts, the average of all possible standardized mean differences is shown. For individual contrasts, use \code{summary}.
##' @param noSpaces Whether to remove spaces added for alignment. Use this option if you prefer to align numbers yourself in other software.
##' @param padColnames Whether to pad column names with spaces to center justify. The default is FALSE. It is not conducted if noSpaces = TRUE.
##' @param varLabels Whether to replace variable names with variable labels obtained from \code{labelled::var_label()} function.
##' @param format The default is "fp" frequency (percentage). You can also choose from "f" frequency only, "p" percentage only, and "pf" percentage (frequency).
##' @param showAllLevels Whether to show all levels. FALSE by default, i.e., for 2-level categorical variables, only the higher level is shown to avoid redundant information.
##' @param cramVars A character vector to specify the two-level categorical variables, for which both levels should be shown in one row.
##' @param dropEqual Whether to drop " = second level name" description indicating which level is shown for two-level categorical variables.
##' @param exact A character vector to specify the variables for which the p-values should be those of exact tests. By default all p-values are from large sample approximation tests (chisq.test).
##' @param nonnormal A character vector to specify the variables for which the p-values should be those of nonparametric tests. By default all p-values are from normal assumption-based tests (oneway.test).
##' @param minMax Whether to use [min,max] instead of [p25,p75] for nonnormal variables. The default is FALSE.
##' @param formatOptions A list of options, which will be passed to \code{\link[base]{format}}. Can be used to modify the \code{big.mark}, \code{decimal.mark}, \code{big.interval} etc. The default is \code{list(scientific = FALSE)}. The options digits, nsmall, justify and trim are not available. (Experimental)
##' @param ... For compatibility with generic. Ignored.
##' @return A matrix object containing what you see is also invisibly returned. This can be assinged a name and exported via \code{write.csv}.
##' @author Kazuki Yoshida, Justin Bohn, Alexander Bartel
##' @seealso
##' \code{\link{CreateTableOne}}, \code{\link{CreateTableOne}}, \code{\link{summary.TableOne}}
##' @examples
##'
##' ## See examples for CreateTableOne and svyCreateTableOne
##'
##' @export
print.TableOne <-
function(x,                   # TableOne object
         catDigits = 1, contDigits = 2, pDigits = 3, # Number of digits to show
         quote         = FALSE,       # Whether to show quotes

         ## Common options
         missing       = FALSE, # Not implemented yet
         explain       = TRUE,  # Whether to show explanation in variable names
         printToggle   = TRUE,  # Whether to print the result visibly
         test          = TRUE,  # Whether to add p-values
         smd           = FALSE, # Whether to add standardized mean differences
         noSpaces      = FALSE, # Whether to remove spaces for alignments
         padColnames   = FALSE, # Whether to pad column names for alignments
         varLabels     = FALSE, # Whether to show variable labels instead of names.

         ## Categorical options
         format        = c("fp","f","p","pf")[1], # Format f_requency and/or p_ercent
         showAllLevels = FALSE, # Show all levels of a categorical variable
         cramVars      = NULL,  # Which 2-level variables to show both levels in one row
         dropEqual     = FALSE, # Do not show " = second level" for two-level variables
         exact         = NULL,  # Which variables should be tested with exact tests

         ## Continuous options
         nonnormal     = NULL,  # Which variables should be treated as nonnormal
         minMax        = FALSE, # Whether to show median

         formatOptions = list(scientific = FALSE), # Options for formatting
         ...) {

    ## Extract Cont/CatTable elements of x and dispatch print() appropriately
    FmtTables <- ModuleFormatTables(x,
                                    catDigits = catDigits, contDigits = contDigits,
                                    test = test, smd = smd, missing = missing,
                                    explain = explain, pDigits = pDigits,

                                    ## print.CatTable arguments passed
                                    format = format, exact = exact,
                                    ## Returns one more column if TRUE
                                    showAllLevels = showAllLevels,
                                    cramVars = cramVars,
                                    dropEqual = dropEqual,

                                    ## print.ContTable arguments passed
                                    nonnormal = nonnormal, minMax = minMax,
                                    insertLevel = showAllLevels,

                                    ## FormatOptions passed
                                    formatOptions = formatOptions)

    ## List of stratum sample size row only tables
    FmtStratumSizesTables <- sapply(FmtTables,
                                    FUN = ModuleStratumSizesRow,
                                    showAllLevels = showAllLevels,
                                    simplify = FALSE)
    names(FmtStratumSizesTables) <- paste0(names(FmtStratumSizesTables), "N")

    ## Combine as a list of necessary table elements
    FmtElementTables <- c(FmtTables, FmtStratumSizesTables)


    ## Add space paddings
    ## Given a list of tables with vecColWidths,
    ## return a strata-by-table df containing spaces to add
    nSpacesToAdd <- ModuleNSpacesToAdd(FmtElementTables)
    ## Actually add spaces to tables
    spcFmtEltTables <- ModuleAddSpacesToTable(FmtElementTables, nSpacesToAdd, showAllLevels)


    ## Create a list of one variable tables excluding sample size row.
    ## This is based on the variable order in the MetaData.
    lstOneVarTables <- ModuleListOfOneVarTables(spcFmtEltTables,
                                                MetaData = x$MetaData)

    ## Replace variable names with variable labels if requested.
    ## Loop over the variable replacing its name with its label.
    if (varLabels) {
        lstOneVarTables <-
            lapply(seq_along(lstOneVarTables),
                   function(i) {
                       ## Each element is a string matrix.
                       mat <- lstOneVarTables[[i]]
                       ## Manipulate if a non-NULL label is available.
                       ## Note MetaData$varLabels is a list.
                       if (!is.null(x$MetaData$varLabels[[i]])) {
                           ## The first row name contains the variable name
                           ## without preceding space. Replace by exact matching.
                           rownames(mat)[1] <- gsub(paste0("^", x$MetaData$vars[i]),
                                                    x$MetaData$varLabels[[i]],
                                                    rownames(mat)[1])
                       }
                       ## Return the entire matrix.
                       mat
                   })
    }

    ## Check if the first row is CatTable element
    ## if so, pick sample size row from space-padded CatTable element
    ## if not, pick sample size row from space-padded ContTable element
    ## Intentionally a one-element list
    lstStratumSizesRow <- ifelse(x$MetaData$logiFactors[1],
                                 list(spcFmtEltTables$FmtCatTableN),
                                 list(spcFmtEltTables$FmtContTableN))

    ## Row-combin n and all variables
    out <- do.call(rbind,
                   ## List concatenation (both are lists)
                   c(lstStratumSizesRow, lstOneVarTables))

    ## Add stratification information to the column header
    ## NULL element has a length of zero
    if (length(x$ContTable) > 1) {
        ## Combine variable names with : in between
        strataVarName <- attributes(x$ContTable)$strataVarName
        ## Create strata string
        strataString <- paste0("Stratified by ", strataVarName)
        ## Name the row dimension with it. 1st dimension name should be empty.
        names(dimnames(out)) <- c("", strataString)

    } else if (length(x$CatTable) > 1) {
        ## Combine variable names with : in between
        strataVarName <- attributes(x$CatTable)$strataVarName
        ## Create strata string
        strataString <- paste0("Stratified by ", strataVarName)
        ## Name the row dimension with it. 1st dimension name should be empty.
        names(dimnames(out)) <- c("", strataString)

    } else {

        names(dimnames(out)) <- c("", "")
    }

    ## Right-justify Missing column if showing and not removing spaces.
    if (missing & !noSpaces) {
        out[,"Missing"] <- format(out[,"Missing"], justify = "right")
    }

    ## Center-justify column names if asked and not removing spaces.
    if (padColnames & !noSpaces) {
        out <- ModuleMidJustifyColnames(mat = out)
    }

    ## Remove spaces if asked.
    out <- ModuleRemoveSpaces(mat = out, noSpaces = noSpaces)
    rownames(out)[grepl('median \\[IQR\\]', rownames(out))] <- 'median [IQR]'
    rownames(out)[grepl('95% CI', rownames(out))] <- '95% CI'
    rownames(out)[grepl('NA \\(%\\)', rownames(out))] <- 'NA (%)'
    rownames(out) <- gsub('__N2F__', '', rownames(out))
    ## Modular version of quote/print toggle.
    out <- ModuleQuoteAndPrintMat(matObj = out,
                                  quote = quote, printToggle = printToggle)

    ## Return the result
    return(invisible(out))
}
