package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.List;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAlternate;

/**
 * ItemAlternateService is middle tier for the {@link ItemAlternate}.
 * 
 * @author dbloom
 */
@Stateless
@LocalBean
public class ItemAlternateServices implements Serializable{

	private static final long serialVersionUID = 1L;
	
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
	private EntityManager entityManager;
	
	/**
	 * @param id int representing the primary key of the {@link ItemAlternate} 
	 * @return {@link ItemAlternate}
	 */
	public ItemAlternate findItemAlternateById(int id) {
		return entityManager.find(ItemAlternate.class, id);
	}

	/**
	 * @param itemId int representing the {@link Item#getId()}
	 * @return {@link List} of {@link ItemAlternate}s for the item
	 */
	@SuppressWarnings("unchecked")
	public List<ItemAlternate> findItemAlternatesByItemId(long itemId) {
		Query query = entityManager.createNamedQuery("alternatesByItemId");
		query.setParameter("i_id", itemId);
		return query.getResultList();
	}
	
	/**
	 * @param itemAlternateId int representing the {@link ItemAlternate#getAlternateItemId()} or {@link Item#getId()}
	 * @return {@link ItemAlternate}; may return null if the {@link Item} is not an alternate.
	 */
	public ItemAlternate findByAlternateItemId(long itemAlternateId) {
		ItemAlternate ia = null;
		
		Query query = entityManager.createNamedQuery("alternateByAlternateItemId");
		query.setParameter("ia_alternate_i_id", itemAlternateId);	
		
		try {
			ia = (ItemAlternate) query.getSingleResult();
		} catch (NoResultException nre) {
			// result will either be zero or one
		}
		
		return ia;
	}

}
