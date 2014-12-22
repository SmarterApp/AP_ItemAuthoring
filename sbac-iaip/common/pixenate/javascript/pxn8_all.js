// generated on Thu Nov 30 18:10:35 2006
/*
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * If you have purchased PXN8 for use on your own servers and want to change the 
 * core functionality we strongly recommend that 
 * You make a copy of this file and rename it to $YOURCOMPANY_pxn8core.js and use that
 * as a working copy.
 */

var PXN8 = PXN8 || {};

/** ============================================================================
 *
 * PXN8 is a global object referenced throughout the PXN8 javascript code.
 * These are it's CORE data members
 */


/**
 * The root member is very important.
 * It's default value is "" but you should change this to the relative path 
 * where PXN8 is installed.
 * For example if your webroot is /var/www/html and you have installed PXN8 
 * in /var/www/html/pixenate, then you should set PXN8.root = "/pixenate/"
 * N.B. Change this value if you install PXN8 anywhere other than the web root
 * folder.
 */
PXN8.root = "";

/**
 * replaceOnSave specifies how PXN8 handles image URLs
 * if set to true then PXN8 always assumes that the photo at the supplied URL has changed.
 * if set to false then PXN8 will assume that the photo at the supplied url hasn't changed since it was last retrieved.
 */
PXN8.replaceOnSave = false;

/**
 * CONSTANTS
 */
PXN8.LANDSCAPE =  0;
PXN8.PORTRAIT = 1;

/**
 * Event constants
 */
PXN8.ON_ZOOM_CHANGE =  "ON_ZOOM_CHANGE";
PXN8.ON_SELECTION_CHANGE =  "ON_SELECTION_CHANGE";
// called when an image is updated
PXN8.ON_IMAGE_CHANGE =  "ON_IMAGE_CHANGE";
// called when an image update fails or an image fails to load
PXN8.ON_IMAGE_ERROR =  "ON_IMAGE_ERROR";
// called when the image element has loaded.
PXN8.ON_IMAGE_LOAD = "ON_IMAGE_LOAD";

/**
 * history stores all session operations
 */
PXN8.history =  [];

/**
 * An array of the response images returned from the server
 * This array contains relative file paths. 
 * It is updated in the  imageUpdateDone() function.
 */
PXN8.responses =  [];

/**
 * images stores a list of all images indexed by opNumber
 * (used by PXN8.tools.history)
 */
PXN8.images =  [];

/*
 * The current image - it's width; height and location (URL)
 */
PXN8.image =   { 
    width: 0, 
    height: 0, 
    location: ""
};

/*
 * What is the current operation number ?
 */
PXN8.opNumber =  0;

/**
 * what is the total number of operations performed ?
 */
PXN8.maxOpNumber =  0;

/*
 * An object which tells what the current aspect ratio is 
 */
PXN8.aspectRatio =  {width:0 , height:0};

/**
 * The image orientation (used by crop tool)
 */
PXN8.orientation =  this.PORTRAIT;

/**
 * The current mouse position
 */
PXN8.position =  {
    x: "-", 
    y: "-"
};

/**
 * The JSON response from the last image operation
 */
PXN8.response =  {
    status: "", 
    image: "", 
    errorCode: 0, 
    errorMessage: "" 
};

/**
 * If an operation is performed on an image then this is set to true
 * until the image update has completed
 */
PXN8.updating =  false;

/**
 * The upper bounds on image sizes
 */
PXN8.resizelimit = { 
    width: 1600,
    height: 1200
};


/**
 * Style-related properties...
 */
PXN8.style = {
    /*
     * The style of the canvas area which is not currently selected.
     */
    notSelected: {
        opacity: 0.33,
        color: "black"
    },
    /*
     * The style of the resize grab handles
     */
    resizeHandles: {
            color: "white",
            size: 6,
            smallsize: 4,
            oldsize: -1
    }
};

/*
 * A hashtable of images with the image.src url as the key (value is 'true')
 * Need this for IE to force onload handler for images which 
 * have already been loaded.
 */
PXN8.imagesBySrc =  {};

// the start of the selection along the X axis (from left)
PXN8.sx =  0;

// the start of the selection along the Y axis (from top)
PXN8.sy =  0;

// the end of the selection along the X axis
PXN8.ex =  0;

// the end of the selection along the Y axis 
PXN8.ey =  0;

/** ============================================================================
 *
 *  CORE MEMBER FUNCTIONS START HERE
 */

/*
 * -- function: PXN8.initialize
 * -- description: Call this function to initialize the PXN8 editor
 * -- param: Can be one of the following...
 *
 *      For the recommended way see [4]
 *
 *      [1] A string containing the full URL of an image to edit
 *          e.g. http://localhost/images/galaxy.jpg
 *
 *      [2] A string containing the absolute URL of an image (omitting the domain)
 *          e.g. /images/galaxy.jpg
 *          If such a URL is supplied and PXN8 is not installed in the webroot '/' folder
 *          then you should set PXN8.root to the path where it is installed.
 *          [see notes on PXN8.root near top of source file]
 *
 *      [3] A string containing the relative URL of an image [see note below]
 *          e.g. images/galaxy.jpg
 *          N.B. The supplied image should be relative to where PXN8 is installed NOT
 *          relative to the current document. For this reason, we do not advise supplying
 *          relative image paths unless the current document is in the same folder where
 *          the pxn8.pl script and other pxn8 files were installed.
 *         
 *      [4] An object with two attributes, url and filepath
 *          e.g. {url: 'images/galaxy.jpg', filepath '../gallery/images/galaxy.jpg'}
 *          The url attribute is the normal url for the image. 
 *          The filepath is a path relative to where PXN8 was installed where the image
 *          file can be found.
 *          This is the recommended way to call PXN8.initialize.
 *
 * Notes: If the image is not on the filesystem but is instead stored in a database
 *        or not accessible via the filesystem then you should use method [1] when 
 *        passing the parameter to this function.
 */
PXN8.initialize = function( param ) 
{
    var dom = PXN8.dom;

    var image_src;
    
    if (typeof param == 'string'){
        image_src = param;
    }else{
        image_src = param.url;
    }
    
    PXN8.priv.createSelectionRect();

    var canvas = PXN8.initializeCanvas();
    
    var rects = ["pxn8_top_rect","pxn8_bottom_rect","pxn8_left_rect","pxn8_right_rect"];
    for (var i = 0;i < rects.length; i++){
        var rect = dom.id(rects[i]);
        if (!rect){
            rect = dom.ac(canvas,dom.ce("div",{id: rects[i]}));
        }

        rect.style.fontSize = "0px";
        if (!rect.style.backgroundColor){
            rect.style.backgroundColor = PXN8.style.notSelected.color;
        }
        rect.style.position = "absolute";
        if (!rect.style.opacity){
            dom.opacity(rect,PXN8.style.notSelected.opacity);
        }
        
        rect.style.top = "0px";
        rect.style.left = "0px";
        rect.style.width = "0px";
        rect.style.height = "0px";
        rect.style.display = "none";
        rect.style.zIndex = "1";

    }
    PXN8.image.location = image_src;

    PXN8.opNumber = 0;
    PXN8.maxOpNumber = 0;
    
    PXN8.history = new Array();
    
    var fetchOp = {operation: "fetch", 
                   image: escape(escape(PXN8.image.location))
    };
    fetchOp.pxn8root = PXN8.root;

    if (param.filepath){
        fetchOp.filepath = param.filepath;
    }
    
    PXN8.history.push(fetchOp);
    

    if (PXN8.replaceOnSave){
        fetchOp.random = PXN8.randomHex();
    }
    
    var pxn8image = dom.id("pxn8_image");

    /**
     * Safari doesn't load the image immediately
     * so setting the PXN8.image.width & height variables
     * makes no sense until the image has loaded.
     * the following function gets called directly from within
     * this function but also from within the img.onload function
     * if no <img id="pxn8_image".../> element appears in the body
     * (if pxn8_image is created dynamically as is the case with a 
     * toolbar theme.
     *
     */
    var onImageLoad = function(pxn8image){

        PXN8.image.width =  pxn8image.width;
        PXN8.image.height = pxn8image.height;


        PXN8.priv.addImageToHistory(pxn8image.src);

        PXN8.show.size();
    };
    
    
    /**
     *  Initialize the image
     */
    if (!pxn8image){
        var imgContainer = dom.id("pxn8_image_container");
        if (!imgContainer){
            imgContainer = dom.ac(canvas,dom.ce("div",{id: "pxn8_image_container"}));
        }
        //
        // this won't work for Safari.
        // it is recommended that the <img> tag always appears
        // inside the pxn8_image_container tag.
        //
        pxn8image = dom.ac(imgContainer,dom.ce("img",{id: "pxn8_image", src: PXN8.image.location}));
        pxn8image.onload = function(){
            onImageLoad(pxn8image);
        };

    }else{

        // 
        //  The image is already present - re-add it to the DOM to ensure the 
        //  correct dimensions are applied.
        // 
        var imgContainer = dom.id("pxn8_image_container");
        dom.cl(imgContainer);
        //
        // wph 20060905 : Must change the image src attribute whenever PXN8.initialize is called
        // e.g. if there is a web-page with thumbnail images which change the current image for 
        // editing, the .src attribute *MUST* be updated !
        pxn8image = dom.ac(imgContainer,dom.ce("img",{id: "pxn8_image", src: PXN8.image.location}));
        pxn8image.onload = function(){
            onImageLoad(pxn8image);
        };
    }

    

    //
    // wph 20060714 notify ON_IMAGE_LOAD listeners
    //
    PXN8.event.removeListener(pxn8image,"load",PXN8.imageLoadNotifier);
    PXN8.event.addListener(pxn8image,"load",PXN8.imageLoadNotifier);
    /**
     * This is for the case where the img src attribute is
     * defined in the html
     */
    onImageLoad(pxn8image);
    
    /* initialize zoom info */
    PXN8.show.zoom();
};

PXN8.imageLoadNotifier = function()
{
    var theImage = PXN8.dom.id("pxn8_image");
    PXN8.listener.notify(PXN8.ON_IMAGE_LOAD,theImage);
};

/*
 * Sets up the mouse handlers for the canvas area
 * Some tools/operations might modify the canvas mouse behaviour
 * If they do so then they should call this method when the tool's
 * work is done or cancelled.
 */
PXN8.initializeCanvas = function()
{
    var dom = PXN8.dom;

    var canvas = dom.id("pxn8_canvas");

    canvas.onmousemove = function (event){ 
        if (!event) event = window.event;
	     var cursorPos = PXN8.dom.cursorPos(event);
        var imagePoint = PXN8.mousePointToElementPoint(cursorPos.x, cursorPos.y);
        PXN8.position.x = imagePoint.x;
        PXN8.position.y = imagePoint.y;
        PXN8.show.position();
        return true;
    };

    canvas.onmouseout = function (event){ 
        if (!event) event = window.event;
        PXN8.position.x = "-";
        PXN8.position.y = "-";
        PXN8.show.position();
    };
    canvas.onmousedown = function (event){
        if (!event) event = window.event;
        PXN8.drag.begin(canvas,
                        event,
                        PXN8.drag.moveCanvasHandler,
                        PXN8.drag.upCanvasHandler);
    };
    canvas.ondrag = function(){ 
        return false;
    };

    var computedCanvasStyle = dom.computedStyle("pxn8_canvas");

    var canvasPosition = null;
    
    if (computedCanvasStyle.getPropertyValue){
        canvasPosition = computedCanvasStyle.getPropertyValue("position");
    }else{
        if (!computedCanvasStyle.position){
            // position may not be available if 
            // computedStyle returns the inline style (on safari).
            //
            canvasPosition = "static";
        }else{
            canvasPosition = computedCanvasStyle.position;
        }
    }
    
    if (!canvasPosition || canvasPosition == "static"){
        // default the canvas position to relative
        canvas.style.position = "relative";
        canvas.style.top = "0px";
        canvas.style.left  = "0px";
    }
    //
    // the canvas should wrap tightly around the image
    // so that the canvas doesn't extend beyond the image,
    // set it's float css property if it hasn't already been set.
    //
    var floatProperty = "cssFloat";
    if (document.all){
        floatProperty = "styleFloat";
    }
    var floatValue = computedCanvasStyle[floatProperty];
    
    if (!floatValue || floatValue == "none"){
        canvas.style[floatProperty] = "left";
    }

    return canvas;
};


/* ============================================================================
 *
 * -- function select
 * -- description Selects an area of the image.
 * -- param startX The start position of the selected area along the X axis
 * -- param startY The start position of the selected area along the Y axis (starts at top)
 * -- param width The width of the selected area
 * -- param height The height of the selected area
 */
PXN8.select = function (startX, startY, width, height)
{
    this.sx = startX;
    this.sy = startY;
    this.ex = this.sx + width;
    this.ey = this.sy + height;
    
    if (this.sx < 0) this.sx = 0;
    if (this.sy < 0) this.sy = 0;
    if (this.ex > PXN8.image.width) this.ex = PXN8.image.width;
    if (this.ey > PXN8.image.height) this.ey = PXN8.image.height;
    
    this.selectArea();
};

/*
 * Return a Rect that represents the current selection
 */
PXN8.getSelection = function()
{
    var rect = {};
    rect.width = this.ex>this.sx?this.ex-this.sx:this.sx-this.ex;
    rect.height = this.ey>this.sy?this.ey-this.sy:this.sy-this.ey;
    rect.left = this.ex>this.sx?this.sx:this.ex;
    rect.top = this.ey>this.sy?this.sy:this.ey;
    rect.left = rect.left<0?0:rect.left;
    rect.top = rect.top<0?0:rect.top;     
    return rect;
};

/**
 * -- function selectByRatio
 * -- description Selects an area using an aspect ratio
 * -- param ratio The ratio is expressed as a string e.g. "4x6"
 * -- param override : Ignore the images's dimensions (don't optimize selection size)
 * --    true or false (default is false)
 */
PXN8.selectByRatio = function(ratio,override)
{
    var dom = PXN8.dom;

    if (typeof ratio != "string"){
        alert("Ratio must be expressed as a string e.g. '4x6'");
        return;
    }
    
    var pair = /^([0-9]+)x([0-9]+)/;
    var match = ratio.match(pair);
    if (match != null){
        var rw = parseInt(match[1]);
        var rh = parseInt(match[2]);
        
        if (override){
            PXN8.aspectRatio.width = rw;
            PXN8.aspectRatio.height = rh;
        }else{
            if (PXN8.image.width > PXN8.image.height){
                if (rw > rh){
                    PXN8.aspectRatio.width = rw;
                    PXN8.aspectRatio.height = rh;
                }else{
                    PXN8.aspectRatio.width = rh;
                    PXN8.aspectRatio.height = rw;
                }
            }else{
                if (rh > rw){
                    PXN8.aspectRatio.width = rh;
                    PXN8.aspectRatio.height = rw;
                }else{
                    PXN8.aspectRatio.width = rw;
                    PXN8.aspectRatio.height = rh;
                }
            }
        }
    }else{
        PXN8.aspectRatio.width = 0;
        PXN8.aspectRatio.height = 0;
        return;
    }
        
    var topRect = dom.id("pxn8_top_rect");
    topRect.style.borderWidth = "1px";
    
    var leftRect = dom.id("pxn8_left_rect");
    leftRect.style.borderWidth = "0px";
    
    this.sx = 0;
    this.sy = 0;
    
    var t1 = PXN8.image.width / PXN8.aspectRatio.width ;
    var t2 = PXN8.image.height / PXN8.aspectRatio.height ;
    if (t2 < t1){
        this.ey = PXN8.image.height;
        this.ex = Math.round(this.ey / PXN8.aspectRatio.height * PXN8.aspectRatio.width);
    }else{
        this.ex = PXN8.image.width;
        this.ey = Math.round(this.ex / PXN8.aspectRatio.width * PXN8.aspectRatio.height);
    }
    this.sx = Math.round((PXN8.image.width - this.ex) / 2);
    this.sy = Math.round((PXN8.image.height - this.ey) / 2);
    this.ex += this.sx;
    this.ey += this.sy;
    this.selectArea();
};

/**
 * -- function rotateSelection
 * -- description Rotates the selection area by 90 degrees 
 */
PXN8.rotateSelection = function()
{
    var sel = PXN8.getSelection();
    var cx = sel.left + (sel.width / 2);
    var cy = sel.top + (sel.height / 2);
    this.select (cx - sel.height/2, cy - sel.width /2, sel.height, sel.width);
};

/* 
 * Select the entire image
 */
PXN8.selectAll = function() 
{
    this.sx = 0;
    this.sy = 0;
    this.ex = PXN8.image.width;
    this.ey = PXN8.image.height;
    this.selectArea(); 
};
/*
 * Unselect the image
 */
PXN8.unselect = function () 
{
    var dom = PXN8.dom;
    
    this.sx = 0;
    this.sy = 0;
    this.ex = 0;
    this.ey = 0;   
    var selectionDiv = dom.id("pxn8_select_rect");
    selectionDiv.style.display = "none";
    
    
    var topRect = dom.id("pxn8_top_rect");
    topRect.style.borderWidth = "1px";
    
    topRect.style.display = "none";
    
    var bottomRect = dom.id("pxn8_bottom_rect");
    bottomRect.style.borderWidth = "1px";
    
    bottomRect.style.display = "none";
    
    var leftRect = dom.id("pxn8_left_rect");
    leftRect.style.display = "none";
    leftRect.style.borderWidth = "0px";
    
    
    dom.id("pxn8_right_rect").style.display = "none";
    
    /*
     * update the field values
     */  
    PXN8.show.position();

    PXN8.show.selection();
    
    this.listener.notify(PXN8.ON_SELECTION_CHANGE);
};

/*
 * Update the display so that it reflects the current selection rectangle
 */
PXN8.selectArea = function()
{
    var dom = PXN8.dom;
    
    var selectRect = dom.id("pxn8_select_rect");
    var theImg = dom.id("pxn8_image");
    var leftRect = dom.id("pxn8_left_rect");
    var rightRect = dom.id("pxn8_right_rect");
    var topRect = dom.id("pxn8_top_rect");
    var bottomRect = dom.id("pxn8_bottom_rect");
    /*
     * has any selection been made yet ?
     */
    if (this.sx <=0 && this.sy <= 0 && this.ex <= 0 && this.ey <= 0){
        selectRect.style.display = "none";
        leftRect.style.display = "none";
        rightRect.style.display = "none";
        topRect.style.display = "none";
        bottomRect.style.display = "none";

        PXN8.listener.notify(PXN8.ON_SELECTION_CHANGE);
        
        return;
    }

    var t = this.ey > this.sy?this.sy:this.ey;
    var l = this.ex > this.sx?this.sx:this.ex;
    var w = this.ex > this.sx?this.ex-this.sx:this.sx-this.ex;
    var h = this.ey > this.sy?this.ey-this.sy:this.sy-this.ey;

    if (((this.ex * PXN8.zoom.value()) > theImg.width) ||
        ((this.ey * PXN8.zoom.value()) > theImg.height)){
        return;
    }
    
    leftRect.style.display = "block";
    leftRect.style.top = "0px";
    leftRect.style.left = "0px";
    leftRect.style.width = (this.sx * PXN8.zoom.value())+ "px";
    leftRect.style.height = theImg.height + "px";
    
    rightRect.style.display = "block";
    rightRect.style.top = "0px";
    rightRect.style.left = (this.ex * PXN8.zoom.value()) + "px";
    rightRect.style.width = (theImg.width - (this.ex * PXN8.zoom.value())) + "px";
    rightRect.style.height = theImg.height + "px";
    
    topRect.style.display = "block";
    topRect.style.top = "0px";
    topRect.style.left = (l* PXN8.zoom.value()) + "px";
    topRect.style.width = (w* PXN8.zoom.value()) + "px";
    topRect.style.height = (t* PXN8.zoom.value()) + "px";

    bottomRect.style.display = "block";
    bottomRect.style.top = ((t+h)* PXN8.zoom.value()) + "px";
    bottomRect.style.left = (l* PXN8.zoom.value()) + "px";
    bottomRect.style.width = (w* PXN8.zoom.value()) + "px";
    bottomRect.style.height = (theImg.height - (this.ey* PXN8.zoom.value())) + "px";
    
    
    selectRect.style.top  = (t* PXN8.zoom.value()) + "px";
    selectRect.style.left = (l* PXN8.zoom.value()) + "px";
    selectRect.style.width = (w* PXN8.zoom.value()) + "px";
    selectRect.style.height = (h* PXN8.zoom.value()) + "px";
    selectRect.style.display = "block";
    
    selectRect.style.zIndex = "100";
    /*
     * update the field values
     */  
    PXN8.position.x = l;
    PXN8.position.y = t;

    PXN8.show.position();
    PXN8.show.selection();
    
    PXN8.listener.notify(PXN8.ON_SELECTION_CHANGE);
};

/* ============================================================================
 *
 * Functions related to PXN8 listeners
 */
PXN8.listener = {
    /**
     * A map of listeners by event type
     */
    listenersByType : {}
};
PXN8.listener.listenersByType[PXN8.ON_ZOOM_CHANGE] = [];
PXN8.listener.listenersByType[PXN8.ON_SELECTION_CHANGE] = [];
PXN8.listener.listenersByType[PXN8.ON_IMAGE_CHANGE] = [];
PXN8.listener.listenersByType[PXN8.ON_IMAGE_ERROR] = [];

/**
 * -- function PXN8.listener.add
 * -- description Adds a new callback function to the list of functions to be called when a PXN8 event occurs.
 * -- param eventType (ON_ZOOM_CHANGE, ON_IMAGE_CHANGE, ON_SELECTION_CHANGE etc)
 * -- param callback The function to be called when the event occurs
 */
PXN8.listener.add = function (eventType,callback) 
{
    var callbacks = this.listenersByType[eventType];
    var found = false;
    if (!callbacks){
        callbacks = [];
        this.listenersByType[eventType] = callbacks;
    }
    for (var i = 0;i < callbacks.length; i++){
        if (callbacks[i] == callback){
            found = true;
            break;
        }
    }
    if (!found){
        callbacks.push (callback);
    }
};
/**
 * -- function PXN8.listener.remove
 * -- description Removes a callback function from the list of functions to be called when a PXN8 event occurs
 * -- param eventType (ON_ZOOM_CHANGE, ON_IMAGE_CHANGE, ON_SELECTION_CHANGE etc)
 * -- param callback The function to be removed.
 */
PXN8.listener.remove = function (eventType, callback)
{
    var callbacks = this.listenersByType[eventType];
    if (!callbacks) return;
    
    for (var i = 0;i < callbacks.length; i++){
        if (callbacks[i] == callback){
            callbacks.splice(i,1);
        }
    }
};
/**
 * -- function PXN8.listener.onceOnly
 * -- description A special-case of listener that only performs once and once only.
 * -- param eventType (ON_ZOOM_CHANGE, ON_IMAGE_CHANGE, ON_SELECTION_CHANGE etc)
 * -- param callback The function to be called when the event occurs (only called once then removed from list)
 */
PXN8.listener.onceOnly = function (eventType,callback)
{
    var wrappedCallback = null;
    wrappedCallback = function(){
        callback();
        PXN8.listener.remove(eventType,wrappedCallback);
    };
    this.add(eventType, wrappedCallback);
};

/**
 * -- function PXN8.listener.notify
 * -- description Called by various methods to notify listeners  
 * -- param eventType (ON_ZOOM_CHANGE, ON_IMAGE_CHANGE, ON_SELECTION_CHANGE etc)
 */ 
PXN8.listener.notify = function(eventType,source)
{
    var listeners = this.listenersByType[eventType];
    if (listeners){
        for (var i = 0; i < listeners.length; i++){
            var listener = listeners[i];
            if (listener != null){
                listener(eventType,source);
            }
        }
    }
};

/* ============================================================================ 
 *
 * the log object has a single method 'append'
 * If your edit page has an element with id 'pxn8_log' then ...
 * PXN8.log.append('hello world') 
 * ... will append a new paragraph with 'hello world' as the text to the div.
 */
PXN8.log = { };

PXN8.log.append = function(str)
{
    var dom = PXN8.dom;
    
    var log = dom.id("pxn8_log");
    if (log){
        if (typeof str == "string"){
            var line = dom.ce("div");
            dom.ac(line,dom.tx(str));
            dom.ac(log,line);
        }else if (typeof str == "object"){
            var s = PXN8.objectToString(str);
            var line = dom.ce("div");
            line.appendChild(dom.tx(s));
            dom.ac(log,line);
        }
    }
};

/* ============================================================================ */

/**
 * Define the PXN8.zoom namespace
 */ 
PXN8.zoom = {

    values: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2, 3, 4 ],
    index: 3,
    zoomedBy: 1.0,

    value : function(){
        return this.zoomedBy;
    },
    canZoomIn : function(){
        return this.zoomedBy < this.values[this.values.length-1];
    },
    canZoomOut : function(){
        return this.zoomedBy > this.values[0];
    }
};

/**
 * Zoom in (increase Magnification level)
 */
PXN8.zoom.zoomIn = function()
{
    if (this.canZoomIn())
    {
        for (var i = 0; i < this.values.length;i++){
            if (this.values[i] > this.zoomedBy){
                this.index = i;
                this.zoomedBy = this.values[i];
                break;
            }
        }

        var theImg = document.getElementById("pxn8_image");
        theImg.width = PXN8.image.width * this.value();
        theImg.height = PXN8.image.height * this.value();

        PXN8.selectArea();
                
        /**
         * Notify listeners
         */
        PXN8.listener.notify(PXN8.ON_ZOOM_CHANGE);
    }else{
        PXN8.show.alert(PXN8.strings.NO_MORE_ZOOMIN,500);
    }
    // return false in case this is called from a link
    return false; 
};

/**
 * Zoom out (decrease Magnification level)
 */
PXN8.zoom.zoomOut = function()
{
    if (this.canZoomOut()){
        for (var i = this.values.length-1; i >= 0; i--){
            if (this.values[i] < this.zoomedBy){
                this.index = i;
                this.zoomedBy = this.values[i];
                break;
            }
        }
        var theImg = document.getElementById("pxn8_image");
        theImg.width = PXN8.image.width * this.value();
        theImg.height = PXN8.image.height * this.value();
        PXN8.selectArea();
        
        /**
         * Notify listeners
         */
        PXN8.listener.notify(PXN8.ON_ZOOM_CHANGE);
        
    }else{
        PXN8.show.alert(PXN8.strings.NO_MORE_ZOOMOUT,500);
    }
    return false;
};

/**
 * Zoom the image to a fixed size
 *
 * @param width The desired image width
 * @param height The desired image height
 * @returns nothing
 */        
PXN8.zoom.toSize = function(width, height)
{
    var hr = width / PXN8.image.width ;
    var vr = height / PXN8.image.height ;
    if (vr < hr){
        this.zoomedBy = vr;
    }else{
        this.zoomedBy = hr;
    }
    // what happens to previous zoom level ?
    // it gets set to the closest to the current
    // zoomedBy value
    //
    for (var i = 0; i < this.values.length;i++){
        if (this.values[i] < this.zoomedBy){
            this.index = i+1;
        }else{
            break;
        }
    }
    if (this.index >= this.values.length){
        this.index = this.values.length -1;
    }
    
    var theImg = document.getElementById("pxn8_image");
            
    theImg.width = PXN8.image.width * this.value();
    theImg.height = PXN8.image.height * this.value();
    PXN8.selectArea();
    PXN8.listener.notify(PXN8.ON_ZOOM_CHANGE);
    return false;
};

/**
 * Restore the zoom settings whenever the image is updated
 */
PXN8.zoom.onImageLoad = function(eventType,image)
{
    
    //
    // wph 20060808 Need to put this function on a timeout or else
    // the editor will think that the zoomed size is the image's real size
    // this is because callbacks added via the DOM event mechanism get called
    // before the image.onload is called. The image.onload handler assumes that the 
    // image has not been resized, so don't do anything that would change the image
    // size before the image.onload is called.
    //
    setTimeout(function(){
        var zoomFactor = PXN8.zoom.value();
        var ow = image.width;
        var oh = image.height;
        var nw = ow * zoomFactor;
        var nh = oh * zoomFactor;
        
        image.width = nw;
        image.height = nh;

        PXN8.dom.opacity(image,100);
        
        PXN8.selectArea();

        PXN8.listener.notify(PXN8.ON_ZOOM_CHANGE);
    },50);
};

PXN8.listener.add(PXN8.ON_IMAGE_LOAD,PXN8.zoom.onImageLoad);



                   
/* ============================================================================
 *
 * Miscellaneous top-level functions
 *
 */

/**
 * -- function getUncompressedImage
 * -- description Returns the relative URL to the uncompressed 100% quality image
 */
PXN8.getUncompressedImage = function()
{
    if (PXN8.responses[PXN8.opNumber]){
        return PXN8.responses[PXN8.opNumber].uncompressed;
    } else {
        return false;
    }
};

/**
 * -- function getScript
 * -- description Return a list of all the operations which have been performed (doesn't include undone operations)
 */
PXN8.getScript = function()
{
    var result = new Array();
    for (var i = 0;i <= this.opNumber; i++){
        var operation = {};
        for (var j in this.history[i]){
            operation[j] = this.history[i][j];
        }
        result.push(operation);
    }
    return result;
};
/**
 * Returns the current script as a string
 */
PXN8.getScriptAsString = function(script)
{
    var result = "";
    script = script || PXN8.getScript();
    for (var i = 0;i < script.length; i++){
        var item = script[i];
        result = result + item.operation;
        var props = new Array();
        /**
         * Sort properties alphabetically
         */
        for (var property in item){
            /**
             * wph 20060719: JSON library interferes with Object.prototype
             * so toJSONString() shows up in all objects.
             * To get around this omit all function() attributes.
             */
            if (property != "operation" 
                && typeof item[property] != "function"){
                props.push(property);
            }
        }
        props.sort();
        
        for (var j = 0; j < props.length; j++){
            result = result + "\t" + props[j] + "=" + item[props[j]] ;
        }
        result = result + "\n";
    }
    return result;
};
/**
 * -- function curry
 * -- description Currying is a way of 'baking-in' an object to a function
 * Its a way of permanently binding an object and a function together
 * in effect create a new distinct function with the object embedded in it.
 * It's one of the cool higher-order programming features of dynamic languages
 * like Javascript and Perl.
 * PXN8.curry is a functor - a function which returns a function
 * -- param object The object to be baked in to the function
 * -- param func The function into which the object will be baked. 
 */
PXN8.curry = function(func,object)
{
    return function(){
        return func(object);
    };
};


/*
 * Update the UI to inform the user that the image is being updated 
 * The msg param is optional - it contains text that will be displayed 
 * at the top of the image. In most cases this is simply 'Updating image. Please wait...'
 * but it can be different - e.g. 'Saving image. Please wait...'
 */
PXN8.prepareForSubmit = function(msg)
{
    var dom = PXN8.dom;

    if (!msg){
        msg = PXN8.strings["UPDATING"];
    }        

    var timer = dom.id("pxn8_timer");
    if (!timer){
        timer = dom.ce("div",{id: "pxn8_timer"});
        dom.ac(timer,dom.tx(msg));
	     var canvas = dom.id("pxn8_canvas");
        
        //dom.ac(document.body,timer);
        dom.ac(canvas,timer);
    }
    
    if (timer){
        dom.ac(dom.cl(timer),dom.tx(msg));
        timer.style.display = 'block';
        var theImage = dom.id("pxn8_image");
        var imagePos = PXN8.dom.ep(theImage);
        timer.style.width  = (theImage.width>200?theImage.width:200) + "px";
    }
    PXN8.updating = true;
};

/**
 * For a given point calculate it's real location when 
 * the scroll area is taken into account.
 */
PXN8.scrolledPoint = function (x,y)
{
    var result = {"x":x,"y":y};

    var canvas = document.getElementById("pxn8_canvas");
    if (canvas.parentNode.id == "pxn8_scroller"){
        var scroller = document.getElementById("pxn8_scroller");
        result.x += scroller.scrollLeft;
        result.y += scroller.scrollTop;
    }
    return result;
};
    

/**
 * -- function createPin
 * -- description Create a pin for placing on top of an image
 * -- param pinId The unique Id to be given to the created pin image
 * -- param imgSrc The image src attribute
 */
PXN8.createPin = function (pinId,imgSrc)
{
    var pinElement = document.createElement("img");
    pinElement.id = pinId;
    pinElement.className = "pin";
    pinElement.src = imgSrc;
    pinElement.style.position = "absolute";
    pinElement.style.width = "24px";
    pinElement.style.height = "24px";
    return pinElement;
};

/**
 * -- function mousePointToElementPoint
 * -- description Convert a mouse event point to a relative point for a given element
 * -- param mx The x value for the mouse event
 * -- param my The y value for the mouse event
 */
PXN8.mousePointToElementPoint = function(mx,my)
{
    var dom = PXN8.dom;
    var result = {};
    var canvas = dom.id("pxn8_canvas");
    var imageBounds = dom.eb(canvas);
    var scrolledPoint = PXN8.scrolledPoint(mx,my);
    result.x = Math.round((scrolledPoint.x - imageBounds.x)/PXN8.zoom.value());
    result.y = Math.round((scrolledPoint.y - imageBounds.y)/PXN8.zoom.value());
    
    if (canvas.style.borderWidth){
        
        var borderWidth = parseInt(canvas.style.borderWidth);
        result.x -= borderWidth;
        result.y -= borderWidth;
        if (result.x < 0){
            result.x = 0;
        }
        if (result.y < 0){
            result.y = 0;
        }
    }
    return result;
};
/**
 * Convert an object to a string (used for debugging)
 */
PXN8.objectToString = function(obj)
{
    var s = "";
    
    var first = true;
    if (obj.length){
        // it's an array
        s = "[";
        for (var i = 0;i < obj.length; i++){
            if (typeof obj[i] == "string"){
                s += "\"" +  obj[i] + "\"";
            }else if (typeof obj[i] == "object"){
                s += PXN8.objectToString(obj[i]);
            }else{
                s += obj[i];
            }
            if (i < obj.length-1){
                s += ",";
            }
            
        }
        s += "]";
        
    }else{
        s = "{";
        for (var i in obj){
            if (first){
                s += i + " : ";
            }else{
                s += ", " + i + " : ";
            }
            first = false;

            if (typeof obj[i] == "string"){
                s += "\"" + obj[i] + "\"";
            }else if (typeof obj[i] == "object"){
                s += PXN8.objectToString(obj[i]);
            }else {
                s += obj[i];
            }
        }
        s += "}";
    }
    
    return s;
};

/**
 * Is an object an Array ?
 */
PXN8.isArray = function(o)
{
	return (o && typeof o == 'object') && o.constructor == Array;
};

/**
 * Return a random hexadecimal value in the range 0 - 65535 (0000 - FFFF)
 */
PXN8.randomHex = function()
{
    return (Math.round(Math.random()*65535)).toString(16)
};
/**
 * Replaces the current editing image with a new one
 */
PXN8.replaceImage = function(imageurl)
{
    var dom = PXN8.dom;
    var imageContainer = dom.cl(dom.id("pxn8_image_container"));

    var theImage = dom.ce("img",{id: "pxn8_image"});
    
    dom.ac(imageContainer,theImage);
    if (PXN8.zoom.value() != 1.0){
        PXN8.dom.opacity(theImage,1);
    }
    //
    // add the onload listener *BEFORE* setting the source for the 
    // listener to fire in IE.
    //
    PXN8.event.addListener(theImage,"load",PXN8.imageLoadNotifier);
    theImage.src = imageurl;

    PXN8.show.size();
};

/*
 * Called when the AJAX request has returned
 */
PXN8.imageUpdateDone = function (jsonResponse) 
{
    var dom = PXN8.dom;
    var targetDiv = dom.id("pxn8_image_container");
    PXN8.response = jsonResponse;

    if (PXN8.response.status == "OK"){
        
        var newImageSrc = PXN8.root + "/" + PXN8.response.image;
        PXN8.responses[PXN8.opNumber] = PXN8.response;
        //
        // wph 20060513: Workaround for IE's over-aggressive
        // image caching.
        // see IE bugs # 4
        // http://www.sourcelabs.com/blogs/ajb/2006/04/rocky_shoals_of_ajax_developme.html
	     //
        if (document.all){
            newImageSrc += "?rnd=" + PXN8.randomHex();
        }
        PXN8.replaceImage(newImageSrc);
    }else{
        alert("An error occurred while updating the image.\n",
              PXN8.response.status);
        PXN8.listener.notify(PXN8.ON_IMAGE_ERROR);
    }

    PXN8.log.append(jsonResponse);
    

    
    var timer = dom.id("pxn8_timer");
    if (timer){
        timer.style.display = "none";
    }
    PXN8.updating = false;
    PXN8.priv.postImageLoad();
};




/*
 * This is a keypress handler,
 * The supplied function is only invoked if the Enter key is pressed.
 * This function has been deprecated in favour of using form.onsubmit
 * to perform image operations.
 */
PXN8.onEnterKey = function(element,func)
{
    element.onkeypress = function(evt){
        evt = evt || window.event;
        var charCode = (evt.charCode) ?evt.charCode :((evt.which) ?evt.which :evt.keyCode);
        if (charCode == 13 || charCode == 3){
            if (func){
                func();
                return false;
            }
        }
        return true;
    };
};

/*
 * Called when the user clicks 'fetch' or hits enter in the 
 * image url field.
 */
PXN8.loadImage = function( imageLoc ){

    PXN8.image.location = imageLoc;
    
    PXN8.opNumber = 0;
    PXN8.maxOpNumber = 0;
    
    PXN8.history = new Array();

    var fetchOp = {operation: "fetch",
                   image: escape(escape(PXN8.image.location))};

    PXN8.history.push(fetchOp);
    
    if (PXN8.replaceOnSave){
        fetchOp.random = PXN8.randomHex();
    }

    PXN8.unselect();

    PXN8.replaceImage(PXN8.image.location);
    
    PXN8.priv.postImageLoad();
};



/* ============================================================================
 *
 * FUNCTIONS TO DISPLAY IMAGE INFORMATION
 */
PXN8.show = {};

/**
 * display selection info 
 */
PXN8.show.selection = function()
{
    var dom = PXN8.dom;
    
    var selectionField = dom.id("pxn8_selection_size");
    if (selectionField){
        var text = "N/A";
        if (PXN8.ex - PXN8.sx > 0){
            text = (PXN8.ex-PXN8.sx) + "," + (PXN8.ey-PXN8.sy);
        }
        dom.ac(dom.cl(selectionField),dom.tx(text));
    }
};

/**
 * display position info 
 */
PXN8.show.position = function()
{
    var dom = PXN8.dom;
    
    var posInfo = dom.id("pxn8_mouse_pos");
    if (posInfo){
        var text = PXN8.position.x + "," + PXN8.position.y;
        dom.ac(dom.cl(posInfo),dom.tx(text));
    }
};

/**
 * display position info 
 */
PXN8.show.zoom = function()
{
    var dom = PXN8.dom;
    
    var zoomInfo = dom.id("pxn8_zoom");
    if (zoomInfo){
        var text = Math.round((PXN8.zoom.value() * 100)) + "%";
        dom.ac(dom.cl(zoomInfo),dom.tx(text));
    }
};

/**
 * display size info 
 */
PXN8.show.size = function ()
{
    var dom = PXN8.dom;
    var sizeInfo = dom.id("pxn8_image_size");
    if (sizeInfo){
        var text = PXN8.image.width + "x" + PXN8.image.height;
        dom.ac(dom.cl(sizeInfo),dom.tx(text));
    }
};

/**
 * Display a soft alert that disappears after a short time
 */
PXN8.show.alert = function (message,duration)
{
    var dom = PXN8.dom;

    duration = duration || 1000;
    
    var warning = dom.id("pxn8_warning");
    if (!warning){
        warning = dom.ce("div",{id: "pxn8_warning",className: "warning"});
    }
    
    warning.style.width  = (PXN8.image.width>200?PXN8.image.width:200) + "px";

    dom.ac(dom.cl(warning),dom.tx(message));
    dom.ac(dom.id("pxn8_canvas"),warning);
    
    setTimeout("PXN8.fade.init();PXN8.fade.fadeout('pxn8_warning',true);",duration);
};



/* ============================================================================
 *
 * Fade functions - make a HTML element fade in and out
 */

PXN8.fade = {
	values: [0.99,0.85, 0.70, 0.55, 0.40, 0.25, 0.10, 0],
	times:      [75, 75,  75,  75,  75,  75,  75,  75],
	i: 0,
	stopfadeout: false
};

PXN8.fade.init = function(){ this.i =0; this.stopfadeout = false;};

PXN8.fade.cancel = function(){ this.stopfadeout = true; };

PXN8.fade.fadeout = function(eltid,destroyOnFade)
{
    var dom = PXN8.dom;
    
    if (this.stopfadeout){
        return;
    }
    dom.opacity(dom.id(eltid),this.values[this.i]);
    if (this.i < this.values.length -1 ){
        this.i++;
        setTimeout("PXN8.fade.fadeout('" + eltid + "'," + destroyOnFade + ");",this.times[this.i]);
    }else{
        if (destroyOnFade){
            var node = dom.id(eltid);
            // it's quite possible that the element has already been destroyed !
            if (!node){
                return;
            }else{
                var parent = node.parentNode;
                parent.removeChild(node);
            }
        }
    }
};

PXN8.fade.fadein = function(eltid)
{
    var dom = PXN8.dom;
    try{
        if (this.i >= this.values.length){
            this.i = this.values.length - 1;
        }
        dom.opacity(dom.id(eltid),this.values[this.i]);
        if (this.i > 0){
            this.i--;
            setTimeout("PXN8.fade.fadein('" + eltid + "');",this.times[this.i]);
        }
    }catch(e){
        alert(e);
    }
};





/* ============================================================================
 *
 * PRIVATE FUNCTIONS and members internal to PXN8 only - do not call from client code
 */

PXN8.priv = {
};

PXN8.priv.addImageToHistory = function(imageLocation)
{
    PXN8.log.append(" addImageToHistory (" + imageLocation + " " + PXN8.image.width + "," + PXN8.image.height + ")");

    var item = {"location": imageLocation,
                "width": PXN8.image.width,
                "height": PXN8.image.height
    };
            
    PXN8.images[PXN8.opNumber] = item;

    for (var i = 0; i <= PXN8.maxOpNumber; i++){
        var item = PXN8.images[i];
        if (item){
            PXN8.log.append("-- [" +i+ "] " + item.location + " " + item.width + "," + item.height);
        }
    }
    PXN8.log.append("---------");
};

/*
 * This function is called at the end of imageUpdateDone and at the end of loadImage
 */
PXN8.priv.postImageLoad = function()
{
    var dom = PXN8.dom;
    var theImage = dom.id("pxn8_image");
    theImage.onerror = function(){
        alert(PXN8.strings.IMAGE_ON_ERROR1 + theImage.src + PXN8.strings.IMAGE_ON_ERROR2);
        PXN8.listener.notify(PXN8.ON_IMAGE_ERROR);
    };
    
    var onloadFunc = function(){
        
	     PXN8.log.append("image " + theImage.src + " has loaded");	     

        PXN8.image.width = theImage.width;
        PXN8.image.height = theImage.height;
        
        PXN8.show.size();
        
        PXN8.priv.addImageToHistory(theImage.src);
        
        if (PXN8.sx > PXN8.image.width || 
            PXN8.ex > PXN8.image.width || 
            PXN8.sy > PXN8.image.height || 
            PXN8.ey > PXN8.image.height)
        {
            PXN8.unselect();
        }else{
            // the surrounding darkened rects might now 
            // extend beyond the bounds of the image 
            // so ...
            PXN8.selectArea();
        }

        PXN8.imagesBySrc[theImage.src] = true;
        PXN8.listener.notify(PXN8.ON_IMAGE_CHANGE);
        PXN8.show.zoom();        
    };
    //
    // IE Bug: If an image with the same URL has already been loaded
    // then the onload method is never called - need to explicitly call the
    // onloadFunc method so that listeners get notified etc.
    //
    if (PXN8.imagesBySrc[theImage.src]){
        onloadFunc();
    }else{
        theImage.onload = onloadFunc;
    }

    PXN8.show.zoom();
};


/**
 * Create the selection area if it's not already defined.
 */
PXN8.priv.createSelectionRect = function()
{
    var dom = PXN8.dom;
    var selectRect = dom.id("pxn8_select_rect");
    if (!selectRect){
        var canvas = dom.id("pxn8_canvas");
        selectRect = dom.ac(canvas, dom.ce("div", {id: "pxn8_select_rect"}));
        selectRect.style.backgroundColor = "white";
        dom.opacity(selectRect,0);
        selectRect.style.cursor = "move";
        selectRect.style.borderWidth  = "1px";
        selectRect.style.borderColor = "red";
        selectRect.style.borderStyle = "dotted";
        selectRect.style.position = "absolute";
        selectRect.style.zIndex = 1;
        selectRect.style.fontSize = "0px";
        selectRect.style.display = "block";
        selectRect.style.width = "0px";
        selectRect.style.height = "0px";
    }
    selectRect.onmousedown = function(event){ 
        if (!event) event = window.event;
        PXN8.drag.begin(selectRect,event,
                        PXN8.drag.moveSelectionBoxHandler,
                        PXN8.drag.upSelectionBoxHandler);
    };
    return selectRect;
};

/* 
 * END OF DECLARATIONS SECTION
 * ============================================================================
 */

PXN8.listener.add(PXN8.ON_IMAGE_CHANGE, PXN8.show.zoom);
PXN8.listener.add(PXN8.ON_ZOOM_CHANGE, PXN8.show.zoom);
/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles AJAX / JSON requests
 *
 */

var PXN8 = PXN8 || {};
PXN8.ajax = {};

PXN8.ajax.createRequest = function(){

	if (typeof XMLHttpRequest != 'undefined') {
   	 return new XMLHttpRequest();
   }	
   try 	{
       return new ActiveXObject("Msxml2.XMLHTTP");
   } catch (e) {
       try {
           return new ActiveXObject("Microsoft.XMLHTTP");
       } catch (e) { }
   }
   return false;
};



/**
 * Submit a series of image-manipulation commands to the server
 */
PXN8.ajax.submitScript = function(script, callback)
{
    var req = PXN8.ajax.createRequest();
    
    PXN8.json.bind(req,callback,function(r){
        alert(PXN8.strings.WEB_SERVER_ERROR + "\n" + r.statusText + "\n" + r.responseText) ;
        var timer = document.getElementById("pxn8_timer");
        if (timer){
            timer.style.display = "none";
        }
        PXN8.updating = false;
    });
    
    req.open("POST", PXN8.root + "/pxn8.pl", true);
    req.setRequestHeader('Content-Type', 
                         'application/x-www-form-urlencoded');
 
    var scriptToText = PXN8.getScriptAsString(script);

    var submission = "script=" + scriptToText;
    
    req.send(submission);
    
};


/**
 * Add an new image operation to the list of existing ops and 
 * submit it to the server for processing.
 */
PXN8.ajax.submitOperation = function(operation, callback)
{
    /**
     * Construct a script for the image processor
     */
    var allops = new Array();
    for (var i = 0;i < PXN8.opNumber; i++){
        allops.push(PXN8.history[i]);
    }
    allops.push(operation);

    PXN8.prepareForSubmit();
    PXN8.ajax.submitScript(allops,callback);
    
};

PXN8.json = {};

PXN8.json.bind = function(request,callback,onerror)
{
    request.onreadystatechange = function(){
        if (request.readyState == 4) {
            
            if (request.status == 200) {
                var json ;
                
                try{
                    json  = eval('('+ request.responseText + ')');
                }catch (e){
                    alert("An exception occured tring to evaluate server response:\n" +
                          request.responseText);
                }
                callback(json);
            } else {
                if (onerror){
                    onerror(request);
                }else{
                    alert(PXN8.strings.WEB_SERVER_ERROR + "\n" + request.statusText + "\n" + request.responseText) ;
                }
            }
        }
    };
};

/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles event managment
 *
 */
var PXN8 = PXN8 || {};

PXN8.event = {
    /**
     * Add a new event handler 
     */
    addListener: function(el,eventstr,func){
        if (el.addEventListener){
            el.addEventListener(eventstr,func,true);
        }else if (el.attachEvent){
            el.attachEvent("on" + eventstr,func);
        }
    },
    /**
     * remove an event handler 
     */
    removeListener: function(el,eventstr,func){
        if (el.removeEventListener){
            el.removeEventListener(eventstr,func,true);
        }else if (el.detachEvent){
            el.detachEvent("on" + eventstr,func);
        }
    },
	
    /**
     * PXN8.event.closure creates an event closure 
     * Parameters: object The object to be baked into the event handler
     * func - The event handler (a function)
     * The closure returned will take 4 parameters...
     * object: The object that has been baked in.
     * source: The HTML element that triggered the event
     * event: The event which triggered the function call.
     * caller: The closure itself - this will not be the same as the function passed into PXN8.event.closure.
     */
    closure: function(object,func){
        return function(event){
            event = event || window.event;
            var source = (window.event) ? event.srcElement : event.target;
            func(event,object,source,arguments.callee);
        };
    },
    /**
     * Creates an event handler where the source, and event are guaranteed to be present and correct
     * It does things like normalizing the event (removing IE & firefox discrepancies)
     */
    normalize: function(func){
        return function(event){
            event = event || window.event;
            var source = (window.event) ? event.srcElement : event.target;
            func(event,source,arguments.callee);
        };
    }
};

/**
 * Bind event-handling behaviour to all elements of a particular class
 */
PXN8.behaviour = {
    
    bind: function(className,behaviourObject){
        var elements = PXN8.dom.clz(className);
        for (var i = 0;i < elements.length; i++)
        {
            for (var j in behaviourObject){
                PXN8.event.addListener(elements[i],j,behaviourObject[j]);
            }
        }
    }
};
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

/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles saving of images
 *
 */
var PXN8 = PXN8 || {};

/* ============================================================================ 
 *
 * Functions for saving the image to different locations
 */

PXN8.save = {};

PXN8.save.toDisk = function()
{
    var uncompressedImage = PXN8.getUncompressedImage();
    if (uncompressedImage){
        var newURL = PXN8.root + "/save.pl?";
        
        if (typeof pxn8_original_filename == "string"){
            newURL += "originalFilename=" + pxn8_original_filename + "&";
        }
        
        newURL += "image=" + uncompressedImage;
        
        document.location = newURL;
            
    }else{
        document.location = "#";
        PXN8.show.alert("You have not changed the image !");
    }
};

/**
 * Save image to flickr
 * This method should be called from your form's onsubmit attribute.
 * See the examples in slick and default templates.
 */
PXN8.save.toFlickr = function(form)
{
    if (typeof form == 'undefined'){
        alert("Incorrect use of PXN8.save.toFlickr - this should be called via a form's onsubmit attribute");
        return false;
    }
    if (PXN8.opNumber == 0){
        PXN8.show.alert("You have not changed the image !");
        return false;
    }
    /* 
     * Need to add an additional field to the form before
     * saving.
     */
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = "img";
    input.value = PXN8.getUncompressedImage();
    form.appendChild(input);
    return true;
};

/*
 * Save the image to CNET's AllYouCanUpload photo-storage service
 * N.B. This is an ALPHA function until CNET release an API
 * as of June 28 2006 It relies on a screen-scraping perl program on the 
 * server side. You have been warned.
 */
PXN8.save.allyoucanupload = function()
{
    var dom = PXN8.dom;

    PXN8.prepareForSubmit('Saving image. Please wait...');
    
    var req = PXN8.ajax.createRequest();
    req.open("GET", PXN8.root + "/allyoucanupload.pl?image=" + PXN8.getUncompressedImage(),true);
    PXN8.json.bind(req, function(response){
        var timer = document.getElementById("pxn8_timer");
        if (timer){
            timer.style.display = "none";
        }
        PXN8.updating = false;
        prompt("Here is the permanent URL for your image.\n" + 
               "Copy and paste this URL into your blog, myspace or bebo page.",
               response.original_image);
    });
    req.send(null);
};
/**
 * Save to server is a wrapper function.
 * This function is called by the pxn8 toolbar.
 * You should define your own function called 'pxn8_save_image()'
 */
PXN8.save.toServer = function()
{
    var relativeFilePathToUncompressedImage = PXN8.getUncompressedImage();
    if (!relativeFilePathToUncompressedImage){
        alert("The image has not been modified.");
        return false;
    }
    
    if (typeof pxn8_save_image == 'function'){
        return pxn8_save_image(relativeFilePathToUncompressedImage);
    } else {
    
        alert("This feature is not available by default.\n" +
              "To enable this feature you must create a PHP,ASP or JSP page to save the image to your own server.\n" +
              "You must also create a javascript function called 'pxn8_save_image()' - it's first parameter is the URL of the changed image.\n" +
              "The path to the changed image (relative to the directory where PXN8 is installed) is " + PXN8.getUncompressedImage());
        return false;
    }
    
};


/**
 * (c) 2006 Sxoop Technologies Ltd.
 * 
 * This javascript file defines all of the image operations used by 
 * pxn8_tools_ui.js
 *
 */

var PXN8 = PXN8 || {};


/**
 * First define a namespace for all the tools
 */

PXN8.tools = {};

PXN8.tools.history = function (offset)
{
    if (offset == 0){
        return;
    }
    if (PXN8.updating){
        alert (PXN8.strings.IMAGE_UPDATING);
        return;
    }
    
    if (!offset) offset = -1;
    if (PXN8.opNumber == 0 && offset < 0){
        PXN8.show.alert(PXN8.strings.NO_MORE_UNDO);
        return;
    }
    if (PXN8.opNumber == PXN8.maxOpNumber && offset > 0){
        PXN8.show.alert(PXN8.strings.NO_MORE_REDO);
        return;
    }	
    
    if (offset < 0){
        PXN8.show.alert("- " + PXN8.history[PXN8.opNumber].operation, 500);
    }else{
        PXN8.log.append("redo: " + PXN8.opNumber);
        for (var i = 0;i < PXN8.history.length; i++){
            PXN8.log.append("redo: " + PXN8.history[i].operation);
        }
        PXN8.show.alert("+ " + PXN8.history[PXN8.opNumber+1].operation,500);
    }
    
    PXN8.opNumber = PXN8.opNumber + offset;

    var currentImageData = PXN8.images[PXN8.opNumber];

    if (!currentImageData){
        alert("Error! PXN8.images[" + PXN8.opNumber + "] is undefined");
        return false;
    }
    
    PXN8.image.location = currentImageData.location;
    PXN8.image.width = currentImageData.width;
    PXN8.image.height = currentImageData.height;
    
    // point image at the array element was bad !
    // changes to PXN8.image were also reflected in 
    // the array element leading to a long bug-tracking session
    // REMEMBER this !!!
    //PXN8.image = PXN8.images[PXN8.opNumber];

    PXN8.replaceImage(PXN8.image.location);

    PXN8.listener.notify(PXN8.ON_IMAGE_CHANGE);    

    PXN8.unselect();
    
    return false;
};


PXN8.tools.undo = function()
{
    PXN8.tools.history(-1);
    return false;
};

PXN8.tools.redo = function()
{
    PXN8.tools.history(+1);
    return false;
};

PXN8.tools.undoall = function()
{
    PXN8.tools.history(0 - PXN8.opNumber);
    return false;
};

PXN8.tools.redoall = function()
{
    PXN8.tools.history(PXN8.maxOpNumber-PXN8.opNumber);
    return false;
};

/**
 * All image operations which require server-side intervention go through
 * this function. This function constructs an URL from the supplied parameters
 * and invokes an XMLHTTPRequest
 */
PXN8.tools.updateImage = function(op)
{
    var executed = true;
    
    /**
     * Don't go to the server unless it's a different operation
     * to one that has been undone
     */

    //
    // at the first op, history.length = 1 (fetch) and opNumber = 0.
    //
    if (PXN8.maxOpNumber > PXN8.opNumber){
        var lastUndoneOp = PXN8.history[PXN8.opNumber+1];
        for (var i in op){
            if (lastUndoneOp[i] == op[i]){
            }else{
                executed = false;
                break;
            }
        }
    }else{
        executed = false;
    }
    
    if (!executed){

        /**
         * wph 20060909 : Don't increment PXN8.opNumber unless the
         * last operation has completed.
         */
        if (PXN8.updating){
            alert (PXN8.strings.IMAGE_UPDATING);
            return;
        }
        
        PXN8.history[++PXN8.opNumber] = op;
    
        PXN8.maxOpNumber = PXN8.opNumber;
        
        PXN8.ajax.submitOperation(op ,PXN8.imageUpdateDone);

    }else{
        PXN8.tools.redo();
    }
};

/**
 * Enhance an image: Normalizes the image (fixes color contrast) and removes
 * 'noise' from the image (useful for smoothing facial lines)
 *
 */
PXN8.tools.enhance = function()
{
    PXN8.tools.updateImage({operation: "enhance"});
};

/**
 *
 */
PXN8.tools.instantFix = function()
{
    PXN8.tools.updateImage({operation: "instant_fix"});
};

PXN8.tools.normalize = function()
{
    PXN8.tools.updateImage({operation: "normalize"});
};


/**
 * Fix the horizon on an image: Uses two points (left and right) to 
 * ascertain what the correct angle of the image should be.
 * 
 */
PXN8.tools.spiritlevel = function(x1,y1,x2,y2)
{
    PXN8.tools.updateImage({operation: "spiritlevel", 'x1': x1, 'x2': x2, 'y1': y1, 'y2':y2});
};

/**
 * Rotate an image or flip it
 * examples :
 *
 * to rotate an image 90 degrees clockwise...
 *
 * PXN8.tools.rotate({angle: 90, flipvt: false, fliphz: false});
 *
 * to flip an image along the horizontal pane (mirror image)
 *
 * PXN8.tools.rotate({fliphz: true});
 */
PXN8.tools.rotate = function(params)
{
    if (!params.angle){ 
        params.angle = 0;
    }
    if (params.fliphz == null){
        params.fliphz = false;
    }
    if (params.flipvt == null){
        params.flipvt = false;
    }
    params.operation = "rotate";

    if (params.angle > 0 || params.flipvt || params.fliphz){
        PXN8.tools.updateImage(params);
    }
};

/**
 * Blur an area of the image (or the entire image)
 * examples:
 * To blur the entire image with a radius of 2x2
 *
 * PXN8.tools.blur({radius: 2});
 *
 * To blur an area of the image...
 *
 * PXN8.tools.blur({radius: 2, top: 4, left: 40, width: 400, height: 200});
 */
PXN8.tools.blur = function (params)
{
    params.operation = "blur";
    PXN8.tools.updateImage(params);
};

/**
 * Change the brightness, saturation ,hue and contrast of an image
 * examples:
 *
 * To increase saturation by 40%...
 *
 * PXN8.tools.colors({saturation: 120});
 *
 * To increase contrast & reduce brightness by 20 %
 *
 * PXN8.tools.colors({contrast: 1, brightness: 80});
 *
 * To increase saturation, brightness, hue and contrast...
 *
 * PXN8.tools.colors ({brightness: 110, saturation: 110, hue: 180, contrast: 2});
 *
 * contrast must be in the range -3 to +3.
 * all other parameters must be in the range 0 - 200
 *
 */
PXN8.tools.colors = function(param)
{
    if (!param.saturation) param.saturation = 100;
    if (!param.brightness) param.brightness = 100;
    if (!param.hue) param.hue = 100;
    if (!param.contrast) param.contrast = 0;
    param.operation = "bsh";
    PXN8.tools.updateImage(param);
};

/**
 * Crop an image.
 * example:
 * 
 * PXN8.tools.crop({top: 10, left: 200, width: 40, height: 80});
 */
PXN8.tools.crop = function (params) 
{
    params.operation = "crop";
    PXN8.tools.updateImage(params);
};

/**
 * Apply a lens-filter to the image
 * example:
 * 
 * PXN8.tools.filter({top: 40, color: '#ff00ff', opacity: 80});
 * 
 * Applies a filter which will tail off at 40 pixels from the top of the image
 * and with a maximum opacity (at the top) of 80%.
 */
PXN8.tools.filter = function (params)
{
    //params.color = escape(params.color);
    params.operation = "filter";
    PXN8.tools.updateImage(params);
};

/**
 * Adds TV-like scan-lines to the image
 * example:
 * 
 * PXN8.tools.interlace({color: '#ffffff', opacity: 50 });
 * Adds white lines with opacity 50% to the image.
 */
PXN8.tools.interlace = function(params)
{
    //params.color = escape(params.color);
    params.operation = "interlace";
    PXN8.tools.updateImage(params);
};

/**
 * Adds a 'lomo' effect to the image
 * example:
 * 
 * PXN8.tools.lomo({opacity: 40, saturate: false});
 * Adds a lomo effect where the dark corners are at 40% opacity (the lower the opacity, the
 * darker the corners) and the image is not saturated.
 */
PXN8.tools.lomo = function(params)
{
    params.operation = "lomo";
    PXN8.tools.updateImage(params);
};

/**
 * Adds a fill-flash (brightens image subtly) effect to the image.
 */
PXN8.tools.fill_flash = function(brightness, threshold)
{
    PXN8.tools.updateImage({operation: "fill_flash"});
};

/**
 * Adds snowflakes to the image
 */
PXN8.tools.snow = function ()
{
    PXN8.tools.updateImage({operation: "snow"});
};
/**
 * Adds text to an image
 * params: gravity [North, South, Center, West, East, NW, SE etc]
 *         font (Arial, Courier, Times-Roman, Helvetica)
 *         fill (color)
 *         point-size (size of font in pt)
 *         text (The message to appear on the image)
 */
PXN8.tools.add_text = function(params)
{
	params.operation = "add_text";
	PXN8.tools.updateImage(params);
}
/**
 * Whitens teeth. 
 * example:
 *
 * PXN8.tools.whiten({top: 40, left: 60, width: 200, height: 75});
 */
PXN8.tools.whiten = function (params)
{
    params.operation = "whiten";
    PXN8.tools.updateImage(params);
};

/**
 * Fixes red-eye in indoor photos
 * example:
 *
 * PXN8.tools.fixredeye({top: 40, left: 60, width: 75, height: 75});
 */
PXN8.tools.fixredeye = function(params)
{
    params.operation = "redeye";
    PXN8.tools.updateImage(params);
};

/**
 * Resize an image to the specified width and height
 */
PXN8.tools.resize = function(width, height)
{
    PXN8.tools.updateImage({"operation": "resize", "width": width, "height": height});
};

/**
 * Add rounded corners to the image.
 */
PXN8.tools.roundedcorners = function(color, radius)
{
    PXN8.tools.updateImage({"operation":"roundcorners",
                                "color":color, 
                                "radius":radius});
};

/**
 * Add a sepia-tone effect to the image
 */
PXN8.tools.sepia = function(color)
{
    PXN8.tools.updateImage({"operation":"sepia","color":color});
};

/**
 * Make the image grayscale (black & white)
 */
PXN8.tools.grayscale = function()
{
    PXN8.tools.updateImage({"operation":"grayscale"});
};
/**
 * Create a charcoal drawing from an image
 */
PXN8.tools.charcoal = function(radius)
{
    PXN8.tools.updateImage({"operation" : "charcoal", "radius" : radius});
}

PXN8.tools.oilpaint = function(radius)
{
    PXN8.tools.updateImage({"operation" : "oilpaint", "radius" : radius});
}
/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code for handling hi-res images
 *
 */

var PXN8 = PXN8 || {};
// called when the hi-res update is complete
PXN8.ON_HIRES_COMPLETE = "ON_HIRES_COMPLETE";
PXN8.ON_HIRES_BEGIN = "ON_HIRES_BEGIN";


PXN8.hires = {
    originalURL: "",
    responses : [],
    jsonCallback : function(jsonResponse){
        PXN8.listener.notify(PXN8.ON_HIRES_COMPLETE,jsonResponse);
    }
};
/**
 * Given a series of commands, scale each of the commands to a certain ratio
 * Only certain commands need to be scaled
 * Any command with 'top','left','width','height' or 'radius' parameters needs 
 * to be scaled.
 */
PXN8.hires.scaleScript = function(script,ratio)
{
    var paramsToScale = ["left","width","top","height","radius"];

    for (var i = 0;i < script.length; i++){
        var op = script[i];
        for (var j = 0; j < paramsToScale.length; j++){
            var attr = paramsToScale[j];
            
            if (op[attr]){
                op[attr] = op[attr] * ratio;
            }
        }
    }
};

/**
 * Called whenever the image is updated by the user.
 */
PXN8.hires.doImageChange = function(eventType)
{
    var loRes = PXN8.images[0];
    var ratio = PXN8.hires.responses[0].height / loRes.height;
    
    var script = PXN8.getScript();
    script[0].image = PXN8.hires.originalURL;

    PXN8.hires.scaleScript(script,ratio);
    
    PXN8.log.append("about to submit: "+ PXN8.objectToString(script));
        
    PXN8.listener.notify(PXN8.ON_HIRES_BEGIN);
    PXN8.ajax.submitScript(script,PXN8.hires.jsonCallback);
    
};
/**
 * Initialize the Hi-Res Ajax Requestor
 * This will kick off a listener which will request an updated version of the hi-res image
 * whenever the user changes the lo-res version.
 */
PXN8.hires.init = function(imageUrl)
{
    PXN8.listener.add(PXN8.ON_HIRES_COMPLETE,function(eventType,jsonResponse){
        PXN8.hires.responses[jsonResponse.opNumber-1] = jsonResponse;
        PXN8.log.append("hires: "+ PXN8.objectToString(jsonResponse));
    });
    // set so that later calls will use same URL
    PXN8.hires.originalURL = imageUrl;
    
    var fetch = {operation: "fetch",
                 image: imageUrl,
                 pxn8root: PXN8.root,
                 random: Math.random()
    };
    PXN8.listener.notify(PXN8.ON_HIRES_BEGIN);
    PXN8.ajax.submitScript([fetch],PXN8.hires.jsonCallback);
    
    PXN8.listener.add(PXN8.ON_IMAGE_CHANGE,PXN8.hires.doImageChange);
    /**
     * over-ride the default PXN8.getUncompressedImage if in hi-res mode
     */
    PXN8.getUncompressedImage = PXN8.hires.getUncompressedImage;
};

/**
 * Get the path to the uncompressed hi-res edited image
 */
PXN8.hires.getUncompressedImage = function()
{
    var result = false;
    if (PXN8.hires.responses[PXN8.opNumber]){
        result = PXN8.hires.responses[PXN8.opNumber].uncompressed;
    }
    return result;
    
};

/* ============================================================================
 *
 * (c) 2005-2006 Sxoop Technologies Ltd. All rights reserved.
 *
 * For support contact support@sxoop.com
 *
 * These function handle sliders as used by some of the 
 * tool configuration panels.
 */
var PXN8 = PXN8 || {};
PXN8.slide = {};
/**
 * Turn a regular HTML div element into a slide
 */
PXN8.slide.bind = function(slideElement,inputElementId,startRange,rangeSize,initValue)
{
    slideElement.className = "pxn8_slide";
    slideElement.onmousedown = function(event){
        if (!event) event = window.event;
        PXN8.slide.onmousedown(slideElement,event,inputElementId,startRange,rangeSize);
    };
    var slider = document.createElement("span");
    slider.className = "pxn8_slider";
    slideElement.appendChild(slider);
    slider.style.left = (3 + (((initValue-startRange) / rangeSize) * 117)) + "px";
    
};

/**
 * This method is called when the user mousedowns on a div of class 'pxn8_slide'
 * Every div of class pxn8_slide should have a child div of class 'pxn8_slider'
 * The slide is the horizontal area through which the slider moves. The slider is the
 * bar indicator which indicates where the current position is in the slide.
 * 
 * |--------------------| slide
 *                 ^      slider
 * 
 * -- param slide The slide div
 * -- param event The mouse event which triggered this call (need to obtain position)
 * -- param inputId An input element whose value must be updated whenever the slider is moved
 * -- param start The start value (lowest possible value that can appear in the input element
 *          (basically the lowest in the range)
 * -- param size The range of values that can appear in the input element.
 */
PXN8.slide.onmousedown = function(slide,event,inputId,start,size)
{
    var kids = slide.getElementsByTagName("*");
    var slider = undefined;
    for (var i = 0; i < kids.length; i++){
        if (kids[i].className == "pxn8_slider"){
            slider = kids[i];
            break;
        }
    }
    slider.onmousemove = null;
    var inputElement = document.getElementById(inputId);
    
    slide.onmousemove = function(evt){ 
        return PXN8.slide.update(slider,
                                 inputElement,
                                 slide,
                                 evt,
                                 start,
                                 size);
    };
    slide.onmouseup = function(){ 
        slide.onmousemove = null; 
    };
    
    PXN8.slide.update(slider,inputElement,slide,event,start,size);    
};
/**
 *
 */
PXN8.slide.update = function(slider,inputElement,slide, evt,start,size)
{ 
    evt = (evt)?evt:window.event;
    var px = PXN8.slide.position(slide);
    var nx = evt.clientX - px;
    if (nx <= 120 && nx >= 3){
        slider.style.left = (nx-3) + "px";
        var iv = start + (((nx-3) / 117 ) * size);
        inputElement.value = Math.round(iv,2);
    }
};
/**
 * get the X position of an element relative to it's parent
 */
PXN8.slide.position = function (obj)
{
    var curleft = 0;
    if (obj.offsetParent)
    {
        while (obj.offsetParent)
        {
            curleft += obj.offsetLeft
                obj = obj.offsetParent;
        }
    }
    else if (obj.x)
        curleft += obj.x;
    return curleft;
};
/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles color selection
 *
 */
var PXN8 = PXN8 || {};

PXN8.colors = {};

PXN8.colors.values = ["#000000","#000033","#000066","#000099","#0000CC","#0000FF","#330000","#330033","#330066","#330099","#3300CC",
                      "#3300FF","#660000","#660033","#660066","#660099","#6600CC","#6600FF","#990000","#990033","#990066","#990099",
                      "#9900CC","#9900FF","#CC0000","#CC0033","#CC0066","#CC0099","#CC00CC","#CC00FF","#FF0000","#FF0033","#FF0066",
                      "#FF0099","#FF00CC","#FF00FF","#003300","#003333","#003366","#003399","#0033CC","#0033FF","#333300","#333333",
                      "#333366","#333399","#3333CC","#3333FF","#663300","#663333","#663366","#663399","#6633CC","#6633FF","#993300",
                      "#993333","#993366","#993399","#9933CC","#9933FF","#CC3300","#CC3333","#CC3366","#CC3399","#CC33CC","#CC33FF",
                      "#FF3300","#FF3333","#FF3366","#FF3399","#FF33CC","#FF33FF","#006600","#006633","#006666","#006699","#0066CC",
                      "#0066FF","#336600","#336633","#336666","#336699","#3366CC","#3366FF","#666600","#666633","#666666","#666699",
                      "#6666CC","#6666FF","#996600","#996633","#996666","#996699","#9966CC","#9966FF","#CC6600","#CC6633","#CC6666",
                      "#CC6699","#CC66CC","#CC66FF","#FF6600","#FF6633","#FF6666","#FF6699","#FF66CC","#FF66FF","#009900","#009933",
                      "#009966","#009999","#0099CC","#0099FF","#339900","#339933","#339966","#339999","#3399CC","#3399FF","#669900",
                      "#669933","#669966","#669999","#6699CC","#6699FF","#999900","#999933","#999966","#999999","#9999CC","#9999FF",
                      "#CC9900","#CC9933","#CC9966","#CC9999","#CC99CC","#CC99FF","#FF9900","#FF9933","#FF9966","#FF9999","#FF99CC",
                      "#FF99FF","#00CC00","#00CC33","#00CC66","#00CC99","#00CCCC","#00CCFF","#33CC00","#33CC33","#33CC66","#33CC99",
                      "#33CCCC","#33CCFF","#66CC00","#66CC33","#66CC66","#66CC99","#66CCCC","#66CCFF","#99CC00","#99CC33","#99CC66",
                      "#99CC99","#99CCCC","#99CCFF","#CCCC00","#CCCC33","#CCCC66","#CCCC99","#CCCCCC","#CCCCFF","#FFCC00","#FFCC33",
                      "#FFCC66","#FFCC99","#FFCCCC","#FFCCFF","#00FF00","#00FF33","#00FF66","#00FF99","#00FFCC","#00FFFF","#33FF00",
                      "#33FF33","#33FF66","#33FF99","#33FFCC","#33FFFF","#66FF00","#66FF33","#66FF66","#66FF99","#66FFCC","#66FFFF",
                      "#99FF00","#99FF33","#99FF66","#99FF99","#99FFCC","#99FFFF","#CCFF00","#CCFF33","#CCFF66","#CCFF99","#CCFFCC",
                      "#CCFFFF","#FFFF00","#FFFF33","#FFFF66","#FFFF99","#FFFFCC","#FFFFFF"];

/*
 * Return the HTML to show a color picker
 */
PXN8.colors.picker = function(initColor,callback)
{
    var closure = function(color,func){
        return function(){ func(color); };
    };
    var table = document.createElement("table");
    table.className = "color_table";
    table.setAttribute("cellpadding","0");
    table.setAttribute("cellspacing","0");
    table.cellPadding = 0;
    table.cellSpacing = 0; // IE
    var cols = 18;
    var rows = Math.ceil(PXN8.colors.values.length/cols);
    var tbody = table.appendChild(document.createElement("tbody"));
    for (var i = 0;i < rows;i++)
    {
        var row = tbody.appendChild(document.createElement("tr"));
        for (var j = 0; j < cols; j++){
            var cell = row.appendChild(document.createElement("td"));
            var index = (i*cols)+j;
            if (index < PXN8.colors.values.length){
                
                var color = PXN8.colors.values[index];
                var link = document.createElement("a");
                link.href="#";
                link.title = color;
                link.onclick = closure(color,callback);
                link.onmouseover = closure(color,function(color){
                    var color_well = document.getElementById("color_well");
                    color_well.style.backgroundColor=color;
                    var color_value = document.getElementById("color_value");
                    color_value.innerHTML = color;
                });
                link.appendChild(document.createTextNode("  "));
                link.style.backgroundColor = color;
                cell.appendChild(link);
            }
        }
    }
    var row = tbody.appendChild(document.createElement("tr"));
    var cell1 = row.appendChild(document.createElement("td"));
    cell1.colSpan = cols/2;
    cell1.id = "color_well";
    cell1.innerHTML = "";
    cell1.style.backgroundColor = initColor;
    var cell2 = row.appendChild(document.createElement("td"));
    cell2.colSpan = cols/2;
    cell2.id = "color_value";
    cell2.innerHTML = initColor;
    return table;
};

/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles color selection
 *
 */
var PXN8 = PXN8 || {};

PXN8.tooltip = {
    forDisplay: {}
};
PXN8.tooltip._show = function(tipId)
{
    var dom = PXN8.dom;
    
	 var tipDiv = null;
	 
	 if (PXN8.tooltip.forDisplay[tipId] == false){
		  return;
	 }
	 
	 tipDiv = dom.id(tipId);
	 
	 if (tipDiv == null){
		  return;
	 }
	 if (tipDiv.style == null){
		  return;
	 }
	 tipDiv.style.display = "block";

	 var imgBounds = dom.eb(dom.id("pxn8_image"));

	 tipDiv.style.top  = imgBounds.y + 10 + "px";
	 tipDiv.style.left = imgBounds.x + 10 + "px";
	 var shadow = dom.id("tipshadow");
	 if (!shadow){
		  shadow = dom.ac(document.body,dom.ce("div"));
	 }
	 shadow.id = "tipshadow";
	 shadow.style.backgroundColor = "black";
	 var opacity = 50;
	 shadow.style.opacity = opacity/100;
	 shadow.style._moz_opacity = opacity/100;
	 shadow.style.filter = "alpha(opacity:" + opacity + ")";
	 var tipBounds = dom.eb(tipDiv);
	 shadow.style.position = "absolute";
	 shadow.style.top = tipBounds.y + 3 + "px";
	 shadow.style.left = tipBounds.x + 3 + "px";
	 shadow.style.width = tipBounds.width+ "px";
	 shadow.style.height = tipBounds.height + "px";
};

PXN8.tooltip.show = function(element, elementId)
{
	 var tipId = null;
	 if (elementId){
		  tipId = elementId + "_tip";
	 }else{
		  tipId = element.id + "_tip";
	 }
	 PXN8.tooltip.forDisplay[tipId] = true;
	 setTimeout("PXN8.tooltip._show('" + tipId + "');",1200);
};

PXN8.tooltip.hide = function (element, elementId)
{
    var dom = PXN8.dom;
    
	 var tipDiv = null;
	 var tipId = null;
	 
	 if (elementId){
		  tipId = elementId + "_tip";
	 }else{
		  tipId = element.id + "_tip";
	 }

	 PXN8.tooltip.forDisplay[tipId] = false;
	 
	 tipDiv = dom.id(tipId);

	 if (tipDiv){
		  tipDiv.style.display="none";
	 }
	 var shadow = dom.id("tipshadow");
	 if (shadow){
		  document.body.removeChild(shadow);
	 }
};

PXN8.dom.addLoadEvent(function(){
    var haveTooltips = PXN8.dom.clz("pxn8_has_tooltip");
        
    for (var i = 0;i < haveTooltips.length; i++){
        var el = haveTooltips[i];
        el.onmouseover = PXN8.curry(PXN8.tooltip.show,el);
        el.onmouseout = PXN8.curry(PXN8.tooltip.hide,el);
    }
});
/*
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 */
PXN8 = PXN8 || {};
/**
 * NAMESPACE
 */
PXN8.tools.ui = {};
/**
 * NO-OP function
 */
PXN8.tools.ui.nop = function(){return false;};

/* ===========================================================================
 * BLUR RELATED FUNCTIONS
 */
PXN8.tools.ui.blur = function()
{
    var dom = PXN8.dom;
    
    var radius = dom.id("blurRadius").value;

    if (isNaN(radius) || radius < 1 || radius > 8){
        alert(PXN8.strings.BLUR_RANGE);
        return false;
    }

    var sel = PXN8.getSelection();

    sel.radius = radius;
    
    PXN8.tools.blur(sel);
    
    return true;
};

/*
 * Configure the blur tool panel 
 */
PXN8.tools.ui.config_blur = function(element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.blur;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.blur(); 
        return false;
    };

    dom.cl(dom.id("pxn8_config_title")).appendChild(dom.tx(PXN8.strings.CONFIG_BLUR_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    
    if (configContent == null){
        alert (PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    dom.cl(configContent);

    var form = dom.ac(configContent,dom.ce("form",{onsubmit: function(){PXN8.tools.ui.blur();return false;}}));

    var radiusInput = dom.ce("input",{className: "pxn8_small_field",
                                      type: "text",
                                      id: "blurRadius",value: 2,
                                      name: "blurRadius"});
    
    var table = dom.table([[PXN8.strings.RADIUS_LABEL,radiusInput]],{width: "100%"});
                          
    dom.ac(form,table);

    radiusInput.onfocus = function(){radiusInput.select();};
 
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.ac(dom.cl(helpArea),dom.tx(PXN8.strings.BLUR_PROMPT));
    
    radiusInput.focus();
};

/* ===========================================================================
 * RESIZE RELATED FUNCTIONS
 */

/*
 * Resize the image
 */
PXN8.tools.ui.resize = function()
{
    var dom = PXN8.dom;

    var newWidth = dom.id("resizeWidth").value;
    var newHeight = dom.id("resizeHeight").value;

    if (newWidth == PXN8.image.width &&
        newHeight == PXN8.image.height){
        return false;
    }
    if (isNaN(newWidth) || isNaN(newHeight)){
        alert(PXN8.strings.NUMERIC_WIDTH_HEIGHT);
        return false;
    }
    if (newWidth.match(/[0-9]+/) && newHeight.match(/[0-9]+/)){
        /* OK */
    }else{
        alert(PXN8.strings.NUMERIC_WIDTH_HEIGHT);
        return false;
    }
    if (newWidth > PXN8.resizelimit.width || newHeight > PXN8.resizelimit.height){
        alert(PXN8.strings.LIMIT_SIZE + PXN8.resizelimit.width + "x" + PXN8.resizelimit.height);
        return false;
    }
    PXN8.unselect();
    PXN8.tools.resize(newWidth,newHeight);

    return true;
};
/**
 *
 */
PXN8.tools.ui.config_resize = function(element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.resize;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.resize(); 
        return false;
    };

    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_RESIZE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    dom.cl(configContent);
    
	 var form = dom.ac(configContent,dom.ce("form"));
    form.onsubmit = function(){ 
        PXN8.tools.ui.resize(); 
        return false;
    };

    var preserveRatioCheckbox = dom.ce("input",{type: "checkbox", 
                                                id: "preserve", 
                                                value: true, 
                                                defaultChecked: true});
	 preserveRatioCheckbox.onclick = function(){ 
        preserveRatio(preserveRatioCheckbox);
    };
    
    var iwidth = dom.ce("input",{className: "pxn8_small_field", 
                                 type: "text", 
                                 value: PXN8.image.width,
                                 id: "resizeWidth", 
                                 name: "resizeWidth"});
    iwidth.onfocus = function (){ 
        iwidth.select();
    };
    iwidth.onblur = function(){ 
        changeDim('width');
    };
    var iheight  = dom.ce("input",{className: "pxn8_small_field", 
                                   type: "text", 
                                   value: PXN8.image.height,
                                   id: "resizeHeight", 
                                   name: "resizeHeight"});
    iheight.onfocus = function (){ 
        iheight.select();
    };
    iheight.onblur = function(){ 
        changeDim('height');
    };
    
    var resizeToSelectedArea = dom.ce("a",{href: "javascript:void(0)"});
    dom.ac(resizeToSelectedArea,dom.tx(PXN8.strings.RESIZE_SELECT_LABEL ));
    resizeToSelectedArea.onclick = function(){
        var sel = PXN8.getSelection();
        if (sel.width <= 0 || sel.height <= 0){
            PXN8.show.alert(PXN8.strings.RESIZE_SELECT_AREA);
            return false;
        }
        PXN8.unselect();
        PXN8.tools.resize(sel.width,sel.height);
        return false;
    };
    
    var table = dom.table([[PXN8.strings.ASPECT_LABEL, preserveRatioCheckbox],
                           [PXN8.strings.WIDTH_LABEL,  iwidth],
                           [PXN8.strings.HEIGHT_LABEL, iheight],
                           [resizeToSelectedArea] ]);
    dom.ac(form,table);
    
    iwidth.focus();

    /**
     * default to 75% of image size
     */
    PXN8.sx = 0;
    PXN8.sy = 0;
    PXN8.ex = PXN8.image.width * 0.75;
    PXN8.ey = PXN8.image.height * 0.75;
    PXN8.selectArea();

    iwidth.setAttribute('value', PXN8.image.width);
    iheight.setAttribute('value', PXN8.image.height);
    
};

/**
 * Change the brightness, hue and saturation
 */
PXN8.tools.ui.bsh = function()
{ 

    var dom = PXN8.dom;

    var bright = dom.id("brightness");
    var sat = dom.id("saturation");
    var h = dom.id("hue");
    var contrast = dom.id("contrast");
    var contrastValue = contrast.options[contrast.selectedIndex];
    
        
    if (isNaN(bright.value) || bright.value < 0 || bright.value.match(/\S+/) == null){
        alert(PXN8.strings.BRIGHTNESS_RANGE);
        return false;
    }
    if (isNaN(h.value) || h.value < 0 || h.value > 200 || h.value.match(/\S+/) == null){
      alert (PXN8.strings.HUE_RANGE);
      return false;
    }
    if (isNaN(sat.value) || sat.value < 0 || sat.value.match(/\S+/) == null){
        alert(PXN8.strings.SATURATION_RANGE);
        return false;
    }
    
    if (bright.value == 100 && h.value == 100 && sat.value == 100 && contrastValue.value == 0){
        return false;
    }

    PXN8.tools.colors ({brightness: bright.value,
                        hue: h.value,
                        saturation: sat.value, 
                        contrast: contrastValue.value});
    return true;
   
};


/*
 * ----------------------------------------------------------------
 * Setup the Tool configuration panel for Brightness/Hue/Saturation
 * ----------------------------------------------------------------
 */
PXN8.tools.ui.config_bsh = function(element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.bsh;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.bsh(); 
        return false;
    };
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    
    dom.cl(dom.id("pxn8_config_title")).appendChild(dom.tx(PXN8.strings.CONFIG_COLOR_TOOL));

    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert (PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var form = dom.ac(dom.cl(configContent),dom.ce("form",{onsubmit: function(){
        PXN8.tools.ui.bsh();
        return false;
    }}));

    /**
     * Construct a slider control to control the brightness
     */
    var brdiv = dom.ce("div");
    // make it a slide 
    PXN8.slide.bind(brdiv,'brightness',0,200,100);
    dom.ac(brdiv,dom.tx(PXN8.strings.BRIGHTNESS_LABEL));
    
    var brdiv2 =   dom.ce("input",{className: "pxn8_slidervalue", 
                                   type: "text", 
                                   name: "brightness", 
                                   id: "brightness", value: 100});
    /**
     * Construct a slider control to control the saturation
     */
    var satdiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(satdiv,'saturation',0,200,100);
    dom.ac(satdiv,dom.tx(PXN8.strings.SATURATION_LABEL));

    var sat2 = dom.ce("input",{className: "pxn8_slidervalue", 
                               type: "text", 
                               name: "saturation", 
                               onkeypress: brdiv2.onkeypress,
                               id: "saturation", 
                               value: 100});

    /**
     * Construct a slider control to control the HUE
     */
    var huediv =  dom.ce("div");
    // make it a slide
    PXN8.slide.bind(huediv,'hue',0,200,100);
    
    dom.ac(huediv,dom.tx(PXN8.strings.HUE_LABEL));

    var hue2 = dom.ce("input",{className: "pxn8_slidervalue", 
                               type: "text", 
                               name: "hue", 
                               onkeypress: brdiv2.onkeypress,
                               id: "hue", 
                               value: 100});
    /**
     * Construct a 'contrast' dropdown combobox
     */
    var sel = dom.ce("select",{name: "contrast", 
                               id: "contrast",
                               onkeypress: brdiv2.onkeypress });
    var options = {"-3": "-3", "-2": "-2", "-1": "-1", "0": PXN8.strings.CONTRAST_NORMAL, "1": "+1", "2": "+2", "3": "+3"};
    var j  = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i],i);
    }
    sel.selectedIndex = 3;

    var table = dom.table([[ brdiv,     brdiv2,   "%"],
                           [ satdiv,    sat2,     "%"],
                           [ huediv,    hue2,     "%"],
                           [ PXN8.strings.CONTRAST_LABEL, sel]],{width: "90%"});
    dom.ac(form,table);
    
    var cells = table.getElementsByTagName("td");
    for (var i = 0 ; i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }
    
    var br = dom.id("brightness");
    br.focus();
    br.select();
};

/*
 * -------------------------------------------------------------------------
 * CROP RELATED FUNCTIONS
 * -------------------------------------------------------------------------
 */

/*
 * perform crop operation
 */
PXN8.tools.ui.crop = function()
{
    var dom = PXN8.dom;

    var sel = PXN8.getSelection();
    
    if (sel.width <= 0 || sel.height <= 0){
        PXN8.show.alert(PXN8.strings.CROP_SELECT_AREA);
        return false;
    }
    
    PXN8.tools.crop(sel);
    
    PXN8.unselect();
    
    PXN8.aspectRatio.width = 0;
    PXN8.aspectRatio.height = 0;
    
    return true;
};

/*
 * Configure the Crop tool panel
 */
PXN8.tools.ui.config_crop = function(element,event)
{  
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.crop(); 
        return false;
    };
    

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,function(){
        /* change the aspect ratio back to 'free select' */
        PXN8.aspectRatio.width = 0;
        PXN8.aspectRatio.height = 0;
        return false;
    });
    
        
    
    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_CROP_TOOL));

    var configContent = dom.id("pxn8_config_content");

    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    
    var theImg = dom.id("pxn8_image");
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));


    var form = dom.ac(dom.cl(configContent),dom.ce("form"));

    form.onsubmit =  function(){ 
        PXN8.tools.ui.crop(); 
        return false;
    };

    var sel = dom.ce("select",{id: "aspect_ratio", name: "aspect_ratio"});
    sel.onchange = function() {
        changeAspectRatio();
    };
    var options = {"free": PXN8.strings.CROP_FREE,
                   "1x1" : PXN8.strings.CROP_SQUARE,
                   "4x6" : "4x6",
                   "5x7" : "5x7",
                   "8x10": "8x10",
                   "6x8" : "6x8"};
    var j = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i],i);
    }   
    /**
     * Portrait orientation
     */
    var op = dom.ce("div",{className: "pxn8_checked", id: "portrait"});
    op.onclick = function(){ 
        changeOrientation(PXN8.PORTRAIT);
        op.className = "pxn8_checked";
        var ol = dom.id("landscape");
        ol.className = "pxn8_unchecked";
    };
    op.style.cursor = "pointer";
    dom.ac(op,dom.tx(PXN8.strings.ORIENTATION_PORTRAIT));
    /**
     * Landscape orientation
     */ 
    var ol = dom.ce("div",{className: "pxn8_unchecked", id: "landscape"});
    ol.onclick = function(){ 
        changeOrientation(PXN8.LANDSCAPE);
        ol.className = "pxn8_checked";
        var op = dom.id("portrait");
        op.className = "pxn8_unchecked";
   
    };
    ol.style.cursor = "pointer";
    dom.ac(ol,dom.tx(PXN8.strings.ORIENTATION_LANDSCAPE));

    /**
     * Preview Crop link
     */
    var prevCropLink = dom.ce("a",{href: "javascript:void(0);",onclick: previewCrop});
    dom.ac(prevCropLink,dom.tx("preview"));

    var table = dom.table([
                           [PXN8.strings.ASPECT_CROP_LABEL, sel],
                           [PXN8.strings.ORIENTATION_LABEL, op],
                           ["",                             ol],
                           [prevCropLink                      ]],
        {width: "100%"});

    dom.ac(form,table);
    
    sel.focus();

    /**
     * Setup initial orientaition radio selection
     */
    var portrait = dom.id("portrait");
    var landscape = dom.id("landscape");

    if (theImg.height > theImg.width){
        portrait.className = "pxn8_checked";
        landscape.className = "pxn8_unchecked";
        changeOrientation(PXN8.PORTRAIT);
    }else{
        portrait.className = "pxn8_unchecked";
        landscape.className = "pxn8_checked";
        changeOrientation(PXN8.LANDSCAPE);
    }    

};

/*
 * Called during crop tool configuration  and when the orientation
 * radiobox is clicked
 */
function changeOrientation(orientation,width,height)
{
    PXN8.orientation = orientation;
	 if (width != null){
        changeAspectRatio(width,height);
    }else{
        changeAspectRatio();
    }
};

/*
 * Called when the user chooses a value from the aspect ratio dropdown
 * and also called when the orientation (portrait,landscape) has changed.
 */
function changeAspectRatio(width,height)
{
    var dom = PXN8.dom;

    if (width != null){
        PXN8.aspectRatio.width = width;
        PXN8.aspectRatio.height = height;
    }else{
        var aspectRatio = dom.id("aspect_ratio");
        if (aspectRatio != null){
            
            var selected = aspectRatio.options[aspectRatio.selectedIndex];
            var pair = /^([0-9]+)x([0-9]+)/;
            var match = selected.value.match(pair);
            if (match != null){
                if (PXN8.orientation == PXN8.LANDSCAPE){
                    PXN8.aspectRatio.width = match[2];
                    PXN8.aspectRatio.height = match[1];
                }else{
                    PXN8.aspectRatio.width = match[1];
                    PXN8.aspectRatio.height = match[2];
                }
            }else{
                PXN8.aspectRatio.width = 0;
                PXN8.aspectRatio.height = 0;
                return;
            }
        }
    }
    if (PXN8.aspectRatio.width == 0 &&
        PXN8.aspectRatio.height == 0){
        return;
    }

    var topRect = dom.id("pxn8_top_rect");
    topRect.style.borderWidth = "1px";
    
    var leftRect = dom.id("pxn8_left_rect");
    leftRect.style.borderWidth = "0px";
            
    PXN8.sx = 0;
    PXN8.sy = 0;
    
    var t1 = PXN8.image.width / PXN8.aspectRatio.width ;
    var t2 = PXN8.image.height / PXN8.aspectRatio.height ;
    if (t2 < t1){
        PXN8.ey = PXN8.image.height;
        PXN8.ex = Math.round(PXN8.ey / PXN8.aspectRatio.height * PXN8.aspectRatio.width);
    }else{
        PXN8.ex = PXN8.image.width;
        PXN8.ey = Math.round(PXN8.ex / PXN8.aspectRatio.width * PXN8.aspectRatio.height);
    }
    PXN8.sx = Math.round((PXN8.image.width - PXN8.ex) / 2);
    PXN8.sy = Math.round((PXN8.image.height - PXN8.ey) / 2);
    PXN8.ex += PXN8.sx;
    PXN8.ey += PXN8.sy;
    
    PXN8.selectArea();
};
/* ===========================================================================
 * FILTER RELATED FUNCTIONS
 * ===========================================================================
 */

/*
 * Add a lens filter to the image
 */
PXN8.tools.ui.filter = function(x,y)
{
    var dom = PXN8.dom;

    var applyBtn  = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    
    PXN8.tools.filter({"top": y,
                       "color": dom.id("filter_color").value,
                       "opacity" : dom.id("filter_opacity").value }
                      );
    return true;
};

/*
 *
 */
PXN8.tools.ui.config_filter = function (element, event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    
    applyBtn.style.display = "none";
    
    var canvas = dom.id("pxn8_canvas");
    var oldonmousedown = canvas.onmousedown;
    
    var onImageUpdated = null;
    onImageUpdated = function(){
        applyBtn.style.display = "inline";
        var pin1 = dom.id("left_pin");
        if (pin1){
            pin1.style.display = "none";
        }
        canvas.onmousedown = oldonmousedown;
    };
    PXN8.listener.onceOnly(PXN8.ON_IMAGE_CHANGE,onImageUpdated);
   

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,onImageUpdated);
    
    var configTitle = dom.cl(dom.id("pxn8_config_title"));
	 dom.ac(configTitle,dom.tx(PXN8.strings.CONFIG_FILTER_TOOL));

    PXN8.unselect();
    var configContent = dom.id("pxn8_config_content");

    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    var colorInput = dom.ce("input",{name: "filter_color", 
                                     className: "pxn8_small_field", 
                                     id: "filter_color",
                                     value: "#FFA500"
    });
    var table = PXN8.colors.picker("#FFA500",function(color){
        colorInput.value = color;
    });
    
	 dom.ac(dom.cl(configContent),table);

    /**
     * Construct a slider control to control opacity
     */
    var opacitySliderDiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opacitySliderDiv,'filter_opacity',0,100,100);
    dom.ac(opacitySliderDiv,dom.tx(PXN8.strings.OPACITY_LABEL));

    var opacityInput = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type: "text", 
         name: "filter_opacity", 
         id: "filter_opacity", 
         value: 100});

    var table2 = dom.table([
                            [PXN8.strings.COLOR_LABEL, colorInput],
                            [opacitySliderDiv,         opacityInput]
                            ]);

    dom.ac(configContent,table2);

    var cells = table2.getElementsByTagName("td");
    for (var i = 0;i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }
    
    dom.ac(dom.cl(dom.id("pxn8_tool_prompt")),dom.tx(PXN8.strings.FILTER_PROMPT));
    
    var newonmousedown = function(event){

        if (!event) event = window.event;
        var cursorPos = PXN8.dom.cursorPos(event);
   
        var imagePoint = PXN8.mousePointToElementPoint(cursorPos.x,cursorPos.y);

        canvas.onmousedown = oldonmousedown;
        // show pin 
        var pin1 = dom.id("left_pin");
        if (pin1 == null){
            pin1 = PXN8.createPin("left_pin", PXN8.root + "/images/bluepin.gif");
            document.body.appendChild(pin1);
        }
        
        pin1.style.display = "block";
        pin1.style.left = "" + (cursorPos.x -7) + "px";
        pin1.style.top = "" + (cursorPos.y - 24) + "px";
        
        PXN8.tools.ui.filter(imagePoint.x,imagePoint.y);
        return true;
    };
    canvas.onmousedown = newonmousedown;
    
};

/* ===========================================================================
 * INTERLACE RELATED FUNCTIONS
 * ===========================================================================
 */


/*
 * Setup the configuration panel for the interlace effect
 */
PXN8.tools.ui.config_interlace = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.interlace;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.interlace(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_INTERLACE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var interlaceColor = dom.ce("input",{name: "interlace_color", 
                                         className: "pxn8_small_field", 
                                         id: "interlace_color",
                                         value: "#000000"
    });
    

    var picker = PXN8.colors.picker("#000000",function(color){
        interlaceColor.value = color;
    });
    
    dom.ac(dom.cl(configContent),picker);

    /**
     * Construct a slider control to control opacity
     */
    var opacitySliderDiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opacitySliderDiv,'interlace_opacity',0,100,20);
    dom.ac(opacitySliderDiv,dom.tx(PXN8.strings.OPACITY_LABEL));

    var opacityInput = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type: "text", 
         name: "interlace_opacity", 
         id: "interlace_opacity", 
         value: 20});

    dom.ac(configContent,
           dom.table([
                      [PXN8.strings.COLOR_LABEL,interlaceColor],
                      [opacitySliderDiv,        opacityInput]],
           {width: "100%"}));
    
    
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.cl(helpArea);
    helpArea.appendChild(dom.tx(PXN8.strings.INTERLACE_PROMPT));
    
    opacityInput.focus();

};

/*
 * Add an interlace effect to the image
 */
PXN8.tools.ui.interlace = function()
{
    
    var dom = PXN8.dom;

    var lineColor = dom.id("interlace_color").value;
    if (lineColor.match(/#[a-fA-F0-9]{6}/)){
        /* it's OK */
    }else{
        alert(PXN8.strings.INVALID_HEX_VALUE);
        return false;
    }
    var sel = PXN8.getSelection();
    var opacityVal = dom.id("interlace_opacity").value;

    sel.opacity = opacityVal;
    sel.color = lineColor;
    
    PXN8.tools.interlace(sel);
        
    return true;
};

/* ===========================================================================
 * LOMO RELATED FUNCTIONS
 * ===========================================================================
 */
/* 
 * Configure the lomo tool panel
 */
PXN8.tools.ui.config_lomo = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.lomo(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_LOMO_TOOL));
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));
    helpArea.appendChild(dom.tx(PXN8.strings.OPACITY_PROMPT));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

	 dom.cl(configContent);
	var form = dom.ce("form",{name: "lomoform"});
	configContent.appendChild(form);    
    //var form = dom.ac(dom.cl(configContent),dom.ce("form",{name: "lomoform"}));
	
    form.onsubmit = function(){
        PXN8.tools.ui.lomo();
        return false;
    };

    /**
     * Construct a slider control to control opacity
     */
	 var opslide = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opslide,'opacity',0,100,60);
	 var opacity_label = dom.tx(PXN8.strings.OPACITY_LABEL);
	 opslide.appendChild(opacity_label);
    //dom.ac(opslide,);

    var opacityField = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type:"text", 
         name:"opacity", 
         id:"opacity", 
         value:60});

    var saturateCheckbox = dom.ce("input",
        {type:"checkbox",
         name: "saturate", 
         defaultChecked: true, 
         id:"saturate"});

    var table = dom.table([[opslide,                     [opacityField,"%"]],
                           [PXN8.strings.SATURATE_LABEL, saturateCheckbox]
                           ],{width: "100%"});



	 form.appendChild(table);
    //dom.ac(form,table);
    var cells = table.getElementsByTagName("td");
    for (var i = 0; i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }

    opacityField.focus();
	
};


/*
 * Add a lomo effect to the image
 */
PXN8.tools.ui.lomo = function()
{
    var dom = PXN8.dom;

    var opacity = dom.id("opacity");
    var saturate = dom.id("saturate");
    
    if (isNaN(opacity.value) || opacity.value <0 || opacity.value > 100){
        alert(PXN8.strings.OPACITY_RANGE);
        return false;
    }
    
    PXN8.tools.lomo({ "opacity": opacity.value, "saturate": saturate.checked });
    
    return true;
};


/*
 * whiten teeth
 */
PXN8.tools.ui.whiten = function()
{
    
    var selection = PXN8.getSelection();
    if (selection.width == 0 || selection.height == 0){
        PXN8.show.alert(PXN8.strings.WHITEN_SELECT_AREA);
        return false;
    } 
    
    if (selection.width * selection.height > 16000){
        PXN8.show.alert (PXN8.strings.SELECT_SMALLER_AREA);
        return false;
    } 
    
    PXN8.tools.whiten(selection);
    
    
    return true;
};


/*
 * -------------------------------------------------------------------------
 * RED EYE RELATED FUNCTIONS
 * -------------------------------------------------------------------------
 */
/*
 * Fix red eye 
 */
PXN8.tools.ui.redeye = function ()
{
    var selection = PXN8.getSelection();
    if (selection.width == 0 || selection.height == 0){
        alert(PXN8.strings.REDEYE_SELECT_AREA);
        return false;
    } 
    if (selection.width > 100 || selection.height > 100){
        alert (PXN8.strings.REDEYE_SMALLER_AREA);
        return false;
    } 

    PXN8.tools.fixredeye(selection);
    
    PXN8.aspectRatio.width = 0;
    PXN8.aspectRatio.height = 0;

    PXN8.unselect();
    return true;
};

/*
 * Configure the red eye tool panel
 */
PXN8.tools.ui.config_redeye = function (element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.redeye;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.redeye(); 
        return false;
    };

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,function(){
        PXN8.aspectRatio.width = 0;
        PXN8.aspectRatio.height = 0;
    });
    
                           

    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_REDEYE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var table = dom.table([[PXN8.strings.REDEYE_PROMPT]],{width: "100%"});
    dom.ac(dom.cl(configContent),table);
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    
    PXN8.aspectRatio.width = 1;
    PXN8.aspectRatio.height = 1;
};


/*
 *  handler for when the 'preserve ratio' button is clicked
 */
function preserveRatio(element){
   if (element.checked){
       matchHeightToWidth();
   }
   return true;
}

/*
 *
 */
function matchHeightToWidth(){

    var dom = PXN8.dom;

    var width = dom.id("resizeWidth").value;
    var heightInput = dom.id("resizeHeight");
    
    var expr = /^([0-9]+)(%*)$/;
    var match = width.match(expr);
    if (match != null){
        if (match[2] == '%'){
            heightInput.value = Math.round(PXN8.image.height *  (match[1] / 100));
        }else{
            heightInput.value = Math.round(PXN8.image.height * (width / PXN8.image.width));
        }
    }
}
/*
 *
 */
function matchWidthToHeight(){
    var dom = PXN8.dom;

    var height = dom.id("resizeHeight").value;
    var widthInput = dom.id("resizeWidth");
    
    var expr = /^([0-9]+)(%*)$/;
    var match = height.match(expr);
    if (match != null){
        if (match[2] == '%'){
            widthInput.value = Math.round(PXN8.image.width *  (match[1] / 100));
        }else{
            widthInput.value = Math.round(PXN8.image.width * (height / PXN8.image.height));
        }
    }
}
/*
 *
 */
function changeDim(axis){
    var dom = PXN8.dom;

    var preserve = dom.id("preserve");
    if (preserve.checked){
        if (axis == 'width'){
            matchHeightToWidth();
        }else{
            matchWidthToHeight();
        }
    }
    return true;
};

/* ===========================================================================
 * ROTATE RELATED FUNCTIONS
 */

/*
 *
 */
PXN8.tools.ui.rotate = function ()
{
    var dom = PXN8.dom;

    var angleCombo = dom.id("angle");
    var angle = angleCombo.options[angleCombo.selectedIndex].value;
    var flipVt = dom.id("flipvt").checked;
    var flipHz = dom.id("fliphz").checked;
    
    if (angle == 0 &&
        flipVt == false &&
        flipHz == false ){
        alert(PXN8.strings.PROMPT_ROTATE_CHOICE);
        return false;
    }

    PXN8.tools.rotate({"angle": angle, 
                       "flipvt": flipVt, 
                       "fliphz": flipHz});
    
    return false;
};

/*
 * ROTATE IMAGE
 */
PXN8.tools.ui.config_rotate = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.rotate;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.rotate(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_ROTATE_TOOL));
    
    PXN8.unselect();
    var configContent = dom.cl(dom.id("pxn8_config_content"));
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));
    
    var form = dom.ac(configContent, dom.ce("form"));
    form.onsubmit =  function(){ 
        PXN8.tools.ui.rotate(); 
        return false;
    };

	 var flipvt = dom.ce("input", {type: "checkbox",
                                  name:"flipvt",
                                  id:"flipvt"});

    var fliphz = dom.ce("input", {type: "checkbox", 
                                  name: "fliphz", 
                                  id: "fliphz"});

    var sel = dom.ce("select",{name: "angle", 
                               id: "angle", 
                               className: "pxn8_small_field"});
    
    var options = {"0": "   ", "90": "90", "180": "180", "270": "270  "};
    var j = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i], i);
    }

    var table = dom.table([[PXN8.strings.FLIPVT_LABEL, flipvt],
                           [PXN8.strings.FLIPHZ_LABEL, fliphz],
                           [PXN8.strings.ANGLE_LABEL,  sel ]
                           ], 
        {width: "100%"});
    

	dom.ac(form,table);
    flipvt.focus();
};


/*
 * Called when the user clicks the 'spirit-level' checkbox
 */
function spiritlevelmode ()
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "none";
    
    var oldOnImageUpdated = PXN8.onImageUpdated;
    
    var tidyup = function(){
		
        var dom = PXN8.dom;

        var blackout= dom.id("blackout");
        if (blackout){
            document.body.removeChild(blackout);
        }
        var prompt = dom.id("prompt");
        if (prompt){
            document.body.removeChild(prompt);
        }
        /**
         * muy importante !
         */
        PXN8.initializeCanvas();
        /**
         * ^^^^^^^^^^^^^^^
         */
        var pin1 = dom.id("left_pin");
        if (pin1){
            pin1.style.display = "none";
        }
        var pin2 = dom.id("right_pin");
        if (pin2){
            pin2.style.display = "none";
        }
        
    };
   
    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,tidyup);
    
    var onImageUpdated = null;
    
    PXN8.listener.onceOnly(PXN8.ON_IMAGE_CHANGE,tidyup);
    
    var blackout = document.createElement("div");
    blackout.id = "blackout";
    
    var imgBounds = dom.eb(dom.id("pxn8_image"));
    PXN8.unselect();
    blackout.style.position = "absolute";
    blackout.style.backgroundColor = "black";
    dom.opacity(blackout,0.7);
    
    blackout.style.top = imgBounds.y + "px";
    blackout.style.left = imgBounds.x + (imgBounds.width/2) + "px";
    blackout.style.width = (imgBounds.width/2)+"px";
    blackout.style.height = imgBounds.height + "px";
    document.body.appendChild(blackout);

    var prompt = document.createElement("div");
    prompt.id = "prompt";
    prompt.style.position = "absolute";
    prompt.style.backgroundColor = "white";
    prompt.style.padding = "4px";
        
    prompt.style.top = imgBounds.y + 10 + "px";
    prompt.style.left = imgBounds.x + 10 + "px";
    prompt.style.width = (imgBounds.width/2)- 20 + "px";
    prompt.style.overflow = "auto";
        
    dom.ac(dom.cl(prompt),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT1));
        
    document.body.appendChild(prompt);
        

    var configContent = dom.id("pxn8_config_content");
    dom.ac(dom.cl(configContent),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT1));
    
    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_SPIRITLVL_TOOL));
    
    var instructionIndex = 0;
    var points = { left: {x: 0, y: 0},
                   right: {x: 0, y: 0}};
        
    dom.cl(dom.id("pxn8_tool_prompt"));

    var canvas = dom.id("pxn8_canvas");
    canvas.onmousedown = function (event){
        var dom = PXN8.dom;

        event = (event)?event:window.event;
        dom.ac(dom.cl(configContent),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT2));
            
        // show pin 
        var pin1 = dom.id("left_pin");
        if (pin1 == null){
            pin1 = PXN8.createPin("left_pin",PXN8.root + "/images/bluepin.gif");
            document.body.appendChild(pin1);
        }
        
        pin1.style.display = "block";
        var cursorPos = PXN8.dom.cursorPos(event);
        pin1.style.left = "" + (cursorPos.x -7) + "px";
        pin1.style.top = "" + (cursorPos.y - 24) + "px";
        
        points.left.x = PXN8.position.x;
        points.left.y = PXN8.position.y;

        blackout.style.left = imgBounds.x + "px";

        prompt.style.left = (imgBounds.x + (imgBounds.width/2)) + 10 + "px";
        dom.ac(dom.cl(prompt),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT2));

        canvas.onmousedown = function (event){
            var dom = PXN8.dom;

            event = (event)?event:window.event;
                
            points.right.x = PXN8.position.x;
            points.right.y = PXN8.position.y;
            // show pin 
            var pin2 = dom.id("right_pin");
            if (pin2 == null){
                pin2 = PXN8.createPin("right_pin",PXN8.root + "/images/redpin.gif");
                document.body.appendChild(pin2);
            }
            pin2.style.display = "block";
            var cursorPos = PXN8.dom.cursorPos(event); 
            pin2.style.left = "" + (cursorPos.x -7) + "px";
            pin2.style.top = "" + (cursorPos.y - 24) + "px";
                
            PXN8.initializeCanvas();

            var blackout= dom.id("blackout");
            if (blackout){
                document.body.removeChild(blackout);
            }
            var prompt = dom.id("prompt");
            if (prompt){
                document.body.removeChild(prompt);
            }

            PXN8.tools.spiritlevel(points.left.x,
                                   points.left.y,
                                   points.right.x,
                                   points.right.y);
                
        };

    };
}


/* ===========================================================================
 * ROUNDED_CORNERS RELATED FUNCTIONS
 * ===========================================================================
 */

/*
 * Configure the rounded-corners tool panel
 */
PXN8.tools.ui.config_roundedcorners = function(element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.roundedcorners;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.roundedcorners(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_ROUNDED_TOOL));
    
    
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.cl(helpArea);
    
    var configContent = dom.id("pxn8_config_content");
    
    dom.cl(configContent);
    var colorInput = dom.ce("input",{name: "corner_color", 
                                     className: "pxn8_small_field", 
                                     id: "corner_color",
                                     value: "#FFFFFF"
    });
    
    var picker = PXN8.colors.picker("#FFFFFF",function(color){
        colorInput.value = color;
    });
    
    configContent.appendChild(picker);
    
    var input = dom.ce("input", {className: "pxn8_small_field", 
                                 type: "text", 
                                 name: "radius",
                                 id: "radius",
                                 value: "32"});

    var table = dom.table([[PXN8.strings.COLOR_LABEL, colorInput],
                           [PXN8.strings.RADIUS_LABEL, input]]);

    dom.ac(configContent,table);
    
    colorInput.focus();

};

/*
 * Add rounded corners to the image
 */
PXN8.tools.ui.roundedcorners = function ()
{
    var dom = PXN8.dom;

    var color = dom.id("corner_color");
    var radius = dom.id("radius");
    
    PXN8.tools.roundedcorners(color.value, radius.value);
    
    return true;
};

/*
 * Make the image sepia tone or black&white
 */
PXN8.tools.ui.sepia = function()
{
    var dom = PXN8.dom;

   /*
    * n.b. the order in which the grayscale/sepia elements are declared is important.
    * for the following line to work since it uses an index - not a name (can't use 
    * name because they're radio buttons )
    */
   //var operation = document.forms["sepia"].elements[1].checked?"grayscale":"sepia";

    var operation = "sepia";
    var gs = dom.id("gs");
    if (gs.className == "pxn8_checked"){
        operation = "grayscale";
    }
    
    if (operation == "sepia"){
        PXN8.tools.sepia(dom.id("sepia_color").value);
    }else{
        PXN8.tools.grayscale();
    }
    
    return true;
};

/* ===========================================================================
 * SEPIA + B&W RELATED FUNCTIONS
 * ===========================================================================
 */


/*
 * Configure the sepia/black & white tool panel
 */
PXN8.tools.ui.config_sepia = function(element, event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
   
    //applyBtn.onclick = sepiaTone;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.sepia(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_BW_TOOL));
    
    var configContent = dom.cl(dom.id("pxn8_config_content"));

    var colorInput = dom.ce("input",{name: "sepia_color", 
                                     className: "pxn8_small_field", 
                                     id: "sepia_color",
                                     value: "#A28A65"
    });
    
    var picker = PXN8.colors.picker("#A28A65",function(color){
        colorInput.value = color;
    });

    dom.ac(dom.cl(configContent),picker);

    dom.ac(configContent,
           dom.table([[PXN8.strings.COLOR_LABEL, colorInput]],{width: "100%"}));
    
    var form2 = dom.ac(configContent,dom.ce("form", {name: "sepia"}));

    form2.onsubmit = function(){ 
        PXN8.tools.ui.sepia(); 
        return false;
    };
    /**
     * Sepia radio button
     */
    var d1 = dom.ce("div",{className:"pxn8_checked", id: "sep"});
    dom.ac(d1,dom.tx(PXN8.strings.SEPIA_LABEL));

    d1.onclick = function(){
        var dom = PXN8.dom;

        d1.className = "pxn8_checked";
        var gs = dom.id("gs");
        gs.className = "pxn8_unchecked";
        dom.opacity(picker,1.0);
    };
    d1.style.cursor = "pointer";
    /**
     * Grayscale radio button
     */
    var d2 = dom.ce("div",{className:"pxn8_unchecked", id: "gs"});
    dom.ac(d2,dom.tx(PXN8.strings.GRAYSCALE_LABEL));
    d2.onclick = function(){
        var dom = PXN8.dom;
        d2.className = "pxn8_checked";
        var sep = dom.id("sep");
        sep.className = "pxn8_unchecked";
        dom.opacity(picker,0.5);
        return true;
    };
    d2.style.cursor = "pointer";

    var table = dom.table([[d1],
                           [d2]],
        {width: "100%"});

    dom.ac(form2,table);
    
    dom.ac(dom.cl(dom.id("pxn8_tool_prompt")),dom.tx(PXN8.strings.BW_PROMPT));
    
    var cf = dom.id("sepia_color");
    cf.focus();
};


function restoreAfterPreview()
{
    var dom = PXN8.dom;
    var rects = ["left","right","top","bottom"];
    for (var i  = 0;i < rects.length; i++){
        var rect = dom.id("pxn8_" + rects[i] + "_rect");
        rect.style.backgroundColor = PXN8.style.notSelected.color;
        dom.opacity(rect,PXN8.style.notSelected.opacity);
    }
    for (var i in PXN8.resize.handles){
        var handle = dom.id( i + "_handle");
        dom.opacity(handle,1.00);
    }

};
/**
 * A nice feature to have: preview a crop operation before doing it.
 */
function previewCrop()
{
    var dom = PXN8.dom;
    var rects = ["left","right","top","bottom"];
    for (var i  = 0;i < rects.length; i++){
        var rect = dom.id("pxn8_" + rects[i] + "_rect");
        rect.style.backgroundColor = "white";
        dom.opacity(rect,1.00);
    }
    for (var i in PXN8.resize.handles){
        var handle = dom.id( i + "_handle");
        dom.opacity(handle,0);
    }
    
    setTimeout(restoreAfterPreview,3500);
};
