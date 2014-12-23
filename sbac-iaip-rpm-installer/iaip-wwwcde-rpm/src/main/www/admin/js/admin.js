var client = { 'id' : '', 'branch' : '', 'num' : '' };
var building = false;
var URL = 'index.pl';
function doBuild( f, button ) {
        document.getElementById('msg_content').innerHTML = '';
	if(client['id'].match(/^\s*$/)) {
	    alert('Please select a Client!');
	    document.admin.client_list.focus();
	    return false;
	}
	if(client['branch'].match(/^\s*$/)) {
	    alert('Please select a Branch!');
	    document.admin.branch_list.focus();
	    return false;
	}
	var post_params = 'action=buildOutCDE&client_name=' + client['id'] +
			  '&branch_name=' + client['branch'] +
			  '&build_num='   + client['num'];
	if(! confirm('Are You Sure You Want To Build?') ) {
	    return false;
	}
	document.admin.build_btn.value = 'BUILDING!';
        document.getElementById('spinner_gif').style.display = 'block';
	building = true;
	clients[client['id']]['build_branch'] = client['branch'];
	clients[client['id']]['build_num']    = client['num'];
	clients[client['id']]['build_time']   = new Date();
	selectClient2(client['id'], '');
        ajaxpack.postAjaxRequest( URL, post_params, displayMsg, "txt" );
}

function createClient(f) {
	var post_params = setClientAttr(f);
	if(! post_params ) return false;
	post_params = 'action=modifyClient' + post_params;
        ajaxpack.postAjaxRequest( URL, post_params, displayMsg, "txt" );
}

function modifyClient(f) {
	var post_params = setClientAttr(f);
	post_params = 'action=modifyClient' + post_params;
        ajaxpack.postAjaxRequest( URL, post_params, displayMsg, "txt" );
}

function setClientAttr(f) {
	clients[f.short_name.value]['client_name'] = f.client_name.value;
        clients[f.short_name.value]['db_name']     = f.db_name.value;
        clients[f.short_name.value]['db_host']     = f.db_host.value;
        clients[f.short_name.value]['db_user']     = f.db_user.value;
        clients[f.short_name.value]['db_pass']     = f.db_pass.value;
        clients[f.short_name.value]['web_path']    = f.web_path.value;
        clients[f.short_name.value]['orca_url']    = f.orca_url.value;
        clients[f.short_name.value]['common_url']  = f.common_url.value;

	var post_params = '&client_name=' + f.client_name.value +
            		  '&short_name='  + f.short_name.value  +
            		  '&db_name=' 	  + f.db_name.value     +
            		  '&db_host=' 	  + f.db_host.value     +
            		  '&db_user=' 	  + f.db_user.value     +
            		  '&db_pass=' 	  + f.db_pass.value     +
            		  '&web_path=' 	  + f.web_path.value    +
            		  '&orca_url=' 	  + f.orca_url.value    +
            		  '&common_url='  + f.common_url.value;
	return post_params;
}

function doAction( f, button ) {
         f.action.value = button.name;
         f.submit();
         return true;
}
function doActionLink( f, action ) {
         f.action.value = action;
         f.submit();
         return true;
}
function selectClient(client_id, f) {
        if(client_id == '') {
            document.getElementById('anc_btn').style.display = 'none';
            document.getElementById('anc_ckb').style.display = 'none';
            document.getElementById('mc_btn').style.display  = 'none';
            f.reset();
            return;
        }
        if(client_id == 'anc') {
            document.getElementById('anc_btn').style.display = 'block';
            document.getElementById('anc_ckb').style.display = 'block';
            document.getElementById('mc_btn').style.display  = 'none';
            f.reset();
            f.client_list[f.client_list.length - 1].selected = true;
            f.short_name.disabled = false;
        }
        else {
            document.getElementById('anc_btn').style.display = 'none';
            document.getElementById('anc_ckb').style.display = 'none';
            document.getElementById('mc_btn').style.display  = 'block';

            f.client_name.value = clients[client_id]['client_name'];
            f.short_name.value  = clients[client_id]['short_name'];
            f.db_name.value     = clients[client_id]['db_name'];
            f.db_host.value     = clients[client_id]['db_host'];
            f.db_user.value     = clients[client_id]['db_user'];
            f.db_pass.value     = clients[client_id]['db_pass'];
            f.web_path.value    = clients[client_id]['web_path'];
            f.orca_url.value    = clients[client_id]['orca_url'];
            f.common_url.value  = clients[client_id]['common_url'];

            f.short_name.disabled = true;
        }
}
function selectClient2(client_id, f) {
        document.getElementById('msg_content').innerHTML = '';
        if(client_id == '') {
            document.getElementById('build_branch_lbl').innerHTML = '';
            document.getElementById('build_num_lbl').innerHTML    = '';
            document.getElementById('build_time_lbl').innerHTML   = '';
 	    client['id']     = '';
 	    client['branch'] = '';
 	    client['num']    = '';
            f.reset();
            return;
        }
	else {
            document.getElementById('build_branch_lbl').innerHTML = clients[client_id]['build_branch'];
            document.getElementById('build_num_lbl').innerHTML    = clients[client_id]['build_num'];
            document.getElementById('build_time_lbl').innerHTML   = clients[client_id]['build_time'];
 	    client['id'] = client_id;
	}
}
function setBranch(branch) {
 	 client['branch'] = branch;
         document.getElementById('msg_content').innerHTML = '';
}
function runTool( f, action ) {
        //document.getElementById('tool_title').innerHTML = tool_titles[action].title;
	var post_params = 'action=' + action;
        var URL = 'index.pl';
        ajaxpack.postAjaxRequest( URL, post_params, displayTool, "txt" );
}
function displayTool() {
	ajax = ajaxpack.ajaxobj;
        if ( ajax.readyState == 4 && ajax.status==200 ) {
            document.getElementById('tools_area').innerHTML = ajax.responseText;
        }
        else if ( ajax.status != 200 ) {
            document.getElementById('tools_area').innerHTML = 'Error retrieving tool : ' + ajax.status + '!';
        }
        else {
            document.getElementById('tools_area').innerHTML = 'Loading...';
        }
}
function displayMsg() {
	ajax = ajaxpack.ajaxobj;
        if ( ajax.readyState == 4 && ajax.status==200 ) {
            document.getElementById('msg_content').innerHTML = ajax.responseText;
        }
        else if ( ajax.status != 200 ) {
            document.getElementById('msg_content').innerHTML = 'Error : ' + ajax.status + '!';
        }
        else {
            document.getElementById('msg_content').innerHTML = 'Running...';
        }
	if(building) {
	    document.admin.build_btn.value = 'Build >>>';
            document.getElementById('spinner_gif').style.display = 'none';
	    building = false;
	}
}

function runReport( f, dbname ) {
        var post_params = 'action=displayUserReport&dbname=' + dbname;
        var URL = 'index.pl';
        ajaxpack.postAjaxRequest( URL, post_params, displayReport, "txt" );
}
function displayReport() {
        ajax = ajaxpack.ajaxobj;
        if ( ajax.readyState == 4 && ajax.status==200 ) {
            document.getElementById('report').innerHTML = ajax.responseText;
        }
        else if ( ajax.status != 200 ) {
            document.getElementById('report').innerHTML = 'Error Creating Report: ' + ajax.status + '!';
        }
        else {
            document.getElementById('report').innerHTML = 'Loading...';
        }
}

//Basic Ajax Routine- Author: Dynamic Drive (http://www.dynamicdrive.com)
//Last updated: Jan 15th, 06'

function createAjaxObj(){
var httprequest=false
if (window.XMLHttpRequest){ // if Mozilla, Safari etc
httprequest=new XMLHttpRequest()
if (httprequest.overrideMimeType)
httprequest.overrideMimeType('text/xml')
}
else if (window.ActiveXObject){ // if IE
try {
httprequest=new ActiveXObject("Msxml2.XMLHTTP");
} 
catch (e){
try{
httprequest=new ActiveXObject("Microsoft.XMLHTTP");
}
catch (e){}
}
}
return httprequest
}

var ajaxpack=new Object()
ajaxpack.basedomain="http://"+window.location.hostname
ajaxpack.ajaxobj=createAjaxObj()
ajaxpack.filetype="txt"
ajaxpack.addrandomnumber=0 //Set to 1 or 0. See documentation.

ajaxpack.getAjaxRequest=function(url, parameters, callbackfunc, filetype){
ajaxpack.ajaxobj=createAjaxObj() //recreate ajax object to defeat cache problem in IE
if (ajaxpack.addrandomnumber==1) //Further defeat caching problem in IE?
var parameters=parameters+"&ajaxcachebust="+new Date().getTime()
if (this.ajaxobj){
this.filetype=filetype
this.ajaxobj.onreadystatechange=callbackfunc
this.ajaxobj.open('GET', url+"?"+parameters, true)
this.ajaxobj.send(null)
}
}

ajaxpack.postAjaxRequest=function(url, parameters, callbackfunc, filetype){
ajaxpack.ajaxobj=createAjaxObj() //recreate ajax object to defeat cache problem in IE
if (this.ajaxobj){
this.filetype=filetype
this.ajaxobj.onreadystatechange = callbackfunc;
this.ajaxobj.open('POST', url, true);
this.ajaxobj.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
this.ajaxobj.setRequestHeader("Content-length", parameters.length);
this.ajaxobj.setRequestHeader("Connection", "close");
this.ajaxobj.send(parameters);
}
}

//ACCESSIBLE VARIABLES (for use within your callback functions):
//1) ajaxpack.ajaxobj //points to the current ajax object
//2) ajaxpack.filetype //The expected file type of the external file ("txt" or "xml")
//3) ajaxpack.basedomain //The root domain executing this ajax script, taking into account the possible "www" prefix.
//4) ajaxpack.addrandomnumber //Set to 0 or 1. When set to 1, a random number will be added to the end of the query string of GET requests to bust file caching of the external file in IE. See docs for more info.

//ACCESSIBLE FUNCTIONS:
//1) ajaxpack.getAjaxRequest(url, parameters, callbackfunc, filetype)
//2) ajaxpack.postAjaxRequest(url, parameters, callbackfunc, filetype)

///////////END OF ROUTINE HERE////////////////////////


//////EXAMPLE USAGE ////////////////////////////////////////////
/* Comment begins here

//Define call back function to process returned data
function processGetPost(){
var myajax=ajaxpack.ajaxobj
var myfiletype=ajaxpack.filetype
if (myajax.readyState == 4){ //if request of file completed
if (myajax.status==200 || window.location.href.indexOf("http")==-1){ if request was successful or running script locally
if (myfiletype=="txt")
alert(myajax.responseText)
else
alert(myajax.responseXML)
}
}
}

/////1) GET Example- alert contents of any file (regular text or xml file):

ajaxpack.getAjaxRequest("example.php", "", processGetPost, "txt")
ajaxpack.getAjaxRequest("example.php", "name=George&age=27", processGetPost, "txt")
ajaxpack.getAjaxRequest("examplexml.php", "name=George&age=27", processGetPost, "xml")
ajaxpack.getAjaxRequest(ajaxpack.basedomain+"/mydir/mylist.txt", "", processGetPost, "txt")

/////2) Post Example- Post some data to a PHP script for processing, then alert posted data:

//Define function to construct the desired parameters and their values to post via Ajax
function getPostParameters(){
var namevalue=document.getElementById("namediv").innerHTML //get name value from a DIV
var agevalue=document.getElementById("myform").agefield.value //get age value from a form field
var poststr = "name=" + encodeURI(namevalue) + "&age=" + encodeURI(agevalue)
return poststr
}

var poststr=getPostParameters()

ajaxpack.postAjaxRequest("example.php", poststr, processGetPost, "txt")
ajaxpack.postAjaxRequest("examplexml.php", poststr, processGetPost, "xml")

Comment Ends here */
