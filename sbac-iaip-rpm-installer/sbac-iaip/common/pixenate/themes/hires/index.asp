
<html>
<head>
<title>Hi-Resolution Photo Editor (powered by PXN8)</title>
<link media="screen" title="Default Style" rel="stylesheet" href="memphis.css" type="text/css"/>

<script language="JavaScript" type="text/javascript" src="../../javascript/pxn8_all.js"></script>
<script language="JavaScript" type="text/javascript" src="../../javascript/pxn8_strings_en.js"></script>

<script language="JavaScript" type="text/javascript">
<!--

PXN8.root = "/pixenate";

var ops = {

    selectnone: [myselectnone,
	              'images/selectnone.gif',
					  'images/selectnonedisabled.gif'],

	 crop: [mycrop,
	        'images/crop.gif',
			  'images/cropdisabled.gif'],
				  
    undo: [myundo,
           'images/undo.gif',
           'images/undodisabled.gif'],

    redo: [myredo,
           'images/redo.gif',
           'images/redodisabled.gif'],

    undoall: [myundoall,
              'images/undoall.gif',
              'images/undoalldisabled.gif'],

    fitcanvas: [myfitcanvas,
                'images/fitcanvas.gif',
                'images/fitcanvasdisabled.gif'],

    zoomin: [myzoomin,
             'images/zoomin.gif',
             'images/zoomindisabled.gif'],

    zoomout: [myzoomout,
              'images/zoomout.gif',
              'images/zoomoutdisabled.gif']
             
};

function showpanel(id)
{
    document.getElementById(id).style.display = "block";
}
function hidepanel(id)
{
    document.getElementById(id).style.display = "none";
}

function myconfigresizepanel(element,event)
{
    showpanel('resizepanel');
    
    var fh = document.getElementById("resizeHeight");
    if (fh){
        fh.value = PXN8.image.height;
    }
    
    var fw = document.getElementById("resizeWidth");
    if (fw){
        fw.value = PXN8.image.width;
        fw.focus();
    } 
}
function myresize()
{
    PXN8.tools.ui.resize();
    hidepanel('resizepanel');
}

function myundoall(element,event)
{
    PXN8.tools.undoall();

    setEnabled('undo',PXN8.opNumber > 0);
    setEnabled('undoall',PXN8.opNumber > 0);
    setEnabled('redo',PXN8.maxOpNumber > PXN8.opNumber);

}

function myundo(element, event)
{
    PXN8.tools.undo();

    setEnabled('undo',PXN8.opNumber > 0);
    setEnabled('undoall',PXN8.opNumber > 0);
    setEnabled('redo',PXN8.maxOpNumber > PXN8.opNumber);
    return false;
    
}
function myrotate (element, event)
{
    PXN8.tools.rotate({angle: 90});
    return false;
    
}
function mycolors (param, value, element, event)
{
    if (param == "brightness"){
        PXN8.tools.colors({brightness: value});
    }
    if (param == "contrast"){
        PXN8.tools.colors({contrast: value});
    }
    
    return false;
}

function myzoomin (element, event)
{
    PXN8.zoom.zoomIn();
    setEnabled('zoomin',PXN8.zoom.canZoomIn());
    setEnabled('zoomout',PXN8.zoom.canZoomOut());
    setEnabled('fitcanvas',true);
    return false;
}
function myzoomout (element, event)
{
    PXN8.zoom.zoomOut();
    setEnabled('zoomin',PXN8.zoom.canZoomIn());
    setEnabled('zoomout',PXN8.zoom.canZoomOut());
    setEnabled('fitcanvas',true);
    return false;
}
function openUploadDlg()
{
	var dlg = document.getElementById("uploadArea");
	dlg.style.display = "block";
	var scroller = document.getElementById("pxn8_scroller");
	var seb = PXN8.dom.eb(scroller);
	dlg.style.top = seb.y + 30 + "px";
	dlg.style.left = seb.x + 30 + "px";
}
function closeUploadDlg()
{
	var dlg = document.getElementById("uploadArea");
	dlg.style.display = "none";
}
function myfitcanvas (element,event)
{
    var scroller = document.getElementById("pxn8_scroller");
    var width = parseInt(scroller.style.width);
    var height = parseInt(scroller.style.height);    
    PXN8.zoom.toSize(width,height);

    setEnabled('zoomout',PXN8.zoom.canZoomOut());
    setEnabled('zoomin',PXN8.zoom.canZoomIn());
    setEnabled('fitcanvas',false);

    return false;
}
/**
 * Setup listeners
 */
PXN8.listener.add(PXN8.ON_IMAGE_CHANGE,function(){
    setEnabled('fitcanvas',true);
    setEnabled('undo',PXN8.opNumber > 0);
    //setEnabled('save',PXN8.opNumber > 0);
    setEnabled('undoall',PXN8.opNumber > 0);
    setEnabled('redo',PXN8.maxOpNumber > PXN8.opNumber);
});

PXN8.listener.add(PXN8.ON_SELECTION_CHANGE, function(){
    var sel = PXN8.getSelection();
    setEnabled('selectnone',sel.width > 0);
	 setEnabled('crop',sel.width > 0);
});


function myselectnone(element,event)
{
    PXN8.unselect();
	 return false;
}
function mycrop(element, event)
{
    PXN8.tools.crop(PXN8.getSelection());
    return false;
}
/**
 * 
 */
function uploadImage()
{
    PXN8.prepareForSubmit('Uploading Image. Please wait...');
    document.getElementById('uploadForm').submit();
}

function myshrink(value)
{
    PXN8.tools.resize(PXN8.image.width*value,PXN8.image.height*value);

    return false;
}

function myredo(element, event)
{
    PXN8.tools.redo();

    setEnabled('undo',PXN8.opNumber > 0);
    setEnabled('undoall',PXN8.opNumber > 0);
    setEnabled('redo',PXN8.maxOpNumber > PXN8.opNumber);

    return false;
}

function empty()
{
    return false;
}

function setEnabled(id,enable)
{
    if (enable){
        var link = document.getElementById(id);
        link.onclick = ops[id][0];
        link.innerHTML = "<img src='" + ops[id][1] + "' id='" + id + "Btn' border='0'/>";
    }else{
        var link = document.getElementById(id);
        link.onclick = empty;
        link.innerHTML = "<img src='" + ops[id][2] + "' id='" + id + "Btn' border='0'/>";
    }
}
/**
 * Called when the imaage upload form is about to be submitted.
 */
function submit_upload_form()
{
    var fname = document.getElementById("filename").value;
    if (fname == "" ){
        alert("Press the Browse button to choose a file first");
        return false;
    }
    return true;
}
-->
</script>
</head>


    


<%

  image = "/pixenate/images/samples/hongkong.jpg"

  If Request.QueryString("image") <> "" Then
     image = Request.QueryString("image")
  End If

  originalFilename = ""

  If Request.QueryString("originalFilename") <> "" Then
     originalFilename = Request.QueryString("originalFilename")
  End If
%>
<body bgcolor="white">
<script type="text/javascript">
pxn8_original_filename = "<%=originalFilename%>";
PXN8.dom.addLoadEvent(function(){
	PXN8.initialize('<%=image%>');
	/**
    * HERE IS A GOOD PLACE TO ADD YOUR OWN ON_IMAGE_LOAD LISTENER
    *
	PXN8.listener.add(PXN8.ON_IMAGE_LOAD,function(){
	});
   */
});
</script>    


<script type="text/javascript">
    PXN8.dom.addLoadEvent(function(){
        PXN8.listener.add(PXN8.ON_HIRES_BEGIN,function(){
            var hiResStatus = document.getElementById("hiResStatus");
            hiResStatus.innerHTML = "Updating hi-res image...";
            var saveBtnImage = document.getElementById("saveBtn");
            saveBtnImage.src = "images/savedisabled.gif";
        });
        PXN8.listener.add(PXN8.ON_HIRES_COMPLETE,function(){
            var hiResStatus = document.getElementById("hiResStatus");
            hiResStatus.innerHTML = "";
            var saveBtnImage = document.getElementById("saveBtn");
            if (PXN8.opNumber > 0){
                saveBtnImage.src = "images/save.gif";
            }else{
                saveBtnImage.src = "images/savedisabled.gif";
            }
        });
        /**
         * This is the only thing that is different about this theme
         * This is how you kick off the hi-res image update
         */



  hires_image = "/pixenate/images/samples/hongkong.jpg"

  If Request.QueryString("hires_image") <> "" Then
     hires_image = Request.QueryString("hires_image")
  End If
PXN8.hires.init("<%= hires_image %>");


        
    });
</script>
                      
<div id="toolArea">

<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Zoom</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a id="zoomin" href="javascript:void(0)" onclick="return myzoomin(this,event);"><img id="zoominBtn" src="images/zoomin.gif" border="0"/></a></td>
<td><a id="zoomout" href="javascript:void(0)" onclick="return myzoomout(this,event);"><img id="zoomoutBtn" src="images/zoomout.gif" border="0"/></a></td>
<td><a id="fitcanvas" href="javascript:void(0)" onclick="return myfitcanvas(this,event);"><img id="fitcanvasBtn" src="images/fitcanvas.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->

<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Cropping</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a id="selectnone" href="javascript:void(0)" onclick="return false;"><img id="selectnoneBtn" src="images/selectnonedisabled.gif" border="0"/></a></td>
<td><a id="crop" href="javascript:void(0)" onclick="return false;"><img id="cropBtn" src="images/cropdisabled.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->


<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Shrink by</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a href="javascript:void(0)" onclick="return myshrink(0.90)"><img src="images/10percent.gif" border="0"/></a></td>
<td><a href="javascript:void(0)" onclick="return myshrink(0.75);"><img src="images/25percent.gif" border="0"/></a></td>
<td><a href="javascript:void(0)" onclick="return myshrink(0.50);"><img src="images/50percent.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->


<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Shape</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a href="javascript:void(0)" onclick="myconfigresizepanel(); return false;"><img src="images/resizeto.gif" border="0"/></a></td>
<td><a href="javascript:void(0)" onclick="myrotate();"><img src="images/rotate.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->
</div> <!-- end of titledPanel -->


<div id="resizepanel" class="titledPanel" style="display: none;">
<div class="panelTitle"><span class="panelTitle">Resize</span></div>
<div class="titledPanelInner">
<form onsubmit="return false;">
  <table>
   <tr>
      <td><input onclick="preserveRatio(this);" type="checkbox" checked id="preserve"  value="true"/></td>
      <td>maintain aspect ratio</td>
   </tr>
   <tr>
      <td>width:</td>
      <td><input onfocus="this.select()" 
                 onblur="changeDim('width')" 
                 class="pxn8_small_field" 
                 type="text" 
                 id="resizeWidth" 
                 name="resizeWidth"/></td>
   </tr>
   <tr>
      <td>height:</td>
      <td><input onfocus="this.select()" 
                 onblur="changeDim('height')" 
                 class="pxn8_small_field" 
                 type="text" 
                 id="resizeHeight" 
                 name="resizeHeight"/></td>
   </tr>

   <tr>
     <td><a href="javascript:void(0)" onclick="myresize(this,event); return false;"><img src="images/apply.gif" border="0"/></a></td>
     <td><a href="javascript:void(0)" onclick="hidepanel('resizepanel');return false;"><img src="images/cancel.gif" border="0"/></a></td>
   </tr>
  </table>
</form>
</div> <!-- end of titledPanelInner -->
</div> <!-- end of titledPanel -->

<div>
<table width="100%">
<tr>
<td>
<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Bright</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a href="javascript:void(0)" onclick="mycolors('brightness',110,this,event);return false;"><img src="images/plus.gif" border="0"/></a></td>
<td><a href="javascript:void(0)" onclick="mycolors('brightness',90,this,event);return false;"><img src="images/minus.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->
</td>
<td>
<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Contrast</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a href="javascript:void(0)" onclick="mycolors('contrast',1,this,event);return false;"><img src="images/plus.gif" border="0"/></a></td>
<td><a href="javascript:void(0)" onclick="mycolors('contrast',-1,this,event);return false;"><img src="images/minus.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->
</td>
</tr>
</table>
</div>


<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Edits</span></div>
<div class="titledPanelInner">
<table>
<tr>
<td><a id="undo" href="javascript:void(0)" onclick="myundo(this,event);return false;"><img id="undoBtn" src="images/undodisabled.gif" border="0"/></a></td>
<td><a id="undoall" href="javascript:void(0)" onclick="return false;"><img id="undoallBtn" src="images/undoalldisabled.gif" border="0"/></a></td>
<td><a id="redo" href="javascript:void(0)" onclick="myredo(); return false;"><img id="redoBtn" src="images/redodisabled.gif" border="0"/></a></td>
</tr>
</table> 
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->

<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">File</span></div>
<div class="titledPanelInner">
<table>
<tr>
   <td colspan="2"><a onclick="openUploadDlg();return true;"><img src="images/openUploadDlg.gif" border="0"/></a></td>
</tr>
<tr>
<td><a id="save" href="javascript:PXN8.save.toDisk()" ><img id="saveBtn" src="images/savedisabled.gif" border="0"/></a></td>
<td><a href="javascript:history.go(-1);"><img src="images/cancel.gif" border="0"/></a></td>
</tr>
</table>
</div> <!-- end of titledPanelInner -->

</div> <!-- end of titledPanel -->


</div> <!-- end of toolArea -->


<div id="canvas_container">
<div>
<table class="infotable">
  <tr>
    <td valign="top" class="infolabel">Selection:</td>
    <td id="pxn8_selection_size"> ----,---- </td>
    <td valign="top" class="infolabel">Size:</td>
    <td id="pxn8_image_size"> ----,---- </td>
    <td valign="top" class="infolabel">Zoom:</td>
    <td id="pxn8_zoom"> 100% </td>
    <td valign="top" class="infolabel">Position:</td>
    <td id="pxn8_mouse_pos"> ----,---- </td>
  </tr>
</table>
</div>

<!-- 
     This is an example of a relatively positioned canvas .
     Other elements can appear below or to the right of the canvas.
-->
<div id="pxn8_scroller" style="border: 3px solid #999999;width: 600px; height: 400px; overflow: auto;">
<div style=" position: relative; top:0px; left: 0px; float: left;" id="pxn8_canvas">
</div><!-- end of canvas -->
</div>

<div id="hiResStatus">
</div>

<!-- logging is optional 
<div id="pxn8_log">
</div>
-->

</div> <!-- end of canvas_container -->

<div id="pxn8_timer" style="display:none;"> Updating image. Please wait...</div>
 
<img src="images/undodisabled.gif" style="display:none;"/>
<img src="images/undoalldisabled.gif" style="display:none;"/>
<img src="images/redodisabled.gif" style="display:none;"/>


<div id="uploadArea" style="display:none; ">
<div class="titledPanel">
<div class="panelTitle"><span class="panelTitle">Upload Photo</span></div>
<div class="titledPanelInner">
<form action="/pixenate/upload.pl" 
      method="POST" id="uploadForm"
      enctype="multipart/form-data"
      onsubmit="return submit_upload_form();">
<input type="hidden" name="pxn8_root" value="/pixenate"/>
<input type="hidden" name="next_page" value="/pixenate/themes/hires/index.asp"/>
<input type="hidden" name="image_param_name" value="image" />
<!-- 
	
	max_dim parameter specifies the maximum size that an image must be by
	either width or height.
	Images which are greater than this size will be resized automatically
	by the upload.pl script.
	
-->
<input type="hidden" name="max_dim" value="600" />
<!--

	hires_image_param_name specifies the name of the hires_image_param to use.
	This is used by upload.pl to pass the hires version of the image back to the page
	from which it was called.

-->
<input type="hidden" name="hires_image_param_name" value="hires_image" />

<table>
<tr>
  <td colspan="2"><input type="file" name="filename" id="filename" ></td>
</tr>
<tr>
  <td><a onclick="closeUploadDlg();uploadImage();return true;"><img src="images/upload.gif" border="0"/></a></td>
  <td><a onclick="closeUploadDlg();return false;"><img src="images/cancel.gif" border="0"/></a></td>
</table>
</form>
</div><!-- titledPanelInner -->
</div><!-- titledPanel -->
</div><!-- uploadArea -->

</body>

</html>