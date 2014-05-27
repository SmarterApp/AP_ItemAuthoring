package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;
import javax.persistence.TypedQuery;
import javax.validation.ValidationException;

import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.SingleResult;
import com.pacificmetrics.common.Status;
import com.pacificmetrics.orca.StatServicesStatus;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.StatAdministration;
import com.pacificmetrics.orca.entities.StatItemValue;
import com.pacificmetrics.orca.entities.StatKey;
import com.pacificmetrics.orca.helpers.StatHelper.ImportFileData;

@Stateless
@LocalBean
public class StatServices implements Serializable {
    
    private static final long serialVersionUID = 1L;

    static private Logger logger = Logger.getLogger(StatServices.class.getName());
    
    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    protected EntityManager entityManager;
    
    @EJB
    private transient ItemServices itemServices;
    
    public StatAdministration findAdministrationById(int id) {
        return entityManager.find(StatAdministration.class, id);        
    }
    
    public List<StatAdministration> findAdministrations(int itemBankId) {
        TypedQuery<StatAdministration> query = entityManager.createNamedQuery("saByItemBankId", StatAdministration.class);
        query.setParameter("ib_id", itemBankId);
        return query.getResultList();   
    }
    
    public StatAdministration merge(StatAdministration statAdministration) throws ServiceException {
        try {
            return entityManager.merge(statAdministration);
        } catch (ValidationException e) {
            throw new ServiceException(e);
        }
    }
    
    public OperationResult importStatistics(StatAdministration sa, ImportFileData data) {
        logger.info("Importing statistics for " + sa.getId() + ": " + data.getRows().size() + " row(s)");
        List<String> keyNames = data.getHeaders().subList(1, data.getHeaders().size());
        List<StatKey> statKeyList = new ArrayList<StatKey>(findStatKeys(keyNames));
        if (keyNames.size() != statKeyList.size()) {
            List<String> keyNameList = new ArrayList<String>(keyNames);
            keyNameList.removeAll(getKeyNames(statKeyList));
            return new SingleResult(StatServicesStatus.IMPORT_UNKNOWN_FIELD, keyNameList.toString());
        }
        sortStatKeyList(statKeyList, keyNames);
        MultipleResults<String> result = new MultipleResults<String>();
        for (List<Object> values: data.getRows()) {
            Status status = importValues(sa, statKeyList, values);
            result.add((String)values.get(0), status);
        }
        if (result.getStatusMap().isEmpty()) {
            return new SingleResult(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        return result;
    }
    
    private void sortStatKeyList(List<StatKey> statKeyList, final List<String> keyNames) {
        Comparator<StatKey> c = new Comparator<StatKey>() {
            @Override
            public int compare(StatKey o1, StatKey o2) {
                return keyNames.indexOf(o1.getName().toUpperCase()) - keyNames.indexOf(o2.getName().toUpperCase());
            }
        };
        Collections.sort(statKeyList, c);
    }
    
    /**
     * Method reads item id and list of values from <b>values<b> parameter and populates database with them.
     * Verification is made to ensure correct number of values and their format
     * 
     * @param statKeyList List of keys to import
     * @param values 
     */
    public Status importValues(StatAdministration sa, List<StatKey> statKeyList, List<? extends Object> values) {
        if (values.size() != statKeyList.size() + 1) {
            return StatServicesStatus.IMPORT_INCORRECT_NUMBER_OF_VALUES;
        }
        Item item = itemServices.findItemByExternalId((String)values.get(0));
        if (item == null) {
            return StatServicesStatus.IMPORT_ITEM_NOT_FOUND;
        }
        if (item.getItemBankId() != sa.getItemBankId()) {
            return StatServicesStatus.IMPORT_WRONG_ITEM_BANK;
        }
        for (int i = 1; i < values.size(); i++) {
            Number d = (Number)values.get(i);
            StatItemValue statItemValue = new StatItemValue();
            statItemValue.setItemId(item.getId());
            statItemValue.setStatAdministrationId(sa.getId());
            statItemValue.setStatKeyId(statKeyList.get(i - 1).getId());
            statItemValue.setNumericValue(d.doubleValue());
            merge(statItemValue);
        }
        return Status.OK;
    }
    
    public StatItemValue merge(StatItemValue statItemValue) {
        return entityManager.merge(statItemValue);
    }
    
    public void deleteStatAdministration(int statAdministrationId) {
        Query query = entityManager.createNamedQuery("saDeleteForId");
        query.setParameter("id", statAdministrationId);
        query.executeUpdate();
    }
    
    public ArrayList<String> getKeyNames(List<StatKey> keys) {
        ArrayList<String> result = new ArrayList<String>();
        for (StatKey key: keys) {
            result.add(key.getName().toUpperCase());
        }
        return result;
    }
    
    /**
     * Method searches for StatKey instances with names in the given list. Key names in parameter must be upper cased.
     * @param keyNames
     * @return
     */
    public List<StatKey> findStatKeys(List<String> keyNames) {
        TypedQuery<StatKey> query = entityManager.createNamedQuery("skByNames", StatKey.class);
        query.setParameter("names", keyNames);
        return query.getResultList();
    }
    
    public void updateStatus(int saId, int status) {
        StatAdministration sa = entityManager.find(StatAdministration.class, saId);
        sa.setStatusId(status);
        entityManager.merge(sa);
    }
    
}
