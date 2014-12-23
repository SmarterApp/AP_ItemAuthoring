if (!Array.prototype.forEach)
{
	Array.prototype.forEach = function(fun /*, thisp*/)
	{
		var len = this.length;
		if (typeof fun != "function")
			throw new TypeError();

		var thisp = arguments[1];
		for (var i = 0; i < len; i++)
		{
			if (i in this)
				fun.call(thisp, this[i], i, this);
		}
	};
}

Raphael.fn.line = function (x1, y1, x2, y2) {

	var linePath = this.path();

    linePath.x1 = x1;
    linePath.y1 = y1;
    linePath.x2 = x2;
    linePath.y2 = y2;
    
    linePath.getPathStr = function() {
        return "M" + this.x1 + " " + this.y1 + " L" + this.x2 + " " + this.y2;
    };

    linePath.attr({path: linePath.getPathStr()});
    
    return linePath;

};

imageMouseOver = function(e) {
    var x = this.attr('x'),
	    y = this.attr('y'),
	    width = this.attr('width'),
	    height = this.attr('height');
    if (!this.boundsRect) {
		this.boundsRect = getPaper().rect(x, y, width, height);
		this.boundsRect.attr({stroke: "black", "stroke-dasharray": "."});
		this.dragRect = getPaper().rect(x + width - 15, y + height - 15, 15, 15);
		this.dragRect.attr({stroke: "black", "stroke-dasharray": "."});
    }
};

imageMouseOut = function(e) {
	this.boundsRect.remove();
	this.boundsRect = undefined;
	this.dragRect.remove();
	this.dragRect = undefined;
};

imageMouseMove = function(e) {
    var mouseX = e.layerX,
        mouseY = e.layerY,
        imgX = this.attr('x'),
        imgY = this.attr('y'),
        imgWidth = this.attr('width'),
        imgHeight = this.attr('height');

    if (Math.abs(mouseX - imgX - imgWidth) < 15 && Math.abs(mouseY - imgY - imgHeight) < 15) {
        this.attr({cursor: 'se-resize'});
        this.action = 'resize';
    } else {
        this.attr({cursor: 'move'});
        if (this.dragging == false) {
            this.action = 'move';
        }
    }
};

lineDrag = function() {
    this.ox1 = this.x1;
    this.ox2 = this.x2;
    this.oy1 = this.y1;
    this.oy2 = this.y2;
    
	var maxX = Math.max(this.x1, this.x2);
	var minX = Math.min(this.x1, this.x2);
	var maxY = Math.max(this.y1, this.y2);
	var minY = Math.min(this.y1, this.y2);

	this.maxdx = this.paper.width - maxX;
	this.maxdy = this.paper.height - maxY;
	this.mindx = - minX;
	this.mindy = - minY;
    
    this.toFront();
};

imageDrag = function() {
    this.ox = this.attr("x");
    this.oy = this.attr("y");
    this.ow = this.attr('width');
    this.oh = this.attr('height');
    this.toFront();
    this.dragging = true;
};

imageMove = function(dx, dy, x, y, event) {
    switch (this.action) {
        case 'move':
            this.attr(checkBounds(this, {x: this.ox + dx, y: this.oy + dy}));
            break;                        
        case 'resize':
            dy = dx; //aspect ratio
            if (this.oh + dy > 5) {
                this.attr({height: this.oh + dy});                         
            }                                
            if (this.ow + dx > 5) {
                this.attr({width: this.ow + dx});
            }
            break;
    }
    if (this.boundsRect) {
    	this.boundsRect.attr({x: this.attr('x'), y: this.attr('y'), width: this.attr('width'), height: this.attr('height')});
    	this.dragRect.attr({x: this.attr('x') + this.attr('width') - 15, y: this.attr('y') + this.attr('height') - 15});
    }
};

imageDrop = function() {
    this.dragging = false;
    this.action = '';
    this.toBack();
    axesToFront(this.paper);
};

lineMove = function(dx, dy, x, y, event) {
	if (dx > this.maxdx) dx = this.maxdx;
	if (dx < this.mindx) dx = this.mindx;
	if (dy > this.maxdy) dy = this.maxdy;
	if (dy < this.mindy) dy = this.mindy;
    this.x1 = this.ox1 + dx;
    this.x2 = this.ox2 + dx;
    this.y1 = this.oy1 + dy;
    this.y2 = this.oy2 + dy;
    this.attr({path: this.getPathStr()});
};

function modifyLine(line, x1, y1, x2, y2) {
	line.x1 = x1;
	line.y1 = y1;
	line.x2 = x2;
	line.y2 = y2;
	line.attr({path: line.getPathStr()});
}

circleDrag = function() {
    this.ox = this.attr("cx");
    this.oy = this.attr("cy");
    this.toFront();
};

circleMove = function(dx, dy, x, y, event) {
	var newPoint = checkBounds(this, {x: this.ox + dx, y: this.oy + dy});
    this.attr({cx: newPoint.x, cy: newPoint.y});
};

circleDrop = function() {
};

lineDrop = function() {
};

function checkBounds(shape, point) {
    if (shape.minX != undefined && point.x < shape.minX) {
        point.x = shape.minX;
    }
    if (shape.minY != undefined && point.y < shape.minY) {
        point.y = shape.minY;
    }
    if (shape.getMaxX && point.x > shape.getMaxX()) {
        point.x = shape.getMaxX();
    }
    if (shape.getMaxY && point.y > shape.getMaxY()) {
        point.y = shape.getMaxY();
    }
    return point;
}

function createImage(r, url, x, y, width, height, draggable) {
    var image = r.image(url, x, y, width, height);
    if (width == 0 || height == 0) {
    	loadImage(image, imageLoaded);
    }
    image.dragging = false;
    image.action = '';
    image.minX = 0;
    image.minY = 0;
    image.getMaxX = function() {
        return this.paper.width - this.attr('width');
    };
    image.getMaxY = function() {
        return this.paper.height - this.attr('height');
    };
    image.toHTML2 = function(div) {
    	var label = document.createTextNode(url + '   ');
    	div.appendChild(label);
    	var button = document.createElement("input");
    	button.type='button';
    	button.value='Remove';
    	button.onclick = function() {
    		removeImage(r, image);
    	};
    	div.appendChild(button);
    	div.appendChild(document.createElement("br"));
    };
    image.isImage = true;
    image.maxY = r.height - height;
    if (draggable == undefined || draggable == true) { 
    	image.drag(imageMove, imageDrag, imageDrop);
        image.mousemove(imageMouseMove);
        image.mouseover(imageMouseOver);
        image.mouseout(imageMouseOut);
    }
    updateImages(r);
    axesToFront(r);
    return image;
}


function updateImages(paper) {
	images = document.getElementById("images");
	if (images) {
		while (images.hasChildNodes()) {
		    images.removeChild(images.lastChild);
		}
		paper.forEach(function(el) {
			if (el.isImage) {
				el.toHTML2(images);
			}
		});
	}
}

function removeImage(paper, element) {
	element.remove();
	updateImages(paper);
}

function loadImage(image, func) {
	var myImage = new Image();
	myImage.image = image;
	myImage.onload = func;
	myImage.src = image.attr('src');
}

function imageLoaded() {
	this.image.attr({width: this.width, height:this.height});
}

function getPaper() {
	return document.getElementById('holder').paper;
}

function createCircle(paper, x, y, r) {
	var circle = paper.circle(x, y, r);
    circle.minX = r;
    circle.minY = r;
    circle.getMaxX = function() {
        return this.paper.width - r;
    };
    circle.getMaxY = function() {
        return this.paper.height - r;
    };
    return circle;
}

function createLine(paper, x1, y1, x2, y2) {
	var line = paper.line(x1, y1, x2, y2);
	line.drag(lineMove, lineDrag, lineDrop);
	return line;
}

function out(msg) {
	document.getElementById("out").innerHTML = msg;
}

rectMove = function(dx, dy, x, y, event) {
    this.attr(checkBounds(this, {x: this.ox + dx, y: this.oy + dy}));
};

rectDrag = function() {
    this.ox = this.attr("x");
    this.oy = this.attr("y");
    this.toFront();
};

rectDrop = function() {
	axesToFront(this.paper);
};

function getInternetExplorerVersion() {
    var rv = -1; // Return value assumes failure.
    if (navigator.appName == 'Microsoft Internet Explorer') {
        var ua = navigator.userAgent;
        var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
        if (re.exec(ua) != null)
            rv = parseFloat(RegExp.$1);
    }
    return rv;
}

function mouseDblClick(e) {
	var paper = getPaper();
	if (paper.dblclick) {
		paper.dblclick(paper, e.pageX - $('#holder').offset().left, e.pageY - $('#holder').offset().top);
	}
}

function mouseMove(e) {
	var paper = getPaper();
	if (paper.mouseMove) {
		paper.mouseMove(paper, e.pageX - $('#holder').offset().left, e.pageY - $('#holder').offset().top);
	}
}

function mouseOut(e) {
	var paper = getPaper();
	if (paper.mouseOut) {
		paper.mouseOut(paper, event);
	}
}

function setCurrentTemplate(template) {
	var field = document.getElementById("templateSelect");
	for (var j = 0; j < field.options.length; j++) {
		if (template == field.options[j].value) {
			field.selectedIndex = j;
			break;
		} 
	}
	onSelection(field);
}

function createImages(paper, images, draggable) {
	for (var i = 0; i < images.length; i++) {
		var image = images[i];
		createImage(paper, image.url, image.x, image.y, image.width, image.height, draggable);
	}
}

function cleanPaper(paper) {
	paper.clear();
	paper.axes = undefined;
	paper.grid = undefined;
	paper.labels = undefined;
	paper.lines = undefined;
	paper.points = undefined;
	paper.params = new Object();
}
