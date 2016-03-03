#!/usr/bin/env bash

##########################################################################
# WARNING: STANDALONE and MESOS are NOT supported in your Infrastructure #
##########################################################################

JAVA_HOME=/usr/java/default

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit it to configure Spark for your site.
if [ "x${SPARK_VERSION}" = "x" ] ; then
  SPARK_VERSION="1.6.1"
fi
if [ "x${SPARK_HOME}" = "x" ] ; then
  SPARK_HOME="/opt/spark"
fi

# - SPARK_CLASSPATH, default classpath entries to append
# Altiscale local libs and folders
# SPARK_CLASSPATH=
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data

# Options read in YARN client mode
HADOOP_HOME=/opt/hadoop/
HIVE_HOME=/opt/hive/
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
HADOOP_CONF_DIR=/etc/hadoop/
YARN_CONF_DIR=/etc/hadoop/

HADOOP_SNAPPY_JAR=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
HADOOP_LZO_JAR=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")

export JAVA_LIBRARY_PATH=$JAVA_LIBRARY_PATH:$HADOOP_HOME/lib/native
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native
export SPARK_LIBRARY_PATH=$SPARK_LIBRARY_PATH:$HADOOP_HOME/lib/native
export MYSQL_JDBC_DRIVER=/opt/mysql-connector/mysql-connector.jar
export HIVE_TEZ_JARS=""
if [ -f /etc/tez/tez-site.xml ] ; then
  HIVE_TEZ_JARS=$(find /opt/tez/ -type f -name "*.jar" | tr -s "\n" ":" | sed 's/:$//')
fi

# OBSOLETE
# DO NOT USE SPARK_CLASSPATH anymore since it conflict in yarn-client mode with --driver-class-path
# Use --jars and --driver-class-path in the future for compatibility on both yarn-client and yarn-cluster mode
# See test_spark_shell.sh and test_spark_hql.sh for examples
# export SPARK_CLASSPATH=$SPARK_CLASSPATH:$HADOOP_SNAPPY_JAR:$HADOOP_LZO_JAR:$MYSQL_JDBC_DRIVER:$HIVE_TEZ_JARS

# - SPARK_EXECUTOR_INSTANCES, Number of workers to start (Default: 2)
# - SPARK_EXECUTOR_CORES, Number of cores for the workers (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Worker (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Master (e.g. 1000M, 2G) (Default: 512 Mb)
# - SPARK_YARN_APP_NAME, The name of your application (Default: Spark)
# - SPARK_YARN_QUEUE, The hadoop queue to use for allocation requests (Default: ‘default’)
# - SPARK_YARN_DIST_FILES, Comma separated list of files to be distributed with the job.
# SPARK_YARN_DIST_FILES=/user/spark/opt/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/yarn/hadoop-yarn-client-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/yarn/hadoop-yarn-common-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/yarn/hadoop-yarn-api-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/yarn/hadoop-yarn-server-web-proxy-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-app-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.4.1.jar,/user/spark/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.4.1.jar
# - SPARK_YARN_DIST_ARCHIVES, Comma separated list of archives to be distributed with the job.
# See docs/hadoop-provided.md
SPARK_HIVE_JAR=$(basename $SPARK_HOME/sql/hive/target/spark-hive_2.10-${SPARK_VERSION}.jar)
SPARK_HIVETHRIFT_JAR=$(basename $SPARK_HOME/sql/hive-thriftserver/target/spark-hive-thriftserver_2.10-${SPARK_VERSION}.jar)
HIVE_JAR_COMMA_LIST="$SPARK_HIVE_JAR:$SPARK_HIVETHRIFT_JAR"
for f in `find /opt/hive/lib/ -type f -name "*.jar"`
do
  HIVE_JAR_COMMA_LIST=$(basename $f):$HIVE_JAR_COMMA_LIST
done

export SPARK_DIST_CLASSPATH=$(hadoop classpath):$HIVE_JAR_COMMA_LIST
