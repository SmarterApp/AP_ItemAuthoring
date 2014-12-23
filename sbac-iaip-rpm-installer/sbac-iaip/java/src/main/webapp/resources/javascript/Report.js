window.onload = function() {
    var content = document.getElementById('reportContent').value;
    //alert('Content: ' + content);
    //document.getElementById('contentFrame').src = "data:text/html;charset=utf-8," + escape(content);
    //document.getElementById('contentFrame').height = document.body.height;
    $('#contentFrame').contents().find('html').html(content);
};