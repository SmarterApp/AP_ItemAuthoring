package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.context.FacesContext;

import org.apache.myfaces.custom.fileupload.UploadedFile;

import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.Status;
import com.pacificmetrics.orca.IBMetafileServicesStatus;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.cache.HierarchyCache;
import com.pacificmetrics.orca.ejb.IBMetafileServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.entities.ItemMetafileAssociation;

@ManagedBean(name = "metafileAssoc")
@ViewScoped
public class IBMetafileAssociationManager extends AbstractManager implements
        Serializable {

    private static final Logger LOGGER = Logger
            .getLogger(IBMetafileAssociationManager.class.getName());

    private static final long serialVersionUID = 1L;

    @EJB
    private transient IBMetafileServices metafileServices;

    private transient HierarchyCache hierarchyCache;

    private int metafileId;
    private int version;
    private ItemBankMetafile metafile;
    private int selectedPageIndex;

    private UploadedFile uploadedFile;
    private String newIDs;

    @SuppressWarnings("serial")
    private Records existing = new Records(2) {
        @Override
        public void loadItemAssociations() {
            itemAssociations = loadExistingItemAssociations();
        }
    };

    @SuppressWarnings("serial")
    private Records outdated = new Records(3) {
        @Override
        public void loadItemAssociations() {
            itemAssociations = loadOutdatedItemAssociations();
        }
    };

    @PostConstruct
    public void load() {
        FacesContext context = FacesContext.getCurrentInstance();
        Map<String, String> paramMap = context.getExternalContext()
                .getRequestParameterMap();
        String metafileParamValue = paramMap.get("metafile");
        String versionParamValue = paramMap.get("version");
        if (metafileParamValue != null && versionParamValue != null) {
            metafileId = Integer.parseInt(metafileParamValue);
            version = Integer.parseInt(versionParamValue);
            metafile = metafileServices.findMetafileByIdAndVersion(metafileId,
                    version);
            //
            existing.itemAssociations = loadExistingItemAssociations();
            outdated.itemAssociations = loadOutdatedItemAssociations();
        }
        CacheManager cache = findBean("cache"); // TODO find out why
                                                // ManagerProperty don't work
        if (cache == null) {
            LOGGER.warning("CacheManager not initialized!");
        } else {
            hierarchyCache = cache.getHierarchyCache();
        }
    }

    private List<ItemMetafileAssociation> loadExistingItemAssociations() {
        return metafileServices.getItemAssociations(metafileId, version);
    }

    private List<ItemMetafileAssociation> loadOutdatedItemAssociations() {
        return metafileServices.getItemAssociationsOutdated(metafileId);
    }

    public UploadedFile getUploadedFile() {
        return uploadedFile;
    }

    public void setUploadedFile(UploadedFile uploadedFile) {
        clear();
        try {
            String content = new String(uploadedFile.getBytes());
            newIDs = content;
        } catch (IOException e) {
            errorMsg("Can't read file: " + e);
        }
        this.uploadedFile = uploadedFile;
        selectedPageIndex = 0;
    }

    public String getNewIDs() {
        return newIDs;
    }

    public void setNewIDs(String newIDs) {
        this.newIDs = newIDs;
    }

    @SuppressWarnings("unchecked")
    public void confirmNewIDs() {
        String[] splitNewIDs = newIDs.split("[,\\s]+");
        LOGGER.info("confirmNewIDs: " + Arrays.asList(splitNewIDs));
        if (splitNewIDs.length == 0
                || (splitNewIDs.length == 1 && splitNewIDs[0].trim().isEmpty())) {
            error(IBMetafileServicesStatus.NOTHING_TO_PROCESS);
            return;
        }
        OperationResult res = metafileServices.associateItemsWithMetafile(
                metafileId, version, splitNewIDs);
        if (res.isSuccess()) {
            int count = 0;
            for (Map.Entry<String, Status> entry : ((MultipleResults<String>) res)
                    .getStatusMap().entrySet()) {
                if (entry.getValue() == Status.OK) {
                    count++;
                } else {
                    error(entry.getValue(), entry.getKey());
                }
            }
            dialogText = count > 0 ? "Successfully associated: " + count : "";
        } else {
            error(Status.OPERATION_FAILED, res.getStatus());
        }
        newIDs = null;
        clearItems();
        selectedPageIndex = 0;
    }

    public int getMetafileId() {
        return metafileId;
    }

    public void setMetafileId(int metafileId) {
        this.metafileId = metafileId;
    }

    public ItemBankMetafile getMetafile() {
        return metafile;
    }

    public void setMetafile(ItemBankMetafile metafile) {
        this.metafile = metafile;
    }

    public void clear() {
        dialogText = "";
    }

    public void clearItems() {
        existing.itemAssociations = null;
        outdated.itemAssociations = null;
        existing.associationsChecked.clear();
        outdated.associationsChecked.clear();
    }

    public String getPrimaryHierarchy(Item item) {
        if (item == null) {
            return null;
        }
        ItemCharacterization ic = item.getCharacterization(1); // TODO make
                                                               // constant
        return ic != null && hierarchyCache != null ? hierarchyCache.get(ic
                .getIntValue()) : "";
    }

    public void updateSelectedAssociations() {
        clear();
        LOGGER.info("updateSelectedAssociations");
        List<Integer> associationsToUpdate = new ArrayList<Integer>();
        for (Map.Entry<Integer, Boolean> entry : outdated.associationsChecked
                .entrySet()) {
            if (entry.getValue()) {
                associationsToUpdate.add(entry.getKey());
            }
        }
        updateAssociations(associationsToUpdate);
    }

    public void updateAllAssociations() {
        clear();
        LOGGER.info("updateAllAssociations");
        List<Integer> associationsToUpdate = new ArrayList<Integer>();
        for (ItemMetafileAssociation ima : outdated.itemAssociations) {
            associationsToUpdate.add(ima.getId());
        }
        updateAssociations(associationsToUpdate);
    }

    @SuppressWarnings("unchecked")
    private void updateAssociations(List<Integer> associationsToUpdate) {
        LOGGER.info("updateAssociations: " + associationsToUpdate);
        OperationResult res = metafileServices.updateItemAssociations(
                metafileId, version, associationsToUpdate);
        if (res.isSuccess()) {
            int count = 0;
            for (Map.Entry<Integer, Status> entry : ((MultipleResults<Integer>) res)
                    .getStatusMap().entrySet()) {
                if (entry.getValue() == Status.OK) {
                    count++;
                } else {
                    error(entry.getValue(), entry.getKey());
                }
            }
            dialogText = count > 0 ? "Successfully updated: " + count : "";
        } else {
            error(Status.OPERATION_FAILED, res.getStatus());
        }
        //
        selectedPageIndex = 3;
        clearItems();
    }

    public void removeSelectedAssociations() {
        clear();
        LOGGER.info("removeSelectedAssociations");
        List<Integer> associationsToRemove = new ArrayList<Integer>();
        for (Map.Entry<Integer, Boolean> entry : existing.associationsChecked
                .entrySet()) {
            if (entry.getValue()) {
                associationsToRemove.add(entry.getKey());
            }
        }
        removeAssociations(associationsToRemove);
    }

    public void removeAllAssociations() {
        clear();
        LOGGER.info("removeAllAssociations");
        List<Integer> associationsToRemove = new ArrayList<Integer>();
        for (ItemMetafileAssociation ima : existing.itemAssociations) {
            associationsToRemove.add(ima.getId());
        }
        removeAssociations(associationsToRemove);
    }

    @SuppressWarnings("unchecked")
    private void removeAssociations(List<Integer> associationsToRemove) {
        OperationResult res = metafileServices.unassociateItems(metafileId,
                version, associationsToRemove);
        if (res.isSuccess()) {
            int count = 0;
            for (Map.Entry<Integer, Status> entry : ((MultipleResults<Integer>) res)
                    .getStatusMap().entrySet()) {
                if (entry.getValue() == Status.OK) {
                    count++;
                } else {
                    error(entry.getValue(), entry.getKey());
                }
            }
            dialogText = count > 0 ? "Successfully removed: " + count : "";
        } else {
            error(Status.OPERATION_FAILED, res.getStatus());
        }
        //
        selectedPageIndex = 2;
        clearItems();
    }

    public int getSelectedPageIndex() {
        return selectedPageIndex;
    }

    public void setSelectedPageIndex(int selectedPageIndex) {
        this.selectedPageIndex = selectedPageIndex;
    }

    public abstract class Records implements Serializable {

        private static final long serialVersionUID = 1L;

        private int selectedPageIndex;
        private int maxDisplayRecordCount = 10;

        protected List<ItemMetafileAssociation> itemAssociations;
        private Map<Integer, Boolean> associationsChecked = new HashMap<Integer, Boolean>();

        public abstract void loadItemAssociations();

        public List<ItemMetafileAssociation> getItemAssociations() {
            if (itemAssociations == null) {
                loadItemAssociations();
            }
            return itemAssociations;
        }

        public Records(int selectedPageIndex) {
            this.selectedPageIndex = selectedPageIndex;
        }

        public int getMaxDisplayRecordCount() {
            return maxDisplayRecordCount;
        }

        public int getDisplayedRecordCount() {
            return maxDisplayRecordCount < getTotalRecordCount() ? maxDisplayRecordCount
                    : getTotalRecordCount();
        }

        public void setMaxDisplayRecordCount(int maxDisplayRecordCount) {
            this.maxDisplayRecordCount = maxDisplayRecordCount;
        }

        public int getTotalRecordCount() {
            List<ItemMetafileAssociation> itemAssociationsLocal = getItemAssociations();
            return itemAssociationsLocal != null ? itemAssociationsLocal.size()
                    : 0;
        }

        public void setUnlimitedRecordCount() {
            clear();
            setMaxDisplayRecordCount(999999);
            IBMetafileAssociationManager.this.selectedPageIndex = this.selectedPageIndex;
        }

        public Map<Integer, Boolean> getAssociationsChecked() {
            return associationsChecked;
        }

    }

    public Records getOutdated() {
        return outdated;
    }

    public Records getExisting() {
        return existing;
    }

    public String getItemViewURL() {
        return ServerConfiguration
                .getProperty(ServerConfiguration.HTTP_SERVER_CGI_BIN_URL)
                + "/itemView.pl";
    }

}
