@echo off

echo ===============================================================================
echo Full Installer (zip)
echo ===============================================================================
echo.
perl make-distribution.pl --version="c" --skip-keypress --zip zip

if errorlevel 1 goto :END

echo.
echo.
echo ===============================================================================
echo Patch
echo ===============================================================================
echo.
perl make-distribution.pl --version="c-Patch" --reference-file="Jailbreak2004b-reference.txt" --reference-version=102 --skip-rebuild --zip zip


:END