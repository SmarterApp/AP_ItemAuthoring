
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<!-- 
    (c) Copyright SXOOP Technology 2005-2006
    All rights reserved.
-->
<head>
  <title>PXN8.COM - Online Photo Editor</title>
  <meta http-equiv="Content-Type" CONTENT="text/html; charset=iso-8859-1"/>
  <meta name="keywords" content="Online photo editor"/>
  <link media="screen" title="" rel="stylesheet" href="./slick.css" type="text/css"/>
  
  <script type="text/javascript" src="../../javascript/pxn8_all.js"></script>
  
  <script type="text/javascript" src="../../javascript/pxn8_strings_en.js"></script>
  <script type="text/javascript" src="./slick.js"></script>
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

</script>
</head>

<% 
   String image = "/pixenate/images/samples/hongkong.jpg"; 
   if (request.getParameter("image") != null){ 
      image= request.getParameter("image");
   } 
   String originalFilename = "";
   if (request.getParameter("originalFilename") != null){ 
      originalFilename= request.getParameter("originalFilename");
   } 
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

    

    


<div id="content">
  <img src="images/logo.gif"/>


  <div id="banner">
    
    <h1 style="color: maroon;">Buy PXN8!</h1>
    PXN8 is available to purchase for install on your own servers. For
    details and pricing see our <a href="productinfo.html">product information page</a>.
    
    
  </div> <!-- end of banner -->

  <div id="left_pane">
    <table cellpadding="0" cellspacing="0" border="0" class="lefttable">
      <tr>
        <td>
          <div id="image_source" style="line-height: 14px;">
            1. <a href="javascript:void(0);" onclick="return toggleVisibility(this,'sourceoptions');">Choose your image to edit.</a>
            <div id="sourceoptions" style="display: none;margin-top: 4px; background: #efefef url(images/topcorners.gif) top left no-repeat;">
              <div id="paddedsourceoptions" style="padding-left: 8px; padding-top:8px;">
                Use an image stored on your computer or camera.
                <p style="font-size: 10px; color: #888888;">(make sure your camera is connected and turned on.)</p>
                
                <form action="/pixenate/upload.pl" method="POST" enctype="multipart/form-data" onsubmit="return submit_upload_form();">
                  <input type="hidden" name="pxn8_root" value="/pixenate"/>
                  <input type="hidden" name="next_page" value="/pixenate/themes/slick/index.jsp"/>
                  <input type="hidden" name="image_param_name" value="image" />
                  <input class="pxn8_has_tooltip" type="file" name="filename" id="filename" >
                  <input style="margin-top: 4px;" onmouseover="PXN8.tooltip.show(this,'filename');" onmouseout="PXN8.tooltip.hide(this,'filename');" type="submit" 
                         onclick="PXN8.tooltip.hide(this,'filename');PXN8.prepareForSubmit('Uploading Image. Please wait...');"
                      value="Upload this image."     />
                </form>
                <div style="margin-top: 8px; padding: 4px; border-top: 2px solid #cccccc;">
                   Or <a href="javascript:void(0)" onclick="return loadImageFromPrompt();">enter the web address of an image</a>
                  
                </div>
                You can edit any image on the web using this bookmarklet...
                
                <a class="bookmarklet" title="Import to PXN8"  
                   onclick="alert('You must first drag and drop this link onto the browser\'s links toolbar.\n' +
                   '(Internet Explorer users: right click and select \'Add to Favourites\'; Create in \'Links\')\n'+
                   'To use this bookmarklet, Visit a web page with images and click the \'Import to PXN8\' button in your browser\'s toolbar');return false;" 
                   href="javascript:try{void(d=document);void(h=d.getElementsByTagName('head')[0]);void((s=d.createElement('script')).setAttribute('src','http://pxn8.com/bookmarklet.js'));void(h.appendChild(s));}catch(e){void(window.location.href='http://pxn8.com/index.pl?image='+escape(window.location.href));}">Import to PXN8</a>
                Drag and drop the bookmarklet onto your browser's <b>Links</b> toolbar. Now when you're viewing a web page with photos, you can edit any photo by clicking the 'Import to PXN8' button in your 'Links' toolbar.    
              </div> <!-- end of paddedsourceoptions -->
            </div> <!-- end of source_options -->
          </div> <!-- end of image_source -->
        </td>
      </tr>
      <tr>
        <td>
          <div id="tools">
            2. Edit your image with the following tools.  
            
            <div id="tool_palette" style="margin-top: 4px; padding: 4px; background: #e0e0e0 url(images/topcorners.gif) top left no-repeat;">
              <div id="all_tools">
                <table class="toolstable" id="tool_table">
                  <tr>
                    <!-- undo -->
                    <td><a id="undo" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="PXN8.tooltip.hide(this);PXN8.tools.undo(); return false;"><img src="../shared/images/undo.gif" border="0" /></a></td>
                    <!-- redo -->
                    <td><a id="redo" href="javascript:void(0)" class="pxn8_has_tooltip" 
                           onclick="PXN8.tooltip.hide(this);PXN8.tools.redo(); return false;"><img src="../shared/images/redo.gif" border="0" /></a></td>
                    <!-- select all -->
                    <td><a id="selectall" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="PXN8.tooltip.hide(this);PXN8.selectAll();return false;"><img src="../shared/images/select_all.gif" border="0"></a></td>
                    <!-- select none -->
                    <td><a id="selectnone" href="javascript:void(0)" class="pxn8_has_tooltip"
                           onclick="PXN8.tooltip.hide(this);PXN8.unselect(); return false;"><img src="../shared/images/select_none.gif" border="0"></a></td>
                  </tr>
                  <tr>
                    <!-- zoom in -->
                    <td><a id="zoomin" href="javascript:void(0)" class="pxn8_has_tooltip"
                           onclick="PXN8.tooltip.hide(this);PXN8.zoom.zoomIn();"><img src="../shared/images/zoomplus.gif" border="0"></a></td>
                    <!-- zoom out -->
                    <td><a id="zoomout" href="javascript:void(0)" class="pxn8_has_tooltip"
                           onclick="PXN8.tooltip.hide(this);PXN8.zoom.zoomOut();"><img src="../shared/images/zoomminus.gif" border="0"></a></td>
                    <td><a id="enhance" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="PXN8.tooltip.hide(this);PXN8.tools.instantFix();return false;"><img src="../shared/images/enhance.gif" border="0"/></a></td>
                    <td><a id="fill_flash" class="pxn8_has_tooltip" href="javascript:void(0)"
                           onclick="PXN8.tooltip.hide(this);PXN8.tools.fill_flash(); return false;"><img src="../shared/images/fill_light.gif" border="0"/></a></td>
                  </tr>
                  <tr>
                    <!-- crop -->
                    <td><a id="crop" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(PXN8.tools.ui.config_crop,this,event);return false;"><img src="../shared/images/crop.gif" border="0"/></a></td>
                    <td><a id="resize" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(PXN8.tools.ui.config_resize,this,event);return false;"><img src="../shared/images/resize.gif" border="0"/></a></td>
                    <!-- rotate -->
                    <td><a id="rotate" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="PXN8.tooltip.hide(this);return slickRotate(event);"><img src="../shared/images/rotate.gif" border="0"/></a></td>
                    <!-- spiritlevel -->
                    <td><a id="spiritlevel" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(spiritlevelmode,this,event);return false;"><img src="../shared/images/spiritlevel.gif" border="0"/></a></td>
                  </tr>
                  <tr>
                    <td><a id="redeye" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(PXN8.tools.ui.config_redeye,this,event); return false;"><img src="../shared/images/redeye.gif" border="0"></a></td>
                    <!-- whiten teeth -->
                    <td><a id="whiten" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="PXN8.tooltip.hide(this);PXN8.tools.ui.whiten(); return false;"><img src="../shared/images/whiten.gif" border="0"/></a></td>
                    <!-- sepia -->
                    <td><a id="sepia" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(PXN8.tools.ui.config_sepia,this,event); return false;"><img src="../shared/images/sepia.gif" border="0"/></a></td>
                    <!-- brightness, hue & saturation -->
                    <td><a id="bsh" class="pxn8_has_tooltip" href="javascript:void(0)" 
                           onclick="configureTool(PXN8.tools.ui.config_bsh,this,event); return false;"><img src="../shared/images/bsh.gif" border="0"/></a></td>
                  </tr>
                </table>
                <a href="javascript:void(0)" class="collapsed" onclick="return toggleVisibility(this,'fun_effects',{show: 'Show fun effects', hide: 'Hide fun effects'});">Show fun effects</a>
                <div style="display:none;" id="fun_effects">
                  <table class="toolstable">
                    <tr>
                      <!-- lomo -->
                      <td><a id="lomo" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="configureTool(PXN8.tools.ui.config_lomo,this,event); return false;"><img src="../shared/images/lomo.gif" border="0"/></a></td>
                      <!-- filter -->
                      <td><a id="filter" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="configureTool(PXN8.tools.ui.config_filter,this,event); return false;"><img src="../shared/images/filter.gif" border="0"/></a></td>
                      <!-- add rounded corner -->
                      <td><a id="roundedcorners" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="configureTool(PXN8.tools.ui.config_roundedcorners,this,event); return false;"><img src="../shared/images/round_corners.gif" border="0" /></a></td>
                      <!-- interlace -->
                      <td><a id="interlace" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="configureTool(PXN8.tools.ui.config_interlace,this,event); return false;"><img src="../shared/images/interlace.gif" border="0" /></a></td>
                    </tr>
                    <tr>
                      <td><a id="blur" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="configureTool(PXN8.tools.ui.config_blur,this,event); return false;"><img src="../shared/images/blur.gif" border="0" /></a></td>
                      <td><a id="snow" class="pxn8_has_tooltip" href="javascript:void(0)" 
                             onclick="PXN8.tooltip.hide(this);PXN8.tools.snow(); return false;"><img src="../shared/images/snow.gif" border="0"/></a></td>
                      <td><a href="javascript:void(0)" onclick="configureTool(showConfigText,this,event); return false;"><img src="../shared/images/text.gif" border="0"/></a></td>
                      <td>&nbsp;</td>
                    </tr>
                  </table>
                </div> <!-- end fun_effects -->
              </div> <!-- end all_tools -->
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
        </td>
      </tr>
      <tr>
        <td>
          <div id="image_save">
            3. What would you like to do with this image ?
            
            <div style="margin-top: 4px; padding: 4px; background: #efefef url(images/topcorners.gif) top left no-repeat;">
              <table>
                <tr>
                  <td style="padding-right: 8px; border-right: 2px dotted #888888;"><a id="save" class="pxn8_has_tooltip" style="padding-left: 24px;" href="javascript:PXN8.save.toDisk()"><img style="padding-bottom: 4px;" src="images/save2disk.gif" border="0"></a>
                    <p style="padding-left: auto; padding-right: auto;text-align:center;">Save to Disk.</p>
                  </td>
                  <td style="padding-left: 8px;">
                    <form style="padding-left: 20px;" action="/pixenate/flickrLogin.pl"  method="POST" onsubmit="return PXN8.save.toFlickr(this);">
                      <input type="image" src="images/save2flickr.gif" border="0" name="submit" id="flickrsave" class="pxn8_has_tooltip" />
                    </form>
                    <p style="padding-left: auto; padding-right:auto;text-align: center;">Upload to Flickr.</p>
                  </td>
                </tr>
                <tr>
                  <td style="border-top: 2px dotted #888888;padding-top: 4px" valign="top" colspan="2">
                    <a href="javascript:void(0)" onclick="PXN8.save.allyoucanupload(); return false;"><img align="right" src="../../images/aycu_medium.gif" border="0"/></a>
                    <span style="font-size: 10px">To save this image permanently on the Internet for use on MySpace, Bebo or others. Click here.</span>
                  </td>
                </tr>
              </table>
            </div>
          </div> <!-- end of image_save -->
        </td>
      </tr>
      <tr>
        <td style="text-align: center;font-size: 80%;">&copy; 2005-2006 <a style="font-size: 100%;" href="http://www.sxoop.com/">Sxoop Technologies Ltd.</a> All rights reserved.</td>
      </tr>
      
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
          <td valign="top" class="infolabel">Zoom:</td>
          <td id="pxn8_zoom"> 100% </td>
          <td valign="top" class="infolabel">Position:</td>
          <td id="pxn8_mouse_pos"> ----,---- </td>
        </tr>
      </table>
    </div>
  <!-- This is an example of a relatively positioned canvas .
       Other elements can appear below or to the right of the canvas.
  -->
    <div style="float: left;">
      <div id="pxn8_canvas"></div>
    </div>
    <div id="google_ads" style="clear: left;  margin-top: 8px; padding-top: 10px; padding-left: 0px; background: #efefef url(images/topcorners736.gif) top left no-repeat; width: 740px; height: 100px;">
     <script type="text/javascript"><!--
     google_ad_client = "pub-6257674001240662";
     google_ad_width = 728;
     google_ad_height = 90;
     google_ad_format = "728x90_as";
     google_ad_type = "text_image";
     google_ad_channel ="";
     google_color_border = "EFEFEF";
     google_color_bg = "EFEFEF";
     google_color_link = "4682B4";
     google_color_url = "800000";
     google_color_text = "000000";
     //--></script>
     <script type="text/javascript"
       src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
     </script>
    </div><!-- end of google_ads -->
    <!-- logging is optional  
    <a href="#" onclick="document.getElementById('pxn8_log').innerHTML = '';return false;">Clear Log</a>
    <div id="pxn8_log" style="height: 360px; width: 640px; overflow:auto;"></div>
    -->
  </div> <!-- end of canvas_container -->

</div><!-- end of content -->
   <%@ include file="../shared/tooltips.html" %>
<div id="pxn8_preloaded_images"></div>
<!-- ///////////////////////////////////////////
     THIS PANEL IS FOR CONFIGURING THE TEXT TOOL 
     ///////////////////////////////////////////
-->
<textarea id="configure_text" style="display: none;">
<table width="100%">
  <tr>
    <td>Color:</td>
    <td><input type="text" class="pxn8_small_field" id="text_color" name="text_color" value="#FFFFFF" /></td>
  </tr>
  <tr>
    <td>Font:</td>
    <td><select name="font" id="font">
          <!-- Arial is guaranteed to be on most machines -->
          <option value="Arial">Arial</option>
        </select>
    </td>
  </tr>
  <tr>
    <td>Size:</td>
    <td><input type="text" class="pxn8_small_field" value="32" name="pointsize" id="pointsize">pt</td>
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
    <td colspan="2"><a href="javascript:void(0)" onclick="return previewText();">Preview</a> (Preview may not exactly match the operation)</td>
  </tr>     
</table>
</textarea>
</body>
</html>