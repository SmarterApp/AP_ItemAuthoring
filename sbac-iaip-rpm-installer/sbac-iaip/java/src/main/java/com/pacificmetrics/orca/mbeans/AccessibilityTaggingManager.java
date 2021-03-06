package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.event.AbortProcessingException;
import javax.faces.event.AjaxBehaviorEvent;
import javax.faces.model.SelectItem;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.myfaces.custom.tabbedpane.TabChangeEvent;
import org.apache.myfaces.custom.tabbedpane.TabChangeListener;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.AccessibilityItemServices;
import com.pacificmetrics.orca.ejb.AccessibilityPassageServices;
import com.pacificmetrics.orca.ejb.AccessibilityServices;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.MiscServices;
import com.pacificmetrics.orca.ejb.PassageServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.InclusionOrder;
import com.pacificmetrics.orca.entities.InclusionOrderElement;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.helpers.ItemPassageHelper;
import com.pacificmetrics.orca.utils.HTMLUtil;

@ManagedBean(name = "accessibilityTagging")
@ViewScoped
public class AccessibilityTaggingManager extends AbstractManager implements
        Serializable, TabChangeListener {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = Logger
            .getLogger(AccessibilityTaggingManager.class.getName());

    // TODO figure out the way to initialize only that instance of
    // AccessibilityServices which is necessary (probably using JNDI lookup)
    @EJB
    private transient AccessibilityItemServices accessibilityItemServices;

    @EJB
    private transient AccessibilityPassageServices accessibilityPassageServices;

    @EJB
    private transient ItemServices itemServices;

    @EJB
    private transient PassageServices passageServices;

    @EJB
    private transient MiscServices miscServices;

    @EJB
    private transient ItemBankServices itemBankServices;

    private Item item;
    private Passage passage;
    private int itemOrPassageId;

    private String itemOrPassageHTML;
    private String stylesheetUrl = "";
    private List<AccessibilityElement> accessibilityElements;
    private List<String> modifiedElementNames;
    private List<InclusionOrder> inclusionOrders;

    private int selectedTabIndex;
    private String selectedElementId;
    private int selectedElementIndex = -1;

    private Map<String, Integer> featuresForTypeMap = new TreeMap<String, Integer>();

    private int selectedFeatureId = -1;
    private Integer selectedFeatureType = null;
    private int selectedFeature = -1;
    private String selectedLanguage = "";
    private String featureInfo = "";
    /**
     * Must be set to true to display feature editing panel
     */
    private boolean isModifyingFeature = false;

    private Map<Integer, List<AccessibilityFeature>> featuresMap = new HashMap<Integer, List<AccessibilityFeature>>();

    private Integer selectedInclusionOrderType;
    private Map<Integer, List<AccessibilityElement>> inclusionOrderElementsMap = new HashMap<Integer, List<AccessibilityElement>>();
    private List<Integer> inclusionOrderTagsSelected;

    public AccessibilityTaggingManager() {
    }

    @PostConstruct
    public void load() throws ManagerException {
        int itemId = Integer.parseInt(getParameter("item", "0"));
        int passageId = Integer.parseInt(getParameter("passage", "0"));
        if (itemId <= 0 && passageId <= 0) {

            redirectWithError("Item/Passage not specified");

        }
        try {
            if (itemId > 0) {
                item = itemServices.findItemWithInteractionsById(itemId);
                itemOrPassageHTML = itemServices.getItemAsHTML2(item);
                stylesheetUrl = StringUtils.isEmpty(item.getStylesheetUrl()) ? ""
                        : ItemPassageHelper.fixPath(item.getStylesheetUrl());
                itemOrPassageId = itemId;
            } else if (passageId > 0) {
                passage = passageServices.findPassageById(passageId);
                if (passage == null) {
                    redirectWithError("Passage not found");
                }
                itemOrPassageId = passageId;
                readPassageContent();
            }
            if (itemOrPassageHTML != null) {
                // Commented out. The solution provided by handleSVG() method
                // doesn't work if SVG is positioned using CSS.
                // Instead, implemented Javascript solution that puts divs on
                // top of SVGs after latters are loaded

            }
            loadRelatedData();
        } catch (Exception e) {
            throw new ManagerException(e);
        }
    }

    public void readPassageContent() {
        try {
            itemOrPassageHTML = ItemPassageHelper
                    .readPassageContentFromFile(passage.getUrl());
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, e.getMessage(), e);
            try {
                redirectWithError(
                        "System cannot display passage content.",
                        "Program Name: "
                                + itemBankServices.getItemBankName(passage
                                        .getItemBankId())
                                + "<br>Passage Name: " + passage.getName());
            } catch (ServiceException e1) {
                // TODO Auto-generated catch block
                e1.printStackTrace();
                LOGGER.severe(e1.toString());
            }

            // TODO Long term we must develop uniform solution for
            // exception handling in managed beans
            LOGGER.severe(e.toString());

        }
    }

    /**
     * This method adds divs of class 'svgdiv' before all SVG objects
     * encountered in itemOrPassageHTML content. Div id is constructed as
     * follows: svgdiv_<object-id> where <object-id> is id of the object tag
     * Div's width and height match ones of the object tag
     */
    private void handleSVG() {
        Pattern patt = Pattern.compile("<object.*?image.*?>");
        Matcher m = patt.matcher(itemOrPassageHTML);
        StringBuffer sb = new StringBuffer(itemOrPassageHTML.length());
        while (m.find()) {
            String text = m.group();
            String id = extractValue("(id=\")(.+?)(\")", 2, text);
            String height = extractValue("(height=\")(.+?)(\")", 2, text);
            String width = extractValue("(width=\")(.+?)(\")", 2, text);
            if (id != null && height != null && width != null) {
                text = "<div style='width: " + width + "px; height: " + height
                        + "px;' class='svgdiv' id='svgdiv_" + id + "'></div>"
                        + text;
                m.appendReplacement(sb, Matcher.quoteReplacement(text));
            }
        }
        m.appendTail(sb);
        itemOrPassageHTML = sb.toString();
    }

    private static String extractValue(String pattern, int group, String text) {
        Matcher m = Pattern.compile(pattern).matcher(text);
        if (m.find()) {
            return m.group(group);
        }
        return null;
    }

    private void loadRelatedData() {
        loadAccessibilityElements();
        loadInclusionOrders();
    }

    private void loadInclusionOrders() {
        inclusionOrders = getAccessibilityServices().findInclusionOrders(
                itemOrPassageId);
        inclusionOrderElementsMap.clear();
        for (InclusionOrder io : inclusionOrders) {
            List<AccessibilityElement> elements = new ArrayList<AccessibilityElement>();
            for (InclusionOrderElement ioe : io.getElementList()) {
                AccessibilityElement ae = findElement(ioe
                        .getAccessibilityElementId());
                if (ae != null) {
                    elements.add(ae);
                }
            }
            inclusionOrderElementsMap.put(io.getType(), elements);
        }
    }

    private void loadAccessibilityElements() {
        accessibilityElements = new ArrayList<AccessibilityElement>(
                getAccessibilityServices().findAccessibilityElements(
                        itemOrPassageId));
        featuresMap.clear();
        for (AccessibilityElement ae : accessibilityElements) {
            ae.setText(getElementText(ae));
            featuresMap.put(ae.getId(),
                    ae.getFeatureList() != null ? ae.getFeatureList()
                            : new ArrayList<AccessibilityFeature>());
        }
    }

    public String getItemOrPassageHTML() {
        return itemOrPassageHTML;
    }

    public String getTagsJSON() throws ManagerException {
        try {
            String result = accessibilityElementsToJSON().toString();
            LOGGER.info("get tagsJSON: " + result);
            return result;
        } catch (JSONException e) {
            throw new ManagerException(e);
        }
    }

    public void setTagsJSON(String tagsJSON) throws ManagerException {
        // No tags will be sent from tabs, other than first one
        if (StringUtils.isEmpty(tagsJSON)) {
            return;
        }
        try {
            JSONArray json = new JSONArray(tagsJSON);
            LOGGER.info("set tagsJSON: " + json);
            readAccessibilityElementsFromJSON(json);
        } catch (JSONException e) {
            throw new ManagerException(e);
        }
    }

    public void setItemOrPassageHTML(String str) {
        // Do nothing because of X and Y.
    }

    private JSONArray accessibilityElementsToJSON() throws JSONException {
        JSONArray result = new JSONArray();
        for (AccessibilityElement ae : accessibilityElements) {
            if (ae.getContentType() != AccessibilityElement.CT_QTI) {
                continue;
            }
            JSONObject elementObj = new JSONObject();
            elementObj.put("elementId", ae.getName());
            elementObj
                    .put("tagName",
                            ae.getContentLinkType() == AccessibilityElement.CLT_TEXT ? "TEXT"
                                    : "OBJECT");
            elementObj.put("id", ae.getContentName());
            elementObj.put("featureCount", ae.getFeatureList() != null ? ae
                    .getFeatureList().size() : 0);
            elementObj.put("tagText", ae.getText());
            if (ae.getContentLinkType() == AccessibilityElement.CLT_TEXT) {
                JSONObject textSelectionObj = new JSONObject();

                elementObj.put("textSelection", textSelectionObj);
                if (ae.getTextLinkType() == AccessibilityElement.TLT_FULL_STRING) {
                    textSelectionObj.put("entireText", true);
                } else if (ae.getTextLinkType() == AccessibilityElement.TLT_CHAR_SEQUENCE) {
                    textSelectionObj.put("substring", true);
                    textSelectionObj.put("startOffset",
                            ae.getTextLinkStartChar() - 1);
                    textSelectionObj.put("endOffset",
                            ae.getTextLinkStopChar() - 1);
                } else if (ae.getTextLinkType() == AccessibilityElement.TLT_WORD) {
                    textSelectionObj.put("singleWord", true);
                    textSelectionObj.put("wordIndex", ae.getTextLinkWord());
                }
            }
            result.put(elementObj);
        }
        return result;
    }

    private List<AccessibilityElement> readAccessibilityElementsFromJSON(
            JSONArray jsonArray) throws JSONException {
        accessibilityElements = new ArrayList<AccessibilityElement>();
        modifiedElementNames = new ArrayList<String>();
        for (int i = 0; i < jsonArray.length(); i++) {
            JSONObject jsonObj = jsonArray.getJSONObject(i);
            AccessibilityElement element = new AccessibilityElement();
            if (item != null) {
                element.setItemId(item.getId());
            } else if (passage != null) {
                element.setPassageId(passage.getId());
            }
            element.setName(jsonObj.getString("elementId"));
            element.setContentType(AccessibilityElement.CT_QTI);

            if ("TEXT".equals(jsonObj.getString("tagName"))) {
                element.setContentLinkType(AccessibilityElement.CLT_TEXT);
            } else {
                element.setContentLinkType(AccessibilityElement.CLT_OBJECT);
            }
            element.setContentName(jsonObj.getString("id"));
            JSONObject textSelectionObj = jsonObj
                    .optJSONObject("textSelection");
            if (textSelectionObj != null) {
                if (textSelectionObj.optBoolean("entireText", false)) {
                    element.setTextLinkType(AccessibilityElement.TLT_FULL_STRING);
                } else if (textSelectionObj.optBoolean("substring", false)) {
                    element.setTextLinkType(AccessibilityElement.TLT_CHAR_SEQUENCE);
                } else if (textSelectionObj.optBoolean("singleWord", false)) {
                    element.setTextLinkType(AccessibilityElement.TLT_WORD);
                }
                String startOffset = textSelectionObj.optString("startOffset",
                        null);
                if (startOffset != null) {
                    element.setTextLinkStartChar(Integer.parseInt(startOffset) + 1);
                }
                String endOffset = textSelectionObj
                        .optString("endOffset", null);
                if (endOffset != null) {
                    element.setTextLinkStopChar(Integer.parseInt(endOffset) + 1);
                }
                String wordIndex = textSelectionObj
                        .optString("wordIndex", null);
                if (wordIndex != null) {
                    element.setTextLinkWord(Integer.parseInt(wordIndex));
                }
            }
            if (jsonObj.optBoolean("modified", false)) {
                modifiedElementNames.add(element.getName());
            }
            element.setText(getElementText(element));
            accessibilityElements.add(element);
        }
        return accessibilityElements;
    }

    public void doSave() {
        LOGGER.info("Save Elements clicked!");
        getAccessibilityServices().replaceAccessibilityElements(
                itemOrPassageId, accessibilityElements, modifiedElementNames);
        loadRelatedData();
    }

    public void doSaveFeatures() {
        LOGGER.info("Save Features clicked!");
        getAccessibilityServices().replaceAccessibilityFeatures(featuresMap);
        loadRelatedData();
    }

    public void doCancel() {
        LOGGER.info("Cancel clicked!");
        loadRelatedData();
    }

    @Override
    public void processTabChange(TabChangeEvent e)
            throws AbortProcessingException {
        LOGGER.info("tabChangeEvent: " + e);
        selectedTabIndex = e.getNewTabIndex();
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public int getSelectedTabIndex() {
        return selectedTabIndex;
    }

    public void setSelectedTabIndex(int selectedTabIndex) {
        this.selectedTabIndex = selectedTabIndex;
    }

    public AccessibilityElement findElement(int id) {
        for (AccessibilityElement ae : accessibilityElements) {
            if (ae.getId() == id) {
                return ae;
            }
        }
        return null;
    }

    public int findElementIndex(String elementName) {
        for (int i = 0; i < accessibilityElements.size(); i++) {
            AccessibilityElement element = accessibilityElements.get(i);
            if (element.getName().equals(elementName)) {
                return i;
            }
        }
        return -1;
    }

    public AccessibilityElement findElement(String elementName) {
        for (int i = 0; i < accessibilityElements.size(); i++) {
            AccessibilityElement element = accessibilityElements.get(i);
            if (element.getName().equals(elementName)) {
                return element;
            }
        }
        return null;
    }

    public void doRefresh() {
        selectedElementIndex = findElementIndex(selectedElementId);
        resetFeature(true);
        setModifyingFeature(false);
    }

    public String getSelectedElementId() {
        return selectedElementId;
    }

    public void setSelectedElementId(String selectedElementId) {
        this.selectedElementId = selectedElementId;
    }

    public List<SelectItem> getFeatureTypes() {
        List<SelectItem> result = new ArrayList<SelectItem>();
        SelectItem si = new SelectItem(null, "Select Type...");
        si.setNoSelectionOption(true);
        result.add(si);
        for (Map.Entry<Integer, String> entry : AccessibilityFeature.TYPES_AS_STRING_MAP
                .entrySet()) {
            SelectItem selectItem = new SelectItem(entry.getKey(),
                    entry.getValue());
            result.add(selectItem);
        }

        return result;
    }

    public void deleteFeature(AccessibilityFeature feature) {
        LOGGER.info("Deleting feature: " + feature.getId());
        deleteFeature(getSelectedElement().getId(), feature.getId());
    }

    public AccessibilityElement getSelectedElement() {
        return selectedElementIndex >= 0 ? accessibilityElements
                .get(selectedElementIndex) : null;
    }

    public void setSelectedElement(AccessibilityElement selectedElement) {
        LOGGER.warning("setSelectedElement: not supported");
    }

    public Map<String, Integer> getFeaturesForTypeMap() {
        return featuresForTypeMap;
    }

    public Integer getSelectedFeatureType() {
        return selectedFeatureType;
    }

    public void setSelectedFeatureType(Integer selectedFeatureType) {
        this.selectedFeatureType = selectedFeatureType;
    }

    /**
     * Executes when user selected feature type
     * 
     * @param evt
     */
    public void featureTypeSelected(AjaxBehaviorEvent evt) {
        resetFeature(false);
        populateFeaturesForTypeMap();
    }

    public void featureSelected(AjaxBehaviorEvent evt) {
        if (AccessibilityFeature.F_TEXT_TO_SPEECH == selectedFeature
                && StringUtils.isNotBlank(selectedElementId)) {
            AccessibilityElement element = findElement(selectedElementId);
            featureInfo = getElementText(element);
        } else {
            featureInfo = "";
        }
    }

    private void populateFeaturesForTypeMap() {
        featuresForTypeMap = new TreeMap<String, Integer>();
        if (selectedFeatureType == null) {
            return;
        }
        for (int feature : getAccessibilityServices().getFeaturesForType(
                selectedFeatureType)) {
            featuresForTypeMap.put(
                    AccessibilityFeature.getFeatureAsString(feature), feature);
            if (selectedFeature < 0) {
                selectedFeature = feature;
            }
        }
    }

    /**
     * Called from JSF when user clicked cancel on the feature editing window
     * 
     * @param resetFeatureType
     */
    public void resetFeature(boolean resetFeatureType) {
        if (resetFeatureType) {
            selectedFeatureId = -1;
            selectedFeatureType = null;
            if (!featuresForTypeMap.isEmpty()) {
                featuresForTypeMap.clear();
            }
        }
        selectedFeature = -1;
        selectedLanguage = null;
        featureInfo = "";
    }

    public Map<String, String> getLanguagesMap() {
        return miscServices.getGlossaryLanguageMap();
    }

    public boolean isTranslation() {
        return selectedFeatureType != null
                && selectedFeatureType == AccessibilityFeature.T_KEYWORD_TRANSLATION;
    }

    public boolean isFeatureInfoModifiable() {
        AccessibilityElement element = findElement(selectedFeatureId);
        return element != null
                && AccessibilityElement.CLT_OBJECT != element
                        .getContentLinkType()
                && AccessibilityFeature.F_TEXT_TO_SPEECH == selectedFeatureType;
    }

    public int getSelectedFeature() {
        return selectedFeature;
    }

    public void setSelectedFeature(int selectedFeature) {
        this.selectedFeature = selectedFeature;
    }

    public String getSelectedLanguage() {
        return selectedLanguage;
    }

    public void setSelectedLanguage(String selectedLanguage) {
        this.selectedLanguage = selectedLanguage;
    }

    public String getFeatureInfo() {
        return featureInfo;
    }

    public void setFeatureInfo(String featureInfo) {
        this.featureInfo = featureInfo;
    }

    public void saveFeature() throws ManagerException {
        LOGGER.info("Persisting feature " + selectedFeatureId);
        int selectedElementIdLocal = getSelectedElement().getId();
        AccessibilityFeature feature = findFeature(selectedElementIdLocal,
                selectedFeatureId);
        if (feature == null) {
            feature = new AccessibilityFeature();
            feature.setId(getMinFeatureId(selectedElementIdLocal) - 1);
            addFeature(selectedElementIdLocal, feature);
        }
        feature.setType(selectedFeatureType);
        feature.setFeature(selectedFeature);
        feature.setLangCode(selectedLanguage);
        feature.setInfo(featureInfo);
        resetFeature(true);
        setModifyingFeature(false);
    }

    private int getMinFeatureId(int elementId) {
        int result = -1;
        List<AccessibilityFeature> featureList = featuresMap.get(elementId);
        if (featureList != null) {
            for (AccessibilityFeature feature : featureList) {
                if (feature.getId() < result) {
                    result = feature.getId();
                }
            }
        }
        return result;
    }

    public int getSelectedFeatureId() {
        return selectedFeatureId;
    }

    public void setSelectedFeatureId(int selectedFeatureId) {
        this.selectedFeatureId = selectedFeatureId;
    }

    public AccessibilityFeature findFeature(int elementId, int featureId) {
        List<AccessibilityFeature> featureList = featuresMap.get(elementId);
        if (featureList != null) {
            for (AccessibilityFeature feature : featureList) {
                if (feature.getId() == featureId) {
                    return feature;
                }
            }
        }
        return null;
    }

    public void deleteFeature(int elementId, int featureId) {
        List<AccessibilityFeature> featureList = featuresMap.get(elementId);
        if (featureList != null) {
            for (int i = 0; i < featureList.size(); i++) {
                AccessibilityFeature feature = featureList.get(i);
                if (feature.getId() == featureId) {
                    featureList.remove(i);
                }
            }
        }
    }

    public void addFeature(int elementId, AccessibilityFeature feature) {
        List<AccessibilityFeature> featureList = featuresMap.get(elementId);
        if (featureList != null) {
            featureList.add(feature);
        }
    }

    public List<AccessibilityFeature> getFeatureListForSelectedElement() {
        AccessibilityElement element = getSelectedElement();
        List<AccessibilityFeature> features = element != null ? featuresMap
                .get(element.getId()) : null;
        if (CollectionUtils.isNotEmpty(features)) {
            for (AccessibilityFeature feature : features) {
                feature.setDesc(getFeatureType(feature));
            }
        }
        return features;
    }

    public boolean isModifyingFeature() {
        return isModifyingFeature;
    }

    public void setModifyingFeature(boolean isModifyingFeature) {
        this.isModifyingFeature = isModifyingFeature;
    }

    /**
     * Called from JSF when user clicked 'Add New Feature' link
     */
    public void addNewFeature() {
        LOGGER.info("addNewFeature() called");
        setModifyingFeature(true);
        resetFeature(true);
    }

    /**
     * Called from JSF when user clicked 'Modify' icon for the feature
     * 
     * @param feature
     */
    public void modifyFeature(AccessibilityFeature feature) {
        LOGGER.info("Modifying " + feature.getId());
        selectedFeatureId = feature.getId();
        selectedFeatureType = feature.getType();
        selectedFeature = feature.getFeature();
        selectedLanguage = feature.getLangCode();
        featureInfo = feature.getUnescapedInfo();
        populateFeaturesForTypeMap();
        setModifyingFeature(true);
    }

    public void cancelEditingFeature() {
        setModifyingFeature(false);
        resetValues("mainForm:afTab:featurePanelGroup");
    }

    public List<SelectItem> getInclusionOrderTypes() {
        List<SelectItem> result = new ArrayList<SelectItem>();
        SelectItem si = new SelectItem(null, "Select Type...");
        si.setNoSelectionOption(true);
        result.add(si);
        for (int i = 1; i < InclusionOrder.TYPES.length; i++) {
            String label = InclusionOrder.TYPES[i];
            List<AccessibilityElement> aeList = inclusionOrderElementsMap
                    .get(i);
            if (aeList != null && !aeList.isEmpty()) {
                label = "* " + label;
            }
            SelectItem selectItem = new SelectItem(i, label);
            result.add(selectItem);
        }
        return result;
    }

    public Integer getSelectedInclusionOrderType() {
        return selectedInclusionOrderType;
    }

    public boolean isInclusionOrderTypeSelected() {
        return selectedInclusionOrderType != null
                && selectedInclusionOrderType > 0;
    }

    public void setSelectedInclusionOrderType(Integer selectedInclusionOrderType) {
        if (selectedInclusionOrderType != this.selectedInclusionOrderType) {
            // clear selected tags when inclusion order type changed
            inclusionOrderTagsSelected = new ArrayList<Integer>();
        }
        this.selectedInclusionOrderType = selectedInclusionOrderType;
    }

    public List<AccessibilityElement> getInclusionOrderElements() {
        List<AccessibilityElement> result = selectedInclusionOrderType != null ? inclusionOrderElementsMap
                .get(selectedInclusionOrderType) : null;
        if (result == null && selectedInclusionOrderType != null
                && selectedInclusionOrderType > 0) {
            result = new ArrayList<AccessibilityElement>();
            inclusionOrderElementsMap.put(selectedInclusionOrderType, result);
        }
        return result;
    }

    public void addTagToInclusionOrder() {
        LOGGER.info("addTagToInclusionOrder: " + selectedElementId);
        List<AccessibilityElement> inclusionOrderElements = getInclusionOrderElements();
        // No order type selected (should never happen)
        if (inclusionOrderElements == null) {
            return;
        }
        for (AccessibilityElement ae : inclusionOrderElements) {
            // Tag already in inclusion order
            if (ae.getName().equals(selectedElementId)) {
                return;
            }
        }
        int index = findElementIndex(selectedElementId);
        if (index >= 0) {
            AccessibilityElement ae = accessibilityElements.get(index);
            inclusionOrderElements.add(ae);
        }
    }

    public void addAllTagsToInclusionOrder() {
        LOGGER.info("addAllTagsToInclusionOrder");
        List<AccessibilityElement> inclusionOrderElements = getInclusionOrderElements();
        // No order type selected (should never happen)
        if (inclusionOrderElements == null) {
            return;
        }
        inclusionOrderElements.clear();
        inclusionOrderElements.addAll(accessibilityElements);
    }

    public void deleteTagFromInclusionOrder() {
        LOGGER.info("deleteTagFromInclusionOrder: "
                + getInclusionOrderTagsSelected());
        for (Iterator<AccessibilityElement> ii = getInclusionOrderElements()
                .iterator(); ii.hasNext();) {
            AccessibilityElement ae = ii.next();
            if (getInclusionOrderTagsSelected().contains(ae.getId())) {
                ii.remove();
            }
        }
    }

    public void moveInclusionOrderTagsUp() {
        List<AccessibilityElement> inclusionOrderElements = getInclusionOrderElements();
        for (int i = 1; i < inclusionOrderElements.size(); i++) {
            if (getInclusionOrderTagsSelected().contains(
                    inclusionOrderElements.get(i).getId())) {
                Collections.swap(inclusionOrderElements, i, i - 1);
            }
        }
    }

    public void moveInclusionOrderTagsDown() {
        List<AccessibilityElement> inclusionOrderElements = getInclusionOrderElements();
        for (int i = inclusionOrderElements.size() - 2; i >= 0; i--) {
            if (getInclusionOrderTagsSelected().contains(
                    inclusionOrderElements.get(i).getId())) {
                Collections.swap(inclusionOrderElements, i, i + 1);
            }
        }
    }

    public List<SelectItem> getInclusionOrderTagItems() {
        List<SelectItem> result = new ArrayList<SelectItem>();
        for (AccessibilityElement ae : getInclusionOrderElements()) {
            result.add(new SelectItem(
                    ae.getId(),
                    ae.getName()
                            + " - "
                            + (ae.getContentLinkType() == AccessibilityElement.CLT_OBJECT ? "Object"
                                    : "Text")));
        }
        return result;
    }

    public List<Integer> getInclusionOrderTagsSelected() {
        LOGGER.info("inclusion order tags selected: "
                + inclusionOrderTagsSelected);
        return inclusionOrderTagsSelected;
    }

    public void setInclusionOrderTagsSelected(
            List<Integer> inclusionOrderTagsSelected) {
        this.inclusionOrderTagsSelected = inclusionOrderTagsSelected;
    }

    public List<InclusionOrder> getInclusionOrderList() {
        List<InclusionOrder> result = new ArrayList<InclusionOrder>();
        for (Map.Entry<Integer, List<AccessibilityElement>> entry : inclusionOrderElementsMap
                .entrySet()) {
            if (entry.getValue().isEmpty()) {
                continue;
            }
            InclusionOrder io = new InclusionOrder();
            if (item != null) {
                io.setItemId(item.getId());
            } else if (passage != null) {
                io.setPassageId(passage.getId());
            }
            io.setType(entry.getKey());
            io.setElementList(new ArrayList<InclusionOrderElement>());
            for (int i = 0; i < entry.getValue().size(); i++) {
                AccessibilityElement ae = entry.getValue().get(i);
                InclusionOrderElement ioe = new InclusionOrderElement();
                ioe.setAccessibilityElementId(ae.getId());
                ioe.setSequence(i + 1);
                ioe.setInclusionOrder(io);
                io.getElementList().add(ioe);
            }
            result.add(io);
        }
        return result;
    }

    public void doSaveInclusionOrder() {
        List<InclusionOrder> inclusionOrdersLocal = getInclusionOrderList();
        getAccessibilityServices().replaceInclusionOrders(itemOrPassageId,
                inclusionOrdersLocal);
    }

    public String getMediaURL() {
        return item != null ? ServerConfiguration
                .getProperty(ServerConfiguration.HTTP_SERVER_CGI_BIN_URL)
                + "/mediaView.pl?itemBankId="
                + item.getItemBankId()
                + "&itemName=" + item.getExternalId() + "&imageId=" : "";
    }

    private AccessibilityServices getAccessibilityServices() {
        return item != null ? accessibilityItemServices
                : accessibilityPassageServices;
    }

    public Passage getPassage() {
        return passage;
    }

    public String getStylesheetUrl() {
        return stylesheetUrl;
    }

    public void setStylesheetUrl(String stylesheetUrl) {
        this.stylesheetUrl = stylesheetUrl;
    }

    private String getElementText(AccessibilityElement element) {
        String text = "";
        if (StringUtils.isNotBlank(itemOrPassageHTML)
                && element != null
                && (AccessibilityElement.CLT_TEXT == element
                        .getContentLinkType() || AccessibilityElement.CLT_OBJECT == element
                        .getContentLinkType())) {

            if (element.getTextLinkType() == AccessibilityElement.TLT_FULL_STRING) {
                text = HTMLUtil.getTextOfElement(itemOrPassageHTML,
                        element.getContentName());
            } else if (element.getTextLinkType() == AccessibilityElement.TLT_CHAR_SEQUENCE) {
                text = HTMLUtil.getCharacterSequenceOfElement(
                        itemOrPassageHTML, element.getContentName(),
                        element.getTextLinkStartChar(),
                        element.getTextLinkStopChar());
            } else if (element.getTextLinkType() == AccessibilityElement.TLT_WORD) {
                text = HTMLUtil.getWordOfElement(itemOrPassageHTML,
                        element.getContentName(), element.getTextLinkWord());
            }
            if (element.getContentLinkType() == AccessibilityElement.CLT_OBJECT
                    && element.getContentType() == AccessibilityElement.CT_QTI) {
                text = HTMLUtil.getTextOfElement(itemOrPassageHTML,
                        element.getContentName());
            }
        }
        return text;
    }

    public String getFeatureType(AccessibilityFeature feature) {
        if (feature != null
                && feature.getType() == AccessibilityFeature.T_KEYWORD_TRANSLATION) {
            for (Entry<String, String> entry : getLanguagesMap().entrySet()) {
                if (feature.getLangCode().equals(entry.getValue())) {
                    return feature.getTypeAsString() + " - " + entry.getKey();
                }
            }
        } else {
            return feature.getTypeAndFeatureAsString();
        }
        return "";
    }

}
