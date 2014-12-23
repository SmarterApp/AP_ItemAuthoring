package com.pacificmetrics.orca.mbeans;

import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.RequestScoped;
import javax.faces.context.FacesContext;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.ejb.IBMetafileServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.PassageServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.entities.ItemMetafileAssociation;
import com.pacificmetrics.orca.entities.MetafileAssociation;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.utils.IBMetafileUtils;

@ManagedBean(name = "metafilesView")
@RequestScoped
public class IBMetafilesViewManager {

    private static final Log LOGGER = LogFactory
            .getLog(IBMetafilesViewManager.class);
    @EJB
    private transient IBMetafileServices metafileServices;

    @EJB
    private transient ItemServices itemServices;

    @EJB
    private transient PassageServices passageServices;

    private int itemId;
    private int passageId;
    private Item item;
    private Passage passage;
    private List<? extends MetafileAssociation> associations;

    private Map<Integer, Integer> latestVersionsMap;

    @PostConstruct
    public void load() {
        FacesContext context = FacesContext.getCurrentInstance();
        Map<String, String> paramMap = context.getExternalContext()
                .getRequestParameterMap();
        String itemParamValue = paramMap.get("item");
        String passageParamValue = paramMap.get("passage");
        if (itemParamValue != null) {
            itemId = Integer.parseInt(itemParamValue);
            item = itemServices.findItemById(itemId);
            associations = metafileServices
                    .getMetafileAssociationsForItem(itemId);
            latestVersionsMap = metafileServices
                    .getLatestVersionsMapForAssocations(associations);
        } else if (passageParamValue != null) {
            passageId = Integer.parseInt(passageParamValue);
            passage = passageServices.findPassageById(passageId);
            associations = metafileServices
                    .getMetafileAssociationsForPassage(passageId);
            latestVersionsMap = metafileServices
                    .getLatestVersionsMapForAssocations(associations);
        }
        if (associations != null) {
            LOGGER.info("Associations loaded: " + associations.size());
        }
    }

    public List<? extends MetafileAssociation> getAssociations() {
        return associations;
    }

    public void setAssociations(List<ItemMetafileAssociation> associations) {
        this.associations = associations;
    }

    public String getURL(ItemBankMetafile metafile) {
        return IBMetafileUtils.getMetafileURL(metafile);
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public boolean displayWarning(MetafileAssociation association) {
        Integer latestVersion = latestVersionsMap.get(association
                .getMetafileId());
        return latestVersion != null
                && latestVersion > association.getVersion();
    }

    public boolean hasWarnings() {
        for (MetafileAssociation association : associations) {
            if (displayWarning(association)) {
                return true;
            }
        }
        return false;
    }

    public Passage getPassage() {
        return passage;
    }

    public void setPassage(Passage passage) {
        this.passage = passage;
    }

}
