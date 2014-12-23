/**
 * 
 */
package com.pacificmetrics.orca.ejb;

import java.io.File;
import java.io.Serializable;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;
import javax.persistence.TypedQuery;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.math.NumberUtils;

import com.pacificmetrics.orca.entities.ContentArea;
import com.pacificmetrics.orca.entities.ContentAttachment;
import com.pacificmetrics.orca.entities.ContentExternalAttribute;
import com.pacificmetrics.orca.entities.ContentResources;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.DevState;
import com.pacificmetrics.orca.entities.Difficulty;
import com.pacificmetrics.orca.entities.ExternalContentMetadata;
import com.pacificmetrics.orca.entities.Genre;
import com.pacificmetrics.orca.entities.Grade;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAssetAttribute;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveDetails;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.entities.ItemMoveStatus;
import com.pacificmetrics.orca.entities.ItemMoveType;
import com.pacificmetrics.orca.entities.ItemPackageFormat;
import com.pacificmetrics.orca.entities.ItemStandard;
import com.pacificmetrics.orca.entities.ObjectCharacterization;
import com.pacificmetrics.orca.entities.Organization;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageItemSet;
import com.pacificmetrics.orca.entities.PassageMedia;
import com.pacificmetrics.orca.entities.PublicationStatus;
import com.pacificmetrics.orca.entities.Rubric;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.saaif.item.ImportExportErrorConstants;

/**
 * @author arindam.majumdar
 * 
 */

@Stateless
@LocalBean
public class ContentMoveServices implements Serializable {

    public List<Passage> findPassagesByItemId(long itemId) {
        List<Passage> passages = new ArrayList<Passage>();
        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT ic_value FROM item_characterization ic WHERE ic.i_id = ?1 AND ic.ic_type = 4")
                    .setParameter(1, itemId);
            List<Integer> passageIds = query.getResultList();
            if (CollectionUtils.isNotEmpty(passageIds)) {
                for (Integer passageId : passageIds) {
                    Passage passage = findPassageById(passageId);
                    if (passage != null) {
                        passages.add(passage);
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error finding passage for item " + e.getMessage(), e);
        }
        return passages;
    }

    public void insertPassageMoveDetails(String externalId,
            ItemMoveMonitor itemMoveMonitor, Passage passage,
            List<ItemDetailStatus> itemDetailStatusList, String imdExternalId) {

        try {
            ItemMoveDetails itemMoveDetails = new ItemMoveDetails();
            itemMoveDetails.setItemMoveMonitorId(itemMoveMonitor.getId());
            itemMoveDetails.setExternalId(passage != null ? passage.getName()
                    : "passage");
            itemMoveDetails.setItem(null);
            itemMoveDetails.setImdExternalId(imdExternalId);

            entityManager.persist(itemMoveDetails);

            for (ItemDetailStatus itemDetailStatus : itemDetailStatusList) {
                itemDetailStatus.setItemMoveDetailsId(itemMoveDetails.getId());
                entityManager.persist(itemDetailStatus);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemMoveDetails : "
                    + e.getMessage(), e);
        }
    }

    private static final Logger LOGGER = Logger
            .getLogger(ContentMoveServices.class.getName());

    private static final long serialVersionUID = 1L;

    private static final DateFormat DATE_FORMAT = new SimpleDateFormat(
            "dd_yyyy_MM");

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;

    public Difficulty findDifficultyById(long difficultyId) {
        try {
            return entityManager.find(Difficulty.class, difficultyId);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error finding difficulty with id "
                    + difficultyId + " " + e.getMessage(), e);
        }
        return null;
    }

    public Genre findGenreById(long genreId) {
        try {
            return entityManager.find(Genre.class, genreId);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error finding genre with id " + genreId
                    + " " + e.getMessage(), e);
        }
        return null;
    }

    public List<ItemBank> findItemBanksWithImporters() {
        List<ItemBank> itemBanks = null;
        try {
            TypedQuery<ItemBank> query = entityManager.createQuery(
                    "SELECT itb FROM ItemBank itb WHERE itb.user.id > 0",
                    ItemBank.class);
            itemBanks = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error finding Item banks with importer users "
                            + e.getMessage(), e);
        }
        return itemBanks != null ? itemBanks : Collections
                .<ItemBank> emptyList();
    }

    public Map<String, Integer> getOrgNamesMapForUser(User user) {
        Map<String, Integer> result = new TreeMap<String, Integer>();

        Query query = entityManager
                .createQuery("select org, usr from Organization org,User usr where org.id=usr.id and usr.id =:userId");
        query.setParameter("userId", user.getId());
        List list = query.getResultList();
        for (Iterator iterator = list.iterator(); iterator.hasNext();) {
            Object[] object = (Object[]) iterator.next();
            Organization org = (Organization) object[0];
            result.put(org.getOrgName(), org.getId());
        }

        return result;
    }

    public DetailStatusType findDetailStatusTypeId(int id) {
        return entityManager.find(DetailStatusType.class, id);
    }

    public List<DetailStatusType> findAllItemDetailStatusTypes() {
        List<DetailStatusType> itemDetailStatus = new ArrayList<DetailStatusType>();
        if (entityManager != null) {
            itemDetailStatus = entityManager.createQuery(
                    "SELECT dst FROM DetailStatusType dst",
                    DetailStatusType.class).getResultList();
        }
        return itemDetailStatus;
    }

    public ContentArea findContentArea(long id) {
        ContentArea ca = new ContentArea();
        try {
            ca = entityManager.find(ContentArea.class, id);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching ContentArea : " + e.getMessage(), e);
        }
        return ca;
    }

    public Grade findGrade(long id) {
        Grade g = new Grade();
        try {
            g = entityManager.find(Grade.class, id);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Grade : " + e.getMessage(), e);
        }
        return g;
    }

    public List<ItemStandard> findItemStandardByItem(Item item) {
        List<ItemStandard> itemStandard = new ArrayList<ItemStandard>();

        try {
            Query query = entityManager.createNamedQuery(
                    "ItemStandard.BY_ITEM", ItemStandard.class).setParameter(
                    "id", item.getId());
            itemStandard = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching ItemStandard : " + e.getMessage(), e);
        }
        return itemStandard;
    }

    @SuppressWarnings("unchecked")
    public List<PassageItemSet> findPISByItem(Item item) {
        List<PassageItemSet> pisList = new ArrayList<PassageItemSet>();

        try {
            Query query = entityManager.createNamedQuery("Item.PIS_BY_ITEM",
                    PassageItemSet.class).setParameter("id", item.getId());
            pisList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching PassageItemSet : " + e.getMessage(), e);
        }
        return pisList;
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findItemCharacterization(long id) {
        List<Object[]> icList = new ArrayList<Object[]>();
        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT * FROM item_characterization ic WHERE ic.i_id = ?1")
                    .setParameter(1, id);
            icList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in fetching ItemCharacterization : "
                            + e.getMessage(), e);
        }
        return icList;
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findObjectCharacterizationByPassage(Passage passage) {
        List<Object[]> ocList = new ArrayList<Object[]>();

        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT * FROM object_characterization oc WHERE oc.oc_object_type = ?1 AND oc.oc_object_id = ?2")
                    .setParameter(1, 7).setParameter(2, passage.getId());
            ocList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in fetching ObjectCharacterization : "
                            + e.getMessage(), e);
        }
        return ocList;
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findItemCharacterizationForRubric(Item item) {
        List<Object[]> ocList = new ArrayList<Object[]>();

        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT ic.* FROM item_characterization ic WHERE ic.ic_type = ?1 AND ic.i_id = ?2")
                    .setParameter(1, ItemCharacterizationTypeConstants.RUBRIC)
                    .setParameter(2, item.getId());
            ocList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in fetching ItemCharacterization : "
                            + e.getMessage(), e);
        }
        return ocList;
    }

    public Rubric findRubricById(int id) {
        Rubric rubric = new Rubric();
        try {
            rubric = entityManager.find(Rubric.class, id);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Rubric : " + e.getMessage(), e);
        }
        return rubric;
    }

    public DetailStatusType findDetailStatusTypeByVal(String value) {
        DetailStatusType detailStatusType = new DetailStatusType();
        try {
	        if (entityManager != null) {
	            detailStatusType = entityManager
	                    .createNamedQuery("DetailStatusType.dataByName",
	                            DetailStatusType.class)
	                    .setParameter("value", value).getSingleResult();
	        }
        } catch(NoResultException e) {
        	LOGGER.log(Level.SEVERE,"No Detail Status found by type " + value, e);
        } catch(Exception e) {
        	LOGGER.log(Level.SEVERE,"Error finding Detail Status by type " + value, e);
        }
        return detailStatusType;
    }

    public List<ItemMoveDetails> findItemMoveDetailsByItemMoveMonitorId(
            Long itemMoveMonitorId) {
        List<ItemMoveDetails> itemMoveDetails = null;
        if (entityManager != null) {
            itemMoveDetails = entityManager
                    .createQuery(
                            "SELECT imd FROM ItemMoveDetails imd WHERE imd.itemMoveMonitorId = :itemMoveMonitorId",
                            ItemMoveDetails.class)
                    .setParameter("itemMoveMonitorId", itemMoveMonitorId)
                    .getResultList();
        }

        return itemMoveDetails;
    }

    public ItemMoveDetails findIMDByItemId(Long id) {
        ItemMoveDetails imd = null;
        try {
            Query query = entityManager.createNamedQuery(
                    "ItemMoveDetails.IMD_BY_ITEMID").setParameter("id", id);
            imd = (ItemMoveDetails) query.getSingleResult();
        } catch (NoResultException e) {
            LOGGER.log(Level.SEVERE, "No item move detail found for : " + id, e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching ItemMoveDetails : " + e.getMessage(), e);
        }
        return imd;
    }

    public Item findItemByFormat(Long id, List<String> name) {
        Item item = null;
        try {
            Query query = entityManager.createNamedQuery("Item.I_BY_FORMAT")
                    .setParameter("id", id);

            query.setParameter("name", name);
            item = (Item) query.getSingleResult();
        } catch (NoResultException e) {
            LOGGER.log(Level.SEVERE, "No item found for : " + id, e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Item : " + e.getMessage(), e);
        }
        return item;
    }

    public List<ItemMoveMonitor> findItemMoveMonitorsByItemBankId(
            Long itemBankId) {
        List<ItemMoveMonitor> itemMoveMonitors = null;
        if (entityManager != null) {
            itemMoveMonitors = entityManager
                    .createQuery(
                            "SELECT imm FROM ItemMoveMonitor imm WHERE imm.itemBank.id = :itemBankId",
                            ItemMoveMonitor.class)
                    .setParameter("itemBankId", itemBankId).getResultList();
        }
        return itemMoveMonitors;
    }

    public List<ItemMoveMonitor> findAllItemMoveMonitors() {
        List<ItemMoveMonitor> itemMoveMonitors = null;
        if (entityManager != null) {
            itemMoveMonitors = entityManager.createQuery(
                    "SELECT im FROM ItemMoveMonitor im", ItemMoveMonitor.class)
                    .getResultList();
        }
        return itemMoveMonitors;
    }

    public Map<Long, ItemMoveStatus> getItemMoveStatusMap() {
        Map<Long, ItemMoveStatus> itemMoveStatusMap = new HashMap<Long, ItemMoveStatus>();
        if (entityManager != null) {
            List<ItemMoveStatus> itemMovestatusList = entityManager
                    .createQuery("SELECT ims FROM ItemMoveStatus as ims",
                            ItemMoveStatus.class).getResultList();
            if (CollectionUtils.isNotEmpty(itemMovestatusList)) {
                for (ItemMoveStatus itemMovestatus : itemMovestatusList) {
                    itemMoveStatusMap.put(itemMovestatus.getId(),
                            itemMovestatus);
                }
            }
        }
        return itemMoveStatusMap;
    }

    public Map<Long, ItemMoveType> getItemMoveTypeMap() {
        Map<Long, ItemMoveType> itemMoveTypeMap = new HashMap<Long, ItemMoveType>();
        if (entityManager != null) {
            List<ItemMoveType> itemMoveTypeList = entityManager.createQuery(
                    "SELECT ims FROM ItemMoveType as ims", ItemMoveType.class)
                    .getResultList();
            if (CollectionUtils.isNotEmpty(itemMoveTypeList)) {
                for (ItemMoveType itemMoveType : itemMoveTypeList) {
                    itemMoveTypeMap.put(itemMoveType.getId(), itemMoveType);
                }
            }
        }
        return itemMoveTypeMap;
    }

    public Map<String, String> getItemMoveSourceMap() {
        Map<String, String> itemMoveSourceMap = new HashMap<String, String>();
        if (entityManager != null) {
            List<String> itemMoveSourceList = entityManager.createQuery(
                    "SELECT DISTINCT imm.source FROM ItemMoveMonitor as imm",
                    String.class).getResultList();
            if (CollectionUtils.isNotEmpty(itemMoveSourceList)) {
                for (String sourceName : itemMoveSourceList) {
                    itemMoveSourceMap.put(sourceName, sourceName);
                }
            }
        }
        return itemMoveSourceMap;
    }

    public Map<String, String> getItemMoveDestinationMap() {
        Map<String, String> itemMoveDestinationMap = new HashMap<String, String>();
        if (entityManager != null) {
            List<String> itemMoveDestinationList = entityManager
                    .createQuery(
                            "SELECT DISTINCT imm.destination FROM ItemMoveMonitor as imm",
                            String.class).getResultList();
            if (CollectionUtils.isNotEmpty(itemMoveDestinationList)) {
                for (String destinationName : itemMoveDestinationList) {
                    itemMoveDestinationMap
                            .put(destinationName, destinationName);
                }
            }
        }
        return itemMoveDestinationMap;
    }

    public ItemMoveMonitor insertItemMoveMonitor(Integer programId,
            Integer userId, Long moveTypeId, Long moveStatusId, String source,
            String destination, String fileName, Timestamp timeOfMove,
            String itemPkgFormat) {

        ItemMoveMonitor itemMoveMonitor = new ItemMoveMonitor();
        try {
            ItemMoveType itemMoveType = entityManager.find(ItemMoveType.class,
                    moveTypeId);
            ItemMoveStatus itemMoveStatus = entityManager.find(
                    ItemMoveStatus.class, moveStatusId);
            ItemBank itemBank = entityManager.find(ItemBank.class, programId);
            User user = entityManager.find(User.class, userId);

            ItemPackageFormat ipf = entityManager.find(ItemPackageFormat.class,
                    Integer.valueOf(itemPkgFormat));

            itemMoveMonitor.setItemBank(itemBank);
            itemMoveMonitor.setUser(user);
            itemMoveMonitor.setItemMoveType(itemMoveType);
            itemMoveMonitor.setItemMoveStatus(itemMoveStatus);
            itemMoveMonitor.setSource(source);
            itemMoveMonitor.setDestination(destination);
            itemMoveMonitor.setFileName(fileName);
            itemMoveMonitor.setTimeOfMove(timeOfMove);
            itemMoveMonitor.setItemPackageFormat(ipf);

            entityManager.persist(itemMoveMonitor);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemMoveMonitor : "
                    + e.getMessage(), e);
        }

        return itemMoveMonitor;
    }

    public void updateItemMonitor(ItemMoveMonitor itemMoveMonitor,
            Map<String, Object> values) {
        ItemMoveStatus itemMoveStatus = entityManager.find(
                ItemMoveStatus.class, values.get("itemMoveStatus"));
        itemMoveMonitor.setItemMoveStatus(itemMoveStatus);

        entityManager.merge(itemMoveMonitor);
    }

    public void updatePassage(Passage passage, Map<String, Object> values) {
        passage.setUrl(String.valueOf(values.get("source")));

        entityManager.merge(passage);
    }

    public void insertItemMoveDetails(String externalId,
            ItemMoveMonitor itemMoveMonitor, Item item,
            List<ItemDetailStatus> itemDetailStatusList, String imdExternalId) {

        try {
            ItemMoveDetails itemMoveDetails = new ItemMoveDetails();
            itemMoveDetails.setItemMoveMonitorId(itemMoveMonitor.getId());
            itemMoveDetails.setExternalId(externalId);
            itemMoveDetails.setItem(item);
            itemMoveDetails.setImdExternalId(imdExternalId);

            entityManager.persist(itemMoveDetails);

            for (ItemDetailStatus itemDetailStatus : itemDetailStatusList) {
                itemDetailStatus.setItemMoveDetailsId(itemMoveDetails.getId());
                entityManager.persist(itemDetailStatus);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemMoveDetails : "
                    + e.getMessage(), e);
        }
    }

    public void insertItemDetailStatus(ItemMoveDetails itemMoveDetails) {
        ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
        try {
            itemDetailStatus.setItemMoveDetailsId(itemMoveDetails.getId());
            entityManager.persist(itemDetailStatus);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemDetailStatus : "
                    + e.getMessage(), e);
        }
    }

    private boolean isSuccesfulItemImport(
            List<ItemDetailStatus> itemDetailStatusList) {
        for (ItemDetailStatus itemDetailStatus : itemDetailStatusList) {
            if (itemDetailStatus.getDetailStatusType().getId() != 1) {
                return false;
            }
        }
        return true;
    }

    @TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
    public String deleteItemMove(String id) {

        File baseDir = new File("/www/cde_resources");
        File instanceDir = new File(baseDir, "cdesbac");
        File imageDir = new File(instanceDir, "images");

        try {

            ItemMoveMonitor itemMoveMonitor = entityManager.find(
                    ItemMoveMonitor.class, id);

            Query imsQuery = entityManager.createNamedQuery(
                    "ItemMoveStatus.dataByStatus").setParameter("status",
                    SAAIFPackageConstants.IMS_IN_PROGRESS);
            ItemMoveStatus ims = (ItemMoveStatus) imsQuery.getSingleResult();

            if (itemMoveMonitor.getItemMoveStatus().getId() != ims.getId()) {
                File libDir = new File(imageDir, "lib"
                        + itemMoveMonitor.getItemBank().getId());
                if (CollectionUtils.isNotEmpty(itemMoveMonitor
                        .getItemMoveDetails())) {
                    for (ItemMoveDetails itemMoveDetails : itemMoveMonitor
                            .getItemMoveDetails()) {

                        if (itemMoveDetails.getItem() != null) {

                            Query query = entityManager
                                    .createNamedQuery("IC.IC_FOR_PASSAGE")
                                    .setParameter("itemId",
                                            itemMoveDetails.getItem().getId())
                                    .setParameter("type", 4);
                            List<ItemCharacterization> passageList = query
                                    .getResultList();

                            for (PassageItemSet passageItemSet : itemMoveDetails
                                    .getItem().getPassageItemSet()) {
                                entityManager.remove(passageItemSet);
                            }

                            for (ItemCharacterization ic : passageList) {
                                Passage passage = entityManager.find(
                                        Passage.class, ic.getIntValue());

                                query = entityManager
                                        .createNamedQuery(
                                                "IC.IC_FOR_PASSAGE_BY_ID")
                                        .setParameter("passageId",
                                                passage.getId())
                                        .setParameter("type", 4);
                                List<ItemCharacterization> sharablePassageList = query
                                        .getResultList();

                                // Checking sharable Passage
                                if (sharablePassageList.size() == 1) {

                                    for (PassageMedia passageMedia : passage
                                            .getPassageMedia()) {
                                        entityManager.remove(passageMedia);
                                    }

                                    if (CollectionUtils.isNotEmpty(passage
                                            .getObjectCharacterization())) {
                                        query = entityManager
                                                .createQuery(
                                                        "DELETE FROM ObjectCharacterization oc WHERE oc.objectId = :objectId")
                                                .setParameter("objectId",
                                                        passage.getId());
                                        query.executeUpdate();
                                    }

                                    /*
                                     * ######## DELETING PASSAGE FILES & FOLDERS
                                     * #######
                                     */

                                    String passageFolder = "";
                                    for (ContentAttachment ca : passage
                                            .getContentAttachment()) {
                                        File passageFile = new File(
                                                ca.getSourceUrl());
                                        passageFolder = passageFile.getParent();
                                        if (passageFile.exists()) {
                                            passageFile.delete();
                                        }
                                    }
                                    File folder = new File(passageFolder);
                                    if (folder != null && folder.exists()) {
                                        folder.delete();
                                    }

                                    File passageImageFile = new File(libDir,
                                            folder.getName());
                                    if (passageImageFile.exists()) {
                                        FileUtils
                                                .deleteQuietly(passageImageFile);
                                        /*
                                         * --- End of Deleting files & Folders
                                         * ---
                                         */
                                    }

                                    query = entityManager
                                            .createQuery(
                                                    "DELETE FROM Passage p WHERE p.id = :id")
                                            .setParameter("id", passage.getId());
                                    query.executeUpdate();

                                }
                            }

                            for (ExternalContentMetadata ecm : itemMoveDetails
                                    .getItem().getExternalContentMetadata()) {
                                if (ecm.getContentResources() != null) {
                                    entityManager.remove(ecm
                                            .getContentResources());

                                    File wordlistOrTutFile = new File(ecm
                                            .getContentResources()
                                            .getSourceUrl());
                                    if (wordlistOrTutFile.exists()) {
                                        FileUtils
                                                .deleteQuietly(wordlistOrTutFile);
                                    }
                                    File wordlistOrTutImageFile = new File(
                                            libDir, wordlistOrTutFile.getName());
                                    if (wordlistOrTutImageFile.exists()) {
                                        FileUtils
                                                .deleteQuietly(wordlistOrTutImageFile);
                                    }
                                }
                            }

                            query = entityManager
                                    .createQuery(
                                            "DELETE FROM ItemCharacterization ic WHERE ic.itemId = :id")
                                    .setParameter("id",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            /* ######## DELETING ITEMS FILES & FOLDERS ####### */

                            String itemFolder = "";
                            for (ContentAttachment ca : itemMoveDetails
                                    .getItem().getContentAttachment()) {
                                File itemFile = new File(ca.getSourceUrl());
                                itemFolder = itemFile.getParent();
                                if (itemFile.exists()) {
                                    itemFile.delete();
                                }
                            }

                            File folder = null;
                            if (itemFolder != null) {
                                folder = new File(itemFolder);
                                if (folder != null && folder.exists()) {
                                    folder.delete();
                                }
                            }

                            for (ItemAssetAttribute iaa : itemMoveDetails
                                    .getItem().getItemAssetAttribute()) {
                                File itemFile = new File(iaa.getSourceUrl());
                                itemFolder = itemFile.getParent();
                                if (itemFile.exists()) {
                                    itemFile.delete();
                                }
                            }

                            if (itemFolder != null) {
                                folder = new File(itemFolder);
                                if (folder != null && folder.exists()) {
                                    folder.delete();
                                }
                            }

                            /* --- End of Deleting files & Folders --- */

                            // DELETING FROM StatItemValue
                            query = entityManager
                                    .createQuery(
                                            "DELETE FROM StatItemValue siv WHERE siv.itemId = :itemId")
                                    .setParameter("itemId",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            // Deleting form the item_status_fragment
                            query = entityManager
                                    .createNativeQuery(
                                            "DELETE FROM item_status_fragment WHERE i_id = ?")
                                    .setParameter(1,
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            // Deleting from the item_status
                            query = entityManager
                                    .createNativeQuery(
                                            "DELETE FROM item_status WHERE i_id = ?1 AND ib_id = ?2")
                                    .setParameter(1,
                                            itemMoveDetails.getItem().getId())
                                    .setParameter(
                                            2,
                                            itemMoveDetails.getItem()
                                                    .getItemBank().getId());
                            query.executeUpdate();

                            // DELETING FROM ItemFragment
                            query = entityManager
                                    .createQuery(
                                            "DELETE FROM ItemFragment ifg WHERE ifg.itemId = :itemId")
                                    .setParameter("itemId",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            // DELETING FROM ItemInteraction
                            query = entityManager
                                    .createQuery(
                                            "DELETE FROM ItemInteraction ii WHERE ii.itemId = :itemId")
                                    .setParameter("itemId",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            // Deleting form ItemAssetAttribute
                            query = entityManager
                                    .createQuery(
                                            "DELETE FROM ItemAssetAttribute iaa WHERE iaa.item.id = :itemId")
                                    .setParameter("itemId",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();

                            // DELETING FROM Item
                            query = entityManager.createQuery(
                                    "DELETE FROM Item it WHERE it.id = :id")
                                    .setParameter("id",
                                            itemMoveDetails.getItem().getId());
                            query.executeUpdate();
                        }
                    }
                }
                Query query = entityManager
                        .createNamedQuery("ItemMoveMonitor.deleteById");
                query.setParameter("id", itemMoveMonitor.getId());
                query.executeUpdate();
            } else {
                return ImportExportErrorConstants.ERROR_RLBACK_PROGRESS;
            }

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, e.getMessage(), e);
            return ImportExportErrorConstants.FAILED_RLBACK;
        }

        return ImportExportErrorConstants.SUCCESS_RLBACK;
    }

    public Item insertItem(String externalId, int itemFormat,
            ItemBank itemBank, User user, String itemDesc,
            String educationDifficulty, String language,
            String publicationStatus, String metadataXml,
            String primaryStandard, List<String> secondaryStandardList,
            int version, String guid, int isOldVersion) {
        Item item = new Item();

        item.setExternalId(externalId);
        item.setItemBank(itemBank);
        item.setItemFormat(itemFormat);
        if (itemFormat > 1) {
            item.setItemType(itemFormat + 1);
        } else {
            item.setItemType(itemFormat);
        }

        try {
            DevState devState = entityManager.find(DevState.class, 1);
            item.setDevState(devState);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching DevState : " + e.getMessage(), e);
        }

        StringBuilder sbufGuid = new StringBuilder("cdesbac::");
        sbufGuid.append(itemBank.getExternalId()).append(":");
        sbufGuid.append(externalId).append(":");
        sbufGuid.append(DATE_FORMAT.format(new Date())).append(":");
        sbufGuid.append(UUID.randomUUID().toString());
        item.setItemGuid(guid != null && !"".equals(guid) ? guid : sbufGuid
                .toString());

        /* Get & Set Difficulty */
        Query query = entityManager.createNamedQuery("Difficulty.difficultId");
        query.setParameter("name", educationDifficulty);
        Difficulty difficulty = null;
        try {
            difficulty = (Difficulty) query.getSingleResult();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in updating EducationDifficulty : "
                    + e.getMessage(), e);
        }
        if (difficulty == null) {
            difficulty = insertDifficulty(educationDifficulty);
        }
        item.setDifficulty((int) difficulty.getId());

        /* Get & Set Publication Status */
        query = entityManager.createNamedQuery("PublicationStatus.dataByName");
        query.setParameter("name", publicationStatus);
        PublicationStatus ps = null;
        try {
            ps = (PublicationStatus) query.getSingleResult();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in updating PublicationStatus : "
                    + e.getMessage(), e);
        }
        if (ps == null) {
            ps = insertPublicationStatus(publicationStatus);
        }
        item.setPublicationStatus(ps.getId());

        item.setDescription(itemDesc);
        item.setLang(SAAIFPackageConstants.LANGUAGE_ENG);
        item.setItemTeiData("");
        item.setItemIsPiSet(0);
        item.setItemXmlData("");
        item.setQtiData("");
        item.setItemLastSaveUserId(user);
        item.setAuthor(user);
        item.setMetadataXml(metadataXml);
        item.setItemXmlData(SAAIFPackageConstants.I_XML_DATA);
        item.setPrimaryStandard(primaryStandard);
        item.setVersion(version);
        item.setIsOldVersion(isOldVersion);

        ItemStandard itemStandard = null;
        List<ItemStandard> itemStandardList = new ArrayList<ItemStandard>();
        if (CollectionUtils.isNotEmpty(secondaryStandardList)) {
            for (String standard : secondaryStandardList) {
                itemStandard = new ItemStandard();
                itemStandard.setStandard(standard);
                itemStandardList.add(itemStandard);
            }
            item.setItemStandardList(itemStandardList);
        }

        try {
            entityManager.persist(item);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting Item : " + e.getMessage(), e);
        }
        return item;
    }

    public Item updateItem(Item item) {
        try {
            entityManager.merge(item);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in updating Item : " + e.getMessage(), e);
        }

        return item;
    }

    public Item checkItem(ItemBank itemBank, String imdExternalId) {

        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT i.* FROM item i LEFT JOIN item_move_details imd ON imd.i_id = i.i_id WHERE i.ib_id = ?1 AND imd.imd_external_id = ?2 AND "
                                    + "(i.i_is_old_version is null || i.i_is_old_version = 0) LIMIT 1",
                            Item.class);
            // Query query =
            // entityManager.createNamedQuery("SELECT imd FROM ItemMoveDetails imd LEFT JOIN FETCH imd.item i WHERE i.itemBank.id = :id AND imd.imdExternalId = :imdExternalId LIMIT 1",
            // arg1)
            query.setParameter(1, itemBank.getId());
            query.setParameter(2, imdExternalId);
            Item item = null;

            item = (Item) query.getSingleResult();

            return item;
        } catch (NoResultException ne) {
        	 LOGGER.log(Level.SEVERE,
                     "No Item found with external id " + imdExternalId, ne);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Item : " + e.getMessage(), e);
        }
        return null;
    }

    public Passage checkPassageByIdentifier(ItemBank itemBank, String identifier) {
        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT p.* FROM passage p JOIN content_external_attribute cea ON p.p_id = cea.p_id "
                                    + "WHERE p.ib_id = ?1 AND cea.cea_external_id = ?2 LIMIT 1",
                            Passage.class);

            query.setParameter(1, itemBank.getId());
            query.setParameter(2, identifier);
            Passage passage = null;

            passage = (Passage) query.getSingleResult();

            return passage;
        } catch (NoResultException ne) {
        	LOGGER.log(Level.SEVERE,
                 "No Passage found with external id " + identifier, ne);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in fetching Passage : "
                    + identifier, e);
        }
        return null;
    }

    public Passage checkPassageByDescription(ItemBank itemBank,
            String description) {
        try {
            Query query = entityManager
                    .createNativeQuery(
                            "SELECT * FROM passage p WHERE p.ib_id = ?1 AND p.p_name = ?2 LIMIT 1",
                            Passage.class);

            query.setParameter(1, itemBank.getId());
            query.setParameter(2, description);
            Passage passage = null;

            passage = (Passage) query.getSingleResult();

            return passage;
        }  catch (NoResultException e) {
            LOGGER.log(Level.SEVERE, "No Passage found by descripion : " + description, e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Passage : " + e.getMessage(), e);
        }
        return null;
        
    }

    public List<ContentExternalAttribute> findContentExternalAttributeByPassageId(
            Integer passageId) {
        List<ContentExternalAttribute> externalAttributeList = new ArrayList<ContentExternalAttribute>();
        try {
            TypedQuery<ContentExternalAttribute> query = entityManager
                    .createNamedQuery(
                            "findContentExternalAttributeByPassageId",
                            ContentExternalAttribute.class);
            query.setParameter("passageId", passageId);
            externalAttributeList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findContentExternalAttributeByPassageId with passageId "
                            + passageId + " " + e.getMessage(), e);
            externalAttributeList = Collections.emptyList();
        }
        return externalAttributeList;
    }

    public List<ExternalContentMetadata> findExternalContentMetadatasByPassageId(
            long passageId) {
        List<ExternalContentMetadata> externalContentMetadataList = new ArrayList<ExternalContentMetadata>();
        try {
            TypedQuery<ExternalContentMetadata> query = entityManager
                    .createNamedQuery("findExternalContentMetadataByPassageId",
                            ExternalContentMetadata.class);
            query.setParameter("passageId", passageId);
            externalContentMetadataList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findExternalContentMetadatasByPassageId with passageId "
                            + passageId + " " + e.getMessage(), e);
        }
        return externalContentMetadataList;
    }

    public List<ContentAttachment> findAttachmentsByPassageId(long passageId) {
        List<ContentAttachment> contentAttachmentList = new ArrayList<ContentAttachment>();
        try {
            TypedQuery<ContentAttachment> query = entityManager
                    .createNamedQuery("findAttachmentByPassageId",
                            ContentAttachment.class);
            query.setParameter("passageId", passageId);
            contentAttachmentList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findAttachmentsByPassageId with passageId "
                            + passageId + " " + e.getMessage(), e);
        }
        return contentAttachmentList;
    }

    public List<ItemAssetAttribute> findItemAssetsByItemId(long itemId) {
        List<ItemAssetAttribute> itemAssetAttributeList = null;
        try {
            TypedQuery<ItemAssetAttribute> query = entityManager
                    .createNamedQuery("findItemAssetAttributeByItemId",
                            ItemAssetAttribute.class);
            query.setParameter("itemId", itemId);
            itemAssetAttributeList = query.getResultList();

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findItemAssetsByItemId with itemId "
                            + itemId + " " + e.getMessage(), e);
            itemAssetAttributeList = Collections.emptyList();
        }
        return itemAssetAttributeList;
    }

    public List<PassageMedia> findPassageMediaByPassage(long psgId) {
        List<PassageMedia> passageMediaList = null;
        try {
            TypedQuery<PassageMedia> query = entityManager.createNamedQuery(
                    "PassageMedia.PSG_MEDIA_BY_PSGID", PassageMedia.class);
            query.setParameter("id", psgId);
            passageMediaList = query.getResultList();

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findItemAssetsByItemId with itemId "
                            + psgId + " " + e.getMessage(), e);
            passageMediaList = Collections.emptyList();
        }
        return passageMediaList;
    }

    public List<ContentExternalAttribute> findContentExternalAttributeByItemId(
            long itemId) {
        List<ContentExternalAttribute> externalAttributeList = new ArrayList<ContentExternalAttribute>();
        try {
            TypedQuery<ContentExternalAttribute> query = entityManager
                    .createNamedQuery("findContentExternalAttributeByItemId",
                            ContentExternalAttribute.class);
            query.setParameter("itemId", itemId);
            externalAttributeList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findContentExternalAttributeByItemId with itemId "
                            + itemId + " " + e.getMessage(), e);
            externalAttributeList = Collections.emptyList();
        }
        return externalAttributeList;
    }

    public List<ExternalContentMetadata> findExternalContentMetadatasByItemId(
            long itemId) {
        List<ExternalContentMetadata> externalContentMetadataList = new ArrayList<ExternalContentMetadata>();
        try {
            TypedQuery<ExternalContentMetadata> query = entityManager
                    .createNamedQuery("findExternalContentMetadataByItemId",
                            ExternalContentMetadata.class);
            query.setParameter("itemId", itemId);
            externalContentMetadataList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findExternalContentMetadatasByItemId with itemId "
                            + itemId + " " + e.getMessage(), e);
        }
        return externalContentMetadataList;
    }

    public List<ContentAttachment> findAttachmentsByItemId(long itemId) {
        List<ContentAttachment> contentAttachmentList = new ArrayList<ContentAttachment>();
        try {
            TypedQuery<ContentAttachment> query = entityManager
                    .createNamedQuery("findAttachmentByItemId",
                            ContentAttachment.class);
            query.setParameter("itemId", itemId);
            contentAttachmentList = query.getResultList();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findAttachmentsByItemId with itemId "
                            + itemId + " " + e.getMessage(), e);
        }
        return contentAttachmentList;
    }

    public List<Passage> findPassageByItemId(long itemId) {
        List<Passage> passage = new ArrayList<Passage>();
        try {
            TypedQuery<Passage> query = entityManager.createNamedQuery(
                    "PassageItemSet.findPassageByItemId", Passage.class);
            query.setParameter("itemId", itemId);
            passage = query.getResultList();

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "ContentMoveService::findPassageByItemId with itemId "
                            + itemId + " " + e.getMessage(), e);
        }
        return passage;
    }

    public Passage findPassageById(long id) {
        Passage passage = new Passage();
        try {
            passage = entityManager.find(Passage.class, id);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching Passage : " + e.getMessage(), e);
        }
        return passage;
    }

    public ExternalContentMetadata insertExternalContentMetadata(
            String contentData, String contentType, Item item, Passage passage,
            ContentResources contentResources) {
        ExternalContentMetadata ecm = new ExternalContentMetadata();
        try {
            ecm.setContentData(contentData);
            ecm.setContentType(contentType);
            ecm.setItem(item);
            ecm.setPassage(passage);
            ecm.setContentResources(contentResources);

            entityManager.persist(ecm);
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in inserting ExternalContentMetadata : "
                            + e.getMessage(), e);
        }
        return ecm;
    }

    public ContentExternalAttribute insertContentExternalAttribute(
            String externalID, String format, Item item, Passage passage) {
        ContentExternalAttribute cea = new ContentExternalAttribute();
        try {
            cea.setExternalID(externalID);
            cea.setFormat(format);
            cea.setItem(item);
            cea.setPassage(passage);

            entityManager.persist(cea);
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in inserting ContentExternalAttribute : "
                            + e.getMessage(), e);
        }
        return cea;
    }

    public ContentAttachment contentAttachment(String filename,
            String sourceUrl, String type, Item item, Passage passage,
            ContentResources contentResources) {
        ContentAttachment ca = new ContentAttachment();
        try {
            ca.setFilename(filename);
            ca.setItem(item);
            ca.setPassage(passage);
            ca.setSourceUrl(sourceUrl);
            ca.setType(type);
            ca.setContentResources(contentResources);

            entityManager.persist(ca);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ContentAttachment : "
                    + e.getMessage(), e);
        }
        return ca;
    }

    public ItemPackageFormat itemPackageFormat(String description, String name) {
        ItemPackageFormat ipf = new ItemPackageFormat();
        try {
            ipf.setDescription(description);
            ipf.setName(name);

            entityManager.persist(ipf);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemPackageFormat : "
                    + e.getMessage(), e);
        }
        return ipf;
    }

    public PassageMedia insertPassageMedia(String clntFilename,
            String description, Passage passage, String srvrFilename, User user) {
        PassageMedia pm = new PassageMedia();
        try {
            pm.setClntFilename(clntFilename);
            pm.setDescription(description);
            pm.setPassage(passage);
            pm.setSrvrFilename(srvrFilename);
            pm.setUser(user);

            entityManager.persist(pm);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting PassageMedia : " + e.getMessage(), e);
        }
        return pm;
    }

    public Passage insertPassage(int itemBankId, String name, String url,
            String genre, String publicationStatus) {
        Passage p = new Passage();

        p.setItemBankId(itemBankId);
        p.setName(name);
        p.setUrl(url);

        /* Get & Set Publication Status */
        if (StringUtils.isNotBlank(genre)) {
            try {
                Query query = entityManager
                        .createNamedQuery("Genre.dataByName");
                query.setParameter("name", genre);
                Genre gn = null;
                gn = (Genre) query.getSingleResult();
                if (gn == null) {
                    gn = insertGenre(genre);
                }
                if (gn != null
                        && gn.getId() >= SAAIFPackageConstants.DEFAULT_GENRE) {
                    p.setGenre((int) gn.getId());
                } else {
                    p.setGenre(SAAIFPackageConstants.DEFAULT_GENRE);
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE,
                        "Error in saving passage Genre : " + e.getMessage(), e);
                p.setGenre(SAAIFPackageConstants.DEFAULT_GENRE);
            }
        } else {
            p.setGenre(SAAIFPackageConstants.DEFAULT_GENRE);
        }

        /* Get & Set Publication Status */
        if (StringUtils.isNotBlank(publicationStatus)) {
            try {
                Query query = entityManager
                        .createNamedQuery("PublicationStatus.dataByName");
                query.setParameter("name", publicationStatus);
                PublicationStatus ps = null;
                ps = (PublicationStatus) query.getSingleResult();
                if (ps == null) {
                    ps = insertPublicationStatus(publicationStatus);
                }
                if (ps != null
                        && ps.getId() >= SAAIFPackageConstants.DEFAULT_PUBLICATION_STATUS) {
                    p.setPublicationStatus(ps.getId());
                } else {
                    p.setPublicationStatus(SAAIFPackageConstants.DEFAULT_PUBLICATION_STATUS);
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Error in set passage publication : "
                        + e.getMessage(), e);
                p.setPublicationStatus(SAAIFPackageConstants.DEFAULT_PUBLICATION_STATUS);
            }
        } else {
            p.setPublicationStatus(SAAIFPackageConstants.DEFAULT_PUBLICATION_STATUS);
        }

        p.setLang(SAAIFPackageConstants.LANGUAGE_ENG);

        try {
            entityManager.persist(p);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting Passage : " + e.getMessage(), e);
        }
        return p;
    }

    public ItemAssetAttribute insertItemAssetAttribute(String classification,
            String fileName, Item item, String mediaDescription,
            String sourceUrl, User user) {
        ItemAssetAttribute iaa = new ItemAssetAttribute();
        try {
            iaa.setClassification(classification);
            iaa.setFileName(fileName);
            iaa.setItem(item);
            iaa.setMediaDescription(mediaDescription);
            iaa.setSourceUrl(sourceUrl);
            iaa.setUser(user);

            entityManager.persist(iaa);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ItemAssetAttribute : "
                    + e.getMessage(), e);
        }
        return iaa;
    }

    public void manageItemCharacterization(int type, String value, long itemId) {

        if (type == 1) {
            Query query = entityManager.createNamedQuery("ContentArea.Id");
            query.setParameter("name",
                    NumberUtils.isNumber(value) ? Integer.parseInt(value)
                            : value);
            List list = query.getResultList();
            ContentArea ca = null;
            for (Object object : list) {
                ca = (ContentArea) object;
            }

            if (ca != null) {
                insertItemCharacterization((int) ca.getId(), itemId,
                        ItemCharacterizationTypeConstants.CONTENT_AREA);
            } else {
                ca = insertContentArea(value);
                insertItemCharacterization((int) ca.getId(), itemId,
                        ItemCharacterizationTypeConstants.CONTENT_AREA);
            }
        } else if (type == 2) {
            Query query = entityManager.createNamedQuery("Grade.Id");
            query.setParameter("name", value);
            List list = query.getResultList();
            Grade g = null;
            for (Object object : list) {
                g = (Grade) object;
            }

            if (g != null) {
                insertItemCharacterization((int) g.getId(), itemId,
                        ItemCharacterizationTypeConstants.GRADE_LEVEL);
            } else {
                insertGrade(value);
                insertItemCharacterization((int) g.getId(), itemId,
                        ItemCharacterizationTypeConstants.GRADE_LEVEL);
            }
        } else if (type == 3) {
            insertItemCharacterization(Integer.valueOf(value), itemId,
                    ItemCharacterizationTypeConstants.POINTS);
        } else if (type == 4) {
            insertItemCharacterization(Integer.valueOf(value), itemId,
                    ItemCharacterizationTypeConstants.GRADE_SPAN_START);
        } else if (type == 5) {
            insertItemCharacterization(Integer.valueOf(value), itemId,
                    ItemCharacterizationTypeConstants.GRADE_SPAN_END);
        } else if (type == 6) {
            insertItemCharacterization(Integer.valueOf(value), itemId,
                    ItemCharacterizationTypeConstants.DOK);
        } else if (type == 7) {
            insertItemCharacterization(Integer.valueOf(value), itemId,
                    ItemCharacterizationTypeConstants.PASSAGE);
        }
    }

    public void managePassageCharacterization(int type, String value,
            long passageId) {

        if (type == 1) {
            Query query = entityManager.createNamedQuery("ContentArea.Id");
            query.setParameter("name", value);
            List list = query.getResultList();
            ContentArea ca = null;
            for (Object object : list) {
                ca = (ContentArea) object;
            }

            if (ca != null) {
                insertObjectCharacterization((int) ca.getId(), passageId,
                        ItemCharacterizationTypeConstants.OT_PASSAGE,
                        ItemCharacterizationTypeConstants.CONTENT_AREA);
            } else {
                ca = insertContentArea(value);
                insertObjectCharacterization((int) ca.getId(), passageId,
                        ItemCharacterizationTypeConstants.OT_PASSAGE,
                        ItemCharacterizationTypeConstants.CONTENT_AREA);
            }
        } else if (type == 2) {
            Query query = entityManager.createNamedQuery("Grade.Id");
            query.setParameter("name", value);
            List list = query.getResultList();
            Grade g = null;
            for (Object object : list) {
                g = (Grade) object;
            }

            if (g != null) {
                insertObjectCharacterization((int) g.getId(), passageId,
                        ItemCharacterizationTypeConstants.OT_PASSAGE,
                        ItemCharacterizationTypeConstants.GRADE_LEVEL);
            } else {
                g = insertGrade(value);
                insertObjectCharacterization((int) g.getId(), passageId,
                        ItemCharacterizationTypeConstants.OT_PASSAGE,
                        ItemCharacterizationTypeConstants.GRADE_LEVEL);
            }
        } else if (type == 3) {
            insertObjectCharacterization(Integer.valueOf(value), passageId,
                    ItemCharacterizationTypeConstants.OT_PASSAGE,
                    ItemCharacterizationTypeConstants.GRADE_SPAN_START);
        } else if (type == 4) {
            insertObjectCharacterization(Integer.valueOf(value), passageId,
                    ItemCharacterizationTypeConstants.OT_PASSAGE,
                    ItemCharacterizationTypeConstants.GRADE_SPAN_END);
        }
    }

    public ItemCharacterization insertItemCharacterization(int intValue,
            long itemId, int type) {

        ItemCharacterization ic = new ItemCharacterization();
        try {
            ic.setIntValue(intValue);
            ic.setItemId((int) itemId);
            ic.setType(type);

            entityManager.persist(ic);

        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in inserting ItemCharacterization : "
                            + e.getMessage(), e);
        }
        return ic;
    }

    public ObjectCharacterization insertObjectCharacterization(int intValue,
            long objectId, int objectType, int characteristic) {

        ObjectCharacterization oc = new ObjectCharacterization();
        try {
            Query query = entityManager
                    .createNativeQuery("INSERT INTO object_characterization VALUES(?1,?2,?3,?4)");
            query.setParameter(1, objectType).setParameter(2, objectId)
                    .setParameter(3, characteristic).setParameter(4, intValue);
            query.executeUpdate();

        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in inserting ObjectCharacterization : "
                            + e.getMessage(), e);
        }
        return oc;
    }

    public ContentArea insertContentArea(String name) {

        ContentArea ca = new ContentArea();
        try {
            ca.setName(name);
            entityManager.persist(ca);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting ContentArea : " + e.getMessage(), e);
        }
        return ca;
    }

    public Grade insertGrade(String name) {

        Grade g = new Grade();
        try {
            g.setName(name);
            entityManager.persist(g);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting Grade : " + e.getMessage(), e);
        }
        return g;
    }

    public ContentResources insertContentResources(String externalId,
            String sourceUrl, String type) {

        ContentResources cr = new ContentResources();
        try {
            cr.setExternalId(externalId);
            cr.setSourceUrl(sourceUrl);
            cr.setType(type);

            entityManager.persist(cr);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting ContentResources : "
                    + e.getMessage(), e);
        }
        return cr;
    }

    public PassageItemSet insertPassageItemSet(Item item, Passage passage,
            int sequence) {

        PassageItemSet pts = new PassageItemSet();
        try {
            pts.setItem(item);
            pts.setPassage(passage);
            pts.setSequence(sequence);

            entityManager.persist(pts);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting PassageItemSet : " + e.getMessage(), e);
        }
        return pts;
    }

    public Difficulty insertDifficulty(String name) {

        Difficulty difficulty = new Difficulty();
        try {
            Query query = entityManager.createNamedQuery("Difficulty.maxId");
            difficulty.setId((Long) query.getSingleResult() + 1);
            difficulty.setName(name);
            entityManager.persist(difficulty);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting Difficulty : " + e.getMessage(), e);
        }
        return difficulty;
    }

    public int getMaxPassageId() {
        int nextPassageId = 0;
        try {
            TypedQuery<Integer> query = entityManager.createNamedQuery(
                    "Passage.maxId", Integer.class);
            nextPassageId = query.getSingleResult();
            nextPassageId += 1;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in fetching next passage id : " + e.getMessage(), e);
        }
        return nextPassageId;
    }

    public PublicationStatus insertPublicationStatus(String name) {

        PublicationStatus ps = new PublicationStatus();
        try {
            Query query = entityManager
                    .createNamedQuery("PublicationStatus.maxId");
            ps.setId((Integer) query.getSingleResult() + 1);
            ps.setName(name);
            entityManager.persist(ps);
        } catch (NoResultException e) {
        	  LOGGER.log(Level.SEVERE, "Error in inserting PublicationStatus : "
                      , e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error in inserting PublicationStatus : "
                    + e.getMessage(), e);
        }
        return ps;
    }

    public Genre insertGenre(String name) {

        Genre g = new Genre();
        try {
            Query query = entityManager.createNamedQuery("Genre.maxId");
            g.setId((Long) query.getSingleResult() + 1);
            g.setName(name);
            entityManager.persist(g);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in inserting Genre : " + e.getMessage(), e);
        }
        return g;
    }

}
