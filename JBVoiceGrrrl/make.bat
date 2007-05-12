@echo off

:: ============================================================================
:: Create Package
:: ============================================================================

echo Creating package...

cd ..\System
if exist ..\Sounds\JBVoiceGrrrl.uax.backup del ..\Sounds\JBVoiceGrrrl.uax.backup
if exist ..\Sounds\JBVoiceGrrrl.uax ren ..\Sounds\JBVoiceGrrrl.uax JBVoiceGrrrl.uax.backup
ucc pkg import sound ..\Sounds\JBVoiceGrrrl ..\JBVoiceGrrrl\Sounds
if exist ..\Sounds\JBVoiceGrrrl.uax.backup ucc conform ..\Sounds\JBVoiceGrrrl.uax ..\Sounds\JBVoiceGrrrl.uax.backup

echo Done.


:: ============================================================================
:end