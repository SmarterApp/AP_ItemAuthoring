
  

RealObjects


edit-on NG Release 3.1.3491
 Date 2013-04-19

Important

This software and support material is copyrighted, it may only be used with a legally acquired and fully paid license and in accordance with the edit-on NG Software License Agreement. By installing and using this software, you accept the terms and conditions of the RealObjects edit-on NG Software License Agreement. For details, see the license.txt file.

If you have not purchased a license, you are only allowed to test and evaluate this software to find out how it fits your requirements during the evaluation period which is determined by the "Evaluation Key". To request an "Evaluation Key", visit http://www.realobjects.com. You are not allowed to use this software with an "Evaluation Key" in a production environment. After expiration of the "Evaluation Period", you must permanently remove this software and its support material from your computers, including the Sentry Spelling-Checker Engine and dictionaries. You are not allowed to use the software at all without a license key.


To purchase an edit-on NG license, please visit our website at http://www.realobjects.com.


Folder Contents

/documentation


edit-on NG documentation (PDF and HTML-Format).

Please make sure to read the documentation!


/lib


Library directory, containing the files required for the integration of EONG.


/samples


Developer samples.


/license


Additional licensing and copyright information.


/extension


Extension for custom extension (such as a custom locale).


/tools


Password encryption tool that can be used to encrypt the password specified in the config.json for WebDAV connections.


Remark:


Please be sure that you unzip the complete directory structure. If you use WinZip activate the "Use Folder Names" option when unzipping.


Installation

Copy the edit-on NG folder (complete with all sub folders) to your web server.


Note: If IIS is used as web server it might be neccessary to:

* Rename the "bin" folder, as by default all "bin" folders are configured as "hiddensegment" in IIS, though requests to these folders will be blocked. Please make also sure to change the base url in setBaseURL() accordingly.
* Register json files as mimetype in IIS


Release Notes and Known Issues
* Make sure to read the documentation, which can be found in the /documentation directory.
* The API of edit-on NG is not directly compatible with existing integrations of edit-on Pro 5 or earlier.
* When running edit-on NG using Safari for Windows, a "java.net.MalformedURLException: no protocol:" exception is displayed in the Java Console when the applet has loaded or whenever a LiveConnect call is performed. This does not have any effect on the functionality of edit-on NG and is an issue that is not caused by the editor itself and can be replicated with Safari for Windows in combination with any other Java applet.


3.1.3491: First Feature Release of edit-on NG 3.1

Important
* If you are using JRE 1.7.0_21 or later are and using custom Java code (custom dialogs or custom actions), the JAR files your custom code is packaged in must now have the "Trusted-Library: true" attribute. For details please see http://docs.oracle.com/javase/6/docs/technotes/guides/jweb/mixed_code.html#trusted_library. 


New Features
* Added horizontal ruler, which allows to edit page and paragraph margins.
* Added a page properties dialog, which allows to edit page margins, size and orientation. Furthermore the headers and footers for the default, first, left and right page can be edited. * Added two new API methods to be used in conjunction with the editor for headers and footers:  - 

loadHeaderFooterPlaceholderStyleSheet: Load a style sheet which is used for controlling the display of placeholders inserted by the "header-footer editor"

 - 

setHeaderFooterEditorStyleURL: Sets an URL to load as a user agent style sheet in the header-footer editor edit-on NG instance. If the main document uses/loads styles affecting the header/footer section, these styles can also be loaded into the "header-footer editor" instance using this method.



* Added a "Paint Format Tool" which allows to copy the formatting applied to a specific section of text to another section in the document. This includes 3 new actions:  - copy-format
 - paste-format
 - format-painter

* Added Track Changes view modes (actions):  - Show final document (show-changes-final)
 - Show final document with deletion bubbles (show-changes-final-bubble)
 - Show original document (show-changes-original)
 - Show final document with insertion bubbles (show-changes-original-bubble)
 - Show changes mixed-inline (show-changes-mixed-inline)



Bug Fixes
* Overriding actions was not possible when omitting the property "actionPath". (#5104)
* The source view and style template panel icons were not displayed correctly if the zoom area was disabled (#5106)
* The height of the applet was calculated wrong if the status bar was disabled. (#5107)


Changes
* Renamed page-properties-dialog action to document-properties-dialog. Added new page-properties-dialog action.
* Added the "Trusted-Library" entry in the manifest of the jar files (eong.jar, libs.jar, customdlg.jar) to prevent mixed code warnings when executing JavaScript API calls.


3.0.3329: Fourth Maintenance Release of edit-on NG 3.0

Important
* Replaced the expired certificate in eong.jar with an updated certificate.
* Using the preload mechanism may cause a warning dialog to be displayed if Java 1.7.0_11 or newer is used. From this Java version on, this dialog is displayed for all unsigned applets.


Bug Fixes
* Tables causing named pages could get cut off. (#5043)
* Editing documents containing named pages could produce incorrect page breaks.


3.0.3289: Third Maintenance Release of edit-on NG 3.0

Bug Fixes
* Fixed versioning issue.


3.0.3285: Second Maintenance Release of edit-on NG 3.0

Bug Fixes
* When importing a document with one of the importLegacyDocument API methods, superfluous inline styles are no longer inserted into the document. (#5020) (Side effect of feature #4254: Support for pasting formatted content from Word)


Features
* Added configuration option to enable/disable pasting images as base64 for the importLegacyDocument methods. (#5021)


3.0.3275: First Maintenance Release of edit-on NG 3.0

Bug Fixes
* Additional element is no longer created when using "setParentElementByNameContent". (#4944)
* It is now possible to localize the "Inserted/Deleted" strings in comparison bubbles (L_BUBBLE_DELETION, L_BUBBLE_INSERTION) (#5013)
* The comparison-document-styles no longer override the comparison-bubble-styles. (#5012)


3.0.3236: First Release of edit-on NG 3.0

New Features
* Improved how the "object" element is displayed in the editor. In addition, it is now possible to configure how this element is displayed (see the "Object Formatter" section in the manual). (#4283)
* The editor can now be started in full screen mode (see the description of the method "startFullscreen" in the manual for details). (#4541)
* The author name and uid for annotations (and changes) can now be configured. (#4931)
* Added new "getCaretPosition" API method that returns a JSON string indicating the caret position. (#4461)
* Added new event handlers: "ONOBJECTSELECTED" and "ONCARETUPDATE". (#4461, #4243)
* Added new methods to manipulate the attributes of all selected rows / columns: (#4584)  - setSelectedColumnsCellAttributes
 - setSelectedRowsCellAttributes
 - getSelectedColumnsCellAttributes
 - getSelectedRowsCellAttributes

* It is now possible for the integrator to specify icons with different size for one action using the new attributes "iconURLTinyPanel", "iconURLSmallPanel", "iconURLMediumPanel", "iconURLLargePanel" in the actionmap extension file. (#4327)
* It is now possible to configure if custom actions should only be enabled when there is only a caret, only a selection, or both. (#4287)


New Features for VersioTrack

VersioTrack now supports Track Changes in addition to Document Comparison. Changes can be tracked in the document on a per-user basis and can be rejected and accepted individually or for the entire document. For details, please see the "VersioTrack (Track Changes)" sample and the Integration Manual. To order VersioTrack, please contact support@realobjects.com.


General Improvements
* Images can now be inserted as base 64 data URIs (can be enabled in config.json).
* Images with a relative path can now be pasted from Internet Explorer.
* Formatting is now preserved when copying & pasting content from Word. (#4254)
* Improved behavior when resizing cells in a table with column span.
* The editor now throws an error message to the Java console if the config.json is empty, or using the JavaScript logger if the uiconfig.json is empty.


Changes
* If a valid license key is used, the editor now runs on localhost or 127.0.0.1 without any restrictions.
* Reevaluated which user preferences should be stored. Certain dialogs and action states are saved in the user preferences (such as the state of certain toggle actions or dialog field values) and restored when the editor is reloaded. 

States are no longer saved for the following dialogs:
 - inserthyperlinkdialog
 - insertimagedialog
 - inserttabledialog
 - splitcelldialog
 - changecasedialog
 - insertobjectdialog (objectproperties)


States are now saved for the following actions:
 - toggle-show-marks
 - toggle-show-table-grid
 - toggle-show-container-grid
 - toggle-show-semantic-elements
 - toggle-auto-spellcheck
 - show-annotation-*

* Removed the "allowuserannotationattributes " configuration option.
* The "insert-annotation" action and "insertAnnotation" API method now only take the annotation text as argument and no longer accept additional arguments.
* Renamed the "setAnnotationUserAttributes" method to "setUserAttributes". The new method sets the author name and uid for annotation and changes.
* Renamed "jquery-1.4.min.js" to "jquery.min.js".
* Updated jquery (1.8.0) and jquery-ui (1.8.23).


Bug Fixes
* Replacing block level elements (such as div) no longer causes empty elements under certain circumstances (#4880).
* Performing an insertion at the end of a table cell no longer places the caret in the next cell. (#4912)
* Read-only elements with "-ro-editable: false" and "-ro-editable-inside: true" are no longer incorrectly deleted when pressing backspace within the element. (#4867)
* It is now possible to place the caret below the text in cells with "vertical-align: top" if there is enough space below it. (#4907)
* Copying and pasting tables with table group elements now properly inserts a well-formed table instead of only inserting the table group elements with no surrounding table element. (#4976)
* The "getElementListAttributes" method now correctly only returns elements matching the expression within the current selection (if there is a selection). (#4961)
* Lists that are within a custom container are now properly imported using the "importLegacy" methods. (#4919)
* Symbols copied & pasted from Word are no longer surrounded by two span elements. (#4462)
* The thesaurus dictionary now is properly used by the languages it was configured for. (#4926)
* Content inside a table cell with a fixed width no loger overflows. (#4247)
* Copying and pasting an animated GIF no longer freezes the editor. (#4471)
* It is now possible to import documents with style rules that contain a style value that start with a value followed by an underscore (e.g. "mso-comment-reference:8_1"). (#4252)
* The document is now spellchecked again if the value of the "xml:lang" or "lang" attribute on the "html" element is modified. (#4925)
* The caret can now be set immediately before the first letter or immediately after the last letter of an annotation. (#4932)
* The autocorrect dialog is now properly localized. (#3927)
* The "getNumberOfWords" method now returns the correct value.
* Comparing documents containing entity references now no longer throws errors. (#4863)
* Resizing tables with a caption now functions as expected. (#4294)


2.1.2620.1: Third Maintenance Release of edit-on NG 2.0

Bug Fixes
* Solved endless loop issue when trying to use the "replace all" functionality of the "Find/Replace" dialog to replace content within a section with "editable: false".
* The libs.jar is now properly signed.


2.1.2620: Second Maintenance Release of edit-on NG 2.0


The new features include:

* Added new "requestFocus()" method to request the focus on the applet. Note: this is not supported on Mac OS X.
* Added support for QR Codes.


Changes
* Typing in a section with a symbol font (Symbol, WebDings, WingDings, WingDings 2 and WingDings 3) now translates typed characters into the appropriate range before they are inserted.
* The style "display: block" is now automatically added to the document for elements defined as container elements in the containerElements configuration when importing a document via "importLegacyDocument" or "importLegacyDocumentFromURL". 
* The "Fragment Language" drop-down menu now contains the "none" entry. Selecting this entry disables spell-checking for the selected fragment.
* Comparing two documents now always enables comparison mode, even if the documents are identical.


Bug Fixes
* The JavaScript paste event (ONPASTE) now properly escapes backslashes within pasted content.
* The getCurrentTableColumnCellAttributes and getCurrentTableRowCellAttributes API methods now return the attributes of the correct row respectively column if an entire row / column or multiple rows / columns are selected.
* The current format of inline content is now always preserved when it is copied and pasted.
* The editor no longer blocks if a PNG images with a relative path is dragged and dropped from an external source.
* Comparison styles are no longer overridden by user agent styles.
* Container elements defined in the "containerElements" configuration no longer are wrapped in a paragraph element when the document containing them is imported via "importLegacyDocument" or "importLegacyDocumentFromURL".
* It is now easier to see that editing in the in-place editing mode is disabled when a dialog is open.
* When trying to learn a word and no language is defined for the document or fragment, the spellchecker now adds it to the default language.
* Empty annotations can now be removed using the "Remove Annotation" button.


2.0.2142: First Maintenance Release of edit-on NG 2.0

Improvements
* Improved font mapping to support a larger range of characters for specific fonts.


2.0.2109: First Release of edit-on NG 2.0

New Features
* New User Interface features.

* Support for tool bar icons with text.
* Added a new icon size (tiny) which allows having 3 rows in a pane/subpanel.
* New structural element (subpanel) in the tool bar which allows to mix different icons sizes in one pane.
* Display the action's selected state in the context menu.
* Action icons are now displayed in the context menu.
* Added a "Page of Pages" counter for the status bar.
* Document/Fragment language area in the status bar to display and change the concerning language.
* Style Template Groups in Style Template Panel are now collapsible.
* Possibility to configure certain elements as "container elements".
* Added configuration option to influence the display of the style template panel on start of the editor.
* Added new API methods that support XPath:

* Select all elements matching the XPath expression.
* Move the caret to the first element matching the XPath expression
* Retrieve / modify the attributes of all elements matching the XPath expression.
* Automatic conversion of (local/file) image URLs to data URIs.
* Added event handler to influence what is pasted into the editor.
* Added a "getSelectionPlainText()" method.
* Added a symbol filter mechanism to ensure the correct display of document content having a symbol (Symbol, WingDings, ...) font-family style declaration.
* Added two new API methods "importLegacyDocument" and "importLegacyDocumentFromURL" to import legacy documents with filtering enabled.


VersioTrack Support

Added support for the VersioTrack module. VersioTrack enables you to compare documents in edit-on NG, display all changes in the compared documents and accept or reject changes. To order VersioTrack, please contact support@realobjects.com.


General Improvements
* Major tool bar design facelift.
* Support for empty bookmarks.
* Improved the "Insert Special Character" dialog. Now supports all Unicode blocks.


Changes
* New uiconfig stucture for subpanels. The old uiconfig structure has been deprecated. It is still possible to use this with edit-on NG 2.0, however you cannot mix new and deprecated uiconfig patterns in one pane.
* Deprecated method: "loadInplaceToolbarIcons". Use "loadCustomJavaIcons" instead. The new method is used to load custom icons for the in-place tool bar and the context menu.
* Deprecated the filter settings "officelist", "officestyledhtml" and "purehtml".


Bug Fixes
* Removed hyperlinks that had a class are still anchors.
* Attributes from elements could not be removed or set to empty.
* The "src" attribute of pasted images is missing.
* Opening a dialog via the context menu causes the applet to crash when using IE.
* Corrected element identification of aligned images followed by an empty tag (e.g. <br/>).
* Inserting aligned images with "setParentElementByNameContent" removes the parent element.
* Copy and paste from IE does not work with certain documents (containing <form> elements).
* Uneditable document when cleaning the source view document and switching to WYSIWYG.
* UserStyleSheets were removed when editing in the source view and switching back to WYSIWYG
* Creating a new paragraph is not possible inside a ro-editable: false and ro-editable-inside: true context.  - Note: Please have a look at the integration manual chapter III.2.2.15 for more information.

* Style template actions are not updated correctly if "enablestyletemplatepanel" is set to false.
* Documents containing regular lists are converted to illegal constructs if the the office list filter is enabled.
* Setting the iconRepository has no influence.
* Changed resolution to 96 DPI on all systems.


1.5.1823: First Release of edit-on NG 1.5

New Features
* Added API method to programmatically resize the editor.
* Attributes can now be removed using the setElementAttributes, setParentElementByNameAttributes, setBlockElementAttributes, setCurrentTableRowCellAttributes and setCurrentTableColumnCellAttributes methods.


General Improvements
* Added support for bookmarks using "name" attributes instead of "id".
* The editor now falls back to a default document when trying to load an empty document.


Performance Improvements
* Improved the reaction time when pressing action buttons across all browsers and specs. This should be especially noticeable on lower end systems, but should generally feel more responsive on all systems.
* Optimized dialog performance. Dialogs should now generally be displayed faster when they are opened.
* Optimized the color picker. The color picker is now more responsive and handles more smoothly on lower end systems, or using Internet Explorer.
* Toolbar drop downs are now displayed faster.


Changes
* The order of the arguments taken by the "insertImage" API method has changed. The arguments for this method now are "string src, string alt, string width, string height, string border" instead of "string src, string width, string height, string border, string alt". All arguments except "src" and "alt" now are optional and may be ignored or set to "null".
* The "insert-image" action now assumes "px" as unit for image width, height, or border width if no other unit is specified.
* The handling of base URLs was improved. In edit-on NG 1.0.1740, the handling of base URLs did not match the behavior described in the manual. The behavior was improved in general and its description was updated to match the changes. For methods that may accept a document base URL:  - If no document base URL is specified, use the URL of the document as base for resources.
 - If a document base URL is specified, use it instead.
 - If the document base URL is explicitly set to null, use the default base URL.
 - If the document base URL is disabled and no default base URL is specified, fall back to the code base.

* Deprecated the "setExtensionDirectoryURL" API method. Use  - setActionExtensionURL(string URL)
 - setDialogExtensionURL(string URL)
 - addLocaleExtensionURL(string localeCode, string localeURL)
instead. 
*  The JRE auto-download functionality default value is now false. 


Bug fixes
* Tooltips displayed in the context menu are now localized.
* Fixed NPE when inserting a hyperlink while multiple block elements are selected.
* Fixed a JavaScript error in Internet Explorer when "saveuistate" is set to false in the configuration file.
* Auto correction entries are now properly removed.
* The "Insert Table" dialog is now correctly displayed in Internet Explorer 7.
* Special characters are now properly encoded in annotations.
* Auto-hyperlinking at the start of a sentence is now possible.
* Fixed issue where the in-place toolbar was not hidden when clicking in the editor using Mac OS X with JRE 1.6.0u20.
* The "elementNames" filter in the actions configuration now no longer ignores element names other than the first.
* It is now possible to move the focus away from the editor in Safari 4.0.5 on Mac OS X.
* Using the shortcuts CTRL+1 through CTRL+6 in order to change the current paragraph to heading 1 through 6 no longer also inserts a character with the corresponding number on Mac OS X.
* The directory containing the edit-on NG files now can contain the string "edit-on-ng".
* The "insert-pagebreak" action now inserts a "div" element with appropriate inline styles instead of a "div" element with the class "pageBreak".
* Fixed exception when calling getCurrentTableColumnCellAttributes or getCurrentTableRowCellAttributes.
* The methods setCurrentTableColumnCellAttributes and setCurrentTableRowCellAttributes now accept the object returned by their getter counterparts (getCurrentTableColumnCellAttributes and getCurrentTableRowCellAttributes resp.) as argument.
* Unless otherwise stored in the user preferences, the first tab panel is now always displayed instead of the second when the editor is loaded.


Additional Notes

Selecting a single word via double-click or an entire block through a triple-click was previously not possible on Mac OS X machines due to missing events in that environment. This has been remedied by Apple in Mac OS 10.6 Update 3 and 10.5 Update 8.


1.0.1740: First Release of edit-on NG 1.0

System Requirements

Server Operating Systems Supported

All Server Operating Systems (Windows 2000/2003/2008, Linux, Solaris, BSD etc.) which support a HTTP capable server (e.g. Apache, IIS, Tomcat, Domino etc.) can be used. Files with the extension *.json and .js must be passed to the client "as-is" and must not be processed on the server.


Client Operating Systems Supported
* Microsoft Windows XP
* Microsoft Windows Vista
* Microsoft Windows 7
* Microsoft Windows 8
* Linux 2.x
* Apple Mac OS X 10.6+ (Safari only)
* Please make sure to install the latest service packs and updates.


Browsers Supported
* Microsoft Internet Explorer 7+
* Mozilla Firefox 15+
* Google Chrome 23+
* Apple Safari 6+


Required Java Runtime Environment
* Latest Oracle JRE 1.6.0 (latest Apple JRE 1.6.0 on Mac OS X 10.6)
* OR latest Oracle JRE 1.7.0 (1.7u7 or newer, JRE 7 before 1.7u7 will not work)


Important: To guarantee the best user experience, it is highly recommended to enable the next generation Java Plug-in (on OS X enable "Run applets: In their own process" in the Java Preferences). This requires Java 1.6.0_10 or newer. For details please see java.com/en/download/help/new_plugin.xml.


If the next generation Java Plug-in is enabled, the maximum memory available for the editor is increased to 256m by default. You can modify this value using the JavaScript API method setMaxMemory(mem).


Example: eong.setMaxMemory("512m");


To download the latest Java VMs for Windows, Linux, Solaris and OS X (Java 1.7 only) please visit: http://www.oracle.com/technetwork/java/javase/downloads/index.html


To download the latest Apple Java VM for Apple Mac OS X 10.6, please use the "Software Update" feature of the operating system.


Minimum Hardware Requirements
* 2 GHz Single Core or 1.5 GHz Dual Core CPU
* 1 GB RAM


In general, hardware requirements depend very much on the platform, the speed of the JVM implementation and the complexity of the documents which are edited.


Software Requirements for the Samples
* Webserver (Apache, IIS or other)


Notes:

* The samples will only run if the directory structure is unmodified.
* Your webserver should be configured to use index.htm as the default page.
* Navigate to http://yourserver/youreditondirectory/samples/index.htm to run the samples.


Support

For information about technical support please visit http://www.realobjects.com/support.


Additional Copyrights and other Important Notes
-----------------------------------------------


Please see the NOTICE.txt file in the /license subdirectory


Copyright (c) 2009-2013, RealObjects GmbH.

All rights reserved.


info@realobjects.com

http://www.realobjects.com
