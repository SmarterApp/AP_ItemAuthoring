package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.io.Serializable;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import javax.faces.component.EditableValueHolder;
import javax.faces.component.UIComponent;
import javax.faces.component.UIViewRoot;
import javax.faces.context.FacesContext;
import javax.faces.context.PartialViewContext;
import javax.inject.Inject;

import org.apache.myfaces.extensions.cdi.jsf.api.Jsf;
import org.apache.myfaces.extensions.cdi.message.api.Message;
import org.apache.myfaces.extensions.cdi.message.api.MessageContext;

import com.pacificmetrics.common.MultipleResults;
import com.pacificmetrics.common.OperationResult;
import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.common.Status;

public class AbstractManager implements Serializable {

    private static final Logger LOGGER = Logger.getLogger(AbstractManager.class
            .getName());

    private static final long serialVersionUID = 1L;

    @Inject
    @Jsf
    protected MessageContext messageContext;

    protected String dialogText;
    protected Map<String, String> parametersMap = Collections.emptyMap();

    public AbstractManager() {
        initializeParameters();
    }

    protected void initializeParameters() {
        FacesContext context = FacesContext.getCurrentInstance();
        if (context != null) {
            initializeParameters(new HashMap<String, String>(context
                    .getExternalContext().getRequestParameterMap()));
        } else {
            LOGGER.warning("Faces Context is NULL");
        }
    }

    public void initializeParameters(Map<String, String> parametersMap) {
        this.parametersMap = parametersMap;
        LOGGER.info("Parameters initialized: " + parametersMap);
    }

    protected void redirect(String url) {
        try {
            FacesContext.getCurrentInstance().getExternalContext()
                    .redirect(url);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    protected void unexpectedError() {
        redirect("errors/error.html");
    }

    protected void redirectWithError(String errorText) {
        redirectWithError(errorText, null);
    }

    protected void redirectWithError(String errorText, String errorDetails) {
        ErrorManager errorManager = findBean("error");
        errorManager.setErrorText(errorText);
        errorManager.setErrorDetails(errorDetails);
        redirect("errors/Error.jsf");
    }

    protected void redirectWithErrorMessage(String message) {
        redirectWithError(this.messageContext.message()
                .text("{" + message + "}").toText());
    }

    protected String getParameter(String name) {
        return this.parametersMap.get(name);
    }

    protected String getParameter(String name, String defaultValue) {
        String result = parametersMap.get(name);
        return result != null ? result : defaultValue;
    }

    protected int getParameterAsInt(String name, int defaultValue) {
        String result = parametersMap.get(name);
        try {
            return result != null ? Integer.parseInt(result) : defaultValue;
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    protected void errorMsg(String msg) {
        Message message = this.messageContext.message().text(msg).create();
        this.messageContext.addMessage(message);
    }

    protected void error(Status status) {
        error(status.toString());
    }

    protected void error(String msgKey) {
        Message message = this.messageContext.message()
                .text("{" + msgKey + "}").create();
        this.messageContext.addMessage(message);
    }

    protected void error(Status status, Object data) {
        if (data != null) {
            error(status.toString(), data.toString());
        } else {
            error(status);
        }
    }

    protected void error(ServiceException e) {
        error(e.getStatus(), e.getData());
    }

    protected void error(String msgKey, String text) {
        String msgText = this.messageContext.message().text("{" + msgKey + "}")
                .toText();
        Message message = this.messageContext.message()
                .text(msgText + " : " + text).create();
        this.messageContext.addMessage(message);
    }

    protected void error(Status status1, Status status2) {
        String text1 = this.messageContext.message()
                .text("{" + status1.toString() + "}").toText();
        String text2 = this.messageContext.message()
                .text("{" + status2.toString() + "}").toText();
        Message message = this.messageContext.message()
                .text(text1 + " : " + text2).create();
        this.messageContext.addMessage(message);
    }

    public String getDialogText() {
        return this.dialogText;
    }

    public void setDialogText(String dialogText) {
        this.dialogText = dialogText;
    }

    public boolean hasMessages() {
        return !FacesContext.getCurrentInstance().getMessageList().isEmpty();
    }

    @SuppressWarnings("unchecked")
    protected <T> void handleOperationResult(OperationResult res) {
        if (res.isSuccess()) {
            int count = 0;
            if (res instanceof MultipleResults) {
                for (Map.Entry<T, Status> entry : ((MultipleResults<T>) res)
                        .getStatusMap().entrySet()) {
                    if (entry.getValue() == Status.OK) {
                        count++;
                    } else {
                        error(entry.getValue(), entry.getKey());
                    }
                }
            }
            this.dialogText = count > 0 ? "Successfully processed: " + count
                    : "";
        } else {
            error(Status.OPERATION_FAILED, res.getStatus());
        }
    }

    @SuppressWarnings("unchecked")
    public static <T> T findBean(String beanName) {
        return (T) FacesContext
                .getCurrentInstance()
                .getELContext()
                .getELResolver()
                .getValue(FacesContext.getCurrentInstance().getELContext(),
                        null, beanName);
    }

    protected void resetValues(FacesContext fc) {
        PartialViewContext partialViewContext = fc.getPartialViewContext();
        Collection<String> renderIds = partialViewContext.getRenderIds();
        UIComponent input;
        UIViewRoot viewRoot = fc.getViewRoot();
        for (String renderId : renderIds) {
            input = viewRoot.findComponent(renderId);
            if (input.isRendered() && input instanceof EditableValueHolder) {
                EditableValueHolder editableValueHolder = (EditableValueHolder) input;
                editableValueHolder.setSubmittedValue(null);
                editableValueHolder.setValue(null);
                editableValueHolder.setValid(true);
                editableValueHolder.setLocalValueSet(false);
            }
        }
    }

    protected void resetValue(UIComponent comp) {
        if (comp.isRendered() && comp instanceof EditableValueHolder) {
            EditableValueHolder editableValueHolder = (EditableValueHolder) comp;
            editableValueHolder.setSubmittedValue(null);
            editableValueHolder.setValue(null);
            editableValueHolder.setValid(true);
            editableValueHolder.setLocalValueSet(false);
        }
        if (comp.getChildCount() > 0) {
            for (UIComponent child : comp.getChildren()) {
                resetValue(child);
            }
        }
    }

    protected void resetValues(String componentId) {
        FacesContext fc = FacesContext.getCurrentInstance();
        UIComponent comp = fc.getViewRoot().findComponent(componentId);
        resetValue(comp);
    }

}
