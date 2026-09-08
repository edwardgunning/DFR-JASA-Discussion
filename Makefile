MAIN := jasa-manuscript
TEX := $(MAIN).tex

.PHONY: all pdf figures clean cleanall

all: pdf

pdf:
	latexmk -pdf $(TEX)

figures:
	Rscript code/manifold-selection-example.R

clean:
	latexmk -c $(TEX)
	rm -f $(MAIN).bbl $(MAIN).run.xml $(MAIN).bcf

cleanall:
	latexmk -C $(TEX)
	rm -f $(MAIN).pdf $(MAIN).log $(MAIN).bbl $(MAIN).run.xml $(MAIN).bcf
