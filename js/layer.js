var _, buildMap, buildOverlay, container, taipeiPosition, darkMapStyle, overlay, buildingMap, readFile, breakdown, decide, bus2Geojson, drawMap;
_ = require("prelude-ls");
console.log(
h337);
buildMap = function(container, mapStyle, position, overlay, callback){
  var map, heatmap, testData;
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
  heatmap = new HeatmapOverlay(map, {
    "radius": 2,
    "maxOpacity": 1,
    "scaleRadius": true,
    "useLocalExtrema": true,
    "latField": "lat",
    "lngField": "lng",
    "valueField": "count"
  });
  testData = {
    "max": 8,
    "data": [{
      "lat": 25.03930553101857,
      "lng": 121.53578906738278,
      "count": 1
    }]
  };
  heatmap.setData(testData);
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
  "height": "1000px",
  "width": "1000px"
});
container = d3.selectAll('#map').node();
taipeiPosition = {
  zoom: 13,
  lat: 25.03930553101857,
  lng: 121.53578906738278
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
      }
    };
  })(
  busdata.BusInfo));
};
drawMap = function(){
  return d3.json("./data/BusData.json", function(err, busData){
    var geojson, path, pathStyle, p;
    geojson = bus2Geojson(
    busData);
    path = d3.geo.path().projection(overlay.googleMapProjection);
    pathStyle = function(it){
      return it.style({
        "fill": "none",
        "stroke": "white"
      });
    };
    p = overlay.svg.selectAll("path").data(geojson.features);
    p.attr("d", path).call(pathStyle);
    return p.enter().append("path").attr("d", path).call(pathStyle);
  });
};
buildingMap(drawMap);