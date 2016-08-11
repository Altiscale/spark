#!/usr/bin/env bash

##########################################################################
# WARNING: STANDALONE and MESOS are NOT supported in your Infrastructure #
##########################################################################

JAVA_HOME=${JAVA_HOME:-"/usr/java/default"}

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit it to configure Spark for your site.
# We honor bin/load-spark-env.sh values, and any external assignment from
# users.
export SPARK_VERSION=${SPARK_VERSION:-"1.5.2"}
# Use absolute path here, do NOT apply /opt/spark here since we need to support multiple version of Spark
export SPARK_HOME=${SPARK_HOME:-"/opt/alti-spark-1.5.2"}
export SPARK_SCALA_VERSION=${SPARK_SCALA_VERSION:-"2.10"}

# - SPARK_CLASSPATH, default classpath entries to append
# Altiscale local libs and folders
# SPARK_CLASSPATH=
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data

# Options read in YARN client mode
HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop/"}
HIVE_HOME=${HIVE_HOME:-"/opt/hive/"}
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"/etc/hadoop/"}
YARN_CONF_DIR=${YARN_CONF_DIR:-"/etc/hadoop/"}

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native
# export HIVE_TEZ_JARS=""
# if [ -f /etc/tez/tez-site.xml ] ; then
#   HIVE_TEZ_JARS=$(find /opt/tez/ -type f -name "*.jar" | tr -s "\n" ":" | sed 's/:$//')
# fi

# See docs/hadoop-provided.md
SPARK_HIVE_JAR=$SPARK_HOME/lib/spark-hive_${SPARK_SCALA_VERSION}.jar
SPARK_HIVETHRIFT_JAR=$SPARK_HOME/lib/spark-hive-thriftserver_${SPARK_SCALA_VERSION}.jar

export SPARK_DIST_CLASSPATH=$(hadoop classpath):$SPARK_HIVE_JAR:$SPARK_HIVETHRIFT_JAR:$(basename $SPARK_HIVE_JAR):$(basename $SPARK_HIVETHRIFT_JAR):${HIVE_HOME}/lib/*:./hive/*
