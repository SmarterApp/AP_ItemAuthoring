function playSound(filename) {
	var flash = document.getElementById('mplayer');
	flash.playSound(filename);
}

function stopSound() {
	var flash = document.getElementById('mplayer');
	flash.stopSound();
}

function stopStimSound() {
	//alert("stop sound");
	//var player = window.frames["content"].frames["stim"].document.getElementById('mplayer');
	var player = window.frames["stim"].document.getElementById('mplayer');
	player.stopSound();
}