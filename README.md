# spark-installer
Installs a pre-existing Spark home dir to the Linux system environment.

Run once, then all Spark commands and libraries will be natively available will be
natively available. Just like standard Linux packages. Never worry about fiddling
with SPARK_HOME, CLASSPATH or PATH again.

## Quickstart

To run simply call the script without any arguments, and it will install directly the
latest version from the Apache downlaod archives:

    git clone https://github.com/Mister-Meeseeks/spark-installer.git
    sudo ./spark-installer/install-spark.sh
    
The install script is a single file without any dependencies in the project. It can be
run without using git or having to copy the repo. Just curl the install script directly
to bash:

    curl https://raw.githubusercontent.com/Mister-Meeseeks/spark-installer/master/install-spark.sh \
      | bash
      
## Usage Patterns

The install script accepts as a positional argument, any directory, tar archive or 
curl-compatible URL. If specified will install that specific source.

### URL

By default uses the latest Apache URL. But you can specify any different URL, for example
to download a different version or from a separate repo. Example:

    sudo ./install-spark.sh https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
 
### Local Filesystem
 
The install script also accepts directories and tar archives from the filesystem. If
you have a custom or cached SPARK_HOME locally, it can be installed like

    sudo ./install-spark.sh ~/mySparkHome

Or for a tar archive

    sudo ./install-spark.sh ~/mySparkHome.tar.gz
    
### Preset /usr/local/src/
    
Finally, if no argument is supplied the default behavior is to first look any Spark
directory in the system source directory (`/usr/local/src/` by default). That means
any directory with Spark or spark in its name. If multiple are found, the latest
version is used.

E.g. for the following directory

    /usr/local/src
               |-- hadoop2.7
               |-- spark-bin-1.8.0
               |-- spark-bin-2.4.0
               |-- zeppelin
               
Then the following command 

    sudo ./install-spark.sh
    
Installs `/usr/local/src/spark-bin-2.4.0`

## Install Targets

### Binaries

The top-level Spark binaries from `$SPARK_HOME/bin` are installed to `/usr/local/bin/`
which is in the $PATH of all shells by default. Therefore after installation any shell
can call a Spark bin as a native command. E.g.:

    bash$ spark-submit

### Jars

Spark's JAR files are installed to `/usr/local/lib/spark`. That makes them available on
any standard JDK or JRE $CLASSPATH by default.

### R

SparkR's libraries are installed to `/usr/local/R/site-library`. That means the SparkR
library will be natively available to all R sessions. In any R terminal, simply call

    > library(SparkR)
    
### pyspark

The pyspark library is installed to `/usr/local/lib/python2.7/site-packages`. That means
the pyspark package will be natively available to all python 2 interpreters by default.

### System Binaries

Spark's system binaries for managing a cluser are stored in `$SPARK_HOME/sbin/`. Because
their names aren't scoped with anything identifying them as spark utilities directly
placing them in the $PATH would be ambigious and confusing.

The installer creates a utility in the `/usr/local/sbin/` directory (available by default
on standard shell $PATH's). The utility is called spark-adm, and accepts as its first
argument the name of the Spark sbin to run. (With or without the .sh extension) Any trailing 
arguments are passed to the underlying Spark sbin.

For example to start a standalone slave run

    bash$ spark-adm start-slave spark://127.0.0.1:7070

### SPARK_HOME

The SPARK_HOME directory itself is copied and stored at `/usr/local/src/spark`

## Dependencies

* bash
* curl
* wget
* readlink (GNU style. Must support -f flag)
* Linux style filesystem
* 
