package com.pacificmetrics.orca.utils;

import java.util.ArrayList;
import java.util.List;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class DomUtil {

    private static final Log LOGGER = LogFactory.getLog(DomUtil.class);

    private DomUtil() {
    }

    public static String getAttributeValue(String attributeName, Element element) {
        if (element.hasAttributes()
                && StringUtils.isNotEmpty(element.getAttribute(attributeName))) {
            return element.getAttribute(attributeName);
        }
        return null;
    }

    public static void setAttributeValue(String attributeName,
            String attributeValue, Element element) {
        if (element.hasAttributes()
                && StringUtils.isNotEmpty(element.getAttribute(attributeName))) {
            element.setAttribute(attributeName, attributeValue);
        }
    }

    public static List<Node> getNodes(String tagName, NodeList nodes) {
        List<Node> nodeList = new ArrayList<Node>();
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                nodeList.add(node);
            }
        }
        return nodeList;
    }

    public static Node getNodeByExpression(Document doc, String expression) {
        try {
            XPathFactory xPathfactory = XPathFactory.newInstance();
            XPath xpath = xPathfactory.newXPath();
            XPathExpression expr = xpath.compile(expression);
            Node node = (Node) expr.evaluate(doc, XPathConstants.NODE);
            return node;
        } catch (XPathExpressionException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        }
        return null;
    }

    public static boolean isNodeExists(Document doc, String expression) {
        try {
            XPathFactory xPathfactory = XPathFactory.newInstance();
            XPath xpath = xPathfactory.newXPath();
            XPathExpression expr = xpath.compile(expression);
            NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
            return nl != null && nl.getLength() > 0 ? true : false;
        } catch (XPathExpressionException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        }
        return false;
    }

    public static Node getNode(String tagName, NodeList nodes) {
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                return node;
            }
        }
        return null;
    }

    public static String getNodeValue(Node node) {
        NodeList childNodes = node.getChildNodes();
        for (int x = 0; x < childNodes.getLength(); x++) {
            Node data = childNodes.item(x);
            if (data.getNodeType() == Node.TEXT_NODE) {
                return data.getNodeValue();
            }
        }
        return "";
    }

    public static void setNodeTextValue(String nodeValue, Node node) {
        NodeList childNodes = node.getChildNodes();
        for (int x = 0; x < childNodes.getLength(); x++) {
            Node data = childNodes.item(x);
            if (data.getNodeType() == Node.TEXT_NODE) {
                data.setNodeValue(nodeValue);
            }
        }
    }

    public static String getNodeValue(String tagName, NodeList nodes) {
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                NodeList childNodes = node.getChildNodes();
                for (int y = 0; y < childNodes.getLength(); y++) {
                    Node data = childNodes.item(y);
                    if (data.getNodeType() == Node.TEXT_NODE) {
                        return data.getNodeValue();
                    }
                }
            }
        }
        return "";
    }

    public static int getNodeIntValue(String tagName, NodeList nodes) {
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                NodeList childNodes = node.getChildNodes();
                for (int y = 0; y < childNodes.getLength(); y++) {
                    Node data = childNodes.item(y);
                    if (data.getNodeType() == Node.TEXT_NODE) {
                        try {
                            return Integer.parseInt(data.getNodeValue());
                        } catch (NumberFormatException e) {
                            return 0;
                        }
                    }
                }
            }
        }
        return 0;
    }

    public static double getNodeDoubleValue(String tagName, NodeList nodes) {
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                NodeList childNodes = node.getChildNodes();
                for (int y = 0; y < childNodes.getLength(); y++) {
                    Node data = childNodes.item(y);
                    if (data.getNodeType() == Node.TEXT_NODE) {
                        try {
                            return Double.parseDouble(data.getNodeValue());
                        } catch (NumberFormatException e) {
                            return 0.0;
                        }
                    }
                }
            }
        }
        return 0.0;
    }

    public static List<String> getNodeValues(String tagName, NodeList nodes) {
        List<String> nodeValues = new ArrayList<String>();
        for (int x = 0; x < nodes.getLength(); x++) {
            Node node = nodes.item(x);
            if (node.getNodeName().equalsIgnoreCase(tagName)) {
                NodeList childNodes = node.getChildNodes();
                for (int y = 0; y < childNodes.getLength(); y++) {
                    Node data = childNodes.item(y);
                    if (data.getNodeType() == Node.TEXT_NODE) {
                        nodeValues.add(data.getNodeValue());
                    }
                }
            }
        }
        return nodeValues;
    }

}
