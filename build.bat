@echo off

del errors.err
del log.txt

odin.exe build .\game -o:none -strict-style -debug 2>> errors.err 1>> log.txt
