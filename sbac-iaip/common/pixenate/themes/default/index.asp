
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<!-- 
    (c) Copyright SXOOP Technology 2005-2006
    All rights reserved.
-->
<head>
<title>PXN8.COM - Photos Made Easy</title>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1"/>
    <meta name="keywords" content="Online photo editing"/>

    <link media="screen" title="Default Style" rel="stylesheet" href="./default.css" type="text/css"/>

<script language="JavaScript" type="text/javascript" src="../../javascript/pxn8_all.js"></script>
<script language="JavaScript" type="text/javascript" src="../../javascript/pxn8_strings_en.js"></script>

<script language="Javascript" type="text/javascript"><!--

PXN8.root = "/pixenate";

function submit_upload_form(form)
{
  var filename = document.getElementById("filename").value;
  if (filename == "" ){
    alert("Press the Browse button to choose a file first");
    return false;
  }
  return true;
}

function loadImageFromField()
{
   var loc = document.getElementById("imageUrl").value;
	PXN8.loadImage(loc);
}
/*
 * Hide the tool config panel 
 */
function hideConfig()
{
    var configArea = document.getElementById("pxn8_config_area");
    configArea.style.display = "none";
}

function showConfig(hide)
{
   var configArea = document.getElementById("pxn8_config_area");
   configArea.style.display = "block";
}
var gActivePanel = '';

function hidePanel()
{
    collapse(document.getElementById('branch_'+gActivePanel),'leaf_' + gActivePanel);
}

function showPanel()
{
    expand(document.getElementById('branch_' + gActivePanel),'leaf_' + gActivePanel);
}
/*
 * expanding and collapsing list elements
 */
function collapse(branchElt, leafId)
{
    var leafElt = document.getElementById(leafId);
    if (leafElt == null){
	     return;
    }
    branchElt.onclick = function(event){
        expand(branchElt,leafId);
    };
    branchElt.className = "collapsed";
    leafElt.style.display = "none";
}
function expand(branchElt, leafId)
{

    var leafElt = document.getElementById(leafId);
    if (leafElt == null){
	    return;
    }
    branchElt.onclick = function(event){
        collapse(branchElt,leafId);
    };
    branchElt.className = "expanded";
    leafElt.style.display = "block";
}

function showPanelHideConfig()
{
	showPanel();
   var toolPalette = document.getElementById("pxn8_config_area");
	toolPalette.style.display = "none";
}
/**
 * If you write a new tool that requires parameters then call this function.
 * otherwise, call the tool function directly.
 *
 */
function configureTool (func, element, event)
{
    if (!event) event = window.event; /* IE */
    PXN8.tooltip.hide(element);
    hidePanel();
    var toolPalette = document.getElementById("pxn8_config_area");
    toolPalette.style.display = "block";
    func(element,event);
}

PXN8.listener.add(PXN8.ON_IMAGE_CHANGE,showPanelHideConfig);

--></script>

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


<div class="toolbar">
<table cellpadding="0" cellspacing="0" style="margin-top: 4px;">
<tr>
  <td valign="top" width="128px" >
     <!-- THIS IS WHERE THE DEFAULT PXN8 LOGO GOES -->
     <img src="images/smallbanner3.jpg" border="0"/>
  </td>
  <td valign="top"><table cellpadding="0" cellspacing="0">

     <tr>
        <td valign="top"  colspan="2"><input style="width: 350px;" class="pxn8_has_tooltip"
                          class="file_location" type="text" name="imageUrl" 
                          id="imageUrl"  value="<%=image%>" 
/></td>

        <td valign="center"><a title="Fetch photo from the web" href="javascript:void(0)" 
            onclick="loadImageFromField();return false;" 
            onmouseout="PXN8.tooltip.hide(this,'imageUrl');" 
            onmouseover="PXN8.tooltip.show(this,'imageUrl');" ><img alt="Fetch photo from the web" src="images/fetch.gif" border="0"/></a></td>

     </tr>

     <tr>
        <td>selection:<span id="pxn8_selection_size">&nbsp;</span></td>

        <td valign="top" align="right">
<form action="/pixenate/upload.pl" method="POST" 
      enctype="multipart/form-data"
      onsubmit="return submit_upload_form(this);">

<input type="hidden" name="pxn8_root" value="/pixenate"/>
<input type="hidden" name="next_page" value="/pixenate/themes/default/index.asp"/>
<input type="hidden" name="image_param_name" value="image" />

<input class="pxn8_has_tooltip" type="file" name="filename" id="filename" 
        style="border:none; margin: 0px; padding:0px; line-height: 10px; font-size:9px;"></td>

        <td valign="top"><input 
                          onmouseover="PXN8.tooltip.show(this,'filename');" 
                          onmouseout="PXN8.tooltip.hide(this,'filename');" 
                          type="image" alt="Upload photo from your computer" name="submit" border="0" src="images/upload.gif" /></td>
       </form>
     </tr>

     <tr>
         <td valign="top" colspan="3"><table width="100%" cellspacing="0" cellpaddding="0">

            <tr>

              <td width="20%">size:<span id="pxn8_image_size"></span></td>

              <td width="20%">zoom:<span id="pxn8_zoom">&nbsp;</span></td>

              <td width="30%">position:<span id="pxn8_mouse_pos">&nbsp;</span></td>

            </tr>

           </table>
         </td>
      </tr>

    </table>
  </td>
  <!--td valign="top"><textarea 
     style="border: none; margin: 0px; margin-bottom: 8px; width: 100%; height: 54px; display: block; overflow: auto; padding-left: 6px; font-size:10px; line-height: 12px; margin-left: 4px;" 
     cols="80" rows="3" name="recording" id="recording">---------------------------------------------------------------------------------</textarea></td-->

  <td valign="top"><div style="background-color: #efefef; height: 58px; font-size: 110%; padding-left: 6px; overflow: auto;">
    <p>&copy; 2005 <a href="http://www.sxoop.com/">Sxoop Technologies Ltd</a>. All rights reserved.</p>
    <p>PXN8 is available for purchase to install on your own
    servers. For details and pricing, email <a href="mailto:sales@sxoop.com?subject=PXN8 Information Request">sales@sxoop.com</a>.</p>
    <p>PXN8 is a pure HTML/CSS/Javascript browser-based photo editor
    that doesn't require any plug-ins (like Flash or Java) so it can be
    easily themed to suit your business identity.</p>
    </div></td>
  
</tr>
</table>
</div><!-- end of toolbar -->

<script type="text/javascript" language="Javascript">


</script>


<div class="palette">

<div id="panel_faq" class="panel">
  <ul>
    <li class="collapsed" onclick="expand(this,'leaf_faq');return false;">Help</li>
    <li id="leaf_faq" style="display: none;">
      <ul>
        <li class="collapsed" onclick="expand(this,'leaf_answer1');">How do I download PXN8 ?</li>
        <li id="leaf_answer1" class="faq_answer" style="display: none;">PXN8 is an <em>online</em> image editing tool. 
           This means there is no software to download. You can edit photos without installing software on your PC.</li>


      <li  class="collapsed" onclick="expand(this,'leaf_answer2');">How do I edit photos on my hard-disk or memory card ?</li>
      <li id="leaf_answer2" class="faq_answer" style="display:  none;">&nbsp;
         <ol>
           <li>Click the 'Browse...' button near the top of the page and a file chooser dialog will appear.</li> 
           <li>Using the file chooser dialog, choose the photo you wish to edit and click 'OK' or 'Open'.</li> 
           <li>Now click 'Upload' next to the 'Browse...' button and in a short time the photo
               should appear on the page ready for editing.</li>
         </ol> 
         <p>There is a size limit of 1024 Kilobytes on uploaded files.</p>
      </li>



      <li class="collapsed" onclick="expand(this,'leaf_answer3');">How do I edit my <a href="http://www.flickr.com/">flickr</a> photos ?</li>
      <li id="leaf_answer3" class="faq_answer" style="display: none;">You can
        edit images from within flickr using this bookmarklet...<p/>
<a class="bookmarklet" title="Import to PXN8"
onclick="alert('You must first drag and drop this link onto the browser\'s links toolbar.\n' +
               '(Internet Explorer users: right click and select \'Add to Favourites\'; Create in \'Links\')\n'+
               'To use this bookmarklet, Visit a web page with images and click the \'Import to PXN8\' button in your browser\'s toolbar');return false;" 
href="javascript:try{void(d=document);void(h=d.getElementsByTagName('head')[0]);void((s=d.createElement('script')).setAttribute('src','http://pxn8.com/bookmarklet.js'));void(h.appendChild(s));}catch(e){void(window.location.href='http://pxn8.com/index.pl?image='+escape(window.location.href));}">Import to PXN8</a>

Drag and drop the bookmarklet onto your browser's <b>Links</b> toolbar. Now when you're viewing a web page with photos, you can edit any photo by clicking
    the 'Import to PXN8' button in your 'Links' toolbar.    

      </li>



      <li class="collapsed" onclick="expand(this,'leaf_answer4');">How do I edit photos which are already online ?</li>
      <li id="leaf_answer4" class="faq_answer" style="display: none;">You can
edit online photos by 2 methods...<p/>
      <ol>
       <li>If you already know the URL (address) of the photo, type it into the URL field near the top of the page (to the left of the 'Fetch' button).</li>
       <li>You can use the following bookmarklet to edit a photo (Make sure
you right-click on the photo and choose 'View Image' first)...<p/>
<a class="bookmarklet" title="Import to PXN8"
onclick="alert('You must first drag and drop this link onto the browser\'s links toolbar.\n' +
               '(Internet Explorer users: right click and select \'Add to Favourites\'; Create in \'Links\')\n'+
               'To use this bookmarklet, Visit a web page with images and click the \'Import to PXN8\' button in your browser\'s toolbar');return false;" 
href="javascript:try{void(d=document);void(h=d.getElementsByTagName('head')[0]);void((s=d.createElement('script')).setAttribute('src','http://pxn8.com/bookmarklet.js'));void(h.appendChild(s));}catch(e){void(window.location.href='http://pxn8.com/index.pl?image='+escape(window.location.href));}">Import to PXN8</a>

Drag and drop the bookmarklet onto your browser's <b>Links</b> toolbar. Now when you're viewing a web page with photos, you can edit any photo by clicking
    the 'Import to PXN8' button in your 'Links' toolbar.    
</li>
      </ol>
      </li>


      <li class="collapsed"
      onclick="expand(this,'leaf_answer5');">Which browsers and Operating Systems   are supported ?</li>
      <li id="leaf_answer5" class="faq_answer" style="display: none;">
      PXN8 works on Windows, Linux and Mac OS X. Supported browsers:
      Internet Explorer 6.0, Firefox and Safari.
      </li>

        <li class="collapsed" onclick="expand(this,'leaf_answer6');">Contact details...</li>
        <li id="leaf_answer6" class="faq_answer" style="display: none;">
       General Enquiries: <br/>
         <a href="mailto:info@sxoop.com">info@sxoop.com</a><br/>
       Problems / Bugs: <br/>
         <a href="mailto:support@sxoop.com">support@sxoop.com</a><br/>
       Licensing: <br/>
         <a href="mailto:sales@sxoop.com">sales@sxoop.com</a><br/>
        </li>
      </ul>
    </li>
  </ul>
</div><!-- end faq  -->



<div id="panel_tools" class="panel">
<ul>
<li id="branch_tools" class="expanded" onclick="collapse(this,'leaf_tools');">Tools</li>
<li id="leaf_tools" style="display:block;"><table>
<tr>
   <!-- save to disk -->
   <td><a id="save" class="pxn8_has_tooltip"
       href="javascript:PXN8.save.toDisk();"><img
       title="" alt=""
       src="../shared/images/save.gif" border="0"></a></td>   

   <!-- save to flickr -->
   <td><form action="/flickrLogin.pl" method="POST" onsubmit="return PXN8.save.toFlickr(this);"><input 
       type="image" src="../shared/images/flickrsave.gif" border="0" name="submit" 
       id="flickrsave" class="pxn8_has_tooltip"
       alt="Save this photo to your Flickr photostream"/></form></td>

   <!-- undo -->
   <td class="_48"><a id="undo" class="pxn8_has_tooltip"
                href="javascript:void(0)"
   onclick="PXN8.tooltip.hide(this);PXN8.tools.undo();return false;"><img 
          src="../shared/images/undo.gif" border="0" 
          alt="" title=""/></a></td>
   <!-- redo -->
   <td class="_48"><a id="redo" href="javascript:void(0)" class="pxn8_has_tooltip"
           onclick="PXN8.tooltip.hide(this);PXN8.tools.redo(); return false;"><img 
          src="../shared/images/redo.gif" border="0" 
          alt="" title=""/></a></td>

</tr>

<tr>
   <!-- select all -->
   <td class="_48"><a id="selectall" class="pxn8_has_tooltip"  href="javascript:void(0)"
       onclick="PXN8.tooltip.hide(this);PXN8.selectAll();return false;"><img 
       title="" alt="" src="../shared/images/select_all.gif" border="0"></a></td>

   <!-- select none -->
   <td class="_48"><a id="selectnone" href="javascript:void(0)" class="pxn8_has_tooltip"
                   onclick="PXN8.tooltip.hide(this);PXN8.unselect(); return false;"><img 
       title="" alt="" src="../shared/images/select_none.gif" border="0"></a></td>

   <!-- zoom in -->
   <td class="_48"><a id="zoomin" href="javascript:void(0)"
   class="pxn8_has_tooltip" onclick="PXN8.tooltip.hide(this);PXN8.zoom.zoomIn();"><img
       title="" alt="" src="../shared/images/zoomplus.gif" border="0"></a></td>


   <!-- zoom out -->
   <td class="_48"><a id="zoomout" href="javascript:void(0)" class="pxn8_has_tooltip"
      onclick="PXN8.tooltip.hide(this);PXN8.zoom.zoomOut();"><img
       title="" alt=""
       src="../shared/images/zoomminus.gif" border="0"></a></td>


</tr>



<tr>
   <!-- crop -->
   <td class="_48"><a id="crop" href="javascript:void(0)" class="pxn8_has_tooltip"
   onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_crop,this,event); return false;"><img 
       title="" alt="" src="../shared/images/crop.gif" border="0"/></a></td>

   <!-- rotate -->
   <td class="_48"><a id="rotate" class="pxn8_has_tooltip" href="javascript:void(0)"
   onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_rotate,this,event);return false;"><img 
       title="" alt="" src="../shared/images/rotate.gif" border="0"/></a></td>

   <!-- spiritlevel -->
   <td class="_48"><a id="spiritlevel" href="javascript:void(0)" class="pxn8_has_tooltip"
   onclick="gActivePanel='tools';configureTool(spiritlevelmode,this,event);return false;"><img 
       title="" alt="" src="../shared/images/spiritlevel.gif" border="0"/></a></td>

   <td class="_48"><a id="resize" href="javascript:void(0)" class="pxn8_has_tooltip"
       onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_resize,this,event);return false;"><img 
       title="" alt="" src="../shared/images/resize.gif" border="0"/></a></td>

</tr>

<tr>
   <!-- brightness, hue & saturation -->
   <td class="_48"><a id="bsh" class="pxn8_has_tooltip"  href="javascript:void(0)" onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_bsh,this,event);return false;"><img 
       title="" alt="" src="../shared/images/bsh.gif" border="0"/></a></td>
   <td class="_48"><a id="redeye" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_redeye,this,event);return false;"><img 
       title="" alt="" src="../shared/images/redeye.gif" border="0"></a></td>
   <!-- whiten teeth -->
   <td class="_48"><a id="whiten" class="pxn8_has_tooltip"
      href="javascript:void(0)" onclick="PXN8.tooltip.hide(this);PXN8.tools.ui.whiten();return false;"><img 
       title="" alt="" src="../shared/images/whiten.gif" border="0"/></a></td>


   <!-- sepia -->
   <td><a id="sepia" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="gActivePanel='tools';configureTool(PXN8.tools.ui.config_sepia,this,event);return false;"><img 
       title="" alt="" src="../shared/images/sepia.gif" border="0"/></a></td>

</tr>
</table>
</li>
</ul>
</div>


<div id="panel_toys" class="panel">
<ul>
<li id="branch_toys" class="collapsed" onclick="expand(this,'leaf_toys');">Toys</li>
<li id="leaf_toys" style="display:none;"><table>
<tr>
   <!-- lomo -->
   <td class="_48"><a id="lomo" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="gActivePanel='toys';configureTool(PXN8.tools.ui.config_lomo,this,event);return false;"><img 
       title="" alt="" src="../shared/images/lomo.gif" border="0"/></a></td>

   <!-- filter -->
   <td class="_48"><a id="filter" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="gActivePanel='toys';configureTool(PXN8.tools.ui.config_filter,this,event);return false;"><img 
       title="" alt="" src="../shared/images/filter.gif" border="0"/></a></td>


   <!-- add rounded corner -->
   <td class="_48"><a id="roundedcorners" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="gActivePanel='toys';configureTool(PXN8.tools.ui.config_roundedcorners,this,event);return false;"><img src="../shared/images/round_corners.gif" border="0" 
          alt="" title=""/></a></td>

   <td class="_48"><a id="interlace" class="pxn8_has_tooltip" href="javascript:void(0)" onclick="configureTool(PXN8.tools.ui.config_interlace,this,event);return false;"><img 
          src="../shared/images/interlace.gif" border="0" 
          alt="" title=""/></a></td>

</tr>

<tr>
   <td class="_48"><a id="blur" class="pxn8_has_tooltip"
       href="javascript:void(0)" onclick="gActivePanel='toys';configureTool(PXN8.tools.ui.config_blur,this,event);return false;"><img 
          src="../shared/images/blur.gif" border="0" 
          alt="" title=""/></a></td>
   <td class="_48"><a id="snow" class="pxn8_has_tooltip"
      href="javascript:void(0)" onclick="PXN8.tooltip.hide(this);PXN8.tools.snow();return false;"><img 
       title="" alt="" src="../shared/images/snow.gif" border="0"/></a></td>
   <td colspan="2">&nbsp;</td>
</tr>
</table>
</li>
</ul>
</div>



<div id="pxn8_config_area" class="panel" style="display: none;">
<span id="pxn8_config_title"></span>
<div id="pxn8_config_content"></div>
<div class="pxn8_config_buttons" align="right">
<a id="pxn8_cancel" style="" class="pxn8_button" href="javascript:void(0)" onclick="showPanelHideConfig();return false;" >Cancel</a>
<a id="pxn8_apply" style=""  class="pxn8_button" href="javascript:void(0)">Apply</a>
</div>
<div id="pxn8_tool_prompt">&nbsp;</div>
</div> <!-- config_area -->

<!--div class="panel"><p>&copy; 2005 <a
href="http://www.sxoop.com/">Sxoop Technologies Ltd</a>.</p>
<p>All rights reserved.</p></div-->

<div class="panel" style="">
  <ul>
    <li id="google_ads_node" class="expanded" onclick="collapse(this,'google_ads');">Advertising</li>
    <li id="google_ads" style="display: block; padding-top: 8px; padding-left: 12px;"> 
<script type="text/javascript"><!--
google_ad_client = "pub-6257674001240662";
google_ad_width = 160;
google_ad_height = 600;
google_ad_format = "160x600_as";
google_ad_type = "text_image";
google_ad_channel ="";
google_color_border = "E0E0E0";
google_color_bg = "EFEFEF";
google_color_link = "4682B4";
google_color_url = "800000";
google_color_text = "000000";
//--></script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
    </li>
</ul>
</div>


</div> <!-- palette -->

<!-- 
   Safari workaround: declare position inline for either the canvas or
   it's parent.
-->

<div style="position: absolute; top: 72px; left: 212px;" id="pxn8_canvas"></div>

<!-- #include file="../shared/tooltips.html"-->


</body>
</html>