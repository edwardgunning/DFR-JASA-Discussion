MAIN := jasa_manuscript
TEX := $(MAIN).tex
BLINDED := anonymous_jasa_manuscript
BLINDED_TEX := $(BLINDED).tex
COVER := cover-letter/main.tex

.PHONY: all pdf blinded cover submission figures clean clean-blinded clean-cover clean-submission cleanall

all: pdf

pdf:
	latexmk -pdf $(TEX)

blinded:
	latexmk -pdf $(BLINDED_TEX)

cover:
	latexmk -cd -pdf $(COVER)

submission: blinded cover

figures:
	Rscript code/manifold-selection-example.R

clean:
	latexmk -c $(TEX)
	rm -f $(MAIN).bbl $(MAIN).run.xml $(MAIN).bcf

clean-blinded:
	latexmk -c $(BLINDED_TEX)
	rm -f $(BLINDED).bbl $(BLINDED).run.xml $(BLINDED).bcf

clean-cover:
	latexmk -cd -c $(COVER)
	rm -f cover-letter/main.bbl cover-letter/main.run.xml cover-letter/main.bcf

clean-submission: clean-blinded clean-cover

cleanall:
	latexmk -C $(TEX)
	rm -f $(MAIN).pdf $(MAIN).log $(MAIN).bbl $(MAIN).run.xml $(MAIN).bcf
	latexmk -C $(BLINDED_TEX)
	rm -f $(BLINDED).pdf $(BLINDED).log $(BLINDED).bbl $(BLINDED).run.xml $(BLINDED).bcf
	latexmk -cd -C $(COVER)
	rm -f cover-letter/main.pdf cover-letter/main.log cover-letter/main.bbl cover-letter/main.run.xml cover-letter/main.bcf
