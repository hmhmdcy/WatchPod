#!/bin/bash
source /home/user/.bashrc_flutter
cd /home/user/watchpod
exec flutter build apk --release > /tmp/apk_build.log 2>&1
