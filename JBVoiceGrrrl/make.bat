@echo off

:: ============================================================================
:: Create Package
:: ============================================================================

echo Creating package...

cd ..\System
ucc pkg import sound ..\Sounds\JBVoiceGrrrl ..\JBVoiceGrrrl\Sounds

echo Done.


:: ============================================================================
:end