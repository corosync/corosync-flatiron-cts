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
#

# required packages
which mock >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo 'please install mock (yum install mock).'
        exit 1
fi
MOCK=$(which mock)

if [ -z "$TARGET" ]
then
	TARGET=rhel-6-x86_64
fi

RPM_DIR=/var/lib/mock/$TARGET/result
if [ ! -d $RPM_DIR ]
then
	$MOCK -v -r $TARGET --init
fi

if [ -z "$COROSYNC_DIR" ]
then
	COROSYNC_DIR=~/corosync
fi

if [ -z "$COROSYNC_CTS_DIR" ]
then
	COROSYNC_CTS_DIR=~/corosync-flatiron-cts
fi
set -e

for d in $COROSYNC_DIR $COROSYNC_CTS_DIR
do
	cd $d
	echo $d': running autogen ...'
	./autogen.sh
	echo $d': running configure ...'
	./configure 
	echo $d': building source rpm'
	rm -f *.src.rpm
	make srpm 
	SRPM=$(ls *src.rpm)
	if [ ! -f $SRPM ]
	then
		echo $0:$d no source rpm to build from!
		exit 1
	fi

	echo "$d: running mock rebuild ($SRPM)"
	$MOCK -v --no-clean -r $TARGET --rebuild $SRPM

	cd -
done

if [ -z "$TEST_NODES" ]
then
	echo no test nodes, exiting without running cts.
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


echo installing $RPM_LIST
echo onto the test nodes $TEST_NODES

# load and install rpm(s) onto the nodes
for n in $TEST_NODES
do
	ssh $n "rm -rf /tmp/corosync*.rpm"
	scp $RPM_LIST $n:/tmp/
        ssh $n "rpm --nodeps --force -Uvf /tmp/corosync*.rpm"
done

echo 'running test ...'
rm -f cts.log
pushd cts
# needs sudo to read /var/log/messages
sudo -n ./corolab.py --nodes "$TEST_NODES" --outputfile ../cts.log
popd

