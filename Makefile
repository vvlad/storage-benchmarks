



RESULTS := results/local.csv
WORKING_DIR := $(PWD)
.SILENT:

all:
	mkdir -p $(LOCAL_DIR)
	mkdir -p results
	echo $(PWD)
	echo "Running local fs benchmark ... "
	for conf in $$(find conf -type f); do \
		cd $(LOCAL_DIR) && fio $(WORKING_DIR)/$$conf > $(WORKING_DIR)/$$(echo $$conf | sed s/.fio/.out/g | sed s/conf/results/g );\
	done




