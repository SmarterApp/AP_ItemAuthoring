package com.pacificmetrics.common;

import java.util.ArrayList;
import java.util.List;

public class XMLTreeNode {

    private String name;
    private List<XMLTreeNode> children;
    
    public XMLTreeNode() {
    }
    
    public XMLTreeNode(String name) {
        this.name = name;
    }
    
    public void addChild(XMLTreeNode node) {
        if (children == null) {
            children = new ArrayList<XMLTreeNode>();
        }
        children.add(node);
    }

    public List<XMLTreeNode> getChildren() {
        return children;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
    
    public boolean hasChildren() {
        return children != null && !children.isEmpty();
    }

}
