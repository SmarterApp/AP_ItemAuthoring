package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.List;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.orca.entities.Passage;

@Stateless
@LocalBean
public class PassageServices implements Serializable {

	private static final long serialVersionUID = 1L;
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;
	
	public Passage findPassageById(int passageId) {
		return entityManager.find(Passage.class, passageId);
	}
	
	@SuppressWarnings("unchecked")
	public List<Passage> getPassagesByBankId(int bankId) {
		Query query = entityManager.createNamedQuery("passageByBankIdOrderByName");
		query.setParameter("ib_id", bankId);
		return query.getResultList();
	}
	
}
