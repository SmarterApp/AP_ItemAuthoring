package com.pacificmetrics.orca.export.saaif;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.math.NumberUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

import com.pacificmetrics.orca.ejb.AccessibilityItemServices;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.DevState;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAlternate;
import com.pacificmetrics.orca.entities.ItemAssetAttribute;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.entities.ItemFragment;
import com.pacificmetrics.orca.entities.ItemInteraction;
import com.pacificmetrics.orca.entities.ItemStandard;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PublicationStatus;
import com.pacificmetrics.orca.entities.Rubric;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.orca.utils.SAAIFItemUtil;
import com.pacificmetrics.saaif.item1.AccessElementType;
import com.pacificmetrics.saaif.item1.AccessibilityInfoType;
import com.pacificmetrics.saaif.item1.ApipAccessibilityType;
import com.pacificmetrics.saaif.item1.AssessmentitemType;
import com.pacificmetrics.saaif.item1.AssessmentitemreleaseType;
import com.pacificmetrics.saaif.item1.BrailleTextType;
import com.pacificmetrics.saaif.item1.ContentLinkInfoType;
import com.pacificmetrics.saaif.item1.DefinitionIdType;
import com.pacificmetrics.saaif.item1.ItemFormatType;
import com.pacificmetrics.saaif.item1.ItemattribType;
import com.pacificmetrics.saaif.item1.ItemattriblistType;
import com.pacificmetrics.saaif.item1.ItemcontentType;
import com.pacificmetrics.saaif.item1.KeyWordTranslationType;
import com.pacificmetrics.saaif.item1.ObjectFactory;
import com.pacificmetrics.saaif.item1.OptionType;
import com.pacificmetrics.saaif.item1.OptionlistType;
import com.pacificmetrics.saaif.item1.ReadAloudType;
import com.pacificmetrics.saaif.item1.RelatedElementInfoType;
import com.pacificmetrics.saaif.item1.RubricType;
import com.pacificmetrics.saaif.item1.RubriclistType;
import com.pacificmetrics.saaif.item1.SamplelistType;
import com.pacificmetrics.saaif.item1.StemType;
import com.pacificmetrics.saaif.item1.W3XHtmlType;
import com.pacificmetrics.saaif.metadata1.MetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType.StandardPublication;

@Stateless
public class ORCA2SAAIFItemWriter {

    private static final Logger LOGGER = Logger
            .getLogger(ORCA2SAAIFItemWriter.class.getName());

    private static final ObjectFactory OBF = new ObjectFactory();

    @EJB
    private ContentMoveServices contentMoveService;

    @EJB
    private AccessibilityItemServices accessibilityItemServices;

    @EJB
    private ItemServices itemServices;

    @EJB
    private ORCA2SAAIFPassageWriter orca2SAAIFPassageWriter;

    public SAAIFItem getItem(Item item) {

        SAAIFItem saaifItem = new SAAIFItem();

        saaifItem.setId(Long.toString(item.getId()));
        saaifItem.setUniqueId(item.getExternalId());
        saaifItem.setVersion(item.getVersion());
        saaifItem.setHref("item-" + item.getItemBankId() + "-"
                + saaifItem.getId() + ".xml");
        saaifItem.setHrefBase("Item_" + saaifItem.getId());
        saaifItem.setMetadataHrefBase("Item_" + saaifItem.getId());
        saaifItem.setMetadataHref("item-" + item.getItemBankId() + "-"
                + saaifItem.getId() + "_metadata.xml");
        saaifItem.setBankKey(Integer.toString(item.getItemBankId()));

        List<ItemAssetAttribute> itemAssetAttributeList = contentMoveService
                .findItemAssetsByItemId(item.getId());

        // Creating a blank attachments
        Map<String, String> attachmentMap = new HashMap<String, String>();

        saaifItem.setAttachments(attachmentMap);

        // finding item asset
        if (CollectionUtils.isNotEmpty(itemAssetAttributeList)) {
            Map<String, String> assetMap = new HashMap<String, String>();
            for (ItemAssetAttribute asset : itemAssetAttributeList) {
                assetMap.put(
                        asset.getFileName(),
                        IMSItemUtil.getItemImageDirPath(item.getItemBankId(),
                                item.getExternalId())
                                + File.separator
                                + asset.getFileName());
            }
            saaifItem.setAssets(assetMap);
        }

        // item content
        saaifItem.setXmlContent(buildItemXml(item));

        // metadata content
        saaifItem.setMetadataXmlContent(buildItemMetadataXml(item));

        saaifItem.setPassages(orca2SAAIFPassageWriter.getPassage(item));

        return saaifItem;
    }

    private String buildItemXml(Item item) {
        String xmlContent = null;

        try {
            AssessmentitemreleaseType itemrelease = OBF
                    .createAssessmentitemreleaseType();
            itemrelease.setVersion(String.valueOf(item.getVersion()));
            AssessmentitemType itemElement = OBF.createAssessmentitemType();

            itemElement.setId(Long.toString(item.getId()));
            itemElement.setVersion(Integer.toString(item.getVersion()));
            // Determine item format type
            String format = SAAIFItemUtil.getSBAIFItemFormatFromORCA(item
                    .getItemInteractions());

            itemElement.setFormat(ItemFormatType.fromValue(format));

            itemElement.setAttriblist(buildItemAttributes(item));
            itemElement.getContent().addAll(buildItemContents(item));

            // Alternate content
            ItemAlternate itemAlternate = contentMoveService
                    .findItemAlternateByItem(item.getId());
            if (null != itemAlternate) {
                Item altItem = contentMoveService.findItemById(itemAlternate
                        .getAlternateItemId());
                if (null != altItem) {
                    itemElement.getContent().addAll(buildItemContents(altItem));
                }
            }
            itemrelease.setItem(itemElement);
            xmlContent = JAXBUtil.mershallSBAIF(itemrelease,
                    AssessmentitemreleaseType.class);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Unable to build item with Item ID "
                    + item.getExternalId() + " " + e.getMessage(), e);
        }

        return xmlContent;
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

        List<Passage> passages = contentMoveService.findPassageByItemId(item
                .getId());
        for (Passage passage : passages) {
            smd.setAssociatedStimulus(String.valueOf(passage.getId()));
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

        xmlContent = JAXBUtil.mershallSBAIF(metadata, MetadataType.class);

        return xmlContent;
    }

    private List<ItemcontentType> buildItemContents(Item item) {
        List<ItemcontentType> contentTypes = new LinkedList<ItemcontentType>();

        ItemcontentType ict = new ItemcontentType();

        ict.setLanguage(SAAIFPackageConstants.LANGUAGE.get(item.getLang())
                .toUpperCase());
        // TODO: Needs for clarification
        ict.setVersion("0");
        // Version of Item
        ict.setApprovedVersion(String.valueOf(item.getVersion()));

        // STEM ELEMENT
        StemType stpe = new StemType();

        String data = "";
        for (ItemFragment ifrag : item.getItemFragments()) {
            if (ifrag.getType() == ItemFragment.IF_STEM
                    || ifrag.getType() == ItemFragment.IF_PROMPT) {
                data += ifrag.getText();
            }
        }
        try {

            if (!data.isEmpty()) {
                data = "<![CDATA[" + FileUtil.modifiedSrcPath(data) + "]]>";
            }

            stpe.setValue(data);

            ict.setStem(stpe);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Exception " + e.getMessage(), e);
        }

        // CREATE INTERACTION sub nodes (PROMPT/CHOICES)
        try {

            for (ItemInteraction ii : item.getItemInteractions()) {
                if (ii.getName()
                        .equalsIgnoreCase(SAAIFPackageConstants.II_NAME)) {
                    List<String> answerChoiceList = null;
                    if (ii.getType() == 1) {
                        answerChoiceList = new ArrayList<String>(
                                Arrays.asList(ii.getCorrect() != null ? ii
                                        .getCorrect().split(" ")
                                        : new String[] { "" }));
                    } else {
                        answerChoiceList = new ArrayList<String>(
                                Arrays.asList(ii.getCorrect()));
                    }
                    StringTokenizer st = new StringTokenizer(item
                            .getItemInteractions().get(0).getAttributes());

                    OptionlistType optionlist = new OptionlistType();
                    while (st.hasMoreTokens()) {
                        String[] attribute = st.nextToken().split("=");
                        String attributeName = attribute[0].trim();
                        if ("maxChoice".equals(attributeName)
                                || "maxChoices".equals(attributeName)) {
                            String attValue = attribute[1].trim().replaceAll(
                                    "^\"|\"$", "");
                            optionlist.setMaxChoices(NumberUtils
                                    .isNumber(attValue) ? Integer
                                    .parseInt(attValue) : -1);
                        } else if ("minChoice".equals(attributeName)
                                || "minChoices".equals(attributeName)) {
                            String attValue = attribute[1].trim().replaceAll(
                                    "^\"|\"$", "");
                            optionlist.setMinChoices(NumberUtils
                                    .isNumber(attValue) ? Integer
                                    .parseInt(attValue) : -1);
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
                                    ifrag.getType() + "#"
                                            + ifrag.getIdentifier(),
                                    ifrag.getText());
                        }
                    }

                    boolean optionFlag = false;
                    for (ItemFragment ifrag : item.getItemFragments()) {

                        switch (ifrag.getType()) {
                        // Choice
                        case ItemCharacterizationTypeConstants.CHOICE:
                            optionFlag = createChoiceSubNodes(ifrag,
                                    sortedOptionMap, answerChoiceList,
                                    optionlist);
                            break;
                        default:
                            break;
                        }

                    }

                    if (!optionFlag) {
                        OptionType option = new OptionType();
                        option.setName("");
                        W3XHtmlType w3xhtmlType = new W3XHtmlType();
                        w3xhtmlType.setValue("");
                        option.setVal(w3xhtmlType);

                        w3xhtmlType = new W3XHtmlType();
                        w3xhtmlType.setValue("");
                        option.setFeedback(w3xhtmlType);
                        optionlist.getOption().add(option);
                    }

                    ict.setOptionlist(optionlist);
                }
            }
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Unable to build Item Contents with Item ID "
                            + item.getExternalId() + " " + e.getMessage(), e);
        }

        // RUBRIC ELEMENT
        List<Object[]> icList = contentMoveService
                .findItemCharacterizationForRubric(item);

        if (icList != null && !icList.isEmpty()) {
            LOGGER.info("Searching original qti for rubrics");

            RubriclistType rubTypeList = new RubriclistType();
            for (Object[] ic : icList) {
                try {
                    Rubric rubric = contentMoveService.findRubricById(Integer
                            .parseInt(ic[2].toString()));
                    File file = new File(rubric.getUrl());

                    RubricType rubType = new RubricType();

                    InputStream is = new FileInputStream(file);
                    DocumentBuilderFactory factory = DocumentBuilderFactory
                            .newInstance();
                    DocumentBuilder builder = factory.newDocumentBuilder();

                    Document oldDoc = builder.parse(is);
                    // retrieve the element 'head'
                    Element element = (Element) oldDoc.getElementsByTagName(
                            "head").item(0);
                    // remove the specific node
                    element.getParentNode().removeChild(element);

                    Node oldRoot = oldDoc.getDocumentElement();
                    Document newDoc = builder.newDocument();
                    Element newRoot = newDoc.createElement("div");
                    newRoot.setAttribute("xmlns",
                            "http://www.w3.org/1999/xhtml");
                    newDoc.appendChild(newRoot);
                    newRoot.appendChild(newDoc.importNode(oldRoot, true));

                    StringWriter stringWriter = new StringWriter();
                    Transformer transformer = TransformerFactory.newInstance()
                            .newTransformer();
                    transformer.transform(new DOMSource(newDoc),
                            new StreamResult(stringWriter));
                    String strFileContent = stringWriter.toString(); // This is
                                                                     // string
                                                                     // data
                                                                     // of
                                                                     // xml
                                                                     // file
                    strFileContent = strFileContent.replace("<html>", "")
                            .replace("</html>", "").replace("<body>", "")
                            .replace("</body>", "");

                    rubType.setScorepoint("0");

                    W3XHtmlType w3xhtmlType = new W3XHtmlType();

                    w3xhtmlType.setValue(strFileContent);
                    rubType.setVal(w3xhtmlType);
                    rubType.setName(rubric.getName());

                    rubTypeList.getRubric().add(rubType);

                    // SAMPLELIST ELEMENT
                    SamplelistType sampleType = new SamplelistType();
                    sampleType.setMaxval(1);
                    sampleType.setMinval(1);

                    rubTypeList.getSamplelist().add(sampleType);

                } catch (Exception e) {
                    LOGGER.log(Level.SEVERE, "Exception " + e.getMessage(), e);
                }
            }
            ict.setRubriclist(rubTypeList);
        }

        // ACCESSIBILITY ELEMENT
        ict.setApipAccessibility(buildItemAccessibilityInfo(item));

        contentTypes.add(ict);

        return contentTypes;
    }

    public boolean createChoiceSubNodes(ItemFragment ifrag,
            Map<String, String> sortedOptionMap, List<String> answerChoiceList,
            OptionlistType optionlist) {
        boolean optionFlag = false;
        OptionType option = new OptionType();
        option.setName(ifrag.getIdentifier());

        String optionVal = "<![CDATA["
                + FileUtil.modifiedSrcPath(sortedOptionMap
                        .get(ItemCharacterizationTypeConstants.CHOICE + "#"
                                + ifrag.getIdentifier())) + "]]>";
        try {

            W3XHtmlType w3xhtmlType = new W3XHtmlType();

            w3xhtmlType.setValue(optionVal);
            option.setVal(w3xhtmlType);

            if (answerChoiceList.contains(ifrag.getIdentifier())) {

                String correctData = "<![CDATA[<p style=\"\">Correct: </p>"
                        + sortedOptionMap
                                .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                        + "#" + ifrag.getIdentifier()) + "]]>";

                w3xhtmlType = new W3XHtmlType();

                w3xhtmlType.setValue(correctData);
                option.setFeedback(w3xhtmlType);
            } else {

                String correctData = "<![CDATA[<p style=\"\">Incorrect: </p>"
                        + sortedOptionMap
                                .get(ItemCharacterizationTypeConstants.DISTRACTOR
                                        + "#" + ifrag.getIdentifier()) + "]]>";

                w3xhtmlType = new W3XHtmlType();

                w3xhtmlType.setValue(correctData);
                option.setFeedback(w3xhtmlType);
            }

            optionlist.getOption().add(option);
            optionFlag = true;
        } catch (Exception e) {
            optionFlag = false;
            LOGGER.log(Level.SEVERE, "Unable to build Choices with Item ID "
                    + e.getMessage(), e);
        }

        return optionFlag;
    }

    public ItemFragment getItemBodyFragment(final Item item) {
        ItemFragment bodyFrag = null;
        LOGGER.info("Retrieving item fragments");
        for (ItemFragment frag : item.getItemFragments()) {
            if (frag.getType() == ItemFragment.IF_STEM) {
                bodyFrag = frag;
            }
        }
        return bodyFrag;
    }

    private ItemattriblistType buildItemAttributes(Item item) {
        ItemattriblistType attributeLists = OBF.createItemattriblistType();

        // id attribute
        ItemattribType itemIdAttribute = OBF.createItemattribType();

        itemIdAttribute.setAttid(ItemAttribConstants.ITEM_ID);
        itemIdAttribute.setName(ItemAttribConstants.ITEM_ID_NAME);
        itemIdAttribute.setVal(Long.toString(item.getId()));
        itemIdAttribute.setDesc("");
        attributeLists.getAttrib().add(itemIdAttribute);

        // subject attribute
        ItemattribType itemSubjectAttribute = OBF.createItemattribType();

        itemSubjectAttribute.setAttid(ItemAttribConstants.ITEM_SUBJECT);
        itemSubjectAttribute.setName(ItemAttribConstants.ITEM_SUBJECT_NAME);
        itemSubjectAttribute.setVal(item.getSubject());
        itemSubjectAttribute.setDesc("");
        attributeLists.getAttrib().add(itemSubjectAttribute);

        // grade attribute
        ItemattribType itemGradeAttribute = OBF.createItemattribType();

        itemGradeAttribute.setAttid(ItemAttribConstants.ITEM_GRADE);
        itemGradeAttribute.setName(ItemAttribConstants.ITEM_GRADE_NAME);
        itemGradeAttribute.setVal(item.getGradeLevel());
        itemGradeAttribute.setDesc("");
        attributeLists.getAttrib().add(itemGradeAttribute);

        // description attribute
        ItemattribType itemDescAttribute = OBF.createItemattribType();

        itemDescAttribute.setAttid(ItemAttribConstants.ITEM_DESC);
        itemDescAttribute.setName(ItemAttribConstants.ITEM_DESC_NAME);
        itemDescAttribute.setVal(item.getDescription());
        itemDescAttribute.setDesc("");
        attributeLists.getAttrib().add(itemDescAttribute);

        // point attribute
        ItemCharacterization pointCharacterization = item
                .getCharacterization(ItemCharacterizationTypeConstants.POINTS);
        if (pointCharacterization != null) {
            int point = pointCharacterization.getIntValue();
            ItemattribType itemPointAttribute = OBF.createItemattribType();

            itemPointAttribute.setAttid(ItemAttribConstants.ITEM_POINT);
            itemPointAttribute.setName(ItemAttribConstants.ITEM_POINT_NAME);
            itemPointAttribute.setVal(point + (point > 1 ? " pts." : " pt."));
            itemPointAttribute.setDesc(point
                    + (point > 1 ? " Points" : " Point"));
            attributeLists.getAttrib().add(itemPointAttribute);
        }

        // format attribute
        String format = SAAIFItemUtil.getSBAIFItemFormatFromORCA(item
                .getItemInteractions());

        ItemattribType itemFormatAttribute = OBF.createItemattribType();

        itemFormatAttribute.setAttid(ItemAttribConstants.ITEM_FORMAT);
        itemFormatAttribute.setName(ItemAttribConstants.ITEM_FORMAT_NAME);
        itemFormatAttribute.setVal(format);
        itemFormatAttribute.setDesc("");
        attributeLists.getAttrib().add(itemFormatAttribute);

        // standard attribute
        ItemattribType itemStandardAttribute = OBF.createItemattribType();

        itemStandardAttribute.setAttid(ItemAttribConstants.ITEM_STRAND);
        itemStandardAttribute.setName(ItemAttribConstants.ITEM_STAND_NAME);
        itemStandardAttribute.setVal(item.getPrimaryStandard() != null ? item
                .getPrimaryStandard() : "");
        itemStandardAttribute.setDesc("");
        attributeLists.getAttrib().add(itemStandardAttribute);

        // response type attribute
        ItemattribType itemResponseTypeAttribute = OBF.createItemattribType();

        itemResponseTypeAttribute
                .setAttid(ItemAttribConstants.ITEM_RESPONSE_TYPE);
        itemResponseTypeAttribute
                .setName(ItemAttribConstants.ITEM_RESPONSE_TYPE_NAME);
        itemResponseTypeAttribute.setVal(SAAIFItemAttributeUtil
                .getResponseType(format));
        itemResponseTypeAttribute.setDesc("");
        attributeLists.getAttrib().add(itemResponseTypeAttribute);

        // page layout attribute
        ItemattribType itemPageLayoutAttribute = OBF.createItemattribType();

        itemPageLayoutAttribute.setAttid(ItemAttribConstants.ITEM_PAGE_LAYOUT);
        itemPageLayoutAttribute
                .setName(ItemAttribConstants.ITEM_PAGE_LAYOUT_NAME);
        itemPageLayoutAttribute.setVal(SAAIFItemAttributeUtil
                .getPageLayout(format));
        itemPageLayoutAttribute.setDesc("");
        attributeLists.getAttrib().add(itemPageLayoutAttribute);

        // answer key attribute
        ItemattribType itemAnswerKeyAttribute = OBF.createItemattribType();

        itemAnswerKeyAttribute.setAttid(ItemAttribConstants.ITEM_ANSWER_KEY);
        itemAnswerKeyAttribute
                .setName(ItemAttribConstants.ITEM_ANSWER_KEY_NAME);
        itemAnswerKeyAttribute.setVal(SAAIFItemAttributeUtil
                .getResponseType(format));
        itemAnswerKeyAttribute.setDesc("");
        attributeLists.getAttrib().add(itemAnswerKeyAttribute);

        // TODO : close Answer
        ItemattribType itemCloseAnswerAttribute = OBF.createItemattribType();

        itemCloseAnswerAttribute
                .setAttid(ItemAttribConstants.ITEM_CLOZE_ANSWERS);
        itemCloseAnswerAttribute
                .setName(ItemAttribConstants.ITEM_CLOZE_ANSWERS_NAME);
        itemCloseAnswerAttribute.setVal("");
        itemCloseAnswerAttribute.setDesc("");
        attributeLists.getAttrib().add(itemCloseAnswerAttribute);

        // TODO : operation Use Answer
        ItemattribType itemOPUseAttribute = OBF.createItemattribType();

        itemOPUseAttribute.setAttid(ItemAttribConstants.ITEM_OPUSE);
        itemOPUseAttribute.setName(ItemAttribConstants.ITEM_OPUSE_NAME);
        itemOPUseAttribute.setVal("");
        itemOPUseAttribute.setDesc("");
        attributeLists.getAttrib().add(itemOPUseAttribute);

        // Field Test Use Answer
        ItemattribType itemFieldUseAttribute = OBF.createItemattribType();

        itemFieldUseAttribute.setAttid(ItemAttribConstants.ITEM_FTUSE);
        itemFieldUseAttribute.setName(ItemAttribConstants.ITEM_FTUSE_NAME);
        itemFieldUseAttribute.setVal("");
        itemFieldUseAttribute.setDesc("");
        attributeLists.getAttrib().add(itemFieldUseAttribute);

        return attributeLists;
    }

    private ApipAccessibilityType buildItemAccessibilityInfo(Item item) {
        ApipAccessibilityType apipAccessibility = new ApipAccessibilityType();
        AccessibilityInfoType accessibilityInfo = new AccessibilityInfoType();
        LOGGER.info("Searching for Accessibility Element");
        /*
         * List<AccessibilityElement> accessElementList = itemServices
         * .findAccessibilityElementByItem(item.getId());
         */
        List<AccessibilityElement> accessElementList = accessibilityItemServices
                .findAccessibilityElements(item.getId());

        int count = 1;
        for (AccessibilityElement ae : accessElementList) {
            AccessElementType accessElement = new AccessElementType();
            accessElement.setIdentifier("ae" + count);

            ContentLinkInfoType contentLinkInfo = new ContentLinkInfoType();
            contentLinkInfo.setType(SAAIFPackageConstants.CONTENT_LINK_TYPE
                    .get(ae.getContentLinkType()));
            contentLinkInfo.setItsLinkIdentifierRef(ae.getContentName());
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

}
