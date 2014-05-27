package com.pacificmetrics.orca.helpers;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.common.ApplicationException;
import com.pacificmetrics.orca.StatServicesStatus;

public class StatHelper {

    public ImportFileData getImportFileData(byte[] bytes) throws ApplicationException {
        ImportFileData result = new ImportFileData();
        String[] lines = new String(bytes).split("(\\r\\n)|\\r|\\n");
        if (lines.length < 2) {
            throw new ApplicationException(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        result.headers = new ArrayList<String>(Arrays.asList(lines[0].toUpperCase().split(", *")));
        if (result.headers.size() < 2 || !result.headers.get(0).trim().equalsIgnoreCase("ID")) {
            throw new ApplicationException(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        result.rows = new ArrayList<List<Object>>();
        for (int i = 1; i < lines.length; i++) {
            if (!lines[i].trim().isEmpty()) {
                if (!StringUtils.isAsciiPrintable(lines[i])) {
                    throw new ApplicationException(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                String[] values = lines[i].split(", *");
                if (values.length != result.headers.size()) {
                    throw new ApplicationException(StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                List<Object> rowValues = new ArrayList<Object>();
                rowValues.add(values[0]);
                for (int j = 1; j < values.length; j++) {
                    try {
                        double d = Double.parseDouble(values[j]);
                        rowValues.add(d);
                    } catch (NumberFormatException e) {
                        throw new ApplicationException(StatServicesStatus.IMPORT_INVALID_NUMBER);
                    }
                }
                result.rows.add(rowValues);
            }
        }
        return result;
    }
    
    static public class ImportFileData implements Serializable {
        
        private static final long serialVersionUID = 1L;

        private List<String> headers;
        private List<List<Object>> rows;
        
        public List<String> getHeaders() {
            return headers;
        }
        
        public List<List<Object>> getRows() {
            return rows;
        }
        
    }
    
}
