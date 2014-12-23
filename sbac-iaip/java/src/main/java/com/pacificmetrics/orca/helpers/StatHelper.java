package com.pacificmetrics.orca.helpers;

import java.io.InputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.myfaces.custom.fileupload.UploadedFile;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import com.pacificmetrics.common.ApplicationException;
import com.pacificmetrics.orca.StatServicesStatus;
import com.pacificmetrics.orca.ejb.ItemServices;

public class StatHelper {

    private static final Log LOGGER = LogFactory.getLog(StatHelper.class);

    ItemServices itemservice;

    public ImportFileData getImportFileData(byte[] bytes,
            Map<String, String> statKeyMap) throws ApplicationException {
        ImportFileData result = new ImportFileData();
        String[] lines = new String(bytes).split("(\\r\\n)|\\r|\\n");

        if (lines.length < 2) {
            throw new ApplicationException(
                    StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        result.headers = new LinkedList<String>(Arrays.asList(lines[0]
                .toUpperCase().split(", *")));
        if (result.headers.size() < 2
                || ((!result.headers.contains("ITEM_ID") && !result.headers
                        .contains("ID")) || !result.headers
                        .contains("ADMINISTRATION"))) {
            throw new ApplicationException(
                    StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
        }
        if (statKeyMap.size() != result.headers.size() - 2) {
            throw new ApplicationException(
                    StatServicesStatus.IMPORT_UNKNOWN_FIELD);
        }

        int idIndex = result.headers.indexOf("ITEM_ID");
        int itemIdIndex = result.headers.indexOf("ID");
        int adminIndex = result.headers.indexOf("ADMINISTRATION");
        result.headers.remove(idIndex == -1 ? itemIdIndex : idIndex);
        result.headers.remove("ADMINISTRATION");
        result.headers.add(0, idIndex == -1 ? "ID" : "ITEM_ID");
        result.headers.add(1, "ADMINISTRATION");

        result.rows = new LinkedList<List<Object>>();
        for (int i = 1; i < lines.length; i++) {
            if (!lines[i].trim().isEmpty()) {
                if (!StringUtils.isAsciiPrintable(lines[i])) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }

                String[] values = lines[i].split(", *", -1);
                if (values.length != result.headers.size()) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                List<String> listValues = new LinkedList<String>(
                        Arrays.asList(values));

                List<String> removeList = new LinkedList<String>();
                removeList.add(listValues.get(idIndex == -1 ? itemIdIndex
                        : idIndex));
                removeList.add(listValues.get(adminIndex));
                listValues.removeAll(removeList);

                listValues.add(0, removeList.get(0));
                listValues.add(1, removeList.get(1));
                values = listValues.toArray(new String[0]);
                List<Object> rowValues = new ArrayList<Object>();
                rowValues.add(values[0]);
                rowValues.add(values[1]);
                for (int j = 2; j < values.length; j++) {

                    double d = 0;

                    boolean flag = true;
                    try {
                        d = Double.parseDouble(values[j]);
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage(), e);
                        if ("Numeric".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(j).toUpperCase()))) {
                            flag = true;
                            values[j] = null;
                        } else {
                            flag = false;
                        }
                    }

                    if (flag) {
                        if ("Numeric".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(j)))
                                || "character".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(j)))) {

                            if (values[j] == null) {
                                rowValues.add(null);
                            } else {
                                rowValues.add(values[j]);
                            }
                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }

                    } else {
                        if ("character".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(j)))) {
                            rowValues.add(values[j]);
                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }
                    }

                }
                result.rows.add(rowValues);
            }
        }
        return result;
    }

    public ImportFileData getExcelImportFileData(UploadedFile uploadedFile,
            Map<String, String> statKeyMap) throws ApplicationException {

        ImportFileData result = new ImportFileData();
        try {
            InputStream inputStream = uploadedFile.getInputStream();
            HSSFWorkbook workbook = new HSSFWorkbook(inputStream);
            HSSFSheet sheet = workbook.getSheetAt(0);
            result.headers = new LinkedList<String>();

            if (sheet.getLastRowNum() < 1) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }

            Row r = (Row) sheet.getRow(0);
            for (Cell c : r) {
                result.headers.add(c.getStringCellValue().trim().toUpperCase());
            }
            if (result.headers.size() < 2
                    || ((!result.headers.contains("ITEM_ID") && !result.headers
                            .contains("ID")) || !result.headers
                            .contains("ADMINISTRATION"))) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }
            if (r.getLastCellNum() != result.headers.size()) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }

            if (statKeyMap.size() != result.headers.size() - 2) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_UNKNOWN_FIELD);
            }

            int idIndex = result.headers.indexOf("ITEM_ID");
            int itemIdIndex = result.headers.indexOf("ID");
            int adminIndex = result.headers.indexOf("ADMINISTRATION");
            result.rows = new LinkedList<List<Object>>();

            for (int j = 1; j <= sheet.getLastRowNum(); j++) {
                Row rLocal = (Row) sheet.getRow(j);
                List<Object> rowValues = new LinkedList<Object>();

                if (rLocal.getLastCellNum() != result.headers.size()) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }

                int i = 0;
                for (Cell c : rLocal) {
                    String rowValue = null;

                    if (i == adminIndex
                            || i == (idIndex == -1 ? itemIdIndex : idIndex)) {
                        rowValues.add(c.getStringCellValue().trim());
                        i++;
                        continue;
                    }

                    switch (c.getCellType()) {

                    case Cell.CELL_TYPE_NUMERIC:
                        Number number = c.getNumericCellValue();
                        rowValue = number.toString();
                        break;
                    case Cell.CELL_TYPE_STRING:
                        rowValue = c.getStringCellValue().trim();
                        break;
                    default:
                        break;
                    }

                    double d = 0;
                    boolean flag = true;
                    try {
                        d = Double.parseDouble(rowValue);
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage(), e);
                        if ("float".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))
                                || "Numeric".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(i)
                                                .toUpperCase()))) {
                            flag = true;
                        } else {
                            flag = false;
                        }
                    }

                    if (flag) {
                        if ("Numeric".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))
                                || "character".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(i)
                                                .toUpperCase()))) {

                            if ("Numeric".equalsIgnoreCase(statKeyMap
                                    .get(result.headers.get(i).toUpperCase()))
                                    && rowValue != null) {
                                String[] rowValuesLocal = rowValue.split("\\.",
                                        2);
                                if ("0".equals(rowValuesLocal[1])) {
                                    rowValues.add(rowValuesLocal[0]);
                                } else {
                                    rowValues.add(rowValue);
                                }

                            } else {
                                rowValues.add(rowValue);
                            }

                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }

                    } else {
                        if ("character".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))) {
                            if (rowValue == null) {
                                rowValues.add(null);
                            } else {
                                rowValues.add(rowValue.trim());
                            }
                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }
                    }

                    i++;
                }
                List<Object> removeList = new LinkedList<Object>();
                removeList.add(rowValues.get(idIndex == -1 ? itemIdIndex
                        : idIndex));
                removeList.add(rowValues.get(adminIndex));
                rowValues.removeAll(removeList);
                rowValues.add(0, removeList.get(0));
                rowValues.add(1, removeList.get(1));
                result.rows.add(rowValues);

            }
        } catch (ApplicationException ae) {
            throw ae;
        } catch (Exception e) {
            e.getStackTrace();
            LOGGER.error(e.getMessage(), e);
        }
        int idIndex = result.headers.indexOf("ITEM_ID");
        int itemIdIndex = result.headers.indexOf("ID");

        result.headers.remove(idIndex == -1 ? itemIdIndex : idIndex);
        result.headers.remove("ADMINISTRATION");
        result.headers.add(0, idIndex == -1 ? "ID" : "ITEM_ID");
        result.headers.add(1, "ADMINISTRATION");
        return result;

    }

    public ImportFileData getNewFormatExcelImportFileData(
            UploadedFile uploadedFile, Map<String, String> statKeyMap)
            throws ApplicationException {

        ImportFileData result = new ImportFileData();
        try {
            InputStream inputStream = uploadedFile.getInputStream();
            XSSFWorkbook workbook = new XSSFWorkbook(inputStream);
            XSSFSheet sheet = workbook.getSheetAt(0);
            result.headers = new ArrayList<String>();

            if (sheet.getLastRowNum() < 1) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }

            Row r = sheet.getRow(0);
            for (Cell c : r) {
                result.headers.add(c.getStringCellValue().trim().toUpperCase());
            }
            if (result.headers.size() < 2
                    || ((!result.headers.contains("ITEM_ID") && !result.headers
                            .contains("ID")) || !result.headers
                            .contains("ADMINISTRATION"))) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }
            if (r.getLastCellNum() != result.headers.size()) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
            }

            if (statKeyMap.size() != result.headers.size() - 2) {
                throw new ApplicationException(
                        StatServicesStatus.IMPORT_UNKNOWN_FIELD);
            }
            int idIndex = result.headers.indexOf("ITEM_ID");
            int itemIdIndex = result.headers.indexOf("ID");
            int adminIndex = result.headers.indexOf("ADMINISTRATION");
            result.rows = new ArrayList<List<Object>>();

            for (int j = 1; j <= sheet.getLastRowNum(); j++) {
                Row rLocal = sheet.getRow(j);
                List<Object> rowValues = new ArrayList<Object>();
                if (rLocal.getLastCellNum() != result.headers.size()) {
                    throw new ApplicationException(
                            StatServicesStatus.IMPORT_BAD_FILE_FORMAT);
                }
                int i = 0;
                for (Cell c : rLocal) {
                    String rowValue = null;

                    if (i == adminIndex
                            || i == (idIndex == -1 ? itemIdIndex : idIndex)) {
                        rowValues.add(c.getStringCellValue().trim());
                        i++;
                        continue;
                    }
                    switch (c.getCellType()) {

                    case Cell.CELL_TYPE_NUMERIC:
                        Number number = c.getNumericCellValue();
                        rowValue = number.toString();
                        break;
                    case Cell.CELL_TYPE_STRING:
                        rowValue = c.getStringCellValue().trim();
                        break;
                    default:
                        break;

                    }

                    double d = 0;
                    boolean flag = true;
                    try {
                        d = Double.parseDouble(rowValue);
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage(), e);
                        if ("float".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))
                                || "Numeric".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(i)
                                                .toUpperCase()))) {
                            flag = true;
                        } else {
                            flag = false;
                        }
                    }

                    if (flag) {
                        if ("float".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))
                                || "Numeric".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(i)
                                                .toUpperCase()))
                                || "character".equalsIgnoreCase(statKeyMap
                                        .get(result.headers.get(i)
                                                .toUpperCase()))) {

                            if ("Numeric".equalsIgnoreCase(statKeyMap
                                    .get(result.headers.get(i).toUpperCase()))
                                    && rowValue != null) {
                                String[] rowValuesLocal = rowValue.split("\\.",
                                        2);
                                if ("0".equals(rowValuesLocal[1])) {
                                    rowValues.add(rowValuesLocal[0]);
                                } else {
                                    rowValues.add(rowValue);
                                }

                            } else {
                                rowValues.add(rowValue);
                            }
                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }

                    } else {
                        if ("character".equalsIgnoreCase(statKeyMap
                                .get(result.headers.get(i).toUpperCase()))) {
                            if (rowValue == null) {
                                rowValues.add(null);
                            } else {
                                rowValues.add(rowValue.trim());
                            }
                        } else {
                            throw new ApplicationException(
                                    StatServicesStatus.IMPORT_INVALID_NUMBER);
                        }
                    }

                    i++;
                }
                List<Object> removeList = new LinkedList<Object>();
                removeList.add(rowValues.get(idIndex == -1 ? itemIdIndex
                        : idIndex));
                removeList.add(rowValues.get(adminIndex));
                rowValues.removeAll(removeList);
                rowValues.add(0, removeList.get(0));
                rowValues.add(1, removeList.get(1));
                result.rows.add(rowValues);

            }
        } catch (ApplicationException ae) {
            throw ae;
        } catch (Exception e) {
            LOGGER.error(e.getMessage(), e);
            e.getStackTrace();
        }
        int idIndex = result.headers.indexOf("ITEM_ID");
        int itemIdIndex = result.headers.indexOf("ID");

        result.headers.remove(idIndex == -1 ? itemIdIndex : idIndex);
        result.headers.remove("ADMINISTRATION");
        result.headers.add(0, idIndex == -1 ? "ID" : "ITEM_ID");
        result.headers.add(1, "ADMINISTRATION");
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
