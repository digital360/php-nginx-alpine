#!/bin/sh -e

FPM_PROCESS_MEMORY_MB=128
RESERVE_INSTANCE_MEMORY=2048

FPM_POOL_FILE=/usr/local/etc/php-fpm.d/www.conf

MEM_KB=`grep MemTotal /proc/meminfo | awk '{print $2}'`
MEM_FOR_FPM_MB=$(($MEM_KB/1024-$RESERVE_INSTANCE_MEMORY))
FPM_PROCESSES=$(($MEM_FOR_FPM_MB/$FPM_PROCESS_MEMORY_MB))

echo "Calculated amount of PHP-FPM processes (from $MEM_FOR_FPM_MB MB): $FPM_PROCESSES"

FPM_PROCESSES=${FPM_PROCESSES%.*}

sed -i -e "s/pm.max_children\s*=.*/pm.max_children = $FPM_PROCESSES/g" $FPM_POOL_FILE

echo "Amount of PHP-FPM processes set to $FPM_PROCESSES"