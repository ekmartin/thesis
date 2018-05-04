TEX := $(shell find . -name '*.tex')

report.pdf: ${TEX} sources.bib
	latexmk report.tex

watch:
	latexmk -pvc report.tex

clean:
	rm *.{aux,blg,dvi,fls,log,toc,pdf,fdb_latexmk}
