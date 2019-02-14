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

function discoverSparkSrc() {
    candCnt=$(listSparkSrcCands | wc -l)
    if [[ $candCnt -eq 1 ]] ; then
	listSparkSrcCands
    elif [[ $candCnt -eq 0 ]] ; then
	echo "Spark Installer Error: No install source argument and no Spark" \
	     "directory in $(srcSysDir)" >&2
	exit 1
    else
	echo "Spark Installer Error: No install source argument and multiple" \
	     "Spark directories in $(srcSysDir)" >&2
	listSparkSrcCands >&2
	exit 1
    fi
}

function listSparkSrcCands() {
    shopt -s dotglob
    if [[ -d $srcSysDir ]] ; then
	ls -d $srcSysDir/spark*/
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
	tar -xvzf $installPath | head -n 1
    elif $(echo $installPath | egrep -q "[.]tar$") ; then
	tar -xvf $installPath | head -n 1
    else
	echo "Spark Installer Error: Unrecognized file archive format:" \
	     $installPath >&2
	exit 1
    fi
}

if [[ -z $installSrc ]] ; then
    installSrc=$(discoverSparkSrc)
fi

canonSparkHome=$(unpackHomeDir $installSrc)

echo $unpackHomeDir

linkFlatSrcHome $canonSparkHome
pointBinsToHome
pointSBinsToHome
linkJarsToHome
linkRLibsToHome

