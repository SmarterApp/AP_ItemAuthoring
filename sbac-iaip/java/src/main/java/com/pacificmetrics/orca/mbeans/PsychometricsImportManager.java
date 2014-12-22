package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.event.AjaxBehaviorEvent;
import javax.faces.model.SelectItem;

import org.apache.commons.lang.StringUtils;
import org.apache.myfaces.custom.fileupload.UploadedFile;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import com.pacificmetrics.common.ApplicationException;
import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.Status;
import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.orca.StatServicesStatus;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.StatServices;
import com.pacificmetrics.orca.ejb.UserServices;
import com.pacificmetrics.orca.entities.StatAdministration;
import com.pacificmetrics.orca.entities.StatAdministrationStatus;
import com.pacificmetrics.orca.entities.StatImportIdentifier;
import com.pacificmetrics.orca.entities.StatKey;
import com.pacificmetrics.orca.helpers.ItemBankHelper;
import com.pacificmetrics.orca.helpers.StatHelper;
import com.pacificmetrics.orca.helpers.StatHelper.ImportFileData;

@ManagedBean(name = "psychometricsImport")
@ViewScoped
public class PsychometricsImportManager extends AbstractManager {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = Logger
            .getLogger(PsychometricsImportManager.class.getName());

    private Integer selectedItemBankId;
    private List<SelectItem> itemBankSelectItems;
    private String searchText;
    private UploadedFile uploadedFile;
    private boolean uploading;
    private List<StatImportIdentifier> administrations;
    private int firstRowIndex;
    private String identifier;
    private String comment;
    private boolean displayingResults = false;
    StatHelper.ImportFileData importFileData;

    // for admin and itemid combination check
    private boolean stop = false;
    private boolean flag = false;
    private boolean showDialog = false;
    private boolean executeCheck = true;

    public boolean isShowDialog() {
        return showDialog;
    }

    public void setShowDialog(boolean showDialog) {
        this.showDialog = showDialog;
    }

    public boolean isStop() {
        return stop;
    }

    public void setStop(boolean stop) {
        this.stop = stop;
    }

    public boolean isFlag() {
        return flag;
    }

    public void setFlag(boolean flag) {
        this.flag = flag;
    }

    public void submitContinue() {
        stop = false;
        showDialog = false;
        executeCheck = false;
        flag = false;
    }

    public void cancelSubmit() {
        this.stop = true;
        showDialog = false;

    }

    @EJB
    private transient ItemBankServices itemBankServices;

    @EJB
    private transient ItemServices itemServices;

    @EJB
    private transient StatServices statServices;

    @EJB
    private transient UserServices userServices;

    private transient ItemBankHelper itemBankHelper;

    @PostConstruct
    public void load() {
        itemBankHelper = new ItemBankHelper(itemBankServices);
        itemBankSelectItems = itemBankHelper
                .getItemBankSelectItems(userServices.getUser());
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
        LOGGER.info("Item bank selected: " + selectedItemBankId);
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
        LOGGER.info("Searching for " + searchText);
    }

    public void uploadNewFile() {
        LOGGER.info("Request to upload");
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
            LOGGER.info("Uploaded file: " + uploadedFile.getName());
        } else {
            LOGGER.warning("Uploaded file is null");
            return;
        }
        if (!uploadedFile.getName().endsWith(".xls")
                && !uploadedFile.getName().endsWith(".csv")
                && !uploadedFile.getName().endsWith(".xlsx")) {
            error("Error.PsychometricsImport.NotCSV");
            return;
        }
        if (StringUtils.isNotBlank(identifier) && identifier.length() > 30) {
            error("Error.PsychometricsImport.IdentifierTooLong");
            return;
        }
        if (StringUtils.isNotBlank(comment) && comment.length() > 250) {
            error("Error.PsychometricsImport.CommentTooLong");
            return;
        }
        try {
            LOGGER.info("File uploaded. Size: "
                    + uploadedFile.getBytes().length);
            //

            if (uploadedFile.getName().endsWith(".xls")) {
                HSSFWorkbook workbook = new HSSFWorkbook(
                        uploadedFile.getInputStream());
                HSSFSheet sheet = workbook.getSheetAt(0);

                if (sheet.getLastRowNum() < 1) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                List<String> columnList = new ArrayList<String>();

                HSSFRow r = sheet.getRow(0);
                Iterator<Cell> cellIterator = r.cellIterator();
                while (cellIterator.hasNext()) {
                    Cell cell = cellIterator.next();
                    columnList.add(cell.getStringCellValue().trim()
                            .toUpperCase());
                }
                importFileData = new StatHelper().getExcelImportFileData(
                        uploadedFile, getAllStatKey(columnList));

            } else if (uploadedFile.getName().endsWith(".xlsx")) {

                XSSFWorkbook workbook = new XSSFWorkbook(
                        uploadedFile.getInputStream());
                XSSFSheet sheet = workbook.getSheetAt(0);

                if (sheet.getLastRowNum() < 1) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                List<String> columnList = new ArrayList<String>();

                XSSFRow r = sheet.getRow(0);
                Iterator<Cell> cellIterator = r.cellIterator();
                while (cellIterator.hasNext()) {
                    Cell cell = cellIterator.next();
                    columnList.add(cell.getStringCellValue().trim()
                            .toUpperCase());

                }
                importFileData = new StatHelper()
                        .getNewFormatExcelImportFileData(uploadedFile,
                                getAllStatKey(columnList));

            } else {
                String[] lines = new String(uploadedFile.getBytes())
                        .split("(\\r\\n)|\\r|\\n");
                if (lines.length < 2) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                List<String> columnList = new LinkedList<String>(
                        Arrays.asList(lines[0].toUpperCase().split(", *")));

                importFileData = new StatHelper().getImportFileData(
                        uploadedFile.getBytes(), getAllStatKey(columnList));
            }
            // validation for same admin, no different admin in single file is
            // allowed
            boolean checkDiiferntAdMin = checkDifferentAdmin(importFileData);
            if (checkDiiferntAdMin == false) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_INVALID_ADMIN);
            }
        } catch (ApplicationException e) {
            LOGGER.log(Level.SEVERE, "Unable to upload file " + e.getMessage(),
                    e);
            error(e.getStatus());
            return;
        } catch (IOException e) {
            throw new ManagerException(e);
        }
        // check itemid and admin combination is already in system or not
        if (executeCheck) {
            for (int i = 0; importFileData.getRows().size() > i; i++) {
                try {
                    if (statServices.checkAdminAndItemCombination((itemServices
                            .findItemByExternalId(importFileData.getRows()
                                    .get(i).get(0).toString())).getId(),
                            statServices.getAdminIdByName(importFileData
                                    .getRows().get(i).get(1).toString()))) {
                        flag = true;
                    }
                } catch (Exception e) {
                    LOGGER.log(Level.SEVERE, e.getMessage(), e);
                    errorMsg(importFileData.getRows().get(i).get(0).toString()
                            + " Item ID is not valid");
                }
            }

        }
        if (flag == true) {
            stop = true;
            showDialog = true;
        }
        if (stop == false) {

            StatImportIdentifier sii = new StatImportIdentifier();
            sii.setIdentifier(identifier);
            sii.setComment(comment);
            sii.setStatusId(StatAdministrationStatus.UNDEFINED);
            sii.setItemBankId(selectedItemBankId);

            StatAdministration sa;

            List<StatAdministration> existStatAdmin = statServices
                    .checkAdminExistence(importFileData.getRows().get(0).get(1)
                            .toString().trim());
            if (existStatAdmin.isEmpty()) {
                sa = new StatAdministration();
                sa.setStatAdministartion(importFileData.getRows().get(0).get(1)
                        .toString().trim());
            } else {
                if (existStatAdmin.size() > 1) {
                    // throw error from here
                }
                sa = existStatAdmin.get(0);
            }

            try {
                sii = statServices.merge(sii);
                sa = statServices.merge(sa);

                OperationResult res = statServices.importStatistics(sa, sii,
                        importFileData);
                if (!res.isSuccess()
                        || (res instanceof MultipleResults && !((MultipleResults<?>) res)
                                .isAllSuccess())) { // That's likely to change
                                                    // if they want partial
                                                    // import

                    // this will also cascade delete all partially imported data
                    statServices.deleteStatAdministration(sa.getId());
                    return;
                }
                // Currently can only be success, as all errors will be rolled
                // back
                statServices
                        .updateStatus(
                                sii.getId(),
                                res.getStatus() == Status.OK ? StatAdministrationStatus.SUCCESS
                                        : StatAdministrationStatus.FAILURE);
                clear();
                // insert identifier id and admin id into stat_identifier_admin
                // table
                statServices.addAminAndIdentifier(sa.getId(), sii.getId());
                uploading = false;
                displayingResults = true;
            } catch (ServiceException e) {
                throw new ManagerException(e);
            }
            loadAdministrations();
            executeCheck = true;
            flag = false;
        }
    }

    private boolean checkDifferentAdmin(ImportFileData importFileData) {

        int rowsSize = importFileData.getRows().size();
        for (int i = 0; i < rowsSize; i++) {
            if (importFileData
                    .getRows()
                    .get(i)
                    .get(1)
                    .toString()
                    .trim()
                    .equalsIgnoreCase(
                            importFileData.getRows().get(0).get(1).toString()
                                    .trim())) {
                // do nothing
            } else {

                return false;

            }
        }

        return true;
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
            administrations = statServices
                    .findAdministrations(selectedItemBankId);
        } else {
            administrations = null;
        }
    }

    public List<StatImportIdentifier> getAdministrations() {
        return administrations;
    }

    public void setAdministrations(List<StatImportIdentifier> administrations) {
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
        return importFileData != null ? importFileData.getHeaders()
                : Collections.<String> emptyList();
    }

    public List<List<Object>> getImportResults() {
        return importFileData != null ? importFileData.getRows() : Collections
                .<List<Object>> emptyList();

    }

    public Map<String, String> getAllStatKey(List<String> stateColumnList) {

        List<StatKey> statKeyList = new ArrayList<StatKey>(
                statServices.findStatKeys(stateColumnList));

        Map<String, String> stateKeypair = new LinkedHashMap<String, String>();
        for (StatKey s : statKeyList) {
            stateKeypair.put(s.getName().toUpperCase(), s.getKeyType());
        }
        return stateKeypair;
    }
}
