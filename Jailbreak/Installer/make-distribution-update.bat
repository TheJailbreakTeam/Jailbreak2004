@echo off

echo ===============================================================================
echo Full Installer
echo ===============================================================================
echo.
perl make-distribution.pl --version="b" --skip-keypress

if errorlevel 1 goto :END

echo.
echo.
echo ===============================================================================
echo Patch
echo ===============================================================================
echo.
perl make-distribution.pl --version="b-Patch" --reference-file="Jailbreak2003-reference.txt" --reference-version=100 --skip-rebuild


:END