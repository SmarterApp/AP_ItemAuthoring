package Action::editImage; 

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  my $image = $pxn8Url . "images/samples/hongkong.jpg";
  if ( $q->param("image") ne "" ) {
      $image = $q->param("image");
  }
  
  my $originalFilename = "";
  
  if ( defined( $q->param("originalFilename") )
      && $q->param("originalFilename") ne "" )
  {
      $originalFilename = $q->param("originalFilename");
  }
  
  my $itemBankId = '';
  if ( $q->param('item_bank_id') ne '' ) {
      $itemBankId = $q->param('item_bank_id');
  }
  
  my $itemName = '';
  if ( $q->param('item_name') ne '' ) {
      $itemName = $q->param('item_name');
  }
  
  my $imageName = $image;
  
  $image = "${imagesUrl}lib${itemBankId}/${itemName}/${image}";
  
  my $psgi_out = <<END_HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<!-- 
    (c) Copyright SXOOP Technology 2005-2006
    All rights reserved.
-->
<head>
<title>Image Editor</title>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1"/>

    <link media="screen" title="" rel="stylesheet" href="${pxn8Url}/styles/pxn8.css" type="text/css"/>

<script type="text/javascript" src="${pxn8Url}javascript/pxn8_all.js"></script>

<script type="text/javascript" src="${pxn8Url}javascript/pxn8_strings_en.js"></script>

<script type="text/javascript" src="${pxn8Url}javascript/pxn8.js"></script>

<script type="text/javascript">

/**
 * Preview the text as it will appear when the AddText operation is performed.
 */
function previewText()
{
    var dom = PXN8.dom;
    var color= dom.id("text_color").value;
    var fontEl = dom.id("font");
    var font = fontEl.options[fontEl.selectedIndex].value;
    var size = parseInt(dom.id("pointsize").value);
    var gravEl = dom.id("gravity");
    var gravity = gravEl.options[gravEl.selectedIndex].value;
    var text = dom.id("text").value;
    
    var imgBounds = dom.eb(dom.id("pxn8_image"));
    
    var preview = dom.ce("div",{id: "pxn8_text_preview"});
    preview.style.position = "absolute";
    preview.style.width = imgBounds.width + "px";
    preview.style.left = imgBounds.x + "px";
    preview.style.color = color;
    preview.style.fontSize = size + "px";
    preview.style.textAlign = "center";
    preview.style.top = imgBounds.y + ((imgBounds.height/2) - size/2) + "px";

    dom.ac(preview,dom.tx(text));
    dom.ac(document.body,preview);

    if (gravity.match("South")){
        preview.style.top = imgBounds.y  + (imgBounds.height - (size + 5)) + "px";
    }
    if (gravity.match("North")){
        preview.style.top = imgBounds.y + "px";
    }
    if (gravity.match("West")){
        preview.style.textAlign = "left";
    }
    if (gravity.match("East")){
        preview.style.textAlign = "right";
    }
    setTimeout(function(){
        document.body.removeChild(preview);
    },3000);
}

/**
 * Show the Text Configuration Tool Panel
 */
function showConfigText()
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    
    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx("Add Text to image"));
    
    
    var cfgContent = dom.cl(dom.id("pxn8_config_content"));

    var picker = PXN8.colors.picker("#FFFFFF",function(color){
        dom.id("text_color").value = color;
    });

    dom.ac(cfgContent,picker);
    
    var ih = dom.id("configure_text").innerHTML;
    ih = ih.replace(/&lt;/g,"<");
    ih = ih.replace(/&gt;/g,">");
    /**
     * wph 20060821: Can't just append to cfgContent.innerHTML
     * because doing so wipes out the onclick handler for the color picker.
     * Strangely, creating a div, setting it's innerHTML and appending the div
     * using DOM works.
     */
    var div = dom.ce("div");
    div.innerHTML = ih;
    dom.ac(cfgContent,div);

    applyBtn.onclick = function(){ 
        var color= dom.id("text_color").value;
        var fontEl = dom.id("font");
        var font = fontEl.options[fontEl.selectedIndex].value;
        var size = dom.id("pointsize").value;
        var gravEl = dom.id("gravity");
        var gravity = gravEl.options[gravEl.selectedIndex].value;
        var text = escape(dom.id("text").value);
        PXN8.tools.add_text({
            "gravity": gravity,
            "fill": color,
            "font": font,
            "point-size": size,
            "text": text});
        return false;
    };

	 var text = document.getElementById("text");
	 
	 text.focus();
    text.select();
    
}

function pxn8_save_image(){
   document.location = "${imageSaveUrl}?item_bank_id=${itemBankId}&item_name=${itemName}&image_name=${imageName}&cached_image=" + PXN8.getUncompressedImage(); }

</script>

</head>
<body bgcolor="white">
<script type="text/javascript">
pxn8_original_filename = "${originalFilename}";
PXN8.dom.addLoadEvent(function(){
	PXN8.initialize('${image}');
	/**
    * HERE IS A GOOD PLACE TO ADD YOUR OWN ON_IMAGE_LOAD LISTENER
    *
	PXN8.listener.add(PXN8.ON_IMAGE_LOAD,function(){
	});
   */
});
</script>


<div id="content">
<span style="font-size: 12pt;">Image Editor</span>
<!--
<div id="banner">
</div> 
-->
<!-- end of banner -->


<div id="left_pane">

<table cellpadding="0" cellspacing="0" border="0" class="lefttable">


<tr><td>

<div id="tools">


<div id="tool_palette" style="margin-top: 4px; padding: 4px; background: #e0e0e0 url(images/topcorners.gif) top left no-repeat;">

<div id="all_tools">
<table class="toolstable" id="tool_table">
<tr>

   <!-- undo -->
   <td><a id="undo" class="pxn8_has_tooltip"
                href="javascript:void(0)" onclick="PXN8.tooltip.hide(this);PXN8.tools.undo(); return false;"><img 
          src="${pxn8Url}themes/shared/images/undo.gif" border="0" 
          alt="" title=""/></a></td>
   <!-- redo -->
   <td><a id="redo" href="javascript:void(0)" class="pxn8_has_tooltip"
           onclick="PXN8.tooltip.hide(this);PXN8.tools.redo(); return false;"><img 
          src="${pxn8Url}themes/shared/images/redo.gif" border="0" 
          alt="" title=""/></a></td>

   <!-- rotate -->
   <td><a id="rotate" class="pxn8_has_tooltip"
       href="javascript:void(0)" onclick="PXN8.tooltip.hide(this);return slickRotate(event);"><img 
       title="" alt="" src="${pxn8Url}themes/shared/images/rotate.gif" border="0"/></a></td>

</tr>

<tr>
   <!-- crop -->
   <td><a id="crop" class="pxn8_has_tooltip"
       href="javascript:void(0)" onclick="configureTool(PXN8.tools.ui.config_crop,this,event);return false;"><img 
       title="" alt="" src="${pxn8Url}themes/shared/images/crop.gif" border="0"/></a></td>

   <td><a id="resize" class="pxn8_has_tooltip"
       href="javascript:void(0)" onclick="configureTool(PXN8.tools.ui.config_resize,this,event);return false;"><img 
       title="" alt="" src="${pxn8Url}themes/shared/images/resize.gif" border="0"/></a></td>

   <!-- sepia -->
   <td><a id="sepia" class="pxn8_has_tooltip"
       href="javascript:void(0)" onclick="configureTool(PXN8.tools.ui.config_sepia,this,event); return false;"><img 
       title="" alt="" src="${pxn8Url}themes/shared/images/sepia.gif" border="0"/></a></td>

</tr>

</table>
</div> <!-- end fun_effects -->
</div> <!-- end all_tools -->

<!-- ///////////////////////////////////////////
     THIS PANEL IS FOR CONFIGURING THE TEXT TOOL 
     ///////////////////////////////////////////
-->

<textarea id="configure_text" style="display: none;">
<table width="100%">
<tr>
       <td>Color:</td>
       <td><input type="text" class="pxn8_small_field" 
                  id="text_color" name="text_color" value="#FFFFFF" /></td>
</tr>
<tr>
  <td>Font:</td>
  <td><select name="font" id="font">
      <!-- Arial is guaranteed to be on most machines -->
	     <option value="Arial">Arial</option>
      </select></td>
</tr>
<tr>
  <td>Size:</td>
  <td><input type="text" class="pxn8_small_field"
             value="32" name="pointsize" id="pointsize">pt</td>
</tr>
<tr>
  <td>Gravity:</td>
  <td><select name="gravity" id="gravity">
	     <option value="Center">Center</option>
        <option value="North">North</option>
        <option value="South">South</option>
        <option value="East">East</option>
        <option value="West">West</option>
        <option value="NorthEast">NorthEast</option>
        <option value="NorthWest">NorthWest</option>
        <option value="SouthEast" selected>SouthEast</option>
        <option value="SouthWest">SouthWest</option>
	   </select></td>
</tr>
<tr>
  <td>Text:</td>
  <td><input type="text" name="text" id="text" value="Text goes here"/></td>
</tr>   
<tr>
  <td colspan="2"><a href="javascript:void(0)" 
                     onclick="return previewText();">Preview</a> 
      (Preview may not exactly match the operation)</td>
</tr>     
</table>
</textarea>

<div id="pxn8_config_area" class="panel" style="display: none;">
<div id="pxn8_config_title"></div>
<div id="pxn8_config_content"></div>
<div class="pxn8_config_buttons" align="right">
<a id="pxn8_cancel" class="pxn8_button" href="javascript:void(0)" onclick="toggleConfigVisibility(false); return false;" >Cancel</a>
<a id="pxn8_apply" class="pxn8_button" style="" href="javascript:void(0)">Apply</a>
</div>
<div id="pxn8_tool_prompt">&nbsp;</div>
</div> <!-- end config_area -->

</div> <!-- end inner tool_palette -->


</div> <!-- end of tools -->
</td></tr>

<tr><td>
<div id="image_save">
<div style="margin-top: 4px; padding: 4px; background: #efefef url(./images/topcorners.gif) top left no-repeat;">
<table>
  <tr>
    <td style="padding-right: 2px; border-right: 2px #888888;" align="center"><a 
	      id="save" class="pxn8_has_tooltip"
         style="padding-left: 4px;" href="javascript:pxn8_save_image()"><img 
         style="padding-bottom: 4px;" 
         src="./images/save2disk.gif" border="0"></a>
	 <p style="padding-left: auto; padding-right: auto;text-align: center;">Save Changes</p></td>
  </tr>
</table>
</div>
</div> <!-- end of image_save -->
</td></tr>
</table> 

</div><!-- end of left_pane-->

<div id="canvas_container">

<div>
<table class="infotable">
  <tr>
    <td valign="top" class="infolabel">Selection:</td>
    <td id="pxn8_selection_size"> ----,---- </td>
    <td valign="top" class="infolabel">Size:</td>
    <td id="pxn8_image_size"> ----,---- </td>
    <!-- 
    <td valign="top" class="infolabel">Zoom:</td>
    <td id="pxn8_zoom"> 100% </td>
    --> 
    <td valign="top" class="infolabel">Position:</td>
    <td id="pxn8_mouse_pos"> ----,---- </td>
  </tr>
</table>
<br />
</div>

<!-- 
     This is an example of a relatively positioned canvas .
     Other elements can appear below or to the right of the canvas.
-->

<div style="float: left;">
<div id="pxn8_canvas">
</div><!-- end of canvas -->

</div>


<!-- logging is optional  
<a href="#" onclick="document.getElementById('pxn8_log').innerHTML = '';return false;">Clear Log</a>
<div id="pxn8_log" style="height: 360px; width: 640px; overflow:auto;">
</div>
-->

</div> <!-- end of canvas_container -->

</div><!-- end of content -->
 


<div id="pxn8_preloaded_images"></div>

</body>
</html>
END_HTML

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
1;
