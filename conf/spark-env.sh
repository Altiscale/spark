#!/usr/bin/env bash

##########################################################################
# WARNING: STANDALONE and MESOS are NOT supported in your Infrastructure #
##########################################################################

JAVA_HOME=/usr/java/default

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit that to configure Spark for your site.
SPARK_VERSION=1.0.0

# - SPARK_CLASSPATH, default classpath entries to append
# Altiscale local libs and folders
# SPARK_CLASSPATH=
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data

# Options read in YARN client mode
HADOOP_HOME=/opt/hadoop/
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
HADOOP_CONF_DIR=/etc/hadoop/
# - SPARK_EXECUTOR_INSTANCES, Number of workers to start (Default: 2)
# - SPARK_EXECUTOR_CORES, Number of cores for the workers (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Worker (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Master (e.g. 1000M, 2G) (Default: 512 Mb)
# - SPARK_YARN_APP_NAME, The name of your application (Default: Spark)
# - SPARK_YARN_QUEUE, The hadoop queue to use for allocation requests (Default: ‘default’)
# - SPARK_YARN_DIST_FILES, Comma separated list of files to be distributed with the job.
# - SPARK_YARN_DIST_ARCHIVES, Comma separated list of archives to be distributed with the job.

