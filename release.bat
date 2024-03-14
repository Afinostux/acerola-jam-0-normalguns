@echo off

del errors.err
del log.txt

odin.exe build .\game -o:aggressive -out:normalguns.exe -strict-style 2>> errors.err 1>> log.txt
