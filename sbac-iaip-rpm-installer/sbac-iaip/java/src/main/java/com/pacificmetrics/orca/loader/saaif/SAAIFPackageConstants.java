package com.pacificmetrics.orca.loader.saaif;

import java.util.HashMap;
import java.util.Map;

public class SAAIFPackageConstants {

    private SAAIFPackageConstants() {
    }

    public static final String MANIFST_FILE_NAME = "imsmanifest.xml";
    public static final String ITEM_NAME_START = "Items";
    public static final String STIMULUS_NAME_START = "Stimuli";
    public static final String ITEM_TYPE = "imsqti_apipitem_xmlv2p2";
    public static final String ITEM_IMS_TYPE = "imsqti_apipitem_xmlv2p1";
    public static final String STIMULUS_TYPE = "imsqti_apipstimulus_xmlv2p2";
    public static final String METADATA_TYPE = "resourcemetadata/apipv1p0";
    public static final String CONTENT_TYPE = "associatedcontent/apip_xmlv1p0/learning-application-resource";
    public static final String TUTORIAL_FORMAT = "tut";
    public static final String WORDLIST_FORMAT = "wordList";
    public static final String WIT_FORMAT = "WIT";
    public static final String CONTENT_LANGUAGE_ENG = "ENU";
    public static final String STIMULUS_FORMAT = "Stimulus";
    public static final String ERROR_MISSING = "Missing resource";
    public static final String ERROR_VALIDATION = "Invalid xml format";
    public static final String II_NAME = "RESPONSE";

    public static final String IMS_IN_PROGRESS = "In Progress";

    public static final int LANGUAGE_ENG = 1;
    public static final int LANGUAGE_SPA = 2;

    public static final String I_XML_DATA = "<item> <question sequence=\"1\"></question> <prompt></prompt> <choice sequence=\"1\" value=\"A\"></choice> <choice sequence=\"2\" value=\"B\"></choice> <choice sequence=\"3\" value=\"C\"></choice> <choice sequence=\"4\" value=\"D\"></choice> </item>";

    public static final int DEFAULT_GENRE = 0;
    public static final int DEFAULT_PUBLICATION_STATUS = 0;
    public static final Map<Integer, String> ITEM_FORMAT = initializeItemFormatMap();
    public static final Map<Integer, String> CONTENT_LINK_TYPE = initializeContentLinkTypeMap();
    public static final Map<Integer, String> LANGUAGE = initializeLanguageMap();

    private static Map<Integer, String> initializeItemFormatMap() {
        Map<Integer, String> itemFormatMap = new HashMap<Integer, String>();
        itemFormatMap.put(1, "MC");
        itemFormatMap.put(2, "SA");
        itemFormatMap.put(3, "ER");
        return itemFormatMap;
    }

    private static Map<Integer, String> initializeContentLinkTypeMap() {
        Map<Integer, String> contentLinkTypeMap = new HashMap<Integer, String>();
        contentLinkTypeMap.put(1, "Text");
        contentLinkTypeMap.put(2, "Graphic");
        contentLinkTypeMap.put(3, "Equation");
        return contentLinkTypeMap;
    }

    private static Map<Integer, String> initializeLanguageMap() {
        Map<Integer, String> languageMap = new HashMap<Integer, String>();
        languageMap.put(1, "eng");
        languageMap.put(2, "spa");
        return languageMap;
    }
}
