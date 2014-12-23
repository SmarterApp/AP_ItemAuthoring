package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.RequestScoped;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.myfaces.custom.tree2.TreeNode;
import org.apache.myfaces.custom.tree2.TreeNodeBase;

import com.pacificmetrics.common.XMLTreeNode;
import com.pacificmetrics.common.XMLTreeView;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.utils.XMLUtil;

/**
 * This class supports tree view of item metadata
 * 
 * @author amiliteev
 * 
 */
@ManagedBean(name = "itemMetadata")
@RequestScoped
public class ItemMetadataManager extends AbstractManager implements
        Serializable {
    private static final long serialVersionUID = 1L;

    private static final Log LOGGER = LogFactory
            .getLog(ItemMetadataManager.class);

    @EJB
    private transient ItemServices itemServices;

    private TreeNode treeData;

    /**
     * This method finds the item by id specified in page's parameter 'item'
     * Redirects to error page if item not specified or not found, if there's no
     * metadata associated with the item or metadata cannot be parsed
     * XMLTreeView is constructed from the parsed XML document
     * populateTreeData() method is called to populate tree data from
     * XMLTreeView
     * 
     */
    @PostConstruct
    public void load() {
        int itemId = getParameterAsInt("item", 0);
        if (itemId <= 0) {
            redirectWithErrorMessage("Error.ItemMetadata.ItemNotSpecified");
            return;
        }
        Item item = itemServices.findItemWithMetadataById(itemId);
        if (item == null) {
            redirectWithErrorMessage("Error.ItemMetadata.ItemNotFound");
            return;
        }
        String metadataXml = item.getMetadataXml();
        if (StringUtils.isEmpty(metadataXml)) {
            redirectWithErrorMessage("Error.ItemMetadata.ItemMetadataNotPresent");
            return;
        }
        XMLUtil parser = new XMLUtil();
        try {
            parser.load(metadataXml);
            XMLTreeView treeView = new XMLTreeView(parser.getDoc());
            treeData = new TreeNodeBase("folder", "Item Metadata", false);
            populateTreeData(treeView.getRoot(), treeData);
        } catch (Exception e) {
            LOGGER.error("Cannot persist item metadata " + e.getMessage(), e);
            redirectWithErrorMessage("Error.ItemMetadata.CannotParseItemMetadata");
            return;
        }
    }

    /**
     * Method populates JSF TreeNode with content obtained from XMLTreeNode
     * 
     * @param xmlTreeNode
     * @param treeNode
     */
    @SuppressWarnings("unchecked")
    private void populateTreeData(XMLTreeNode xmlTreeNode, TreeNode treeNode) {
        if (!xmlTreeNode.hasChildren()) {
            return;
        }
        for (XMLTreeNode xmlChildNode : xmlTreeNode.getChildren()) {
            TreeNodeBase childNode = new TreeNodeBase(
                    xmlChildNode.hasChildren() ? "folder" : "document",
                    xmlChildNode.getName(), !xmlChildNode.hasChildren());
            treeNode.getChildren().add(childNode);
            populateTreeData(xmlChildNode, childNode);
        }
    }

    public TreeNode getTreeData() {
        return treeData;
    }

}