package com.pacificmetrics.orca.ejb;

import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import org.apache.commons.io.FileUtils;

import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.SingleResult;
import com.pacificmetrics.common.Status;
import com.pacificmetrics.orca.IBMetafileServicesStatus;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemBankMetafile;
import com.pacificmetrics.orca.entities.ItemBankMetafilePK;
import com.pacificmetrics.orca.entities.ItemMetafileAssociation;
import com.pacificmetrics.orca.entities.MetafileAssociation;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageMetafileAssociation;
import com.pacificmetrics.orca.utils.IBMetafileUtils;

@Stateless
@LocalBean
public class IBMetafileServices implements Serializable {
	
	
	private static final long serialVersionUID = 1L;
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;
	
	@EJB
	private transient ItemServices itemServices;
	
	@EJB
	private transient PassageServices passageServices;
	
	@SuppressWarnings("unchecked")
	public List<ItemBankMetafile> getAllMetafiles() {
		if (entityManager != null) { 
			Query query = entityManager.createQuery("select ibm from ItemBankMetafile ibm order by ibm.timestamp desc");
			return query.getResultList();
		} else {
			return new ArrayList<ItemBankMetafile>();
		}
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemBankMetafile> getMetafileHistory(int metafileId) {
		Query query = entityManager.createNamedQuery("metafilesByIdOrderByVersionDesc");
		query.setParameter("id", metafileId);
		return query.getResultList();
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemBankMetafile> getMetafiles(int itemBankId) {
		if (entityManager != null) { 
			String queryStr = "SELECT ibm.* FROM item_bank_metafiles ibm " + 
						      "INNER JOIN (SELECT ibm_id, MAX(ibm_version) AS max_version FROM item_bank_metafiles GROUP BY ibm_id) ibm3 " +
						      "ON ibm.ibm_id = ibm3.ibm_id AND ibm.ibm_version = ibm3.max_version WHERE ib_id = " + itemBankId + 
						      " ORDER BY ibm.ibm_timestamp DESC";
			Query query = entityManager.createNativeQuery(queryStr, ItemBankMetafile.class);
			return query.getResultList();
		} else {
			return new ArrayList<ItemBankMetafile>();
		}
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemMetafileAssociation> getMetafileAssociationsForItem(int itemId) {
		Query query = entityManager.createNamedQuery("itemAssociationByItem");
		query.setParameter("item_id", itemId);
		return query.getResultList();
	}
	
	public ItemBankMetafile findMetafile(int itemBankId, String fileName) {
		if (entityManager != null) { 
			Query query = entityManager.createNamedQuery("metafilesByBankIdAndName");
			query.setParameter("ib_id", itemBankId);
			query.setParameter("file_name", fileName);
			List<?> resultList = query.getResultList();
			return resultList != null && !resultList.isEmpty() ? (ItemBankMetafile)resultList.get(0) : null;
		} else {
			return null;
		}
	}
	
	public ItemBankMetafile findMetafileByIdAndVersion(int metafileId, int version) {
		if (entityManager != null) { 
			return entityManager.find(ItemBankMetafile.class, new ItemBankMetafilePK(metafileId, version));
		} else {
			return null;
		}
	}
	

	
	public ItemBankMetafile addMetafile(int ibId, String fileName, String fileType, String comment, int typeCode) throws ServiceException {
		return addMetafile(ibId, fileName, 0, fileType, comment, null, typeCode);
	}
	
	public ItemBankMetafile addMetafile(int ibId, String fileName, int version, String fileType, String comment, Integer metafileId, int typeCode) throws ServiceException {
		checkFile(fileName, fileType);
		//Checking if metafile with the same name and different metafile id already exists. If so, can't update 
		if (!checkExistingMetaFile(ibId, fileName, metafileId != null ? metafileId : -1)) {
			throw new ServiceException(IBMetafileServicesStatus.METAFILE_NAME_ALREADY_EXISTS, fileName);
		}
		ItemBankMetafile ibm = new ItemBankMetafile();
		Integer	metafileIdLocal = metafileId;
		if (metafileIdLocal == null) {
			metafileIdLocal = getMaxMetafileId() + 1;
		}
		ibm.setId(metafileIdLocal);
		ibm.setItemBankId(ibId);
		ibm.setOriginalFileName(fileName);
		ibm.setVersion(version);
		ibm.setFileType(fileType);
		ibm.setComment(comment);
		ibm.setSystemName(metafileIdLocal + "." + version + "-" + fileName);
		ibm.setTypeCode(typeCode);
		ibm = entityManager.merge(ibm);
		return ibm;
	}
	
	public void removeMetafile(int metafileId, int version) {
		ItemBankMetafile ibm = findMetafileByIdAndVersion(metafileId, version);
		if (ibm != null) {
			entityManager.remove(ibm);
		}
	}
	
	public void storeMetafile(ItemBankMetafile ibm, byte[] content) throws IOException {
		String dirName = IBMetafileUtils.getMetafileDirName(ibm.getItemBankId());
		File directory = new File(dirName);
		directory.mkdirs();
		File file = new File(dirName, ibm.getSystemName());
		FileUtils.writeByteArrayToFile(file, content);
	}
	
	public void deleteMetafile(int ibId, String fileName) throws IOException {
		String dirName = IBMetafileUtils.getMetafileDirName(ibId);
		File file = new File(dirName, fileName);
		file.delete();
	}

	/**
	 * Checks if metafile with the given name exists for the item bank with given Id. 
	 * If metafile Id is supplied and found metafile has the same id, method returns false
	 * 
	 * @param itemBankId
	 * @param fileName
	 * @param metafileId
	 * @return
	 */
	public boolean checkExistingMetaFile(int itemBankId, String fileName, int metafileId) {
		ItemBankMetafile existingMetafile = findMetafile(itemBankId, fileName);
		if (existingMetafile != null && (metafileId < 0 || existingMetafile.getId() != metafileId)) {
			return false;
		}
		return true;
	}
	
	public ItemBankMetafile updateMetafile(int metafileId, int version, String fileName, String fileType, String comment, int typeCode, boolean updateAssociations) throws ServiceException {
		checkFile(fileName, fileType);
		ItemBankMetafile existingIBM = findMetafileByIdAndVersion(metafileId, version);
		//Checking if latest version is the given version. Otherwise file was updated by someone else, so can't update
		int latestVersion = getLatestVersion(metafileId);
		if (latestVersion != version) {
			throw new ServiceException(IBMetafileServicesStatus.METAFILE_NEWER_VERSION_EXISTS, existingIBM.getOriginalFileName() + ", version " + existingIBM.getVersion());
		}
		//TODO figure out how to return status, so user can get meaningful message when can't update
		ItemBankMetafile result = addMetafile(existingIBM.getItemBankId(), fileName, version + 1, fileType, comment, metafileId, typeCode);
		//If needed, updating existing associations with the latest version
		if (updateAssociations) {
			updateAllItemAssociations(metafileId, result.getVersion());
			updateAllPassageAssociations(metafileId, result.getVersion());
		}
		return result;
	}
	
	public OperationResult updateAllItemAssociations(int metafileId, int version) {
		List<ItemMetafileAssociation> associations = getItemAssociations(metafileId);
		for (ItemMetafileAssociation ima: associations) {
			if (ima.getVersion() < version) {
				ima.setVersion(version);
				entityManager.merge(ima);
			}
		}
		return new SingleResult(Status.OK);
	}
	
	public int getMaxMetafileId() {
		if (entityManager != null) { 
			Query query = entityManager.createNamedQuery("maxId");
			return (Integer)query.getSingleResult();
		} else {
			return 0;
		}
	}
	
	public OperationResult associateItemsWithMetafile(int metafileId, int version, String[] itemIDs) {
		ItemBankMetafile ibm = findMetafileByIdAndVersion(metafileId, version);
		if (ibm == null) {
			return new SingleResult(IBMetafileServicesStatus.METAFILE_NOT_FOUND);
		}
		MultipleResults<String> result = new MultipleResults<String>();
		for (String itemID: itemIDs) {
			Item item = itemServices.findItemByItemBankAndExternalId(ibm.getItemBankId(), itemID);
			if (item == null) {
				result.add(itemID, IBMetafileServicesStatus.ITEM_NOT_FOUND);
			} else {
				if (isItemAssociatedWithMetafile(item.getId(), metafileId)) {
					result.add(itemID, IBMetafileServicesStatus.METAFILE_ALREADY_ASSOCIATED);
				} else {
					ItemMetafileAssociation ima = new ItemMetafileAssociation();
					ima.setMetafile(ibm);
					ima.setItem(item);
					entityManager.persist(ima);
					result.add(itemID, Status.OK);
				}
			}
		}
		result.setStatus(Status.OK);
		return result;
	}
	
	public boolean isMetafileAssociatedWithItems(int metafileId) {
		Query query = entityManager.createNamedQuery("itemAssociationCountByMetafile");
		query.setParameter("metafile_id", metafileId);
		Number count = (Number)query.getSingleResult();
		return count.intValue() > 0;
	}
	
	public boolean isItemAssociatedWithMetafile(long itemId, int metafileId) {
		Query query = entityManager.createNamedQuery("itemAssociationByItemAndMetafile");
		query.setParameter("item_id", itemId);
		query.setParameter("metafile_id", metafileId);
		return !query.getResultList().isEmpty();
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemMetafileAssociation> getItemAssociations(int metafileId) {
		Query query = entityManager.createNamedQuery("itemAssociationByMetafile");
		query.setParameter("metafile_id", metafileId);
		return query.getResultList();
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemMetafileAssociation> getItemAssociationsOutdated(int metafileId) {
		Query query = entityManager.createNamedQuery("itemAssociationByMetafileOutdated");
		query.setParameter("metafile_id", metafileId);
		return query.getResultList();
	}
	
	@SuppressWarnings("unchecked")
	public List<ItemMetafileAssociation> getItemAssociations(int metafileId, int version) {
		Query query = entityManager.createNamedQuery("itemAssociationByMetafileAndVersion");
		query.setParameter("metafile_id", metafileId);
		query.setParameter("version", version);
		return query.getResultList();
	}
	
	public OperationResult unassociateItems(int metafileId, int version, List<Integer> associationIds) {
		return unassociate(ItemMetafileAssociation.class, metafileId, version, associationIds);
	}
	
	public OperationResult updateItemAssociations(int metafileId, int version, List<Integer> associationIds) {
		return updateAssociations(ItemMetafileAssociation.class, metafileId, version, associationIds);
	}

	public OperationResult updateAssociations(Class<? extends MetafileAssociation> cls, int metafileId, int version, List<Integer> associationIds) {
		ItemBankMetafile ibm = findMetafileByIdAndVersion(metafileId, version);
		if (ibm == null) {
			return new SingleResult(IBMetafileServicesStatus.METAFILE_NOT_FOUND);
		}
		MultipleResults<Integer> result = new MultipleResults<Integer>();
		for (int associationId: associationIds) {
			MetafileAssociation ma = entityManager.find(cls, associationId);
			if (ma == null) {
				result.add(associationId, IBMetafileServicesStatus.ASSOCIATION_NOT_FOUND);
			} else {
				int latestVersion = getLatestVersion(ma.getMetafileId());
				if (latestVersion < 0) {
					result.add(associationId, IBMetafileServicesStatus.METAFILE_NOT_FOUND);
				} else {
					ma.setVersion(latestVersion);
					entityManager.merge(ma);
					result.add(associationId, Status.OK);
				}
			}
		}
		result.setStatus(Status.OK);
		return result;
	}
	
	public Map<Integer, Integer> getLatestVersionsMapForAssocations(List<? extends MetafileAssociation> associations) {
		List<Integer> metafileIds = new ArrayList<Integer>();
		for (MetafileAssociation ma: associations) {
			metafileIds.add(ma.getMetafileId());
		}
		return getLatestVersionsMap(metafileIds);
	}
	
	public int getLatestVersion(int metafileId) {
		Map<Integer, Integer> map = getLatestVersionsMap(Arrays.asList(new Integer[] {metafileId}));
		return map.isEmpty() ? -1 : map.entrySet().iterator().next().getValue();
	}
	
	public Map<Integer, Integer> getLatestVersionsMap(List<Integer> metafileIds) {
		Map<Integer, Integer> result = new HashMap<Integer, Integer>();
		Query query = entityManager.createNativeQuery("select max(ibm_version) from item_bank_metafiles where ibm_id = ?");
		for (int metafileId: metafileIds) {
			query.setParameter(1, metafileId);
			Number number = (Number)query.getSingleResult();
			if (number != null) {
				result.put(metafileId, number.intValue());
			}
		}
		return result;
	}
	
	public OperationResult associatePassagesWithMetafile(int metafileId, int version, Iterable<Integer> passageIds) {
		ItemBankMetafile ibm = findMetafileByIdAndVersion(metafileId, version);
		if (ibm == null) {
			return new SingleResult(IBMetafileServicesStatus.METAFILE_NOT_FOUND);
		}
		MultipleResults<String> result = new MultipleResults<String>();
		for (int passageId: passageIds) {
			Passage passage = passageServices.findPassageById(passageId);
			if (passage == null) {
				result.add(String.valueOf(passageId), IBMetafileServicesStatus.ITEM_NOT_FOUND);
			} else {
				if (ibm.getItemBankId() != passage.getItemBankId()) {
					result.add(passage.getName(), IBMetafileServicesStatus.ITEM_BANKS_NOT_MATCH);
				} else if (isPassageAssociatedWithMetafile(passageId, metafileId)) {
					result.add(passage.getName(), IBMetafileServicesStatus.METAFILE_ALREADY_ASSOCIATED);
				} else {
					PassageMetafileAssociation pma = new PassageMetafileAssociation();
					pma.setMetafile(ibm);
					pma.setPassage(passage);
					entityManager.persist(pma);
					result.add(passage.getName(), Status.OK);
				}
			}
		}
		result.setStatus(Status.OK);
		return result;
	}
	
	public boolean isPassageAssociatedWithMetafile(int passageId, int metafileId) {
		Query query = entityManager.createNamedQuery("passageAssociationByPassageAndMetafile");
		query.setParameter("passage_id", passageId);
		query.setParameter("metafile_id", metafileId);
		return !query.getResultList().isEmpty();
	}
	
	@SuppressWarnings("unchecked")
	public List<PassageMetafileAssociation> getPassageAssociations(int metafileId, int version) {
		Query query = entityManager.createNamedQuery("passageAssociationByMetafileAndVersion");
		query.setParameter("metafile_id", metafileId);
		query.setParameter("version", version);
		return query.getResultList();
	}
	
	@SuppressWarnings("unchecked")
	public List<PassageMetafileAssociation> getPassageAssociations(int metafileId) {
		Query query = entityManager.createNamedQuery("passageAssociationByMetafile");
		query.setParameter("metafile_id", metafileId);
		return query.getResultList();
	}
	
	@SuppressWarnings("unchecked")
	public List<PassageMetafileAssociation> getPassageAssociationsOutdated(int metafileId) {
		Query query = entityManager.createNamedQuery("passageAssociationByMetafileOutdated");
		query.setParameter("metafile_id", metafileId);
		return query.getResultList();
	}
	
	public Map<Integer, Integer> getLatestVersionsMapForPassageAssocations(List<PassageMetafileAssociation> associations) {
		List<Integer> metafileIds = new ArrayList<Integer>();
		for (PassageMetafileAssociation pma: associations) {
			metafileIds.add(pma.getMetafileId());
		}
		return getLatestVersionsMap(metafileIds);
	}
	
	@SuppressWarnings("unchecked")
	public List<PassageMetafileAssociation> getMetafileAssociationsForPassage(int passageId) {
		Query query = entityManager.createNamedQuery("passageAssociationByPassage");
		query.setParameter("passage_id", passageId);
		return query.getResultList();
	}
	
	public OperationResult unassociate(Class<? extends MetafileAssociation> cls, int metafileId, int version, List<Integer> assocationIds) {
		ItemBankMetafile ibm = findMetafileByIdAndVersion(metafileId, version);
		if (ibm == null) {
			return new SingleResult(IBMetafileServicesStatus.METAFILE_NOT_FOUND);
		}
		MultipleResults<Integer> result = new MultipleResults<Integer>();
		for (int associationId: assocationIds) {
			Object obj = entityManager.find(cls, associationId);
			if (obj == null) {
				result.add(associationId, IBMetafileServicesStatus.ASSOCIATION_NOT_FOUND);
			} else {
				entityManager.remove(obj);
				result.add(associationId, Status.OK);
			}
		}
		result.setStatus(Status.OK);
		return result;
	}
	
	public OperationResult unassociatePassages(int metafileId, int version, List<Integer> associationIds) {
		return unassociate(PassageMetafileAssociation.class, metafileId, version, associationIds);
	}
	
	public OperationResult updateAllPassageAssociations(int metafileId, int version) {
		List<PassageMetafileAssociation> associations = getPassageAssociations(metafileId);
		for (PassageMetafileAssociation pma: associations) {
			if (pma.getVersion() < version) {
				pma.setVersion(version);
				entityManager.merge(pma);
			}
		}
		return new SingleResult(Status.OK);
	}
	
	public OperationResult updatePassageAssociations(int metafileId, int version, List<Integer> associationIds) {
		return updateAssociations(PassageMetafileAssociation.class, metafileId, version, associationIds);
	}

	public boolean isMetafileAssociatedWithPassages(int metafileId) {
		Query query = entityManager.createNamedQuery("passageAssociationCountByMetafile");
		query.setParameter("metafile_id", metafileId);
		Number count = (Number)query.getSingleResult();
		return count.intValue() > 0;
	}
	
	public void checkFile(String fileName, String contentType) throws ServiceException {
		if (fileName.length() > 200) {
			throw new ServiceException(IBMetafileServicesStatus.METAFILE_NAME_TOO_LONG, fileName);
		}
		List<String> disallowedTypes = ServerConfiguration.getPropertyAsList(ServerConfiguration.ITEM_BANK_METAFILE_MIME_TYPES_DISALLOWED);
		if (disallowedTypes.contains(contentType)) {
			throw new ServiceException(IBMetafileServicesStatus.METAFILE_MIME_TYPE_DISALLOWED, fileName);
		}
	}

}
