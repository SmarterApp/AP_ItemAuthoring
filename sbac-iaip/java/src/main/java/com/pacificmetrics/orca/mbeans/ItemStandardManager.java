package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;
import java.util.List;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;

import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemStandard;

/**
 * 
 * 
 * 
 * @author dbloom
 */
@ManagedBean(name = "itemStandard")
@ViewScoped
public class ItemStandardManager extends AbstractManager implements
        Serializable {

    private static final Logger LOGGER = Logger
            .getLogger(ItemStandardManager.class.getName());

    private static final long serialVersionUID = 1L;

    private Item originalItem;
    @EJB
    private ItemServices itemServices;

    private List<ItemStandard> itemStandardList;
    private String standardValue;
    private String standardId;
    private Boolean existPrimaryStandard = Boolean.FALSE;

    public Item getOriginalItem() {
        return originalItem;
    }

    public void setOriginalItem(Item originalItem) {
        this.originalItem = originalItem;
    }

    public ItemServices getItemServices() {
        return itemServices;
    }

    public void setItemServices(ItemServices itemServices) {
        this.itemServices = itemServices;
    }

    public List<ItemStandard> getItemStandardList() {
        return itemStandardList;
    }

    public void setItemStandardList(List<ItemStandard> itemStandardList) {
        this.itemStandardList = itemStandardList;
    }

    /**
     * @return the standardValue
     */
    public String getStandardValue() {
        return standardValue;
    }

    /**
     * @param standardValue
     *            the standardValue to set
     */
    public void setStandardValue(String standardValue) {
        this.standardValue = standardValue;
    }

    /**
     * @return the standardId
     */
    public String getStandardId() {
        return standardId;
    }

    /**
     * @param standardId
     *            the standardId to set
     */
    public void setStandardId(String standardId) {
        this.standardId = standardId;
    }

    /**
     * @return the existPrimaryStandard
     */
    public Boolean getExistPrimaryStandard() {
        return existPrimaryStandard;
    }

    /**
     * @param existPrimaryStandard
     *            the existPrimaryStandard to set
     */
    public void setExistPrimaryStandard(Boolean existPrimaryStandard) {
        this.existPrimaryStandard = existPrimaryStandard;
    }

    @PostConstruct
    public void load() {
        Long itemId = null;

        if (getParameter("itemId") != null) {
            try {
                itemId = Long.valueOf(getParameter("itemId"));
            } catch (NumberFormatException nfe) {
                // doesn't matter whether too long or wrong format, but
                // could be
                // someone trying something so worth logging
                LOGGER.warning(nfe.getMessage());
                error("Error.ItemStandard.InvalidItemId");
                return;
            }
        } else {
            error("Error.ItemStandard.InvalidItemId");
            return;
        }

        if (itemId != null) {

            fetchItem(itemId);
        } else {
            error("Error.ItemStandard.InvalidItemId");
            return;
        }

        if (originalItem == null) {
            error("Error.ItemStandard.InvalidItemId", String.valueOf(itemId));
            return;
        }
    }

    public void removeStandard(ItemStandard itemStandard) {
        itemServices.removeItemStandard(itemStandard.getId());
        fetchItem(originalItem.getId());
    }

    public void makePrimary(ItemStandard itemStandard) {
        String primaryStandard = originalItem.getPrimaryStandard();
        itemServices.updateItemField(originalItem.getId(),
                "i_primary_standard", itemStandard.getStandard());
        itemServices.updateItemStandard(itemStandard.getId(), primaryStandard);
        fetchItem(originalItem.getId());
    }

    public void fetchItem(Long itemId) {
        originalItem = itemServices.findItemById(Integer.valueOf(String
                .valueOf(itemId)));
        itemStandardList = originalItem.getItemStandardList();
        if (originalItem.getPrimaryStandard() != null
                && !originalItem.getPrimaryStandard().isEmpty()) {
            existPrimaryStandard = Boolean.TRUE;
        }
    }
}
