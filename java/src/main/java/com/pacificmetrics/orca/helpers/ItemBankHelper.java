package com.pacificmetrics.orca.helpers;

import java.util.ArrayList;
import java.util.List;

import javax.faces.model.SelectItem;

import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.User;

public class ItemBankHelper {
    
    private ItemBankServices itemBankServices;

    public ItemBankHelper(ItemBankServices itemBankServices) {
        super();
        this.itemBankServices = itemBankServices;
    }
    
    public List<SelectItem> getItemBankSelectItems(User user) {
        List<SelectItem> result = new ArrayList<SelectItem>();
        SelectItem si = new SelectItem(null, "Select Program...");
        si.setNoSelectionOption(true);
        result.add(si);
        for (ItemBank itemBank: itemBankServices.getItemBanksForUser(user)) {
            SelectItem selectItem = new SelectItem(itemBank.getId(), itemBank.getExternalId());
            result.add(selectItem);
        }
        return result;
    }
    
    

}
