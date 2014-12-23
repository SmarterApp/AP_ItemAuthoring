package com.pacificmetrics.orca.loader.ims;

public class IMSPackageConstants {

    private IMSPackageConstants() {

    }

    public static final String DEFAULT_DIFFICULTY = "Easy";
    public static final String DEFAULT_LANG = "English";
    public static final String DEFAULT_PUBLICATION_STATUS = "Unused";
    public static final String DEFAULT_GENRE = "";

    public static final String MANIFST_FILE_NAME = "imsmanifest.xml";
    public static final String IMS_APIP_QTI_ITEM_TYPE_V2 = "imsqti_apipitem_xmlv2p2";
    public static final String IMS_APIP_QTI_ITEM_TYPE_V1 = "imsqti_apipitem_xmlv2p1";
    public static final String IMS_APIP_SECTION_TYPE = "imsqti_apipsection_xmlv2p2";
    public static final String IMS_APIP_STIMULUS_TYPE = "imsqti_apipstimulus_xmlv2p2";
    public static final String IMS_CONTROL_FILE_TYPE = "controlfile/apip_xmlv1p0";
    public static final String IMS_METADATA_TYPE = "resourcemetadata/apipv1p0";
    public static final String IMS_CONTENT_TYPE = "associatedcontent/apip_xmlv1p0/learning-application-resource";

    public static final Integer IMS_MANIFEST_TYPE = 1;
    public static final Integer IMS_ITEM_TYPE = 2;
    public static final Integer IMS_SECTION_TYPE = 3;
    public static final Integer IMS_STIMULUS_TYPE = 4;
    public static final Integer IMS_ITEM_METADATA_TYPE = 5;

    public static final String MANIFEST_XSD = "apipv1p0_imscpv1p2_v1p0.xsd";
    public static final String ITEM_XSD = "apipv1p0_qtiitemv2p2_v1p0.xsd";
    public static final String SECTION_XSD = "apipv1p0_qtisectionv2p2_v1p0.xsd";
    public static final String STIMULUS_XSD = "apipv1p0_qtistimulusv2p2_v1p0.xsd";
    public static final String METADATA_XSD = "apip_sbac_metadata.xsd";

    public static final String ERROR_MISSING_RESOURCES = "missing asset";
    public static final String ERROR_MISSING_ASSETS = "Missing resource";
    public static final String ERROR_INVALID_XML = "Invalid xml format";
    public static final String ERROR_UNIQUE_PASSAGE = "Passage name must be unique";
    public static final String ERROR_UNIQUE_ITEM = "Item already exists for the program:";
    public static final String ERROR_INVALID_METADATA = "Missing Metadata Element(s)";
    public static final String STIMULUS_FORMAT = "Stimulus";

}
