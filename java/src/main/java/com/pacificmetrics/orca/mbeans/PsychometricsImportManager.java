package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.event.AjaxBehaviorEvent;
import javax.faces.model.SelectItem;

import org.apache.myfaces.custom.fileupload.UploadedFile;

import com.pacificmetrics.common.ApplicationException;
import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.Status;
import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.StatServices;
import com.pacificmetrics.orca.ejb.UserServices;
import com.pacificmetrics.orca.entities.StatAdministration;
import com.pacificmetrics.orca.entities.StatAdministrationStatus;
import com.pacificmetrics.orca.helpers.ItemBankHelper;
import com.pacificmetrics.orca.helpers.StatHelper;

@ManagedBean(name="psychometricsImport")
@ViewScoped
public class PsychometricsImportManager extends AbstractManager {

    private static final long serialVersionUID = 1L;
    
    static private Logger logger = Logger.getLogger(PsychometricsImportManager.class.getName()); 
    
    private Integer selectedItemBankId;
    private List<SelectItem> itemBankSelectItems;
    private String searchText;
    private UploadedFile uploadedFile;
    private boolean uploading;
    private List<StatAdministration> administrations;
    private int firstRowIndex;
    private String identifier;
    private String comment;
    private boolean displayingResults = false;
    StatHelper.ImportFileData importFileData;

    @EJB
    private transient ItemBankServices itemBankServices;

    @EJB
    private transient StatServices statServices;
    
    @EJB
    private transient UserServices userServices;

    private transient ItemBankHelper itemBankHelper;
    
    @PostConstruct
    public void load() {
        itemBankHelper = new ItemBankHelper(itemBankServices);
        itemBankSelectItems = itemBankHelper.getItemBankSelectItems(userServices.getUser());
    }

    public List<SelectItem> getItemBankSelectItems() {
        return itemBankSelectItems;
    }

    public void setItemBankSelectItems(List<SelectItem> itemBankSelectItems) {
        this.itemBankSelectItems = itemBankSelectItems;
    }

    public Integer getSelectedItemBankId() {
        return selectedItemBankId;
    }

    public void setSelectedItemBankId(Integer selectedItemBankId) {
        this.selectedItemBankId = selectedItemBankId;
    }
    
    public void itemBankSelected(AjaxBehaviorEvent event) {
        logger.info("Item bank selected: " + selectedItemBankId);
        loadAdministrations();
        setFirstRowIndex(0);
    }
    
    public boolean isItemBankSelected() {
        return selectedItemBankId != null && selectedItemBankId > 0;
    }

    public String getSearchText() {
        return searchText;
    }

    public void setSearchText(String searchText) {
        this.searchText = searchText;
    }
    
    public void doSearch() {
        logger.info("Searching for " + searchText);
    }
    
    public void uploadNewFile() {
        logger.info("Request to upload");
        uploading = true;
    }

    public UploadedFile getUploadedFile() {
        return uploadedFile;
    }

    public void setUploadedFile(UploadedFile uploadedFile) {
        this.uploadedFile = uploadedFile;
    }
    
    public void upload() throws ManagerException {
        if (uploadedFile != null) {
            logger.info("Uploaded file: " + uploadedFile.getName());
        } else {
            logger.warning("Uploaded file is null");
            return;
        }
        if (!uploadedFile.getName().endsWith(".csv")) {
            error("Error.PsychometricsImport.NotCSV");
            return;
        }
        try {
            logger.info("File uploaded. Size: " + uploadedFile.getBytes().length);
            importFileData = new StatHelper().getImportFileData(uploadedFile.getBytes());
        } catch (ApplicationException e) {
            error(e.getStatus());
            return;
        } catch (IOException e) {
            throw new ManagerException(e);
        }
        StatAdministration sa = new StatAdministration();
        sa.setIdentifier(identifier);
        sa.setComment(comment);
        sa.setStatusId(StatAdministrationStatus.UNDEFINED);
        sa.setItemBankId(selectedItemBankId);
        try {
            sa = statServices.merge(sa);
            OperationResult res = statServices.importStatistics(sa, importFileData);
            if (!res.isSuccess() || (res instanceof MultipleResults && !((MultipleResults<?>)res).isAllSuccess())) { //That's likely to change if they want partial import
                errorMsg("Error [" + new SimpleDateFormat("MM/dd/yyyy").format(new Date()) + "]");
                //this will also cascade delete all partially imported data
                statServices.deleteStatAdministration(sa.getId());
                return;
            }
            //Currently can only be success, as all errors will be rolled back
            statServices.updateStatus(sa.getId(), res.getStatus() == Status.OK ? StatAdministrationStatus.SUCCESS : StatAdministrationStatus.FAILURE); 
            clear();
            uploading = false;
            displayingResults = true;
        } catch (ServiceException e) {
            throw new ManagerException(e);
        }
        loadAdministrations();
    }
    
    private void clear() {
        uploadedFile = null;
        identifier = null;
        comment = null;
    }
    
    public boolean isUploading() {
        return uploading;
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
    
    private void loadAdministrations() {
        if (selectedItemBankId != 0) {
            administrations = statServices.findAdministrations(selectedItemBankId);
        } else {
            administrations = null;
        }
    }

    public List<StatAdministration> getAdministrations() {
        return administrations;
    }

    public void setAdministrations(List<StatAdministration> administrations) {
        this.administrations = administrations;
    }

    public int getFirstRowIndex() {
        return firstRowIndex;
    }

    public void setFirstRowIndex(int firstRowIndex) {
        this.firstRowIndex = firstRowIndex;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }
    
    public boolean isDisplayingResults() {
        return displayingResults;
}

    public void setDisplayingResults(boolean displayingResults) {
        this.displayingResults = displayingResults;
    }
    
    public void hideImportResults() {
        displayingResults = false;
    }
    
    public List<String> getImportHeaders() {
        return importFileData != null ? importFileData.getHeaders() : Collections.<String>emptyList();
    }
    
    public List<List<Object>> getImportResults() {
        return importFileData != null ? importFileData.getRows() : Collections.<List<Object>>emptyList();
//        List<List<?>> result = new ArrayList<List<?>>();
//        {
//            List<Object> list = new ArrayList<Object>();
//            list.add("XXX");
//            list.add(0.3);
//            list.add(0.2);
//            list.add(0.1);
//            result.add(list);
//        }
//        {
//            List<Object> list = new ArrayList<Object>();
//            list.add("YYY");
//            list.add(0.4);
//            list.add(0.5);
//            list.add(0.6);
//            result.add(list);
//        }
//        return result;
    }
    
}

/* TODO Implement Search functionality in Psychometrics Import page

        <h:inputText id="searchText" styleClass="searchText" size="50" value="#{psychometricsImport.searchText}" />
        <h:commandButton value="Search" action="#{psychometricsImport.doSearch}">
            <f:ajax execute="searchText" render=""/>
        </h:commandButton>

*/
