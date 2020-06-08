#!/bin/bash -l

# This build script is only applicable to Spark without Hadoop and Hive

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
git_hash=""

export M2_HOME=/opt/mvn3
export JAVA_HOME=/opt/java

# AE-1226 temp fix on the R PATH
export R_HOME=/usr
if [ "x${R_HOME}" = "x" ] ; then
  echo "warn - R_HOME not defined, CRAN R isn't installed properly in the current env"
else
  echo "ok - R_HOME redefined to $R_HOME based on installed RPM due to AE-1226"
fi

export PATH=$M2_HOME/bin:$JAVA_HOME/bin:$PATH:$R_HOME

export HADOOP_VERSION=${HADOOP_VERSION:-"2.7.3"}
export HIVE_VERSION=${HIVE_VERSION:-"2.1.1"}
# Define default spark uid:gid and build version
# and all other Spark build related env
export SPARK_PKG_NAME=${SPARK_PKG_NAME:-"spark"}
export SPARK_GID=${SPARK_GID:-"411460017"}
export SPARK_UID=${SPARK_UID:-"411460024"}
# XMAKE_PROJECT_VERSION derived from cfg/VERSION file
RELEASE=$(echo $XMAKE_PROJECT_VERSION | cut -d- -f2)
export SPARK_VERSION=$(echo $XMAKE_PROJECT_VERSION | cut -d- -f1)
export SCALA_VERSION=${SCALA_VERSION:-"2.11"}

if [[ $SPARK_VERSION == 2.* ]] ; then
  if [[ $SCALA_VERSION != 2.11 ]] ; then
    2>&1 echo "error - scala version requires 2.11+ for Spark $SPARK_VERSION, can't continue building, exiting!"
    exit -1
  fi
fi

export BUILD_TIMEOUT=${BUILD_TIMEOUT:-"86400"}
# centos6.5-x86_64
# centos6.6-x86_64
# centos6.7-x86_64
export BUILD_ROOT=${BUILD_ROOT:-"centos6.5-x86_64"}
export BUILD_TIME=$(date +%Y%m%d%H%M)
# Customize build OPTS for MVN
export MAVEN_OPTS=${MAVEN_OPTS:-"-Xmx2048m -XX:MaxPermSize=1024m"}
export PRODUCTION_RELEASE=${PRODUCTION_RELEASE:-"false"}

export PACKAGE_BRANCH=${PACKAGE_BRANCH:-"sap-branch-2.3.2-alti"}
DEBUG_MAVEN=${DEBUG_MAVEN:-"false"}





env | sort

if [ "x${PACKAGE_BRANCH}" = "x" ] ; then
  echo "error - PACKAGE_BRANCH is not defined. Please specify the branch explicitly. Exiting!"
  exit -9
fi

echo "ok - extracting git commit label from user defined $PACKAGE_BRANCH"
git_hash=$(git rev-parse HEAD | tr -d '\n')
echo "ok - we are compiling spark branch $PACKAGE_BRANCH upto commit label $git_hash"

# Get a copy of the source code, and tar ball it, remove .git related files
# Rename directory from spark to alti-spark to distinguish 'spark' just in case.
echo "ok - preparing to compile, build, and packaging spark"

if [ "x${HADOOP_VERSION}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=$HADOOP_VERSION
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x${HIVE_VERSION}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=$HIVE_VERSION
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi


echo "ok - building Spark in directory $(pwd)"
echo "ok - building assembly with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION scala=scala-${SCALA_VERSION}"

# clean up for *NIX environment only, deleting window's cmd
rm -f ./bin/*.cmd

# Remove launch script AE-579
# TODO: Review this for K8s and multi-cloud since we may need this for spark standalond cluster
# later on.
echo "warn - removing Spark standalone scripts that may be required for Kubernetes"
rm -f ./sbin/start-slave*
rm -f ./sbin/start-master.sh
rm -f ./sbin/start-all.sh
rm -f ./sbin/stop-slaves.sh
rm -f ./sbin/stop-master.sh
rm -f ./sbin/stop-all.sh
rm -f ./sbin/slaves.sh
rm -f ./sbin/spark-daemons.sh
rm -f ./sbin/spark-executor
rm -f ./sbin/*mesos*.sh
rm -f ./conf/slaves

env | sort


# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
# Default JDK version applied is 1.7 here.

# hadoop.version, yarn.version, and hive.version are all defined in maven profile now
# they are tied to each profile.
# hadoop-2.2 No longer supported, removed.
# hadoop-2.4 hadoop.version=2.4.1 yarn.version=2.4.1 hive.version=0.13.1a hive.short.version=0.13.1
# hadoop-2.6 hadoop.version=2.6.0 yarn.version=2.6.0 hive.version=1.2.1.spark hive.short.version=1.2.1
# hadoop-2.7 hadoop.version=2.7.1 yarn.version=2.7.1 hive.version=1.2.1.spark hive.short.version=1.2.1

hadoop_profile_str=""
testcase_hadoop_profile_str=""
if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
  hadoop_profile_str="-Phadoop-2.4"
  testcase_hadoop_profile_str="-Phadoop24-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
  hadoop_profile_str="-Phadoop-2.6"
  testcase_hadoop_profile_str="-Phadoop26-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
  hadoop_profile_str="-Phadoop-2.7"
  testcase_hadoop_profile_str="-Phadoop27-provided"
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi

# TODO: This needs to align with Maven settings.xml, however, Maven looks for
# -SNAPSHOT in pom.xml to determine which repo to use. This creates a chain reaction on 
# legacy pom.xml design on other application since they are not implemented in the Maven way.
# :-( 
# Will need to create a work around with different repo URL and use profile Id to activate them accordingly
# mvn_release_flag=""
# if [ "x%{_production_release}" == "xtrue" ] ; then
#   mvn_release_flag="-Preleases"
# else
#   mvn_release_flag="-Psnapshots"
# fi

DEBUG_MAVEN=${DEBUG_MAVEN:-"false"}
if [ "x${DEBUG_MAVEN}" = "xtrue" ] ; then
  mvn_cmd="mvn -U -X $hadoop_profile_str -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests install"
else
  mvn_cmd="mvn -U $hadoop_profile_str -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests install"
fi

echo "$mvn_cmd"
DATE_STRING=`date +%Y%m%d%H%M%S`
$mvn_cmd --log-file mvnbuild_${DATE_STRING}.log

if [ $? -ne "0" ] ; then
  echo "fail - spark build failed!"
  popd
  exit -99
fi

# AE-1369
echo "ok - start packging a sparkr.zip for YARN distributed cache, this assumes user isn't going to customize this file"
pushd R/lib/
/opt/java/bin/jar cvMf sparkr.zip SparkR
popd

# Build RPM
export RPM_NAME=`echo alti-spark-${SPARK_VERSION}`
export RPM_DESCRIPTION="Apache Spark ${SPARK_VERSION}\n\n${DESCRIPTION}"
export RPM_YARNSHUFFLE_NAME=`echo alti-spark-${SPARK_VERSION}-yarn-shuffle`
export RPM_YARNSHUFFLE_DESCRIPTION="The Apache Spark ${SPARK_VERSION} pluggable spark_shuffle RPM to install spark_shuffle JAR compiled by maven\n\n${DESCRIPTION}\nThis package contains the yarn-shuffle JAR to enable spark_shuffle on YARN node managers when it is added to NM classpath."

GIT_REPO="https://github.com/Altiscale/spark"
INSTALL_DIR="${curr_dir}/spark_rpmbuild"
mkdir --mode=0755 -p ${INSTALL_DIR}

export RPM_DIR="${INSTALL_DIR}/rpm/"
mkdir -p --mode 0755 ${RPM_DIR}

echo "Packaging spark yarn shuffle rpm with name ${RPM_NAME} with version ${SPARK_VERSION}-${DATE_STRING}"

##########################
# Spark YARN SHUFFLE RPM #
##########################
export RPM_BUILD_DIR=${INSTALL_DIR}/opt/alti-spark-${SPARK_VERSION}
# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${RPM_BUILD_DIR}"

pushd "$RPM_BUILD_DIR"
mkdir --mode=0755 -p common/network-yarn/target/scala-${SCALA_VERSION}/
cp -rp $curr_dir/common/network-yarn/target/*.jar ./common/network-yarn/target/
cp -rp $curr_dir/common/network-yarn/target/scala-${SCALA_VERSION}/*.jar ./common/network-yarn/target/scala-${SCALA_VERSION}/
popd

pushd ${RPM_DIR}
fpm --verbose \
--maintainer andrew.lee02@sap.com \
--vendor SAP \
--provides ${RPM_YARNSHUFFLE_NAME} \
--description "$(printf "${RPM_YARNSHUFFLE_DESCRIPTION}")" \
--replaces ${RPM_YARNSHUFFLE_NAME} \
--url "${GITREPO}" \
--license "Apache License v2" \
--epoch 1 \
--rpm-os linux \
--architecture all \
--category "Development/Libraries" \
-s dir \
-t rpm \
-n ${RPM_YARNSHUFFLE_NAME} \
-v ${SPARK_VERSION}  \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--template-value version=$SPARK_VERSION \
--template-value scala_version=$SCALA_VERSION \
--template-value pkgname=$RPM_YARNSHUFFLE_NAME \
--rpm-auto-add-directories \
-C ${INSTALL_DIR} \
opt

if [ $? -ne 0 ] ; then
  echo "FATAL: spark $RPM_YARNSHUFFLE_NAME rpm build fail!"
  popd
  exit -1
fi

mv "${RPM_DIR}${RPM_YARNSHUFFLE_NAME}-${SPARK_VERSION}-${DATE_STRING}.noarch.rpm" "${RPM_DIR}${RPM_YARNSHUFFLE_NAME}.rpm"

echo "ok - spark $RPM_YARNSHUFFLE_NAME and RPM completed successfully!"

popd


##################
# Spark Core RPM #
##################
echo "Packaging spark rpm with name ${RPM_NAME} with version ${SPARK_VERSION}-${DATE_STRING}"

export RPM_BUILD_DIR=${INSTALL_DIR}/opt/alti-spark-${SPARK_VERSION}
# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${INSTALL_DIR}/etc/alti-spark-${SPARK_VERSION}"
mkdir --mode=0755 -p "${INSTALL_DIR}/service/log/alti-spark-${SPARK_VERSION}"

# Init local directories within spark pkg
pushd ${RPM_BUILD_DIR}
mkdir --mode=0755 -p assembly/target/scala-${SCALA_VERSION}/jars
mkdir --mode=0755 -p data/
mkdir --mode=0755 -p examples/target/scala-${SCALA_VERSION}/jars/
mkdir --mode=0755 -p external/kafka-0-8/target/
mkdir --mode=0755 -p external/kafka-0-8-assembly/target/
mkdir --mode=0755 -p external/flume/target/
mkdir --mode=0755 -p external/flume-sink/target/
mkdir --mode=0755 -p external/flume-assembly/target/
mkdir --mode=0755 -p graphx/target/
mkdir --mode=0755 -p licenses/
mkdir --mode=0755 -p mllib/target/
mkdir --mode=0755 -p common/network-common/target/
mkdir --mode=0755 -p common/network-shuffle/target/
mkdir --mode=0755 -p repl/target/
mkdir --mode=0755 -p streaming/target/
mkdir --mode=0755 -p sql/hive/target/
mkdir --mode=0755 -p sql/hive-thriftserver/target/
mkdir --mode=0755 -p tools/target/
mkdir --mode=0755 -p R/lib/
# Added due to AE-1219 to support Hive 1.2.0+ with Hive on Spark
mkdir --mode=0755 -p lib/
cp -rp $curr_dir/assembly/target/scala-${SCALA_VERSION}/jars/*.jar ./assembly/target/scala-${SCALA_VERSION}/jars/
cp -rp $curr_dir/examples/target/*.jar ./examples/target/
cp -rp $curr_dir/examples/target/scala-${SCALA_VERSION}/jars/*.jar ./examples/target/scala-${SCALA_VERSION}/jars/
# required for python and SQL
cp -rp $curr_dir/examples/src ./examples/
cp -rp $curr_dir/tools/target/*.jar ./tools/target/
cp -rp $curr_dir/mllib/data ./mllib/
cp -rp $curr_dir/mllib/target/*.jar ./mllib/target/
cp -rp $curr_dir/graphx/target/*.jar ./graphx/target/
cp -rp $curr_dir/streaming/target/*.jar ./streaming/target/
cp -rp $curr_dir/repl/target/*.jar ./repl/target/
cp -rp $curr_dir/bin ./
cp -rp $curr_dir/sbin ./
cp -rp $curr_dir/python ./
cp -rp $curr_dir/project ./
cp -rp $curr_dir/docs ./
cp -rp $curr_dir/dev ./
cp -rp $curr_dir/external/kafka-0-10/target/*.jar ./external/kafka-0-8/target/
cp -rp $curr_dir/external/kafka-0-10-assembly/target/*.jar ./external/kafka-0-8-assembly/target/
# cp -rp $curr_dir/external/flume/target/*.jar ./external/flume/target/
# cp -rp $curr_dir/external/flume-sink/target/*.jar ./external/flume-sink/target/
# cp -rp $curr_dir/external/flume-assembly/target/*.jar ./external/flume-assembly/target/
cp -rp $curr_dir/common/network-common/target/*.jar ./common/network-common/target/
cp -rp $curr_dir/common/network-shuffle/target/*.jar ./common/network-shuffle/target/
cp -rp $curr_dir/sql/hive/target/*.jar ./sql/hive/target/
cp -rp $curr_dir/sql/hive-thriftserver/target/*.jar ./sql/hive-thriftserver/target/
cp -rp $curr_dir/data/* ./data/
cp -rp $curr_dir/R/lib/* ./R/lib/
cp -rp $curr_dir/licenses/* ./licenses/
cp -p $curr_dir/README.md ./
cp -p $curr_dir/LICENSE ./
cp -p $curr_dir/NOTICE ./
cp -p $curr_dir/CONTRIBUTING.md ./
popd

pushd ${RPM_DIR}
fpm --verbose \
--maintainer andrew.lee02@sap.com \
--vendor SAP \
--provides ${RPM_NAME} \
--description "$(printf "${RPM_DESCRIPTION}")" \
--replaces ${RPM_NAME} \
--url "${GITREPO}" \
--license "Apache License v2" \
--epoch 1 \
--rpm-os linux \
--architecture all \
--category "Development/Libraries" \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${SPARK_VERSION}  \
--iteration ${RELEASE} \
--rpm-user root \
--rpm-group root \
--template-value version=$SPARK_VERSION \
--template-value scala_version=$SCALA_VERSION \
--template-value pkgname=$RPM_NAME \
--rpm-auto-add-directories \
-C ${INSTALL_DIR} \
opt etc

if [ $? -ne 0 ] ; then
	echo "FATAL: spark core rpm build fail!"
	popd
	exit -1
fi
popd

SAP_RPM_NAME="sap-${RPM_NAME}-${RELEASE}.noarch"
mv "${RPM_DIR}${RPM_NAME}-${SPARK_VERSION}-${DATE_STRING}.noarch.rpm" "${RPM_DIR}${SAP_RPM_NAME}.rpm"
echo "ok - spark $RPM_NAME and RPM completed successfully!"

echo "ok - build completed successfully!"

exit 0
