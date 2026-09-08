
# DFR JASA Discussion

This repository contains the LaTeX source for a JASA
discussion/commentary on Deep Fréchet Regression, along with the code
and figures used for the manifold dimension selection example.

## Repository Layout

- `jasa-manuscript.tex`: main JASA manuscript LaTeX file.
- `manuscript/`: section-level manuscript source files.
- `references.bib`: bibliography database.
- `agsm.bst`: bibliography style used by the JASA template.
- `figures/`: figure files included in the manuscript.
- `code/manifold-selection-example.R`: R script used to generate the
  simulation figures.

## Build Locally

The manuscript is built with `pdflatex` and BibTeX through `latexmk`.

``` sh
make
```

or explicitly:

``` sh
make pdf
```

The output is `jasa-manuscript.pdf`.

To remove LaTeX auxiliary files:

``` sh
make clean
```

To also remove the generated PDF and log:

``` sh
make cleanall
```

## Regenerate Figures

The figures can be regenerated from the R script:

``` sh
make figures
```

This requires the R packages used by
`code/manifold-selection-example.R`, including `ggplot2`, `lattice`,
`data.table`, `scales`, `sn`, `here`, and any other packages loaded by
the script.

## Overleaf Notes

For Overleaf, upload the source files rather than local build products.
The important files are:

- `jasa-manuscript.tex`
- `manuscript/`
- `references.bib`
- `agsm.bst`
- `figures/`

Use `jasa-manuscript.tex` as the main document, `pdfLaTeX` as the
compiler, and BibTeX for the bibliography. If switching from an older
`biblatex` version, clear cached/generated files or use “Recompile from
scratch” so stale `*.aux`/`*.bbl` files do not interfere with the natbib
build.

## Generated Files

LaTeX build products such as `*.aux`, `*.bbl`, `*.blg`, `*.fdb_latexmk`,
`*.fls`, `*.out`, and `*.synctex.gz` are ignored by Git. The PDF and log
are also ignored locally.

## Acknowledgement

Edward Gunning is the author of this repository. The author used ChatGPT
Version 5.5 (OpenAI) for coding and copy-editing assistance. It was also
used to help versioning the repository and construct the README and
Makefile. All AI generated edits were reviewed and approved by the
author.

### Reproducibility Notes

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: aarch64-apple-darwin20
    ## Running under: macOS Sequoia 15.7.3
    ## 
    ## Matrix products: default
    ## BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib 
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
    ## 
    ## locale:
    ## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    ## 
    ## time zone: Europe/Dublin
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices datasets  utils     methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] compiler_4.5.2    fastmap_1.2.0     cli_3.6.5         htmltools_0.5.9  
    ##  [5] tools_4.5.2       otel_0.2.0        rstudioapi_0.19.0 yaml_2.3.12      
    ##  [9] rmarkdown_2.31    knitr_1.51        xfun_0.60         digest_0.6.39    
    ## [13] rlang_1.3.0       renv_1.2.3        evaluate_1.0.5
