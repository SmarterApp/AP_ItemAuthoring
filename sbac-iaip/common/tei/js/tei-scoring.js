var selectedAnswer = 1;
var scoringNames = [];

function addAnswer() {
	var table = document.getElementById('answersTable');
	var rows = table.rows;
	var answerNo = rows.length; 
	var row = table.insertRow(rows.length - 1);
	var cell1 = row.insertCell(0);
	cell1.innerHTML = "<div id='answer" + answerNo + 
	                  "' style='cursor: pointer' onclick='selectAnswer(" + answerNo + 
	                  ")'>Answer #" + answerNo + "</div>";
	var cell2 = row.insertCell(1);
	cell2.innerHTML = "<input id='deleteAnswer" + answerNo + "' type='button' value='X' onclick='deleteAnswer(" + answerNo + ");'>";
	if (answerNo == 1) {
		setDeleteButtonDisabled(1, true);
	} else {
		setDeleteButtonDisabled(answerNo - 1, true);
	}
	selectAnswer(answerNo);
}

function setDeleteButtonDisabled(answerNo, flag) {
	var deleteAnswerButton = document.getElementById('deleteAnswer' + answerNo);
	if (deleteAnswerButton) {
		deleteAnswerButton.disabled = flag; 
	}
}

function selectAnswer(answerNo) {
	for (var i = 1; ; i++) {
		var div = document.getElementById('answer' + i);
		if (div) {
			if (i == answerNo) {
				div.style.background = 'lightgray';
			} else {
				div.style.background = 'white';
			}
		} else {
			break;
		}
	}
	selectedAnswer = answerNo;
	setValues();
}

function setValuesByNames(names) {
	var div = document.getElementById('answer' + selectedAnswer);
	if (div) {
		if (div.scoringValues == undefined) {
			div.scoringValues = {};
			div.auxValues = {};
		}
		for (var i = 0; i < names.length; i++) {
			var field = document.getElementById(names[i]);
			if (field.tagName == 'SELECT') {
				var index = 0;
				for (var j = 0; j < field.options.length; j++) {
					if (div.scoringValues[names[i]] == field.options[j].text) {
						index = j;
						break;
					} 
				}
				field.selectedIndex = index;
			} else {
				document.getElementById(names[i]).value = div.scoringValues[names[i]] ? div.scoringValues[names[i]] : '';
			}
			if (document.getElementById(names[i] + '_Aux')) {
				document.getElementById(names[i] + '_Aux').value = div.auxValues[names[i]] ? div.auxValues[names[i]] : '';
			}
		}
	}
}

function setValues() {
	setValuesByNames(scoringNames);
}

function updateValues() {
	updateValuesByNames(scoringNames);
}

function updateValuesByNames(names) {
	var div = document.getElementById('answer' + selectedAnswer);
	if (div.scoringValues == undefined) {
		div.scoringValues = {};
		div.auxValues = {};
	}
	for (var i = 0; i < names.length; i++) {
		div.scoringValues[names[i]] = document.getElementById(names[i]).value;
		if (document.getElementById(names[i] + '_Aux')) {
			div.auxValues[names[i]] = document.getElementById(names[i] + '_Aux').value;
		}
	}
}

function clearAnswers() {
	var table = document.getElementById('answersTable');
	while (table.rows.length > 1) {
		table.deleteRow(0);
	}
}

function deleteAnswer(answerNo) {
	var table = document.getElementById('answersTable');
	table.deleteRow(answerNo - 1);
	if (answerNo > 2) {
		setDeleteButtonDisabled(answerNo - 1, false);
	}
	if (selectedAnswer == answerNo) {
		selectAnswer(1);
	}
}