/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code to draw and manage the selection box
 */
var PXN8 = PXN8 || {};

/* ============================================================================ 
 *
 * Drag - related functions and members
 */

PXN8.drag = {
    dx: 0,
    dy: 0,
    beginDragX: 0,
    beginDragY: 0,
    
    /* used when dragging selection */
    osx: 0,
    osy: 0,
    ow: 0,
    oh: 0
};

PXN8.drag.begin = function (elementToDrag, event, moveHandler, upHandler)
{
    var dom = PXN8.dom;
    
    var elementBounds = dom.eb(elementToDrag);

    var cursorPos = dom.cursorPos(event);
    
    var scrolledPoint = PXN8.scrolledPoint(cursorPos.x,cursorPos.y);

    
    PXN8.drag.beginDragX = scrolledPoint.x;
    PXN8.drag.beginDragY = scrolledPoint.y;
    
    PXN8.drag.dx = scrolledPoint.x - elementBounds.x;
    PXN8.drag.dy = scrolledPoint.y - elementBounds.y;
    
    PXN8.drag.osx = PXN8.sx;
    PXN8.drag.osy = PXN8.sy;
    PXN8.drag.ow = PXN8.ex - PXN8.sx;
    PXN8.drag.oh = PXN8.ey - PXN8.sy;
    
    if (document.addEventListener){
        document.addEventListener("mousemove", moveHandler, true);
        document.addEventListener("mouseup", upHandler, true);
    }else if (document.attachEvent){
        document.attachEvent("onmousemove",moveHandler);
        document.attachEvent("onmouseup",upHandler);
    }
    if (event.stopPropogation) event.stopPropogation();/* DOM Level 2 */
    else event.cancelBubble = true; /* IE */
   
    if (event.preventDefault){
        event.preventDefault(); /* DOM Level 2 */
    }else {
        event.returnValue = false; /*  IE */
    }
};

PXN8.drag.moveCanvasHandler = function (event)
{
    var dom = PXN8.dom;
    
    if (!event) event = window.event; /* IE */

    var canvasBounds = dom.eb(dom.id("pxn8_canvas"));
    
    var theImg = dom.id("pxn8_image");

    var maxX = canvasBounds.x + theImg.width;
    var maxY = canvasBounds.y + theImg.height;
    
    var cursorPos = dom.cursorPos(event);
    /*
     * prohibit move outside right and bottom
     */
    var scrolledPoint = PXN8.scrolledPoint(cursorPos.x, cursorPos.y);
    
    var x2 = scrolledPoint.x>maxX?maxX:scrolledPoint.x; 
    x2 = x2 < canvasBounds.x?canvasBounds.x:x2;
    var y2 = scrolledPoint.y>maxY?maxY:scrolledPoint.y;
    y2 = y2 < canvasBounds.y?canvasBounds.y:y2;

    var numerical = function(a,b){
        return a-b;
    };
    var xVals = [PXN8.drag.beginDragX-canvasBounds.x,x2-canvasBounds.x].sort(numerical);
    var yVals = [PXN8.drag.beginDragY-canvasBounds.y,y2-canvasBounds.y].sort(numerical);
    
    var pixelWidth = xVals[1] - xVals[0];
    var pixelHeight = yVals[1] - yVals[0];
    
    var width = Math.round(pixelWidth / PXN8.zoom.value());
    var height = Math.round(pixelHeight / PXN8.zoom.value());
    
    height = height > PXN8.image.height?PXN8.image.height:height;
    width = width > PXN8.image.width?PXN8.image.width:width;
    if (width > PXN8.aspectRatio.width &&
        height > PXN8.aspectRatio.height &&
        PXN8.aspectRatio.width > 0){
        
        if (PXN8.aspectRatio.width > PXN8.aspectRatio.height){
            height = Math.round(width/PXN8.aspectRatio.width *PXN8.aspectRatio.height);
        }else{
            width = Math.round(height/PXN8.aspectRatio.height *PXN8.aspectRatio.width);
        }
    }
    
    PXN8.sx = Math.round(xVals[0]/PXN8.zoom.value());
    PXN8.ex = PXN8.sx + width;
    
    PXN8.sy = Math.round(yVals[0]/PXN8.zoom.value());
    PXN8.ey = PXN8.sy + height;

    PXN8.selectArea();
    
    if (event.stopPropogation) event.stopPropogation(); /* DOM Level 2 */
    else event.cancelBubble = true; /*  IE */
};

/*
 * Handler passed to beginDrag when the user is dragging on the canvas.
 * This handler will be invoked on a mouseup event
 */
PXN8.drag.upCanvasHandler = function (event)
{

    PXN8.log.append("aspect_ratio: width=" + PXN8.aspectRatio.width + ", height=" + PXN8.aspectRatio.height);

    if (!event) event = window.event ; /* IE */
    
    if (document.removeEventListener){
        document.removeEventListener("mouseup",PXN8.drag.upCanvasHandler,true);
        document.removeEventListener("mousemove",PXN8.drag.moveCanvasHandler, true);
    }else if (document.detachEvent){
        document.detachEvent("onmouseup",PXN8.drag.upCanvasHandler);
        document.detachEvent("onmousemove",PXN8.drag.moveCanvasHandler);
    }
    if (event.stopPropogation) event.stopPropogation(); /*  DOM Level 2 */
    else event.cancelBubble = true; /* IE */
    
};


PXN8.drag.moveSelectionBoxHandler = function (event)
{
    var dom = PXN8.dom;
    
    if (!event) event = window.event; /* IE  */
    
    var canvasBounds = dom.eb(dom.id("pxn8_canvas"));
    var theImg = dom.id("pxn8_image");
    
    var mx = canvasBounds.x + theImg.width;
    var my = canvasBounds.y + theImg.height;

    var cursorPos = dom.cursorPos(event);
    var scrolledPoint = PXN8.scrolledPoint(cursorPos.x, cursorPos.y);

    /* how much (in pixels) the cursor has moved */
    var rx = scrolledPoint.x - PXN8.drag.beginDragX;
    var ry = scrolledPoint.y - PXN8.drag.beginDragY;
    
    
    /* is it right of left border ? */
    PXN8.sx = Math.round((PXN8.drag.osx + (rx/PXN8.zoom.value()))>0?(PXN8.drag.osx+(rx/PXN8.zoom.value())):0);
    
    PXN8.sx = Math.round((PXN8.sx+PXN8.drag.ow)>PXN8.image.width?(PXN8.image.width-PXN8.drag.ow):PXN8.sx);
    /*  is it below the top border ? */
    PXN8.sy = Math.round((PXN8.drag.osy + (ry/PXN8.zoom.value()))>0?(PXN8.drag.osy+(ry/PXN8.zoom.value())):0);
    
    PXN8.sy = Math.round((PXN8.sy+PXN8.drag.oh)>PXN8.image.height?(PXN8.image.height-PXN8.drag.oh):PXN8.sy);
    
    PXN8.ex = (PXN8.sx + PXN8.drag.ow)>0?(PXN8.sx+PXN8.drag.ow):0;
    PXN8.ey = (PXN8.sy + PXN8.drag.oh)>0?(PXN8.sy+PXN8.drag.oh):0;
    
    if (event.stopPropogation) event.stopPropogation(); /* DOM Level 2 */
    else event.cancelBubble = true; /* IE */

    PXN8.selectArea();
};


/*
 * Handler passed to beginDrag when the user is dragging the selection rect around.
 * This handler will be invoked on a mouseup event
 */
PXN8.drag.upSelectionBoxHandler = function (event)
{
    if (!event) event = window.event ; /* IE */
    if (document.removeEventListener){
        document.removeEventListener("mouseup",PXN8.drag.upSelectionBoxHandler,true);
        document.removeEventListener("mousemove",PXN8.drag.moveSelectionBoxHandler, true);
    }else if (document.detachEvent){
        document.detachEvent("onmouseup",PXN8.drag.upSelectionBoxHandler);
        document.detachEvent("onmousemove",PXN8.drag.moveSelectionBoxHandler);
    }
    if (event.stopPropogation) event.stopPropogation(); /* DOM Level 2 */
    else event.cancelBubble = true; /* IE */
};
