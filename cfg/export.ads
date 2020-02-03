artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "spark", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-${buildVersion}.rpm"
    }

    artifact "spark-shuffle", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-${buildVersion}-yarn-shuffle.rpm"
    }

    artifact "spark-devel", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-${buildVersion}-devel.rpm"
    }

    artifact "spark-kinesis", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-${buildVersion}-kinesis.rpm"
    }
  }
}
