/**
 * Created by Ahmad on 01/02/2022.
 */

public with sharing class MetadataCallback implements Metadata.DeployCallback {

    public static Id upsertMetadata(List<SObject> customMetadataList) {

        // Create Deployment container for custom Metadata
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for (SObject sObj : customMetadataList) {

            // Get metadata object name and details
            String sObjectName = sObj.getSObjectType().getDescribe().getName();

            // Create custom Metadata instance
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            String recordName = String.valueOf(sObj.get('DeveloperName')).replaceAll(' ', '_');
            customMetadata.fullName = sObjectName + '.' + recordName;
            customMetadata.label = (String) sObj.get('MasterLabel');

            // Get all fields
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

            Map<String, Schema.SObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();
            Set<String> skipFieldSet = new Set<String>{
                    'developername', 'masterlabel', 'language', 'namespaceprefix', 'label', 'qualifiedapiname', 'id'
            };

            // Use getPopulatedFieldsAsMap to get the populate field and iterate over them
            for (String fieldName : sObj.getPopulatedFieldsAsMap().keySet()) {

                if (skipFieldSet.contains(fieldName.toLowerCase()) || sObj.get(fieldName) == null) {
                    continue;
                }

                Object value = sObj.get(fieldName);

                // Create field instance and populate it with field API name and value
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = fieldName;
                Schema.DisplayType valueType = sObjectFields.get(fieldName).getDescribe().getType();

                if (value instanceof String && valueType != Schema.DisplayType.STRING) {
                    if (valueType == Schema.DisplayType.PERCENT || valueType == Schema.DisplayType.CURRENCY) {
                        customField.value = Decimal.valueOf(String.valueOf(value));
                    } else if (valueType == Schema.DisplayType.DOUBLE) {
                        customField.value = Double.valueOf(value);
                    } else if (valueType == Schema.DisplayType.INTEGER) {
                        customField.value = Integer.valueOf(value);
                    } else if (valueType == Schema.DisplayType.BASE64) {
                        customField.value = Blob.valueOf(String.valueOf(value));
                    } else if (valueType == Schema.DisplayType.DATE) {
                        customField.value = Date.valueOf(value);
                    } else if (valueType == Schema.DisplayType.DATETIME) {

                        // DateTime is a special case which we need to handle carefully.
                        try {
                            String d1 = String.valueOf(value);
                            List<String> d2 = d1.split('-');
                            List<Integer> timeCmp = new List<Integer>();
                            timeCmp.add(Integer.valueOf(d2[0]));
                            timeCmp.add(Integer.valueOf(d2[1]));
                            timeCmp.add(Integer.valueOf(d2[2].left(2)));

                            String t = d2[2].substringBetween('T', '.');

                            List<String> t1 = t.split(':');
                            timeCmp.add(Integer.valueOf(t1[0]));
                            timeCmp.add(Integer.valueOf(t1[1]));
                            timeCmp.add(Integer.valueOf(t1[2]));

                            customField.value = Datetime.newInstance(timeCmp[0], timeCmp[1], timeCmp[2], timeCmp[3], timeCmp[4], timeCmp[5]);
                        } catch (Exception e) {
                        }
                    } else {
                        customField.value = value;
                    }
                } else {
                    customField.value = value;
                }
                // Add fields in the object, similar to creating sObject instance
                customMetadata.values.add(customField);
            }
            // Add metadata in container
            mdContainer.addMetadata(customMetadata);
        }
        // Callback class instance
        MetadataCallback callback = new MetadataCallback();

        // Enqueue custom metadata deployment
        // jobId is the deployment ID
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        return jobId;
    }

    // Use it to pass single metadata instance
    public static Id upsertMetadata(SObject customMetadata) {
        List<SObject> sObjects = new List<SObject>();
        sObjects.add(customMetadata);
        return upsertMetadata(sObjects);
    }

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {

        } else {

        }
    }
}