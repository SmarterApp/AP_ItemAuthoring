package com.pacificmetrics.orca.ejb;

import java.util.List;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.TypedQuery;

import com.pacificmetrics.orca.entities.MetadataMapping;

@Stateless
@LocalBean
public class MetadataServices {
	
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;

    /**
     * This method is used to retrieve all entries from 'metadata_mapping' tables
     * 
     * @return List of MetadataMapping entities corresponding to entries in 'metadata_mapping' tables
     * 
     */
	public List<MetadataMapping> getAllMetadataMappings() {
        TypedQuery<MetadataMapping> query = entityManager.createNamedQuery("allMetadataMapping", MetadataMapping.class);
        return query.getResultList();
    }
    
    /**
     * This method is used to retrieve entries for OT_ITEM object type from 'metadata_mapping' tables
     * 
     * @return List of MetadataMapping entities corresponding to entries in 'metadata_mapping' tables
     * 
     */
    public List<MetadataMapping> getMetadataMappingsForItems() {
        TypedQuery<MetadataMapping> query = entityManager.createNamedQuery("mmByObjectType", MetadataMapping.class);
        query.setParameter("mm_object_type", MetadataMapping.OT_ITEM);
        return query.getResultList();
    }
    
}
