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
