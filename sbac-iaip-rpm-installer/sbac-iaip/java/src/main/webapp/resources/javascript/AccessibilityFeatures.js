var featuresModified;
var Popup_Wind = new Array();

function modifyFeature() {
	if (featuresModified) {
		featuresModified();
	}
}

function deleteFeature() {
	if (confirm('This accessibility feature will be deleted. Continue?')) {
		modifyFeature(); 
		return true;
	} 
	return false;
}

function myOpen(name,url,id, w, h) {
	var info = document.getElementById(id);
	url = url + encodeURI(info.value);
	var myWin = window
			.open(
					url,
					name,
					'width='
							+ w
							+ ',height='
							+ h
							+ ',resizable=no,dialog=yes,minimizable=no,maximizable=no,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    myWin.focus();
    Popup_Wind[Popup_Wind.length] = myWin;
	return false;
}

function CloseChildWindow() {
    if (Popup_Wind.length != 0) {
        for (var i = 0; i < Popup_Wind.length; i++) {
            Popup_Wind[0].close();
        }
    } 
}