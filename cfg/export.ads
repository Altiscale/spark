artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "spark", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-${buildVersion}.noarch.rpm"
    }

    artifact "spark-shuffle", {
      file "$gendir/src/spark_rpmbuild/rpm/alti-spark-2.3.2-yarn-shuffle.rpm"
    }
  }
}
