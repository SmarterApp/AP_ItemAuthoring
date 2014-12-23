package com.pacificmetrics.orca.export.saaif;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;

import com.pacificmetrics.orca.ejb.AccessibilityPassageServices;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageMedia;
import com.pacificmetrics.orca.entities.PublicationStatus;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.saaif.metadata1.MetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType;
import com.pacificmetrics.saaif.passage1.AccessElementType;
import com.pacificmetrics.saaif.passage1.AccessibilityInfoType;
import com.pacificmetrics.saaif.passage1.ApipAccessibilityType;
import com.pacificmetrics.saaif.passage1.BrailleTextType;
import com.pacificmetrics.saaif.passage1.ContentLinkInfoType;
import com.pacificmetrics.saaif.passage1.DefinitionIdType;
import com.pacificmetrics.saaif.passage1.KeyWordTranslationType;
import com.pacificmetrics.saaif.passage1.ObjectFactory;
import com.pacificmetrics.saaif.passage1.PassageType;
import com.pacificmetrics.saaif.passage1.PassageattribType;
import com.pacificmetrics.saaif.passage1.PassageattriblistType;
import com.pacificmetrics.saaif.passage1.PassagecontentType;
import com.pacificmetrics.saaif.passage1.PassagereleaseType;
import com.pacificmetrics.saaif.passage1.ReadAloudType;
import com.pacificmetrics.saaif.passage1.RelatedElementInfoType;
import com.pacificmetrics.saaif.passage1.StemType;
import com.pacificmetrics.saaif.passage1.TitleType;

@Stateless
public class ORCA2SAAIFPassageWriter {

    private static final Logger LOGGER = Logger
            .getLogger(ORCA2SAAIFPassageWriter.class.getName());
    private static final ObjectFactory OBF = new ObjectFactory();

    @EJB
    private ContentMoveServices contentMoveService;

    @EJB
    private AccessibilityPassageServices accessibilityPassageServices;

    @EJB
    private ItemServices itemServices;

    public ORCA2SAAIFPassageWriter() {
    }

    public List<SAAIFItem> getPassage(Item item) {

        List<SAAIFItem> saaifItemList = new ArrayList<SAAIFItem>();
        List<Object[]> itemCharacterizations = contentMoveService
                .findItemCharacterization(item.getId());

        if (CollectionUtils.isNotEmpty(itemCharacterizations)) {
            for (Object[] ic : itemCharacterizations) {
                int type = Integer.parseInt(ic[1].toString());
                int objId = Integer.parseInt(ic[2].toString());
                if (type == ItemCharacterizationTypeConstants.PASSAGE) {
                    Passage passage = contentMoveService.findPassageById(objId);

                    SAAIFItem saaifPassage = new SAAIFItem();
                    saaifPassage.setId(Long.toString(passage.getId()));
                    saaifPassage.setBankKey(Integer.toString(passage
                            .getItemBankId()));

                    saaifPassage.setHref("stim-" + passage.getItemBankId()
                            + "-" + saaifPassage.getId() + ".xml");
                    saaifPassage.setHrefBase("Stim_" + saaifPassage.getId());
                    saaifPassage.setMetadataHrefBase("Stim_"
                            + saaifPassage.getId());
                    saaifPassage.setMetadataHref("stim-"
                            + passage.getItemBankId() + "-"
                            + saaifPassage.getId() + "_metadata.xml");

                    saaifPassage.setType(SAAIFPackageConstants.STIMULUS_FORMAT);

                    List<PassageMedia> passageMediaList = contentMoveService
                            .findPassageMediaByPassage(passage.getId());

                    // finding Passage asset
                    if (CollectionUtils.isNotEmpty(passageMediaList)) {
                        Map<String, String> assetMap = new HashMap<String, String>();
                        for (PassageMedia asset : passageMediaList) {
                            assetMap.put(
                                    asset.getSrvrFilename(),
                                    IMSItemUtil.getPassageMediaDirPath(
                                            passage.getItemBankId(),
                                            passage.getId())
                                            + File.separator
                                            + asset.getSrvrFilename());
                        }

                        File assetGraphicsFile = new File(
                                IMSItemUtil.getPassageImageDirPath(
                                        passage.getItemBankId(),
                                        passage.getId()));
                        for (File file : assetGraphicsFile.listFiles()) {
                            assetMap.put(file.getName(), file.getPath());
                        }
                        saaifPassage.setAssets(assetMap);
                    }

                    // item content
                    saaifPassage.setXmlContent(buildPassageXml(passage));

                    // metadata content
                    saaifPassage
                            .setMetadataXmlContent(buildPassageMetadataXml(passage));

                    saaifItemList.add(saaifPassage);
                }
            }
        }
        return saaifItemList;
    }

    private String buildPassageXml(Passage passage) {
        String xmlContent = null;

        PassagereleaseType passagerelease = OBF.createPassagereleaseType();
        passagerelease.setVersion("0");
        PassageType passageElement = OBF.createPassageType();

        passageElement.setId(Long.toString(passage.getId()));
        passageElement.setVersion("0");

        passageElement.setAttriblist(buildPassageAttributes(passage));
        passageElement.getContent().addAll(buildPassageContents(passage));

        passagerelease.setPassage(passageElement);

        xmlContent = JAXBUtil.mershallSBAIF(passagerelease,
                PassagereleaseType.class);

        return xmlContent;
    }

    private PassageattriblistType buildPassageAttributes(Passage passage) {
        PassageattriblistType psgAttListType = OBF
                .createPassageattriblistType();

        // id attribute
        PassageattribType psgIdAttribute = OBF.createPassageattribType();
        psgIdAttribute.setAttid(PassageAttribConstants.PASSAGE_ID);
        psgIdAttribute.setName(PassageAttribConstants.PASSAGE_ID_NAME);
        psgIdAttribute.setVal(Long.toString(passage.getId()));
        psgIdAttribute.setDesc("");
        psgAttListType.getAttrib().add(psgIdAttribute);

        // subject attribute
        PassageattribType psgSubjectAttribute = OBF.createPassageattribType();
        psgSubjectAttribute.setAttid(PassageAttribConstants.PASSAGE_SUBJECT);
        psgSubjectAttribute
                .setName(PassageAttribConstants.PASSAGE_SUBJECT_NAME);
        List<Object[]> contentAreaCharacterization = contentMoveService
                .findObjectCharacterizationByPassage(passage);
        for (Object[] oc : contentAreaCharacterization) {
            int characterization = Integer.parseInt(oc[2].toString());
            int objId = Integer.parseInt(oc[3].toString());
            if (characterization == ItemCharacterizationTypeConstants.CONTENT_AREA) {
                psgSubjectAttribute.setVal(contentMoveService.findContentArea(
                        objId).getName());
            }
        }
        psgSubjectAttribute.setDesc("");
        psgAttListType.getAttrib().add(psgSubjectAttribute);

        // description attribute
        PassageattribType psgDescAttribute = OBF.createPassageattribType();
        psgDescAttribute.setAttid(PassageAttribConstants.PASSAGE_DESC);
        psgDescAttribute.setName(PassageAttribConstants.PASSAGE_DESC_NAME);
        psgDescAttribute.setVal(passage.getName());
        psgDescAttribute.setDesc("");
        psgAttListType.getAttrib().add(psgDescAttribute);

        return psgAttListType;
    }

    private List<PassagecontentType> buildPassageContents(Passage passage) {
        List<PassagecontentType> contentTypes = new LinkedList<PassagecontentType>();

        PassagecontentType pct = new PassagecontentType();

        pct.setLanguage("ENU");
        pct.setVersion("0"); // TODO: Needs for clarification
        pct.setApprovedVersion("0"); // TODO: Version of Item

        TitleType title = new TitleType();
        title.setValue(passage.getName());
        pct.setTitle(title);
        // STEM ELEMENT
        StemType stpe = new StemType();

        String root = PropertyUtil.getProperty(PropertyUtil.WEB_DIR);

        try {
            File file = new File(
                    passage.getUrl().startsWith(root) ? passage.getUrl() : root
                            + passage.getUrl());

            String strFileContent = FileUtils.readFileToString(file);

            if (strFileContent != null && !strFileContent.isEmpty()) {
                strFileContent = "<![CDATA["
                        + FileUtil.modifiedSrcPath(strFileContent) + "]]>";
            }
            stpe.setValue(strFileContent);

            pct.setStem(stpe);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Exception " + e.getMessage(), e);
        }

        pct.setApipAccessibility(buildItemAccessibilityInfo(passage));

        contentTypes.add(pct);

        return contentTypes;
    }

    private ApipAccessibilityType buildItemAccessibilityInfo(Passage passage) {
        // ACCESSIBILITY ELEMENT
        ApipAccessibilityType apipAccessibility = new ApipAccessibilityType();
        AccessibilityInfoType accessibilityInfo = new AccessibilityInfoType();
        LOGGER.info("Searching for Accessibility Element");
        List<AccessibilityElement> accessElementList = accessibilityPassageServices
                .findAccessibilityElements(passage.getId());
        int count = 1;
        for (AccessibilityElement ae : accessElementList) {
            AccessElementType accessElement = new AccessElementType();

            accessElement.setIdentifier("ae" + count);
            ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
            contentLinkInfo.setType(SAAIFPackageConstants.CONTENT_LINK_TYPE
                    .get(ae.getContentLinkType()));
            // TODO: -- "ItsLinkIdentifierRef" needs clarification--
            contentLinkInfo.setItsLinkIdentifierRef("");
            contentLinkInfo.setObjectLink("");
            accessElement.setContentLinkInfo(contentLinkInfo);

            RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();
            List<String> featureType = new ArrayList<String>();
            for (AccessibilityFeature accessFeature : ae.getFeatureList()) {
                if (accessFeature.getType() == 3
                        && accessFeature.getFeature() == 3) { // Braille Text
                    BrailleTextType brailleText = new BrailleTextType();
                    brailleText.setBrailleTextString(accessFeature.getInfo());
                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());

                    relatedElementInfo.setBrailleText(brailleText);
                } else if (accessFeature.getType() == 1
                        && accessFeature.getFeature() == 2) { // Text Speech
                                                              // Pronunciation
                    ReadAloudType readAloud = new ReadAloudType();
                    readAloud.setTextToSpeechPronunciation(accessFeature
                            .getInfo());
                    readAloud
                            .setTextToSpeechPronunciationAlternate(accessFeature
                                    .getInfo());

                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());
                    relatedElementInfo.setReadAloud(readAloud);
                } else if (accessFeature.getType() == 1
                        && accessFeature.getFeature() == 1) { // Spoken Text
                    LOGGER.info("Spoken Text not available..");
                } else if (accessFeature.getType() == 4
                        && accessFeature.getFeature() == -1) { // Keyword
                                                               // Translation
                    KeyWordTranslationType kwtt = new KeyWordTranslationType();
                    DefinitionIdType dit = new DefinitionIdType();
                    dit.setLang(accessFeature.getLangCode());
                    dit.setTextString(accessFeature.getInfo());
                    LOGGER.info("Translation Glossary.."
                            + accessFeature.getInfo());
                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());
                    kwtt.setDefinitionId(dit);

                    relatedElementInfo.setKeyWordTranslation(kwtt);
                } else if (accessFeature.getType() == 5
                        && accessFeature.getFeature() == 5) { // Highlighting
                    LOGGER.info("Highlighting not available..");
                }
            }

            if (!featureType.contains("3#3")) { // To give a default BRAILLE
                                                // TEXT element into xml
                BrailleTextType brailleText = new BrailleTextType();
                brailleText.setBrailleTextString("");

                relatedElementInfo.setBrailleText(brailleText);
            }

            if (!featureType.contains("1#2")) { // To give a default BRAILLE
                                                // TEXT element into xml
                ReadAloudType readAloud = new ReadAloudType();
                readAloud.setTextToSpeechPronunciation("");
                readAloud.setTextToSpeechPronunciationAlternate("");

                relatedElementInfo.setReadAloud(readAloud);
            }

            accessElement.setRelatedElementInfo(relatedElementInfo);
            accessibilityInfo.getAccessElement().add(accessElement);
            count++;
        }

        if (accessElementList == null || accessElementList.isEmpty()) {
            AccessElementType accessElement = new AccessElementType();
            accessElement.setIdentifier("ae" + count);

            ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
            contentLinkInfo.setType(SAAIFPackageConstants.CONTENT_LINK_TYPE
                    .get(1));
            contentLinkInfo.setItsLinkIdentifierRef("");
            contentLinkInfo.setObjectLink("");
            accessElement.setContentLinkInfo(contentLinkInfo);

            RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();
            ReadAloudType readAloud = new ReadAloudType();
            readAloud.setTextToSpeechPronunciation("");
            relatedElementInfo.setReadAloud(readAloud);

            BrailleTextType brailleText = new BrailleTextType();
            relatedElementInfo.setBrailleText(brailleText);

            accessElement.setRelatedElementInfo(relatedElementInfo);
            accessibilityInfo.getAccessElement().add(accessElement);
        }

        apipAccessibility.setAccessibilityInfo(accessibilityInfo);

        return apipAccessibility;
    }

    private String buildPassageMetadataXml(Passage passage) {

        String xmlContent = null;
        com.pacificmetrics.saaif.metadata1.ObjectFactory mbof = new com.pacificmetrics.saaif.metadata1.ObjectFactory();
        MetadataType metadata = mbof.createMetadataType();
        SmarterAppMetadataType smd = mbof.createSmarterAppMetadataType();

        smd.setIdentifier(Long.toString(passage.getId()));
        smd.setVersion(Integer.toString(0));
        smd.setInteractionType("Stimulus");

        smd.getLanguage().add(
                SAAIFPackageConstants.LANGUAGE.get(passage.getLang()));
        smd.setSecurityStatus("Non-secure");

        List<Object[]> gradeCharacterization = contentMoveService
                .findObjectCharacterizationByPassage(passage);
        for (Object[] oc : gradeCharacterization) {
            int characterization = Integer.parseInt(oc[2].toString());
            int objId = Integer.parseInt(oc[3].toString());
            if (characterization == ItemCharacterizationTypeConstants.GRADE_LEVEL) {
                smd.setIntendedGrade(contentMoveService.findGrade(objId)
                        .getName());
            } else if (characterization == ItemCharacterizationTypeConstants.GRADE_SPAN_START) {
                smd.setMinimumGrade(contentMoveService.findGrade(objId)
                        .getName());
            } else if (characterization == ItemCharacterizationTypeConstants.GRADE_SPAN_END) {
                smd.setMaximumGrade(contentMoveService.findGrade(objId)
                        .getName());
            } else if (characterization == ItemCharacterizationTypeConstants.CONTENT_AREA) {
                smd.setSubject(contentMoveService.findContentArea(objId)
                        .getName());
            } else if (characterization == ItemCharacterizationTypeConstants.DOK) {
                smd.setDepthOfKnowledge(Integer.toString(objId));
            }
        }

        if (gradeCharacterization == null || gradeCharacterization.isEmpty()) {
            smd.setSubject("");
        }

        smd.setStimulusName(passage.getName());
        smd.setMaximumNumberOfPoints("NA");
        smd.setItemSpecFormat("SmarterApp");
        smd.getEvidenceStatement().add("");
        smd.setStimulusFormat("Standard");

        PublicationStatus publicationStatus = passage
                .getPassagePublicationStatus();
        if (publicationStatus != null) {
            smd.setStatus(publicationStatus.getName());
        }
        smd.setPresentationFormat("Text with graphics");

        metadata.setSmarterAppMetadata(smd);

        xmlContent = JAXBUtil.mershallSBAIF(metadata, MetadataType.class);

        return xmlContent;
    }
}
