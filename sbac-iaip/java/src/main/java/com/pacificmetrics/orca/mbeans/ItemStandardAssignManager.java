package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;

import java.util.Collections;
import java.util.List;


import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.event.ValueChangeEvent;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.orca.cts.model.Category;
import com.pacificmetrics.orca.cts.model.Publication;
import com.pacificmetrics.orca.cts.model.Publisher;
import com.pacificmetrics.orca.cts.model.Standard;
import com.pacificmetrics.orca.cts.model.Subject;
import com.pacificmetrics.orca.cts.service.ClaimTargetStandardService;
import com.pacificmetrics.orca.ejb.ItemServices;

/**
 * 
 * 
 * 
 * @author amajumdar
 */
@ManagedBean(name = "itemStandardAssign")
@ViewScoped
public class ItemStandardAssignManager extends AbstractManager implements
		Serializable {


	private static final long serialVersionUID = 1L;
	
	@EJB
	private ClaimTargetStandardService claimTargetStandardService;
	
	@EJB
	private ItemServices itemServices;
	
	private String itemId;
	private String standardValue;
	private String standardId;
	private String publisher;
	private String publication;
	private String grade;
	private String subject;
	private String subjectKey;
	private String standardInd;
	private Boolean saveFlag = Boolean.FALSE;
	private List<Category> categoryList;
	private List<Publisher> publisherList;
	private List<Publication> publicationList;
	private String[] standardArray;
	private String callerFlag;
	
	@PostConstruct
	public void load() {
		if(CollectionUtils.isEmpty(categoryList)) {
			itemId = getParameter("item");
			standardValue = getParameter("standardValue");
			standardId = getParameter("standardId");
			grade = getParameter("grade");
			subject = getParameter("subject");
			standardInd = getParameter("standardInd");
			callerFlag = getParameter("callerFlag");
			
			if(StringUtils.isBlank(grade)) {
				error("Error.ItemStandard.InvalidGrade");
			}
			if(StringUtils.isBlank(subject)) {
				error("Error.ItemStandard.InvalidSubject");
			}
		
			parseStandardValue();
			publisherList = claimTargetStandardService.findAllPublishers();
			if(StringUtils.isBlank(publisher)) {
				for(Publisher publisherObj:publisherList) {
					if("SBAC".equalsIgnoreCase(publisherObj.getKey())) {
						publisher = publisherObj.getKey();
						break;
					}
				}
				if(StringUtils.isBlank(publisher)) {
					publisher = publisherList.get(0).getKey();
				}
			}
			List<Subject> subjectList = claimTargetStandardService.findSubjects(publisher);
			if(subjectList != null && CollectionUtils.isNotEmpty(subjectList)) {
				for(Subject subjectObj:subjectList) {
					if(subject.toUpperCase().startsWith(subjectObj.getKey().toUpperCase())) {
						subjectKey = subjectObj.getKey();
					}
				}
			}
			populatePublication();
		}
	}


	public String getCallerFlag() {
		return callerFlag;
	}

	public void setCallerFlag(String callerFlag) {
		this.callerFlag = callerFlag;
	}


	/**
	 * @return the itemId
	 */
	public String getItemId() {
		return itemId;
	}

	/**
	 * @param itemId the itemId to set
	 */
	public void setItemId(String itemId) {
		this.itemId = itemId;
	}

	/**
	 * @return the standardValue
	 */
	public String getStandardValue() {
		return standardValue;
	}

	/**
	 * @param standardValue the standardValue to set
	 */
	public void setStandardValue(String standardValue) {
		this.standardValue = standardValue;
	}

	/**
	 * @return the standardId
	 */
	public String getStandardId() {
		return standardId;
	}

	/**
	 * @param standardId the standardId to set
	 */
	public void setStandardId(String standardId) {
		this.standardId = standardId;
	}

	/**
	 * @return the publisher
	 */
	public String getPublisher() {
		return publisher;
	}

	/**
	 * @param publisher the publisher to set
	 */
	public void setPublisher(String publisher) {
		this.publisher = publisher;
	}

	/**
	 * @return the publication
	 */
	public String getPublication() {
		return publication;
	}

	/**
	 * @param publication the publication to set
	 */
	public void setPublication(String publication) {
		this.publication = publication;
	}

	/**
	 * @return the grade
	 */
	public String getGrade() {
		return grade;
	}

	/**
	 * @param grade the grade to set
	 */
	public void setGrade(String grade) {
		this.grade = grade;
	}

	/**
	 * @return the subject
	 */
	public String getSubject() {
		return subject;
	}

	/**
	 * @param subject the subject to set
	 */
	public void setSubject(String subject) {
		this.subject = subject;
	}

	/**
	 * @return the subjectKey
	 */
	public String getSubjectKey() {
		return subjectKey;
	}

	/**
	 * @param subjectKey the subjectKey to set
	 */
	public void setSubjectKey(String subjectKey) {
		this.subjectKey = subjectKey;
	}

	/**
	 * @return the standardInd
	 */
	public String getStandardInd() {
		return standardInd;
	}

	/**
	 * @param standardInd the standardInd to set
	 */
	public void setStandardInd(String standardInd) {
		this.standardInd = standardInd;
	}

	/**
	 * @return the saveFlag
	 */
	public Boolean getSaveFlag() {
		return saveFlag;
	}

	/**
	 * @param saveFlag the saveFlag to set
	 */
	public void setSaveFlag(Boolean saveFlag) {
		this.saveFlag = saveFlag;
	}

	/**
	 * @return the categoryList
	 */
	public List<Category> getCategoryList() {
		return categoryList;
	}

	/**
	 * @param categoryList the categoryList to set
	 */
	public void setCategoryList(List<Category> categoryList) {
		this.categoryList = categoryList;
	}

	/**
	 * @return the publisherList
	 */
	public List<Publisher> getPublisherList() {
		return publisherList;
	}

	/**
	 * @param publisherList the publisherList to set
	 */
	public void setPublisherList(List<Publisher> publisherList) {
		this.publisherList = publisherList;
	}

	/**
	 * @return the publicationList
	 */
	public List<Publication> getPublicationList() {
		return publicationList;
	}

	/**
	 * @param publicationList the publicationList to set
	 */
	public void setPublicationList(List<Publication> publicationList) {
		this.publicationList = publicationList;
	}

	/**
	 * @return the standardArray
	 */
	public String[] getStandardArray() {
		return standardArray;
	}

	/**
	 * @param standardArray the standardArray to set
	 */
	public void setStandardArray(String[] standardArray) {
		this.standardArray = standardArray;
	}

	/**
	 * parse standard value to find out category and tree levels
	 * @return 
	 */
	private void parseStandardValue() {
		if (standardValue != null && standardValue.indexOf(":") > 1) {
			publisher = standardValue.substring(0, standardValue.indexOf("-"));
			int indexOfColon = standardValue.indexOf(":");
			publication = standardValue.substring(0,indexOfColon);
			
			String levels = standardValue.substring(indexOfColon + 1);
			standardArray = levels.split("\\|");
			populateStandards();
		} 
	}
	
	/**
	 * populate publication list and set publication
	 * for a publisher and subject combination
	 * @return 
	 */
	private void populatePublication() {
		if (subjectKey == null) {
			subjectKey = "";
		}
		publicationList = claimTargetStandardService.findPublications(
				publisher, subjectKey);
		if (StringUtils.isBlank(publication)) {
			if (publicationList != null
					&& CollectionUtils.isNotEmpty(publicationList)) {
				publication = publicationList.get(0).getKey();
			}
			populateStandards();
		}
	}
	
	/**
	 * populate publication list and set publication
	 * for a publisher and subject combination
	 * @return 
	 */
	private void populateStandards() {
		saveFlag = Boolean.FALSE;
		categoryList = claimTargetStandardService.findCateogries(publication);
		if(categoryList != null && CollectionUtils.isNotEmpty(categoryList)) {
			int i = 0;
			StringBuilder sbParentLevel;
			List<Standard> standardList;
			for(Category category:categoryList) {
				if(i == 0) {
					standardList = claimTargetStandardService.findStandards(publication, grade, String.valueOf(i + 1));
					if(standardArray != null && standardArray.length >= i) {
						category.setLevel(publication + ":" + standardArray[i]);
					} else {
						if (CollectionUtils.isNotEmpty(standardList)) {
							category.setLevel(standardList.get(0).getKey());
						}
					}
				} else {
					sbParentLevel = null;
					if(standardArray != null && standardArray.length >= i) {
						for (int j = 0; j < i; j++) {
							if (sbParentLevel == null) {
								sbParentLevel = new StringBuilder(publication);
								sbParentLevel.append(":");
							} else {
								sbParentLevel.append("|");
							}
							sbParentLevel.append(standardArray[j]);
						}
						standardList = claimTargetStandardService
								.findStandards(
										publication,
										grade,
										String.valueOf(i + 1),
										sbParentLevel != null ? sbParentLevel
												.toString() : "null");
						category.setLevel(sbParentLevel + "|" + standardArray[i]);
					} else {
						String parentLevel = categoryList.get(i-1).getLevel();
						standardList = claimTargetStandardService
								.findStandards(publication, grade, String
										.valueOf(i + 1),
										parentLevel != null ? parentLevel
												: "null");
						if (CollectionUtils.isNotEmpty(standardList)) {
							category.setLevel(standardList.get(0).getKey());
						}
					}
				}

				if(standardList != null) {
					category.setStandardList(standardList);
				} else {
					category.setStandardList(Collections.<Standard>emptyList());
				}
				i++;
			}
		}
	}
	
	public void onChangeStandard(ValueChangeEvent event) {
        String selectedStandardKey = (String) event.getNewValue();
        String changedStandardKey = (String) event.getOldValue();
		if (!(StringUtils.isBlank(selectedStandardKey) && StringUtils.isBlank(changedStandardKey))) {
			saveFlag = Boolean.FALSE;

			int i = 0;
			int changedLevel = -1;
			for (Category category : categoryList) {
				if (changedStandardKey.equals(category.getLevel())) {
					category.setLevel(selectedStandardKey);
					changedLevel = i;
				} else if (changedLevel >= 0) {
					List<Standard> standardList = claimTargetStandardService
							.findStandards(publication, grade,
									String.valueOf(i + 1), selectedStandardKey);
					if (CollectionUtils.isNotEmpty(standardList)) {
						category.setStandardList(standardList);
						selectedStandardKey = standardList.get(0).getKey();
					} else {
						category.setStandardList(Collections.<Standard>emptyList());
						selectedStandardKey = "";
					}
					category.setLevel(selectedStandardKey);
				}
				i++;
			}
		}
	}
	
	public void onChangePublisher(ValueChangeEvent event) {
		publisher = (String) event.getNewValue();
		if (StringUtils.isNotBlank(publisher)) {
			publication = null;
			populatePublication();
		}
	}
	
	public void onChangePublication(ValueChangeEvent event) {
		publication = (String) event.getNewValue();
		if (StringUtils.isNotBlank(publication)) {
			populateStandards();
		}
	}
	
	public void saveStandard() {
		try {
			if(/*categoryList != null && */CollectionUtils.isNotEmpty(categoryList)) {
				standardValue = categoryList.get(categoryList.size() - 1)
						.getLevel();
				if (StringUtils.isNotBlank(standardValue)) {
					if (StringUtils.isNotBlank(standardInd)) {
						if ("P".equalsIgnoreCase(standardInd)) {
							itemServices.updateItemField(
									Long.parseLong(itemId),
									"i_primary_standard", standardValue);
						} else if ("S".equalsIgnoreCase(standardInd)) {
							if (standardId == null || standardId.isEmpty()) {
								itemServices.insertItemStandard(itemId,
										standardValue);
							} else {
								itemServices.updateItemStandard(
										Long.parseLong(standardId),
										standardValue);
							}
						}
					}
					saveFlag = Boolean.TRUE;
				}else{
					error("Error.ItemStandard.StandardNotFound");
					saveFlag = Boolean.FALSE;
				}
			}
			
		} catch (NumberFormatException e) {
			error("OPERATION_FAILED", String.valueOf(itemId));
		}
	}
	
	public void okStandard() {
		try {
			if(categoryList != null && CollectionUtils.isNotEmpty(categoryList)) {
				standardValue = categoryList.get(categoryList.size() - 1)
						.getLevel();
				if (StringUtils.isNotBlank(standardValue)) {
				saveFlag = Boolean.TRUE;
				} else {
					error("Error.ItemStandard.StandardNotFound");
					saveFlag = Boolean.FALSE;
				}
			}
					
		} catch (NumberFormatException e) {
			error("OPERATION_FAILED", String.valueOf(itemId));
		}
	}
	
}
