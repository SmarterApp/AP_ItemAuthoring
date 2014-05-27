package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;
import javax.persistence.TypedQuery;

import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemFragment;
import com.pacificmetrics.orca.entities.ItemInteraction;
import com.pacificmetrics.orca.helpers.ItemPassageHelper;

@Stateless
@LocalBean
public class ItemServices implements Serializable {
    
    private static final String INTERACTION_REG_EXP = "<(?:span|div) class=\\\"orca:interaction\\\" id=\\\"interaction_(\\d+)\\\"[^>]*>.*?<\\/(?:span|div)>";
    
    static private Logger logger = Logger.getLogger(ItemServices.class.getName()); 

	private static final long serialVersionUID = 1L;
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;
	
	public Item findItemByExternalId(String externalId) {
		TypedQuery<Item> query = entityManager.createNamedQuery("itemByExternalId", Item.class);
		query.setParameter("external_id", externalId);
		List<Item> resultList = query.getResultList();
		return resultList != null && !resultList.isEmpty() ? (Item)resultList.get(0) : null;
	}
	
    public Item findItemByItemBankAndExternalId(int ibId, String externalId) {
        TypedQuery<Item> query = entityManager.createNamedQuery("itemByItemBankAndExternalId", Item.class);
        query.setParameter("ib_id", ibId);
        query.setParameter("external_id", externalId);
        List<Item> resultList = query.getResultList();
        return resultList != null && !resultList.isEmpty() ? resultList.get(0) : null;
    }
	
    public Item findItemById(int id) {
        return entityManager.find(Item.class, id);
    }
    
    /**
     * Retrieves item with the given item id from database. Makes sure that item interactions associated with the item are also retrieved 
     * 
     * @param id
     * @return instance of Item with ItemInteraction list populated
     */
    public Item findItemWithInteractionsById(int id) {
        Item result = entityManager.find(Item.class, id);
        if (result != null) {
            result.getItemInteractions();
        }
        return result;
    }
    
    public Item findItemWithMetadataById(int id) {
        Item result = entityManager.find(Item.class, id);
        if (result != null) {
            result.getMetadataXml();
        }
        return result;
    }
    
	@SuppressWarnings("unchecked")
	public List<ItemFragment> findItemFragments(long itemId) {
		Query query = entityManager.createNamedQuery("itemFragmentsById");
		query.setParameter("i_id", itemId);
		return query.getResultList();
	}
	
	public String getItemAsHTML(Item item) {
		StringBuffer result = new StringBuffer();
		SortedMap<Integer, String> stemMap = new TreeMap<Integer, String>(),
				promptMap = new TreeMap<Integer, String>(), choiceMap = new TreeMap<Integer, String>();
		for (ItemFragment itemFragment: findItemFragments(item.getId())) {
		    String text = ItemPassageHelper.fixImageSource(itemFragment.getText());
			if (itemFragment.getType() == ItemFragment.IF_STEM) {
				stemMap.put(itemFragment.getSequence(), text);
			}
			if (itemFragment.getType() == ItemFragment.IF_PROMPT) {
				promptMap.put(itemFragment.getSequence(), text);
			}
			if (itemFragment.getType() == ItemFragment.IF_CHOICE) {
				choiceMap.put(itemFragment.getSequence(), text);
			}
		}
		for (Map.Entry<Integer, String> entry: stemMap.entrySet()) {
			result.append(entry.getValue() + "<br>");
		}
		for (Map.Entry<Integer, String> entry: promptMap.entrySet()) {
			result.append(entry.getValue() + "<br>");
		}
		if (item.getItemType() == Item.IT_SR_EXCLUSIVE || item.getItemType() == Item.IT_SR_NON_ECLUSIVE) {
    		result.append("<table>");
    		for (Map.Entry<Integer, String> entry: choiceMap.entrySet()) {
    			result.append("<tr><td><b>" + (char)('A' + entry.getKey() - 1) + ":&nbsp; </b><td>" + entry.getValue() + "<br>");
    		}
    		result.append("</table>");
		}
		return result.toString();
	}
	
    /**
     * Modified version of the method that returns HTML representation of the item. Retrieves data from item_fragment and item_interaction tables
     * First, the stem is retrieved; then looking in stem for interactions using pattern INTERACTION_REG_EXP.
     * Each interaction is then replaced with its HTML presentation. @See getItemInteractionAsHTML()
     * 
     * @param item
     * @return HTML representation of the item (non-interactive)
     */
	public String getItemAsHTML_2(Item item) {
        StringBuffer result = new StringBuffer();
        List<ItemFragment> itemFragments = findItemFragments(item.getId());
        for (ItemFragment itemFragment: itemFragments) {
            if (itemFragment.getType() == ItemFragment.IF_STEM) {
                String text = ItemPassageHelper.fixImageSource(itemFragment.getText());
                
                Pattern p = Pattern.compile(INTERACTION_REG_EXP);
                Matcher m = p.matcher(text);
                while (m.find()) {
                    int interactionId = Integer.parseInt(m.group(1));
                    ItemInteraction interaction = item.findItemInteraction(interactionId);
                    if (interaction == null) {
                        logger.warning("Item Interaction not found for ii_id = " + interactionId);
                    } else {
                        m.appendReplacement(result, getItemInteractionAsHTML(interaction, itemFragments));
                    }
                }
                m.appendTail(result);
                return result.toString();
            }
        }
        logger.warning("Stem not found for item with i_id = " + item.getId());
        return result.toString();
    }
    
    /**
     * Returns HTML representation of the given item interaction, using given list of ItemFragment instances for the item
     * Searches for prompt(s) and choice(s) in the list of item fragments and concatenates their content according to sequence 
     * 
     * @param itemInteraction
     * @param itemFragments
     * @return
     */
	public String getItemInteractionAsHTML(ItemInteraction itemInteraction, List<ItemFragment> itemFragments) {
        StringBuffer result = new StringBuffer();
        SortedMap<Integer, String> promptMap = new TreeMap<Integer, String>(), 
                                   choiceMap = new TreeMap<Integer, String>();
        for (ItemFragment itemFragment: itemFragments) {
            if (itemFragment.getItemInteractionId() == itemInteraction.getId()) {
                String text = ItemPassageHelper.fixImageSource(itemFragment.getText());
                if (itemFragment.getType() == ItemFragment.IF_PROMPT) {
                    promptMap.put(itemFragment.getSequence(), text);
                }
                if (itemFragment.getType() == ItemFragment.IF_CHOICE) {
                    choiceMap.put(itemFragment.getSequence(), text);
                }
            }
        }
        for (Map.Entry<Integer, String> entry: promptMap.entrySet()) {
            result.append(entry.getValue() + "<br>");
        }
        if (itemInteraction.getType() == ItemInteraction.II_CHOICE) { 
            result.append("<table>");
            for (Map.Entry<Integer, String> entry: choiceMap.entrySet()) {
                result.append("<tr><td><b>" + (char)('A' + entry.getKey() - 1) + ":&nbsp; </b><td>" + entry.getValue());
            }
            result.append("</table>");
        }
        return result.toString();
    }
    
	public Map<Long, String> getItemIds(List<String> externalIdList) {
	    Map<Long, String> result = new HashMap<Long, String>();
	    TypedQuery<Object[]> query = entityManager.createQuery("select new String(i.externalId), new Long(i.id) from Item i where i.externalId IN :list", Object[].class);
	    query.setParameter("list", externalIdList);
	    for (Object[] row: query.getResultList()) {
	        result.put((Long)row[1], (String)row[0]);
	    }
	    return result;
	}
	
	/**
	 * This method deletes all entries from item_characterization table for the given item id and characterization type
	 * 
	 * @param itemId Item ID
	 * @param icType Characterization type
	 */
	public void deleteItemCharacterization(long itemId, int icType) {
        Query query = entityManager.createNativeQuery("delete from item_characterization where i_id = ? and ic_type = ?");
        query.setParameter(1, itemId);
        query.setParameter(2, icType);
        query.executeUpdate();
	}
	
	/**
	 * This method inserts entry with the given value into item_characterization table for the given item id and characterization type 
	 * 
	 * @param itemId Item Id
	 * @param icType Characterization type
	 * @param value  Value to be inserted
	 */
	public void insertItemCharacterization(long itemId, int icType, int value) {
	    Query query = entityManager.createNativeQuery("insert into item_characterization (i_id, ic_type, ic_value) values (?, ?, ?)");
        query.setParameter(1, itemId);
        query.setParameter(2, icType);
        query.setParameter(3, value);
        query.executeUpdate();
	}
	
    /**
     * This method deletes all existing entries for the given item id and characterization type (if any)
     * and inserts new record with the given value
     * 
     * @param itemId Item Id
     * @param icType Characterization type
     * @param value  Value to be inserted/updated
     */
	public void upsertItemCharacterization(long itemId, int icType, int value) {
        deleteItemCharacterization(itemId, icType);
        insertItemCharacterization(itemId, icType, value);
    }
    
	/**
	 * This method is used to update single field in 'item' table using native query
	 * 
	 * @param itemId    Item Id
	 * @param fieldName Field name to update
	 * @param value     The value to set for the field
	 */
	public void updateItemField(long itemId, String fieldName, Object value) {
	    Query query = entityManager.createNativeQuery("update item set " + fieldName + " = ? where i_id = ?");
	    query.setParameter(1, value);
	    query.setParameter(2, itemId);
	    query.executeUpdate();
	}
	
}
