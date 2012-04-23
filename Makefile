


PACKAGES=fio


RESULTS := results/local.csv

LOCAL_DIR := /tmp/bm-test.$$PPID
ISCSI_0_DIR := /media/iscsi/test0/bm-test.$$PPID
.SILENT:

all:
	echo "Installing pre-requirements ... "
	sudo apt-get -y install $(PACKAGES) >/dev/null 2>&1 
	mkdir -p $(LOCAL_DIR)
	mkdir -p results
	echo "Running local fs benchmark ... "
	for conf in $$(find conf -type f); do \
		fio $$conf > $$(echo $$conf | sed s/.fio/.out/g | sed s/conf/results/g );\
	done




