#!/bin/sh
#
# This script is called by buildbot to test
# corosync. It is run continously to help catch regressions.
#
# ENVIRONMENT variables that affect it's behaviour:
#
# TEST_NODES - the hostnames of the nodes to be tested
# TARGET - this is used by mock so look in /etc/mock for
#          possible options.
# COROSYNC_DIR path to corosync dir
# COROSYNC_CTS_DIR path to corosync-flatiron-cts dir
#

LOG="echo CTS: "

# required packages
which mock >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo 'please install mock (yum install mock).'
        exit 1
fi
MOCK=/usr/bin/mock

if [ -z "$TARGET" ]
then
	TARGET=rhel-6-x86_64-core
fi

RPM_DIR=/var/lib/mock/$TARGET/result
if [ ! -d $RPM_DIR ]
then
	$MOCK -v -r $TARGET --init
else
	rm -f $RPM_DIR/corosync*.rpm
fi

if [ -z "$COROSYNC_CTS_DIR" ]
then
	COROSYNC_CTS_DIR=$(pwd)/../corosync-flatiron-cts
fi

if [ -z "$COROSYNC_DIR" ]
then
	COROSYNC_DIR=$(pwd)
fi

echo COROSYNC_CTS_DIR is $COROSYNC_CTS_DIR
echo COROSYNC_DIR is $COROSYNC_DIR

if [ ! -d $COROSYNC_CTS_DIR ]
then
	git clone git://corosync.org/corosync-flatiron-cts.git $COROSYNC_CTS_DIR
	cd $COROSYNC_CTS_DIR
else
	cd $COROSYNC_CTS_DIR
	git checkout -f
	git clean -dfx
	git pull
fi
cd -

set -e

for d in $COROSYNC_DIR $COROSYNC_CTS_DIR
do
	cd $d
	$LOG "in dir $d"
	git clean -dfx
	$LOG 'running autogen ...'
	./autogen.sh
	$LOG 'running configure ...'
	./configure 
	$LOG 'building source rpm'
	rm -f *.src.rpm
	make srpm 
	SRPM=$(ls *src.rpm)
	if [ ! -f $SRPM ]
	then
		$LOG no source rpm to build from!
		exit 1
	fi

	$LOG "running mock rebuild ($SRPM)"
	$MOCK -v --no-clean -r $TARGET --rebuild $SRPM

	cd -
done

if [ -z "$TEST_NODES" ]
then
	$LOG no test nodes, exiting without running cts.
	exit 0
else
	# start the VMs, or leave them running?
	true
fi

RPM_LIST=
for r in $RPM_DIR/corosync*.rpm
do
	case $r in
		*src.rpm)
	;;
		*-devel-*)
	;;
		*)
		RPM_LIST="$RPM_LIST $r"
	;;
	esac
done

$LOG installing $RPM_LIST
$LOG onto the test nodes $TEST_NODES

# load and install rpm(s) onto the nodes
for n in $TEST_NODES
do
	$LOG "Installing onto $n"
	ssh $n "rm -rf /tmp/corosync*.rpm"
	scp $RPM_LIST $n:/tmp/
        ssh $n "rpm --nodeps --force -Uvf /tmp/corosync*.rpm"
done

cd $COROSYNC_CTS_DIR
$LOG 'running CTS ...'
CTS_LOG=$(pwd)/cts.log
rm -f $CTS_LOG

cd cts
# needs sudo to read /var/log/messages
sudo -n ./corolab.py --nodes "$TEST_NODES" --outputfile $CTS_LOG

