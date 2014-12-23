var ie=document.all;
var nn6=document.getElementById&&!document.all;
var isdrag=false;
var x,y;
var dobj;

var draginterval;

//event handlers for dragging
document.onmousedown = selectmouse;
document.onmouseup   = new Function("isdrag=false");

function toggleVisible(obj_name)
{
	var obj     = document.getElementById(obj_name);
	var status  = obj.style.visibility;
	var display = '';

	if(status == "visible")
	{
		status = "hidden";
		display = "none";
	}
	else if(status == "hidden")
	{
		status = "visible";
		display = "block";
	}
	
	obj.style.visibility = status;
	obj.style.display   = display;
}

function showStimulus(obj_name)
{
	var obj     = document.getElementById(obj_name);
	
	obj.style.visibility = "visible";
	obj.style.display    = "block";
	
	var frame = document.getElementById("stim");
	frame.src = frame.default_src;
}

function hideStimulus(obj_name)
{
	var obj     = document.getElementById(obj_name);
	
	obj.style.visibility = "hidden";
	obj.style.display    = "none";
	
	var frame = document.getElementById("stim");
	frame.src = "blank.html";
}

function movemouse(e)
{
	var evt = nn6 ? e : event;
	var evt = nn6 ? e : event;
	
	if((evt.clientX <= 10)                      || 
	   (evt.clientY <= 10)                      ||
	   (evt.clientX >= parent.parent.width-20)  || 
	   (evt.clientY >= parent.parent.height-20)    ) {
		isdrag = false;
	} else if (isdrag) {
		dobj.style.left = tx + evt.clientX - x;
		dobj.style.top  = ty + evt.clientY - y;
				
		return false;
	}
}

function selectmouse(e)
{
	var fobj       = nn6 ? e.target : event.srcElement;
	var topelement = nn6 ? "HTML" : "BODY";
	while (fobj.tagName != topelement && fobj.className != "dragger")
	{
		fobj = nn6 ? fobj.parentNode : fobj.parentElement;
	}
	if (fobj.className=="dragger")
	{
		isdrag = true;
		dobj = document.getElementById(fobj.target);
		tx = parseInt(dobj.style.left+0);
		ty = parseInt(dobj.style.top+0);
		x = nn6 ? e.clientX : event.clientX;
		y = nn6 ? e.clientY : event.clientY;
		document.onmousemove=movemouse;
		
		return false;
	}
}
