# spark-installer
Installs a pre-existing Spark home dir to the Linux environment

Installs Spark resources to the /usr/local filesystem hiearchy. Bins and sbins go to 
/usr/local/bin and /usr/local/sbin so they're accessible from standard $PATHS. JARs
go to /usr/local/lib/spark/ as is convention for installed project JARs. R libraries
go to /usr/local/lib/R/site-library/SparkR/ as is convention for installed project
R libs. The Spark home itself is made accessible at /usr/local/src/spark/

To run the installer point it at a Spark home directory. Also accepts tar files and
URLs to download. Default argument installs from any directory /usr/local/src/ that
starts with "spark" E.g.

    ./install-spark.sh    # To install if Spark's at /usr/local/src/spark-2.4.0
    ./install-spark.sh  ~/sparkHome/
    ./install-spark.sh. ~/spark-2.4.0.tar.gz
    ./install-spark.sh  https://archive.apache.org/dist/spark/spark-2.4.0.tgz
