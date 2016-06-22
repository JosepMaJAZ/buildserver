echo ---- Building pthreads ----
set PTHREADS_PATH=pthreads-2.9.1

if %MACHINE_X86% (
  set PLATFORM=Win32
) else (
  set PLATFORM=x64
)

if %CONFIG_RELEASE% (
  set CONFIG=Release
) else (
  set CONFIG=Debug
)

cd build\%PTHREADS_PATH%
%MSBUILD% pthread.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /t:pthread:Clean;pthread:Rebuild

copy %PLATFORM%\%CONFIG%\pthread.dll %LIB_DIR%
copy %PLATFORM%\%CONFIG%\pthread.lib %LIB_DIR%
copy %PLATFORM%\%CONFIG%\pthread.pdb %LIB_DIR%
copy pthread.h %INCLUDE_DIR%
copy semaphore.h %INCLUDE_DIR%
copy sched.h %INCLUDE_DIR%

cd %ROOT_DIR%