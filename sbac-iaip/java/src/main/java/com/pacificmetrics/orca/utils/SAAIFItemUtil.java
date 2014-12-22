package com.pacificmetrics.orca.utils;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.entities.ItemInteraction;
import com.pacificmetrics.orca.entities.ItemStandard;
import com.pacificmetrics.orca.export.saaif.ItemAttribConstants;
import com.pacificmetrics.orca.export.saaif.PassageAttribConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.saaif.item1.AssessmentitemType;
import com.pacificmetrics.saaif.item1.AttachmentType;
import com.pacificmetrics.saaif.item1.ItemcontentType;
import com.pacificmetrics.saaif.metadata.MetadataFieldConstants;
import com.pacificmetrics.saaif.metadata1.SmarterAppMetadataType.StandardPublication;
import com.pacificmetrics.saaif.passage1.PassageType;
import com.pacificmetrics.saaif.passage1.PassagecontentType;
import com.pacificmetrics.saaif.passage1.StemType;
import com.pacificmetrics.saaif.tutorial.TutorialcontentType;
import com.pacificmetrics.saaif.tutorial.TutorialitemType;

public class SAAIFItemUtil {

    private static final Logger LOGGER = Logger.getLogger(SAAIFItemUtil.class
            .getCanonicalName());

    private SAAIFItemUtil() {
    }

    public static String getItemExternalId(String filePath) {
        String externalId = null;
        try {
            String xmlContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));

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
                externalId = DomUtil.getAttributeValue("id", itemElement);
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return externalId;
    }

    public static String getItemExternalIdFromString(String xmlContent) {
        String externalId = null;
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
                externalId = DomUtil.getAttributeValue("id", itemElement);
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return externalId;
    }

    public static String getPassageExternalId(String xmlContent) {
        String externalId = null;
        try {
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);

            Node itemReleaseNode = document.getFirstChild();

            Node itemNode = DomUtil.getNode("passage",
                    itemReleaseNode.getChildNodes());
            if (itemNode != null) {
                Element itemElement = (Element) itemNode;
                externalId = DomUtil.getAttributeValue("id", itemElement);
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return externalId;
    }

    public static String setItemAttribute(String xmlContent, String id,
            String bankKey, String version, String description,
            String contentArea, String gradeLevel) {
        String xmlItemContent = null;
        try {
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);

            String encoding = document.getXmlEncoding();

            Node itemReleaseNode = document.getFirstChild();

            Node itemNode = DomUtil.getNode("item",
                    itemReleaseNode.getChildNodes());
            if (itemNode != null) {
                Element itemElement = (Element) itemNode;
                DomUtil.setAttributeValue("id", id, itemElement);
                DomUtil.setAttributeValue("version", version, itemElement);
            }

            Node attributeListNode = DomUtil.getNode("attriblist",
                    itemNode.getChildNodes());
            if (attributeListNode != null) {
                List<Node> attributeNodeList = DomUtil.getNodes("attrib",
                        attributeListNode.getChildNodes());
                if (CollectionUtils.isNotEmpty(attributeNodeList)) {
                    for (Node attributeNode : attributeNodeList) {
                        Element attributeElement = (Element) attributeNode;
                        String attridValue = DomUtil.getAttributeValue(
                                "listType", attributeElement);
                        // item id
                        if (StringUtils.isNotEmpty(id)
                                && ItemAttribConstants.ITEM_ID
                                        .equals(attridValue)) {
                            Node valueNode = DomUtil.getNode("val",
                                    attributeNode.getChildNodes());
                            DomUtil.setNodeTextValue(id, valueNode);
                        }
                        // item description
                        if (StringUtils.isNotEmpty(description)
                                && ItemAttribConstants.ITEM_DESC
                                        .equals(attridValue)) {
                            Node valueNode = DomUtil.getNode("val",
                                    attributeNode.getChildNodes());
                            DomUtil.setNodeTextValue(description, valueNode);
                        }
                        // item content area
                        if (StringUtils.isNotEmpty(contentArea)
                                && ItemAttribConstants.ITEM_SUBJECT
                                        .equals(attridValue)) {
                            Node valueNode = DomUtil.getNode("val",
                                    attributeNode.getChildNodes());
                            DomUtil.setNodeTextValue(contentArea, valueNode);
                        }
                        // item grade
                        if (StringUtils.isNotEmpty(gradeLevel)
                                && ItemAttribConstants.ITEM_GRADE
                                        .equals(attridValue)) {
                            Node valueNode = DomUtil.getNode("val",
                                    attributeNode.getChildNodes());
                            DomUtil.setNodeTextValue(gradeLevel, valueNode);
                        }
                    }
                }
            }

            Transformer tf = TransformerFactory.newInstance().newTransformer();
            tf.setOutputProperty(OutputKeys.ENCODING,
                    encoding != null ? encoding : "UTF-8");
            tf.setOutputProperty(OutputKeys.INDENT, "yes");
            tf.setOutputProperty("{http://xml.apache.org/xslt}indent-amount",
                    "2");
            tf.setOutputProperty(OutputKeys.METHOD, "xml");
            Writer out = new StringWriter();
            tf.transform(new DOMSource(document), new StreamResult(out));
            xmlItemContent = out.toString();

        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerFactoryConfigurationError e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return xmlItemContent;
    }

    public static String setPassageAttribute(String xmlContent, String id,
            String bankKey, String version, String subject) {
        String xmlPassageContent = null;
        try {
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);

            String encoding = document.getXmlEncoding();

            Node itemReleaseNode = document.getFirstChild();

            Node passageNode = DomUtil.getNode("passage",
                    itemReleaseNode.getChildNodes());
            if (passageNode != null) {
                Element passageElement = (Element) passageNode;
                DomUtil.setAttributeValue("id", id, passageElement);

                Node attributeListNode = DomUtil.getNode("attriblist",
                        passageNode.getChildNodes());
                if (attributeListNode != null) {
                    List<Node> attributeNodeList = DomUtil.getNodes("attrib",
                            attributeListNode.getChildNodes());
                    if (CollectionUtils.isNotEmpty(attributeNodeList)) {
                        for (Node attributeNode : attributeNodeList) {
                            Element attributeElement = (Element) attributeNode;
                            String attridValue = DomUtil.getAttributeValue(
                                    "listType", attributeElement);
                            // passage id
                            if (StringUtils.isNotEmpty(id)
                                    && PassageAttribConstants.PASSAGE_ID
                                            .equals(attridValue)) {
                                Node valueNode = DomUtil.getNode("value",
                                        attributeNode.getChildNodes());
                                DomUtil.setNodeTextValue(id, valueNode);
                            }
                            // passage subject
                            if (StringUtils.isNotEmpty(subject)
                                    && PassageAttribConstants.PASSAGE_SUBJECT
                                            .equals(attridValue)) {
                                Node valueNode = DomUtil.getNode("value",
                                        attributeNode.getChildNodes());
                                DomUtil.setNodeTextValue(subject, valueNode);
                            }
                        }
                    }
                }

                Transformer tf = TransformerFactory.newInstance()
                        .newTransformer();
                tf.setOutputProperty(OutputKeys.ENCODING,
                        encoding != null ? encoding : "UTF-8");
                tf.setOutputProperty(OutputKeys.INDENT, "yes");
                tf.setOutputProperty(
                        "{http://xml.apache.org/xslt}indent-amount", "2");
                tf.setOutputProperty(OutputKeys.METHOD, "xml");
                Writer out = new StringWriter();
                tf.transform(new DOMSource(document), new StreamResult(out));
                xmlPassageContent = out.toString();
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerFactoryConfigurationError e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return xmlPassageContent;
    }

    public static String setPassageMetadataAttribute(String xmlContent,
            String id, String subject, String genre, String publicationStatus,
            String gradeLevel, String minimumGrade, String maximumGrade) {
        String xmlMetadataContent = null;
        try {
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);

            String encoding = document.getXmlEncoding();

            Node metadataNode = document.getFirstChild();

            Node saMetadataNode = DomUtil.getNode("smarterAppMetadata",
                    metadataNode.getChildNodes());

            // identifier
            Node identifierNode = DomUtil.getNode(
                    MetadataFieldConstants.IDENTIFIER,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(id) && identifierNode != null) {
                DomUtil.setNodeTextValue(id, identifierNode);
            } else if (StringUtils.isNotEmpty(id)) {
                identifierNode = document
                        .createElement(MetadataFieldConstants.IDENTIFIER);
                identifierNode.setTextContent(id);
                saMetadataNode.appendChild(identifierNode);
            }

            // subject
            Node subjectNode = DomUtil.getNode(MetadataFieldConstants.SUBJECT,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(subject) && subjectNode != null) {
                DomUtil.setNodeTextValue(subject, subjectNode);
            } else if (StringUtils.isNotEmpty(subject)) {
                subjectNode = document
                        .createElement(MetadataFieldConstants.SUBJECT);
                subjectNode.setTextContent(subject);
                saMetadataNode.appendChild(subjectNode);
            }

            // grade level
            Node gradeNode = DomUtil.getNode(
                    MetadataFieldConstants.INTENDEDGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(gradeLevel) && gradeNode != null) {
                DomUtil.setNodeTextValue(gradeLevel, gradeNode);
            } else if (StringUtils.isNotEmpty(gradeLevel)) {
                gradeNode = document
                        .createElement(MetadataFieldConstants.INTENDEDGRADE);
                gradeNode.setTextContent(gradeLevel);
                saMetadataNode.appendChild(gradeNode);
            }

            // maximum grade
            Node maxGradeNode = DomUtil.getNode(
                    MetadataFieldConstants.MAXIMUMGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(maximumGrade) && maxGradeNode != null) {
                DomUtil.setNodeTextValue(maximumGrade, maxGradeNode);
            } else if (StringUtils.isNotEmpty(maximumGrade)) {
                maxGradeNode = document
                        .createElement(MetadataFieldConstants.MAXIMUMGRADE);
                maxGradeNode.setTextContent(maximumGrade);
                saMetadataNode.appendChild(maxGradeNode);
            }

            // minimum grade level
            Node minGradeNode = DomUtil.getNode(
                    MetadataFieldConstants.MINIMUMGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(minimumGrade) && minGradeNode != null) {
                DomUtil.setNodeTextValue(minimumGrade, minGradeNode);
            } else if (StringUtils.isNotEmpty(minimumGrade)) {
                minGradeNode = document
                        .createElement(MetadataFieldConstants.MINIMUMGRADE);
                minGradeNode.setTextContent(minimumGrade);
                saMetadataNode.appendChild(minGradeNode);
            }

            // genre
            Node genreNode = DomUtil.getNode(
                    MetadataFieldConstants.STIMULUSGENRE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(genre) && genreNode != null) {
                DomUtil.setNodeTextValue(genre, genreNode);
            } else if (StringUtils.isNotEmpty(genre)) {
                genreNode = document
                        .createElement(MetadataFieldConstants.STIMULUSGENRE);
                genreNode.setTextContent(genre);
                saMetadataNode.appendChild(genreNode);
            }

            // publication status
            Node administrationDateNode = DomUtil.getNode(
                    MetadataFieldConstants.ADMINISTRATIONDATE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(publicationStatus)
                    && administrationDateNode != null) {
                DomUtil.setNodeTextValue(publicationStatus,
                        administrationDateNode);
            } else if (StringUtils.isNotEmpty(publicationStatus)) {
                administrationDateNode = document
                        .createElement(MetadataFieldConstants.STIMULUSGENRE);
                administrationDateNode.setTextContent(publicationStatus);
                saMetadataNode.appendChild(administrationDateNode);
            }

            Transformer tf = TransformerFactory.newInstance().newTransformer();
            tf.setOutputProperty(OutputKeys.METHOD, "xml");
            tf.setOutputProperty(OutputKeys.ENCODING,
                    encoding != null ? encoding : "UTF-8");
            tf.setOutputProperty(OutputKeys.INDENT, "yes");
            tf.setOutputProperty("{http://xml.apache.org/xslt}indent-amount",
                    "2");
            tf.setOutputProperty(OutputKeys.METHOD, "xml");
            Writer out = new StringWriter();
            tf.transform(new DOMSource(document), new StreamResult(out));
            xmlMetadataContent = out.toString();

        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerFactoryConfigurationError e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return xmlMetadataContent;
    }

    public static String setItemMetadataAttribute(String xmlContent, String id,
            String externalId, String subject, String maximumNoOfPoint,
            String educationDifficulties, String depthOfKnowdledge,
            String publicationStatus, String gradeLevel, String minimumGrade,
            String maximumGrade, String primaryStandard,
            List<ItemStandard> itemStandardList, String descriptor) {
        String xmlMetadataContent = null;
        try {
        	String[] metadataTags = new String[] {
        			MetadataFieldConstants.IDENTIFIER, MetadataFieldConstants.STANDARDPUBLICATION,
        			MetadataFieldConstants.MAXNOOFPOINTS, MetadataFieldConstants.EDUCATIONALDIFFICULTY        			
        	};
        	
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);
            
            for (String string : metadataTags) {
            	// retrieve the element 'head'
            	NodeList list = document.getElementsByTagName(string);
            	for (; 0 < list.getLength();) {
	    			Element element = (Element) document.getElementsByTagName(
	    					string).item(0);
	    			// remove the specific node
	    				element.getParentNode().removeChild(element);
            	}
			} 
         
            
            String encoding = document.getXmlEncoding();

            Node metadataNode = document.getFirstChild();

            Node saMetadataNode = DomUtil.getNode("smarterAppMetadata",
                    metadataNode.getChildNodes());

            if (StringUtils.isNotEmpty(externalId)) {
                Node alternateIdNode = document
                        .createElement("AlternateIdentifier");

                Node alternativeIdNodeValue = document
                        .createTextNode(externalId);
                alternateIdNode.appendChild(alternativeIdNodeValue);

                Node interactionTypeNode = DomUtil.getNode("InteractionType",
                        metadataNode.getChildNodes());
                saMetadataNode.insertBefore(alternateIdNode,
                        interactionTypeNode);
            }

            // identifier
            Node identifierNode = DomUtil.getNode(
                    MetadataFieldConstants.IDENTIFIER,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(id) && identifierNode != null) {
                DomUtil.setNodeTextValue(id, identifierNode);
            } else if (StringUtils.isNotEmpty(id)) {
                identifierNode = document
                        .createElement(MetadataFieldConstants.IDENTIFIER);
                identifierNode.setTextContent(id);
                saMetadataNode.appendChild(identifierNode);
            }

         // SmarterAppItemDescriptor
            Node smarterAppItemDescriptorNode = DomUtil.getNode(
                    MetadataFieldConstants.ITEMDESCRIPTOR,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(descriptor) && smarterAppItemDescriptorNode != null) {
                DomUtil.setNodeTextValue(descriptor, smarterAppItemDescriptorNode);
            } else if (StringUtils.isNotEmpty(descriptor)) {
                identifierNode = document
                        .createElement(MetadataFieldConstants.ITEMDESCRIPTOR);
                smarterAppItemDescriptorNode.setTextContent(descriptor);
                saMetadataNode.appendChild(smarterAppItemDescriptorNode);
            }
            
            // subject
            Node subjectNode = DomUtil.getNode(MetadataFieldConstants.SUBJECT,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(subject) && subjectNode != null) {
                DomUtil.setNodeTextValue(subject, subjectNode);
            } else if (StringUtils.isNotEmpty(subject)) {
                subjectNode = document
                        .createElement(MetadataFieldConstants.SUBJECT);
                subjectNode.setTextContent(subject);
                saMetadataNode.appendChild(subjectNode);
            }

            // grade level
            Node gradeNode = DomUtil.getNode(
                    MetadataFieldConstants.INTENDEDGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(gradeLevel) && gradeNode != null) {
                DomUtil.setNodeTextValue(gradeLevel, gradeNode);
            } else if (StringUtils.isNotEmpty(gradeLevel)) {
                gradeNode = document
                        .createElement(MetadataFieldConstants.INTENDEDGRADE);
                gradeNode.setTextContent(gradeLevel);
                saMetadataNode.appendChild(gradeNode);
            }

            // maximum grade
            Node maxGradeNode = DomUtil.getNode(
                    MetadataFieldConstants.MAXIMUMGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(maximumGrade) && maxGradeNode != null) {
                DomUtil.setNodeTextValue(maximumGrade, maxGradeNode);
            } else if (StringUtils.isNotEmpty(maximumGrade)) {
                maxGradeNode = document
                        .createElement(MetadataFieldConstants.MAXIMUMGRADE);
                maxGradeNode.setTextContent(maximumGrade);
                saMetadataNode.appendChild(maxGradeNode);
            }

            // minimum grade level
            Node minGradeNode = DomUtil.getNode(
                    MetadataFieldConstants.MINIMUMGRADE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(minimumGrade) && minGradeNode != null) {
                DomUtil.setNodeTextValue(minimumGrade, minGradeNode);
            } else if (StringUtils.isNotEmpty(minimumGrade)) {
                minGradeNode = document
                        .createElement(MetadataFieldConstants.MINIMUMGRADE);
                minGradeNode.setTextContent(minimumGrade);
                saMetadataNode.appendChild(minGradeNode);
            }

            // Education difficulty
            Node educationDifficultyNode = DomUtil.getNode(
                    MetadataFieldConstants.EDUCATIONALDIFFICULTY,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(educationDifficulties)
                    && educationDifficultyNode != null) {
                DomUtil.setNodeTextValue(educationDifficulties,
                        educationDifficultyNode);
            } else if (StringUtils.isNotEmpty(educationDifficulties)) {
                educationDifficultyNode = document
                        .createElement(MetadataFieldConstants.EDUCATIONALDIFFICULTY);
                educationDifficultyNode.setTextContent(educationDifficulties);
                saMetadataNode.appendChild(educationDifficultyNode);
            }

            // Depth of Knowledge
            Node depthOfKnowdlegeNode = DomUtil.getNode(
                    MetadataFieldConstants.DEPTHOFKNOWLEDGE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(depthOfKnowdledge)
                    && depthOfKnowdlegeNode != null) {
                DomUtil.setNodeTextValue(depthOfKnowdledge,
                        depthOfKnowdlegeNode);
            } else if (StringUtils.isNotEmpty(depthOfKnowdledge)) {
                depthOfKnowdlegeNode = document
                        .createElement(MetadataFieldConstants.DEPTHOFKNOWLEDGE);
                depthOfKnowdlegeNode.setTextContent(depthOfKnowdledge);
                saMetadataNode.appendChild(depthOfKnowdlegeNode);
            }

            // Administration date
            Node administrationDateNode = DomUtil.getNode(
                    MetadataFieldConstants.ADMINISTRATIONDATE,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(publicationStatus)
                    && administrationDateNode != null) {
                DomUtil.setNodeTextValue(publicationStatus,
                        administrationDateNode);
            } else if (StringUtils.isNotEmpty(publicationStatus)) {
                administrationDateNode = document
                        .createElement(MetadataFieldConstants.ADMINISTRATIONDATE);
                administrationDateNode.setTextContent(publicationStatus);
                saMetadataNode.appendChild(administrationDateNode);
            }

            // Maximum no of Points
            Node maximumPointNode = DomUtil.getNode(
                    MetadataFieldConstants.MAXNOOFPOINTS,
                    saMetadataNode.getChildNodes());
            if (StringUtils.isNotEmpty(maximumNoOfPoint)
                    && maximumPointNode != null) {
                DomUtil.setNodeTextValue(maximumNoOfPoint, maximumPointNode);
            } else if (StringUtils.isNotEmpty(maximumNoOfPoint)) {
                maximumPointNode = document
                        .createElement(MetadataFieldConstants.MAXNOOFPOINTS);
                maximumPointNode.setTextContent(maximumNoOfPoint);
                saMetadataNode.appendChild(maximumPointNode);
            }

            // Primary Standard
            Node primaryStandardNode = DomUtil.getNode(
                    MetadataFieldConstants.PRIMARYSTANDARD,
                    saMetadataNode.getChildNodes());            
            Node standardPublication = document.createElement(
                    MetadataFieldConstants.STANDARDPUBLICATION);
            String publication = primaryStandard != null ? primaryStandard.split(":")[0] : "";
            Node publicationNode = document.createElement(
                    MetadataFieldConstants.PUBLICATION);
            publicationNode.setTextContent(publication);
            standardPublication.appendChild(publicationNode);
            if (StringUtils.isNotEmpty(primaryStandard)
                    && primaryStandardNode != null) {
                DomUtil.setNodeTextValue(primaryStandard, primaryStandardNode);
            } else if (StringUtils.isNotEmpty(primaryStandard)) {           	
                primaryStandardNode = document
                        .createElement(MetadataFieldConstants.PRIMARYSTANDARD);
                primaryStandardNode.setTextContent(primaryStandard);                
            }
            standardPublication.appendChild(primaryStandardNode);

            // Secondary Standard
            List<Node> secondaryStandardNodeList = DomUtil.getNodes(
                    MetadataFieldConstants.SECONDARYSTANDARD,
                    saMetadataNode.getChildNodes());
            if (CollectionUtils.isNotEmpty(secondaryStandardNodeList)) {
                for (Node secondaryStandardNode : secondaryStandardNodeList) {
                    saMetadataNode.removeChild(secondaryStandardNode);
                }
            }
            if (CollectionUtils.isNotEmpty(itemStandardList)) {
                Node secondaryStandardNode = null;
                for (ItemStandard itemStandard : itemStandardList) {
                    secondaryStandardNode = document
                            .createElement(MetadataFieldConstants.SECONDARYSTANDARD);
                    secondaryStandardNode.setTextContent(itemStandard
                            .getStandard());
                    standardPublication.appendChild(secondaryStandardNode);
                }
            }
            
            saMetadataNode.appendChild(standardPublication);
            
            Transformer tf = TransformerFactory.newInstance().newTransformer();
            tf.setOutputProperty(OutputKeys.ENCODING,
                    encoding != null ? encoding : "UTF-8");
            tf.setOutputProperty(OutputKeys.INDENT, "yes");
            tf.setOutputProperty("{http://xml.apache.org/xslt}indent-amount",
                    "2");
            tf.setOutputProperty(OutputKeys.METHOD, "xml");
            Writer out = new StringWriter();
            tf.transform(new DOMSource(document), new StreamResult(out));
            xmlMetadataContent = out.toString();

        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerFactoryConfigurationError e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (TransformerException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return xmlMetadataContent;
    }

    public static boolean isAttachmentResource(AssessmentitemType item,
            String fileName) {
        if (item != null && CollectionUtils.isNotEmpty(item.getContent())) {
            for (ItemcontentType content : item.getContent()) {
                if (SAAIFPackageConstants.CONTENT_LANGUAGE_ENG.equals(content
                        .getLanguage())
                        && content.getAttachmentlist() != null
                        && CollectionUtils.isNotEmpty(content
                                .getAttachmentlist().getAttachment())) {
                    for (AttachmentType attachment : content
                            .getAttachmentlist().getAttachment()) {
                        if (StringUtils.equalsIgnoreCase(fileName,
                                attachment.getFile())) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    public static boolean isAttachmentResource(TutorialitemType item,
            String fileName) {
        if (item != null && CollectionUtils.isNotEmpty(item.getContent())) {
            for (TutorialcontentType content : item.getContent()) {
                if (SAAIFPackageConstants.CONTENT_LANGUAGE_ENG.equals(content
                        .getLanguage())
                        && content.getAttachmentlist() != null
                        && CollectionUtils.isNotEmpty(content
                                .getAttachmentlist().getAttachment())) {
                    for (com.pacificmetrics.saaif.tutorial.AttachmentType attachment : content
                            .getAttachmentlist().getAttachment()) {
                        if (StringUtils.equalsIgnoreCase(fileName,
                                attachment.getFile())) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    public static boolean isAttachmentResource(PassageType passage,
            String fileName) {
        if (passage != null && CollectionUtils.isNotEmpty(passage.getContent())) {
            for (PassagecontentType content : passage.getContent()) {
                if (SAAIFPackageConstants.CONTENT_LANGUAGE_ENG.equals(content
                        .getLanguage())
                        && content.getAttachmentlist() != null
                        && CollectionUtils.isNotEmpty(content
                                .getAttachmentlist().getAttachment())) {
                    for (com.pacificmetrics.saaif.passage1.AttachmentType attachment : content
                            .getAttachmentlist().getAttachment()) {
                        if (StringUtils.equalsIgnoreCase(fileName,
                                attachment.getFile())) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    public static String getPassageContentAsHtml(StemType stem) {
        // TODO : implement passage type
        return "";
    }

    public static String getFormatOrTypeOfItem(String filePath) {
        String formatOrType = "";
        try {
            String xmlContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));

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
                formatOrType = DomUtil.getAttributeValue("format", itemElement);
                if (StringUtils.isEmpty(formatOrType)) {
                    formatOrType = DomUtil.getAttributeValue("type",
                            itemElement);
                }
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return formatOrType;
    }

    public static String getFormatOrTypeOfItemFromString(String xmlContent) {
        String formatOrType = "";
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
                formatOrType = DomUtil.getAttributeValue("format", itemElement);
                if (StringUtils.isEmpty(formatOrType)) {
                    formatOrType = DomUtil.getAttributeValue("type",
                            itemElement);
                }
            }
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (SAXException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        return formatOrType;
    }

    public static String getSBAIFItemFormatFromORCA(
            List<ItemInteraction> itemInteraction) {
        String format = "";
        int count = 0;
        if (itemInteraction != null && !itemInteraction.isEmpty()) {
            int typeId = itemInteraction.get(count).getType();
            format = SAAIFPackageConstants.ITEM_FORMAT.get(typeId);

            List<String> answerChoiceList = null;
            if ("MC".equalsIgnoreCase(format)) {
                answerChoiceList = new ArrayList<String>(
                        Arrays.asList(itemInteraction.get(count).getCorrect() != null ? itemInteraction
                                .get(count).getCorrect().split(" ")
                                : new String[] { "" }));
                if (answerChoiceList.size() > 1) {
                    format = "MS";
                }
            }
        }

        return format;
    }

}
