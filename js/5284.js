var _, buildMap, buildOverlay, container, taipeiPosition, darkMapStyle, overlay, buildingMap, readFile, breakdown, decide, bus2Geojson, stops2Geojson, blowBus, drawMap;
_ = require("prelude-ls");
buildMap = function(container, mapStyle, position, overlay, callback){
  var map;
  map = new google.maps.Map(container, {
    zoom: position.zoom,
    center: new google.maps.LatLng(position.lat, position.lng),
    mapTypeControlOptions: {
      mapTypeId: [google.maps.MapTypeId.ROADMAP, 'map_style']
    }
  });
  google.maps.event.addListener(map, "bounds_changed", function(){
    var bounds, northEast, southWest;
    bounds = this.getBounds();
    northEast = bounds.getNorthEast();
    return southWest = bounds.getSouthWest();
  });
  map.mapTypes.set('map_style', mapStyle);
  map.setMapTypeId('map_style');
  if (overlay !== undefined) {
    return overlay.setMap(map);
  }
};
buildOverlay = function(){
  var pathOverlay, appendSVG;
  pathOverlay = new google.maps.OverlayView();
  buildOverlay.mapOffset = 4000;
  pathOverlay.cellOperation = null;
  pathOverlay.svg = null;
  appendSVG = function(that, offset){
    var svg, group;
    svg = d3.select(that.getPanes().overlayMouseTarget).append("div").attr("class", "mapOverlay").append("svg");
    group = svg.append("g").attr({
      "class": "class",
      "gPrints": "gPrints"
    });
    svg.attr({
      "width": offset * 2,
      "height": offset * 2
    }).style({
      "position": "absolute",
      "top": -1 * offset + "px",
      "left": -1 * offset + "px"
    });
    return group;
  };
  pathOverlay.onAdd = function(){
    pathOverlay.svg = appendSVG(this, buildOverlay.mapOffset);
    return pathOverlay.draw = function(){
      var projection;
      projection = this.getProjection();
      pathOverlay.googleMapProjection = function(coordinates){
        var googleCoordinates, pixelCoordinates;
        googleCoordinates = new google.maps.LatLng(coordinates[1], coordinates[0]);
        pixelCoordinates = projection.fromLatLngToDivPixel(googleCoordinates);
        return [pixelCoordinates.x + buildOverlay.mapOffset, pixelCoordinates.y + buildOverlay.mapOffset];
      };
      return drawMap();
    };
  };
  return pathOverlay;
};
d3.selectAll('#map').style({
  "height": "500px",
  "width": "500px"
});
container = d3.selectAll('#map').node();
taipeiPosition = {
  zoom: 12,
  lat: 25.018675536420737,
  lng: 121.50900989257809
};
darkMapStyle = new google.maps.StyledMapType([
  {
    "featureType": "all",
    "elementType": "all",
    "stylers": [
      {
        "visibility": "off"
      }, {
        "color": '#000000'
      }, {
        "saturation": -100
      }, {
        "lightness": 33
      }, {
        "gamma": 0.5
      }
    ]
  }, {
    "featureType": "landscape.natural",
    "elementType": "all",
    "stylers": [{
      "visibility": "on"
    }]
  }, {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "visibility": "on"
      }, {
        "color": '#3887be'
      }
    ]
  }
], {
  name: "Styled Map"
});
overlay = buildOverlay();
buildingMap = function(callback){
  return buildMap(container, darkMapStyle, taipeiPosition, overlay, callback);
};
readFile = function(file, callback){
  return d3.json("./data/" + file, function(err, geojson){
    return _.map(function(it){
      return callback(
      it["geometry"]);
    })(
    geojson["features"]);
  });
};
breakdown = function(object){
  if (object.type === "GeometryCollection") {
    return _.map(function(it){
      return breakdown(
      it);
    })(
    object["geometries"]);
  } else {
    return decide(object);
  }
};
decide = function(object){
  if (object.type === "Point") {
    return drawPoint(object);
  } else if (object.type === "LineString") {
    return drawLineString(object);
  } else if (object.type === "Polygon") {
    return drawPolygon(object);
  }
};
bus2Geojson = function(busdata){
  return function(it){
    return {
      "type": "FeatureCollection",
      "features": it
    };
  }(
  _.map(function(cell){
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [cell.Longitude, cell.Latitude]
      },
      "properties": cell
    };
  })(
  busdata.BusInfo));
};
stops2Geojson = function(busdata){
  return function(it){
    return {
      "type": "FeatureCollection",
      "features": it
    };
  }(
  _.map(function(cell){
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [cell.showLon, cell.showLat]
      },
      "properties": cell
    };
  })(
  busdata));
};
blowBus = function(it){
  return it.style({
    "opacity": 1,
    "stroke-width": "5px",
    "stroke": "white"
  }).attr({
    "stroke-dasharray": function(){
      return 20 + " " + this.getTotalLength();
    },
    "stroke-dashoffset": function(){
      return 20;
    },
    "shape-rendering": "geometricPrecision"
  }).transition().ease('linear').duration(function(){
    return this.getTotalLength() * 3;
  }).delay(function(it, i){
    return i * 2000 * Math.random();
  }).attr({
    "stroke-dashoffset": function(){
      return -this.getTotalLength();
    }
  }).each("end", function(){
    return d3.select(this).call(blowBus);
  });
};
drawMap = function(){
  return d3.json("./data/307.json", function(err, busData){
    var path, geojson;
    path = d3.geo.path().projection(overlay.googleMapProjection);
    geojson = busData;
    return d3.csv("./data/stop.csv", function(err, stops){
      var geoStops, pathStyle, w, stopsStyle, s;
      geoStops = stops2Geojson(
      _.sortBy(function(it){
        return it.seqNo;
      })(
      stops.filter(function(it, i){
        it.seqNo = +it.seqNo;
        return true;
      })));
      pathStyle = function(it){
        return it.style({
          "fill": "none",
          "stroke": "rgb(164, 51, 216)",
          "stroke-width": "5px",
          "mix-blend-mode": "screen",
          "opacity": 1
        });
      };
      w = overlay.svg.selectAll(".basePath").data(geojson.features);
      w.attr("d", path).call(pathStyle);
      w.enter().append("path").attr("d", path).attr({
        "class": "basePath"
      }).call(pathStyle);
      stopsStyle = function(it){
        return it.style({
          "fill": "white"
        }).style({
          "opacity": 0
        });
      };
      s = overlay.svg.selectAll(".stops").data(geoStops.features);
      s.attr({
        "d": path
      }).call(stopsStyle);
      return s.enter().append("path").attr({
        "d": path,
        "class": function(it, i){
          return "stops stops" + it.properties.stopId;
        }
      }).call(stopsStyle);
    });
  });
};
buildingMap(drawMap);