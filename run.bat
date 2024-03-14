@echo off

del errors.err
del log.txt

odin.exe run .\game -o:minimal -debug 2>> errors.err 1>> log.txt
