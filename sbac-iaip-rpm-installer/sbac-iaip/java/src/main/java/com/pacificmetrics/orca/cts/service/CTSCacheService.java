package com.pacificmetrics.orca.cts.service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.AccessTimeout;
import javax.ejb.ConcurrencyManagement;
import javax.ejb.ConcurrencyManagementType;
import javax.ejb.EJB;
import javax.ejb.Lock;
import javax.ejb.LockType;
import javax.ejb.Singleton;

import net.sf.ehcache.Cache;
import net.sf.ehcache.CacheManager;
import net.sf.ehcache.Element;

import org.apache.commons.collections.CollectionUtils;

import com.pacificmetrics.orca.cts.CTSCacheConstants;
import com.pacificmetrics.orca.cts.model.Category;
import com.pacificmetrics.orca.cts.model.Grade;
import com.pacificmetrics.orca.cts.model.Publication;
import com.pacificmetrics.orca.cts.model.Publisher;
import com.pacificmetrics.orca.cts.model.Standard;
import com.pacificmetrics.orca.cts.model.Subject;

@ConcurrencyManagement(ConcurrencyManagementType.CONTAINER)
@Singleton
public class CTSCacheService {

    private static final Logger LOGGER = Logger.getLogger(CTSCacheService.class
            .getCanonicalName());

    @EJB
    private CTSService ctsService;

    private CacheManager cacheManager;

    private Cache ctsCache;

    @AccessTimeout(value = 1, unit = TimeUnit.HOURS)
    public void initCache() {
        LOGGER.info("Initializing CTS cache manager ...");
        try {
            cacheManager = CacheManager.create(CTSScheduler.class
                    .getClassLoader().getResourceAsStream("ehcache.xml"));
            LOGGER.info("Creating CTS cache...");
            ctsCache = cacheManager.getCache(CTSCacheConstants.CTS_CACHE);
            LOGGER.info("Created CTS cache...");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error : " + e.getMessage(), e);
        }
        LOGGER.info("Completing initializing CTS cache manager ...");
        refreshCache();
    }

    @AccessTimeout(value = 1, unit = TimeUnit.HOURS)
    public void refreshCache() {
        if (cacheManager == null || ctsCache == null) {
            initCache();
        }
        LOGGER.info("Refreshing CTS cache ...");
        long startTime = System.currentTimeMillis();

        List<Publisher> publishers = ctsService.findAllPublishers();
        if (CollectionUtils.isNotEmpty(publishers)) {
            setPublishers(publishers);
            for (Publisher publisher : publishers) {
                fetchSubjects(publisher.getKey());
            }
        }

        List<Grade> grades = ctsService.findAllGrades();
        setGrades(grades);

        List<Subject> subjects = ctsService.findAllSubjects();
        setSubjects(subjects);
        long endTime = System.currentTimeMillis();
        LOGGER.info("Total Cache Size " + ctsCache.getSize());
        LOGGER.info("Completed CTS cache refresh in ... "
                + ((endTime - startTime) / 1000) + " seconds");
    }

    public void fetchSubjects(String publisherKey) {
        LOGGER.info("Fetching subjects for publisher key " + publisherKey);
        List<Subject> subjects = ctsService
                .findSubjectsByPublisher(publisherKey);
        LOGGER.info("Total subjects found "
                + (subjects != null ? subjects.size() : "0")
                + " for publisher key " + publisherKey);
        if (CollectionUtils.isNotEmpty(subjects)) {
            setSubjects(publisherKey, subjects);
            for (Subject subject : subjects) {
                fetchPublications(publisherKey, subject.getKey());
            }
        }
    }

    public void fetchPublications(String publisherKey, String subjectKey) {
        LOGGER.info("Fetching publications by publisher key " + publisherKey
                + " and subject key " + subjectKey);
        List<Publication> publications = ctsService
                .findPublicationByPublisherAndSubject(publisherKey, subjectKey);
        LOGGER.info("Total publications found "
                + (publications != null ? publications.size() : "0")
                + " for publisher key " + publisherKey + " and subject key "
                + subjectKey);
        if (CollectionUtils.isNotEmpty(publications)) {
            setPublications(publisherKey, subjectKey, publications);
            for (Publication publication : publications) {
                fetchCategories(publication.getKey());
                fetchGrades(publication.getKey());
            }
        }
    }

    private void fetchCategories(String publicationKey) {
        LOGGER.info("Fetching categories by publication key " + publicationKey);
        List<Category> categories = ctsService
                .findCategoryByPublicationKey(publicationKey);
        LOGGER.info("Total categories found "
                + (categories != null ? categories.size() : "0")
                + " by publication key " + publicationKey);
        setCategories(publicationKey, categories);
    }

    private void fetchGrades(String publicationKey) {
        LOGGER.info("Fetching grades by publication key " + publicationKey);
        List<Grade> grades = ctsService.findGradesByPublication(publicationKey);
        LOGGER.info("Total grades found "
                + (grades != null ? grades.size() : "0")
                + " by publication key " + publicationKey);
        if (CollectionUtils.isNotEmpty(grades)) {
            setGrades(publicationKey, grades);
            for (Grade grade : grades) {
                fetchStandards(publicationKey, grade.getKey());
            }
        }
    }

    private void fetchStandards(String publicationKey, String gradeKey) {
        LOGGER.info("Fetching standards by publication key " + publicationKey
                + " and grade key " + gradeKey);
        List<Standard> standards = ctsService
                .findStandardByPublicationAndGrade(publicationKey, gradeKey);
        LOGGER.info("Total standards found "
                + (standards != null ? standards.size() : "0")
                + " by publication key " + publicationKey + " and grade key "
                + gradeKey);
        setStandards(publicationKey, gradeKey, standards);
    }

    @Lock(LockType.READ)
    public List<Publisher> getPublishers() {
        return this.<Publisher> getValues(CTSCacheConstants.PUBLISHER);
    }

    public void setPublishers(List<Publisher> publishers) {
        put(CTSCacheConstants.PUBLISHER, publishers);
    }

    public void setSubjects(List<Subject> subjects) {
        if (CollectionUtils.isNotEmpty(subjects)) {
            put(CTSCacheConstants.SUBJECT, subjects);
        }
    }

    @Lock(LockType.READ)
    public List<Subject> getSubject() {
        return getValues(CTSCacheConstants.SUBJECT);
    }

    @Lock(LockType.READ)
    public List<Subject> getSubjects(String publisherKey) {
        return getValues(CTSCacheConstants.SUBJECT + "-" + publisherKey);
    }

    public void setSubjects(String publisherKey, List<Subject> subjects) {
        put(CTSCacheConstants.SUBJECT + "-" + publisherKey, subjects);
    }

    public List<Publication> getPublications(String publisherKey,
            String subjectKey) {
        return getValues(CTSCacheConstants.PUBLICATION + "-" + publisherKey
                + "-" + subjectKey);
    }

    public void setPublications(String publisherKey, String subjectKey,
            List<Publication> publications) {
        put(CTSCacheConstants.PUBLICATION + "-" + publisherKey + "-"
                + subjectKey, publications);
    }

    public List<Category> getCategories(String publicationKey) {
        return getValues(CTSCacheConstants.CATEGORY + "-" + publicationKey);
    }

    public void setCategories(String publicationKey, List<Category> categories) {
        if (CollectionUtils.isNotEmpty(categories)) {
            put(CTSCacheConstants.CATEGORY + "-" + publicationKey, categories);
        }
    }

    public List<Standard> getStandards(String publicationKey, String gradeKey) {
        return getValues(CTSCacheConstants.STANDARD + "-" + publicationKey
                + "-" + gradeKey);
    }

    public void setStandards(String publicationKey, String gradeKey,
            List<Standard> standards) {
        if (CollectionUtils.isNotEmpty(standards)) {
            put(CTSCacheConstants.STANDARD + "-" + publicationKey + "-"
                    + gradeKey, standards);
        }
    }

    @Lock(LockType.READ)
    public List<Grade> getGrades() {
        return getValues(CTSCacheConstants.GRADE);
    }

    public void setGrades(List<Grade> grades) {
        if (CollectionUtils.isNotEmpty(grades)) {
            put(CTSCacheConstants.GRADE, grades);
        }
    }

    @Lock(LockType.READ)
    public List<Grade> getGrades(String publicationKey) {
        return getValues(CTSCacheConstants.GRADE + "-" + publicationKey);
    }

    public void setGrades(String publicationKey, List<Grade> grades) {
        if (CollectionUtils.isNotEmpty(grades)) {
            put(CTSCacheConstants.GRADE + "-" + publicationKey, grades);
        }
    }

    private synchronized <T> void put(String key, T object) {
        try {
            if (ctsCache != null) {
                ctsCache.acquireWriteLockOnKey(key);
                ctsCache.put(new Element(key, object));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error acquireing write lock "
                    + "and cache put for key " + key + " " + e.getMessage(), e);
        } finally {
            if (ctsCache != null) {
                ctsCache.releaseWriteLockOnKey(key);
            }
        }
    }

    private synchronized <T> void put(String key, List<T> objects) {
        try {
            if (ctsCache != null) {
                ctsCache.acquireWriteLockOnKey(key);
                ctsCache.put(new Element(key, objects));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error acquireing write lock "
                    + "and cache put for key " + key + " " + e.getMessage(), e);
        } finally {
            if (ctsCache != null) {
                ctsCache.releaseWriteLockOnKey(key);
            }
        }
    }

    private synchronized <K, V> void put(String key, Map<K, V> objectMap) {
        try {
            if (ctsCache != null) {
                ctsCache.acquireWriteLockOnKey(key);
                ctsCache.put(new Element(key, objectMap));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error acquireing write lock "
                    + "and cache put for key " + key + " " + e.getMessage(), e);
        } finally {
            if (ctsCache != null) {
                ctsCache.releaseWriteLockOnKey(key);
            }
        }
    }

    private <T> T getValue(String key) {
        Element element = ctsCache.get(key);
        if (element != null && element.getObjectValue() != null) {
            return (T) element.getObjectValue();
        }
        return null;
    }

    private <T> List<T> getValues(String key) {
        try {
            if (ctsCache != null) {
                Element element = ctsCache.get(key);
                if (element != null
                        && element.getObjectValue() instanceof List<?>) {
                    return (List<T>) element.getObjectValue();
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Unable to read cache for key " + key
                    + " " + e.getMessage(), e);
        }
        return Collections.<T> emptyList();
    }

    private <K, V> Map<K, V> getValueMap(String key) {
        if (ctsCache != null) {
            Element element = ctsCache.get(key);
            if (element != null
                    && element.getObjectValue() instanceof Map<?, ?>) {
                return (Map<K, V>) element.getObjectValue();
            }
        }
        return Collections.<K, V> emptyMap();
    }

    public void destroyCache() {
        LOGGER.info("Shutting down CTS cache manager ...");
        cacheManager.shutdown();
        LOGGER.info("Shutdown CTS cache manager ...");
    }

}
