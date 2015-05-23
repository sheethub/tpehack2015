var _, side, svgMouseMove, svg;
_ = require("prelude-ls");
side = {};
side.ctn_w = 700;
side.ctn_h = 3000;
side.svg_margin = {
  top: 80,
  left: 100,
  right: 20,
  bottom: 20
};
side.svg_w = side.ctn_w - side.svg_margin.left - side.svg_margin.right;
side.svg_h = side.ctn_h - side.svg_margin.top - side.svg_margin.bottom;
svgMouseMove = null;
svg = d3.selectAll(".sideCol").append("svg").attr({
  "width": side.svg_w + side.svg_margin.left + side.svg_margin.right + "px",
  "height": side.svg_h + side.svg_margin.top + side.svg_margin.bottom + "px"
}).on("mousemove", function(){
  return svgMouseMove(this);
}).append("g").attr({
  "transform": "translate(" + side.svg_margin.left + "," + side.svg_margin.top + ")"
});
d3.csv("./data/stop.csv", function(err, stops){
  var getStops;
  stops = _.sortBy(function(it){
    return it.seqNo;
  })(
  stops.filter(function(it, i){
    it.seqNo = +it.seqNo;
    return true;
  }));
  getStops = function(stopId){
    var rlst;
    rlst = stops.filter(function(it, i){
      return it.stopId === stopId + "";
    });
    return rlst[0]["nameZh"];
  };
  return d3.json("./data/schedule.json", function(err, schedule){
    var Oschedule, lsKeys, stopData, lsBusStop, flatStopData, stopScale, stopScaleInvert, timeScale, busPath, listColor, color, yAxis;
    Oschedule = JSON.parse(
    JSON.stringify(
    schedule));
    lsKeys = _.Obj.keys(
    schedule);
    stopData = function(it){
      return it.map(function(row, idx){
        return _.map(function(cell){
          cell.busID = lsKeys[idx];
          cell.time = new Date(cell.time * 1000);
          return cell;
        })(
        row);
      });
    }(
    _.Obj.values(
    schedule));
    lsBusStop = [15294, 15296, 15298, 15299, 15300, 15301, 15302, 15303, 15304, 15305, 15306, 15307, 15308, 15309, 15310, 15311, 15312, 15313, 15314, 15315, 15316, 15317, 15318, 15319, 15320, 15321, 15322, 15323, 15324, 15325, 15326, 15327, 15328, 15329, 15330, 15331, 15332, 15333, 15334, 15335, 15336, 15337, 15338, 15339, 15340, 15382, 15383, 15384, 153797, 153798, 15385, 59444, 15386, 15387, 15388, 15389, 15390, 15391, 15392, 15394, 21594];
    flatStopData = _.flatten(
    stopData);
    stopScale = d3.scale.ordinal().domain(lsBusStop).rangePoints([0, side.svg_w]);
    stopScaleInvert = function(x){
      var l, w, j, rslt;
      l = stopScale.range();
      w = stopScale.rangeBand();
      j = 0;
      while (x > l[j] + w) {
        ++j;
      }
      rslt = stopScale.domain()[j];
      if (rslt === undefined) {
        return "_";
      } else {
        return rslt;
      }
    };
    timeScale = d3.time.scale().domain(d3.extent(flatStopData, function(it){
      return it.time;
    })).range([0, side.svg_h]);
    busPath = d3.svg.line().x(function(it){
      return stopScale(
      it.stop_id);
    }).y(function(it){
      return timeScale(
      it.time);
    });
    svgMouseMove = function(that){
      var y, x, hour, listBus;
      y = d3.mouse(that)[1] - side.svg_margin.top;
      x = d3.mouse(that)[0] - side.svg_margin.left;
      hour = d3.time.format('%I:%M');
      d3.selectAll(".horizon").attr({
        "y1": y,
        "y2": y
      }).style({
        "opacity": 1
      }).transition().duration(3000).transition().style({
        "opacity": 0
      });
      d3.selectAll(".timeTick").style({
        "opacity": 1
      }).attr({
        "y": y
      }).text(hour(
      timeScale.invert(
      y)));
      listBus = _.join(",")(
      _.map(function(it){
        return ".stops" + it;
      })(
      _.map(function(it){
        return it[0];
      })(
      get_stops_by_time(Oschedule, function(it){
        return it.getTime() / 1000;
      }(
      timeScale.invert(
      y))))));
      console.log(
      listBus);
      d3.selectAll('#bus_stop_name').text("站名：" + getStops(
      stopScaleInvert(
      x)));
      d3.selectAll(".stops").style({
        "opacity": 0
      });
      return d3.selectAll(listBus).style({
        "opacity": 1
      });
    };
    svg.append("line").attr({
      "class": "horizon",
      "x1": 0,
      "x2": side.svg_w,
      "y1": 0,
      "y2": 0
    }).style({
      "stroke-width": "3px",
      "stroke": "white"
    }).attr({
      "opacity": 0
    });
    listColor = ["yellow", "yellow", "yellow", "yellow"];
    color = d3.scale.category10();
    svg.selectAll("path").data(stopData).enter().append("path").attr({
      "d": busPath
    }).style({
      "stroke": function(it){
        var c;
        c = it["0"]["busID"].split(":")["1"];
        return listColor[c];
      },
      "stroke-width": "3px",
      "fill": "none",
      "opacity": 1
    }).on("mousedown", function(){
      return d3.selectAll('#bus_name').text(" / 公車班次:" + d3.select(this).data()[0][0]["busID"]);
    });
    yAxis = d3.svg.axis().scale(timeScale).orient("left");
    svg.append("g").attr({
      "transform": "translate(0,0)",
      "class": "y axis"
    }).call(yAxis);
    return d3.selectAll(".y.axis").append("text").style({
      "text-anchor": "end",
      "opacity": 0
    }).attr({
      "x": "-10",
      "class": "timeTick"
    });
  });
});