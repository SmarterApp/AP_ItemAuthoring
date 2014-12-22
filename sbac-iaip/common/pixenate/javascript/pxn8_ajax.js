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

