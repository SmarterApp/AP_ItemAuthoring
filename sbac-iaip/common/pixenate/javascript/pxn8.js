//
// If your original file is overwritten each time you save  
// then set this value to true.
//
PXN8.replaceOnSave = true;
//
// N.B. By default PXN8 should be installed in a subfolder of your webroot called pixenate.
// If you install PXN8 elsewhere you should change the PXN8.root variable accordingly. 
//
PXN8.root = "/common/pixenate";
/*
 * optimized rotation: if rotated 90 degrees x 4 then just undo previous 3 operations
 */
function slickRotate(event)
{
    if (!event) event = window.event;
    
    // figure out how many immediate prior 90 degree rotations we've done
    
    for (var i = PXN8.opNumber; i >= 0; i--){
        var op = PXN8.history[i];
        if (op.operation){
            if (op.operation == "rotate" && op.angle == 90){
                // do nothing
            }else{
                break;
            }
        }else{
           break;
        }
        
    }
    var rotations = (PXN8.opNumber - i) + 1;
    
    if (rotations >= 4){
        PXN8.tools.history(-3);
    }else{

        
        PXN8.tools.rotate({angle:90});
    }
    
    return false;
}

function submit_upload_form()
{
    var fname = document.getElementById("filename").value;
    if (fname == "" ){
        alert("Press the Browse button to choose a file first");
        return false;
    }
    return true;
}
function loadImageFromPrompt()
{
    var loc = prompt("Please enter the web address of the image:","http:/" + "/");
    if (loc){
        toggleVisibility(null,'sourceoptions'); //
        //
        PXN8.loadImage(loc);
    }
    return false;
}
function toggleVisibility(element, targetId, nodeTexts)
{
    var dom  = PXN8.dom;
    
    var targetElement = dom.id(targetId);
    if (targetElement.style.display == "none"){
        targetElement.style.display = "block";
        if (nodeTexts){
            element.innerHTML = nodeTexts.hide;
        }
    }else{
        targetElement.style.display = "none";
        if (nodeTexts){
            element.innerHTML = nodeTexts.show;
        }
    }
    return false;
}
function toggleConfigVisibility(visible)
{
    var dom = PXN8.dom;
    
    var toolPalette = dom.id("all_tools");
    toolPalette.style.display = visible?"none":"block";
    var toolPalette = dom.id("pxn8_config_area");
    toolPalette.style.display = visible?"block":"none";
}

function configureTool (func, element, event)
{
    PXN8.tooltip.hide(element);
    toggleConfigVisibility(true);
    func(element,event);
}

PXN8.listener.add(PXN8.ON_IMAGE_CHANGE,function(element, event){
    toggleConfigVisibility(false);
});
