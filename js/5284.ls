_ = require "prelude-ls"



buildMap = (container, mapStyle, position, overlay, callback)->
	map = new google.maps.Map(container, {
		zoom: position.zoom,
		center: new google.maps.LatLng(position.lat, position.lng),
		# disableDefaultUI: true,
		# scrollwheel: false
		# navigationControl: false
		# mapTypeControl: false
		# scaleControl: false
		# draggable: false
		# zoomControl: false
		# disableDoubleClickZoom: true
		mapTypeControlOptions:{
			mapTypeId: [google.maps.MapTypeId.ROADMAP, 'map_style']
		}
	})

	google.maps.event.addListener(map, "bounds_changed", -> 
		bounds = @getBounds!
		northEast = bounds.getNorthEast!
		southWest = bounds.getSouthWest!
		# console.log [(southWest.lng! + northEast.lng!) / 2, (southWest.lat! + northEast.lat!) / 2]
	)

	map.mapTypes.set('map_style', mapStyle)
	map.setMapTypeId('map_style')



	if overlay is not undefined then overlay.setMap map
	# google.maps.event.addListenerOnce map, 'idle', callback


buildOverlay = ->
	pathOverlay = new google.maps.OverlayView!
	buildOverlay.mapOffset = 4000
	pathOverlay.cellOperation = null
	pathOverlay.svg = null

	appendSVG = (that, offset)->
		svg = d3.select(that.getPanes!.overlayMouseTarget).append("div")
			.attr("class", "mapOverlay")
			.append "svg"

		group = svg.append "g"
			.attr {
				"class" "gPrints"
			}
		svg
			.attr {
				"width": offset * 2
				"height": offset * 2
			}
			.style {
				"position": "absolute"
				"top": -1 * offset + "px"
				"left": -1 * offset + "px"
			}
		group

	pathOverlay.onAdd = ->
		pathOverlay.svg := appendSVG @, buildOverlay.mapOffset

		pathOverlay.draw = ->
			projection = @getProjection!

			pathOverlay.googleMapProjection = (coordinates)->
				googleCoordinates = new google.maps.LatLng(coordinates[1], coordinates[0])
				pixelCoordinates = projection.fromLatLngToDivPixel googleCoordinates
				[pixelCoordinates.x + buildOverlay.mapOffset, pixelCoordinates.y + buildOverlay.mapOffset]
			drawMap!

	pathOverlay

d3.selectAll '#map'
	.style {
		"height": "500px"
		"width": "500px"
	}
container = d3.selectAll '#map' .node!
taipeiPosition = {zoom: 12, lat: 25.018675536420737, lng: 121.50900989257809}
darkMapStyle = new google.maps.StyledMapType([
	{"featureType":"all","elementType":"all","stylers":[{"visibility":"off"},{"color":'#000000'},{"saturation":-100},{"lightness":33},{"gamma":0.5}]},
	{"featureType":"landscape.natural","elementType":"all","stylers":[{"visibility":"on"}]},
	{"featureType":"water","elementType":"geometry.fill","stylers":[{"visibility":"on"},{"color":'#3887be'}]},
	# {"featureType":"water","elementType":"geometry.fill","stylers":[{"visibility":"on"},{"color":'#000000'}]},
	],
	{name: "Styled Map"}
	)
 
overlay = buildOverlay!

buildingMap = (callback)-> 
	(buildMap container, darkMapStyle, taipeiPosition, overlay, callback)


readFile = (file, callback)->
	err, geojson <- d3.json "./data/" + file
	geojson["features"]
	|> _.map (-> it["geometry"] |> callback )

breakdown = (object)->
	# object |> console.log 
	if object.type is "GeometryCollection"
		object["geometries"] |> _.map (-> it |> breakdown)
	else 
		decide object

decide = (object)	->
	if object.type is "Point" then drawPoint object
	else if object.type is "LineString" then drawLineString object
	else if object.type is "Polygon" then drawPolygon object

# list
# |> _.map (-> 
# 	it |>  readFile _, breakdown)


# Latitude: 25.053135
# Longitude: 121.549112

bus2Geojson = (busdata)->
	busdata.BusInfo
	|> _.map ((cell)->
		{
			"type":"Feature"
			"geometry": {
				"type": "Point"
				"coordinates": [cell.Longitude, cell.Latitude]
			}
			"properties": cell
		}
		)
	|> (->
		{
			"type": "FeatureCollection"
			"features": it
		}
		)


stops2Geojson = (busdata)->
	busdata
	|> _.map ((cell)->
		{
			"type":"Feature"
			"geometry": {
				"type": "Point"
				"coordinates": [cell.showLon, cell.showLat]
			}
			"properties": cell
		}
		)
	|> (->
		{
			"type": "FeatureCollection"
			"features": it
		}
		)



blowBus = ->
	it
		.style {
			"opacity": 1
			"stroke-width": "5px"
			"stroke": "white"
		}
		.attr {
			"stroke-dasharray": -> 20 + " " + @.getTotalLength!
			"stroke-dashoffset": -> 20
			"shape-rendering": "geometricPrecision"
		}
		.transition!
		.ease 'linear'
		.duration -> (@.getTotalLength! * 3)
		.delay (it, i)-> i * 2000 * Math.random!
		.attr {
			"stroke-dashoffset": -> -@.getTotalLength!
			### 0
		}
		# .transition!
		# .duration 1000
		# .style {
		# 	"opacity": 0
		# }
		.each "end", -> 
			d3.select @
			.call blowBus



drawMap = ->

	err, busData <- d3.json "./data/307.json"
	path = d3.geo.path!.projection overlay.googleMapProjection
	geojson = busData



	err, stops <- d3.csv "./data/stop.csv"

	geoStops = stops
		.filter (it, i)->
			it.seqNo = + it.seqNo
			true
	|> _.sort-by ( .seqNo )
	|> stops2Geojson


	pathStyle = ->
		it
			.style {
				"fill": "none"
				"stroke": "rgb(164, 51, 216)"
				"stroke-width": "5px" ### "10px" # "1px"
				"mix-blend-mode": "screen" ## look great on safari
				"opacity": 1
			}

	w = overlay.svg
		.selectAll ".basePath"
		.data geojson.features

	w
		.attr "d", path
		.call pathStyle

	w
		.enter!
		.append "path"
		.attr "d", path
		.attr {
			"class": "basePath"
		}
		.call pathStyle
		

	# p = overlay.svg
	# 	.selectAll ".flow"
	# 	.data geojson.features
	# 	# (topojson.feature geojson, geojson["objects"]["臺北市公車路線圖"])["features"]

	# p
	# 	.attr "d", path
	# 	.call pathStyle
	# 	.call blowBus

	# p
	# 	.enter!
	# 	.append "path"
	# 	.attr "d", path	
	# 	.attr {
	# 		"class": "flow"
	# 	}
	# 	.call pathStyle
	# 	.call blowBus


	stopsStyle = ->
		it
			.style {
				"fill": "white"
			}
			.style {
				"opacity": 0
			}

	s = overlay.svg
		.selectAll ".stops"
		.data geoStops.features

	s
		.attr {
			"d": path
		}
		.call stopsStyle

	s
		.enter!
		.append "path"
		.attr {
			"d": path
			"class": (it, i)-> "stops stops" + it.properties.stopId
		}
		.call stopsStyle
		
	


		

	

buildingMap drawMap