report.pdf: report.tex macros.tex sources.bib
	latexmk report.tex

watch:
	latexmk -pvc report.tex

clean:
	rm report.{aux,blg,dvi,fls,log,toc,pdf,fdb_latexmk}
