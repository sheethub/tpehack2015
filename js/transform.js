var get_stops_by_time = function(data, time) {
    var stop_ids = [];
    for (var id in data) {
        if (time < data[id][0].time) {
            continue;
        }
        if (time > data[id][data[id].length - 1].time) {
            continue;
        }
        for (var i = 0; i < data[id].length; i ++) {
            if (time < data[id][i].time) {
                stop_ids.push([data[id][i].stop_id, id]);
                break;
            }
        }
    }
    return stop_ids;
};