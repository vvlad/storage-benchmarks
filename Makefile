


PACKAGES=open-iscsi \
				 bonnie++\
				 ruby\
				 imagemagick


RESULTS := results/local.csv\
					 results/iscsi.csv

LOCAL_DIR := /tmp/bm-test.$$PPID
ISCSI_0_DIR := /media/iscsi/test0/bm-test.$$PPID
.SILENT:

all: prepare test


prepare:
	echo "Installing pre-requirements ... "
	sudo aptitude -y install $(PACKAGES) >/dev/null 2>&1 
	mkdir -p $(LOCAL_DIR)
	mkdir -p $(ISCSI_0_DIR)
	mkdir -p results

results/local.csv:
	echo "Running local fs benchmark ... "
	/usr/sbin/bonnie++ -s 20480 -f -b -q -x 10 -d$(LOCAL_DIR) >results/local.csv

results/iscsi.csv:
	echo "Running iscsi fs benchmark ... "
	/usr/sbin/bonnie++ -s 20480 -f -b -q -x 10 -d$(ISCSI_0_DIR) >results/iscsi.csv



test: $(RESULTS)


