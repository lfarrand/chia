#!/bin/bash

# Crontab
# */30 * * * * /home/lee/scripts/move_files.sh job1 '/mnt/f/tmp/src1 /mnt/f/tmp/src2' '/mnt/f/tmp/dst1 /mnt/f/tmp/dst2 /mnt/f/tmp/dst3' > /var/log/movefilesjob/job1-`date +\%Y\%m\%d\%H\%M\%S`.log 2>&1

# Testing: ./move_files.sh job1 '/mnt/f/tmp/src1 /mnt/f/tmp/src2 /mnt/f/tmp/src3' '/mnt/f/tmp/dst1 /mnt/f/tmp/dst2 /mnt/f/tmp/dst3'

echo "$$ trying to acquire lock"
(
    flock -x -n 200
    flockretcode=$?

    if [ "$flockretcode" != 0 ]; then
        echo "Already running script, skipping"
        exit 1
    fi

    echo "Lock acquired by $$"

    # Clean up old log files
    find /var/log/movefilesjob/$1-* -mtime +1 -type f -delete

    echo "sources: $2"
    echo "targets: $3"
    echo "skip free space check: $4"
    skipFreeSpaceCheck='N'

    if [ ! -z "$4" ] && [ $4 == 'Y' ]; then
        skipFreeSpaceCheck='Y'
    fi

    rm -rf "$1-jobs"

    sources=( $2 )
    targets=( $3 )

    size120GBInKB=125829120

    targetsWithAvailableSpace=()

    if [ $skipFreeSpaceCheck == 'N' ]; then
        echo "Checking targets for available space"
        # Free space check
        for tgt in ${targets[@]}; do
            free=`df -k --output=avail "$tgt" | tail -n1 | sed 's/ //g'`

            echo "$tgt has $free KB available"

            if (($free > $size120GBInMB )); then
                targetsWithAvailableSpace+=("$tgt")
            else
                echo "Skipping $tgt as it has less than 120GB available"
            fi
        done

        targets=("${targetsWithAvailableSpace[@]}")
    fi

    sourcesCount="${#sources[@]}"
    targetsCount="${#targets[@]}"
    count=0

    if (($targetsCount == 0)); then
        echo "Unable to move any files because no targets had more than 120GB available"
        exit 1
    fi

    # Build work list
    for sourceIndex in "${!sources[@]}"; do
        #echo $sourceIndex
        source="${sources[$sourceIndex]}"
        filecount="$(find $source -name "*.plot" -type f | wc -l)"
        echo "Found $filecount files to copy from $source"
        sourceCount=0

        if (( $filecount > 0 )); then
            for file in $(find $source -name "*.plot" -type f); do
                targetIndex=$(($count % $targetsCount))
                target=${targets[$targetIndex]}
                ((lineNumber=(($sourceCount+1)*$sourcesCount)-($sourcesCount-$sourceIndex-1)))
                echo "lineNumber: $lineNumber"
                echo "Moving file $file from $source to $target"
                echo "$lineNumber rsync -avz --no-owner --no-group --remove-source-files $file $target/" >> "$1-jobs"
                ((count=count+1))
                ((sourceCount=sourceCount+1))
            done
        else
            echo "Skipping $source because there were no files"
        fi
    done

    if [ -f "$1-jobs" ]; then
        sort -n -o "$1-jobs" "$1-jobs"
        sed -i 's/^[0-9]*\s//g' "$1-jobs"
        echo "parallel --jobs $targetsCount < $1-jobs"
        parallel --jobs $targetsCount < "$1-jobs"
    else
        echo "Didn't find any files to move"
    fi

) 200>/var/lock/movefilesjob-$1.lck
