package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import org.apache.commons.beanutils.BeanUtils;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.orca.AccessibilityServicesStatus;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.InclusionOrder;

@Stateless
@LocalBean
/**
 * This EJB class is technically abstract and shouldn't be instantiated. Use AccessibilityItemServices or AccessibilityPassageServices
 * 
 * @author amiliteev
 *
 */
public class AccessibilityServices implements Serializable {

    private static final long serialVersionUID = 1L;

    @PersistenceContext(unitName = "cde-unit-unicode", type = PersistenceContextType.TRANSACTION)
    protected EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public List<AccessibilityElement> findAccessibilityElements(long itemId) {
        Query query = createNamedQuery("aeBy?Id");
        query.setParameter(getFieldName(), itemId);
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<InclusionOrder> findInclusionOrders(int itemId) {
        Query query = createNamedQuery("ioBy?Id");
        query.setParameter(getFieldName(), itemId);
        return query.getResultList();
    }

    public void deleteAccessibilityElements(int itemId,
            List<String> retainElementNames) {
        if (retainElementNames != null && !retainElementNames.isEmpty()) {
            Query query = createNamedQuery("aeDeleteFor?Id");
            query.setParameter(getFieldName(), itemId);
            query.setParameter("nameList", retainElementNames);
            query.executeUpdate();
        } else {
            Query query = createNamedQuery("aeDeleteFor?IdNoRetain");
            query.setParameter(getFieldName(), itemId);
            query.executeUpdate();
        }
    }

    public void replaceAccessibilityElements(int itemId,
            List<AccessibilityElement> elements) {
        replaceAccessibilityElements(itemId, elements,
                Collections.<String> emptyList());
    }

    public void replaceAccessibilityElements(int itemId,
            List<AccessibilityElement> elements,
            Collection<String> modifiedElementNames) {
        // delete those elements that have been removed by user; populating
        // array of element names to retain
        List<String> elementNames = new ArrayList<String>();
        for (AccessibilityElement ae : elements) {
            elementNames.add(ae.getName());
        }
        deleteAccessibilityElements(itemId, elementNames);
        // insert those elements that have been added by user
        List<AccessibilityElement> existingElements = findAccessibilityElements(itemId);
        Set<String> existingElementNames = new HashSet<String>();
        Map<String, AccessibilityElement> elementsToModify = new HashMap<String, AccessibilityElement>();
        for (AccessibilityElement ae : existingElements) {
            existingElementNames.add(ae.getName());
            if (modifiedElementNames.contains(ae.getName())) {
                elementsToModify.put(ae.getName(), ae);
            }
        }
        for (AccessibilityElement ae : elements) {
            if (!existingElementNames.contains(ae.getName())) {
                entityManager.persist(ae);
            } else {
                AccessibilityElement elementToModify = elementsToModify.get(ae
                        .getName());
                if (elementToModify != null) {
                    updateElement(elementToModify, ae);
                }
            }
        }
    }

    public void updateElement(AccessibilityElement elementToModify,
            AccessibilityElement newElement) {
        elementToModify.setContentLinkType(newElement.getContentLinkType());
        elementToModify.setContentName(newElement.getContentName());
        elementToModify.setContentType(newElement.getContentType());
        elementToModify.setTextLinkStartChar(newElement.getTextLinkStartChar());
        elementToModify.setTextLinkStopChar(newElement.getTextLinkStopChar());
        elementToModify.setTextLinkType(newElement.getTextLinkType());
        elementToModify.setTextLinkWord(newElement.getTextLinkWord());
        entityManager.persist(elementToModify);
    }

    /**
     * Replaces accessibility features for the given elements
     * 
     * @param featuresMap
     *            Map elementId to List of features
     * 
     */
    public void replaceAccessibilityFeatures(
            Map<Integer, List<AccessibilityFeature>> featuresMap) {
        for (Map.Entry<Integer, List<AccessibilityFeature>> entry : featuresMap
                .entrySet()) {
            replaceAccessibilityFeatures(entry.getKey(), entry.getValue());
        }
    }

    public void replaceAccessibilityFeatures(int elementId,
            List<AccessibilityFeature> features) {
        deleteAccessibilityFeaturesForElement(elementId);
        for (AccessibilityFeature feature : features) {
            feature.setId(0);
            feature.setElementId(elementId);
            try {
                entityManager.persist(BeanUtils.cloneBean(feature));
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }

    public void deleteAccessibilityFeaturesForElement(int elementId) {
        Query query = entityManager.createNamedQuery("afDeleteForElementId");
        query.setParameter("ae_id", elementId);
        query.executeUpdate();
    }

    public AccessibilityElement findAccessibilityElementById(int id) {
        return entityManager.find(AccessibilityElement.class, id);
    }

    public AccessibilityFeature findAccessibilityFeatureById(int id) {
        return entityManager.find(AccessibilityFeature.class, id);
    }

    public List<Integer> getFeaturesForType(int type) {
        List<Integer> result = new ArrayList<Integer>();
        switch (type) {
        case AccessibilityFeature.T_BRAILLE:
            result.add(AccessibilityFeature.F_BRAILLE_TEXT);
            break;
        case AccessibilityFeature.T_HIGHLIGHTING:
            result.add(AccessibilityFeature.F_HIGHLIGHTED_TEXT);
            break;
        case AccessibilityFeature.T_SPOKEN:
            result.add(AccessibilityFeature.F_AUDIO_TEXT);
            result.add(AccessibilityFeature.F_TEXT_TO_SPEECH);
            break;
        case AccessibilityFeature.T_TACTILE:
            result.add(AccessibilityFeature.F_AUDIO_FILE);
            result.add(AccessibilityFeature.F_AUDIO_TEXT);
            result.add(AccessibilityFeature.F_BRAILLE_TEXT);
            break;
        default:

        }
        return result;
    }

    public AccessibilityFeature insertFeature(int featureId, int elementId,
            int featureType, int featureCode, String langCode, String info)
            throws ServiceException {
        AccessibilityFeature feature = featureId > 0 ? findAccessibilityFeatureById(featureId)
                : new AccessibilityFeature();
        if (feature == null) {
            throw new ServiceException(
                    AccessibilityServicesStatus.FEATURE_NOT_FOUND, featureId);
        }
        feature.setElementId(elementId);
        feature.setType(featureType);
        feature.setFeature(featureCode);
        feature.setLangCode(langCode);
        feature.setInfo(info);
        return entityManager.merge(feature);
    }

    public void deleteAccessibilityFeature(int id) throws ServiceException {
        AccessibilityFeature feature = findAccessibilityFeatureById(id);
        if (feature == null) {
            throw new ServiceException(
                    AccessibilityServicesStatus.FEATURE_NOT_FOUND, id);
        }
        entityManager.remove(feature);
    }

    public void persistInclusionOrders(
            Collection<InclusionOrder> inclusionOrders) {
        for (InclusionOrder io : inclusionOrders) {
            entityManager.persist(io);
        }
    }

    public void deleteInclusionOrders(int id) {
        Query query = createNamedQuery("ioDeleteFor?Id");
        query.setParameter(getFieldName(), id);
        query.executeUpdate();
    }

    public void replaceInclusionOrders(int id,
            Collection<InclusionOrder> inclusionOrders) {
        deleteInclusionOrders(id);
        persistInclusionOrders(inclusionOrders);
    }

    public String getEntityName() {
        return "";
    }

    public String getFieldName() {
        return "";
    }

    private Query createNamedQuery(String queryName) {
        return entityManager.createNamedQuery(queryName.replace("?",
                getEntityName()));
    }

}
