(function ($) {

    var firstRequest = true;

    var iframe = $("#exportFrame")[0];
    $("#exportButton").click(function () {
        firstRequest = false;
        iframe.src = "export/export/{filename}.zip"
            .replace("{filename}", $("#filenameId").val());
    });

    $(document).bind("global.ajaxPost", function (evt) {
        var result = $.parseJSON(evt.response);
        if (result) {
            $("#response").html(
                "<span style='background-color: green;font-weight: bold;'>Phase: {phase} Message: {message}</span>"
                    .replace("{phase}", evt.response.phase)
                    .replace("{message}", evt.response.message)
            );
        } else {
            $("#response").html("<span style='background-color: red;font-weight: bold;'>Failed uploading: Unrecognized response from the server.</span>");
        }
    });

    (function (iframe) {
        var event = new $.Event("global.ajaxPost");
        if (iframe.attachEvent) {
            iframe.attachEvent("onload", function () {
                event.response = iframe.contentWindow.document;
                //workaround for 'browser'
                !firstRequest && $(document).trigger(event)
            });
        } else {
            iframe.onload = function () {
                event.response = iframe.contentWindow.document;
                //workaround for FF
                !firstRequest && $(document).trigger(event);
            }
        }
    })(iframe);

})(jQuery);