package com.pacificmetrics.orca.export.saaif;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.manifest.LomManifestType;
import com.pacificmetrics.saaif.manifest.Manifest;
import com.pacificmetrics.saaif.manifest.Manifest.Metadata;
import com.pacificmetrics.saaif.manifest.Manifest.Resources;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource.Dependency;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource.File;
import com.pacificmetrics.saaif.manifest.ObjectFactory;

public class SAAIFManifestWriter {

	private static final Log LOGGER = LogFactory
			.getLog(SAAIFManifestWriter.class);

	private static final String ITEM_FILE_PREFIX = "item-";
	private static final String STIMULUS_FILE_PREFIX = "stim-";
	private static final String XML_FILE_EXT = ".xml";
	private static final String METADATA_FILE_EXT = "_metadata.xml";
	private static final String METADATA_POSTFIX = "_metadata";

	private final ObjectFactory of = new ObjectFactory();
	private final Manifest m = this.of.createManifest();
	private final Resources resources = of.createManifestResources();
	private final Set<String> uniqueIds = new HashSet<String>();
	private final Set<String> resourceIdentifiers = new HashSet<String>();

	public void addItem(SAAIFItem item) {
		String itemIdentifier = ITEM_FILE_PREFIX + item.getBankKey() + "-"
				+ item.getId();

		item.setHref(getItemHref(item.getId(),
				ITEM_FILE_PREFIX + item.getBankKey() + "-" + item.getId()
						+ XML_FILE_EXT));
		item.setHrefBase(getItemHrefBase(item.getId()));
		item.setMetadataHref(getItemHref(item.getId(),
				ITEM_FILE_PREFIX + item.getBankKey() + "-" + item.getId()
						+ METADATA_FILE_EXT));
		item.setMetadataHrefBase(getItemHrefBase(item.getId()));

		// Add Item resource
		Resource itemResource = of.createManifestResourcesResource();

		// Add Item File
		File itemFile = of.createManifestResourcesResourceFile();
		itemFile.setHref(item.getHref());

		itemResource.setIdentifier(itemIdentifier);
		itemResource.setType(SAAIFPackageConstants.ITEM_TYPE);
		itemResource.setFile(itemFile);

		// Add Item metadata dependency
		Dependency metadataDependency = of
				.createManifestResourcesResourceDependency();
		metadataDependency.setIdentifierref(ITEM_FILE_PREFIX
				+ item.getBankKey() + "-" + item.getId() + METADATA_POSTFIX);
		itemResource.getDependency().add(metadataDependency);

		// Add Item metadata resource
		Resource metadataResource = of.createManifestResourcesResource();
		File metadataFile = of.createManifestResourcesResourceFile();

		metadataResource.setIdentifier(ITEM_FILE_PREFIX + item.getBankKey()
				+ "-" + item.getId() + METADATA_POSTFIX);
		metadataResource.setType(SAAIFPackageConstants.METADATA_TYPE);
		metadataFile.setHref(item.getMetadataHref());
		metadataResource.setFile(metadataFile);

		resources.getResource().add(itemResource);
		resources.getResource().add(metadataResource);

		// Add attachment dependencies
		if (item.getAttachments() != null
				&& CollectionUtils.isNotEmpty(item.getAttachments().entrySet())) {
			for (String fileName : item.getAttachments().keySet()) {
				String fileKey = fileName.replace(".", "_");
				String fileIdentifier = ITEM_FILE_PREFIX + item.getBankKey()
						+ "-" + item.getId() + "_" + fileKey;

				// Add Attachment dependency
				Dependency attachmentDependency = of
						.createManifestResourcesResourceDependency();
				attachmentDependency.setIdentifierref(fileIdentifier);

				itemResource.getDependency().add(attachmentDependency);

				// Add attachment resource
				Resource attachmentResource = of
						.createManifestResourcesResource();

				// Add attachment file
				File attachmentFile = of.createManifestResourcesResourceFile();
				attachmentFile.setHref(item.getHrefBase() + fileName);

				attachmentResource.setIdentifier(fileIdentifier);
				attachmentResource.setType(SAAIFPackageConstants.CONTENT_TYPE);
				attachmentResource.setFile(attachmentFile);

				resources.getResource().add(attachmentResource);
			}
		}
		
				// Add assets dependencies
				if (item.getAssets() != null && CollectionUtils.isNotEmpty(item.getAssets().entrySet())) {
					for (String fileName : item.getAssets().keySet()) {
						String fileKey = fileName.replace(".", "_");
						String fileIdentifier = fileKey;
						
						// Add Assets dependency
						Dependency attachmentDependency = of
								.createManifestResourcesResourceDependency();
						attachmentDependency
								.setIdentifierref(fileIdentifier);
		
						itemResource.getDependency().add(
								attachmentDependency);
						
						// Add Assets resource
						Resource assetsResource = of
								.createManifestResourcesResource();
						
						File assetsFile = of
								.createManifestResourcesResourceFile();
						assetsFile.setHref(item.getHrefBase()
								+ fileName);
		
						assetsResource.setIdentifier(fileIdentifier);
						assetsResource
								.setType(SAAIFPackageConstants.CONTENT_TYPE);
						assetsResource.setFile(assetsFile);
		
						resources.getResource().add(assetsResource);
					}
				}

		// TODO : Check for duplicate wordlist
		// Add wordlist dependency
		if (CollectionUtils.isNotEmpty(item.getWordlists())) {
			for (SAAIFItem wordlist : item.getWordlists()) {
				String dependencyIdentifier = ITEM_FILE_PREFIX
						+ wordlist.getBankKey() + "-" + wordlist.getId();

				if (!resourceIdentifiers.contains(dependencyIdentifier)) {
					resourceIdentifiers.add(dependencyIdentifier);

					wordlist.setHref(getItemHref(wordlist.getId(),
							ITEM_FILE_PREFIX + wordlist.getBankKey() + "-"
									+ wordlist.getId() + XML_FILE_EXT));
					wordlist.setHrefBase(getItemHrefBase(wordlist.getId()));
					wordlist.setMetadataHref(getItemHref(wordlist.getId(),
							ITEM_FILE_PREFIX + wordlist.getBankKey() + "-"
									+ wordlist.getId() + METADATA_FILE_EXT));
					wordlist.setMetadataHrefBase(getItemHrefBase(wordlist
							.getId()));

					// Add wordlist dependency
					Dependency wordlistDependency = of
							.createManifestResourcesResourceDependency();
					wordlistDependency.setIdentifierref(dependencyIdentifier);

					itemResource.getDependency().add(wordlistDependency);

					Resource wordlistResource = of
							.createManifestResourcesResource();
					File wordlistFile = of
							.createManifestResourcesResourceFile();

					wordlistFile.setHref(wordlist.getHref());
					wordlistResource.setType(SAAIFPackageConstants.ITEM_TYPE);
					wordlistResource.setIdentifier(dependencyIdentifier);
					wordlistResource.setFile(wordlistFile);

					// Add wordlist metadata file
					Resource wordlistMetadataResource = of
							.createManifestResourcesResource();

					File wordlisMetadatatFile = of
							.createManifestResourcesResourceFile();

					wordlisMetadatatFile.setHref(wordlist.getMetadataHref());

					wordlistMetadataResource
							.setType(SAAIFPackageConstants.METADATA_TYPE);
					wordlistMetadataResource.setIdentifier(dependencyIdentifier
							+ METADATA_POSTFIX);
					wordlistMetadataResource.setFile(wordlisMetadatatFile);

					// Add wordlist metadata dependency
					Dependency wordlistMetadataDependency = of
							.createManifestResourcesResourceDependency();
					wordlistMetadataDependency
							.setIdentifierref(dependencyIdentifier
									+ METADATA_POSTFIX);
					wordlistResource.getDependency().add(
							wordlistMetadataDependency);

					resources.getResource().add(wordlistResource);
					resources.getResource().add(wordlistMetadataResource);
				}
			}
		}

		// TODO : Check for duplicate tutorial
		// Add tutorial dependency
		if (CollectionUtils.isNotEmpty(item.getTutorials())) {
			for (SAAIFItem tutorial : item.getTutorials()) {

				String dependencyIdentifier = ITEM_FILE_PREFIX
						+ tutorial.getBankKey() + "-" + tutorial.getId();

				if (!resourceIdentifiers.contains(dependencyIdentifier)) {
					resourceIdentifiers.add(dependencyIdentifier);

					tutorial.setHref(getItemHref(tutorial.getId(),
							ITEM_FILE_PREFIX + tutorial.getBankKey() + "-"
									+ tutorial.getId() + XML_FILE_EXT));
					tutorial.setHrefBase(getItemHrefBase(tutorial.getId()));
					tutorial.setMetadataHref(getItemHref(tutorial.getId(),
							ITEM_FILE_PREFIX + tutorial.getBankKey() + "-"
									+ tutorial.getId() + METADATA_FILE_EXT));
					tutorial.setMetadataHrefBase(getItemHrefBase(tutorial
							.getId()));

					// Add tutorial dependency
					Dependency tutorialDependency = of
							.createManifestResourcesResourceDependency();
					tutorialDependency.setIdentifierref(dependencyIdentifier);
					itemResource.getDependency().add(tutorialDependency);

					// Add tutorial Resource
					Resource tutorialResource = of
							.createManifestResourcesResource();
					File tutorialFile = of
							.createManifestResourcesResourceFile();

					tutorialFile.setHref(tutorial.getHref());
					tutorialResource.setType(SAAIFPackageConstants.ITEM_TYPE);
					tutorialResource.setIdentifier(dependencyIdentifier);
					tutorialResource.setFile(tutorialFile);

					// Add tutorial Resource
					Resource tutorialMetadataResource = of
							.createManifestResourcesResource();
					File tutorialMetadatatFile = of
							.createManifestResourcesResourceFile();

					tutorialMetadatatFile.setHref(tutorial.getMetadataHref());
					tutorialMetadataResource
							.setType(SAAIFPackageConstants.METADATA_TYPE);
					tutorialMetadataResource.setIdentifier(dependencyIdentifier
							+ METADATA_POSTFIX);
					tutorialMetadataResource.setFile(tutorialMetadatatFile);

					// Add tutorial metadata dependency
					Dependency tutorialMetadataDependency = of
							.createManifestResourcesResourceDependency();
					tutorialMetadataDependency
							.setIdentifierref(dependencyIdentifier
									+ METADATA_POSTFIX);
					tutorialResource.getDependency().add(
							tutorialMetadataDependency);

					resources.getResource().add(tutorialResource);
					resources.getResource().add(tutorialMetadataResource);

					// Add attachment dependencies
					if (tutorial.getAttachments() != null
							&& CollectionUtils.isNotEmpty(tutorial
									.getAttachments().entrySet())) {
						for (String fileName : tutorial.getAttachments()
								.keySet()) {
							String fileKey = fileName.replace(".", "_");
							String fileIdentifier = ITEM_FILE_PREFIX
									+ tutorial.getBankKey() + "-"
									+ tutorial.getId() + "_" + fileKey;

							// Add Attachment dependency
							Dependency attachmentDependency = of
									.createManifestResourcesResourceDependency();
							attachmentDependency
									.setIdentifierref(fileIdentifier);

							tutorialResource.getDependency().add(
									attachmentDependency);

							// Add attachment resource
							Resource attachmentResource = of
									.createManifestResourcesResource();

							// Add attachment file
							File attachmentFile = of
									.createManifestResourcesResourceFile();
							attachmentFile.setHref(tutorial.getHrefBase()
									+ fileName);

							attachmentResource.setIdentifier(fileIdentifier);
							attachmentResource
									.setType(SAAIFPackageConstants.CONTENT_TYPE);
							attachmentResource.setFile(attachmentFile);

							resources.getResource().add(attachmentResource);
						}
					}
				}
			}
		}

		// TODO : Check for duplicate passage
		if (CollectionUtils.isNotEmpty(item.getPassages())) {
			for (SAAIFItem passage : item.getPassages()) {

				String dependencyIdentifier = STIMULUS_FILE_PREFIX
						+ passage.getBankKey() + "-" + passage.getId();
				if (!resourceIdentifiers.contains(dependencyIdentifier)) {
					resourceIdentifiers.add(dependencyIdentifier);

					passage.setHref(getStimuliHref(passage.getId(),
							STIMULUS_FILE_PREFIX + passage.getBankKey() + "-"
									+ passage.getId() + XML_FILE_EXT));
					passage.setHrefBase(getStimuliHrefBase(passage.getId()));
					passage.setMetadataHref(getStimuliHref(passage.getId(),
							STIMULUS_FILE_PREFIX + passage.getBankKey() + "-"
									+ passage.getId() + METADATA_FILE_EXT));
					passage.setMetadataHrefBase(getStimuliHrefBase(passage
							.getId()));

					// Add stimuli dependency
					Dependency passageDependency = of
							.createManifestResourcesResourceDependency();
					passageDependency.setIdentifierref(dependencyIdentifier);
					itemResource.getDependency().add(passageDependency);

					// Add stimuli Resource
					Resource passageResource = of
							.createManifestResourcesResource();
					File passageFile = of.createManifestResourcesResourceFile();

					passageFile.setHref(passage.getHref());
					passageResource
							.setType(SAAIFPackageConstants.STIMULUS_TYPE);
					passageResource.setIdentifier(dependencyIdentifier);
					passageResource.setFile(passageFile);

					// Add stimuli Resource
					Resource passageMetadataResource = of
							.createManifestResourcesResource();
					File passageMetadatatFile = of
							.createManifestResourcesResourceFile();

					passageMetadatatFile.setHref(passage.getMetadataHref());
					passageMetadataResource
							.setType(SAAIFPackageConstants.METADATA_TYPE);
					passageMetadataResource.setIdentifier(dependencyIdentifier
							+ METADATA_POSTFIX);
					passageMetadataResource.setFile(passageMetadatatFile);

					// Add stimuli metadata dependency
					Dependency passageddMetadataDependency = of
							.createManifestResourcesResourceDependency();
					passageddMetadataDependency
							.setIdentifierref(dependencyIdentifier
									+ METADATA_POSTFIX);
					passageResource.getDependency().add(
							passageddMetadataDependency);

					resources.getResource().add(passageResource);
					resources.getResource().add(passageMetadataResource);

					// Add attachment dependencies
					if (passage.getAttachments() != null && CollectionUtils.isNotEmpty(passage.getAttachments().entrySet())) {
						for (String fileName : passage.getAttachments()
								.keySet()) {
							String fileKey = fileName.replace(".", "_");
							String fileIdentifier = "Passage-"
									+ passage.getBankKey() + "-"
									+ passage.getId() + "_" + fileKey;

							// Add Attachment dependency
							Dependency attachmentDependency = of
									.createManifestResourcesResourceDependency();
							attachmentDependency
									.setIdentifierref(fileIdentifier);

							passageResource.getDependency().add(
									attachmentDependency);

							// Add attachment resource
							Resource attachmentResource = of
									.createManifestResourcesResource();

							// Add attachment file
							File attachmentFile = of
									.createManifestResourcesResourceFile();
							attachmentFile.setHref(passage.getHrefBase()
									+ fileName);

							attachmentResource.setIdentifier(fileIdentifier);
							attachmentResource
									.setType(SAAIFPackageConstants.CONTENT_TYPE);
							attachmentResource.setFile(attachmentFile);

							resources.getResource().add(attachmentResource);
						}
					}
					
					// Add Assets dependencies
					if (passage.getAssets() != null && CollectionUtils.isNotEmpty(passage.getAssets().entrySet())) {
						for (String fileName : passage.getAssets().keySet()) {
							String fileKey = fileName.replace(".", "_");
							String fileIdentifier = fileKey;
							
							// Add Assets dependency
							Dependency attachmentDependency = of
									.createManifestResourcesResourceDependency();
							attachmentDependency
									.setIdentifierref(fileIdentifier);

							passageResource.getDependency().add(
									attachmentDependency);
							
							// Add Assets resource
							Resource assetsResource = of
									.createManifestResourcesResource();
							
							File assetsFile = of
									.createManifestResourcesResourceFile();
							assetsFile.setHref(passage.getHrefBase()
									+ fileName);

							assetsResource.setIdentifier(fileIdentifier);
							assetsResource
									.setType(SAAIFPackageConstants.CONTENT_TYPE);
							assetsResource.setFile(assetsFile);

							resources.getResource().add(assetsResource);
						}
					}
				}
			}
		}

		addDefaultManifestMetadata();

		m.setResources(resources);

	}

	public void write(java.io.File file) {
		try {
			String manifestContent = JAXBUtil.mershall(m, Manifest.class);
			FileUtils.write(file, manifestContent);
		} catch (IOException e) {
			LOGGER.error("Unable to write SAABIF manifest to file ", e);
		}
	}

	public void addDefaultManifestMetadata() {
		this.m.setIdentifier("MANIFEST-QTI-" + getUniqueId());

		Metadata metadata = of.createManifestMetadata();
		LomManifestType lom = of.createLom();

		metadata.setSchema("APIP Item Bank");
		metadata.setSchemaversion("1.0.0");
		metadata.setLom(lom);

		m.setMetadata(metadata);
	}

	private static String getItemHref(String base, String fileName) {
		return getItemHrefBase(base) + fileName;
	}

	private static String getStimuliHref(String base, String fileName) {
		return getStimuliHrefBase(base) + fileName;
	}

	private static String getItemHrefBase(String base) {
		return "Items/Item_" + base + '/';
	}

	private static String getStimuliHrefBase(String base) {
		return "Stimuli/Stim_" + base + '/';
	}

	private final String getUniqueId() {
		String key = 'A' + UUID.randomUUID().toString().substring(1)
				.toUpperCase();
		this.uniqueIds.add(key);
		return key;
	}

}
