artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "spark", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-3.0.0.rpm"
    }

    artifact "spark-shuffle", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-3.0.0-yarn-shuffle.rpm"
    }
  }
}
