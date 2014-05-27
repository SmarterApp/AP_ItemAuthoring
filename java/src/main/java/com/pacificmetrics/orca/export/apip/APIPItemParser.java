/**
 * 
 */
package com.pacificmetrics.orca.export.apip;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;
import java.util.logging.Logger;

import javax.naming.InitialContext;
import javax.naming.NamingException;
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
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.apache.commons.io.FileUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.tidy.Tidy;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.AccessibilityItemServices;
import com.pacificmetrics.orca.ejb.AccessibilityPassageServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.InclusionOrder;
import com.pacificmetrics.orca.entities.InclusionOrderElement;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.entities.ItemFragment;
import com.pacificmetrics.orca.entities.ItemInteraction;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.Rubric;
import com.pacificmetrics.orca.utils.XMLUtil;

/**
 * This class is not thread safe.
 * 
 * @author maumock
 * 
 */
public class APIPItemParser extends XMLUtil {
    private boolean validate = false;
    private static final Logger log = Logger.getLogger(APIPItemParser.class.getName());
    private static final String RESOURCES = "//:img/@src | //:stylesheet/@href | //:object/@data | //:div[starts-with(@class, 'orca:media')]/@class |/:assessmentItem/apip:apipAccessibility//apip:fileHref/node()";
    // XXX not substring-ing-after orca:media
    //private static final String RESOURCES = "//:img/@src | //:stylesheet/@href | //:div[starts-with(@class, 'orca:media')]/@class[substring-after(., 'orca:media')] |/:assessmentItem/apip:apipAccessibility//apip:fileHref/node()";
    // XXX java.lang.ClassCastException: com.sun.org.apache.xpath.internal.objects.XString cannot be cast to com.sun.org.apache.xpath.internal.objects.XNodeSet
    //private static final String RESOURCES = "//:img/@src | //:stylesheet/@href | substring-after(//:div[starts-with(@class, 'orca:media')]/@class, 'orca:media') |/:assessmentItem/apip:apipAccessibility//apip:fileHref/node()";
    private static final String INTERACTION_TYPES = "//:*[substring(name(),string-length(name())-10)='Interaction']";
    private static final String TIME_DEPENDENT = "/:assessmentItem/@timeDependent";
    private static final String FEEDBACK = "//:feedbackBlock/@outcomeIdentifier | //:feedbackInline/@outcomeIdentifier | //:modalFeedback/@outcomeIdentifier";
    private static final String TOOL_VERSION = "/:assessmentItem/@toolVersion";
    private static final String TOOL_NAME = "/:assessmentItem/@toolName";

    private static final String CONTENT_BASE = ServerConfiguration.getProperty(ServerConfiguration.PASSAGES_DIRECTORY);

    public APIPItemParser() throws ParserConfigurationException {
        addXPathNS("", "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1");
        addXPathNS("apip", "http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0");
    }

    public APIPItemParser(boolean validate) throws SAXException, ParserConfigurationException {
        this();
        this.validate = validate;
        if (this.validate) {
            setSchema("http://www.w3.org/2001/XMLSchema");
        }
    }

    public APIPItem getAPIPItem(final Item item) throws ParserConfigurationException, SAXException, IOException,
            XPathExpressionException, TransformerException {
        APIPItem out = new APIPItem();

        log.info("Checking item validity");
        if (item == null) {
            throw new IOException("A null item was passed to the item parser.");
        }

        if (item.getQtiData() == null || item.getQtiData().trim().length() == 0) {
            // generate item qti if it doesn't exist...
            // FIXME: hacky-hacky, but for now use -> xjc jaxb cannot generate
            // from qti xsd [getting NPE]
            String qtiData = "<assessmentItem "
                    + "xmlns=\"http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1\" "
                    + "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
                    + "xmlns:apip=\"http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0\" "
                    + "xsi:schemaLocation=\"http://www.w3.org/1998/Math/MathML "
                    + "http://www.w3.org/Math/XMLSchema/mathml2/mathml2.xsd "
                    + "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1 "
                    + "http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_qtiitemv2p1_v1p0.xsd "
                    + "http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0 "
                    + "http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_qtiextv2p1_v1p0.xsd\" "
                    + "identifier=\"" + item.getExternalId() + "\" " + "title=\"" + item.getDescription() + "\" "
                    + "adaptive=\"false\" " + "timeDependent=\"false\">" + "<itemBody></itemBody>"
                    + "<apip:apipAccessibility/>" + "</assessmentItem>";

            item.setQtiData(qtiData);
        }
        
        // validating original qti
        validate(item.getQtiData());

        // FIXME: may not be optimal place/algorithm to parse itembody content,
        // but done for expediency
        buildItemBody(item);
        buildAPIP(item);

        /*
        // read in the item qti
        DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes()));
        doc.normalizeDocument();

        // write out item qti
        TransformerFactory transformerFactory = TransformerFactory.newInstance();
        transformerFactory.setAttribute("indent-number", 4);
        Transformer transformer = transformerFactory.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        StringWriter writer = new StringWriter();
        transformer.transform(new DOMSource(doc), new StreamResult(writer));
        item.setQtiData(writer.getBuffer().toString());
        */
        
        log.info(item.getQtiData());

        if (this.validate) {
            log.info("Validating schematron rules against QTI XML");
            validate(item.getQtiData());
        }

        log.info("Loading QTI XML from item");
        //log.info(item.getQtiData());
        load(item.getQtiData());

        log.info("Verifying there are no parse errors during XML loading");
        if (getErrorHandler().hasError()) {
            if (getErrorHandler().getFatal().size() > 0) {
                throw new SAXException(getErrorHandler().getFatal().get(0));
            } else {
                throw new SAXException(getErrorHandler().getErrors().get(0));
            }
        }

        log.info("Setting attributes defined in the QTI XML.");
        out.setComposite(isComposite());
        out.setFeedbackType(getFeedbackType());
        out.setInteractionTypes(getInteractionTypes());
        out.setResources(getResources());
        out.setSolutionAvailable(isSolutionAvailable());
        out.setTimeDependent(isTimeDependent());
        out.setToolName(getToolName());
        out.setToolVersion(getToolVersion());
        out.setToolVendor(getToolVendor());

        log.info("Setting attributes defined in the item.");
        out.setVersion(item.getDevState() == null ? "UNDEFINED" : item.getDevState().getName());
        out.setId(item.getExternalId());

        return out;
    }

    private void correctMediaElements(final Document doc, final XPath xPath) throws XPathExpressionException {
        // replace internal representation with QTI
        final NodeList mediaNodes = (NodeList) xPath.evaluate("//div[starts-with(@class, 'orca:media')]", doc,
                XPathConstants.NODESET);
        
        final int numMediaNodes = mediaNodes.getLength();
        
        for (int i = 0; i < numMediaNodes; i++) {
            final Element mediaElement = (Element)mediaNodes.item(i);
            
            final Element mediaObject = doc.createElement("object");
            final String mediaFileName = mediaElement.getAttribute("class").substring("orca:media:".length());
            mediaObject.setAttribute("data", mediaFileName);
            // XXX need to configure own content.types.user.table
            // URLConnection.guessContentTypeFromName(mediaFileName)
            if (mediaFileName.endsWith("mp3")) {
                mediaObject.setAttribute("type", "audio/mp3");
            } else if (mediaFileName.endsWith("mp4")) {
                mediaObject.setAttribute("type", "video/mp4");
            } else if (mediaFileName.endsWith("swf")) {
                mediaObject.setAttribute("type", "application/x-shockwave-flash");
            } else if (mediaFileName.endsWith("m4a")) {
                mediaObject.setAttribute("type", "audio/mp4a-latm");
            } else if (mediaFileName.endsWith("m4v")) {
                mediaObject.setAttribute("type", "video/x-m4v");
            }
            
            mediaElement.getParentNode().replaceChild(mediaObject, mediaElement);
        }
    }
    
    private void buildItemBody(final Item item) throws SAXException, IOException,
            ParserConfigurationException, TransformerException, XPathExpressionException {
        final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        
        final ItemFragment bodyFrag = getItemBodyFragment(item);

        Node itemBodyElement = null;
        
        if (bodyFrag != null) {
            log.info("Creating replacement itemBody from item stem fragment");
            // pre-processing
            /*
            byte[] itemStemFragment = ("<itemBody>" + bodyFrag.getText() + "</itemBody>").getBytes();
            Document itemBodyDocument = docBuilder.parse(new ByteArrayInputStream(itemStemFragment));
            */
            
            final byte[] itemStemFragment = ("<itemBody>" + bodyFrag.getText() + "</itemBody>").getBytes("ISO-8859-1");
            final ByteArrayInputStream bais = new ByteArrayInputStream(itemStemFragment);
            final InputSource is = new InputSource(bais);
            is.setEncoding("ISO-8859-1");
            final Document itemBodyDocument = docBuilder.parse(is);

            // FIXME: clean-up:
            // unnecessary duplication of code; should be able to leverage
            // XMLUtil
            // too much hard-coded
            XPath xPath = XPathFactory.newInstance().newXPath();
            NamespaceAware namespaceContext = new NamespaceAware(1, 1.0F);
            namespaceContext.put("", "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1");
            namespaceContext.put("apip", "http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0");
            xPath.setNamespaceContext(namespaceContext);

            buildOutcomeDeclaration(item);

            // QTI does not support span elements with style attributes
            stripStyleAttributes(itemBodyDocument, xPath);
            
            itemBodyElement = itemBodyDocument.getDocumentElement();
            stripInvalidBlock(itemBodyElement);

            buildPassages(item, docBuilder, itemBodyElement, itemBodyDocument, xPath);
            buildRubrics(item, docBuilder, itemBodyElement, itemBodyDocument, xPath);

            buildInteractions(item, docBuilder, itemBodyDocument, xPath);

            log.info("Updating resource paths");
            correctResourcePath(itemBodyDocument, xPath);
            
            correctMediaElements(itemBodyDocument, xPath);
        }

        log.info("Reading item qti");
        //final Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes()));
        final ByteArrayInputStream bais = new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1"));
        final InputSource is = new InputSource(bais);
        is.setEncoding("ISO-8859-1");
        final Document doc = docBuilder.parse(is);

        if (itemBodyElement != null) {
            log.info("Importing replacement itemBody");
            final Node imported = doc.importNode(itemBodyElement, true);

            // replace item body with item fragment stem
            log.info("Retrieving original itemBody");
            // FIXME: Assumes itembody exists in qti; may not be safe assumption
            final Node itemBody = doc.getElementsByTagName("itemBody").item(0);
            final Node parentNode = itemBody.getParentNode();

            log.info("Replacing itemBody");
            parentNode.replaceChild(imported, itemBody);
        }
        
        setItemQtiDataFromDocument(item, doc);
    }

    private void setItemQtiDataFromDocument(final Item item, final Document doc)
            throws TransformerFactoryConfigurationError, TransformerConfigurationException, TransformerException {
        final TransformerFactory transformerFactory = TransformerFactory.newInstance();
        transformerFactory.setAttribute("indent-number", 4);
        final Transformer transformer = transformerFactory.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        final StringWriter writer = new StringWriter();
        transformer.transform(new DOMSource(doc), new StreamResult(writer));
        
        item.setQtiData(writer.getBuffer().toString());
        //log.info(item.getQtiData());
    }

    private ItemFragment getItemBodyFragment(final Item item) {
        ItemFragment bodyFrag = null;
        log.info("Retrieving item fragments");
        for (ItemFragment frag : item.getItemFragments()) {
            if (frag.getType() == ItemFragment.IF_STEM) {
                bodyFrag = frag;
            }
        }
        return bodyFrag;
    }

    private void buildInteractions(final Item item, final DocumentBuilder docBuilder, final Document itemBodyDocument, final XPath xPath)
            throws XPathExpressionException, ParserConfigurationException, SAXException, IOException,
            TransformerException {
        log.info("Searching original qti for item interactions");
        NodeList interactions = (NodeList) xPath.evaluate("//*[@class='orca:interaction']", itemBodyDocument,
                XPathConstants.NODESET);
        int numInteractions = interactions.getLength();
        log.info("Found " + numInteractions + " interactions");
        for (int i = 0; i < numInteractions; i++) {
            Node interactionNode = interactions.item(i);

            // XXX consider strategy pattern for building different types of
            // interactions

            // determine what type of interaction to create appropriate node
            Element interaction = null;

            String contentId = interactionNode.getAttributes().getNamedItem("id").getTextContent();
            // strip the prefix
            int interactionId = Integer.parseInt(contentId.substring("interaction_".length()));

            // convert interactions to qti
            for (ItemInteraction itemInteraction : item.getItemInteractions()) {
                if (itemInteraction.getId() == interactionId) {
                    // only build response declarations for item interactions
                    // included in item body
                    buildResponseDeclaration(item, itemInteraction);

                    // buildOutcomeDeclaration(item, itemInteraction);

                    String interactionElementName = null;

                    // XXX '***' denotes QTI attributes and nodes that are not
                    // currently supported by IAIP
                    switch (itemInteraction.getType()) {
                    case 1:
                        // interaction -> blockInteraction -> choiceInteraction
                        interactionElementName = "choiceInteraction";

                        // {choiceInteraction} parent {blockInteraction} nodes:
                        // prompt [0..1] {bodyElement} -> if_type 6

                        // {blockInteraction} parent {interaction} attributes:
                        // responseIdentifier [1] {identifier}

                        // -> item_interaction.ii_attribute_list
                        // {choiceInteraction} attributes:
                        // shuffle [0..1] {boolean: default=false}
                        // maxChoices [1] {integer: default=1}
                        // *** minChoices[0..1] {integer: default=0}
                        // *** orientation[0..1] {orientation:
                        // vertical|horizontal}

                        // {choiceInteraction} nodes:
                        // simpleChoice[1..*] {simpleChoice} (ordered) -> if
                        // type 2
                        break;
                    case 2:
                        // inlineInteraction, stringInteraction
                        interactionElementName = "textEntryInteraction";

                        // {textEntryInteraction} parent {inlineInteraction}
                        // {inlineInteraction} parent {interaction} attributes:
                        // responseIdentifier [1] {identifier}

                        // {textEntryInteraction} parent {stringInteraction}
                        // attributes:
                        // *** base [0..1] {integer: default=10}
                        // *** stringIdentifier [0..1] {identifier}
                        // expectedLength [0..1] {integer}
                        // *** patternMask [0..1] {string}
                        // *** placeholderText [0..1] {string}
                        break;
                    case 3:
                        // blockInteraction, stringInteraction
                        interactionElementName = "extendedTextInteraction";

                        // {extendedTextInteraction} parent {blockInteraction}
                        // nodes:
                        // prompt [0..1] {bodyElement} -> if_type 6

                        // {blockInteraction} parent {interaction} attributes:
                        // responseIdentifier [1] {identifier}

                        // {extendedTextInteraction} parent {stringInteraction}
                        // attributes:
                        // base [0..1] {integer: default=10}
                        // stringIdentifier [0..1] {identifier}
                        // expectedLength [0..1] {integer}
                        // patternMask [0..1] {string}
                        // placeholderText [0..1] {string}

                        // -> item_interaction.ii_attribute_list
                        // {extendedTextInteraction} attributes:
                        // maxStrings [0..1] {integer}
                        // minStrings [0..1] {integer: default=0}
                        // expectedLines [0..1] {integer}
                        // format [0..1] {textFormat: plain|preFormatted|xhtml
                        // default=plain}
                        break;
                    case 4:
                        // inlineInteraction
                        interactionElementName = "inlineChoiceInteraction";

                        // {inlineChoiceInteraction} parent {inlineInteraction}
                        // {inlineInteraction} parent {interaction} attributes:
                        // responseIdentifier [1] {identifier}

                        // {inlineChoiceInteraction} nodes:
                        // inlineChioce [1..*] {ordered}
                        break;
                    case 5:
                        // blockInteraction
                        interactionElementName = "matchInteraction";

                        // {matchInteraction} parent {blockInteraction} nodes:
                        // prompt [0..1] {bodyElement} -> if_type 6

                        // {blockInteraction} parent {interaction} attributes:
                        // responseIdentifier [1] {identifier}

                        // -> item_interaction.ii_attribute_list
                        // {matchInteraction} attributes:
                        // *** shuffle [0..1] {boolean: default=false}
                        // *** maxAssociations [0..1] {integer: default=1}
                        // *** minAssociations [0..1] {integer: default=0}

                        // {matchInteraction} nodes:
                        // simpleMatchSet [2]
                        break;
                    default:
                        log.info("Unsupported Interaction: " + itemInteraction.getType());
                    }

                    // interaction
                    interaction = itemBodyDocument.createElement(interactionElementName);

                    // handled by itemInteraction attribute logic [IAIP
                    // interaction editor persists in attribute field]
                    // required attribute: set responseDeclaration for this
                    // qtiInteraction by responseIdenifier attribute
                    // qtiInteractionNode.getAttributes().getNamedItem("responseIdentifier").setTextContent(itemInteraction.getName());

                    // NamedNodeMap qtiInteractionAttrs =
                    // qtiInteractionNode.getAttributes();

                    // XXX item interaction attributes are persisted as a
                    // string; should encapsulate
                    // logic to parse somewhere
                    StringTokenizer st = new StringTokenizer(itemInteraction.getAttributes());

                    String matchMaxSource = null;
                    String matchMaxTarget = null;

                    while (st.hasMoreTokens()) {
                        String[] attribute = st.nextToken().split("=");
                        String attributeName = attribute[0].trim();
                        String attributeValue = attribute[1].trim().replaceAll("^\"|\"$", "");

                        if (attributeName.equals("matchMaxSource")) {
                            matchMaxSource = attributeValue;
                        } else if (attributeName.equals("matchMaxTarget")) {
                            matchMaxTarget = attributeValue;
                        } else {
                            if (attributeName.equals("responseIdentifier")) {
                                attributeValue = correctIdentifier(attributeValue);
                            }
                            interaction.setAttribute(attributeName, attributeValue);
                        }
                    }

                    // look for item_fragments for item_interaction
                    // if if_type 2 then choice, 3 then distractor, 6 then
                    // prompt, 7 then match choice

                    if (itemInteraction.getType() == 5) {
                        // {simpleMatchSet} nodes:
                        // simpleAssociableChoice [*]
                        // {simpleAssociableChoice} (ordered)
                        Element sourceMatchSet = itemBodyDocument.createElement("simpleMatchSet");
                        interaction.appendChild(sourceMatchSet);
                        Element targetMatchSet = itemBodyDocument.createElement("simpleMatchSet");
                        interaction.appendChild(targetMatchSet);
                    }

                    // create interaction sub nodes (prompt/choices)
                    for (ItemFragment ifrag : item.getItemFragments()) {
                        if (ifrag.getItemInteractionId() == itemInteraction.getId()) {
                            switch (ifrag.getType()) {
                            case 6: // prompt
                                Node prompt = buildInteractionBlock(docBuilder, ifrag, "prompt");
                                prompt = itemBodyDocument.importNode(prompt, true);

                                // prompt really should come first
                                interaction.insertBefore(prompt, interaction.getFirstChild());
                                break;
                            case 2: // choice
                                String interactionTagName = null;

                                if (itemInteraction.getType() == 1) {
                                    // {simpleChoice} parent {choice}
                                    // attributes:
                                    // identifier [1] {identifier}
                                    // *** fixed [0..1] {boolean:
                                    // default=false}
                                    // *** templateIdentifier [0..1]
                                    // {identifier}
                                    // *** showHide [0..1] {showHide:
                                    // show|hide default=show}

                                    interactionTagName = "simpleChoice";
                                } else if (itemInteraction.getType() == 4) {
                                    // {inlineChoice} parent {choice}
                                    // attributes:
                                    // identifier [1] {identifier}
                                    // *** fixed [0..1] {boolean:
                                    // default=false}
                                    // *** templateIdentifier [0..1]
                                    // {identifier}
                                    // *** showHide [0..1] {showHide:
                                    // show|hide default=show}

                                    // {inlineChoice} attributes:
                                    // textOrVariable [*] ordered

                                    interactionTagName = "inlineChoice";
                                }

                                Element choice = (Element) buildInteractionBlock(docBuilder, ifrag, interactionTagName);
                                choice = (Element) itemBodyDocument.importNode(choice, true);
                                choice.setAttribute("identifier", correctIdentifier(ifrag.getIdentifier()));

                                interaction.appendChild(choice);
                                break;
                            case 7: // choice match
                                // {simpleAssociableChoice} parent
                                // {associableChoice} attributes:
                                // {associableChoice} parent {choice}
                                // attributes:
                                // identifier [1] {identifier}
                                // *** fixed [0..1] {boolean: default=false}
                                // *** templateIdentifier [0..1]
                                // {identifier}
                                // *** showHide [0..1] {showHide: show|hide
                                // default=show}

                                // {simpleAssociableChoice} attributes:
                                // matchMax [1] {integer}
                                // *** matchMin [0..1] {integer: default=0}

                                // {simpleAssociableChoice} nodes:
                                // flowStatic [*] {flowStatic} (ordered)
                                Element matchChoice = (Element) buildInteractionBlock(docBuilder, ifrag,
                                        "simpleAssociableChoice");
                                matchChoice = (Element) itemBodyDocument.importNode(matchChoice, true);
                                matchChoice.setAttribute("identifier", correctIdentifier(ifrag.getIdentifier()));

                                // XXX not ideal
                                if (ifrag.getMatchSequence() == 1) {
                                    matchChoice.setAttribute("matchMax", matchMaxSource);
                                } else if (ifrag.getMatchSequence() == 2) {
                                    matchChoice.setAttribute("matchMax", matchMaxTarget);
                                }

                                NodeList matchSets = interaction.getElementsByTagName("simpleMatchSet");
                                matchSets.item(ifrag.getMatchSequence() - 1).appendChild(matchChoice);

                                break;
                            case 3: // XXX how to represent distractor
                                    // rationale in QTI?
                            default:
                                log.info("Unsupported Item Interaction Fragment" + ifrag.getType());
                            }
                        }
                    }

                    buildResponseProcessing(item, itemInteraction);

                    // found the itemInteraction do not need to loop through any
                    // remaining itemInteractions
                    break;
                }
            }

            log.info("Replacing interaction:" + interactionNode.getAttributes().getNamedItem("id"));
            interactionNode.getParentNode().replaceChild(interaction, interactionNode);
        }
    }

    private Node buildInteractionBlock(final DocumentBuilder docBuilder, final ItemFragment ifrag, final String interactionTagName)
            throws SAXException, IOException {
        //ByteArrayInputStream is = null;
        ByteArrayInputStream bais = null;
        Document interactionBlockDoc = null;

        try {
            final String interactionContent = "<" + interactionTagName + ">" + ifrag.getText() + "</"
                    + interactionTagName + ">";
            /*
            is = new ByteArrayInputStream(interactionContent.getBytes());
            interactionBlockDoc = docBuilder.parse(is);
            */
            bais = new ByteArrayInputStream(interactionContent.getBytes("ISO-8859-1"));
            final InputSource is = new InputSource(bais);
            is.setEncoding("ISO-8859-1");
            interactionBlockDoc = docBuilder.parse(is);
        } finally {
            try {
                if (bais != null) {
                    bais.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }
        }

        return interactionBlockDoc.getDocumentElement();
    }

    private void buildRubrics(final Item item, final DocumentBuilder docBuilder, final Node itemBodyElement, final Document itemBodyDocument,
            final XPath xPath) throws XPathExpressionException, IOException, SAXException {
        // XXX Temporary Workaround for issue in OpenJPA
        List<Rubric> badrubs = item.getRubrics();
        List<ItemCharacterization> ichars = item.getItemCharacterizations();
        List<Rubric> rubrics = new ArrayList<Rubric>();
        for (ItemCharacterization ichar : ichars) {
            if (ichar.getType() == 16) {
                for (Rubric badrub : badrubs) {
                    if (badrub.getId() == ichar.getIntValue()) {
                        rubrics.add(badrub);
                        break;
                    }
                }
            }
        }

        // replace original rubrics with new rubrics
        if (rubrics != null && rubrics.size() > 0) {
            log.info("Searching original qti for rubrics");
            // find any existing rubrics
            NodeList rubricNodes = (NodeList) xPath.evaluate("//*[@class='scoringData' and @view='scorer']",
                    itemBodyDocument, XPathConstants.NODESET);
            final int numRubrics = rubricNodes.getLength();
            log.info("Found " + numRubrics + " rubrics");

            // remove original rubrics
            for (int i = 0; i < numRubrics; i++) {
                Element rubricElement = (Element) rubricNodes.item(i);
                log.info("Removing original rubric " + rubricElement.getAttribute("id") + " from itemBody");
                rubricElement.getParentNode().removeChild(rubricElement);
            }
        }

        // add new rubrics
        for (Rubric rubric : rubrics) {
            final File rubricFile = new File(CONTENT_BASE + rubric.getUrl());

            final String rubricContent = FileUtils.readFileToString(rubricFile);
            log.info("rubric content : " + rubricContent);

            final Node rubricBlockNode = buildRubricBlock(docBuilder, rubricContent);

            final Element rubricElement = (Element) itemBodyDocument.importNode(rubricBlockNode, true);
            rubricElement.setAttribute("id", rubric.getName());
            rubricElement.setAttribute("class", "scoringData");
            rubricElement.setAttribute("view", "scorer");

            buildRubricBlockStylesheets(itemBodyDocument, rubricElement, rubricContent);

            stripInvalidBlock(rubricElement);

            log.info("Adding new rubric " + rubricElement.getAttribute("id") + " to itemBody");
            itemBodyElement.insertBefore(rubricElement, itemBodyElement.getFirstChild());
        }
    }

    private void buildPassages(final Item item, final DocumentBuilder docBuilder, final Node itemBodyElement, final Document itemBodyDocument,
            final XPath xPath) throws XPathExpressionException, IOException, SAXException {
        // XXX Temporary Workaround for issue in OpenJPA
        List<Passage> badpassages = item.getPassages();
        List<ItemCharacterization> ichars = item.getItemCharacterizations();
        List<Passage> passages = new ArrayList<Passage>();
        log.info("number of characterizations : " + ichars.size());
        for (ItemCharacterization ichar : ichars) {
            log.info("characterization information: [item id : " + ichar.getItemId() + "][type : " + ichar.getType()
                    + "][char id : " + ichar.getIntValue() + "]");
            if (ichar.getType() == 4) {
                log.info("char is a passage");
                for (Passage badpassage : badpassages) {
                    log.info("passage : " + badpassage.getId());
                    if (badpassage.getId() == ichar.getIntValue()) {
                        log.info("Adding item characiterization : " + ichar.getIntValue() + " as passage");
                        passages.add(badpassage);
                        break;
                    }
                }
            }
        }

        // replace original passages with new passages
        if (passages != null && passages.size() > 0) {
            log.info("Searching original qti for passages");
            // find any existing passages
            NodeList passageNodes = (NodeList) xPath.evaluate("//*[@class='passage' and @view='candidate']",
                    itemBodyDocument, XPathConstants.NODESET);
            final int numPassages = passageNodes.getLength();
            log.info("Found " + numPassages + " passages");

            // remove original passages
            for (int i = 0; i < numPassages; i++) {
                Element passageElement = (Element) passageNodes.item(i);
                log.info("Removing original passage " + passageElement.getAttribute("id") + " from itemBody");
                passageElement.getParentNode().removeChild(passageElement);
            }
        }

        log.info("Number of passages for item : " + passages.size());

        // add new passages
        for (Passage passage : passages) {
            final File passageFile = new File(CONTENT_BASE + passage.getUrl());

            final String passageContent = FileUtils.readFileToString(passageFile);
            log.info("passage content : " + passageContent);

            // Import HTML document convert to XHTML and to valid QTI XML
            // rubricBlock
            // [http://www.imsglobal.org/question/qtiv2p1/imsqti_infov2p1.html#element10252]
            // block {but no interactions}
            // http://www.imsglobal.org/question/qtiv2p1/imsqti_infov2p1.html#element10119
            // stylesheet
            // http://www.imsglobal.org/question/qtiv2p1/imsqti_infov2p1.html#section10075

            Node rubricBlockNode = buildRubricBlock(docBuilder, passageContent);

            Element passageElement = (Element) itemBodyDocument.importNode(rubricBlockNode, true);
            passageElement.setAttribute("id", passage.getName());
            passageElement.setAttribute("class", "passage");
            passageElement.setAttribute("view", "candidate");

            buildRubricBlockStylesheets(itemBodyDocument, passageElement, passageContent);

            stripInvalidBlock(passageElement);

            log.info("Adding new passage " + passageElement.getAttribute("id") + " to itemBody");
            itemBodyElement.insertBefore(passageElement, itemBodyElement.getFirstChild());
        }
    }

    private Node buildRubricBlock(final DocumentBuilder docBuilder, final String htmlContent) throws SAXException,
            IOException {
        final String bodyContent = getBodyContent(htmlContent);

        // pre-processing
        final String rubricBlock = "<rubricBlock>" + bodyContent + "</rubricBlock>";

        //ByteArrayInputStream is = null;
        ByteArrayInputStream bais = null;
        Document rubricBlockDoc = null;

        try {
            /*
            is = new ByteArrayInputStream(rubricBlock.getBytes());
            rubricBlockDoc = docBuilder.parse(is);
            */
            bais = new ByteArrayInputStream(rubricBlock.getBytes("ISO-8859-1"));
            final InputSource is = new InputSource(bais);
            is.setEncoding("ISO-8859-1");
            rubricBlockDoc = docBuilder.parse(is);
        } finally {
            try {
                if (bais != null) {
                    bais.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }
        }

        Node rubricBlockNode = rubricBlockDoc.getDocumentElement();
        return rubricBlockNode;
    }

    private void buildRubricBlockStylesheets(final Document itemBodyDocument, final Element rubricBlockElement,
            final String htmlContent) throws UnsupportedEncodingException {
        final Tidy tidy = new Tidy();
        tidy.setXHTML(true);
        tidy.setMakeClean(true);

        ByteArrayInputStream is = null;
        ByteArrayOutputStream os = null;

        try {
            is = new ByteArrayInputStream(htmlContent.getBytes("ISO-8859-1"));
            os = new ByteArrayOutputStream(htmlContent.length());
            final Document tidyDoc = tidy.parseDOM(is, os);

            final NodeList linkNodes = tidyDoc.getElementsByTagName("link");
            for (int i = 0; i < linkNodes.getLength(); i++) {
                Element linkElement = (Element) linkNodes.item(i);
                if (linkElement.getAttribute("rel").equals("stylesheet")) {
                    Element stylesheet = itemBodyDocument.createElement("stylesheet");
                    stylesheet.setAttribute("href", linkElement.getAttribute("href"));
                    stylesheet.setAttribute("type", linkElement.getAttribute("type"));
                    rubricBlockElement.appendChild(stylesheet);
                }
            }
        } finally {
            try {
                if (is != null) {
                    is.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }

            try {
                if (os != null) {
                    os.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }
        }
    }

    private String getBodyContent(final String htmlContent) throws UnsupportedEncodingException {
        String bodyContent = null;

        final Tidy tidy = new Tidy();
        tidy.setXHTML(true);
        tidy.setMakeClean(true);
        tidy.setNumEntities(true);
        tidy.setPrintBodyOnly(true);

        ByteArrayInputStream is = null;
        ByteArrayOutputStream os = null;

        try {
            is = new ByteArrayInputStream(htmlContent.getBytes("ISO-8859-1"));
            os = new ByteArrayOutputStream(htmlContent.length());
            tidy.parseDOM(is, os);

            bodyContent = new String(os.toByteArray());
            log.info("body content : " + bodyContent);
        } finally {
            try {
                if (is != null) {
                    is.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }

            try {
                if (os != null) {
                    os.close();
                }
            } catch (IOException ex) {
                log.info(ex.getMessage());
            }
        }

        return bodyContent;
    }

    private void buildResponseProcessing(final Item item, final ItemInteraction itemInteraction)
            throws ParserConfigurationException, SAXException, IOException, TransformerException {
        // only if interaction type dictates response processing
        final int[] responseProcessingInteractions = { 1, 4, 5 };
        final boolean requiresResponseProcessing = Arrays.asList(responseProcessingInteractions).contains(
                itemInteraction.getType());
        if (requiresResponseProcessing) {
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
            final ByteArrayInputStream bais = new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1"));
            final InputSource is = new InputSource(bais);
            is.setEncoding("ISO-8859-1");
            final Document doc = docBuilder.parse(is);
            
            //Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes()));

            Element responseProcessingNode = doc.createElement("responseProcessing");

            // XXX determine whether can use template
            /*
             * if (false) { String responseProcessingTemplate = null;
             * 
             * // requirements: // responseDeclaration RESPONSE //
             * correctResponse // outcomeDeclaration SCORE float
             * //responseProcessingTemplate =
             * "http://www.imsglobal.org/question/qti_v2p1/rptemplates/match_correct"
             * ;
             * 
             * // requirements: // responseDeclaration RESPONSE // mapping //
             * outcomeDeclaration SCORE float //responseProcessingTemplate =
             * "http://www.imsglobal.org/question/qti_v2p1/rptemplates/map_response"
             * ;
             * 
             * // XXX IAIP does not support matchResponsePoint
             * expression/areaMapping/interactions with baseType point
             * //responseProcessingTemplate =
             * "http://www.imsglobal.org/question/qti_v2p1/rptemplates/map_response_point"
             * ;
             * 
             * responseProcessingNode.setAttribute("template",
             * responseProcessingTemplate); }
             */

            // TODO will require more complex response processing (e.g. if
            // identifiers are not RESPONSE or SCORE)

            doc.appendChild(responseProcessingNode);

            setItemQtiDataFromDocument(item, doc);
        }
    }

    private void correctResourcePath(final Document doc, final XPath xPath) throws XPathExpressionException {
        // NodeList resourceNodes = (NodeList) xPath.evaluate(RESOURCES,
        // doc, XPathConstants.NODESET);
        // FIXME: only monkeying around with images and stylesheets for now
        NodeList resourceNodes = (NodeList) xPath.evaluate("//img/@src | //stylesheet/@href", doc,
                XPathConstants.NODESET);

        // NodeList resourceNodes = getNodes(RESOURCES);
        int numResourceNodes = resourceNodes.getLength();
        log.info("numResources:" + numResourceNodes);
        for (int i = 0; i < numResourceNodes; i++) {
            Node resourceNode = resourceNodes.item(i);
            String resourcePath = resourceNode.getTextContent();
            log.info(resourcePath);
            String truncResourcePath = resourcePath.substring(resourcePath.lastIndexOf("/"));
            log.info(truncResourcePath);
            resourceNode.setTextContent(truncResourcePath);
        }
    }

    /**
     * An identifier is a string of characters that must start with a Letter or
     * an underscore ('_') and contain only Letters, underscores, hyphens ('-'),
     * period ('.', a.k.a. full-stop), Digits, CombiningChars and Extenders
     * 
     * @param identifier
     * @see http
     *      ://www.imsglobal.org/question/qtiv2p1/imsqti_infov2p1.html#element10722
     * @return
     */
    private String correctIdentifier(String identifier) {
        while (identifier.matches("^[^a-zA-Z_]")) {
            identifier = identifier.substring(1);
        }

        return identifier.replaceAll("[^a-zA-Z0-9_-]", "");
    }

    /*
     * // find all JNDI names Context ctx = (Context)new
     * InitialContext().lookup("java:/comp/env/"); listContext(ctx, " ");
     * 
     * private static final void listContext(Context ctx, String indent) throws
     * NamingException { NamingEnumeration list = ctx.listBindings(""); while
     * (list.hasMore()) { Binding binding = (Binding) list.next(); String
     * className = binding.getClassName(); String name = binding.getName();
     * log.info(indent + className + " " + name); Object o =
     * binding.getObject();
     * 
     * if (o instanceof javax.naming.Context) { listContext((Context) o, indent
     * + " "); } } }
     */

    private void buildAPIP(final Item item) throws TransformerException, ParserConfigurationException, SAXException, IOException {
        //log.info(item.getQtiData());
        
        final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        docFactory.setNamespaceAware(true);
        
        final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        final ByteArrayInputStream bais = new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1"));
        final InputSource is = new InputSource(bais);
        is.setEncoding("ISO-8859-1");
        final Document doc = docBuilder.parse(is);
        //Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes("UTF-8")), "UTF-8");
        //Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1")));
        
        // XXX may not start with namespace
        //final Node apipNode = doc.getElementsByTagName("apipAccessibility").item(0);
        //final Node apipNode = doc.getElementsByTagName("apip:apipAccessibility").item(0);
        //final Node apipNode = doc.getElementsByTagNameNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "apipAccessibility").item(0);
        final Node apipNode = doc.getElementsByTagNameNS("*", "apipAccessibility").item(0);
        //log.info(apipNode.getNamespaceURI() + ":" + apipNode.getNodeName());
        final Node apipParentNode = apipNode.getParentNode();
        //log.info(apipParentNode.getLocalName());
        //final Node apipReplacementNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "apipAccessibility");
        final Node apipReplacementNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "apipAccessibility");
        
        /*
        if () {
            apipReplacementNode.setPrefix("apip");
        }
        */

        buildAPIPCompanionMaterials(doc, item, apipReplacementNode);

        final AccessibilityItemServices accessibilityItemServices = getAccessibilityItemServices();

        buildAPIPInclusionOrder(doc, item, apipReplacementNode, accessibilityItemServices);

        buildAPIPAccessibilityInfo(doc, item, apipReplacementNode, accessibilityItemServices);

        // XXX this will mean that any existing APIP tags will be overwritten
        // and that only IAIP supported apip content will be exported
        apipParentNode.replaceChild(apipReplacementNode, apipNode);
        
        setItemQtiDataFromDocument(item, doc);
    }

    private void buildAPIPAccessibilityInfo(final Document doc, final Item item, final Node apipReplacementNode,
            final AccessibilityItemServices accessibilityItemServices) {
        final List<AccessibilityElement> accessibilityElements = accessibilityItemServices
                .findAccessibilityElements((int) item.getId());

        if (accessibilityElements != null && accessibilityElements.size() > 0) {
            final Node accessibilityInfoNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "accessibilityInfo");
            log.info("number of accessibility elements: " + accessibilityElements.size());
            for (AccessibilityElement accessibilityElement : accessibilityElements) {
                final Element accessElementElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "accessElement");
                accessElementElement.setAttribute("identifier", "ae" + accessibilityElement.getId());

                final Element contentLinkInfo = buildAPIPContentLinkInfo(doc, accessibilityElement);
                accessElementElement.appendChild(contentLinkInfo);

                // relatedElementInfo
                final Element relatedElementInfo = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "relatedElementInfo");

                final List<AccessibilityFeature> features = accessibilityElement.getFeatureList();
                final Map<Integer, List<AccessibilityFeature>> featuresByType = new HashMap<Integer, List<AccessibilityFeature>>();

                for (AccessibilityFeature feature : features) {
                    final int featureType = feature.getType();

                    if (featuresByType.get(featureType) == null) {
                        featuresByType.put(featureType, new ArrayList<AccessibilityFeature>());
                    }

                    List<AccessibilityFeature> featureTypeFeatures = featuresByType.get(featureType);
                    featureTypeFeatures.add(feature);

                    featuresByType.put(featureType, featureTypeFeatures);
                }

                for (int featureType : featuresByType.keySet()) {
                    List<AccessibilityFeature> featureTypeFeatures = featuresByType.get(featureType);

                    if (featureType == AccessibilityFeature.T_BRAILLE) {
                        Element brailleText = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "brailleText");
                        Element brailleTextString = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "brailleTextString");
                        // should only ever be one
                        for (AccessibilityFeature feature : featureTypeFeatures) {
                            brailleTextString.setAttribute("contentLinkIdentifier", "bt" + feature.getId());
                            brailleTextString.setTextContent(feature.getInfo());
                            brailleText.appendChild(brailleTextString);
                        }
                        relatedElementInfo.appendChild(brailleText);
                    } else if (featureType == AccessibilityFeature.T_HIGHLIGHTING) {
                        Element keyWordEmphasis = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "keyWordEmphasis");
                        relatedElementInfo.appendChild(keyWordEmphasis);
                    } else if (featureType == AccessibilityFeature.T_KEYWORD_TRANSLATION) {
                        Element keyWordTranslation = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "keyWordTranslation");
                        for (AccessibilityFeature feature : featureTypeFeatures) {
                            Element definitionId = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "definitionId");
                            Element language = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "language");
                            language.setTextContent(feature.getLangCode());
                            definitionId.appendChild(language);
                            Element textString = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textString");
                            textString.setAttribute("contentLinkIdentifier", "ts" + feature.getId());
                            definitionId.setTextContent(feature.getInfo());
                            definitionId.appendChild(textString);
                            keyWordTranslation.appendChild(definitionId);
                        }
                        relatedElementInfo.appendChild(keyWordTranslation);
                    } else if (featureType == AccessibilityFeature.T_SPOKEN) {
                        Element spoken = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "spoken");
                        for (AccessibilityFeature feature : featureTypeFeatures) {
                            final int featureFeature = feature.getFeature();

                            if (featureFeature == AccessibilityFeature.F_AUDIO_TEXT) {
                                Element spokenText = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "spokenText");
                                spokenText.setAttribute("contentLinkIdentifier", "st" + feature.getId());
                                spokenText.setTextContent(feature.getInfo());
                                spoken.appendChild(spokenText);
                            } else if (featureFeature == AccessibilityFeature.F_TEXT_TO_SPEECH) {
                                Element textToSpeechPronunciation = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textToSpeechPronunciation");
                                textToSpeechPronunciation.setAttribute("contentLinkIdentifier",
                                        "ttsp" + feature.getId());
                                textToSpeechPronunciation.setTextContent(feature.getInfo());
                                spoken.appendChild(textToSpeechPronunciation);
                            } else if (featureFeature == AccessibilityFeature.F_AUDIO_FILE) {
                                Element audioFileInfo = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "audioFileInfo");
                                audioFileInfo.setAttribute("contentLinkIdentifier", "af" + feature.getId());
                                audioFileInfo.setTextContent(feature.getInfo());
                                spoken.appendChild(audioFileInfo);
                            }
                        }
                        relatedElementInfo.appendChild(spoken);
                    } else if (featureType == AccessibilityFeature.T_TACTILE) {
                        Element tactileFile = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "tactileFile");
                        for (AccessibilityFeature feature : featureTypeFeatures) {
                            final int featureFeature = feature.getFeature();

                            if (featureFeature == AccessibilityFeature.F_AUDIO_TEXT) {
                                Element tactileAudioText = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "tactileAudioText");
                                tactileAudioText.setAttribute("contentLinkIdentifier", "tat" + feature.getId());
                                tactileAudioText.setTextContent(feature.getInfo());
                                tactileFile.appendChild(tactileAudioText);
                            } else if (featureFeature == AccessibilityFeature.F_BRAILLE_TEXT) {
                                Element tactileBrailleText = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "tactileBrailleText");
                                tactileBrailleText.setAttribute("contentLinkIdentifier", "tbt" + feature.getId());
                                tactileBrailleText.setTextContent(feature.getInfo());
                                tactileFile.appendChild(tactileBrailleText);
                            } else if (featureFeature == AccessibilityFeature.F_AUDIO_FILE) {
                                Element tactileAudioFile = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "tactileAudioFile");
                                tactileAudioFile.setAttribute("contentLinkIdentifier", "taf" + feature.getId());
                                tactileAudioFile.setTextContent(feature.getInfo());
                                tactileFile.appendChild(tactileAudioFile);
                            }
                        }
                        relatedElementInfo.appendChild(tactileFile);
                    }
                }
                accessElementElement.appendChild(relatedElementInfo);

                accessibilityInfoNode.appendChild(accessElementElement);
            }

            apipReplacementNode.appendChild(accessibilityInfoNode);
        }
    }

    private Element buildAPIPContentLinkInfo(final Document doc, final AccessibilityElement accessibilityElement) {
        // contentLinkInfo
        Element contentLinkInfo = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "contentLinkInfo");
        final int contentType = accessibilityElement.getContentType();

        if (contentType == AccessibilityElement.CT_QTI) {
            contentLinkInfo.setAttribute("qtiLinkIdentifierRef", accessibilityElement.getContentName());
        } else if (contentType == AccessibilityElement.CT_APIP) {
            contentLinkInfo.setAttribute("apipLinkIdentifierRef", accessibilityElement.getContentName());
        }

        final int contentLinkType = accessibilityElement.getContentLinkType();

        if (contentLinkType == AccessibilityElement.CLT_OBJECT) {
            Node objectLink = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "objectLink");
            contentLinkInfo.appendChild(objectLink);
        } else if (contentLinkType == AccessibilityElement.CLT_TEXT) {
            Node textLink = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textLink");
            final int textLinkType = accessibilityElement.getTextLinkType();

            if (textLinkType == AccessibilityElement.TLT_FULL_STRING) {
                Node fillString = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "fullString");
                textLink.appendChild(fillString);
            } else if (textLinkType == AccessibilityElement.TLT_CHAR_SEQUENCE) {
                if (accessibilityElement.getTextLinkStartChar() != accessibilityElement.getTextLinkStopChar()) {
                    Node characterStringLink = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "characterStringLink");

                    Node startCharacter = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "startCharacter");
                    startCharacter.setTextContent(String.valueOf(accessibilityElement.getTextLinkStartChar()));
                    characterStringLink.appendChild(startCharacter);

                    Node stopCharacter = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "stopCharacter");
                    stopCharacter.setTextContent(String.valueOf(accessibilityElement.getTextLinkStopChar()));
                    characterStringLink.appendChild(stopCharacter);

                    textLink.appendChild(characterStringLink);
                } else {
                    Node characterLink = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "characterLink");
                    characterLink.setTextContent(String.valueOf(accessibilityElement.getTextLinkStartChar()));
                    textLink.appendChild(characterLink);
                }
            } else if (textLinkType == AccessibilityElement.TLT_WORD) {
                Node wordLink = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "wordLink");
                wordLink.setTextContent(String.valueOf(accessibilityElement.getTextLinkWord()));
                textLink.appendChild(wordLink);
            }

            contentLinkInfo.appendChild(textLink);
        }
        return contentLinkInfo;
    }

    private AccessibilityItemServices getAccessibilityItemServices() {
        AccessibilityItemServices accessibilityItemServices = null;
        try {
            accessibilityItemServices = (AccessibilityItemServices) new InitialContext()
                    .lookup("java:/comp/env/com.pacificmetrics.orca.mbeans.AccessibilityTaggingManager/accessibilityItemServices");
        } catch (NamingException e) {
            log.info("NamingExecption looking up accessibilityItemServices" + e.getMessage());
        }
        return accessibilityItemServices;
    }

    private AccessibilityPassageServices getAccessibilityPassageServices() {
        AccessibilityPassageServices accessibilityPassageServices = null;
        try {
            accessibilityPassageServices = (AccessibilityPassageServices) new InitialContext()
                    .lookup("java:/comp/env/com.pacificmetrics.orca.mbeans.AccessibilityTaggingManager/accessibilityPassageServices");
        } catch (NamingException e) {
            log.info("NamingExecption looking up accessibilityPassageServices: " + e.getMessage());
        }
        return accessibilityPassageServices;
    }

    private void buildAPIPInclusionOrder(final Document doc, final Item item, final Node apipStub,
            final AccessibilityItemServices accessibilityItemServices) {
        List<InclusionOrder> inclusionOrders = accessibilityItemServices.findInclusionOrders((int) item.getId());

        if (inclusionOrders != null && inclusionOrders.size() > 0) {
            Node inclusionOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "inclusionOrder");
            log.info("number of inclusion orders: " + inclusionOrders.size());
            for (InclusionOrder inclusionOrder : inclusionOrders) {
                log.info("inclusion type: " + inclusionOrder.getType());
                if (inclusionOrder.getType() == InclusionOrder.T_BRAILLE_DEFAULT) {
                    Node brailleDefaultOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "brailleDefaultOrder");
                    inclusionOrderNode.appendChild(brailleDefaultOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_TEXT_AUDIO_DEFAULT) {
                    Node textAudioDefaultOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textGraphicsDefaultOrder");
                    inclusionOrderNode.appendChild(textAudioDefaultOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_TEXT_AUDIO_ON_DEMAND) {
                    Node textAudioOnDemandOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textGraphicsDefaultOrder");
                    inclusionOrderNode.appendChild(textAudioOnDemandOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_TEXT_GRAPHICS_DEFAULT) {
                    Node textTextGraphicsDefaultOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textGraphicsDefaultOrder");
                    inclusionOrderNode.appendChild(textTextGraphicsDefaultOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_TEXT_GRAPHICS_ON_DEMAND) {
                    Node textTextGraphicsOnDemandOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "textGraphicsOnDemandOrder");
                    inclusionOrderNode.appendChild(textTextGraphicsOnDemandOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_GRAPHICS_ON_DEMAND) {
                    Node textGraphicsOnDemandOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "graphicsOnlyOnDemandOrder");
                    inclusionOrderNode.appendChild(textGraphicsOnDemandOrderNode);
                } else if (inclusionOrder.getType() == InclusionOrder.T_NON_VISUAL_DEFAULT) {
                    Node nonVisualDefaultOrderNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "nonVisualDefaultOrder");
                    inclusionOrderNode.appendChild(nonVisualDefaultOrderNode);
                }

                List<InclusionOrderElement> elements = inclusionOrder.getElementList();
                log.info("number of inclusion element orders: " + elements.size());

                for (InclusionOrderElement element : elements) {
                    Element elementOrderElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "elementOrder");
                    // TODO get ae name
                    elementOrderElement.setAttribute("identifierRef", "ae" + element.getAccessibilityElementId());
                    Element orderElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "order");
                    orderElement.setTextContent(String.valueOf(element.getSequence()));
                    elementOrderElement.appendChild(orderElement);
                    inclusionOrderNode.getLastChild().appendChild(elementOrderElement);
                }

                apipStub.appendChild(inclusionOrderNode);
            }
        }
    }

    private void buildAPIPCompanionMaterials(final Document doc, final Item item, final Node apipStub) {
        // protractor
        ItemCharacterization protractorChar = item.getCharacterization(9);

        boolean protractorEnabled = false;

        if (protractorChar != null) {
            // 0 - no, 1 - yes, 2 - maybe
            protractorEnabled = (protractorChar.getIntValue() > 0);
        }

        // rule
        ItemCharacterization ruleChar = item.getCharacterization(10);

        boolean ruleEnabled = false;

        if (ruleChar != null) {
            ruleEnabled = (ruleChar.getIntValue() > 0);
        }

        // calculator
        ItemCharacterization calculatorChar = item.getCharacterization(13);

        boolean calculatorEnabled = false;

        if (calculatorChar != null) {
            calculatorEnabled = (calculatorChar.getIntValue() > 0);
        }

        if (!(protractorEnabled || ruleEnabled || calculatorEnabled)) {
            return;
        }

        Node companionMaterialsInfoNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "companionMaterialsInfo");

        if (protractorEnabled) {
            Node protractorNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "protractor");

            Node descriptionNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "description");
            descriptionNode
                    .setTextContent("A floating, transparent protractor that can be moved over the angles in the item.");
            protractorNode.appendChild(descriptionNode);

            Node incrementNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "incrementUS");
            Element minorIncrementElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "minorIncrement");
            minorIncrementElement.setAttribute("unit", "Degree");
            minorIncrementElement.setTextContent("5.0");
            incrementNode.appendChild(minorIncrementElement);

            Element majorIncrementElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "majorIncrement");
            majorIncrementElement.setAttribute("unit", "Degree");
            majorIncrementElement.setTextContent("30.0");
            incrementNode.appendChild(majorIncrementElement);

            protractorNode.appendChild(incrementNode);

            companionMaterialsInfoNode.appendChild(protractorNode);
        }

        if (ruleEnabled) {
            Node ruleNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "rule");

            Node descriptionNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "description");
            descriptionNode.setTextContent("A metric ruler with increments on one side of the rule.");
            ruleNode.appendChild(descriptionNode);

            Node ruleSystemNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "ruleSystemSI");
            Node minLengthNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "minimumLength");
            minLengthNode.setTextContent("10");
            ruleSystemNode.appendChild(minLengthNode);

            Element minorIncrementElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "minorIncrement");
            minorIncrementElement.setAttribute("unit", "Meter");
            minorIncrementElement.setTextContent("0.5");
            ruleSystemNode.appendChild(minorIncrementElement);

            Element majorIncrementElement = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "majorIncrement");
            majorIncrementElement.setAttribute("unit", "Meter");
            majorIncrementElement.setTextContent("1.0");
            ruleSystemNode.appendChild(majorIncrementElement);

            ruleNode.appendChild(ruleSystemNode);

            companionMaterialsInfoNode.appendChild(ruleNode);
        }

        if (calculatorEnabled) {
            Node calculatorNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "calculator");

            Node calculatorTypeNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "calculatorType");
            calculatorTypeNode.setTextContent("Basic");
            calculatorNode.appendChild(calculatorTypeNode);

            Node descriptionNode = doc.createElementNS("http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0", "description");
            descriptionNode.setTextContent("4 function calculator");
            calculatorNode.appendChild(descriptionNode);

            companionMaterialsInfoNode.appendChild(calculatorNode);
        }

        apipStub.appendChild(companionMaterialsInfoNode);
    }

    // TODO consider constructing an XSTL to convert the XHTML content to valid
    // QTI blocks
    private void stripStyleAttributes(final Document doc, final XPath xPath) throws XPathExpressionException {
        NodeList nodes = (NodeList) xPath.evaluate("//*[@style]", doc, XPathConstants.NODESET);
        int numNodes = nodes.getLength();
        log.info("found " + numNodes + " with style attribute");
        for (int i = 0; i < numNodes; i++) {
            Element span = (Element) nodes.item(i);
            span.removeAttribute("style");
        }
    }

    // FIXME: use jaxb to query qti xsd for list of valid tags (i.e., not
    // hard-coded); if not use xpath to identify nodes
    private final static List<String> VALID_TAGS = new ArrayList<String>();

    static {
        VALID_TAGS.add("pre");
        VALID_TAGS.add("h1");
        VALID_TAGS.add("h2");
        VALID_TAGS.add("h3");
        VALID_TAGS.add("h4");
        VALID_TAGS.add("h5");
        VALID_TAGS.add("h6");
        VALID_TAGS.add("p");
        VALID_TAGS.add("address");
        VALID_TAGS.add("dl");
        VALID_TAGS.add("ol");
        VALID_TAGS.add("hr");
        VALID_TAGS.add("ul");
        VALID_TAGS.add("blockqoute");
        VALID_TAGS.add("table");
        VALID_TAGS.add("div");
        // for rubric blocks
        VALID_TAGS.add("stylesheet");
    }

    // TODO consider constructing an XSTL to convert the XHTML content to valid
    // QTI blocks
    private void stripInvalidBlock(final Node replacement) {
        stripInvalidNodes(replacement, VALID_TAGS);
    }

    private void stripInvalidNodes(final Node replacement, final List<String> validTags) {
        // Parse item body content for interactions and invalid content
        List<Node> nodesToRemove = new ArrayList<Node>();

        NodeList childNodes = replacement.getChildNodes();
        int numChildNodes = childNodes.getLength();

        for (int i = 0; i < numChildNodes; i++) {
            Node childNode = childNodes.item(i);
            String nodeName = childNode.getNodeName();

            log.info("Node name: " + nodeName);

            if (!validTags.contains(nodeName)) {
                nodesToRemove.add(childNode);
            }
        }

        // stripping any invalid nodes
        for (Node invalidNode : nodesToRemove) {
            log.info("Removing invalid node:" + invalidNode.getNodeName());
            replacement.removeChild(invalidNode);
        }
    }

    /**
     * Response variables are declared by response declarations and bound to
     * interactions in the itemBody. Each response variable declared may be
     * bound to one and only one interaction.
     * 
     * @param item
     * @param itemInteraction
     * @throws ParserConfigurationException
     * @throws SAXException
     * @throws IOException
     * @throws TransformerException
     * @throws XPathExpressionException
     */
    private void buildResponseDeclaration(final Item item, final ItemInteraction itemInteraction)
            throws ParserConfigurationException, SAXException, IOException, TransformerException,
            XPathExpressionException {
        final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        final ByteArrayInputStream bais = new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1"));
        final InputSource is = new InputSource(bais);
        is.setEncoding("ISO-8859-1");
        final Document doc = docBuilder.parse(is);
        //Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes()));

        String baseType = "identifier";
        String cardinality = "single";

        switch (itemInteraction.getType()) {
        case 1: // choiceInteraction
            // bound to baseType of identifier

            // bound to single or multiple cardinality
            // if maxChoices is greater than 1 (or 0) then bound to a response
            // with multiple cardinality
            StringTokenizer st = new StringTokenizer(itemInteraction.getAttributes());

            while (st.hasMoreTokens()) {
                String[] attribute = st.nextToken().split("=");
                String attributeName = attribute[0].trim();
                if (attributeName.equals("maxChoice")) {
                    String attributeValue = attribute[1].trim().replaceAll("^\"|\"$", "");
                    if (Integer.valueOf(attributeValue) > 1) {
                        cardinality = "multiple";
                    } else if (Integer.valueOf(attributeValue) == 0) {
                        StringTokenizer correctTokenizer = new StringTokenizer(itemInteraction.getCorrect());
                        if (correctTokenizer.countTokens() > 1) {
                            cardinality = "multiple";
                        }
                    }
                    break;
                }
            }
            break;
        case 2: // textEntryInteraction
            // bound to a response variable with single cardinality only

            // bound to a response variable baseType of string, integer or float
            // XXX IAIP does not currently supply a mechanism to specify whether
            // a textEntryInteraction should be captured as a numeric response
            baseType = "string";
            break;
        case 3: // extendedTextInteraction
            // bound to single cardinality a single string of text is required
            // from the candidate.
            // bound to multiple or ordered cardinality several separate text
            // strings may be required, see maxStrings below.
            // XXX IAIP does not currently supply a mechanism to specify whether
            // multiple response are required for extendedTextInteraction

            // bound to baseType of string, integer or float
            // XXX IAIP does not currently supply a mechanism to specify whether
            // a extendedTextInteraction should be captured as a numeric
            // response
            baseType = "string";
            break;
        case 4: // inlineInteraction
            // bound to baseType of identifier
            // bound to single cardinality
            break;
        case 5: // blockInteraction
            // bound to a response variable with base-type directedPair and
            // either single or multiple cardinality
            baseType = "directedPair";
            // XXX since maxAssociations not supported in IAIP cannot generate
            // multiple cardinality
            break;
        default:
            log.info("Unsupported Interaction: " + itemInteraction.getType());
        }

        // response declaration
        Element responseDeclaration = doc.createElement("responseDeclaration");
        responseDeclaration.setAttribute("identifier", correctIdentifier(itemInteraction.getName()));
        responseDeclaration.setAttribute("cardinality", cardinality);
        responseDeclaration.setAttribute("baseType", baseType);

        /*
         * response declaration -> correct response
         * 
         * A response declaration may assign an optional correctResponse. This
         * value may indicate the only possible value of the response variable
         * to be considered correct or merely just a correct value. For
         * responses that are being measured against a more complex scale than
         * correct/incorrect this value should be set to the (or an) optimal
         * value. Finally, for responses for which no such optimal value is
         * defined the correctResponse must be omitted. If a delivery system
         * supports the display of a solution then it should display the correct
         * values of responses (where defined) to the candidate. When correct
         * values are displayed they must be clearly distinguished from the
         * candidate's own responses (which may be hidden completely if
         * necessary).
         */
        if (itemInteraction.getCorrect() != null && itemInteraction.getCorrect().length() > 0) {
            Element correctResponse = doc.createElement("correctResponse");

            switch (itemInteraction.getType()) {
            case 1: // choiceInteraction
                if (cardinality == "multiple") {
                    StringTokenizer correctTokenizer = new StringTokenizer(itemInteraction.getCorrect());
                    while (correctTokenizer.hasMoreTokens()) {
                        String correctValue = correctTokenizer.nextToken();
                        Element value = doc.createElement("value");
                        value.setTextContent(correctValue);
                        correctResponse.appendChild(value);
                    }
                } else {
                    Element value = doc.createElement("value");
                    value.setTextContent(itemInteraction.getCorrect());
                    correctResponse.appendChild(value);
                }
                break;
            case 5: // matchInteraction
                StringTokenizer correctTokenizer = new StringTokenizer(itemInteraction.getCorrect());
                while (correctTokenizer.hasMoreTokens()) {
                    String correctValue = correctTokenizer.nextToken();
                    Element value = doc.createElement("value");

                    // (directedPair are split by space, but internally
                    // represented by semi-colon)
                    String directedPairValue = correctValue.replace(":", " ");

                    value.setTextContent(directedPairValue);
                    correctResponse.appendChild(value);
                }
                break;
            case 3: // extendedTextInteraction
                // no correct response
                break;
            case 2: // textEntryInteraction
            case 4: // inlineChoiceInteraction
            default:
                Element value = doc.createElement("value");
                value.setTextContent(itemInteraction.getCorrect());
                correctResponse.appendChild(value);
            }

            responseDeclaration.appendChild(correctResponse);
        }

        /*
         * response declaration -> mapping
         * 
         * The mapping provides a mapping from the set of base values to a set
         * of numeric values for the purposes of response processing. See
         * mapResponse for information on how to use the mapping.
         */
        // XXX may want to map from textEntryInteraction to outcomeDeclaration
        if (cardinality == "multiple") {
            Element mapping = doc.createElement("mapping");
            mapping.setAttribute("upperBound", String.valueOf(itemInteraction.getMaxScore()));

            // XXX limits to only correct values, may want to allow for item
            // authors to specify scores for bad values
            StringTokenizer correctTokenizer = new StringTokenizer(itemInteraction.getCorrect());
            while (correctTokenizer.hasMoreTokens()) {
                String correctValue = correctTokenizer.nextToken();

                // for matchInterction need to convert to directedPair
                if (itemInteraction.getType() == 5) {
                    correctValue = correctValue.replace(":", " ");
                }

                Element mapEntry = doc.createElement("mapEntry");
                mapEntry.setAttribute("mapKey", correctValue);
                // XXX may want to allow for item authors to specify value
                mapEntry.setAttribute("mappedValue",
                        String.valueOf(itemInteraction.getMaxScore() / correctTokenizer.countTokens()));
                mapping.appendChild(mapEntry);
            }

            responseDeclaration.appendChild(mapping);
        }

        // response declaration -> area mapping
        // XXX IAIP does not support any interactions that require an area
        // mapping

        // Does ResponseDeclaration exist; if so replace with new
        XPath xPath = XPathFactory.newInstance().newXPath();
        NamespaceAware namespaceContext = new NamespaceAware(1, 1.0F);
        namespaceContext.put("", "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1");
        namespaceContext.put("apip", "http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0");
        xPath.setNamespaceContext(namespaceContext);
        NodeList nodes = (NodeList) xPath.evaluate("/assessmentItem/responseDeclaration", doc, XPathConstants.NODESET);

        for (int i = 0; i < nodes.getLength(); i++) {
            Element existingResponseDeclaration = (Element) nodes.item(i);
            if (existingResponseDeclaration.getAttribute("identifier").equals(itemInteraction.getName())) {
                // TODO replace existing
                // existingResponseDeclaration.getParentNode().replaceChild(existingResponseDeclaration,
                // responseDeclaration);
                existingResponseDeclaration.getParentNode().removeChild(existingResponseDeclaration);
                break;
            }
        }

        doc.getDocumentElement().insertBefore(responseDeclaration, doc.getDocumentElement().getFirstChild());

        setItemQtiDataFromDocument(item, doc);
    }

    /**
     * Outcome variables are declared by outcome declarations. Their value is
     * set either from a default given in the declaration itself or by a
     * responseRule during responseProcessing.
     * 
     * @param item
     * @throws ParserConfigurationException
     * @throws SAXException
     * @throws IOException
     * @throws TransformerException
     */
    private void buildOutcomeDeclaration(final Item item) throws ParserConfigurationException, SAXException, IOException,
            TransformerException {
        final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        final ByteArrayInputStream bais = new ByteArrayInputStream(item.getQtiData().getBytes("ISO-8859-1"));
        final InputSource is = new InputSource(bais);
        is.setEncoding("ISO-8859-1");
        final Document doc = docBuilder.parse(is);
        //final Document doc = docBuilder.parse(new ByteArrayInputStream(item.getQtiData().getBytes()));

        // XXX there can be many outcomeDeclarations, not clear how item author
        // can establish

        /*
         * Items that declare a numeric outcome variable representing the
         * candidate's overall performance on the item should use the outcome
         * name 'SCORE' for the variable. SCORE needs to be a float.
         */
        final Element outcomeDeclaration = doc.createElement("outcomeDeclaration");
        outcomeDeclaration.setAttribute("identifier", "SCORE");
        outcomeDeclaration.setAttribute("cardinality", "single");
        outcomeDeclaration.setAttribute("baseType", "float");

        /*
         * outcomeDeclarations need to appear: after => responseDeclaration
         * before => templateDeclaration, templateProcessing, stylesheet,
         * itemBody, responseProcessing, and modalFeedback
         */
        final NodeList responseDeclarations = doc.getElementsByTagName("responseDeclaration");
        
        if (responseDeclarations.getLength() > 0) {
            final Node lastResponseDeclaration = responseDeclarations.item(responseDeclarations.getLength() - 1);
            doc.getDocumentElement().insertBefore(outcomeDeclaration, lastResponseDeclaration.getNextSibling());
        } else {
            final NodeList itemBody = doc.getElementsByTagName("itemBody");
            doc.getDocumentElement().insertBefore(outcomeDeclaration, itemBody.item(0));
        }

        setItemQtiDataFromDocument(item, doc);
    }

    private static void validate(String xml) throws SAXException {
        TransformerFactory tFactory = TransformerFactory.newInstance();
        Transformer transformer;
        try {
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            transformer = tFactory.newTransformer(new StreamSource(APIPItemParser.class.getResourceAsStream("/xslt/apip/itemSchematron.xsl")));
            transformer.transform(new StreamSource(new ByteArrayInputStream(xml.getBytes("UTF-8"))), new StreamResult(os));
            String data = os.toString();
            if (data.indexOf("<svrl:failed-assert") > 0) {
                throw new SAXException("Error processing schematron rules:" + data);
            }
        } catch (TransformerConfigurationException e) {
            throw new SAXException(e);
        } catch (TransformerException e) {
            throw new SAXException(e);
        } catch (UnsupportedEncodingException e) {
            throw new SAXException(e);
        }
    }

    protected Set<String> getResources() throws XPathExpressionException {
        String[] values = getValues(RESOURCES);
        log.info("Found " + values.length + " resources in content");

        List<String> truncResourcePaths = new ArrayList<String>();

        // strip extraneous path information
        for (String value : values) {
            log.info("content resource path: " + value);
            String truncValue = value.substring(value.lastIndexOf("/") + 1);
            // XXX preferable to get XPATH substring-after to work
            if (truncValue.startsWith("orca:media:")) {
                truncValue = truncValue.substring("orca:media:".length());
            }
            log.info("truncated resource path: " + truncValue);
            truncResourcePaths.add(truncValue);
        }

        return new HashSet<String>(truncResourcePaths);
    }

    protected Set<String> getInteractionTypes() throws XPathExpressionException {
        NodeList nodes = getNodes(INTERACTION_TYPES);
        Set<String> out = new HashSet<String>(nodes.getLength(), 1.0F);
        for (int i = 0; i < nodes.getLength(); i++) {
            Node n = nodes.item(i);
            if (nodes.item(i).getLocalName() != null) {
                out.add(nodes.item(i).getLocalName());
            } else {
                out.add(n.getNodeName());
            }
        }
        return out;
    }

    protected String getToolVersion() throws XPathExpressionException {
        final String s;
        return (s = getValue(TOOL_VERSION)) != null ? s : "v2.1.9";
    }

    protected String getToolName() throws XPathExpressionException {
        final String s;
        return (s = getValue(TOOL_NAME)) != null ? s : "orca-sbac";
    }

    protected static String getToolVendor() {
        return "PacificMetrics";
    }

    protected boolean isTimeDependent() throws XPathExpressionException {
        String info = getValue(TIME_DEPENDENT);
        if (info == null || !"true".equalsIgnoreCase(info.trim())) {
            return false;
        }
        return true;
    }

    /**
     * TODO check feedback declaration exists!!
     * 
     * @return
     * @throws XPathExpressionException
     */
    protected String getFeedbackType() throws XPathExpressionException {
        String[] values = getValues(FEEDBACK);
        Set<String> identifiers = new HashSet<String>(Arrays.asList(values));
        Iterator<String> i = identifiers.iterator();
        while (i.hasNext()) {
            String identifier = i.next();
            return getValue("//outcomeDeclaration[@identifier='" + identifier + "']/@baseType");
        }
        return "none";
    }

    protected boolean isSolutionAvailable() throws XPathExpressionException {
        NodeList nodes = getNodes("/assessmentItem/responseDeclaration");
        for (int i = 0; i < nodes.getLength(); i++) {
            final NodeList tmp = getNodes("//correctResponse", nodes.item(i));
            // verify each response declaration has correct response child
            // elements
            if (tmp == null || tmp.getLength() == 0) {
                return false;
            }
        }
        // verify there are actually response declarations to provide an answer
        return nodes.getLength() > 0;
    }

    protected boolean isComposite() throws XPathExpressionException {
        return getInteractionTypes().size() > 1;
    }
}
