package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;

import org.apache.myfaces.custom.fileupload.UploadedFile;

import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.common.web.WebUtils;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ItemServices;

/**
 * Managed bean to support Psychometrics starting page and Psychometrics Reports page
 * 
 * @author amiliteev
 * @modifier maumock
 *
 */
@ManagedBean(name="psychometrics")
@ViewScoped
public class PsychometricsManager extends AbstractManager {

    private static final long serialVersionUID = 1L;
    
    static private Logger logger = Logger.getLogger(PsychometricsManager.class.getName()); 
    
    private static final String REPORTS = "REPORTS";
    private static final String IMPORT = "IMPORT";
    private static final String SETTINGS = "SETTINGS";
    
    private String selectedPageName;
    private String reportContent;
    private boolean uploading;
    private boolean displayingInvalidItems;
    
    private UploadedFile uploadedFile;
    private Collection<Long> itemIds;
    private Collection<String> invalidItemIds;
    
    @EJB
    transient private ItemServices itemServices; 

    public PsychometricsManager() {
    }
    
    public void setReportsPageSelected() {
        this.selectedPageName = REPORTS;
    }

    public void setImportPageSelected() {
        this.selectedPageName = IMPORT;
    }

    public void setSettingsPageSelected() {
        this.selectedPageName = SETTINGS;
    }
    
    public boolean isReportsPageSelected() {
        return REPORTS.equals(this.selectedPageName);
    }

    public boolean isImportPageSelected() {
        return IMPORT.equals(this.selectedPageName);
    }

    public boolean isSettingsPageSelected() {
        return SETTINGS.equals(this.selectedPageName);
    }

    public String getSelectedPageName() {
        return this.selectedPageName;
    }

    public void setSelectedPageName(String selectedPageName) {
        this.selectedPageName = selectedPageName;
    }
    
    /**
     * Method returns URL to Jasper server that should be used to invoke psychometrics report; 
     * URL constructed using server properties: jasper.http.url, jasper.user.name, jasper.password, jasper.reports.directory
     * If item ids have been set, they are included in respective parameter of the report 
     * 
     * @return
     */
    public String getReportUrl() {
        String jasperHttpUrl = ServerConfiguration.getProperty("jasper.http.url");
        String userName = ServerConfiguration.getProperty("jasper.user.name");
        String password = ServerConfiguration.getProperty("jasper.password");
        String directory = ServerConfiguration.getProperty("jasper.reports.directory");
        String itemViewURL = ServerConfiguration.getProperty("item.view.url");
        String result = jasperHttpUrl + "/flow.html?standAlone=true&_flowId=viewReportFlow&reportUnit=/Reports" + 
                                        directory + "/Psychometrics1&decorate=no" +
                                        //"&j_username=" + userName + "&j_password=" + password +
                                        "&ItemViewURL=" + WebUtils.encodeURL(itemViewURL) +
                                        (this.itemIds != null ? "&ItemIds=" + this.itemIds.toString().replaceAll("\\[|\\]| ", ""): "");
        //TODO huge security hole here; need to figure out a way to call jasper server from tomcat and send generated html to client;
        return result;
    }
    
    public String getReportContent() {
        return this.reportContent;
    }

    public boolean isUploading() {
        return this.uploading;
    }

    public void setUploading(boolean uploading) {
        this.uploading = uploading;
    }
    
    public void initUpload() {
        this.uploading = true;
    }
    
    public void cancelUpload() {
        this.uploading = false;
    }
    
    /**
     * Method should be invoked to process uploaded file: read item id(s) separated by comma/newline, check items' existence, populate itemIds
     * and invalidItemIds 
     * 
     * @throws ManagerException
     */
    public void upload() throws ManagerException {
        logger.info("Uploading file: " + this.uploadedFile);
        if (this.uploadedFile != null) {
            try {
                String[] externalIds = new String(this.uploadedFile.getBytes()).split("( |,|\\n|\\r\\n)+");
                Map<Long, String> itemIdMap = this.itemServices.getItemIds(Arrays.asList(externalIds));
                this.itemIds = itemIdMap.keySet();
                populateInvalidItemIds(externalIds, itemIdMap.values());
                logger.info("Uploaded " + this.itemIds + " item(s) from file " + this.uploadedFile.getName() + "; " + this.invalidItemIds.size() + " invalid item(s) found");
            } catch (IOException e) {
                throw new ManagerException(e);
            }
        } else {
            logger.warning("uploadedFile is null");
        }
        setUploading(false);
    }
    
    private void populateInvalidItemIds(String[] uploadedIds, Collection<String> foundIds) {
        Set<String> upperCasedItemIds = new HashSet<String>();
        for (String itemId: foundIds) {
            upperCasedItemIds.add(itemId.toUpperCase());
        }
        this.invalidItemIds = new ArrayList<String>(Arrays.asList(uploadedIds));
        for (Iterator<String> ii = this.invalidItemIds.iterator(); ii.hasNext(); ) {
            String itemId = ii.next();
            if (upperCasedItemIds.contains(itemId.toUpperCase())) {
                ii.remove();
            }
        }
    }

    public UploadedFile getUploadedFile() {
        return this.uploadedFile;
    }

    public void setUploadedFile(UploadedFile uploadedFile) {
        this.uploadedFile = uploadedFile;
    }
    
    public String getUploadedFileName() {
        return this.uploadedFile != null ? this.uploadedFile.getName() : null;
    }
    
    public void clearUploaded() {
        this.uploadedFile = null;
        this.itemIds = null;
    }
    
    public void displayInvalidItems() {
        this.displayingInvalidItems = true;
    }

    public void hideInvalidItems() {
        this.displayingInvalidItems = false;
    }

    public Collection<Long> getItemIds() {
        return this.itemIds;
    }
    
    public int getItemCount() {
        return this.itemIds != null ? this.itemIds.size() : 0;
    }

    public int getInvalidItemCount() {
        return this.invalidItemIds != null ? this.invalidItemIds.size() : 0;
    }

    public void setItemIds(List<Long> itemIds) {
        this.itemIds = itemIds;
    }

    public boolean isDisplayingInvalidItems() {
        return this.displayingInvalidItems;
    }

    public void setDisplayingInvalidItems(boolean displayingInvalidItems) {
        this.displayingInvalidItems = displayingInvalidItems;
    }

    public Collection<String> getInvalidItemIds() {
        return this.invalidItemIds;
    }

}
