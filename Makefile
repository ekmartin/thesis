TEX := $(shell find . -name '*.tex')

report.pdf: ${TEX} sources.bib
	latexmk report.tex

watch:
	latexmk -pvc report.tex

clean:
	rm -f *-blx.bib
	rm -f *.{aux,bak,bbl,blg,dvi,fls,log,out,toc,pdf,fdb_latexmk,xml}
