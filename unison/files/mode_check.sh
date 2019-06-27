#!/bin/bash

# stat wrapper to check file chmod

DEBUG=False

if [ $# == 2 ]
  then
    FILE_PATH=$1
    MODE=$2
  else
    if [ $DEBUG == True ]
      then
        echo "Need 2 args, now $# args"    
        echo ""
        echo "Usage: $0 %FilePath% %Mode%"
        echo "$0 /bin/bash 777"
        echo ""
        echo "Abort!"
        echo ""
    fi
    exit 1

fi

    

stat_bin=$(whereis stat | cut -f 2 -d ' ')

file_mode=$($stat_bin --format '%a' $FILE_PATH)


if [ $DEBUG == True ]
  then
    echo "Stat return - $file_mode"
    echo ''
fi

if [ $file_mode == $MODE ]
  then
    if [ $DEBUG == True ]
      then
        echo "All ok, file mode correct"
        echo ""
    fi
    exit 0
  else
    if [ $DEBUG == True ]
      then
        echo "Current file mode is different"
        echo "Current mode = $file_mode"
        echo ""
    fi
    exit 1
fi

