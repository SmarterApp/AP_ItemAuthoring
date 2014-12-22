document.onkeydown = keyListener; 

function keyListener(e){
   if(!e){
      //for IE
      e = window.event;
   }
   
   if(e.keyCode == 65){
	   acHandler("a");
   }
   if(e.keyCode == 66){
	   acHandler("b");
   }
   if(e.keyCode == 67){
	   acHandler("c");
   }
   if(e.keyCode == 68){
	   acHandler("d");
   }
}

function acHandler(ac) {
	var form = document.my_form;
	if(!form.radio) return;
	
	for (var i=0; i<form.radio.length; i++)
	{
		if(form.radio[i].value == ac)
			form.radio[i].checked = true;
		else
			form.radio[i].checked = false;
	}
}