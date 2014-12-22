function getImages(paper) {
    var result = new Array();
    paper.forEach(function(el) {
        if (el.isImage) {
            var image = Object();
            image.x = el.attr('x');
            image.y = el.attr('y');
            image.width = el.attr('width');
            image.height = el.attr('height');
            image.url = el.attr('src');
            result.push(image);
        }
    });
    return result.length > 0 ? result : undefined;
}


function getDropTargets(paper) {
    var result = new Array();
    paper.forEach(function(el) {
        if (el.targetNo) {
            var target = new Object();
            target.x = el.attr('x');
            target.y = el.attr('y');
            target.targetNo = el.targetNo;
            result.push(target);
        }
    });
    return result.length > 0 ? result : undefined;
}

function getDragElements(paper) {
    var result = new Array();
    paper.forEach(function(el) {
        if (el.elementNo) {
            var element = new Object();
            element.x = el.attr('x');
            element.y = el.attr('y');
            element.elementNo = el.elementNo;
            element.imageUrl = el.image.attr('src');
            result.push(element);
        }
    });
    return result.length > 0 ? result : undefined;
}

function getItemAsObject(currentTemplate, paper) {
    var result = new Object();
    result.template = currentTemplate;
    result.images = getImages(paper);
    result.bounds = paper.params.bounds;
    if (paper.grid) {
        result.showGrid = true;
    }
    if (paper.params.snapToEnabled) {
        result.snapToEnabled = paper.params.snapToEnabled;
    }
    if (paper.params.extendLineBeyondEndPoints) {
        result.extendLineBeyondEndPoints = paper.params.extendLineBeyondEndPoints;
    }
    result.box = paper.params.box;
    result.dropTargets = getDropTargets(paper);
    result.dragElements = getDragElements(paper);
    result.workingText = paper.params.workingText;
    result.separator = paper.params.separator;
    result.fontName = paper.params.fontName;
    result.fontSize = paper.params.fontSize;
    if (currentTemplate == "01") {
        result.maxPoints = 2;
    } else if (currentTemplate == "03") {
        result.maxPoints = 4;
    } else if (currentTemplate == "04") {
        result.maxPoints = 3;
    }
    return result;
}

function getAsJSON(currentTemplate, paper) {
//  alert(JSON.stringify(result));
    return JSON.stringify(getItemAsObject(currentTemplate, paper));
}

function loadFromJSON(item) {
    var paper = getPaper();
    item = JSON.parse(item);
    setCurrentTemplate(item.template);
    if (item.images) {
        createImages(paper, item.images, true);
    }
    if (item.bounds) {
        populateFromBounds(item.bounds);
        setBounds(paper, item.bounds, item.showGrid, item.snapToEnabled);
    }
    document.getElementById("endPointsCheck").checked = item.extendLineBeyondEndPoints ? true : false;
    extendLineBeyondEndPoints(item.extendLineBeyondEndPoints);
    if (item.box) {
        setBoxSize(paper, item.box);
        if (item.dragElements) {
            for (var i = 0; i < item.dragElements.length; i++) {
                var element = item.dragElements[i];
                createDragElement(paper, element.imageUrl, element.x, element.y, item.box.width, item.box.height); 
            }
            enableBoxSizeUpdate();          
        }
        if (item.dropTargets) {
            for (var i = 0; i < item.dropTargets.length; i++) {
                var target = item.dropTargets[i];
                createDropTarget(paper, target.x, target.y, item.box.width, item.box.height); 
            }
            enableBoxSizeUpdate();          
        }
    }
    if (item.workingText) {
        setTextParams(item.workingText, item.separator, item.fontName, item.fontSize);
    }
}
