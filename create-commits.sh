#!/bin/bash

SCRIPT="`readlink -f "${BASH_SOURCE[0]}"`"
SCRIPT_HOME="`dirname "$SCRIPT"`"

# secconds passed since first commit (default 1 year)
FIRST_BUILD_SINCE=${FIRST_BUILD_SINCE:-31536000}
# seconds passed since last commit (default 0 / now)
LAST_BUILD_SINCE=${LAST_BUILD_SINCE:-0}

# minimum seconds till next commit (default 10)
MIN_SHIFT=${MIN_SHIFT:-10}
# maximum seconds till next commit (default 1 day)
MAX_SHIFT=${MAX_SHIFT:-86400}
# linear modifier for MIN_SHIFT (operator [+,-] must be appended; default '+0')
MIN_MOD_LINEAR=${MIN_MOD_LINEAR:-'+0'}
# factor modifier for MIN_SHIFT (default 1)
MIN_MOD_FACTOR=${MIN_MOD_FACTOR:-1}
# linear modifier for MAX_SHIFT (operator [+,-] must be appended; default '+0')
MAX_MOD_LINEAR=${MAX_MOD_LINEAR:-'+0'}
# factor modifier for MAX_SHIFT (default 1)
MAX_MOD_FACTOR=${MAX_MOD_FACTOR:-1}

CURRENT_TIME=$(date +%s)
CURRENT_BUILD_NO=1

# time stamp to use for every commit (will be modified in loop)
FAKE_TIME_STAMP=$(($CURRENT_TIME - $FIRST_BUILD_SINCE))
# max time for last commit (condition in loop)
LAST_BUILD_TIME=$(($CURRENT_TIME - $LAST_BUILD_SINCE))

FAKE_RESULT=(FAILURE SUCCESS)

mkdir "/tmp/$CURRENT_TIME"
cd "/tmp/$CURRENT_TIME"

while [ $FAKE_TIME_STAMP -lt $LAST_BUILD_TIME ]
do
  mkdir $CURRENT_BUILD_NO
  cp "${SCRIPT_HOME}/build.xml.template" "${CURRENT_BUILD_NO}/build.xml"

  FAKE_START_TIME=$(( $FAKE_TIME_STAMP + $(shuf -i 2-30 -n 1) ))
  FAKE_RESULT_NO=$(shuf -i 0-1 -n 1)
  FAKE_DURATION=$(shuf -i 10-600000 -n 1)

  sed -i "s/QUEUE_ID/${CURRENT_BUILD_NO}/g" "${CURRENT_BUILD_NO}/build.xml"
  sed -i "s/TIMESTAMP/${FAKE_TIME_STAMP}000/g" "${CURRENT_BUILD_NO}/build.xml"
  sed -i "s/START_TIME/${FAKE_START_TIME}000/g" "${CURRENT_BUILD_NO}/build.xml"
  sed -i "s/RESULT/${FAKE_RESULT[$FAKE_RESULT_NO]}/g" "${CURRENT_BUILD_NO}/build.xml"
  sed -i "s/DURATION/${FAKE_DURATION}/g" "${CURRENT_BUILD_NO}/build.xml"

  CURRENT_BUILD_NO=$(( $CURRENT_BUILD_NO + 1 ))

  # next commit between MIN_SHIFT and MAX_SHIFT
  TIME_SHIFT=$(shuf -i $MIN_SHIFT-$MAX_SHIFT -n 1)
  FAKE_TIME_STAMP=$(($FAKE_TIME_STAMP + $TIME_SHIFT))

  # modify MIN_SHIFT and MAX_SHIFT
  TEMP_MIN_SHIFT=$(echo | awk "{printf \"%.0f\n\",($MIN_SHIFT $MIN_MOD_LINEAR) * $MIN_MOD_FACTOR}" )
  TEMP_MAX_SHIFT=$(echo | awk "{printf \"%.0f\n\",($MAX_SHIFT $MAX_MOD_LINEAR) * $MAX_MOD_FACTOR}" )

  if [ $TEMP_MIN_SHIFT -gt 0 ] && [ $TEMP_MIN_SHIFT -lt $TEMP_MAX_SHIFT ]; then
    MIN_SHIFT=$TEMP_MIN_SHIFT
  fi

  if [ $TEMP_MAX_SHIFT -gt 0 ] && [ $TEMP_MAX_SHIFT -gt $TEMP_MIN_SHIFT ]; then
    MAX_SHIFT=$TEMP_MAX_SHIFT
  fi
done

echo "New repository created in /tmp/$CURRENT_TIME"
