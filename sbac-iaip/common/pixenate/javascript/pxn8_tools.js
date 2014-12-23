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
