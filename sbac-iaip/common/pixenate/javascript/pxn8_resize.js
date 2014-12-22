/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code to draw and manage the resize handles that 
 * appear on the selection box.
 *
 */
var PXN8 = PXN8 || {};

/* ============================================================================
 *
 * Resizing code makes extensive use of 'currying' (functions that return 
 * functions with variables 'baked in'. If not for currying, this code would 
 * be way too long and repetitive.
 * walter higgins
 * 3 February 2006
 *
 */
PXN8.resize = {
    dx: 0,
    dy: 0,
    start_width: 0,
    start_height: 0,
    canResizeNorth: function(yOffset){
        
        return (PXN8.sy + yOffset < (PXN8.ey-PXN8.style.resizeHandles.size)) && (PXN8.sy + yOffset > 0);
    },
    canResizeWest: function(xOffset){

        return (PXN8.sx + xOffset < (PXN8.ex-PXN8.style.resizeHandles.size)) && (PXN8.sx + xOffset > 0);
    },
    canResizeSouth: function(yOffset){

        return (PXN8.ey + yOffset > (PXN8.sy+PXN8.style.resizeHandles.size)) && (PXN8.ey + yOffset < PXN8.image.height);
    },
    canResizeEast: function(xOffset){

        return (PXN8.ex + xOffset > (PXN8.sx+PXN8.style.resizeHandles.size)) && (PXN8.ex + xOffset < PXN8.image.width);
    },
    nTest: function(xOffset,yOffset,event){

        if (PXN8.resize.canResizeNorth(yOffset) && PXN8.aspectRatio.width == 0)        // PXN8.sy > 0
        {
            PXN8.resize.dy = event.clientY;
            PXN8.sy = Math.round(PXN8.sy + yOffset);
            return true;
            
        }
        return false;
    },
    sTest: function(xOffset,yOffset,event){

        if (PXN8.resize.canResizeSouth(yOffset)  && PXN8.aspectRatio.width == 0)
        {
            PXN8.resize.dy = event.clientY;
            PXN8.ey = Math.round(PXN8.ey + yOffset);
            return true;
        }
        return false;
    },
    wTest: function(xOffset,yOffset,event){

        if (PXN8.resize.canResizeWest(xOffset)  && PXN8.aspectRatio.width == 0)        // PXN8.sx > 0
        {
            PXN8.resize.dx = event.clientX;
            PXN8.sx = Math.round(PXN8.sx + xOffset);
            return true;
        }
        return false;
    },
    eTest: function(xOffset,yOffset,event){

        if (PXN8.resize.canResizeEast(xOffset) && PXN8.aspectRatio.width == 0)
        {
            PXN8.resize.dx = event.clientX;
            PXN8.ex = Math.round(PXN8.ex + xOffset);
            return true;
        }
        return false;
    },
    nwTest: function(xOffset,yOffset,event){
        if (xOffset == 0 || yOffset == 0){
            return false;
        }
        var hr = PXN8.resize.start_height/PXN8.resize.start_width;
        var wr = 1 / hr;
        
        if (wr > hr){
            xOffset = yOffset * wr;
        }else if (wr < hr){
            yOffset = xOffset * hr;
        }else{
            yOffset = xOffset;
        }
        //
        // for NW corner
        // ensure both offsets are either negative or positive
        //
        if (xOffset > 0){
            // make Y positive if not already
            yOffset = Math.abs(yOffset);
        }else{
            // make y negative if not already
            yOffset = 0 - Math.abs(yOffset);
        }
        if (PXN8.resize.canResizeWest(xOffset) && PXN8.resize.canResizeNorth(yOffset))
        {
            PXN8.resize.dx = event.clientX;
            PXN8.resize.dy = event.clientY;
            PXN8.sx = Math.round(PXN8.sx + xOffset);
            PXN8.sy = Math.round(PXN8.sy + yOffset);
            return true;
        }
        return false;
    },

    swTest: function(xOffset,yOffset,event) {
        if (xOffset == 0 || yOffset == 0){
            return false;
        }
        var hr = PXN8.resize.start_height/PXN8.resize.start_width;
        var wr = 1 / hr;
        
        if (wr > hr){
            yOffset = xOffset * wr;
        }else{
            yOffset = xOffset;
        }
        
        //
        // for SW corner
        // ensure offset are +/-
        //
        if (xOffset > 0){
            // make Y negative if X is positive
            yOffset = 0 - Math.abs(yOffset);
        }else{
            // make y positive if X is negative
            yOffset = Math.abs(yOffset);
        }
        if (PXN8.resize.canResizeWest(xOffset) && PXN8.resize.canResizeSouth(yOffset))
        {
            PXN8.resize.dx = event.clientX;
            PXN8.resize.dy = event.clientY;
            PXN8.sx = Math.round(PXN8.sx + xOffset);
            PXN8.ey = Math.round(PXN8.ey + yOffset);
            return true;
        }
        return false;
    },
    neTest: function(xOffset,yOffset,event) {
        if (xOffset == 0 || yOffset == 0){
            return false;
        }
        var hr = PXN8.resize.start_height/PXN8.resize.start_width;
        var wr = 1 / hr;
        
        if (wr > hr){
            xOffset = yOffset * wr;
        }else{
            xOffset = yOffset;
        }
        //
        // for NE corner
        // ensure offset are +/-
        //
        if (yOffset > 0){
            // make Y negative if X is positive
            xOffset = 0 - Math.abs(xOffset);
        }else{
            // make y positive if X is negative
            xOffset = Math.abs(xOffset);
        }
        if (PXN8.resize.canResizeEast(xOffset) && PXN8.resize.canResizeNorth(yOffset))
        {  
            PXN8.resize.dx = event.clientX;
            PXN8.resize.dy = event.clientY;
            PXN8.ex = Math.round(PXN8.ex + xOffset);
            PXN8.sy = Math.round(PXN8.sy + yOffset);
            
            return true;
        }
        return false;
    },
    seTest: function(xOffset,yOffset,event) {
        if (xOffset == 0 || yOffset == 0){
            return false;
        }
        var hr = PXN8.resize.start_height/PXN8.resize.start_width;
        var wr = 1 / hr;
        
        if (wr > hr){
            xOffset = yOffset * wr;
        }else{
            yOffset = xOffset;
        }
        //
        // for SE corner
        // ensure offsets are both + or -
        //
        if (xOffset > 0){
            // make Y positive if X is positive
            yOffset = Math.abs(yOffset);
        }else{
            // make y negative if X is negative
            yOffset = 0 - Math.abs(yOffset);
        }
        if (PXN8.resize.canResizeEast(xOffset) && PXN8.resize.canResizeSouth(yOffset))
        {
            PXN8.resize.dx = event.clientX;
            PXN8.resize.dy = event.clientY;
            PXN8.ex = Math.round(PXN8.ex + xOffset);
            PXN8.ey = Math.round(PXN8.ey + yOffset);
            return true;
        }
        return false;
    },
    stopResizing: function(event){
        if (!event) event = window.event ; /* IE */
        
        if (document.removeEventListener){
            document.removeEventListener("mouseup",PXN8.resize.stopResizing,true);
            for (var i in PXN8.resize.handles){
                document.removeEventListener("mousemove",PXN8.resize.handles[i].moveHandler, true);
            }
            
        }else if (document.detachEvent){
            document.detachEvent("onmouseup",PXN8.resize.stopResizing);
            for (var i in PXN8.resize.handles){
                document.detachEvent("onmousemove",PXN8.resize.handles[i].moveHandler);
            }
        }
        if (event.stopPropogation) event.stopPropogation(); /*  DOM Level 2 */
        else event.cancelBubble = true; /* IE */
    },

    /**
     * Returns a handler that get's called when the user 
     * mouses-down on one of the resize handlers
     */
    startResizing: function(hdlr){
        var result = function(event){
            
            if (!event) event = window.event;
            
            PXN8.resize.dx = event.clientX;
            PXN8.resize.dy = event.clientY;

            var sel = PXN8.getSelection();
            
            PXN8.resize.start_height = sel.height;
            PXN8.resize.start_width = sel.width;
            
            if (document.addEventListener){
                document.addEventListener("mousemove", hdlr, true);
                document.addEventListener("mouseup", PXN8.resize.stopResizing, true);
            }else if (document.attachEvent){
                document.attachEvent("onmousemove",hdlr);
                document.attachEvent("onmouseup",PXN8.resize.stopResizing);
            }
            if (event.stopPropogation) event.stopPropogation();/* DOM Level 2 */
            else event.cancelBubble = true; /* IE */
            
            if (event.preventDefault) event.preventDefault(); /* DOM Level 2 */
            else event.returnValue = false; /*  IE */
            
        };
        return result;
    },
    
    createResizeHandle: function(direction,size,color) {
        var result = document.createElement("div");
        result.id = direction + "_handle";
        result.style.backgroundColor = color;
        result.style.position = "absolute";
        result.style.width = size + "px";
        result.style.height = size + "px";
        result.style.overflow = "hidden"; // fixes IE
        result.style.zIndex = 999;
        result.style.cursor = direction + "-resize";
        result.onmousedown = PXN8.resize.startResizing(PXN8.resize.handles[direction].moveHandler);
        result.ondrag = function(){return false;};
        return result;
    },
    
    positionResizeHandles: function() {
        var dom = PXN8.dom;

        var sel = PXN8.getSelection();
	 
        if (sel.width == 0){
            PXN8.resize.hideResizeHandles();
            return;
        }
        var zoom = PXN8.zoom.value();
        var rhsz = PXN8.style.resizeHandles.size;
        var rhsm = PXN8.style.resizeHandles.smallsize;

        if (((sel.width * zoom <= (rhsz * 3)) && rhsz != rhsm) ||
            ((sel.height * zoom <= (rhsz * 3)) && rhsz != rhsm)){
            /**
             * Shrink the resize handles 
             */
            //            rhsz = rhsm;
            //            PXN8.style.resizeHandles.oldsize = PXN8.style.resizeHandles.size;
            //            PXN8.style.resizeHandles.size = PXN8.style.resizeHandles.smallsize;
        }else{
            /**
             * expand the resize handles back to their original size
             */
            //            if (PXN8.style.resizeHandles.oldsize > -1){
            //                PXN8.style.resizeHandles.size = PXN8.style.resizeHandles.oldsize;
            //            }
        }
        
        
        var canvas = dom.id("pxn8_canvas");
        
        for (var i in PXN8.resize.handles){
            var handle = dom.id( i + "_handle");
            if (!handle){
                handle = PXN8.resize.createResizeHandle(i, rhsz,
                                                        PXN8.style.resizeHandles.color);
                dom.ac(canvas,handle);
            }else{
                /*
                 * change size of resize handles to suit selection size
                 */
                //                handle.style.width = rhsz + "px";
                //                handle.style.height = rhsz + "px";
            }
            if (handle.style.display == "none"){
                handle.style.display = "block";
            }
            PXN8.resize.handles[i].position(handle,sel);
        }
    },

    hideResizeHandles: function(hdls) {
        var dom = PXN8.dom;

        if (hdls){
            for (var i =0; i < hdls.length;i++){
                var handle = dom.id( i + "_handle");
                if (handle){
                    handle.style.display = "none";
                }
            }
        }else{
            // hide all
            for (var i in PXN8.resize.handles){
                var handle = dom.id( i + "_handle");
                if (handle){
                    handle.style.display = "none";
                }
            }
        }
    }
};

PXN8.resize.resizer = function( testFunc ) 
{
    var result = function(event){
        
        if (!event) event = window.event;
        var rdy = event.clientY - PXN8.resize.dy;
        var rdx = event.clientX - PXN8.resize.dx;
        /*
         * sane resizing when zoomed 
         */
        var prdy = Math.round(rdy / PXN8.zoom.value());
        var prdx = Math.round(rdx / PXN8.zoom.value());
        
        if (prdx == 0 && prdy == 0){
            // do nothing
        }else{
            if (testFunc(prdx,prdy,event) == true){
                PXN8.selectArea();
            }
        }
        
        if (event.stopPropogation) event.stopPropogation(); /* DOM Level 2 */
        else event.cancelBubble = true; /* IE */
    };
    return result;
};


/**
 * All of the resize handles are defined here
 */
PXN8.resize.handles = {
    "n":  { moveHandler: PXN8.resize.resizer(PXN8.resize.nTest),
            position: function(handle,sel){
                var sel_rect = PXN8.dom.eb(PXN8.dom.id("pxn8_select_rect"));
                handle.style.left = sel_rect.x + Math.ceil(sel_rect.width/2) - (PXN8.style.resizeHandles.size/2) + "px";
                handle.style.top = sel_rect.y + "px";
            }
    },
    "s":  { moveHandler: PXN8.resize.resizer(PXN8.resize.sTest),
            position: function(handle,sel){
                var sel_rect = PXN8.dom.eb(PXN8.dom.id("pxn8_select_rect"));
                handle.style.left = sel_rect.x + Math.ceil(sel_rect.width/2) - (PXN8.style.resizeHandles.size/2) + "px";
                handle.style.top = Math.round(((sel.top + sel.height) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
            }
    },
    "e":  { moveHandler: PXN8.resize.resizer(PXN8.resize.eTest),
            position: function(handle,sel){
                var sel_rect = PXN8.dom.eb(PXN8.dom.id("pxn8_select_rect"));
                handle.style.left = Math.round(((sel.left + sel.width) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
                //handle.style.left = (sel_rect.x + sel_rect.width - PXN8.style.resizeHandles.size) + "px";
                handle.style.top = sel_rect.y + Math.ceil(sel_rect.height / 2) - (PXN8.style.resizeHandles.size / 2) + "px";
                //handle.style.top = Math.round((sel.top + (sel.height/2) - (PXN8.style.resizeHandles.size /2 )) * PXN8.zoom.value()) + "px";
            }
    },
    "w":  { moveHandler: PXN8.resize.resizer(PXN8.resize.wTest),
            position: function(handle,sel){
                var sel_rect = PXN8.dom.eb(PXN8.dom.id("pxn8_select_rect"));
                //handle.style.left = Math.round(sel.left * PXN8.zoom.value()) + "px";
                //handle.style.top = Math.round((sel.top + (sel.height/2) - (PXN8.style.resizeHandles.size /2 )) * PXN8.zoom.value()) + "px";
                handle.style.top = sel_rect.y + Math.ceil(sel_rect.height / 2) - (PXN8.style.resizeHandles.size / 2) + "px";
                handle.style.left = sel_rect.x + "px";
            }
    },
    "nw": { moveHandler: PXN8.resize.resizer(PXN8.resize.nwTest),
            position: function(handle,sel){
                handle.style.left = Math.round(sel.left * PXN8.zoom.value()) + "px";
                handle.style.top = Math.round((sel.top * PXN8.zoom.value())) + "px";
            }
    },
    "sw": { moveHandler: PXN8.resize.resizer(PXN8.resize.swTest),
            position: function(handle,sel){
                handle.style.left = Math.round(sel.left * PXN8.zoom.value()) + "px";
                handle.style.top = Math.round(((sel.top + sel.height) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
            }
    },
    "ne": { moveHandler: PXN8.resize.resizer(PXN8.resize.neTest),
            position: function(handle,sel){
                var sel_rect = PXN8.dom.eb(PXN8.dom.id("pxn8_select_rect"));
                handle.style.left = Math.round(((sel.left + sel.width) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
                handle.style.top = sel_rect.y + "px";
            }
    },
    "se": { moveHandler: PXN8.resize.resizer(PXN8.resize.seTest),
            position: function(handle,sel){
                handle.style.left = Math.round(((sel.left + sel.width) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
                handle.style.top = Math.round(((sel.top + sel.height) * PXN8.zoom.value()) - PXN8.style.resizeHandles.size) + "px";
            }
    }
};

/** ============================================================================
 *  
 */
PXN8.listener.add(PXN8.ON_SELECTION_CHANGE, PXN8.resize.positionResizeHandles);
