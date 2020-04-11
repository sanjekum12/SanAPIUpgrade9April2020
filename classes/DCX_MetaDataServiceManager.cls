/*****************************************************************************
 *                       Copyright (C) 2019 ServiceMax, Inc
 *                               All rights reserved
 *
 *****************************************************************************/

/**
 * Metadata Service manager which has business logic for all the services, related to user settings and svmx settings, re-written for DCx
 * @author Sandeep Dhariwal
 * @version 19.2000
 * @since 2019
 */
public with sharing class DCX_MetaDataServiceManager {
    
    public static metaDataSetting fetchMetaData() {
        long startDC = DateTime.Now().getTime();
        metaDataSetting metaDataSet = new metaDataSetting();
        String userId = String.Valueof(UserInfo.getUserId());
        List<SFM_WrapperDef.FieldProperties> fieldPropertyList;
        Boolean isTextArea;
        
        try {

            long startDisp = DateTime.Now().getTime();
            metaDataSet.displayTags = 
                DCON_Configuration_WS.DCON_Retrieve_Display_Tags_WS(userId);
            long stopDisp = DateTime.Now().getTime();
            system.debug('Time takenx for DCON_Retrieve_Display_Tags_WS: '+(stopDisp-startDisp));

            long startTZ = DateTime.Now().getTime();
            metaDataSet.timeZoneInfo = DCON_Configuration_WS.DCON_GetAllTimeZone_WS(userId);
            long stopTZ = DateTime.Now().getTime();
            system.debug('Time takenx for DCON_GetAllTimeZone_WS: '+(stopTZ-startTZ));
            
            long startGO = DateTime.Now().getTime();
            DCON_Configuration_WS.SVMX_Response objectFieldInfo = 
                new DCON_Configuration_WS.SVMX_Response();
            objectFieldInfo = DCON_Configuration_WS.DCON_getObjectFieldList_WS();
            long stopGO = DateTime.Now().getTime();
            system.debug('Time takenx for DCON_getObjectFieldList_WS: '+(stopGO-startGO));
            
            long startSFM = DateTime.Now().getTime();
            fieldPropertyList = new List<SFM_WrapperDef.FieldProperties>();
            metaDataSet.sfmWorkOrderFields = 
                SFM_WebServicesDef.SFM_getObjectFieldList_WS(setSFMFieldsWrapper('SVMXC__Service_Order__c','SCREEN'));
                long stopSFM = DateTime.Now().getTime();
                system.debug('Time takenx for Work Order SFM_getObjectFieldList_WS: '+(stopSFM-startSFM));
            
            long startEv = DateTime.Now().getTime();
            // get skills
            long startskill = DateTime.Now().getTime();
            metaDataSet.skills = SVMXC.DCON_MultiCriteriaTechMatch_WS.getSkillDetails();
            long stopskill = DateTime.Now().getTime();
            system.debug('Time takenx for getSkillDetails: '+(stopskill-startskill));
            metaDataSet.sfmEventFields = fetchEventColorFields();
            metaDataSet.sfmServiceGroupMembers = fetchFields('SVMXC__Service_Group_Members__c');
            metaDataSet.sfmServiceGroup = fetchFields('SVMXC__Service_Group__c');
            long stopEv = DateTime.Now().getTime();
            system.debug('Time takenx for Event SFM_getObjectFieldList_WS: '+(stopEv-startEv));
            
        } catch (Exception ex) {
            throw new DCX_CommonServiceManager.DCxException(ex.getmessage());
        }
        long stopDC = DateTime.Now().getTime();
        system.debug('Time taken for fetchMetaDataSettings: '+(stopDC-startDC));
        return metaDataSet;
    }

    public static SFM_WrapperDef.SFM_Request setSFMFieldsWrapper (String objectName, String objectType) {
        SFM_WrapperDef.SFM_Request wrapper = new SFM_WrapperDef.SFM_Request();
        List<SFM_WrapperDef.SFM_StringMap> sfmMaps = new List<SFM_WrapperDef.SFM_StringMap>();
        SFM_WrapperDef.SFM_StringMap sfmMap;
        sfmMap = new SFM_WrapperDef.SFM_StringMap('OBJECTNAME',objectName);
        sfmMaps.add(sfmMap);
        sfmMap = new SFM_WrapperDef.SFM_StringMap('OBJECTTYPE',objectType);
        sfmMaps.add(sfmMap);
        wrapper.setstringMap(sfmMaps);
        return wrapper;
    }

    public static List<objFieldInfo> fetchEventColorFields() {
        List<String> evtFields = new List<string> {'Id', 'Subject','DurationInMinutes','Description','WhatId','WhoId','ActivityDate','ActivityDateTime','StartDateTime','EndDateTime','Location','LastModifiedDate','SVMXC__Driving_Time__c','SVMXC__Overhead_Time_Before__c','SVMXC__Overhead_Time_After__c','SVMXC__Driving_Time_Home__c','SVMXC__Service_Duration__c','SVMXC__Break_Time_Total__c','Type','IsAllDayEvent','SVMXC__SM_Latitude__c','SVMXC__SM_Longitude__c'};
        List<objFieldInfo> eventFields = new List<objFieldInfo>();
        List<String> fieldList = new List<String>();
        List<String> pickListValuesList= new List<String>();
        List<Schema.PicklistEntry> ple = new List<Schema.PicklistEntry>();
        Map<String, Schema.SObjectField> fieldMap = Event.sObjectType.getDescribe().fields.getMap();
        eventFields.add(new objFieldInfo('Id','Activity Id','id',String.Valueof(fieldMap.get('Id').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('Subject','Subject','subject',String.Valueof(fieldMap.get('Subject').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('DurationInMinutes','Duration','durationInMinutes',String.Valueof(fieldMap.get('DurationInMinutes').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('Description','Description','description',String.Valueof(fieldMap.get('Description').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('WhatId','Related To','whatId',String.Valueof(fieldMap.get('WhatId').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('WhoId','Name','whoId',String.Valueof(fieldMap.get('WhoId').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('ActivityDate','Due Date Only','activityDate',String.Valueof(fieldMap.get('ActivityDate').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('ActivityDateTime','Due Date Time','activityDateTime',String.Valueof(fieldMap.get('ActivityDateTime').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('StartDateTime','Start','startDateTime',String.Valueof(fieldMap.get('StartDateTime').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('EndDateTime','End','endDateTime',String.Valueof(fieldMap.get('EndDateTime').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('Location','Location','location',String.Valueof(fieldMap.get('Location').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('LastModifiedDate','Last Modified Date','lastModifiedDateTime',String.Valueof(fieldMap.get('LastModifiedDate').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Driving_Time__c','Travel Time to Workorder Location (Mins)','Driving_Time',String.Valueof(fieldMap.get('SVMXC__Driving_Time__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Overhead_Time_Before__c','Overhead Time at Start of the Job (Mins)','Overhead_Time_Before',String.Valueof(fieldMap.get('SVMXC__Overhead_Time_Before__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Overhead_Time_After__c','Overhead Time at End of the Job (Mins)','Overhead_Time_After',String.Valueof(fieldMap.get('SVMXC__Overhead_Time_After__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Driving_Time_Home__c','Travel Time Back to Home Base (Mins)','Driving_Time_Home',String.Valueof(fieldMap.get('SVMXC__Driving_Time_Home__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Service_Duration__c','Service Time (in Seconds)','Service_Duration',String.Valueof(fieldMap.get('SVMXC__Service_Duration__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__Break_Time_Total__c','Total Break Time (Mins)','Break_Time_Total',String.Valueof(fieldMap.get('SVMXC__Break_Time_Total__c').getDescribe().getType()),null));
        ple = fieldMap.get('Type').getDescribe().getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        eventFields.add(new objFieldInfo('Type','Type','Type',String.Valueof(fieldMap.get('Type').getDescribe().getType()),string.join(pickListValuesList,',')));
        eventFields.add(new objFieldInfo('IsAllDayEvent','All-Day Event','IsAllDayEvent',String.Valueof(fieldMap.get('IsAllDayEvent').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__SM_Latitude__c','Latitude','latitude',String.Valueof(fieldMap.get('SVMXC__SM_Latitude__c').getDescribe().getType()),null));
        eventFields.add(new objFieldInfo('SVMXC__SM_Longitude__c','Longitude','longitude',String.Valueof(fieldMap.get('SVMXC__SM_Longitude__c').getDescribe().getType()),null));

        fieldList = DCX_Utils.getConfiguredEventFields();
            for(String settingVal : fieldList) {
                if(fieldMap.containsKey(settingVal.toLowerCase())){
                    if(!evtFields.contains(settingVal)) {
                        if(fieldMap.get(settingVal).getDescribe().getType() == Schema.DisplayType.Picklist) {
                            pickListValuesList= new List<String>();
                            ple = new List<Schema.PicklistEntry>();
                            ple = fieldMap.get(settingVal).getDescribe().getPicklistValues();
                            for( Schema.PicklistEntry pickListVal : ple){
                                pickListValuesList.add(pickListVal.getLabel());
                            }
                            eventFields.add(new objFieldInfo(settingVal,fieldMap.get(settingVal).getDescribe().getLabel(),settingVal,String.Valueof(fieldMap.get(settingVal).getDescribe().getType()),string.join(pickListValuesList,',')));
                        } else {
                            eventFields.add(new objFieldInfo(settingVal,fieldMap.get(settingVal).getDescribe().getLabel(),settingVal,String.Valueof(fieldMap.get(settingVal).getDescribe().getType()),null));
                        }
                    }
                }
            }
        return eventFields;
    }

    public static List<objFieldInfo> fetchFields(String objectName) {
        List<objFieldInfo> objectFields = new List<objFieldInfo>();
        String apiName,labelName,dataType;
        Map<String, Schema.SObjectField> fieldMap;
        if(objectName == 'SVMXC__Service_Group_Members__c') {
            fieldMap = SVMXC__Service_Group_Members__c.sObjectType.getDescribe().fields.getMap();   
        }
        else {
            fieldMap = SVMXC__Service_Group__c.sObjectType.getDescribe().fields.getMap();
        }
        for(String fieldName: fieldMap.keySet()) {
            apiName = String.Valueof(fieldMap.get(fieldName).getDescribe().getName());
            labelName = String.Valueof(fieldMap.get(fieldName).getDescribe().getLabel());
            dataType = String.Valueof(fieldMap.get(fieldName).getDescribe().getType());
            objectFields.add(new objFieldInfo(apiName,labelName,null,dataType,null));   
        }
        return objectFields;
    }

    public class metaDataSetting {
        public List<COMM_TagWebServices.TagsMap> displayTags {get; set;}
        public List<DCON_Configuration_WS.SVMX_StringMap> timeZoneInfo {get; set;}
        public SFM_WrapperDef.SFM_Response_ObjectFields sfmWorkOrderFields {get; set;}
        public List<objFieldInfo> sfmEventFields {get;set;}
        public List<objFieldInfo> sfmServiceGroupMembers {get;set;}
        public List<objFieldInfo> sfmServiceGroup {get;set;}
        public list<DCON_MultiCriteriaTechMatch_WS.skill> skills {get;set;}
    }

    public class objFieldInfo {
        public String apiName;
        public String labelName;
        public String wrapperName;
        public String dataType;
        public String pickListVals;

        objFieldInfo(String apiName,String labelName,String wrapperName, String dataType, String val) {
            this.apiName = apiName;
            this.labelName = labelName;
            this.wrapperName = wrapperName;
            this.dataType = dataType;
            this.pickListVals = val;
        }   
    }
}