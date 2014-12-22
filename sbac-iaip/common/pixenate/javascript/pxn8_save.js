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


