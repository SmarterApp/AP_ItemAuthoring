package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.application.FacesMessage;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.component.UIComponent;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;
import javax.faces.model.SelectItem;
import javax.validation.constraints.Size;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.myfaces.custom.fileupload.UploadedFile;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.orca.ejb.IBMetafileServices;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.UserServices;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.utils.IBMetafileUtils;

@ManagedBean(name="metafiles")
@ViewScoped
public class IBMetafileManager extends AbstractManager implements Serializable {

    static private Logger logger = Logger.getLogger(IBMetafileManager.class.getName()); 
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@EJB 
	transient private IBMetafileServices metafileServices;

	@EJB 
	transient private ItemBankServices itemBankServices;
	
	@EJB
	private transient UserServices userServices;
	
	private List<ItemBankMetafile> metafileList;
	private List<ItemBankMetafile> unfilteredMetafileList;
	private List<ItemBank> itemBankList;
	private String newFileName;
	
	@Size(max=240)
	private String newComment;
	private String selectedItemBank;
	private String searchText;
	private int fileTypeCode = ItemBankMetafile.TC_OTHER;
	private int firstRowIndex;
	private boolean editingFile;
	
	private ItemBankMetafile metafileToUpdate;
	
	private UploadedFile uploadedFile;
	
	private boolean updateAssociations;
	
	private UIComponent comp1;
	
	private List<SelectItem> fileTypeSelectItems;

	
	public IBMetafileManager() {
		fillFileTypeSelectItems();
	}
	
	@PostConstruct
	public void load() {
		itemBankList = itemBankServices.getItemBanksForUser(userServices.getUser());
		logger.info("Item banks loaded. Count = " + itemBankList.size());
	}
	
	public List<ItemBankMetafile> getAllMetafiles() {
		if (metafileList == null && !StringUtils.isEmpty(selectedItemBank) && metafileServices != null) {
			unfilteredMetafileList = metafileList = metafileServices.getMetafiles(Integer.parseInt(selectedItemBank));
			setFirstRowIndex(0);
		}
		if (metafileList != null) {
			filter();
		}
		return metafileList != null ? metafileList : Collections.<ItemBankMetafile>emptyList();
	}

	public Map<String, Integer> getItemBankNamesMap() {
		Map<String, Integer> result = new TreeMap<String, Integer>();
		for (ItemBank itemBank: itemBankList) {
			result.put(itemBank.getExternalId(), itemBank.getId());
		}
		return result;
	}

	public String getNewFileName() {
		return newFileName;
	}

	public void setNewFileName(String newFileName) {
		this.newFileName = newFileName;
	}

	public String getNewComment() {
		return newComment;
	}

	public void setNewComment(String newComment) {
		this.newComment = newComment;
	}
	
//	public String addNewFile() {
//		System.out.println("add new file executed");
//		if (!StringUtils.isEmpty(selectedItemBank)) {
//			metafileServices.addMetafile(Integer.parseInt(selectedItemBank), newFileName, "unknown", newComment);
//			metafileList = null;
//			clear();
//		}
//		return null;
//	}

	public String getSelectedItemBank() {
		return selectedItemBank;
	}

	public void setSelectedItemBank(String selectedItemBank) {
		if (!selectedItemBank.equals(this.selectedItemBank)) {
			this.selectedItemBank = selectedItemBank;
			metafileList = null;
			clear();
		}
	}
	
	public void itemBankSelected(ValueChangeEvent valueChangeEvent) {
		System.out.println("itemBankSelected: " + valueChangeEvent);
	}

	public String getSearchText() {
		return searchText;
	}

	public void setSearchText(String searchText) {
		this.searchText = searchText;
	}
	
	public void doSearch() {
		clear();
		setFirstRowIndex(0);
	}
	
	public void addNewFile() {
		resetValues("fileUploadForm");
		clear();
		editingFile = true;
	}

	public UploadedFile getUploadedFile() {
		return uploadedFile;
	}

	public void setUploadedFile(UploadedFile uploadedFile) {
		this.uploadedFile = uploadedFile;
	}
	
	public void uploadFile() {
		String fileName = getFileName();
		logger.info("Uploading file: " + fileName + ", type: " + uploadedFile.getContentType());
		ItemBankMetafile metafile;
		try {
			if (metafileToUpdate != null) { //updating existing file
				metafile = metafileServices.updateMetafile(metafileToUpdate.getId(), metafileToUpdate.getVersion(), fileName, 
	                                                       uploadedFile.getContentType(), newComment, fileTypeCode, updateAssociations);
			} else {
				if (StringUtils.isEmpty(selectedItemBank)) {
					super.errorMsg("No program selected");
					return;
				}
				int ibId = Integer.parseInt(selectedItemBank);
				metafile = metafileServices.addMetafile(ibId, fileName, uploadedFile.getContentType(), newComment, fileTypeCode);
			}
			storeMetafile(metafile);
			metafileList = null;
			clear();
		} catch (ServiceException e) {
			super.error(e);
		}
	}
	
	public void cancelUploadFile() {
		editingFile = false;
	}
	
	private String getFileName() {
		logger.info("Uploading file: " + uploadedFile.getName());
		StringBuffer result = new StringBuffer(FilenameUtils.getName(uploadedFile.getName()));
		for (int i = 0; i < result.length(); i++) {
			char ch = result.charAt(i);
			if (ch < ' ' || ch > 255 || ch == '*' || ch == '?' || ch == '/' || ch == '\\' || ch == '%' || ch == ':' || ch == '|' || ch == '"' || ch == '<' || ch == '>') {
				result.setCharAt(i, '_');
			}
		}
		return result.toString().replaceAll("&#\\d+;", "_");
	}
	
	private void storeMetafile(ItemBankMetafile metafile) {
		try {
			metafileServices.storeMetafile(metafile, uploadedFile.getBytes());
		} catch (IOException e) {
			error("Can't store metafile: " + e);
		}
	}
	
	public void actionOnMetafile(ItemBankMetafile metafile) {
		System.out.println("action on " + metafile);
	}
	
	public void deleteActionOnMetafile(ItemBankMetafile metafile) {
		if (metafileServices.isMetafileAssociatedWithItems(metafile.getId()) ||
			metafileServices.isMetafileAssociatedWithPassages(metafile.getId())) 
		{
			error("This metafile is associated with item(s) and/or passage(s). It cannot be deleted");
			return;
		}
		try {
			metafileServices.deleteMetafile(metafile.getItemBankId(), metafile.getSystemName());
		} catch (IOException e) {
			error("Can't delete metafile: " + e);
			return; 
		}
		metafileServices.removeMetafile(metafile.getId(), metafile.getVersion());
		metafileList = null;
		clear();
	}
	
	public void updateActionOnMetafile(ItemBankMetafile metafile) {
		logger.info("update action on " + metafile);
		resetValues("fileUploadForm");
		metafileToUpdate = metafile;
		newComment = metafile.getComment();
		fileTypeCode = metafile.getTypeCode();
		if (fileTypeCode < 1) {
			fileTypeCode = ItemBankMetafile.TC_OTHER;
		}
		editingFile = true;
	}
	
	public void actionEvent(ActionEvent evt) {
		System.out.println("event: " + evt);
	}

	public void actionSelected(ValueChangeEvent valueChangeEvent) {
		System.out.println("actionSelected: " + valueChangeEvent);
	}

	public void error(String msg) {
		FacesContext.getCurrentInstance().addMessage(null, new FacesMessage(msg));
		System.out.println(msg); //TODO fix error messaging as the whole
	}

	public ItemBankMetafile getMetafileToUpdate() {
		return metafileToUpdate;
	}

	public void setMetafileToUpdate(ItemBankMetafile metafileToUpdate) {
		this.metafileToUpdate = metafileToUpdate;
	}
	
	public void cancelUpdate() {
		System.out.println("Update cancelled");
		resetValues("fileUploadForm");
		clear();
	}
	
	public UIComponent getComp1() {
		return comp1;
	}

	public void setComp1(UIComponent comp1) {
		this.comp1 = comp1;
	}
	
	public void scrollerAction() {
		clear();
	}
	
	private void clear() {
		metafileToUpdate = null;
		newFileName = null;
		newComment = null;
		fileTypeCode = ItemBankMetafile.TC_OTHER;
		editingFile = false;
		updateAssociations = false;
	}
	
	public String getURL(ItemBankMetafile ibm) {
		return (IBMetafileUtils.getMetafileURL(ibm.getItemBankId())) + "/" + ibm.getSystemName();
	}
	
	public void clearSearch() {
		clear();
		searchText = null;
		metafileList = unfilteredMetafileList;
		setFirstRowIndex(0);
	}
	
	public void filter() {
		if (StringUtils.isEmpty(searchText)) {
		    clearSearch();
			return;
		}
		List<ItemBankMetafile> newMetafileList = new ArrayList<ItemBankMetafile>();
		for (ItemBankMetafile metafile: unfilteredMetafileList) {
			if (metafile.getOriginalFileName().toUpperCase().contains(searchText.toUpperCase()) ||
				metafile.getComment().toUpperCase().contains(searchText.toUpperCase()))
			{
				newMetafileList.add(metafile);
			}
		}
		metafileList = newMetafileList;
	}

	public int getFirstRowIndex() {
		return firstRowIndex;
	}

	public void setFirstRowIndex(int firstRowIndex) {
		this.firstRowIndex = firstRowIndex;
	}
	
	public String getMetafileParams() {
		if (metafileToUpdate == null) {
			return "";
		}
		return "metafile=" + metafileToUpdate.getId() + "&version=" + metafileToUpdate.getVersion();
	}

	public boolean isUpdateAssociations() {
		return updateAssociations;
	}

	public void setUpdateAssociations(boolean updateAssociations) {
		this.updateAssociations = updateAssociations;
	}

	public int getFileTypeCode() {
		return fileTypeCode;
	}

	public void setFileTypeCode(int fileTypeCode) {
		this.fileTypeCode = fileTypeCode;
	}
	
	public void fillFileTypeSelectItems() {
		fileTypeSelectItems = new ArrayList<SelectItem>();
		for (Map.Entry<Integer, String> entry: ItemBankMetafile.TYPES_MAP.entrySet()) {
			SelectItem selectItem = new SelectItem(entry.getKey(), entry.getValue());
			fileTypeSelectItems.add(selectItem);
		}
	}

	public List<SelectItem> getFileTypeSelectItems() {
		return fileTypeSelectItems;
	}

	public void setFileTypeSelectItems(List<SelectItem> fileTypeSelectItems) {
		this.fileTypeSelectItems = fileTypeSelectItems;
	}
	
	public boolean isSearchingText() {
		return !StringUtils.isEmpty(searchText);
	}
	
	public boolean isExistingFile() {
		return metafileToUpdate != null;
	}

	public boolean isEditingFile() {
		return editingFile;
	}

}
