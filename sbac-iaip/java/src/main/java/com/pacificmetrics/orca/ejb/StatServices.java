package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.logging.Level;
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
import com.pacificmetrics.orca.entities.StatImportIdentifier;
import com.pacificmetrics.orca.entities.StatItemValue;
import com.pacificmetrics.orca.entities.StatKey;
import com.pacificmetrics.orca.helpers.StatHelper.ImportFileData;

@Stateless
@LocalBean
public class StatServices implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = Logger.getLogger(StatServices.class
            .getName());

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    protected EntityManager entityManager;

    @EJB
    private transient ItemServices itemServices;

    public StatImportIdentifier findAdministrationById(int id) {
        return entityManager.find(StatImportIdentifier.class, id);
    }

    public List<StatImportIdentifier> findAdministrations(int itemBankId) {
        TypedQuery<StatImportIdentifier> query = entityManager
                .createNamedQuery("saByItemBankId", StatImportIdentifier.class);
        query.setParameter("ib_id", itemBankId);
        return query.getResultList();
    }

    public StatAdministration merge(StatAdministration statAdministration)
            throws ServiceException {
        try {
            return entityManager.merge(statAdministration);
        } catch (ValidationException e) {
            throw new ServiceException(e);
        }
    }

    public StatImportIdentifier merge(StatImportIdentifier statImportIdentifier)
            throws ServiceException {
        try {
            return entityManager.merge(statImportIdentifier);
        } catch (ValidationException e) {
            throw new ServiceException(e);
        }
    }

    public OperationResult importStatistics(StatAdministration sa,
            StatImportIdentifier sii, ImportFileData data) {
        LOGGER.info("Importing statistics for " + sa.getId() + ": "
                + data.getRows().size() + " row(s)");
        // value 1 changed to 2
        List<String> keyNames = data.getHeaders().subList(2,
                data.getHeaders().size());
        List<StatKey> statKeyList = new ArrayList<StatKey>(
                findStatKeys(keyNames));
        if (keyNames.size() != statKeyList.size()) {
            List<String> keyNameList = new ArrayList<String>(keyNames);
            keyNameList.removeAll(getKeyNames(statKeyList));
            return new SingleResult(StatServicesStatus.IMPORT_UNKNOWN_FIELD,
                    keyNameList.toString());
        }
        sortStatKeyList(statKeyList, keyNames);
        MultipleResults<String> result = new MultipleResults<String>();
        for (List<Object> values : data.getRows()) {
            Status status = importValues(sa, sii, statKeyList, values);
            result.add((String) values.get(0), status);
        }
        if (result.getStatusMap().isEmpty()) {
            return new SingleResult(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        return result;
    }

    private void sortStatKeyList(List<StatKey> statKeyList,
            final List<String> keyNames) {
        Comparator<StatKey> c = new Comparator<StatKey>() {
            @Override
            public int compare(StatKey o1, StatKey o2) {
                return keyNames.indexOf(o1.getName().toUpperCase())
                        - keyNames.indexOf(o2.getName().toUpperCase());
            }
        };
        Collections.sort(statKeyList, c);
    }

    /**
     * Method reads item id and list of values from <b>values<b> parameter and
     * populates database with them. Verification is made to ensure correct
     * number of values and their format
     * 
     * @param statKeyList
     *            List of keys to import
     * @param values
     */
    public Status importValues(StatAdministration sa, StatImportIdentifier sii,
            List<StatKey> statKeyList, List<? extends Object> values) {
        // value 1 changed to 2
        if (values.size() != statKeyList.size() + 2) {
            return StatServicesStatus.IMPORT_INCORRECT_NUMBER_OF_VALUES;
        }
        Item item = itemServices.findItemByExternalId((String) values.get(0));
        if (item == null) {
            return StatServicesStatus.IMPORT_ITEM_NOT_FOUND;
        }
        if (item.getItemBankId() != sii.getItemBankId()) {
            return StatServicesStatus.IMPORT_WRONG_ITEM_BANK;
        }
        // validation will go here

        for (int i = 2; i < values.size(); i++) {
            deleteItemStatInfo(item.getId(), sa.getId(), statKeyList.get(i - 2)
                    .getId());

            String d = "";
            if (values.get(i) == null) {
                d = null;
            } else {
                d = values.get(i).toString();
            }
            StatItemValue statItemValue = new StatItemValue();
            statItemValue.setItemId(item.getId());
            statItemValue.setStatAdministrationId(sa.getId());
            statItemValue.setStatKeyId(statKeyList.get(i - 2).getId());
            statItemValue.setNumericValue(d);
            merge(statItemValue);
        }
        return Status.OK;
    }

    private void deleteItemStatInfo(long id, int statAdministartion,
            int statKeyId) {
        Query query = entityManager
                .createNativeQuery("delete from stat_item_value where i_id = ? and sa_id = ? and sk_id = ?");
        query.setParameter(1, id);
        query.setParameter(2, statAdministartion);
        query.setParameter(3, statKeyId);
        query.executeUpdate();

    }

    public StatItemValue merge(StatItemValue statItemValue) {
        return entityManager.merge(statItemValue);
    }

    public void deleteStatAdministration(int statAdministrationId) {
        Query query = entityManager.createNamedQuery("saDeleteForId");
        query.setParameter("id", statAdministrationId);
        query.executeUpdate();
    }

    public List<String> getKeyNames(List<StatKey> keys) {
        List<String> result = new ArrayList<String>();
        for (StatKey key : keys) {
            result.add(key.getName().toUpperCase());
        }
        return result;
    }

    /**
     * Method searches for StatKey instances with names in the given list. Key
     * names in parameter must be upper cased.
     * 
     * @param keyNames
     * @return
     */
    public List<StatKey> findStatKeys(List<String> keyNames) {
        TypedQuery<StatKey> query = entityManager.createNamedQuery("skByNames",
                StatKey.class);
        query.setParameter("names", keyNames);
        return query.getResultList();

    }

    public void updateStatus(int saId, int status) {
        StatImportIdentifier sa = entityManager.find(
                StatImportIdentifier.class, saId);
        sa.setStatusId(status);
        entityManager.merge(sa);
    }

    public List<StatAdministration> checkAdminExistence(String admin) {
        List<StatAdministration> statAdmin = null;
        try {
            TypedQuery<StatAdministration> query = entityManager
                    .createQuery(
                            "SELECT sa FROM StatAdministration sa WHERE sa.statAdministartion = :admin",
                            StatAdministration.class);
            query.setParameter("admin", admin);
            statAdmin = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error to check AdminExistency for "
                    + admin + ": " + e.getMessage(), e);
        }
        return statAdmin;
    }

    public boolean checkAdminAndItemCombination(long itemId, Object admin) {
        Query query = entityManager
                .createNativeQuery("select * from stat_item_value  where i_id = ? and sa_id = ?");
        query.setParameter(1, itemId);
        query.setParameter(2, admin.toString());
        List<Object> o = query.getResultList();
        if (!o.isEmpty()) {
            return true;
        }
        return false;
    }

    public int getAdminIdByName(String string) {
        List<StatAdministration> statAdmin = null;
        try {
            TypedQuery<StatAdministration> query = entityManager
                    .createQuery(
                            "SELECT sa FROM StatAdministration sa WHERE sa.statAdministartion = :admin",
                            StatAdministration.class);
            query.setParameter("admin", string);
            statAdmin = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error to get AdminId for " + string
                    + ": " + e.getMessage(), e);
        }
        if (statAdmin.isEmpty()) {
            return 0;
        }

        return statAdmin.get(0).getId();
    }

    public void addAminAndIdentifier(int adminId, int identifierId) {

        Query query = entityManager
                .createNativeQuery("insert into stat_identifier_admin(sii_id,sa_id) values (?,?)");
        query.setParameter(1, identifierId);
        query.setParameter(2, adminId);
        query.executeUpdate();
    }

}
