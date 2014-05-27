package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.context.FacesContext;

import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.orca.IBMetafileServicesStatus;
import com.pacificmetrics.orca.ejb.IBMetafileServices;
import com.pacificmetrics.orca.ejb.PassageServices;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageMetafileAssociation;

@ManagedBean(name="metafilePassageAssoc")
@ViewScoped
public class IBMetafilePassageAssociationManager extends AbstractManager implements Serializable {
	
	private static final long serialVersionUID = 1L;

	@EJB
	transient private IBMetafileServices metafileServices;
	
	@EJB
	transient private PassageServices passageServices;

	private List<Passage> allPassages = new ArrayList<Passage>();
	private List<PassageMetafileAssociation> existingPassageAssociations;
	private List<PassageMetafileAssociation> outdatedPassageAssociations;
	private int metafileId;
	private int version;
	private ItemBankMetafile metafile;
	private int selectedPageIndex;
	
	private List<Integer> selectedPassages;
	private List<Integer> selectedExistingPassages;
	private List<Integer> selectedOutdatedPassages;
	
	@PostConstruct
	public void load() {
		FacesContext context = FacesContext.getCurrentInstance();
        Map<String, String> paramMap = context.getExternalContext().getRequestParameterMap();
        String metafileParamValue = paramMap.get("metafile");
        String versionParamValue = paramMap.get("version");
        if (metafileParamValue != null && versionParamValue != null) {
        	metafileId = Integer.parseInt(metafileParamValue);
        	version = Integer.parseInt(versionParamValue);
        	metafile = metafileServices.findMetafileByIdAndVersion(metafileId, version);
        	//
        	allPassages = passageServices.getPassagesByBankId(metafile.getItemBankId());
        	updateAssociations();
        }
	}
	
	private void clear() {
		selectedPassages = null;
		selectedExistingPassages = null;
	}

	public List<Passage> getAllPassages() {
		return allPassages;
	}

	public void setAllPassages(List<Passage> allPassages) {
		this.allPassages = allPassages;
	}

	public int getMetafileId() {
		return metafileId;
	}

	public void setMetafileId(int metafileId) {
		this.metafileId = metafileId;
	}

	public int getVersion() {
		return version;
	}

	public void setVersion(int version) {
		this.version = version;
	}

	public ItemBankMetafile getMetafile() {
		return metafile;
	}

	public void setMetafile(ItemBankMetafile metafile) {
		this.metafile = metafile;
	}

	public int getSelectedPageIndex() {
		return selectedPageIndex;
	}

	public void setSelectedPageIndex(int selectedPageIndex) {
		this.selectedPageIndex = selectedPageIndex;
	}
	
	public void confirmNewIDs() {
		if (selectedPassages == null || selectedPassages.isEmpty()) {
			error(IBMetafileServicesStatus.NOTHING_TO_PROCESS);
			return;
		}
		OperationResult res = metafileServices.associatePassagesWithMetafile(metafileId, version, selectedPassages);
		handleOperationResult(res);
		selectedPageIndex = 0;
		selectedPassages = null;
		updateAssociations();
	}
	
	private void updateAssociations() {
		existingPassageAssociations = metafileServices.getPassageAssociations(metafileId, version);
		outdatedPassageAssociations = metafileServices.getPassageAssociationsOutdated(metafileId);
	}
	
	public List<Integer> getSelectedPassages() {
		return selectedPassages;
	}

	public void setSelectedPassages(List<Integer> selectedPassages) {
		this.selectedPassages = selectedPassages;
	}

	public List<PassageMetafileAssociation> getExistingPassageAssociations() {
		return existingPassageAssociations;
	}

	public void setExistingPassageAssociations(List<PassageMetafileAssociation> existingPassageAssociations) {
		this.existingPassageAssociations = existingPassageAssociations;
	}

	public List<Integer> getSelectedExistingPassages() {
		return selectedExistingPassages;
	}

	public void setSelectedExistingPassages(List<Integer> selectedExistingPassages) {
		this.selectedExistingPassages = selectedExistingPassages;
	}
	
	public void removeSelected() {
		remove(selectedExistingPassages);
	}
	
	public void removeAll() {
		List<Integer> associationIds = new ArrayList<Integer>();
		for (PassageMetafileAssociation pma: existingPassageAssociations) {
			associationIds.add(pma.getId());
		}
		remove(associationIds);
	}
	
	private void remove(List<Integer> associationIds) {
		OperationResult res = metafileServices.unassociatePassages(metafileId, version, associationIds);
		handleOperationResult(res);
		updateAssociations();
		clear();
		selectedPageIndex = 1;
	}

	public List<PassageMetafileAssociation> getOutdatedPassageAssociations() {
		return outdatedPassageAssociations;
	}

	public void setOutdatedPassageAssociations(
			List<PassageMetafileAssociation> outdatedPassageAssociations) {
		this.outdatedPassageAssociations = outdatedPassageAssociations;
	}

	public List<Integer> getSelectedOutdatedPassages() {
		return selectedOutdatedPassages;
	}

	public void setSelectedOutdatedPassages(List<Integer> selectedOutdatedPassages) {
		this.selectedOutdatedPassages = selectedOutdatedPassages;
	}
	
	public void updateSelected() {
		update(selectedOutdatedPassages);
	}
	
	public void updateAll() {
		List<Integer> associationIds = new ArrayList<Integer>();
		for (PassageMetafileAssociation pma: outdatedPassageAssociations) {
			associationIds.add(pma.getId());
		}
		update(associationIds);
	}
	
	private void update(List<Integer> associationIds) {
		OperationResult res = metafileServices.updatePassageAssociations(metafileId, version, associationIds);
		handleOperationResult(res);
		updateAssociations();
		clear();
		selectedPageIndex = 2;
	}

}
