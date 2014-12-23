package com.pacificmetrics.orca.loader.saaif;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.utils.DomUtil;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.item1.AssessmentitemType;
import com.pacificmetrics.saaif.item1.AssessmentitemreleaseType;
import com.pacificmetrics.saaif.item1.ItemFormatType;
import com.pacificmetrics.saaif.item1.ItemattribType;
import com.pacificmetrics.saaif.item1.ItemattriblistType;
import com.pacificmetrics.saaif.metadata.Metadata;
import com.pacificmetrics.saaif.tutorial.TutorialitemType;
import com.pacificmetrics.saaif.tutorial.TutorialreleaseType;
import com.pacificmetrics.saaif.wordlist.WordlistitemType;
import com.pacificmetrics.saaif.wordlist.WordlistreleaseType;

public class SAAIFItemReader {

    private static final Log LOGGER = LogFactory.getLog(SAAIFItemReader.class);

    private SAAIFItemReader() {
    }

    public static Metadata readItemMetadata(InputStream inputStream) {
        String metadataContent = FileUtil.readToString(inputStream, false);
        Metadata metadata = JAXBUtil.<Metadata> unmershall(metadataContent,
                Metadata.class);
        return metadata;
    }

    public static Metadata readeItemMetadataFromString(String metadataContent) {
        try {
            return JAXBUtil.<Metadata> unmershall(metadataContent,
                    Metadata.class);
        } catch (Exception e) {
            LOGGER.error("Error in unmershalling Metadata : " + e.getMessage(),
                    e);
            return null;
        }
    }

    public static Metadata readItemMetadata(String filePath) {
        try {
            String metadataContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            return JAXBUtil.<Metadata> unmershall(metadataContent,
                    Metadata.class);
        } catch (Exception e) {
            LOGGER.error("Error in unmershalling Metadata : " + e.getMessage(),
                    e);
            return null;
        }
    }

    public static AssessmentitemType readItem(InputStream inputStream) {
        String itemContent = FileUtil.readToString(inputStream, false);
        AssessmentitemreleaseType itemRelease = JAXBUtil
                .<AssessmentitemreleaseType> unmershall(itemContent,
                        AssessmentitemreleaseType.class);
        if (itemRelease != null) {
            return itemRelease.getItem();
        }
        return null;
    }

    public static AssessmentitemType readItem(String filePath) {
        try {
            String itemContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));

            AssessmentitemreleaseType itemRelease = JAXBUtil
                    .<AssessmentitemreleaseType> unmershall(itemContent,
                            AssessmentitemreleaseType.class);
            if (itemRelease != null) {
                return itemRelease.getItem();
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error in unmershalling AssessmentitemType : "
                            + e.getMessage(), e);
            return null;
        }
        return null;
    }

    private static AssessmentitemType perseItem(String xmlContent) {
        AssessmentitemType itemType = new AssessmentitemType();
        try {

            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);
            Node itemReleaseNode = document.getFirstChild();

            Node itemNode = DomUtil.getNode("item",
                    itemReleaseNode.getChildNodes());
            if (itemNode != null) {
                Element itemElement = (Element) itemNode;
                itemType.setId(DomUtil.getAttributeValue("id", itemElement));
                String format = DomUtil
                        .getAttributeValue("format", itemElement);
                if (StringUtils.isNotEmpty(format)) {
                    itemType.setFormat(ItemFormatType.fromValue(format));
                }
                itemType.setType(DomUtil.getAttributeValue("type", itemElement));
                itemType.setVersion(DomUtil.getAttributeValue("version",
                        itemElement));

                Node attribListNode = DomUtil.getNode("attriblist",
                        itemElement.getChildNodes());
                List<Node> attribNodes = DomUtil.getNodes("attrib",
                        attribListNode.getChildNodes());

                ItemattriblistType attribListType = new ItemattriblistType();
                List<ItemattribType> itemAttribTypes = new ArrayList<ItemattribType>();

                for (Node attribNode : attribNodes) {
                    ItemattribType attribType = new ItemattribType();
                    Element attribElement = (Element) attribNode;
                    attribType.setName(DomUtil.getNodeValue("name",
                            attribNode.getChildNodes()));
                    attribType.setVal(DomUtil.getNodeValue("val",
                            attribNode.getChildNodes()));
                    attribType.setDesc(DomUtil.getNodeValue("desc",
                            attribNode.getChildNodes()));

                    String listType = "";
                    listType = DomUtil
                            .getAttributeValue("attid", attribElement);
                    if (StringUtils.isEmpty(listType)) {
                        listType = DomUtil.getAttributeValue("listType",
                                attribElement);
                    }
                    attribType.setAttid(listType);

                    itemAttribTypes.add(attribType);
                }
                attribListType.getAttrib().addAll(itemAttribTypes);
                itemType.setAttriblist(attribListType);
            }
        } catch (ParserConfigurationException e) {
            LOGGER.error(
                    "Error in perser configuration for AssessmentitemType : "
                            + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.error(
                    "Error in parsing AssessmentitemType : " + e.getMessage(),
                    e);
        } catch (IOException e) {
            LOGGER.error(
                    "IO Error in unmershalling AssessmentitemType : "
                            + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error(
                    "Error in unmershalling AssessmentitemType : "
                            + e.getMessage(), e);
        }
        return itemType;
    }

    public static TutorialitemType readTutorialFromString(String itemContent) {
        TutorialreleaseType itemRelease = JAXBUtil
                .<TutorialreleaseType> unmershall(itemContent,
                        TutorialreleaseType.class);
        if (itemRelease != null) {
            return itemRelease.getItem();
        }
        return null;
    }

    public static TutorialitemType readTutorialFromPath(String filePath) {
        try {
            String itemContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            TutorialreleaseType itemRelease = JAXBUtil
                    .<TutorialreleaseType> unmershall(itemContent,
                            TutorialreleaseType.class);
            if (itemRelease != null) {
                return itemRelease.getItem();
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error in unmershalling TutorialitemType : "
                            + e.getMessage(), e);
        }
        return null;
    }

    public static WordlistitemType readWordlistFromString(String itemContent) {
        WordlistreleaseType itemRelease = JAXBUtil
                .<WordlistreleaseType> unmershall(itemContent,
                        WordlistreleaseType.class);
        if (itemRelease != null) {
            return itemRelease.getItem();
        }
        return null;
    }

    public static WordlistitemType readWordlistFromPath(String filePath) {
        try {
            String itemContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            WordlistreleaseType itemRelease = JAXBUtil
                    .<WordlistreleaseType> unmershall(itemContent,
                            WordlistreleaseType.class);
            if (itemRelease != null) {
                return itemRelease.getItem();
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error in unmershalling WordlistitemType : "
                            + e.getMessage(), e);
        }
        return null;
    }

    public static AssessmentitemType readItemFromString(String itemContent) {
        AssessmentitemreleaseType itemRelease = JAXBUtil
                .<AssessmentitemreleaseType> unmershall(itemContent,
                        AssessmentitemreleaseType.class);
        if (itemRelease != null) {
            return itemRelease.getItem();
        }
        return null;
    }

    public static String readItemString(InputStream inputStream) {
        return FileUtil.readToString(inputStream, false);
    }

    public static String saveItemResource(InputStream inputStream,
            String fileName, int itemBankId, String itemName) {
        try {

            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File imageDir = new File(instanceDir, "attachments");
            if (!imageDir.exists()) {
                imageDir.mkdir();
            }
            File libDir = new File(imageDir, "lib" + itemBankId);
            if (!libDir.exists()) {
                libDir.mkdir();
            }

            File itemDir = new File(libDir, itemName);
            if (!itemDir.exists()) {
                itemDir.mkdir();
            }

            File resourceFile = new File(itemDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.writeToFile(inputStream,
                        resourceFile.getAbsolutePath(), false);

            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Error in saving Item resource : " + e.getMessage(), e);
            return null;
        }
    }

    public static String savePassageMedia(String sourcePath, String fileName,
            int itemBankId, int passageId) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File passagesDir = new File(instanceDir, "passages");

            File libDir = new File(passagesDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File mediaDir = new File(libDir, "media");
            FileUtil.createDir(mediaDir);

            File passageDir = new File(mediaDir, "p" + passageId);
            FileUtil.createDir(passageDir);

            File resourceFile = new File(passageDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save item asset from path " + sourcePath
                    + " file " + fileName, e);
            return null;
        }
    }

    public static String savePassageBody(String stemContent, int itemBankId,
            int passageId) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File passagesDir = new File(instanceDir, "passages");

            File libDir = new File(passagesDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File resourceFile = new File(libDir, "p" + passageId + ".htm");
            if (!resourceFile.exists()) {
                FileUtils.write(resourceFile, stemContent, false);
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save passage body to file p" + passageId
                    + ".htm", e);
            return null;
        }
    }

    public static String savePassageImage(String sourcePath, String fileName,
            int itemBankId, int passageId) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File passagesDir = new File(instanceDir, "passages");

            File libDir = new File(passagesDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File imageDir = new File(libDir, "images");
            FileUtil.createDir(imageDir);

            File passageDir = new File(imageDir, "p" + passageId);
            FileUtil.createDir(passageDir);

            File resourceFile = new File(passageDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save item asset from path " + sourcePath
                    + " file " + fileName, e);
            return null;
        }
    }

    public static String saveItemAsset(String sourcePath, String fileName,
            int itemBankId, String itemName) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");

            File imageDir = new File(instanceDir, "images");
            FileUtil.createDir(imageDir);

            File libDir = new File(imageDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File itemDir = new File(libDir, itemName);
            FileUtil.createDir(itemDir);

            File resourceFile = new File(itemDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save item asset from path " + sourcePath
                    + " file " + fileName, e);
            return null;
        }
    }

    public static String saveItemAttachment(String sourcePath, String fileName,
            int itemBankId, String itemName) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");

            File attachmentDir = new File(instanceDir, "attachments");
            FileUtil.createDir(attachmentDir);

            File libDir = new File(attachmentDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File itemDir = new File(libDir, itemName);
            FileUtil.createDir(itemDir);

            File resourceFile = new File(itemDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save item attachment from path "
                    + sourcePath + " file " + fileName, e);
            return null;
        }
    }

    public static String saveWordList(String sourcePath, String fileName,
            int itemBankId, String itemName) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");

            File wordListDir = new File(instanceDir, "wordlists");
            FileUtil.createDir(wordListDir);

            File libDir = new File(wordListDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File itemDir = new File(libDir, itemName);
            FileUtil.createDir(itemDir);

            File resourceFile = new File(itemDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();

        } catch (Exception e) {
            LOGGER.error("Unable to save wordlist from path " + sourcePath
                    + " file " + fileName, e);
            return null;
        }
    }

    public static String saveTutorial(String sourcePath, String fileName,
            int itemBankId, String itemName) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");

            File tutorialDir = new File(instanceDir, "tutorials");
            FileUtil.createDir(tutorialDir);

            File libDir = new File(tutorialDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File itemDir = new File(libDir, itemName);
            FileUtil.createDir(itemDir);

            File resourceFile = new File(itemDir, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();

        } catch (Exception e) {
            LOGGER.error("Unable to save tutorial from path " + sourcePath
                    + " file " + fileName, e);
            return null;
        }
    }

}
