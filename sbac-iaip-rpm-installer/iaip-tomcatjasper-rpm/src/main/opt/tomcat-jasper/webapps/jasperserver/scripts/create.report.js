/*
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
 * http://www.jaspersoft.com.
 *
 * Unless you have purchased  a commercial license agreement from Jaspersoft,
 * the following license terms  apply:
 *
 * This program is free software: you can redistribute it and/or  modify
 * it under the terms of the GNU Affero General Public License  as
 * published by the Free Software Foundation, either version 3 of  the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero  General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public  License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Module for creating report from Adhoc Data View
 */
JRS.CreateReport = (function(jQuery) {
    var advSelDialog = null;

    //this module needs some scripts from PRO in order to run
    getDialog = function() {
        if(!advSelDialog) {
            advSelDialog = new JRS.RepositorySelectionDialog({
                treeFlowId: "adhocTreeFlow",
                treeProviderId: "adhocDataViewsTreeDataProvider",
                uriOnCancel: null, //no redirect
                selectionValidationMessage: JRS.CreateReport.messages.advNotSelected,
                organizationId: JRS.organizationId,
                publicFolderUri: JRS.publicFolderUri,
                okHandler: JRS.CreateReport.showGeneratedReport
            });
        }
        return advSelDialog;
    }

    return {
        /**
         * Redirects browser page that generates report from advUri Adhoc Data View and displays generated report
         * @param advUri
         */
        showGeneratedReport: function(advUri) {
            var form = jQuery("#reportGeneratorForm");
            form.find("input[name=advUri]").val(advUri);
            form.submit();
        },

        selectADV: function() {
            getDialog().open();
        }
    };
})(jQuery);

jQuery(function() {
    //make sure ajaxbuffer is available
    if(jQuery("#ajaxbuffer").length == 0) {
        jQuery("body").append(jQuery('<div id="ajaxbuffer" style="display:none"></div>'));
    }
})
