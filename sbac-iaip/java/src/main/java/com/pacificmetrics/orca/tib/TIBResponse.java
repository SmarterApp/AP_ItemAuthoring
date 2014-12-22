package com.pacificmetrics.orca.tib;

import java.util.List;

import org.apache.commons.collections.CollectionUtils;

public class TIBResponse {
    private String importStatus;

    private String fileImportStatus;

    private List<String> messages;

    public String getImportStatus() {
        return importStatus;
    }

    public void setImportStatus(String importStatus) {
        this.importStatus = importStatus;
    }

    public String getFileImportStatus() {
        return fileImportStatus;
    }

    public void setFileImportStatus(String fileImportStatus) {
        this.fileImportStatus = fileImportStatus;
    }

    public List<String> getMessages() {
        return messages;
    }

    public void setMessages(List<String> messages) {
        this.messages = messages;
    }

    public String getMessage() {
        StringBuilder statusBuffer = new StringBuilder();
        if (CollectionUtils.isNotEmpty(messages)) {
            for (String message : messages) {
                statusBuffer.append("\n").append(message);
            }
        }
        return statusBuffer.toString();
    }
}
