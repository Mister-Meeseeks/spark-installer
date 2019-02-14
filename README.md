# spark-installer
Installs a pre-existing Spark home dir to the Linux system environment.

Run once, then all Spark commands and libraries will be natively available will be
natively available. Just like standard Linux packages. Never worry about fiddling
with SPARK_HOME, CLASSPATH or PATH again.

# Quickstart

To run simply call the script with a directory, tar archive or URL of a valid Spark
Home as the argument. E.g. to download from Apache and install

    git clone https://github.com/Mister-Meeseeks/spark-installer.git
    sudo ./spark-installer/install-spark.sh https://archive.apache.org/dist/spark/spark-2.4.0.tgz
    
The install script is a single file without any dependencies in the project. It can be
run without using git or having to copy the repo. Just curl the install script directly
to bash:

    curl https://raw.githubusercontent.com/Mister-Meeseeks/spark-installer/master/install-spark.sh \
      | bash https://archive.apache.org/dist/spark/spark-2.4.0.tgz
      
# Usage Patterns
 
The install script also accepts directories and tar archives from the filesystem. If
you have a custom or cached SPARK_HOME locally, it can be installed like

    sudo ./install-spark.sh ~/mySparkHome

Or for a tar archive

    sudo ./install-spark.sh ~/mySparkHome.tar.gz
    
URLs also work with any curl-compatible protocol:

    sudo ./install-spark.sh sftp://artifact-repo.local/mySparkHome.tgz

Finally, if no argument is supplied the default behavior is to look for the last
directory in the system source directory (`/usr/local/src/` by default) that has 
spark or Spark in its name.

E.g. for the following directory

    /usr/local/src
               |-- hadoop2.7
               |-- spark-bin-1.8.0
               |-- spark-bin-2.4.0
               |-- zeppelin
               
Then the following command 

    sudo ./install-spark.sh
    
Installs `/usr/local/src/spark-bin-2.4.0`

