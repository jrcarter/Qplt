# Qplt
Quick Plot: an Ada-GUI program to quickly produce a plot of a data set

##Usage
type

qplt -?

for usage instructions

##Dependencies
Qplt requires Ada GUI (https://github.com/jrcarter/Ada_GUI) and the PragmAda Reusable Components (https://github.com/jrcarter/PragmARC).

##Sample Input
The files qplt_sine.txt, qplt_sombrero.txt, and qplt_wpop.txt contain sample data for Qplt.

qplt_sine.txt contains a sine curve. Suggested use:

qplt np -t Sine qplt_sine.txt

qplt_sombrero.txt contains the "Sombrero" curve, sin x / x (with the limit of 1 plotted for x = 0). Suggested use:

qplt np -t Sombrero qplt_sombrero.txt

qplt_wpop.txt contains values of world population since 1600. Suggested use:

qplt -t "World Population" -x Year -y "Population in billions" qplt_wpop.txt

The sample input files are proveded under the CC BY-SA license (https://creativecommons.org/licenses/by-sa/4.0/).
