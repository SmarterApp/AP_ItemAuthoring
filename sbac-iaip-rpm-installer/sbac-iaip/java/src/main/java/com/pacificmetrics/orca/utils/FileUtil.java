package com.pacificmetrics.orca.utils;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class FileUtil {

    private static final Log LOGGER = LogFactory.getLog(FileUtil.class);

    private FileUtil() {
    }

    public static String getFileExtension(String fileName) {
        if (StringUtils.isNotEmpty(fileName) && fileName.contains(".")
                && fileName.split("\\.").length >= 2) {
            return fileName.split("\\.")[1];
        }
        return null;
    }

    public static boolean copyFile(String fromPath, String toPath) {
        File sourceFile = new File(fromPath);
        File destinationFile = new File(toPath);
        try {
            FileUtils.copyFile(sourceFile, destinationFile);
            return true;
        } catch (IOException e) {
            LOGGER.error("Unable to copy file from " + fromPath + " to "
                    + toPath, e);
            return false;
        }
    }

    public static String readToString(String filePath) {
        try {
            return FileUtils.readFileToString(new File(filePath));
        } catch (IOException e) {
            LOGGER.error("Unable to read file content from " + filePath, e);
            return "";
        }
    }

    public static String readToString(InputStream inputStream,
            boolean closeStream) {
        BufferedReader br = null;
        StringBuilder sb = new StringBuilder();

        String line;
        try {

            br = new BufferedReader(new InputStreamReader(inputStream));
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }

        } catch (IOException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        } finally {
            if (br != null && closeStream) {
                try {
                    br.close();
                } catch (IOException e) {
                    LOGGER.error("Error : " + e.getMessage(), e);
                }
            }
        }

        return sb.toString();
    }

    public static boolean writeToFile(InputStream ins, String fileName,
            boolean closeStream) {
        try {
            FileOutputStream fos = new FileOutputStream(fileName);
            byte[] buffer = new byte[10];
            while (ins.read(buffer) != -1) {
                fos.write(buffer);

            }
            fos.flush();
            fos.close();
            return true;
        } catch (FileNotFoundException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
            return false;
        } catch (IOException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
            return false;
        } finally {
            if (ins != null && closeStream) {
                try {
                    ins.close();
                } catch (IOException e) {
                    LOGGER.error("Error : " + e.getMessage(), e);
                }
            }
        }
    }

    public static boolean writeToFile(String fileContent, String fileName,
            boolean closeStream) {

        try {
            File file = new File(fileName);
            createFile(file);
            FileUtils.write(file, fileContent);
            return true;
        } catch (IOException e) {
            LOGGER.error("Unable to write content to  file " + fileName, e);
            return false;
        }
    }

    public static void createDir(String directoryPath) {
        File file = new File(directoryPath);
        if (!file.exists()) {
            file.mkdir();
        }
    }

    public static void createDir(File directory) {
        if (directory != null && !directory.exists()) {
            directory.mkdir();
        }
    }

    public static boolean createFile(String filePath) {
        File file = new File(filePath);
        if (!file.exists()) {
            try {
                return file.createNewFile();
            } catch (IOException e) {
                LOGGER.error("Unable to create  file " + filePath, e);
                return false;
            }
        }
        return true;
    }

    public static boolean createFile(File file) {
        if (!file.exists()) {
            try {
                file.getParentFile().mkdirs();
                return file.createNewFile();
            } catch (IOException e) {
                LOGGER.error("Unable to create  file " + file, e);
                return false;
            }
        }
        return true;
    }

    public static void createParentDirs(File file) {
        throw new java.lang.UnsupportedOperationException();
    }

    public static boolean pathExitsts(String path) {
        File file = new File(path);
        return file.exists() ? true : false;
    }

    public static String readXMLFileWithoutDeclaration(InputStream inputStream) {
        BufferedReader br = null;
        StringBuilder sb = new StringBuilder();

        String line;
        try {

            br = new BufferedReader(new InputStreamReader(inputStream));
            while ((line = br.readLine()) != null) {
                if (!line.contains("?xml")) {
                    sb.append(line);
                }
            }
        } catch (IOException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        } finally {
            if (br != null) {
                try {
                    br.close();
                } catch (IOException e) {
                    LOGGER.error("Error : " + e.getMessage(), e);
                }
            }
        }
        return sb.toString();
    }

    public static String readXMLFileWithoutDeclaration(File file) {
        BufferedReader br = null;
        StringBuilder sb = new StringBuilder();

        String line;
        try {

            br = new BufferedReader(new InputStreamReader(new FileInputStream(
                    file)));
            while ((line = br.readLine()) != null) {
                if (!line.contains("?xml")) {
                    sb.append(line);
                }
            }
        } catch (IOException e) {
            LOGGER.error("Error : " + e.getMessage(), e);
        } finally {
            if (br != null) {
                try {
                    br.close();
                } catch (IOException e) {
                    LOGGER.error("Error : " + e.getMessage(), e);
                }
            }
        }
        return sb.toString();
    }

    public static final void delete(File f) throws IOException {
        if (f.isDirectory()) {
            for (File c : f.listFiles()) {
                delete(c);
            }
        }
        if (!f.delete()) {
            throw new FileNotFoundException("Failed to delete file: "
                    + f.getAbsolutePath());
        }
    }

    public static final void zip(File directory, File base,
            ZipOutputStream zos, byte[] buffer) throws IOException {
        int read = 0;
        for (File file : directory.listFiles()) {
            if (file.isDirectory()) {
                zip(file, base, zos, buffer);
            } else {
                FileInputStream in = new FileInputStream(file);
                try {
                    ZipEntry entry = new ZipEntry(file.getPath().substring(
                            base.getPath().length() + 1));
                    zos.putNextEntry(entry);
                    while ((read = in.read(buffer)) > -1) {
                        zos.write(buffer, 0, read);
                    }
                } finally {
                    in.close();
                }
            }
        }
    }

    public static final void zip(File directory, File zip) throws IOException {
        byte[] buffer = new byte[8192];
        FileOutputStream fos = new FileOutputStream(zip);
        ZipOutputStream zos = new ZipOutputStream(fos);
        try {
            zip(directory, directory, zos, buffer);
        } finally {
            zos.close();
            fos.close();
        }
    }
    
    public static String modifiedSrcPath(String srcPath) {    
		String searchItem = "src=\"";
		for (int i = 0; i < srcPath.length(); i++) {
			int firstOccurrence = srcPath.indexOf(searchItem, i);
			if (firstOccurrence >= 0) {
				int positionOfFirstOccurrence = srcPath.indexOf("\"", firstOccurrence + searchItem.length() + 1);
				String srcValue = srcPath.substring(firstOccurrence + searchItem.length(), positionOfFirstOccurrence);
				String modifiedValue = srcValue.substring(srcValue.lastIndexOf(File.separator) + 1);
				srcPath = srcPath.replace(srcValue, modifiedValue);
				positionOfFirstOccurrence -= (srcValue.length() - modifiedValue.length());				
				i = positionOfFirstOccurrence;
			} else {
				break;
			}			
		}		
		return srcPath;
    }
}
