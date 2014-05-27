var featuresModified;


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