@echo off
cls

odin build src\ -vet -collection:pinky=.\src -out:.\out\pinky.exe && out\pinky.exe ..\programs\example.pinky
