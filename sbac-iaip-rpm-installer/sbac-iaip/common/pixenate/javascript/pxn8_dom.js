/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code for manipulating the DOM (document object model)
 */
var PXN8 = PXN8 || {};

/* ============================================================================
 *
 * DOM Manipulation FUNCTIONS
 */
PXN8.dom = {
    /**
     * Computing the style is expensive.
     * cache computation results here.
     */
    cachedComputedStyles: {}
};

/**
 * Removes all children from the specified node.
 * returns the passed in element
 * so that it can be called like this...
 *
 * dom.cl(elt).appendChild(dom.tx("hello"));
 * 
 * ... or this ...
 * 
 * var elt = dom.cl(dom.id("nodeid"));
 *
 */
PXN8.dom.cl = function(elt)
{
    if (!elt) return false;
    while (elt.firstChild){ elt.removeChild(elt.firstChild);}
    return elt;
};

/**
 * shorthand for document.createTextNode()
 */
PXN8.dom.tx = function(str){ return document.createTextNode(str);};

/**
 * Shorthand for document.getElementById
 */
PXN8.dom.id = function(str){ return document.getElementById(str);};

/**
 * shorthand for document.createElement();
 */
PXN8.dom.ce = function(nodeType,attrs)
{
    var el = document.createElement(nodeType);
    for (var i in attrs){ el[i] = attrs[i];}
    return el;
};

/**
 * shorthand for append child
 * returns the child not the parent
 */
PXN8.dom.ac = function(parent,child)
{ 
    parent.appendChild(child);
    return child;
};

/**
 * Return the element bounds for an element
 */
PXN8.dom.eb = function(elt)
{
    var x = null;
    var y = null;
    
    if(elt.style.position == "absolute") 
    {
        x = parseInt(elt.style.left);
        y = parseInt(elt.style.top);
    } else {
        var pos = this.ep(elt); 
        x = pos.x;
        y = pos.y;
    } 
    return {x: x, y: y, width: elt.offsetWidth, height: elt.offsetHeight};
};
/*
 * Given an element, calculate it's absolute position relative to 
 * the BODY element.
 * Returns an object with attributes x and y
 */
PXN8.dom.ep = function (elt)
{
   var tmpElt = elt;
   var posX = parseInt(tmpElt["offsetLeft"]);
   var posY = parseInt(tmpElt["offsetTop"]);
   while(tmpElt.tagName.toUpperCase() != "BODY") {
      tmpElt = tmpElt.offsetParent;
      posX += parseInt(tmpElt["offsetLeft"]);
      posY += parseInt(tmpElt["offsetTop"]);
   } 
   return {x: posX, y:posY};
};


/*
 * Calculate the size of the browser window
 */
PXN8.dom.windowSize = function() 
{
    if (document.all){
        return {width: document.body.clientWidth, 
                height: document.body.clientHeight};
    }else{
        return {width: window.outerWidth,
                height: window.outerHeight};
    } 
};

/**
 * set the opacity of an element 
 */
PXN8.dom.opacity = function(element, value)
{
    /*
     * it's quite possible that the element has been deleted
     */
    if (!element){
        return;
    }
    if (document.all){
        element.style.filter = "alpha(opacity:" + (value*100) + ")";
    }else{
        element.style.opacity = value;
        element.style._moz_opacity = value;
    }
};

/*
 * Return an array of elements with the supplied classname
 */
PXN8.dom.clz = function(className)
{
    var links = document.getElementsByTagName("*");
    
    var result = new Array();
    for (var i = 0;i < links.length; i++){
        if (links[i].className.match(className)){
            result.push(links[i]);
        }
    }
    return result;
};

/**
 * -- function computedStyle
 * -- description Returns the style of an element based on it's external stylesheet,
 *                and any inline styles.
 * -- param elementId The id of the element whose style must be computed
 * -- returns A Style object
 */
PXN8.dom.computedStyle = function(elementId)
{
    var result = null;
    
    if (this.cachedComputedStyles[elementId]){
        result = this.cachedComputedStyles[elementId];
    }else{
        var element = this.id(elementId);
        if (document.all){
            
            result = element.currentStyle;
            
        }else{
            if (window.getComputedStyle){
                result = window.getComputedStyle(element,null);                
            }else{
                /**
                 * Safari doesn't support getComputedStyle() 
                 */
                result = element.style;
            }
        }
        this.cachedComputedStyles[elementId] = result;
    }
    return result;
};
/**
 * -- function cursorPos
 * -- description Return the current adjusted cursor position
 */
PXN8.dom.cursorPos = function (e) 
{
    e = e || window.event;
    var cursor = {x:0, y:0};
    if (e.pageX || e.pageY) {
        cursor.x = e.pageX;
        cursor.y = e.pageY;
    }
    else {
        cursor.x = e.clientX +
            (document.documentElement.scrollLeft ||
            document.body.scrollLeft) -
            document.documentElement.clientLeft;
        cursor.y = e.clientY +
            (document.documentElement.scrollTop ||
            document.body.scrollTop) -
            document.documentElement.clientTop;
    }
    return cursor;
};

/**
 * -- function addLoadEvent
 * -- description Add a callback to the window's onload event
 * -- param func The callback function to be called when the window has loaded.
 */
PXN8.dom.addLoadEvent = function(func)
{
    var oldonload = window.onload;
    if (typeof window.onload != 'function'){
        window.onload = func;
    } else {
        window.onload = function(){
            if (oldonload){
                oldonload();
            }
            func();
        };
    }
};

PXN8.dom.addClickEvent = function(elt,func)
{
    var oldonclick = elt.onclick;
    if (typeof oldonclick != 'function'){
        elt.onclick = func;
    } else {
        elt.onclick = function(){
            if (oldonclick){
                oldonclick(elt);
            }
            func(elt);
        };
    }
};
PXN8.dom.onceOnlyClickEvent = function(elt,func)
{
    var oldonclick = elt.onclick;
    
    PXN8.dom.addClickEvent(elt,function(){
        func();
        elt.onclick = oldonclick;
    });
};
/**
 * Make constructing tables easier
 * -- param rows An array of arrays (2-dimensional) 
 *    Each item in the inner arrays must be either a string or a DOM element.
 *    
 * -- e.g. PXN8.dom.table([[ "Row1Col1", document.getElementById("pxn8_image") ],
 *                         [ "Row2Col1", "Hello World" ],
 *                         [ "This spans two columns"  ]]);
 */
PXN8.dom.table = function(rows, attributes)
{
    var dom = PXN8.dom;
    
    var result = dom.ce("table",attributes);
    var tbody = dom.ce("tbody");
	 result.appendChild(tbody);
    /**
     * First scan the array to find find the widest row (most cells)
     */
    var mostCells = 0;
    for (var i = 0; i < rows.length; i++){
        var row = rows[i];
        if (row.length > mostCells){
           mostCells = row.length;
        }
    }
   
    for (var i = 0; i < rows.length; i++){
        var tr = dom.ce("tr");
	     tbody.appendChild(tr);
        var rowData = rows[i];
        var cellsInRow = rowData.length;
        for (var j = 0; j < rows[i].length; j++){
            var cellData = rows[i][j];

            var td = dom.ce("td");
	         tr.appendChild(td);
            if (j == rows[i].length -1 && cellsInRow < mostCells){
                td.colSpan = (mostCells - cellsInRow)+1;
            }
            if (typeof cellData == "string"){
	             td.appendChild(dom.tx(cellData));
            }else if (PXN8.isArray(cellData)){
                // it's an array
                for (var k = 0; k < cellData.length; k++){
                    if (typeof cellData[k] == "string"){
	                     td.appendChild(dom.tx(cellData[k]));
                    }else{
	                     td.appendChild(cellData[k]);
                    }
                }
            }else{
	             td.appendChild(cellData);
            }
        }
    }	
    return result;
};

