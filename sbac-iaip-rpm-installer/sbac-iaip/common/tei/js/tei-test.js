function tryItJSON(paper, item) {
    tryIt(paper, JSON.parse(item));
}

function tryIt(paper, item) {
    
    cleanPaper(paper);

    if (item.bounds) {
        paper.bounds = item.bounds;
        
        displayAxes(paper, paper.bounds, true);
        displayGrid(paper, paper.bounds, item.showGrid);
    }
    
    paper.extendLine = item.extendLineBeyondEndPoints ? true : false;
    paper.snapOn = item.snapToEnabled ? true : false;
    
    if (item.maxPoints) {
        initPoints(item.maxPoints);
        if (item.maxPoints > 2) {
            paper.maxPointNo = item.maxPoints;
        }
          
    }
    
    if (item.template == "01" || item.template == "03" || item.template == "04") {
        paper.dblclick = dblclickAddPoint;
    }
    
    if (item.template == "05") {
        paper.reorder = true;
        paper.mouseMove = reorderMouseMove;
    }
    
    if (item.template == "06") {
        paper.select = true;
        paper.selectCount = 3;
    }
    
    if (item.template == "07") {
        paper.selectAndEdit = true;
        paper.fragmentBGColor = "white";
        var table = document.getElementById("changeTextTable");
        table.style.display = "table";
    }
    
    if (item.images) {
        createImages(paper, item.images);
    }
    
    if (item.box) {
        if (item.dragElements) {
            for (var i = 0; i < item.dragElements.length; i++) {
                var element = item.dragElements[i];
                createTestDragElement(paper, element.imageUrl, parseInt(element.x), parseInt(element.y), parseInt(item.box.width), parseInt(item.box.height)); 
            }
        }
        if (item.dropTargets) {
            for (var i = 0; i < item.dropTargets.length; i++) {
                var target = item.dropTargets[i];
                createTestDropTarget(paper, parseInt(target.x), parseInt(target.y), parseInt(item.box.width), parseInt(item.box.height), parseInt(target.targetNo)); 
            }
        }
    }
    
    if (item.workingText) {
        initText(paper, item.workingText, item.separator, item.fontName, item.fontSize);
    }
    
}

function initText(paper, text, separator, fontName, fontSize) {
    paper.fragments = splitText2(text, separator);
    createTextElements(paper, paper.fragments, fontName, fontSize);
}

function createImages(paper, images) {
    for (var i = 0; i < images.length; i++) {
        var image = images[i];
        createImage(paper, image.url, image.x, image.y, image.width, image.height, false);
    } 
}

function initPoints(maxPoints) {
    var table = document.getElementById("pointsTable");
    table.innerHTML = "";
    for (var i = 1; i <= maxPoints; i++) {
        var row = table.insertRow(-1);
        var cell = row.insertCell(-1);
        cell.innerHTML = "Point #" + i + ": X = <td><input id='X" + i + "' type='text' value='' size=2> Y = <input id='Y" + i + "' type='text' value='' size=2>"; 
        cell = row.insertCell(-1);
        cell.innerHTML = "<input id='add" + i + "' type='button' value='Add' onclick='add(" + i + ");'><td>" +
                         "<input id='remove" + i + "' type='button' value='Remove' disabled='disabled' onclick='remove(" + i + ");'>";
    }
}


