#!/bin/sh
cd /app/extra/smartscope || exit 1
exec /app/bin/mono SmartScope.exe "$@"
