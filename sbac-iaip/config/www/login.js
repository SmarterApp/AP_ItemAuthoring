function check() {
	if (document.loginForm.username.value == ""
			&& document.loginForm.password.value == "") {
		alert("Please enter your username and password and try again.");
		return false;
	}
	if (document.loginForm.username.value == "") {
		alert("Please enter your username and try again.");
		return false;
	}
	if (document.loginForm.password.value == "") {
		alert("Please enter your password and try again.");
		return false;
	} else {
		return true;
	}
}