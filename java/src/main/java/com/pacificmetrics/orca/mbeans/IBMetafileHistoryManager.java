package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.context.FacesContext;

import com.pacificmetrics.orca.ejb.IBMetafileServices;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.utils.IBMetafileUtils;

@ManagedBean(name="metafileHistory")
@ViewScoped
public class IBMetafileHistoryManager extends AbstractManager implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@EJB 
	transient private IBMetafileServices metafileServices;
	
	private List<ItemBankMetafile> metafiles;
	
	public IBMetafileHistoryManager() {
	}
	
	@PostConstruct
	public void load() {
		FacesContext context = FacesContext.getCurrentInstance();
        Map<String, String> paramMap = context.getExternalContext().getRequestParameterMap();
        String metafileParamValue = paramMap.get("metafile");
        if (metafileParamValue != null) {
        	int metafileId = Integer.parseInt(metafileParamValue);
			metafiles = metafileServices.getMetafileHistory(metafileId);
		} else {
			metafiles = Collections.emptyList();
		}
	}
	
	public String getURL(ItemBankMetafile ibm) {
		return (IBMetafileUtils.getMetafileURL(ibm.getItemBankId())) + "/" + ibm.getSystemName();
	}

	public List<ItemBankMetafile> getMetafiles() {
		return metafiles;
	}
	
}
