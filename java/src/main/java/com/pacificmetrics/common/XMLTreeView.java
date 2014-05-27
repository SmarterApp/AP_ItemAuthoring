package com.pacificmetrics.common;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * The purpose of this class is to provide convenient user-friendly view of XML document
 * This representation can be used in association with JSF Tree2 to provide read-only view of XML document  
 * 
 * @author amiliteev
 *
 */
public class XMLTreeView {
    
    /**
     * Root node of the tree
     */
    private XMLTreeNode root;

    /**
     * Constructor traverses DOM tree to populate internal tree structure
     * @param doc
     */
    public XMLTreeView(Document doc) {
        traverse(doc.getDocumentElement(), root = new XMLTreeNode());
    }
    
    /**
     * Starting from given Node populates given XMLTreeNode and its children with data extracted from XML content
     * 
     * @param node
     * @param xmlTreeNode
     */
    private static void traverse(Node node, XMLTreeNode xmlTreeNode) {
        xmlTreeNode.setName(getUserFriendlyName(node.getNodeName()));
        NodeList nodeList = node.getChildNodes();
        for (int i = 0; i < nodeList.getLength(); i++) {
            Node currentNode = nodeList.item(i);
            if (currentNode.getNodeType() == Node.ELEMENT_NODE) {
                XMLTreeNode childTreeNode = new XMLTreeNode();
                xmlTreeNode.addChild(childTreeNode);
                NamedNodeMap attributes = currentNode.getAttributes();
                if ("string".equals(currentNode.getNodeName()) && attributes.getLength() > 0) {
                    childTreeNode.setName(getUserFriendlyName(attributes.item(0).getNodeName()) + " : " + attributes.item(0).getNodeValue());
                } else {
                    for (int j = 0; j < attributes.getLength(); j++) {
                        if (!attributes.item(j).getNodeName().equals("xmlns")) {
                            childTreeNode.addChild(new XMLTreeNode(getUserFriendlyName(attributes.item(j).getNodeName()) + " : " + attributes.item(j).getNodeValue()));
                        }
                    }
                    if (currentNode.getChildNodes().getLength() == 1 && currentNode.getChildNodes().item(0).getNodeType() == Node.TEXT_NODE) {
                        childTreeNode.setName(getUserFriendlyName(currentNode.getNodeName()) + " : " + currentNode.getChildNodes().item(0).getNodeValue());
                    } else {
                        traverse(currentNode, childTreeNode);
                    }
                }
            } 
        }
    }
    
    /**
     * Returns user friendly view of CamelCase identifer by separating words and capitalizing first letter
     * 
     * @param str
     * @return
     */
    private static String getUserFriendlyName(String str) {
        if (str.length() == 0) {
            return str;
        }
        str = Character.toUpperCase(str.charAt(0)) + str.substring(1);
        return str.replaceAll("([A-Z])", " $0");
    }

    /**
     * @return Root node of the tree
     */
    public XMLTreeNode getRoot() {
        return root;
    }
    
}
