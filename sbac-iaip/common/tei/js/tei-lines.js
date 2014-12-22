var axisLabelFont = "Arial";
var axisLabelSize = 14;

function add(pointNo) {
    var points = getPoints();
    if (points["x" + pointNo] == null || points["y" + pointNo] == null) {
        document.getElementById('X' + pointNo).value = '';
        document.getElementById('Y' + pointNo).value = '';
        return;
    }
    document.getElementById('add' + pointNo).disabled = true;
    document.getElementById('remove' + pointNo).disabled = false;
    document.getElementById('X' + pointNo).disabled = true;
    document.getElementById('Y' + pointNo).disabled = true;
    var pointXY = {x: points["x" + pointNo], y: points["y" + pointNo]};
    var paper = getPaper();
    if (paper.snapOn) {
        pointXY = snap(paper, pointXY);
    }
    var point = createPoint(paper, toPaperX(paper, pointXY.x), toPaperY(paper, pointXY.y));
    point.no = pointNo;
    point.lines = new Array();
    if (paper.points == undefined) {
        paper.points = new Array();
    }
    paper.points[pointNo] = point; 
    updateXY(point);
    checkCreateLine(paper, pointNo);
}

function checkCreateLine(paper, pointNo) {
    if (paper.points[pointNo - 1]) {
        createLineBetweenPoints(paper, paper.points[pointNo - 1], paper.points[pointNo]);
    } 
    if (paper.points[pointNo + 1]) {
        createLineBetweenPoints(paper, paper.points[pointNo], paper.points[pointNo + 1]);
    } 
    if (paper.maxPointNo == pointNo && paper.points[1]) {
        createLineBetweenPoints(paper, paper.points[pointNo], paper.points[1]);
    };
    if (paper.maxPointNo && paper.points[paper.maxPointNo] && pointNo == 1) {
        createLineBetweenPoints(paper, paper.points[paper.maxPointNo], paper.points[1]);
    };
}

function createLineBetweenPoints(paper, pointA, pointB) {
    
    var line = paper.line(pointA.attr('cx'), pointA.attr('cy'), 
                          pointB.attr('cx'), pointB.attr('cy'));
    
    line.drag(moveAllLines, dragAllLines, dropAllLinesWithSnap);
    line.attr({stroke: "black", "stroke-width": 2, cursor: "move"});
    line.point1 = pointA;
    line.point2 = pointB;
    pointA.lines.push(line);
    pointB.lines.push(line);
    
    if (paper.extendLine == true) {
        var extLinePoints = getExtLinePoints(line);
        drawExtLine(line, extLinePoints);

    }
    
    if (paper.lines == undefined) {
        paper.lines = new Array();
    }
    paper.lines.push(line);
}

function drawExtLine(line, extLinePoints) {
    var paper = getPaper();
    var index = 0;
    for (var i = 0; i < extLinePoints.length; i++) {
        var point = extLinePoints[i];
        if (isNaN(point.x) || isNaN(point.y)) { continue; }
        if (Math.abs(point.x - line.x1) < 5 && Math.abs(point.y - line.y1) < 5) { continue; } // there's no line to draw
        line['extLine' + index] = paper.path("M " + line.x1 + "," + line.y1 + " L " + Math.round(point.x) + "," + Math.round(point.y));
        line['extLine' + index].attr({stroke: "black", "stroke-width": 2, "arrow-end": "classic-wide-long"});
        line['extLine' + index].toBack();
        index++;
    }
}

function modifyExtLine(line, extLinePoints) {
    removeExtLine(line);
    drawExtLine(line, extLinePoints);
}

function removeExtLine(line) {
    for (var i = 0; ; i++) {
        var extLine = line['extLine' + i];
        if (extLine) {
            extLine.remove();
            line['extLine' + i] = undefined;
        } else {
            break;
        }
    }
}

function getX(line, y) {

    var x1 = line.x1;
    var y1 = line.y1;
    var x2 = line.x2;
    var y2 = line.y2;
    
    return (y - y1) / (y2 - y1) * (x2 - x1) + x1;
    
}

function getY(line, x) {

    var x1 = line.x1;
    var y1 = line.y1;
    var x2 = line.x2;
    var y2 = line.y2;
    
    return (x - x1) / (x2 - x1) * (y2 - y1) + y1;
    
}

function getExtLinePoints(line) {
    
    var x11 = getX(line, 0); 
    var x22 = getX(line, line.paper.height);
    var y11 = getY(line, 0);
    var y22 = getY(line, line.paper.width);
    
    var points = new Array();
    
    if (x11 >= 0 && x11 <= line.paper.width) {
        points.push({x: x11, y: 0});
    }
    if (x22 >= 0 && x22 <= line.paper.width) {
        points.push({x: x22, y: line.paper.height});
    }
    if (y11 >= 0 && y11 <= line.paper.height) {
        points.push({x: 0, y: y11});
    }
    if (y22 >= 0 && y22 <= line.paper.height) {
        points.push({x: line.paper.width, y: y22});
    }
    
    return points;
}


moveAllLines = function(dx, dy, x, y, event) {
//  console.log('dx=' + dx + ', mindx=' + this.paper.lines.mindx + ', maxdx=' + this.paper.lines.maxdx);
    var paper = this.paper;
    paper.lines.forEach(function(line) {
        if (dx > line.maxdx) dx = line.maxdx; 
        if (dx < line.mindx) dx = line.mindx; 
        if (dy > line.maxdy) dy = line.maxdy; 
        if (dy < line.mindy) dy = line.mindy;
    });
    paper.lines.forEach(function(line) {
        
        lineMove.call(line, dx, dy, x, y, event);
        modifyPoint(line.point1, line.x1, line.y1);
        modifyPoint(line.point2, line.x2, line.y2);
        
        if (line.extLine0) {
            var extLinePoints = getExtLinePoints(line);
            modifyExtLine(line, extLinePoints);
        }
        
    });
};

dragAllLines = function() {
    this.paper.lines.forEach(function(element) {
        lineDrag.call(element);
    });
};

function modifyPoint(point, x, y) {
    point.attr({cx: x, cy: y});
    updateXY(point);
}

function checkDeleteLines(point) {
    for (var i=0; i<point.lines.length; ) {
        var line = point.lines[i];
        detachLine(line);
        if (line.extLine0) { 
            removeExtLine(line);
        }
        line.paper.lines.splice(line.paper.lines.indexOf(line), 1);
        line.remove();
    }
}

function detachLine(line) {
    line.point1.lines.splice(line.point1.lines.indexOf(line), 1);
    line.point2.lines.splice(line.point2.lines.indexOf(line), 1);
}

function createPoint(paper, x, y) {
    var point = paper.circle(x, y, 5);
    
    point.minX = 0;
    point.minY = 0;
    point.getMaxX = function() {
        return this.paper.width;
    };
    point.getMaxY = function() {
        return this.paper.height;
    };
    
    point.drag(pointMove, circleDrag, circleDropWithSnap);
    point.attr({stroke: "black", "stroke-width": 1, fill:"black", cursor: "move"});
    return point;
}

pointMove = function(dx, dy, x, y, event) {
    circleMove.call(this, dx, dy, x, y, event);
//  out(this.no + ': x = ' + fromPaperX(this.paper, this.attr("cx")) + ', y = ' + fromPaperY(this.paper, this.attr("cy")));
    updateXY(this);
    modifyLines(this);
};

function modifyLines(point) {
    for (var i=0; i<point.lines.length; i++) {
        var line = point.lines[i];
        var point1 = line.point1;
        var point2 = line.point2;
        //out(point1.attr("cx") + ',' + point1.attr("cy") + ',' + point2.attr("cx") + ',' + point2.attr("cy"));
        modifyLine(line, point1.attr("cx"), point1.attr("cy"), point2.attr("cx"), point2.attr("cy"));
        if (line.extLine0) { 
            var extLinePoints = getExtLinePoints(line);
            modifyExtLine(line, extLinePoints);
        }
    }
}

function updateXY(point) {
    var x = fromPaperX(point.paper, point.attr("cx"));
    var y = fromPaperY(point.paper, point.attr("cy"));
    document.getElementById("X" + point.no).value = Math.round(x * 100) / 100;
    document.getElementById("Y" + point.no).value = Math.round(y * 100) / 100;
}

function remove(pointNo) {
    document.getElementById('add' + pointNo).disabled = false;
    document.getElementById('remove' + pointNo).disabled = true;
    document.getElementById("X" + pointNo).value = "";
    document.getElementById("Y" + pointNo).value = "";
    document.getElementById('X' + pointNo).disabled = false;
    document.getElementById('Y' + pointNo).disabled = false;
    var paper = getPaper();
    checkDeleteLines(paper.points[pointNo]);
    paper.points[pointNo].remove();
    paper.points[pointNo] = null;
}

function getPoints() {
    var paper = getPaper();
    var points = new Object();
    for (var i=1; ; i++) {
        if (document.getElementById("X" + i)) {
            points["x" + i] = +document.getElementById("X" + i).value;
            points["y" + i] = +document.getElementById("Y" + i).value;
            if (isNaN(points["x" + i])) points["x" + i] = null;//points["x" + i] = 0;
            if (isNaN(points["y" + i])) points["y" + i] = null;//points["y" + i] = 0;
            if (points["x" + i] > paper.bounds.maxX) points["x" + i] = null;
            if (points["x" + i] < paper.bounds.minX) points["x" + i] = null;
            if (points["y" + i] > paper.bounds.maxY) points["y" + i] = null;
            if (points["y" + i] < paper.bounds.minY) points["y" + i] = null;
        } else {
            break;
        }
    }
    return points;
}

function fromPaperX(paper, paperX) {
    var ratio = paper.width / (paper.bounds.maxX - paper.bounds.minX);
    return paper.bounds.minX + paperX / ratio;
}

function fromPaperY(paper, paperY) {
    var ratio = paper.height / (paper.bounds.maxY - paper.bounds.minY);
    return paper.bounds.maxY - paperY / ratio;
}

function toPaperX(paper, x) {
    var ratio = paper.width / (paper.bounds.maxX - paper.bounds.minX);
    return (x - paper.bounds.minX) * ratio;
}

function toPaperY(paper, y) {
    var ratio = paper.height / (paper.bounds.maxY - paper.bounds.minY);
    return (paper.bounds.maxY - y) * ratio;
}

function enableDisableElements(flag) {
    document.getElementById('minX').disabled = !flag;
    document.getElementById('maxX').disabled = !flag;
    document.getElementById('stepX').disabled = !flag;
    document.getElementById('minY').disabled = !flag;
    document.getElementById('maxY').disabled = !flag;
    document.getElementById('stepY').disabled = !flag;
    if (!flag) {
        document.getElementById('gridVisibleCheck').checked = false;
        document.getElementById('snapToCheck').checked = false;
    }
    document.getElementById('gridVisibleCheck').disabled = !flag;
    document.getElementById('snapToCheck').disabled = !flag;
}

function dblclickAddPoint(paper, x, y) {
    var paperX = fromPaperX(paper, x);
    var paperY = fromPaperY(paper, y);
    for (var i = 1; ; i++) {
        var elem = document.getElementById('add' + i);
        if (!elem) {
            break;
        } else if (!elem.disabled) {
            document.getElementById('X' + i).value = paperX;
            document.getElementById('Y' + i).value = paperY;
            add(i);
            break;
        }
    }
}

function findSnapOnValue(v, min, max, step) {
    var minDiff = 1e9, value = 0; 
    for (var d = min; d <= max; d += step) {
        var diff = Math.abs(v - d);
        if (diff < minDiff) {
            minDiff = diff;
            value = d;
        }
    }
    return value;
}

function snap(paper, point) {
    point.x = findSnapOnValue(point.x, paper.bounds.minX, paper.bounds.maxX, paper.bounds.stepX);
    point.y = findSnapOnValue(point.y, paper.bounds.minY, paper.bounds.maxY, paper.bounds.stepY);
    return point;
}

circleDropWithSnap = function() {
    var paper = this.paper;
    if (!paper.snapOn) {
        return;
    }
    var pointXY = {x: fromPaperX(paper, this.attr('cx')), y: fromPaperY(paper, this.attr('cy'))};
    pointXY = snap(this.paper, pointXY);
    modifyPoint(this, toPaperX(paper, pointXY.x), toPaperY(paper, pointXY.y));
    modifyLines(this);
};

dropAllLinesWithSnap = function() {
    var paper = this.paper;
    if (!paper.snapOn) {
        return;
    }
    paper.lines.forEach(function(line) {

        var point1 = {x: fromPaperX(paper, line.x1), y: fromPaperY(paper, line.y1)};
        var point2 = {x: fromPaperX(paper, line.x2), y: fromPaperY(paper, line.y2)};
        if (paper.snapOn) {
            point1 = snap(paper, point1);       
            point2 = snap(paper, point2);       
        }
        point1 = {x: toPaperX(paper, point1.x), y: toPaperY(paper, point1.y)};
        point2 = {x: toPaperX(paper, point2.x), y: toPaperY(paper, point2.y)};
        modifyPoint(line.point1, point1.x, point1.y);
        modifyPoint(line.point2, point2.x, point2.y);
        modifyLine(line, point1.x, point1.y, point2.x, point2.y);
        
        if (line.extLine0) { 
            var extLinePoints = getExtLinePoints(line);
            modifyExtLine(line, extLinePoints);
        }
        
    });
};

function displayAxes(paper, bounds, flag) {
//  showAxes(paper);
    if (flag) {
        showAxes(paper, bounds);
    } else {
        paper.params.bounds = undefined;
        hideAxes(paper);
    }
}

function showAxes(paper, bounds) {
    paper.params.bounds = bounds;
    var path1 = null, path11 = null, path2 = null, path22 = null;
    if (bounds) {
        if (bounds.minX <= 0 && bounds.maxX >= 0) {
            var x = paper.width / (bounds.maxX - bounds.minX) * (- bounds.minX);
            path1 = paper.path("M " + x + "," + paper.height + " L " + x + "," + 0);
            path11 = paper.path("M " + x + "," + 0 + " L " + x + "," + paper.height);
        }
        if (bounds.minY <= 0 && bounds.maxY >= 0) {
            var y = paper.height / (bounds.maxY - bounds.minY) * (bounds.maxY);
            path2 = paper.path("M 0," + y + " L " + paper.width + "," + y); 
            path22 = paper.path("M " + paper.width + "," + y + " L 0," + y);
        }
    }
    if (path1 != null || path2 != null) {
        paper.axes = paper.set();
        if (path1 != null) {
            paper.axes.push(path1);
            paper.axes.push(path11);
        }
        if (path2 != null) {
            paper.axes.push(path2);
            paper.axes.push(path22);
        }
        paper.axes.attr({stroke: "black", "stroke-width": 1, "arrow-end": "block-wide-long"});
        showLabels(paper, bounds);
    } else {
        hideAxes(paper);
    }
}

function showLabels(paper, bounds) {
    if (bounds) {
        paper.labels = paper.set();
        var y = paper.height / (bounds.maxY - bounds.minY) * (bounds.maxY);
        var step = paper.width / (bounds.maxX - bounds.minX) * bounds.stepX;
        var pos = step;
        for (var i=bounds.minX + bounds.stepX; i<bounds.maxX; i+=bounds.stepX) {
            if (i != 0) {
            	var yy = bounds.minY < 0 ? y + 12 : y - 13;
                var text = paper.text(pos, yy, i);
                addLabel(paper, text, "middle");
            }
            pos += step;
        }
        var x = paper.width / (bounds.maxX - bounds.minX) * (- bounds.minX);
        step = paper.height / (bounds.maxY - bounds.minY) * bounds.stepY;
        pos = step;
        for (var i=bounds.maxY - bounds.stepY; i>bounds.minY; i-=bounds.stepY) {
            if (i != 0) {
//              var width = measureText(i, labelSize, labelFont).width;
            	var xx = bounds.minX < 0 ? x - 4 : x + 4;
            	var anchor = bounds.minX < 0 ? "end" : "start";
                var text = paper.text(xx, pos, i);
                addLabel(paper, text, anchor);
            }
            pos += step;
        }
        addLabel(paper, paper.text(paper.width - 8, y - 13, "x"), "middle", "italic");
        addLabel(paper, paper.text(x + 8, 10, "y"), "middle", "italic");
    }
}

function addLabel(paper, text, textAnchor, fontStyle) {
    text.attr({"font-size": axisLabelSize, "font-family": axisLabelFont, "text-anchor": textAnchor});
    if (fontStyle) {
        text.attr({"font-style": fontStyle});
    }
    $(text.node).css({
        "-webkit-touch-callout": "none",
        "-webkit-user-select": "none",
        "-khtml-user-select": "none",
        "-moz-user-select": "none",
        "-ms-user-select": "none",
        "user-select": "none"
    }); 
    paper.labels.push(text);
}

function hideLabels(paper) {
    if (paper.labels) {
        paper.labels.remove();
        paper.labels = undefined;
    }
}

function hideAxes(paper) {
    if (paper.axes) {
        paper.axes.remove();
        paper.axes = undefined;
    }
    hideGrid(paper);
    hideLabels(paper);
}

function displayGrid(paper, bounds, flag) {
    if (flag && bounds) {
        showGrid(paper, bounds);
    } else {
        hideGrid(paper);
    }
}


function showGrid(paper, bounds) {
    var step = paper.width / (bounds.maxX - bounds.minX) * bounds.stepX;
    var pathStr = "M " + step + ",0 ";
    for (var x=step; x<paper.width; x+=step) {
        pathStr += "L " + x + "," + paper.height + " M " + (x + step) + ",0 ";
    }
    step = paper.height / (bounds.maxY - bounds.minY) * bounds.stepY;
    pathStr += "M 0," + step + " ";
    for (var y=step; y<paper.height; y+=step) {
        pathStr += "L " + paper.width + "," + y + " M 0," + (y + step) + " "; 
    }
    paper.grid = paper.path(pathStr);//paper.path("M 0,240 L 640,240 M 320,0 L 320,480");
    paper.grid.attr({stroke: "black", "stroke-width": 1, "stroke-dasharray": ". "});
}

function hideGrid(paper) {
    if (paper.grid) {
        paper.grid.remove();
        paper.grid = undefined;
    }
} 

function axesToFront(paper) {
    if (paper.axes) {
        paper.axes.toFront();
    }
    if (paper.grid) {
        paper.grid.toFront();
    }
    if (paper.labels) {
        paper.labels.toFront();
    }
}

function enableSnapTo(flag) {
    getPaper().params.snapToEnabled = flag;
}

function extendLineBeyondEndPoints(flag) {
    getPaper().params.extendLineBeyondEndPoints = flag;
}

function changeAxis() {
    var paper = document.getElementById('holder').paper;
    hideAxes(paper);
    if (document.getElementById("displayAxesCheck").checked) {
        showAxes(paper, getBounds());
    }
    if (document.getElementById("gridVisibleCheck").checked) {
        displayGrid(paper, getBounds(), true);
    }
}

function getBounds() {
    var result = new Object();
    result.minX = parseInt(document.getElementById("minX").value);
    result.maxX = parseInt(document.getElementById("maxX").value);
    result.stepX = parseInt(document.getElementById("stepX").value);
    result.minY = parseInt(document.getElementById("minY").value);
    result.maxY = parseInt(document.getElementById("maxY").value);
    result.stepY = parseInt(document.getElementById("stepY").value);
    if (isNaN(result.minX)) return null;
    if (isNaN(result.maxX)) return null;
    if (isNaN(result.stepX)) return null;
    if (isNaN(result.minY)) return null;
    if (isNaN(result.maxY)) return null;
    if (isNaN(result.stepY)) return null;
    if (result.minX - result.maxX >= 0) return null;
    if (result.minY - result.maxY >= 0) return null;
    return result;
}

function populateFromBounds(bounds) {
    document.getElementById("minX").value = bounds.minX;
    document.getElementById("maxX").value = bounds.maxX;
    document.getElementById("stepX").value = bounds.stepX;
    document.getElementById("minY").value = bounds.minY;
    document.getElementById("maxY").value = bounds.maxY;
    document.getElementById("stepY").value = bounds.stepY;
}

function displayAxesChecked(paper, flag) {
    enableDisableElements(flag);
    displayAxes(paper, getBounds(), flag);
}

function setBounds(paper, bounds, gridVisible, snapToEnabled) {
    document.getElementById("displayAxesCheck").checked = true;
    showAxes(paper, bounds);
    document.getElementById("gridVisibleCheck").checked = gridVisible;
    if (gridVisible) {
        displayGrid(paper, bounds, true);
    }
    enableDisableElements(true);
    document.getElementById("snapToCheck").checked = snapToEnabled;
    enableSnapTo(snapToEnabled);
}

