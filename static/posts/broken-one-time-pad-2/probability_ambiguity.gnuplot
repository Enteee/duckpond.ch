set border 4095 front lt black linewidth 1.000 dashtype solid
set view map scale 1
set samples 100, 100
set isosamples 100, 100
unset surface 
set style data pm3d
set style function pm3d
set ticslevel 0

set title "Probability for an ambiguity"

set xlabel 'possible characters : size of M'
set xrange [ 0 : 256 ] noreverse nowriteback

set ylabel 'number of tests : |c| / |k|'
set yrange [ 0 : 10 ] noreverse nowriteback

set zrange [ 0 : 1.00000 ] noreverse nowriteback

set pm3d implicit at b
set palette rgbformulae 30, 31, 32

set terminal svg size 350,262 fname 'Verdana' fsize 10
set output 'probability_ambiguity.svg'

splot (x/256)**y
