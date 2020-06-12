artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "spark", {
      file "$gendir/src/spark_rpmbuild/rpm/sap-alti-spark-${baseversion}.noarch.rpm"
    }

    artifact "spark-shuffle", {
      file "$gendir/src/spark_rpmbuild/rpm/sap-alti-spark-2.3.2-yarn-shuffle-${baseversion}.noarch.rpm"
    }
  }
}
