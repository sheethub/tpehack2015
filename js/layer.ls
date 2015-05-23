_ = require "prelude-ls"


h337
|> console.log 

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
		### console.log [(southWest.lng! + northEast.lng!) / 2, (southWest.lat! + northEast.lat!) / 2]
	)

	map.mapTypes.set('map_style', mapStyle)
	map.setMapTypeId('map_style')


	heatmap = new HeatmapOverlay map, {
		"radius": 2
		"maxOpacity": 1
		"scaleRadius": true
		"useLocalExtrema": true
		"latField": "lat"
		"lngField": "lng"
		"valueField": "count"
	}
	testData = {
		"max": 8
		"data": [
			{
				"lat": 25.03930553101857
				"lng": 121.53578906738278
				"count": 1
			}
		]
	}

	heatmap.setData testData


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
		"height": "1000px"
		"width": "1000px"
	}
container = d3.selectAll '#map' .node!
taipeiPosition = {zoom: 13, lat: 25.03930553101857, lng: 121.53578906738278}
darkMapStyle = new google.maps.StyledMapType([
	{"featureType":"all","elementType":"all","stylers":[{"visibility":"off"},{"color":'#000000'},{"saturation":-100},{"lightness":33},{"gamma":0.5}]},
	{"featureType":"landscape.natural","elementType":"all","stylers":[{"visibility":"on"}]},
	{"featureType":"water","elementType":"geometry.fill","stylers":[{"visibility":"on"},{"color":'#3887be'}]},
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
		}
		)
	|> (->
		{
			"type": "FeatureCollection"
			"features": it
		}
		)



drawMap = ->
	### overlay.svg
	### overlay.googleMapProjection
#		 err, geojson <- d3.json "./data/臺北市健保特約藥局.json"
	# # "./data/blur_light_bus.json"
	# #	"./data/5284公車路線圖.json"
	# # "./data/單一縣市界圖.json"
	# # "./data/單一公車路線.json"


	err, busData <- d3.json "./data/BusData.json"
	geojson = busData |> bus2Geojson	
	path = d3.geo.path!.projection overlay.googleMapProjection

	# HeatmapOverlay
	# # |> console.log 


	pathStyle = ->
		it
			.style {
				"fill": "none"
				"stroke": "white"
			}
			# .style {
			# 	"fill": "yellow"
			# 	"opacity": 0.2
			# }

	p = overlay.svg
		.selectAll "path"
		.data geojson.features
		# (topojson.feature geojson, geojson["objects"]["臺北市公車路線圖"])["features"]
	p
		.attr "d", path
		.call pathStyle
	p
		.enter!
		.append "path"
		.attr "d", path	
		.call pathStyle

buildingMap drawMap