
install [phantomjs](http://phantomjs.org/download.html)
you should first storage-benchmarks (https://github.com/vvlad/storage-benchmarks), and each result you should name it to a folder like "category.results", where category but be a name/description of those tests (ex.: "amazon-cloud.results")

    ./bin/parse_fio.pl -j fio_tests1_dir fio_tests2_dir ... > ./graps/data.json
    ./graphs/graphs.js ./graphs/data.json
