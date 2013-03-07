#!/usr/bin/env phantomjs-1.8.2-linux-x86_64/bin/phantomjs
#
# By Vlad Verestiuc <vvlad@me.com> & Bogdan Velcea <phil2k@gmail.com>
#

var system = require('system');
var page = require('webpage').create();
var fs = require('fs');

page.injectJs("./js/jquery-1.9.1.min.js") || (console.log("Unable to load jQuery") && phantom.exit());
page.injectJs("./js/highcharts.js") || (console.log("Unable to load Highcharts") && phantom.exit());
page.injectJs("./js/modules/exporting.js") || (console.log("Unable to load Highcharts") && phantom.exit());

page.onConsoleMessage = function (msg) {
	console.log(msg);
};

phantom.injectJs(system.args[1]) || (console.log("Unable to load json file") && phantom.exit());

var width = 800, height = 400;
if (system.args.length == 4) {
	width = parseInt(system.args[2], 10);
	height = parseInt(system.args[3], 10);
}

console.log("Loaded result file");


var title = "";

var graphit = function (config) {
  if ( $("#container").length == 0 ){
	$('body').append('<div id="container"></div>');
  }
  console.log(config.series);
  var chart = new Highcharts.Chart({
	chart: {
		renderTo: 'container',
		animations: false,
		width: config.width,
		height: config.height,
		type: 'column'
	},
	exporting: {
		enabled: false,
	},
	series: config.series,
	title: {
		text: config.title,
	},
	subtitle: {
	        text: '(using fio)',
        },
	credits: {
		text: "by eMAG.RO",
	},
	plotOptions: {
		column: {
		  pointPadding: 0.2,
                  borderWidth: 0
                  }
	},
	xAxis: {
	        categories: config.categories,
        },
	yAxis: {
	        min: 0,
		title: { text: config.y_title },
	},
   });
  return chart.getSVG();
}

var graph_types = [ "bw", "iops" ]; // by this key will be generated each file
var iosenses = [ "read", "write" ];

/* Here we generate the config to the graph function */
for(gt_idx in graph_types) {
  console.log(gt_idx);
  
  var graph_type = graph_types[gt_idx];
  if (graph_type == 'bw') {
    metric='Throughput';
    unit='mbps';
  } else {
    metric='I/O Rate';
    unit='iops';
  }
  categories = [];
  var category = "";
  series = [];
  opers = []; // keys from iosenses (read/write) => values from each test (a list of categories values)
  
  for(name in tests) { // name will have the name of the test bunches (folder with fio out files)
      if (('category' in tests[name]) && (tests[name]['category'].length)) {
        category = tests[name]['category'];
      }
      categories.push((category.length?category+': ':'')+name);
      
      for(ios_idx in iosenses){ // read , write
        var io_sense = iosenses[ios_idx];
        var key = io_sense + '.' + graph_type;
        
        //console.log("io_sense = "+io_sense);
        if (!(io_sense in opers)) { opers[io_sense]=[]; }
        opers[io_sense].push(tests[name][key]);
      }
  }
  
  var oper;
  for(oper in opers) {
      series.push({
        name: oper,
        data: opers[oper],
      });
  }
      
  config = {
	width: width,
	height: height,
	series: series,
	categories: categories,
	title: (title.length?title+' - ':'') + metric,
	y_title: unit,
  }
  svg = page.evaluate(graphit, config);
  file_name = "./"+graph_type+".svg";
  fs.isFile(file_name) && fs.remove(file_name);
  console.log("Saved SVG to file");
  fs.write(file_name, svg);
  console.log("Writed " + file_name);
}


phantom.exit();
