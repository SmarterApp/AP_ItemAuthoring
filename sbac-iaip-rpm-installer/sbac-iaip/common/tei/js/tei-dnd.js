var boxFontSize = 12,
    boxFontName = 'Arial';

function createDropTarget(r, x, y, width, height) {
    r.params.box = {width: width, height: height};
    var rect = r.rect(x, y, width, height);
    rect.attr({stroke: "black", "stroke-width": 2, fill: "white", "fill-opacity": 0, cursor: "move"});
    rect.toHTML = function(div) {
        var label = document.createTextNode('Target #' + this.targetNo + '   ');
        div.appendChild(label);
        var button = document.createElement("input");
        button.type='button';
        button.value='Remove';
        button.onclick = function() {
            removeTarget(rect);
        };
        div.appendChild(button);
        div.appendChild(document.createElement("br"));
    };
    
    rect.targetNo = getMaxTargetNo(r) + 1;

    rect.textRect = holder.paper.rect(0, 0, 0, 0);
    rect.textRect.attr({stroke: "black", fill: "black", cursor: "move"});
    setTextRectAttr(rect);
    
    rect.text = holder.paper.text(0, 0, "Target #" + rect.targetNo);
    rect.text.attr({"font-size": boxFontSize, "font-family": boxFontName, "text-anchor": "end", fill: "white", cursor: "move"});
    setTextAttr(rect);
    
    rect.drag(targetMove, targetDrag, rectDrop);
    rect.text.drag(function(dx, dy, x, y, event) { targetMove.call(rect, dx, dy, x, y, event); }, function() { targetDrag.call(rect); }, rectDrop);
    rect.textRect.drag(function(dx, dy, x, y, event) { targetMove.call(rect, dx, dy, x, y, event); }, function() { targetDrag.call(rect); }, rectDrop);
    
    rect.divName = "targets";
    updateDiv(r, "targets");

    
    return rect;
}

function setTextRectAttr(rect) {
    rect.textRect.attr({x: parseInt(rect.attr('x')) + parseInt(rect.attr('width')) - 70, 
                        y: parseInt(rect.attr('y')) + parseInt(rect.attr('height')) - boxFontSize - 2, width: 70, height: boxFontSize + 2});
}

function setTextAttr(rect) {
    rect.text.attr({x: parseInt(rect.attr('x')) + parseInt(rect.attr('width')) - 3, 
                    y: parseInt(rect.attr('y')) + parseInt(rect.attr('height')) - boxFontSize / 2 - 2});   
}

targetDrag = function() {
    this.oX = this.attr('x');
    this.oY = this.attr('y');
    if (this.text) {
        this.text.toFront();
    }
};

targetMove = function(dx, dy, x, y, event) {
    var newX = (dx + this.oX);
    var newY = (dy + this.oY);
    
    if (newX < 0) newX = 0;
    if (newY < 0) newY = 0;
    if (newX > this.paper.width - this.attr("width")) newX = this.paper.width - this.attr("width"); 
    if (newY > this.paper.height - this.attr("height")) newY = this.paper.height - this.attr("height");
    
    this.attr({x: newX, y: newY});
    
    if (this.text) {
        setTextRectAttr(this);
        setTextAttr(this);
    }
    
};


function updateDiv(paper, divName) {
    div = document.getElementById(divName);
    while (div.hasChildNodes()) {
        div.removeChild(div.lastChild);
    }
    paper.forEach(function(el) {
        if (el.divName && el.divName == divName) {
            el.toHTML(div);
        }
    });
}

function removeTarget(target) {
    var paper = target.paper;
    target.text.remove();
    target.textRect.remove();
    target.remove();
    updateDiv(paper, "targets");
    disableUpdateBoxSizeButton(paper);
}

function getMaxTargetNo(paper) {
    var maxTargetNo = 0;
    paper.forEach(function(el) {
        if (el.targetNo && el.targetNo > maxTargetNo) {
            maxTargetNo = el.targetNo;
        }
    });
    return maxTargetNo;
}

function createDragElement(r, url, x, y, width, height) {
    r.params.box = {width: width, height: height};
    var rect = r.rect(x, y, width, height);
    var elementNo = getMaxElementNo(r) + 1;
    var elementName = 'Element ' + String.fromCharCode("A".charCodeAt() - 1 + elementNo);
    rect.attr({stroke: "black", "stroke-width": 2, fill: "white", "fill-opacity": 0, cursor: "move"});
    rect.toHTML = function(div) {
        var label = document.createTextNode(elementName + '   ');
        div.appendChild(label);
        var button = document.createElement("input");
        button.type='button';
        button.value='Remove';
        button.onclick = function() {
            removeElement(rect);
        };
        div.appendChild(button);
        div.appendChild(document.createElement("br"));
    };
    
    rect.elementNo = elementNo;

    rect.textRect = holder.paper.rect(0, 0, 0, 0);
    rect.textRect.attr({stroke: "black", fill: "black", cursor: "move"});
    setTextRectAttr(rect);
    
    rect.text = holder.paper.text(0, 0, elementName);
    rect.text.attr({"font-size": boxFontSize, "font-family": boxFontName, "text-anchor": "end", fill: "white", cursor: "move"});
    setTextAttr(rect);
    
    rect.drag(elementMove, elementDrag, rectDrop);
    rect.text.drag(function(dx, dy, x, y, event) { elementMove.call(rect, dx, dy, x, y, event); }, function() { elementDrag.call(rect); }, rectDrop);
    rect.textRect.drag(function(dx, dy, x, y, event) { elementMove.call(rect, dx, dy, x, y, event); }, function() { elementDrag.call(rect); }, rectDrop);
    
    createElementImage(rect, url);
    rect.image.attr({cursor: "move"});
    rect.image.drag(function(dx, dy, x, y, event) { elementMove.call(rect, dx, dy, x, y, event); }, function() { elementDrag.call(rect); }, rectDrop);
    
    rect.toFront();
    rect.textRect.toFront();
    rect.text.toFront();
    
    rect.divName = "elements";
    updateDiv(r, "elements");

    return rect;
}

elementDrag = function() {
    targetDrag.call(this);
    this.image.toFront();
    this.toFront();
    if (this.text) {
        this.textRect.toFront();
        this.text.toFront();
    }
};

elementMove = function(dx, dy, x, y, event) {
    targetMove.call(this, dx, dy, x, y, event);
    setImageAttr(this);
};

function removeElement(element) {
    var paper = element.paper;
    element.text.remove();
    element.textRect.remove();
    element.image.remove();
    element.remove();
    updateDiv(paper, "elements");
    disableUpdateBoxSizeButton(paper);
}

function disableUpdateBoxSizeButton(paper) {
    var no1 = getMaxElementNo(paper);
    var no2 = getMaxTargetNo(paper);
    if (no1 == 0 && no2 == 0) {
        document.getElementById("boxSizeUpdate").disabled = 'disabled';
    }
}

function enableBoxSizeUpdate() {
    document.getElementById("boxSizeUpdate").disabled = '';
}

function getMaxElementNo(paper) {
    var maxElementNo = 0;
    paper.forEach(function(el) {
        if (el.elementNo && el.elementNo > maxElementNo) {
            maxElementNo = el.elementNo;
        }
    });
    return maxElementNo;
}

function createElementImage(rect, url) {
    var x = rect.attr('x');
    var y = rect.attr('y');
    rect.image = rect.paper.image(url, x, y, 0, 0);
    loadImage(rect.image, function() { elementImageLoaded(this, rect); });
}

function elementImageLoaded(image, rect) {
    var ratio = image.height / image.width;
    var rectWidth = rect.attr('width');
    var rectHeight = rect.attr('height');

    var newWidth = image.width;
    var newHeight = image.height;
    
    if (newHeight > rectHeight) {
        newHeight = rectHeight;
        newWidth = newHeight / ratio;
    }
    
    if (newWidth > rectWidth) {
        newWidth = rectWidth;
        newHeight = newWidth * ratio;
    }
    
    rect.image.attr({width: newWidth, height: newHeight});
    setImageAttr(rect);
}

function setImageAttr(rect) {
    rect.image.attr({x: rect.attr('x') + (parseInt(rect.attr('width')) - parseInt(rect.image.attr('width'))) / 2, 
                     y: rect.attr('y') + (parseInt(rect.attr('height')) - parseInt(rect.image.attr('height'))) / 2});   
}

function updateBoxSize(paper, width, height) {
    paper.params.box = {width: width, height: height};
    paper.forEach(function(el) {
        if (el.elementNo || el.targetNo) {
            el.attr({width: width, height: height});
            setTextAttr(el);
            setTextRectAttr(el);
            if (el.image) {
                setImageAttr(el);
            }
        }
    });
}

function setBoxSize(paper, box) {
    paper.params.box = box;
    document.getElementById('boxWidth').value = box.width;
    document.getElementById('boxHeight').value = box.height;
}


function createTestDropTarget(paper, x, y, width, height, targetNo) {
    
    var rect = paper.rect(x, y, width, height);
    rect.targetNo = targetNo;

    rect.attr({stroke: "black", "stroke-width": 3, fill: "gray", "fill-opacity": 0.5});
    
}


function createTestDragElement(paper, url, x, y, width, height) {
    
    var rect = paper.rect(x, y, width, height);

    rect.attr({stroke: "black", "stroke-width": 2, fill: "gray", "fill-opacity": 0.1, cursor: "move"});
    rect.ooX = x;
    rect.ooY = y;
    
    rect.drag(elementMove, elementDrag, elementDrop);
    
    createElementImage(rect, url);
    rect.image.attr({cursor: "move"});
    rect.image.drag(function(dx, dy, x, y, event) { elementMove.call(rect, dx, dy, x, y, event); }, 
                    function() { elementDrag.call(rect); }, 
                    function() { elementDrop.call(rect); });
    
    rect.toFront();
    
}


elementDrop = function() {
    var element = this;
    var foundTarget = false;
    this.paper.forEach(function(el) {
        if (el.targetNo) {
            if (boxesIntersect(box(el), box(element))) {
                element.attr({x: el.attr('x'), y: el.attr('y')});
                foundTarget = true;
                setImageAttr(element);
            }
        }
    });
    if (!foundTarget) {
        element.attr({x: element.ooX, y: element.ooY});
        setImageAttr(element);
    }
};

function box(el) {
    return {x: el.attr('x'), y: el.attr('y'), width: el.attr('width'), height: el.attr('height')};
} 

function boxesIntersect(box1, box2) {
    if ((box1.x >= box2.x && box1.x <= box2.x + box2.width) && 
        (box1.y >= box2.y && box1.y <= box2.y + box2.height)) return true;
    if ((box1.x + box1.width >= box2.x && box1.x + box1.width <= box2.x + box2.width) && 
        (box1.y >= box2.y && box1.y <= box2.y + box2.height)) return true;
    if ((box1.x >= box2.x && box1.x <= box2.x + box2.width) && 
        (box1.y + box1.height >= box2.y && box1.y + box1.height <= box2.y + box2.height)) return true;
    if ((box1.x + box1.width >= box2.x && box1.x + box1.width <= box2.x + box2.width) && 
        (box1.y + box1.height >= box2.y && box1.y + box1.height <= box2.y + box2.height)) return true;          
    
    return false;
}
