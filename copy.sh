#!/bin/bash
echo "creating a 20MB sample file"
dd if=/dev/zero of=/tmp/file.dd count=10 bs=2M

echo "start to copy with class 3 (idle)"
(time ionice -c 3 dd if=/tmp/file.dd of=/tmp/file3.dd iflag=direct && echo "" && echo "ionice with class 3 (idle) finished" && echo ====================================) &

echo "start to copy with class 1 (realtime) priority 0"
(time ionice -c 1 -n 0 dd if=/tmp/file.dd of=/tmp/file1-0.dd iflag=direct && echo "ionice with class 1 (realtime) priority 0 finished" && echo ====================================) &

echo "start to copy with class 1 (realtime) priority 7"
(time ionice -c 1 -n 7 dd if=/tmp/file.dd of=/tmp/file1-7.dd iflag=direct && echo "ionice with class 1 (realtime) priority 7 finished" && echo ====================================) &

echo "start to copy with class 2 (best effort - standard) priority 0"
(time ionice -c 2 -n 0 dd if=/tmp/file.dd of=/tmp/file2-0.dd iflag=direct && echo "ionice with class 2 (best effort) priority 0 finished" && echo ====================================) &

sleep 5
ps ax | grep iflag

