package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.orca.ItemBankServicesStatus;
import com.pacificmetrics.orca.ORCAConstants;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.entities.UserPermission;

@Stateless
@LocalBean
public class ItemBankServices implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;
	
	@SuppressWarnings("unchecked")
	public List<ItemBank> getAllItemBanks() {
		Query query = entityManager.createNamedQuery("allItemBanks");
		return query.getResultList();
	}
	
	public ItemBank findItemBank(int itemBankId) {
	    return entityManager.find(ItemBank.class, itemBankId);
	}
	
	public String getItemBankName(int itemBankId) throws ServiceException {
	    ItemBank itemBank = findItemBank(itemBankId);
	    if (itemBank == null) {
	        throw new ServiceException(ItemBankServicesStatus.ITEM_BANK_NOT_FOUND);
	    }
	    return itemBank.getExternalId();
	}

	public List<ItemBank> getItemBanksForUser(User user) {
		List<ItemBank> result = new ArrayList<ItemBank>();
		List<UserPermission> userPermissions = user.findUserPermissions(ORCAConstants.UP_ITEM_BANK);
		for (ItemBank itemBank: getAllItemBanks()) {
			for (UserPermission userPermission: userPermissions) {
				if (userPermission.getValue() == itemBank.getId()) {
					result.add(itemBank);
					break;
				}
			}
		}
		return result;
	}

}
