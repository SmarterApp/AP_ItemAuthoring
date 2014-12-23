package com.pacificmetrics.orca.export.ims;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.IOUtils;
import org.w3.synthesis.Audio;
import org.w3.synthesis.Break;
import org.w3.synthesis.Emphasis;
import org.w3.synthesis.Mark;
import org.w3.synthesis.Prosody;
import org.w3.synthesis.SayAs;
import org.w3.synthesis.Sub;
import org.w3.synthesis.Voice;
import org.xml.sax.InputSource;

import com.pacificmetrics.ims.apip.qti.AccessElementType;
import com.pacificmetrics.ims.apip.qti.AccessibilityInfoType;
import com.pacificmetrics.ims.apip.qti.ApipAccessibility;
import com.pacificmetrics.ims.apip.qti.BrailleTextType;
import com.pacificmetrics.ims.apip.qti.ContentLinkInfoType;
import com.pacificmetrics.ims.apip.qti.DefinitionIdType;
import com.pacificmetrics.ims.apip.qti.EmptyPrimitiveTypeType;
import com.pacificmetrics.ims.apip.qti.KeyWordTranslationType;
import com.pacificmetrics.ims.apip.qti.LabelledStringType;
import com.pacificmetrics.ims.apip.qti.RelatedElementInfoType;
import com.pacificmetrics.ims.apip.qti.SpokenType;
import com.pacificmetrics.ims.qti.stimulus.AssessmentStimulus;
import com.pacificmetrics.ims.qti.stimulus.ObjectFactory;
import com.pacificmetrics.ims.qti.stimulus.StimulusBody;
import com.pacificmetrics.orca.ejb.AccessibilityPassageServices;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ObjectCharacterization;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageMedia;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.export.saaif.ORCA2SAAIFPassageWriter;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.HTMLUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.saaif.metadata1.MetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType;

@Stateless
public class ORCAToIMSPassageWriter {

    private static final Logger LOGGER = Logger
            .getLogger(ORCA2SAAIFPassageWriter.class.getName());
    private static final ObjectFactory OBF = new ObjectFactory();

    @EJB
    private ContentMoveServices contentMoveService;

    @EJB
    private AccessibilityPassageServices accessibilityPassageServices;

    @EJB
    private ItemServices itemServices;

    public ORCAToIMSPassageWriter() {
        // TODO Auto-generated constructor stub
    }

    public List<IMSItem> getPassage(Item item) {

        List<IMSItem> imsItemList = new ArrayList<IMSItem>();
        List<Object[]> itemCharacterizations = contentMoveService
                .findItemCharacterization(item.getId());
        if (CollectionUtils.isNotEmpty(itemCharacterizations)) {
            for (Object[] ic : itemCharacterizations) {
                int type = Integer.parseInt(ic[1].toString());
                int objId = Integer.parseInt(ic[2].toString());
                if (type == ItemCharacterizationTypeConstants.PASSAGE) {
                    Passage passage = contentMoveService.findPassageById(objId);

                    IMSItem imsPassage = new IMSItem();
                    imsPassage.setIdentifier(Long.toString(passage.getId()));

                    imsPassage.setHref("stim-" + passage.getItemBankId() + "-"
                            + imsPassage.getIdentifier() + ".xml");
                    imsPassage
                            .setHrefBase("Stim_" + imsPassage.getIdentifier());
                    imsPassage.setMetadataHrefBase("Stim_"
                            + imsPassage.getIdentifier());
                    imsPassage.setMetadataHref("stim-"
                            + passage.getItemBankId() + "-"
                            + imsPassage.getIdentifier() + "_metadata.xml");

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

                        imsPassage.setAssets(assetMap);
                    }

                    // item content
                    imsPassage.setXmlContent(buildPassageXml(passage));

                    // metadata content
                    imsPassage
                            .setMetadataXmlContent(buildPassageMetadataXml(passage));

                    imsItemList.add(imsPassage);
                }
            }
        }
        return imsItemList;
    }

    private String buildPassageMetadataXml(Passage passage) {
        String xmlContent = null;
        com.pacificmetrics.saaif.metadata1.ObjectFactory mbof = new com.pacificmetrics.saaif.metadata1.ObjectFactory();
        MetadataType metadata = mbof.createMetadataType();
        SmarterAppMetadataType smd = mbof.createSmarterAppMetadataType();

        smd.setIdentifier(Long.toString(passage.getId()));
        smd.setVersion(Integer.toString(0));
        smd.setInteractionType("Stimulus");
        User user = itemServices.getUserById(passage.getUserId());
        String authorName = user != null ? user.getUserName() : "";
        smd.getItemAuthorIdentifier().add(authorName);

        ObjectCharacterization contentAreaCharacterization = passage
                .getCharacterization(ItemCharacterizationTypeConstants.CONTENT_AREA);
        if (contentAreaCharacterization != null) {
            smd.setSubject(contentMoveService.findContentArea(
                    contentAreaCharacterization.getIntValue()).getName());

        }
        smd.getLastModifiedBy().add(authorName);
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
            }
        }

        smd.setSmarterAppItemDescriptor(passage.getName());
        smd.setMaximumNumberOfPoints("NA");
        smd.setItemSpecFormat("SmarterApp");
        smd.getEvidenceStatement().add("");
        smd.setStimulusFormat("Standard");

        smd.setStimulusGenre(contentMoveService.findGenreById(
                passage.getGenre()).getName());

        metadata.setSmarterAppMetadata(smd);

        xmlContent = JAXBUtil.mershall(metadata, MetadataType.class);

        return xmlContent;
    }

    private String buildPassageXml(Passage passage) {
        String xmlContent = null;
        Map<String, Object> idRefMap = new HashMap<String, Object>();

        AssessmentStimulus assessmentStimulus = OBF.createAssessmentStimulus();
        assessmentStimulus.setIdentifier(String.valueOf(passage.getId()));
        assessmentStimulus.setTitle(passage.getName());
        StimulusBody stimulusBody = OBF.createStimulusBody();
        stimulusBody.setId(Long.toString(passage.getId()));

        try {
            String root = PropertyUtil.getProperty(PropertyUtil.WEB_DIR);
            File file = new File(
                    passage.getUrl().startsWith(root) ? passage.getUrl() : root
                            + passage.getUrl());

            JAXBContext jaxbContext = JAXBContext.newInstance(
                    StimulusBody.class, org.w3.synthesis.ObjectFactory.class,
                    Sub.class, Voice.class, Audio.class, Emphasis.class,
                    SayAs.class, Break.class, Mark.class, Prosody.class);
            Unmarshaller jaxbUnmarshaller = jaxbContext.createUnmarshaller();
            InputStream is = new FileInputStream(file);
            String theString = IOUtils.toString(is, "UTF-8");

            theString = "<div xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtistimulus/imsqti_v2p2\">"
                    + HTMLUtil.sanitizeHtml(theString) + "</div>";

            InputSource isr = new InputSource();
            isr.setCharacterStream(new StringReader(theString));
            com.pacificmetrics.ims.qti.stimulus.Div div = new com.pacificmetrics.ims.qti.stimulus.Div();
            div = (com.pacificmetrics.ims.qti.stimulus.Div) jaxbUnmarshaller
                    .unmarshal(isr);
            idRefMap = IMSItemUtil.createIdRefMapForStimulus(div);
            stimulusBody.getMathsAndIncludesAndPres().add(div);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in building Passage xml: " + e.getMessage(), e);
        }

        assessmentStimulus.setStimulusBody(stimulusBody);
        assessmentStimulus.setApipAccessibility(buildItemAccessibilityInfo(
                passage, idRefMap));

        xmlContent = JAXBUtil.mershall(assessmentStimulus,
                AssessmentStimulus.class, org.w3.synthesis.ObjectFactory.class);

        return xmlContent;
    }

    private ApipAccessibility buildItemAccessibilityInfo(Passage passage,
            Map<String, Object> idRefMap) {
        ApipAccessibility apipAccessibility = new ApipAccessibility();
        AccessibilityInfoType accessibilityInfo = new AccessibilityInfoType();
        LOGGER.info("Searching for Accessibility Element");
        List<AccessibilityElement> accessElementList = accessibilityPassageServices
                .findAccessibilityElements(passage.getId());
        int count = 1;
        for (AccessibilityElement ae : accessElementList) {
            AccessElementType accessElement = new AccessElementType();
            accessElement.setIdentifier(ae.getName());

            ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
            contentLinkInfo.setApipLinkIdentifierRef(idRefMap.get(ae
                    .getContentName()));
            EmptyPrimitiveTypeType eptt = new EmptyPrimitiveTypeType();
            contentLinkInfo.setObjectLink(eptt);
            accessElement.getContentLinkInfos().add(contentLinkInfo);

            RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();
            List<String> featureType = new ArrayList<String>();
            int elementCount = 1;
            for (AccessibilityFeature accessFeature : ae.getFeatureList()) {
                if (accessFeature.getType() == 3
                        && accessFeature.getFeature() == 3) { // Braille Text
                    BrailleTextType brailleText = new BrailleTextType();
                    LabelledStringType lst = new LabelledStringType();
                    lst.setContentLinkIdentifier(ae.getContentName()
                            + elementCount);
                    lst.setValue(accessFeature.getInfo());
                    brailleText.setBrailleTextString(lst);

                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());

                    relatedElementInfo
                            .getSpokensAndBrailleTextsAndTactileFiles().add(
                                    brailleText);
                    elementCount++;
                } else if (accessFeature.getType() == 1
                        && accessFeature.getFeature() == 2) { // Text Speech
                                                              // Pronunciation
                    SpokenType spoken = new SpokenType();
                    LabelledStringType lst = new LabelledStringType();
                    lst.setContentLinkIdentifier(ae.getContentName()
                            + elementCount);
                    lst.setValue(accessFeature.getInfo());

                    spoken.setTextToSpeechPronunciation(lst);
                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());

                    relatedElementInfo
                            .getSpokensAndBrailleTextsAndTactileFiles().add(
                                    spoken);
                    elementCount++;
                } else if (accessFeature.getType() == 1
                        && accessFeature.getFeature() == 1) { // Spoken Text
                    SpokenType spoken = new SpokenType();
                    LabelledStringType lst = new LabelledStringType();
                    lst.setContentLinkIdentifier(ae.getContentName()
                            + elementCount);
                    lst.setValue(accessFeature.getInfo());

                    spoken.setTextToSpeechPronunciation(lst);
                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());

                    relatedElementInfo
                            .getSpokensAndBrailleTextsAndTactileFiles().add(
                                    spoken);
                    elementCount++;
                } else if (accessFeature.getType() == 4
                        && accessFeature.getFeature() == -1) { // Keyword
                                                               // Translation
                    KeyWordTranslationType kwtt = new KeyWordTranslationType();
                    DefinitionIdType dit = new DefinitionIdType();
                    LabelledStringType lst = new LabelledStringType();
                    lst.setContentLinkIdentifier(ae.getContentName()
                            + elementCount);
                    lst.setValue(accessFeature.getInfo());
                    dit.setLang(accessFeature.getLangCode());
                    dit.setTextString(lst);

                    featureType.add(accessFeature.getType() + "#"
                            + accessFeature.getFeature());
                    kwtt.getDefinitionIds().add(dit);

                    relatedElementInfo
                            .getSpokensAndBrailleTextsAndTactileFiles().add(
                                    kwtt);
                    elementCount++;
                } else if (accessFeature.getType() == 5
                        && accessFeature.getFeature() == 5) { // Highlighting
                    LOGGER.info("Highlighting not available..");
                }
            }

            if (!featureType.contains("3#3")) { // To give a default BRAILLE
                                                // TEXT element into xml
                BrailleTextType brailleText = new BrailleTextType();
                LabelledStringType lst = new LabelledStringType();
                lst.setContentLinkIdentifier(ae.getContentName() + elementCount);
                lst.setValue("");
                brailleText.setBrailleTextString(lst);

                relatedElementInfo.getSpokensAndBrailleTextsAndTactileFiles()
                        .add(brailleText);
            }

            if (!featureType.contains("1#2")) { // To give a default BRAILLE
                                                // TEXT element into xml
                SpokenType spoken = new SpokenType();
                LabelledStringType lst = new LabelledStringType();
                lst.setContentLinkIdentifier(ae.getContentName() + elementCount);
                lst.setValue("");

                spoken.setTextToSpeechPronunciation(lst);

                relatedElementInfo.getSpokensAndBrailleTextsAndTactileFiles()
                        .add(spoken);
            }

            accessElement.setRelatedElementInfo(relatedElementInfo);
            accessibilityInfo.getAccessElements().add(accessElement);
            count++;
        }

        if (accessElementList == null || accessElementList.isEmpty()) {
            AccessElementType accessElement = new AccessElementType();
            accessElement.setIdentifier("ae" + count);

            ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
            contentLinkInfo.setApipLinkIdentifierRef(idRefMap.get("div1"));
            EmptyPrimitiveTypeType eptt = new EmptyPrimitiveTypeType();
            contentLinkInfo.setObjectLink(eptt);
            accessElement.getContentLinkInfos().add(contentLinkInfo);

            RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();

            accessElement.setRelatedElementInfo(relatedElementInfo);
            accessibilityInfo.getAccessElements().add(accessElement);
        }

        apipAccessibility.setAccessibilityInfo(accessibilityInfo);
        return apipAccessibility;
    }
}
