_ = require "prelude-ls"


side = {}

side.ctn_w = 700
side.ctn_h = 3000

side.svg_margin = {top: 80, left: 100, right: 20, bottom: 20}
side.svg_w = side.ctn_w - side.svg_margin.left - side.svg_margin.right
side.svg_h = side.ctn_h - side.svg_margin.top - side.svg_margin.bottom
svgMouseMove = null

svg = d3.selectAll ".sideCol"
	.append "svg"
	.attr {
		"width": side.svg_w + side.svg_margin.left + side.svg_margin.right + "px"
		"height": side.svg_h + side.svg_margin.top + side.svg_margin.bottom +  "px"
	}
	.on "mousemove", -> svgMouseMove @
	.append "g"
	.attr {
		"transform": "translate(" + side.svg_margin.left + "," + side.svg_margin.top + ")"
	}

### svg
### 	.append "defs"
### 	.append "clipPath"
### 	.attr {
### 		"id": "area"
### 	}
### 	.append "rect"
### 	.attr {
### 		"x": 0
### 		"y": 0
### 		"width": side.svg_w
### 		"height": side.svg_h
### 	}


# stopsName = [1 to 30]
# |> _.map -> "a" + it

## [
## 	{
## 		"busID": "a"
## 		"stopID": "1"
## 		"time": new Date!
## 	}
## ]



err, stops <- d3.csv "./data/stop.csv"

stops = stops
	.filter (it, i)->
		it.seqNo = + it.seqNo
		true
|> _.sort-by ( .seqNo )

# stops |> console.log 

getStops = (stopId)->
	# console.log stopId
	rlst = stops.filter (it, i)->
		it.stopId is (stopId + "")
	rlst[0]["nameZh"]


err, schedule <- d3.json "./data/schedule.json"

Oschedule = schedule
|> JSON.stringify
|> JSON.parse





lsKeys = schedule |> _.Obj.keys


stopData = schedule
|> _.Obj.values
|> (-> it.map (row, idx)->
	row
	|> _.map ((cell)->

		cell.busID = lsKeys[idx]
		cell.time = new Date (cell.time * 1000)
		cell
		)
	)
# |> _.drop 2
# |> _.take 1

lsBusStop = [15294,15296,15298,15299,15300,15301,15302,15303,15304,15305,15306,15307,15308,15309,15310,15311,15312,15313,15314,15315,15316,15317,15318,15319,15320,15321,15322,15323,15324,15325,15326,15327,15328,15329,15330,15331,15332,15333,15334,15335,15336,15337,15338,15339,15340,15382,15383,15384,153797,153798,15385,59444,15386,15387,15388,15389,15390,15391,15392,15394,21594]


# stopData |> console.log 


#sBusStop  = stopData
# |> (-> 
# 	it[0]
# 	|> _.map ( .stop_id )
# 	)



# stopData
# |> console.log 

# lsBusStop
# |> console.log 

# # # baseDate = new Date ("2015/05/23 06:00:00")
# # # lsBusStop = [1 to 40]

# # # stopData = [1 to 30]
# # # 	# [1 to 600]
# # # |> _.map ((bus)->
# # # 	lsBusStop
# # # 	|> _.map (stop)->
# # # 		{
# # # 			"busID": bus
# # # 			"stopID": stop
# # # 			"time": new Date(baseDate.getTime! + (((bus * 3) + stop * 1 + ~~(Math.random! * 2)) * 60000))
# # # 		}
# # # 	)

# # # stopData |> console.log 

flatStopData = stopData |> _.flatten


stopScale = d3.scale.ordinal!
	.domain lsBusStop
	.rangePoints [0, side.svg_w]

stopScaleInvert = (x)->
	l = stopScale.range!
	w = stopScale.rangeBand!

	j = 0
	while (x > (l[j] + w))
		++j

	rslt = stopScale.domain![j]
	if rslt is undefined then "_" else rslt


timeScale = d3.time.scale!
	.domain (d3.extent flatStopData, -> it.time)
	.range [0, side.svg_h]

busPath = d3.svg.line!
	.x -> it.stop_id |> stopScale
	.y -> it.time |> timeScale
	# .interpolate "cardinal"



svgMouseMove := (that)->
	y = (d3.mouse that)[1] - side.svg_margin.top
	x = (d3.mouse that)[0] - side.svg_margin.left
	hour = d3.time.format '%I:%M'
	d3.selectAll ".horizon"
		.attr {
			"y1": y
			"y2": y
		}
		.style {
			"opacity": 1
		}
		.transition!
		.duration 3000
		.transition!
		.style {
			"opacity": 0
		}

	d3.selectAll ".timeTick"
		.style {
			"opacity": 1
		}
		.attr {
			"y": y
		}
		.text (y |> timeScale.invert |> hour)


		listBus = y
		|> timeScale.invert
		|> (-> it.getTime! / 1000)
		|> get_stops_by_time Oschedule, _
		|> _.map (-> it[0])
		|> _.map (-> ".stops" + it)
		|> _.join ","

		listBus |> console.log 

		

	d3.selectAll '#bus_stop_name'
		.text "站名：" + (x |> stopScaleInvert |> getStops)

	d3.selectAll ".stops"
		.style {
			"opacity": 0
		}

	d3.selectAll listBus
	# ".stops" + (x |> stopScaleInvert)
		.style {
			"opacity": 1
		}
		# .transition!
		# .style {
		# 	"stroke-width": 20
		# }
		# .transition!
		# .style {
		# 	"stroke-width": 5
		# }








svg
	.append "line"
	.attr {
		"class": "horizon"
		"x1": 0
		"x2": side.svg_w
		"y1": 0
		"y2": 0
	}
	.style {
		"stroke-width": "3px"
		"stroke": "white"
	}
	.attr {
		"opacity": 0
	}


# listColor = ["white" "yellow" "orange" "red"]
listColor = ["yellow" "yellow" "yellow" "yellow"]

color = d3.scale.category10!

svg
	.selectAll "path"
	.data stopData
	.enter!
	.append "path"
	.attr {
		"d": busPath
	}
	.style {
		# "stroke": -> (it["0"]["busID"].split ":")["1"] |> (-> listColor[it])
		"stroke": -> 
			c = (it["0"]["busID"].split ":")["1"]
			listColor[c]
		"stroke-width": "3px"
		"fill": "none"
		"opacity": 1
	}
	.on "mousedown", ->
		d3.selectAll '#bus_name'
			.text " / 公車班次:" + (d3.select @).data![0][0]["busID"]

		# d3.selectAll '.stops' + (d3.select @).data![0][0]
		


yAxis = d3.svg.axis!
	.scale timeScale
	.orient "left"


svg
	.append "g"
	.attr {
		"transform": "translate(0,0)"
		"class": "y axis"
	}
	.call yAxis

d3.selectAll ".y.axis"
	.append "text"
	.style {
		"text-anchor": "end"
		"opacity": 0
	}
	.attr {
		"x": "-10"
		"class": "timeTick"
	}




# stops |> console.log