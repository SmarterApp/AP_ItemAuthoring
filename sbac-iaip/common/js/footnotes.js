function showFootnote(id) {
	var f = document.getElementById(id);
	
	f.style.border = "1px solid #000000";
	f.style.backgroundColor = "#FFFFCC";
	
	f.style.width    = 250;
	f.style.padding  = 3;
	f.style.position = "absolute";
	
	var coords = getMousePos();
	var mouseX = coords[0];
	var mouseY = coords[1];
	                                    
	f.style.top      = mouseY + 5;
	if(mouseX < document.body.clientWidth/2)  f.style.left = mouseX + 5;
	else                                      f.style.left = mouseX - 250 - 5;
	f.style.display  = "block";
}

function hideFootnote(id) {
	var f = document.getElementById(id);
	f.style.display = "none";
}

function getMousePos() {
	var posx = 0;
	var posy = 0;
	if (!e) var e = window.event;
	if (e.pageX || e.pageY) 	{
		posx = e.pageX;
		posy = e.pageY;
	}
	else if (e.clientX || e.clientY) 	{
		posx = e.clientX + document.body.scrollLeft
			+ document.documentElement.scrollLeft;
		posy = e.clientY + document.body.scrollTop
			+ document.documentElement.scrollTop;
	}
	return Array(posx, posy);
}