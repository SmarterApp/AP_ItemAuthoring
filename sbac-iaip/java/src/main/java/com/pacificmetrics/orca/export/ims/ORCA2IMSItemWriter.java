package com.pacificmetrics.orca.export.ims;

import java.io.File;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.math.NumberUtils;
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
import com.pacificmetrics.ims.apip.qti.item.AssessmentItem;
import com.pacificmetrics.ims.apip.qti.item.ChoiceInteraction;
import com.pacificmetrics.ims.apip.qti.item.CorrectResponse;
import com.pacificmetrics.ims.apip.qti.item.DefaultValue;
import com.pacificmetrics.ims.apip.qti.item.Div;
import com.pacificmetrics.ims.apip.qti.item.ExtendedTextInteraction;
import com.pacificmetrics.ims.apip.qti.item.FeedbackBlock;
import com.pacificmetrics.ims.apip.qti.item.ItemBody;
import com.pacificmetrics.ims.apip.qti.item.ObjectFactory;
import com.pacificmetrics.ims.apip.qti.item.OutcomeDeclaration;
import com.pacificmetrics.ims.apip.qti.item.Prompt;
import com.pacificmetrics.ims.apip.qti.item.ResponseDeclaration;
import com.pacificmetrics.ims.apip.qti.item.SimpleChoice;
import com.pacificmetrics.ims.apip.qti.item.TextEntryInteraction;
import com.pacificmetrics.ims.apip.qti.item.Value;
import com.pacificmetrics.orca.ejb.AccessibilityItemServices;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.DevState;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAssetAttribute;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.entities.ItemFragment;
import com.pacificmetrics.orca.entities.ItemInteraction;
import com.pacificmetrics.orca.entities.ItemStandard;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PublicationStatus;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.orca.utils.SAAIFItemUtil;
import com.pacificmetrics.saaif.metadata1.MetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType.StandardPublication;

@Stateless
public class ORCA2IMSItemWriter {

    private static final Logger LOGGER = Logger
            .getLogger(ORCA2IMSItemWriter.class.getName());
    private static final ObjectFactory OBF = new ObjectFactory();

    @EJB
    private ContentMoveServices contentMoveService;

    @EJB
    private AccessibilityItemServices accessibilityItemServices;

    @EJB
    private ItemServices itemServices;

    @EJB
    private ORCAToIMSPassageWriter orcaToIMSPassageWriter;

    public IMSItem getItem(Item item) {

        IMSItem imsItem = new IMSItem();

        try {

            imsItem.setIdentifier(Long.toString(item.getId()));

            imsItem.setBankKey(Integer.toString(item.getItemBankId()));
            imsItem.setTitle(item.getDescription());
            imsItem.setHref("item-" + item.getItemBankId() + "-"
                    + imsItem.getIdentifier() + ".xml");
            imsItem.setHrefBase("Item_" + imsItem.getIdentifier());
            imsItem.setMetadataHrefBase("Item_" + imsItem.getIdentifier());
            imsItem.setMetadataHref("item-" + item.getItemBankId() + "-"
                    + imsItem.getIdentifier() + "_metadata.xml");

            /*
             * List<ContentAttachment> itemContentAttachmentList =
             * contentMoveService .findAttachmentsByItemId(item.getId());
             */

            List<ItemAssetAttribute> itemAssetAttributeList = contentMoveService
                    .findItemAssetsByItemId(item.getId());

            // Creating a blank attachments
            Map<String, String> attachmentMap = new HashMap<String, String>();

            imsItem.setAttachments(attachmentMap);

            // finding item asset
            if (CollectionUtils.isNotEmpty(itemAssetAttributeList)) {
                Map<String, String> assetMap = new HashMap<String, String>();
                for (ItemAssetAttribute asset : itemAssetAttributeList) {
                    assetMap.put(
                            asset.getFileName(),
                            IMSItemUtil.getItemImageDirPath(
                                    item.getItemBankId(), item.getExternalId())
                                    + File.separator + asset.getFileName());
                }
                imsItem.setAssets(assetMap);
            }

            // item content
            imsItem.setXmlContent(buildItemXml(item));

            // metadata content
            imsItem.setMetadataXmlContent(buildItemMetadataXml(item));

            imsItem.setPassages(orcaToIMSPassageWriter.getPassage(item));

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error building imsItem " + e.getMessage(), e);
        }
        return imsItem;

    }

    private String buildItemXml(Item item) {
        String xmlContent = null;
        Map<String, Object> idRefMap = new HashMap<String, Object>();

        AssessmentItem itemElement = OBF.createAssessmentItem();

        itemElement.setIdentifier(Long.toString(item.getId()));
        itemElement.setTitle(item.getDescription());
        itemElement.setAdaptive(false);
        itemElement.setTimeDependent(false);

        // Determine item format type

        ResponseDeclaration responseDeclaration = new ResponseDeclaration();
        responseDeclaration.setCardinality("multiple");
        responseDeclaration.setIdentifier("RESPONSE");
        responseDeclaration.setBaseType("string");
        itemElement.getResponseDeclarations().add(responseDeclaration);

        OutcomeDeclaration outcomeDeclaration = new OutcomeDeclaration();
        outcomeDeclaration.setIdentifier("SCORE");
        outcomeDeclaration.setCardinality("single");
        outcomeDeclaration.setBaseType("integer");

        DefaultValue defaultValue = new DefaultValue();
        Value value = new Value();
        value.setValue("0");
        defaultValue.getValues().add(value);
        outcomeDeclaration.setDefaultValue(defaultValue);

        ItemBody itemBody = new ItemBody();
        itemBody.setId("content1");

        // STEM ELEMENT
        String data = "";
        String dataToMakeRef = "";
        for (ItemFragment ifrag : item.getItemFragments()) {
            if (ifrag.getType() == ItemFragment.IF_STEM) {
                data += ifrag.getText();
            }
        }

        dataToMakeRef = data;
        try {
            data = "<div id=\"div1\" xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\">"
                    + FileUtil.modifiedSrcPath(data) + "</div>";
            JAXBContext jaxbContext = JAXBContext.newInstance(ItemBody.class,
                    org.w3.synthesis.ObjectFactory.class, Sub.class,
                    Voice.class, Audio.class, Emphasis.class, SayAs.class,
                    Break.class, Mark.class, Prosody.class);

            Unmarshaller jaxbUnmarshaller = jaxbContext.createUnmarshaller();
            InputSource is = new InputSource();
            is.setCharacterStream(new StringReader(data));
            Div div = new Div();
            div = (Div) jaxbUnmarshaller.unmarshal(is);

            itemBody.getRubricBlocksAndPositionObjectStagesAndCustomInteractions()
                    .add(div);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Exception " + e.getMessage(), e);
        }

        IMSInteractionInf intInf = null;
        String format = SAAIFItemUtil.getSBAIFItemFormatFromORCA(item
                .getItemInteractions());
        if ("MC".equalsIgnoreCase(format) || "MS".equalsIgnoreCase(format)) {
            ChoiceInteraction ci = new ChoiceInteraction();
            ci.setResponseIdentifier(SAAIFPackageConstants.II_NAME);
            intInf = ci;
        } else if ("ER".equalsIgnoreCase(format)) {
            ExtendedTextInteraction eti = new ExtendedTextInteraction();
            eti.setResponseIdentifier(SAAIFPackageConstants.II_NAME);
            intInf = eti;
        } else if ("SA".equalsIgnoreCase(format)) {
            TextEntryInteraction tei = new TextEntryInteraction();
            tei.setResponseIdentifier(SAAIFPackageConstants.II_NAME);
            intInf = tei;
        }

        for (ItemInteraction ii : item.getItemInteractions()) {
            if (ii.getName().equalsIgnoreCase(SAAIFPackageConstants.II_NAME)) {
                List<String> answerChoiceList = null;
                if (ii.getType() == 1) {
                    answerChoiceList = new ArrayList<String>(Arrays.asList(ii
                            .getCorrect() != null ? ii.getCorrect().split(" ")
                            : new String[] { "" }));
                } else {
                    answerChoiceList = new ArrayList<String>(Arrays.asList(ii
                            .getCorrect()));
                }
                CorrectResponse cr = new CorrectResponse();
                for (String string : answerChoiceList) {
                    Value val = new Value();
                    val.setValue(string);
                    cr.getValues().add(val);
                }
                responseDeclaration.setCorrectResponse(cr);

                StringTokenizer st = new StringTokenizer(item
                        .getItemInteractions().get(0).getAttributes());

                while (st.hasMoreTokens()) {
                    String[] attribute = st.nextToken().split("=");
                    String attributeName = attribute[0].trim();
                    if ("maxChoice".equals(attributeName)
                            || "maxChoices".equals(attributeName)) {
                        String attValue = attribute[1].trim().replaceAll(
                                "^\"|\"$", "");
                        outcomeDeclaration
                                .setNormalMaximum(Double
                                        .parseDouble(NumberUtils
                                                .isNumber(attValue) ? attValue
                                                : "0"));
                    } else if ("minChoice".equals(attributeName)
                            || "minChoices".equals(attributeName)) {
                        String attValue = attribute[1].trim().replaceAll(
                                "^\"|\"$", "");
                        outcomeDeclaration
                                .setNormalMinimum(Double
                                        .parseDouble(NumberUtils
                                                .isNumber(attValue) ? attValue
                                                : "0"));
                    }
                }

                // SORTING OPTIONS
                Map<String, String> sortedOptionMap = new HashMap<String, String>();
                for (ItemFragment ifrag : item.getItemFragments()) {
                    if (ItemCharacterizationTypeConstants.CHOICE == ifrag
                            .getType()
                            || ItemCharacterizationTypeConstants.DISTRACTOR == ifrag
                                    .getType()) {
                        sortedOptionMap.put(
                                ifrag.getType() + "#" + ifrag.getIdentifier(),
                                ifrag.getText());
                    }
                }

                Prompt prompt = new Prompt();
                int count = 1;
                for (ItemFragment ifrag : item.getItemFragments()) {
                    switch (ifrag.getType()) {
                    case ItemCharacterizationTypeConstants.CHOICE: // Choice
                        SimpleChoice simpleChoice = new SimpleChoice();

                        simpleChoice.setIdentifier("option" + count);
                        simpleChoice.setLabel(ifrag.getIdentifier());
                        dataToMakeRef += sortedOptionMap
                                .get(ItemCharacterizationTypeConstants.CHOICE
                                        + "#" + ifrag.getIdentifier());
                        String optionVal = "<div xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\">"
                                + FileUtil
                                        .modifiedSrcPath(sortedOptionMap
                                                .get(ItemCharacterizationTypeConstants.CHOICE
                                                        + "#"
                                                        + ifrag.getIdentifier()))
                                + "</div>";
                        try {
                            JAXBContext jaxbContext = JAXBContext.newInstance(
                                    SimpleChoice.class,
                                    org.w3.synthesis.ObjectFactory.class,
                                    Sub.class, Voice.class, Audio.class,
                                    Emphasis.class, SayAs.class, Break.class,
                                    Mark.class, Prosody.class);

                            Unmarshaller jaxbUnmarshaller = jaxbContext
                                    .createUnmarshaller();
                            InputSource is = new InputSource();
                            is.setCharacterStream(new StringReader(optionVal));
                            Div div = new Div();
                            div = (Div) jaxbUnmarshaller.unmarshal(is);
                            simpleChoice.getContent().add(div);

                            FeedbackBlock feedbackBlock = new FeedbackBlock();
                            feedbackBlock.setIdentifier("feedback" + count);
                            feedbackBlock.setOutcomeIdentifier("SCORE");
                            if (answerChoiceList
                                    .contains(ifrag.getIdentifier())) {
                                dataToMakeRef += sortedOptionMap
                                        .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                                + "#" + ifrag.getIdentifier());
                                String correctData = "<div xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\"><p style=\"\">CORRECT. </p>"
                                        + sortedOptionMap
                                                .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                                        + "#"
                                                        + ifrag.getIdentifier())
                                        + "</div>";
                                jaxbContext = JAXBContext.newInstance(
                                        SimpleChoice.class,
                                        org.w3.synthesis.ObjectFactory.class,
                                        Sub.class, Voice.class, Audio.class,
                                        Emphasis.class, SayAs.class,
                                        Break.class, Mark.class, Prosody.class);

                                jaxbUnmarshaller = jaxbContext
                                        .createUnmarshaller();
                                is = new InputSource();
                                is.setCharacterStream(new StringReader(
                                        correctData));
                                div = new Div();
                                div = (Div) jaxbUnmarshaller.unmarshal(is);
                                feedbackBlock.getContent().add(div);

                            } else {
                                dataToMakeRef += sortedOptionMap
                                        .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                                + "#" + ifrag.getIdentifier());
                                String correctData = "<div xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\"><p style=\"\">INCORRECT. </p>"
                                        + sortedOptionMap
                                                .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                                        + "#"
                                                        + ifrag.getIdentifier())
                                        + "</div>";
                                jaxbContext = JAXBContext.newInstance(
                                        SimpleChoice.class,
                                        org.w3.synthesis.ObjectFactory.class,
                                        Sub.class, Voice.class, Audio.class,
                                        Emphasis.class, SayAs.class,
                                        Break.class, Mark.class, Prosody.class);

                                jaxbUnmarshaller = jaxbContext
                                        .createUnmarshaller();
                                is = new InputSource();
                                is.setCharacterStream(new StringReader(
                                        correctData));
                                div = new Div();
                                div = (Div) jaxbUnmarshaller.unmarshal(is);
                                feedbackBlock.getContent().add(div);
                            }
                            simpleChoice.getContent().add(feedbackBlock);

                            intInf.getSimpleChoices().add(simpleChoice);
                        } catch (Exception e) {
                            LOGGER.log(
                                    Level.SEVERE,
                                    "Error Marshalling and Unmarshalling: "
                                            + e.getMessage(), e);
                        }
                        count++;
                        break;
                    // Prompt
                    case ItemCharacterizationTypeConstants.PROMPT:
                        data = ifrag.getText();
                        dataToMakeRef += data;
                        try {
                            data = "<div xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\">"
                                    + FileUtil.modifiedSrcPath(data) + "</div>";
                            JAXBContext jaxbContext = JAXBContext.newInstance(
                                    Prompt.class,
                                    org.w3.synthesis.ObjectFactory.class,
                                    Sub.class, Voice.class, Audio.class,
                                    Emphasis.class, SayAs.class, Break.class,
                                    Mark.class, Prosody.class);

                            Unmarshaller jaxbUnmarshaller = jaxbContext
                                    .createUnmarshaller();
                            InputSource is = new InputSource();
                            is.setCharacterStream(new StringReader(data));
                            Div div = new Div();
                            div = (Div) jaxbUnmarshaller.unmarshal(is);

                            prompt.getContent().add(div);
                            intInf.setPrompt(prompt);
                        } catch (Exception e) {
                            LOGGER.log(Level.SEVERE,
                                    "Exception " + e.getMessage(), e);
                        }
                        break;
                    default:
                        break;
                    }
                }

            }
        }

        try {
            dataToMakeRef = "<div id=\"div1\" xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2\">"
                    + FileUtil.modifiedSrcPath(dataToMakeRef) + "</div>";
            JAXBContext jaxbContext = JAXBContext.newInstance(ItemBody.class,
                    org.w3.synthesis.ObjectFactory.class, Sub.class,
                    Voice.class, Audio.class, Emphasis.class, SayAs.class,
                    Break.class, Mark.class, Prosody.class);

            Unmarshaller jaxbUnmarshaller = jaxbContext.createUnmarshaller();
            InputSource is = new InputSource();
            is.setCharacterStream(new StringReader(dataToMakeRef));
            Div div = new Div();
            div = (Div) jaxbUnmarshaller.unmarshal(is);
            idRefMap = IMSItemUtil.createIdRefMap(div);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Exception " + e.getMessage(), e);
        }

        try {
            itemBody.getRubricBlocksAndPositionObjectStagesAndCustomInteractions()
                    .add(intInf);

            itemElement.getOutcomeDeclarations().add(outcomeDeclaration);
            itemElement.setItemBody(itemBody);

            itemElement.setApipAccessibility(buildItemAccessibilityInfo(item,
                    idRefMap));

            xmlContent = JAXBUtil.mershall(itemElement, AssessmentItem.class,
                    org.w3.synthesis.ObjectFactory.class);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Exception building item xml " + e.getMessage(), e);
        }
        return xmlContent;
    }

    private ApipAccessibility buildItemAccessibilityInfo(Item item,
            Map<String, Object> idRefMap) {
        ApipAccessibility apipAccessibility = new ApipAccessibility();
        AccessibilityInfoType accessibilityInfo = new AccessibilityInfoType();
        LOGGER.info("Searching for Accessibility Element");
        try {
            if (item != null) {
                List<AccessibilityElement> accessElementList = accessibilityItemServices
                        .findAccessibilityElements(item.getId());
                int count = 1;
                if (CollectionUtils.isNotEmpty(accessElementList)) {
                    LOGGER.info("Found Accessibility Elements "
                            + accessElementList.size());
                    for (AccessibilityElement ae : accessElementList) {
                        AccessElementType accessElement = new AccessElementType();
                        accessElement.setIdentifier(ae.getName());

                        ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
                        contentLinkInfo.setApipLinkIdentifierRef(idRefMap
                                .get(ae.getContentName()));
                        EmptyPrimitiveTypeType eptt = new EmptyPrimitiveTypeType();
                        contentLinkInfo.setObjectLink(eptt);
                        accessElement.getContentLinkInfos()
                                .add(contentLinkInfo);

                        RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();
                        List<String> featureType = new ArrayList<String>();
                        int elementCount = 1;
                        for (AccessibilityFeature accessFeature : ae
                                .getFeatureList()) {
                            if (accessFeature.getType() == 3
                                    && accessFeature.getFeature() == 3) { // Braille
                                                                          // Text
                                BrailleTextType brailleText = new BrailleTextType();
                                LabelledStringType lst = new LabelledStringType();
                                lst.setContentLinkIdentifier(ae
                                        .getContentName() + elementCount);
                                lst.setValue(accessFeature.getInfo());
                                brailleText.setBrailleTextString(lst);

                                featureType.add(accessFeature.getType() + "#"
                                        + accessFeature.getFeature());

                                relatedElementInfo
                                        .getSpokensAndBrailleTextsAndTactileFiles()
                                        .add(brailleText);
                                elementCount++;
                            } else if (accessFeature.getType() == 1
                                    && accessFeature.getFeature() == 2) { // Text
                                                                          // Speech
                                                                          // Pronunciation
                                SpokenType spoken = new SpokenType();
                                LabelledStringType lst = new LabelledStringType();
                                lst.setContentLinkIdentifier(ae
                                        .getContentName() + elementCount);
                                lst.setValue(accessFeature.getInfo());

                                spoken.setTextToSpeechPronunciation(lst);
                                featureType.add(accessFeature.getType() + "#"
                                        + accessFeature.getFeature());

                                relatedElementInfo
                                        .getSpokensAndBrailleTextsAndTactileFiles()
                                        .add(spoken);
                                elementCount++;
                            } else if (accessFeature.getType() == 1
                                    && accessFeature.getFeature() == 1) { // Spoken
                                                                          // Text
                                SpokenType spoken = new SpokenType();
                                LabelledStringType lst = new LabelledStringType();
                                lst.setContentLinkIdentifier(ae
                                        .getContentName() + elementCount);
                                lst.setValue(accessFeature.getInfo());

                                spoken.setTextToSpeechPronunciation(lst);
                                featureType.add(accessFeature.getType() + "#"
                                        + accessFeature.getFeature());

                                relatedElementInfo
                                        .getSpokensAndBrailleTextsAndTactileFiles()
                                        .add(spoken);
                                elementCount++;
                            } else if (accessFeature.getType() == 4
                                    && accessFeature.getFeature() == -1) { // Keyword
                                                                           // Translation
                                KeyWordTranslationType kwtt = new KeyWordTranslationType();
                                DefinitionIdType dit = new DefinitionIdType();
                                LabelledStringType lst = new LabelledStringType();
                                lst.setContentLinkIdentifier(ae
                                        .getContentName() + elementCount);
                                lst.setValue(accessFeature.getInfo());
                                dit.setLang(accessFeature.getLangCode());
                                dit.setTextString(lst);

                                featureType.add(accessFeature.getType() + "#"
                                        + accessFeature.getFeature());
                                kwtt.getDefinitionIds().add(dit);

                                relatedElementInfo
                                        .getSpokensAndBrailleTextsAndTactileFiles()
                                        .add(kwtt);
                                elementCount++;
                            } else if (accessFeature.getType() == 5
                                    && accessFeature.getFeature() == 5) { // Highlighting
                                LOGGER.info("Highlighting not available..");
                            }
                        }

                        if (!featureType.contains("3#3")) { // To give a default
                                                            // BRAILLE
                                                            // TEXT element into
                                                            // xml
                            BrailleTextType brailleText = new BrailleTextType();
                            LabelledStringType lst = new LabelledStringType();
                            lst.setContentLinkIdentifier(ae.getContentName()
                                    + elementCount);
                            lst.setValue("");
                            brailleText.setBrailleTextString(lst);

                            relatedElementInfo
                                    .getSpokensAndBrailleTextsAndTactileFiles()
                                    .add(brailleText);
                        }

                        if (!featureType.contains("1#2")) { // To give a default
                                                            // BRAILLE
                                                            // TEXT element into
                                                            // xml
                            SpokenType spoken = new SpokenType();
                            LabelledStringType lst = new LabelledStringType();
                            lst.setContentLinkIdentifier(ae.getContentName()
                                    + elementCount);
                            lst.setValue("");

                            spoken.setTextToSpeechPronunciation(lst);

                            relatedElementInfo
                                    .getSpokensAndBrailleTextsAndTactileFiles()
                                    .add(spoken);
                        }

                        accessElement.setRelatedElementInfo(relatedElementInfo);
                        accessibilityInfo.getAccessElements()
                                .add(accessElement);
                        count++;
                    }
                }

                if (accessElementList == null || accessElementList.isEmpty()) {
                    AccessElementType accessElement = new AccessElementType();
                    accessElement.setIdentifier("ae" + count);

                    ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
                    contentLinkInfo.setApipLinkIdentifierRef(idRefMap
                            .get("div1"));
                    EmptyPrimitiveTypeType eptt = new EmptyPrimitiveTypeType();
                    contentLinkInfo.setObjectLink(eptt);
                    accessElement.getContentLinkInfos().add(contentLinkInfo);

                    RelatedElementInfoType relatedElementInfo = new RelatedElementInfoType();

                    accessElement.setRelatedElementInfo(relatedElementInfo);
                    accessibilityInfo.getAccessElements().add(accessElement);
                }

                apipAccessibility.setAccessibilityInfo(accessibilityInfo);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Unable to build item accessibility xml "
                    + e.getMessage(), e);
        }
        return apipAccessibility;
    }

    private String buildItemMetadataXml(Item item) {
        String xmlContent = null;
        com.pacificmetrics.saaif.metadata1.ObjectFactory mbof = new com.pacificmetrics.saaif.metadata1.ObjectFactory();
        MetadataType metadata = mbof.createMetadataType();
        SmarterAppMetadataType smd = mbof.createSmarterAppMetadataType();

        smd.setIdentifier(Long.toString(item.getId()));
        smd.setVersion(Integer.toString(item.getVersion()));
        smd.getAlternateIdentifier().add(item.getItemGuid());
        smd.setInteractionType(SAAIFItemUtil.getSBAIFItemFormatFromORCA(item
                .getItemInteractions()));
        smd.setSubject(item.getSubject());
        DevState devStatus = item.getDevState();
        if (devStatus != null) {
            smd.setStatus(devStatus.getName());
        }
        smd.getLanguage().add(
                SAAIFPackageConstants.LANGUAGE.get(item.getLang()));
        smd.setSecurityStatus("Non-secure");
        ItemCharacterization gradeCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.GRADE_LEVEL);
        if (gradeCharacterization != null) {
            smd.setIntendedGrade(Integer.toString(gradeCharacterization
                    .getIntValue()));
        }
        ItemCharacterization gradeStartCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.GRADE_SPAN_START);
        if (gradeStartCharacterization != null) {
            smd.setMinimumGrade(Integer.toString(gradeStartCharacterization
                    .getIntValue()));
        }
        ItemCharacterization gradeEndCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.GRADE_SPAN_END);
        if (gradeEndCharacterization != null) {
            smd.setMaximumGrade(Integer.toString(gradeEndCharacterization
                    .getIntValue()));
        }
        ItemCharacterization enemyItemCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.ITEM_ENEMY);
        if (enemyItemCharacterization != null) {
            Item enemyItem = null;
            try {
                enemyItem = itemServices.findItemById(enemyItemCharacterization
                        .getIntValue());
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE,
                        "Unable to find enemy item with Item ID "
                                + enemyItemCharacterization.getIntValue() + " "
                                + e.getMessage(), e);
            }
            if (enemyItem != null) {
                smd.setMaximumGrade(enemyItem.getItemGuid());
            }
        }

        smd.setSmarterAppItemDescriptor(item.getDescription());

        ItemCharacterization pointCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.GRADE_LEVEL);
        if (pointCharacterization != null) {
            smd.setMaximumNumberOfPoints(Integer.toString(pointCharacterization
                    .getIntValue()));
            StringBuilder scorePoints = new StringBuilder("0");
            for (int point = 1; point < pointCharacterization.getIntValue(); point++) {
                scorePoints.append(",").append(point);
            }

            smd.getScorePoints().add(scorePoints.toString());
        }

        List<Passage> passages = new ArrayList<Passage>();

        List<Object[]> itemCharacterizations = contentMoveService
                .findItemCharacterization(item.getId());

        if (CollectionUtils.isNotEmpty(itemCharacterizations)) {
            for (Object[] ic : itemCharacterizations) {
                int type = Integer.parseInt(ic[1].toString());
                int objId = Integer.parseInt(ic[2].toString());
                if (type == ItemCharacterizationTypeConstants.PASSAGE) {
                    Passage passage = contentMoveService.findPassageById(objId);
                    passages.add(passage);
                }
            }
        }

        if (CollectionUtils.isNotEmpty(passages)) {
            for (Passage passage : passages) {
                smd.setAssociatedStimulus(String.valueOf(passage.getId()));
            }
        }

        smd.setItemSpecFormat("SmarterApp");
        smd.getEvidenceStatement().add("");
        smd.setStimulusFormat("Standard");
        smd.setEducationalDifficulty(contentMoveService.findDifficultyById(
                item.getDifficulty()).getName());

        ItemCharacterization depthOfKnowledgeCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.DOK);
        if (depthOfKnowledgeCharacterization != null) {
            smd.setDepthOfKnowledge(Integer
                    .toString(depthOfKnowledgeCharacterization.getIntValue()));
        }

        PublicationStatus publicationStatus = item.getItemPublicationStatus();
        if (publicationStatus != null) {
            smd.setStatus(publicationStatus.getName());
        }
        smd.setPresentationFormat("Text with graphics");

        StandardPublication sp = new StandardPublication();
        String primaryStandard = item.getPrimaryStandard();
        String publication = primaryStandard != null ? primaryStandard
                .split(":")[0] : "";
        sp.setPublication(publication);
        sp.setPrimaryStandard(primaryStandard);
        for (ItemStandard itemStandard : item.getItemStandardList()) {
            sp.getSecondaryStandard().add(itemStandard.getStandard());
        }
        smd.getStandardPublication().add(sp);

        metadata.setSmarterAppMetadata(smd);

        xmlContent = JAXBUtil.mershall(metadata, MetadataType.class);

        return xmlContent;
    }

}
