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

