var systemError = {
    initialize: function() {
        var nothingToDisplay = jQuery("#nothingToDisplay");
        nothingToDisplay.removeClass(layoutModule.HIDDEN_CLASS);
        centerElement(nothingToDisplay, {horz: true, vert: true});
    }
};

jQuery(document).ready(function() {
    systemError.initialize();
});