#! /bin/bash
#
# Copyright (c) 2020, Andy Frank
# Licensed under the Apache License version 2.0
#
# History:
#   4 Mar 2020  Andy Frank  Creation
#

# TODO: this could be alot better :)

WORK_DIR=$(cd `dirname $0` && pwd)
TEMP_DIR=$WORK_DIR/temp
mkdir -p $WORK_DIR/jdks
mkdir -p $WORK_DIR/temp
mkdir -p $WORK_DIR/releases

# first check for --clean
if [[ "$*" == "--clean" ]]; then
  echo "Clean"
  echo "  Delete [$WORK_DIR/jdks]"
  rm -f $WORK_DIR/jdks/*
  echo "  Delete [$WORK_DIR/releases]"
  rm -f $WORK_DIR/releases/*
  echo "SUCCESS!"
  exit 0
fi

# make sure java11 is installed
command -v java >/dev/null 2>&1 || { echo >&2 "ERR: java not found"; exit 1; }
HOST_JDK_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
[[ $HOST_JDK_VER == 11.* ]] || { echo >&2 "ERR: java11 required "; exit 1; }

function make_jre()
{
  JDK_BASE_URI=$1
  JDK_NAME=$2
  JDK_TAR="${JDK_NAME}.tar.gz"
  JDK_DIR="$3"
  JRE_NAME=$4
  JRE_TAR="studs-${JRE_NAME}.tar.gz"
  MODULES=$5

  echo "  Make [$JRE_NAME]"

  # download JDK if not found
  if [[ ! -f "$WORK_DIR/jdks/$JDK_TAR" ]]; then
    echo "    Download [$JDK_NAME]"
    cd $WORK_DIR/jdks && wget $JDK_BASE_URI/$JDK_TAR
  fi

  # untar jdk
  echo "    Untar [$JDK_NAME]"
  tar xf $WORK_DIR/jdks/$JDK_TAR -C $TEMP_DIR

  # create jlink release dir
  echo "    Jlink [$JRE_NAME]"
  OUT_DIR=$TEMP_DIR/$JRE_NAME
  $JAVA_HOME/bin/jlink --module-path $TEMP_DIR/$JDK_DIR/jmods --compress=2 --add-modules $MODULES --output $OUT_DIR
  rm -rf $OUT_DIR/lib/client

  # tar to release dir
  echo "    Tar [$JRE_NAME]"
  cd $TEMP_DIR && tar czf $JRE_TAR $JRE_NAME/
  mv $JRE_TAR $WORK_DIR/releases/
  echo "    Complete [$JRE_TAR]"
}

# always start fresh
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

echo "BuildJre"

# studs-jre-arm32hf-11.0.6-min
make_jre \
  "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10" \
  "OpenJDK11U-jdk_arm_linux_hotspot_11.0.6_10" \
  "jdk-11.0.6+10" \
  "jre-arm32hf-11.0.6-min" \
  "java.base"

# done
echo "SUCCESS!"