report.pdf: report.tex macros.tex
	latexmk -xelatex report.tex
