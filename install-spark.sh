#!/bin/bash -e

sysDir=/usr/local

while getopts "l:b:s:j:R:S:" opt ; do
    case $opt in
	l) sysDir=$OPTARG;;
	b) binSysDir=$OPTARG;;
	s) sbinSysDir=$OPTARG;;
	j) jarsSysDir=$OPTARG;;
	R) rLibSysDir=$OPTARG;;
	S) srcSysDir=$OPTARG;;
    esac
done
shift $(($OPTIND - 1))
installSrc=$1

mkdir -p $sysDir
sysDir=$(readlink -f $sysDir)

if [[ -z $binSysDir ]] ; then
    binSysDir=$sysDir/bin
fi
if [[ -z $sbinSysDir ]] ; then
    sbinSysDir=$sysDir/sbin
fi
if [[ -z $jarsSysDir ]] ; then
    jarsSysDir=$sysDir/lib
fi
if [[ -z $rLibSysDir ]] ; then
    rLibSysDir=$sysDir/lib/R/site-library/
fi
if [[ -z $srcSysDir ]] ; then
    srcSysDir=$sysDir/src
fi

mkdir -p $binSysDir $sbinSysDir \
      $jarsSysDir $rLibSysDir $srcSysDir

function discoverSparkSrc() {
    candCnt=$(listSparkSrcCands | wc -l)
    if [[ $candCnt -eq 0 ]] ; then
	canonApacheUrl
    elif [[ $candCnt -eq 1 ]] ; then
	listSparkSrcCands
    else
	local bestCand=$(listSparkSrcCands | sort -V | tail -n 1)
	echo "Spark Installer Warning: Multiple Spark Home candidates in" \
	     $srcSysDir "Using $bestCand" >&2
	echo $bestCand
    fi
}

function canonApacheUrl() {
    version=$(checkLatestVersion)
    echo https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-without-hadoop.tgz
}

function checkLatestVersion() {
    curl https://spark.apache.org/downloads.html \
	| grep "Latest Release" | sed 's+.*(Spark \([0-9.]*\).*+\1+'
}

function listSparkSrcCands() {
    shopt -s dotglob
    if [[ -d $srcSysDir ]] ; then
	ls -d $srcSysDir/*/ | grep -i spark
    fi
}

function unpackHomeDir() {
    local installSrc=$1
    if [[ -d $installSrc ]] ; then
	unpackDirHome $installSrc
    elif [[ -e $installSrc ]] ; then
	unpackArchiveHome $installSrc
    elif isUrl $installSrc ; then
	unpackUrl $installSrc
    else 
	echo "Spark Installer Error: Install source ($installSrc) not" \
	     "present" >&2
	exit 1
    fi
}

function isUrl() {
    local installSrc=$1
    echo $installSrc | egrep -q "^[a-z]*://"
}

function unpackUrl() {
    local installSrc=$1
    local installName=$(basename $installSrc)
    local downloadPath=$srcSysDir/$installName
    mkdir -p $srcSysDir
    cd $srcSysDir

    if [[ -e $downloadPath ]] ; then
	echo "Spark Installer already has a local copy at $downloadPath" \
	     "Skipping download........" >&2
    else
	wget $installSrc
    fi
    
    if [[ -e $downloadPath ]] ; then
	unpackArchiveHome $downloadPath
	rm $downloadPath
    else
	echo "Spark Installer Error: Failed to download $installSrc" >&2
	exit 1
    fi
}

function unpackDirHome() {
    local installDir=$1
    local parentDir=$(dirname $(readlink -f $installDir))
    local baseName=$(basename $(readlink -f $installDir))
    
    if [[ $parentDir == $srcSysDir ]] ; then
	echo $installDir
    else
	mkdir -p $srcSysDir
	cp -r $installDir -T $srcSysDir/$baseName
	echo $srcSysDir/$baseName
    fi
}

function unpackArchiveHome() {
    installPath=$1
    mkdir -p $srcSysDir
    cd $srcSysDir

    if $(echo $installPath | egrep -q "[.](tar[.]gz|tgz)$") ; then
	local baseDir=$(tarDeclare -xvzf $installPath)
    elif $(echo $installPath | egrep -q "[.]tar$") ; then
	local baseDir=$(tarDeclare -xvf $installPath)
    else
	echo "Spark Installer Error: Unrecognized file archive format:" \
	     $installPath >&2
	exit 1
    fi
    echo $srcSysDir/$baseDir
}

# We want to output the name of the unpacked directory, but want tar
# to fully unpack. So don't pipe directly to `head` or else tar will
# close with a SIGPIPE before finishing. 
function tarDeclare() {
    tarFlags=$1
    installPath=$2
    tar $tarFlags $installPath | \
	perl -ne 'BEGIN{ $onFirst = 1;} if ($onFirst) { print $_; $onFirst=0;}'
}

function linkFlatSrcHome() {
    local sparkHome=$1
    srcDir=$(dirname $sparkHome)
    homeName=$(basename $sparkHome)
    if [[ $srcDir != $srcSysDir ]] ; then
	echo "Spark Intaller Internal Error: Unpacked SPARK_HOME not in" \
	     "$srcSysDir: SPARK_HOME=$sparkHome" >&2
	exit 1
    elif [[ $homeName != spark ]] ; then
	cd $srcSysDir
	[[ -h spark ]] && unlink spark
	ln -s $homeName spark
    fi
    echo $srcSysDir/spark
}

function pointBinsToHome() {
    local sparkHome=$1
    for bin in $(importantSparkBins) ; do
	binPath=$sparkHome/bin/$bin
	dereferenceBash $sparkHome $binPath > $binSysDir/$bin
	chmod u+x $binSysDir/$bin
    done
}

function importantSparkBins() {
    echo beeline
    echo pyspark
    echo spark-class
    echo sparkR
    echo spark-shell
    echo spark-sql
    echo spark-submit
}

function dereferenceBash() {
    local binPath=$1
    echo "#!/bin/bash -eu"
    echo $binPath \$@
}

function pointSBinsToHome() {
    local sparkHome=$1
    wordRefBash $sparkHome/sbin/ > $sbinSysDir/spark-adm
    chmod u+x $sbinSysDir/spark-adm
}

function wordRefBash() {
    local cmdDir=$1
    echo "#!/bin/bash -eu"
    echo "$cmdDir/\$1.sh \$@"
}

function linkJarsToHome() {
    local sparkHome=$1
    [[ -L $jarsSysDir/spark ]] && unlink $jarsSysDir/spark
    ln -s $sparkHome/jars/ $jarsSysDir/spark
}

function linkRLibsToHome() {
    local sparkHome=$1
    [[ -L $rLibSysDir/SparkR ]] && unlink $rLibSysDir
    ln -s $sparkHome/R/lib/SparkR/ $rLibSysDir/SparkR
}

if [[ -z $installSrc ]] ; then
    installSrc=$(discoverSparkSrc)
fi

canonSparkHome=$(unpackHomeDir $installSrc)
sparkHome=$(linkFlatSrcHome $canonSparkHome)

pointBinsToHome $sparkHome
pointSBinsToHome $sparkHome
linkJarsToHome $sparkHome
linkRLibsToHome $sparkHome

