/*****************************************************************************
 *                       Copyright (C) 2019 ServiceMax, Inc
 *                               All rights reserved
 *
 *****************************************************************************/

/**
 * Service manager which has business logic for all the services, related to event object, re-written for DCx
 * @author Vinay Vijay
 * @version 19.2000
 * @since 2019
 */
public with sharing class DCX_EventServiceManager {
    
    //TODO: Move all the static variables to method level
    public static DCX_Utils dcUtils = new DCX_Utils();
    public static boolean isSplRelatedHandling = false;
    public static set<string> setApiName = new set<string>();
    public static Map<String, String> mapSFUSerTechId = new Map<String, String>();
    public static map<String,SVMXC__Service_Group_Members__c> mapIdTech = 
        new map<String,SVMXC__Service_Group_Members__c>();

    public static DCxFetchLaunchEvents fetchEventsOnLaunch() {
        Boolean isLocal = true;
        List<String> SFUSerIds = new List<String>();
        List<String> SVMXUserIds = new List<String>();
        List<Event> lstSalesforceEvents = new List<Event>();
        List<SVMXC__SVMX_Event__c> lstServiceMaxEvents = new List<SVMXC__SVMX_Event__c>();
        List<DCX_CommonServiceManager.Events_WP> resultSet = 
            new List<DCX_CommonServiceManager.Events_WP>();
        Event_Inp inp = formInputsForLaunch();
        
        List<String> TechnicianIds = new List<String>();
        for(SVMXC__Service_Group_Members__c tech : inp.techIds)
            TechnicianIds.add(tech.id);
        String UserId = UserInfo.getUserId();
        String timeZone = Userinfo.getTimeZone().getID();
         
        
        try {

            for(SVMXC__Service_Group_Members__c tl: [Select id, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c where Id IN :TechnicianIds]) {
                //Get all user Id associated with SF tech to retrieve SF event
                if(tl.SVMXC__Salesforce_User__c != NULL)
                    SFUSerIds.add(tl.SVMXC__Salesforce_User__c);
            } 
         
            Date st = Date.newinstance(inp.startDate.year(), inp.startDate.month(), inp.startDate.day());
            Date ed = Date.newinstance(inp.endDate.year(), inp.endDate.month(), inp.endDate.day());
            lstSalesforceEvents = DCON_Retrieve_Salesforce_Events_WS(timeZone, st, ed, SFUSerIds);
         
            lstServiceMaxEvents = DCON_Retrieve_ServiceMax_Events_WS(timeZone, st, ed, TechnicianIds);
         
            
            resultSet = mergeEvents(lstSalesforceEvents, lstServiceMaxEvents, UserId, timeZone, isLocal);
         

            if(resultSet != null && resultSet.size() > 0 ) {
                resultSet.get(resultSet.size()-1).lastSyncedTime = DateTime.now().getTime();
            }
            else {
                DCX_CommonServiceManager.Events_WP obj = new DCX_CommonServiceManager.Events_WP();
                obj.lastSyncedTime = DateTime.now().getTime();
                resultSet.add(obj);
            }

        }
        catch(Exception ex) {
            system.debug(LoggingLevel.WARN, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
            throw new DCX_CommonServiceManager.DCxException(ex);
        }


            system.debug(logginglevel.warn,'Event wrapper: ' + resultSet);
            DCxFetchLaunchEvents events = new DCxFetchLaunchEvents(resultSet,inp.startDate.format('yyyy-MM-dd HH:mm:ss'), inp.endDate.format('yyyy-MM-dd HH:mm:ss'),TechnicianIds);
            return events;
    }

    private static String SVMX_getFieldNamesFromList(set<String> fieldList) {
        String fieldNames = '';
            for (String field : fieldList) {
                if (fieldNames.length()>0) {
                    fieldNames += ',';
                }
                fieldNames += field;
            }
        return fieldNames;

    }  
        
        //This method returns a list of Salesforce calendar events for one or more technicians.
        //We are using UserId as Timezone
        //Depending upon the type of technician record, events are retrieved either from Salesforce Events or ServiceMax Events.
        private static List<Event> DCON_Retrieve_Salesforce_Events_WS(String timeZone, Date DStartDate, Date DEndDate, List<String> EventOwnerIds) {
            List<Event> EventList = new List<Event>();
            Datetime DStartDatetime = Datetime.newInstanceGMT(DStartDate,Time.newInstance(0, 0, 0, 0));
//            Map<String,String> mapValidSettingsForUpdate = new Map<String,String>();
//            mapValidSettingsForUpdate = DCON_Event_WS.getValidateSettingsFrom38To47();
            Set<String> fieldList = getConfiguredEventUpdateFields();
    
            set<String> EventOwners = new set<String>();
            set<String> flds = new set<String>();
            set<String> Eventflds = new set<String>();
            EventOwners.addAll(EventOwnerIds);
            try {
                DateTime dtmStartDateTime = dcUtils.getDateTimeInTimezone(DStartDate, Time.newInstance(0, 0, 0, 0), timeZone);
                DateTime dtmEndDateTime = dcUtils.getDateTimeInTimezone(DEndDate, Time.newInstance(23, 59, 59, 59), timeZone);
        
                if(fieldList.size() > 0) {
                    flds.addAll(fieldList);
//                if(mapValidSettingsForUpdate.size() > 0) {
//                    for(String strfld : mapValidSettingsForUpdate.keySet())
//                        flds.add(mapValidSettingsForUpdate.get(strfld));    
         
                    String whereStr = ' where (((StartDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime) OR (EndDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime)) OR (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND IsAllDayEvent = true)) and OwnerId IN :EventOwners and IsRecurrence = false';
                    system.debug('SFEvent where clause'+whereStr);  

                    // This is the change due to the introduction of new fields in event objects
                    flds.add('SVMXC__Driving_Time__c');
                    flds.add('SVMXC__Overhead_Time_Before__c'); 
                    flds.add('SVMXC__Overhead_Time_After__c'); 
                    flds.add('SVMXC__Driving_Time_Home__c'); 
                    flds.add('SVMXC__Service_Duration__c');
                    flds.add('SVMXC__Break_Time_Total__c');
                    flds.add('SVMXC__SM_Latitude__c');
                    flds.add('SVMXC__SM_Longitude__c');
                                        
                    EventList = Database.query('Select Id, Type, ActivityDate, IsAllDayEvent, ActivityDateTime, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from Event ' + whereStr );
      
                }
                else {
                    EventList = [Select Id, Type, ActivityDate, ActivityDateTime, IsAllDayEvent, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,SVMXC__Driving_Time__c, SVMXC__Overhead_Time_Before__c, SVMXC__Overhead_Time_After__c, SVMXC__Driving_Time_Home__c, SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,SVMXC__SM_Longitude__c,SVMXC__SM_Latitude__c from Event where (((StartDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime) OR (EndDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime)) OR (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND IsAllDayEvent = true)) and OwnerId IN :EventOwners and IsRecurrence = false];
         
                }
            }
            catch(Exception ex) {
                system.debug(LoggingLevel.WARN, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
                throw new DCX_CommonServiceManager.DCxException(ex);
            }
        return EventList;
        }

        //This method returns a list of ServiceMax calendar events for one or more technicians.
        //Depending upon the type of technician record, events are retrieved either from Salesforce Events or ServiceMax Events.
        private static List<SVMXC__SVMX_Event__c> DCON_Retrieve_ServiceMax_Events_WS(String timeZone, Date DStartDate, Date DEndDate, List<String> ServiceMaxEventOwnerIds) {
            List<SVMXC__SVMX_Event__c> EventList = new List<SVMXC__SVMX_Event__c>();
            Datetime DStartDatetime = Datetime.newInstanceGMT(DStartDate,Time.newInstance(0, 0, 0, 0));
//            Map<String,String> mapValidSettingsForUpdate = new Map<String,String>();
//            mapValidSettingsForUpdate = DCON_Event_WS.getValidateSettingsFrom38To47();
            Set<String> fieldList = getConfiguredEventUpdateFields();
            Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
            set<String> flds = new set<String>();
            set<String> Eventflds = new set<String>();
         
            try{
                set<String> EventOwners = new set<String>();
                EventOwners.addAll(ServiceMaxEventOwnerIds);
                DateTime dtmStartDateTime = dcUtils.getDateTimeInTimezone(DStartDate, Time.newInstance(0, 0, 0, 0), timeZone);
                DateTime dtmEndDateTime = dcUtils.getDateTimeInTimezone(DEndDate, Time.newInstance(23, 59, 59, 59), timeZone);
         
                System.debug('dtmStartDateTime:'+ dtmStartDateTime);
                System.debug('dtmEndDateTime:'+ dtmEndDateTime);
                if(fieldList.size() > 0) {
                    for(String fName : fieldList) {
                        if(souObjfieldMapEVT.containsKey(fName.toLowerCase())) {
                            flds.add(fName);
                        }
                    }
                    //flds.addAll(fieldList);
//                if(mapValidSettingsForUpdate.keySet().size() > 0) {
//                    for(String strfld : mapValidSettingsForUpdate.keySet())
//                        flds.add(mapValidSettingsForUpdate.get(strfld));    
         
                    String whereStr = ' where (((SVMXC__StartDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime) OR (SVMXC__EndDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR (SVMXC__ActivityDate__c <= :DEndDate and SVMXC__EndDateTime__c >= :DStartDatetime AND SVMXC__IsAllDayEvent__c = true) OR(SVMXC__StartDateTime__c = :DStartDatetime AND SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c IN :EventOwners';
                    // This is the change due to the introduction of new fields in event objects
                    //Defect# 014336 - added 'SVMXC__Type__c' field
                    //In future due to any moficications, if we are facing duplicate field error while querying, we may have to use the 
                    //set 'flds' below to add new fields
                    flds.add('SVMXC__Driving_Time__c');
                    flds.add('SVMXC__Overhead_Time_Before__c'); 
                    flds.add('SVMXC__Overhead_Time_After__c'); 
                    flds.add('SVMXC__Driving_Time_Home__c'); 
                    flds.add('SVMXC__Service_Duration__c');
                    flds.add('SVMXC__Break_Time_Total__c');
                    flds.add('SVMXC__IsAllDayEvent__c');
                    flds.add('SVMXC__SM_Latitude__c');
                    flds.add('SVMXC__SM_Longitude__c');
                                        
                    EventList = Database.query('SELECT Id, SVMXC__Type__c, SVMXC__ActivityDate__c, SVMXC__ActivityDateTime__c,  SVMXC__Technician__c, SVMXC__Technician__r.Name, SVMXC__DurationInMinutes__c, Name, SVMXC__Description__c, SVMXC__WhatId__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c, SVMXC__Location__c, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from SVMXC__SVMX_Event__c  '+whereStr);
        
                }
                else {
                    //Defect# 014336 - added 'SVMXC__Type__c' field
                    EventList = [Select Id, SVMXC__Type__c, SVMXC__ActivityDate__c, SVMXC__ActivityDateTime__c,
                                 SVMXC__Technician__c, SVMXC__DurationInMinutes__c, Name, 
                                 SVMXC__Description__c, SVMXC__WhatId__c, SVMXC__StartDateTime__c, 
                                 SVMXC__EndDateTime__c, SVMXC__Location__c, LastModifiedDate,
                                 SVMXC__Driving_Time__c, SVMXC__IsAllDayEvent__c,
                                 SVMXC__Overhead_Time_Before__c, SVMXC__Overhead_Time_After__c, 
                                 SVMXC__Driving_Time_Home__c, SVMXC__Service_Duration__c,
                                 SVMXC__Break_Time_Total__c,SVMXC__SM_Longitude__c,
                                 SVMXC__SM_Latitude__c,SVMXC__Technician__r.Name
                                 from SVMXC__SVMX_Event__c where 
                                 (((SVMXC__StartDateTime__c >= : dtmStartDateTime and 
                                 SVMXC__StartDateTime__c <= : dtmEndDateTime) OR 
                                 (SVMXC__EndDateTime__c >= : dtmStartDateTime and 
                                 SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR 
                                 (SVMXC__ActivityDate__c <= :DEndDate and 
                                 SVMXC__EndDateTime__c >= :DStartDatetime AND SVMXC__IsAllDayEvent__c = true) 
                                 OR(SVMXC__StartDateTime__c = :DStartDatetime 
                                 AND SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c IN :EventOwners];
         
                }
            } catch(Exception ex) {
                throw new DCX_CommonServiceManager.DCxException(ex);
            }

            return EventList;
        }
        
        private static Event_Inp formInputsForLaunch() {

            //Soql to fetch all the relevant DC settings        
            List<String> settingIds = new List<String>{'DCON001_SET033','DCON001_SET034','DCON001_SET001','DCON001_SET004'};
            Map<String,String> grpGblSettings = 
                COMM_Utils_ManageSettings.SVMX_getSettingValueForList(settingIds);
            //fetch user settings
            DCX_CommonServiceManager.UserSetting uSet = DCX_SettingServiceManager.fetchUserSettings();
            
            //Global APP SETTINGS
            Integer techBatchSize = Integer.valueOf(grpGblSettings.get('DCON001_SET033'));//DCON001_SET033
            Integer daysBatchSize = Integer.valueOf(grpGblSettings.get('DCON001_SET034'));//DCON001_SET034
            //Group APP SETTINGS
            String schWindowDuration = grpGblSettings.get('DCON001_SET001');//DCON001_SET001
            String treeType = grpGblSettings.get('DCON001_SET004');//TEAM, TERRITORY - DCON001_SET004
            //USER SETTINGS
            List<String> expandedTeams = new List<String>();
            //expandedTeams = uSet.collapsedTeam.split(',');//TODO: change to expandedTeam
            expandedTeams = uSet.tech_ExpandedTeam;
            List<String> expandedTerritories = new List<String>();
            expandedTerritories = uSet.tech_expandedTerritory;
            Integer noOfDays = Integer.valueOf(uSet.tech_noOfDays);
            String condition = uSet.tech_condition;//before, after
            
            //fetch the techIds
            String soql = '';
            List<SVMXC__Service_Group_Members__c> techIds = new List<SVMXC__Service_Group_Members__c>();
            if(treeType.equalsIgnoreCase('TEAM')) {
                soql = 'SELECT id FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Service_Group__c = :item ORDER BY NAME limit :techBatchSize';
                techIds = fetchTechIds(expandedTeams, soql, techBatchSize);
            } else { 
                soql = 'SELECT id FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Service_Territory__c = :item ORDER BY NAME limit :techBatchSize';
                techIds = fetchTechIds(expandedTerritories, soql, techBatchSize);
            }
            
            //fetch the date range
            Date today = date.today();
            Date startDt, endDt;
            if(condition.equalsIgnoreCase('BEFORE')) {
                startDt = today.addDays(-noOfDays);
            } else {//AFTER
                startDt = today.addDays(noOfDays);
            }
            if(daysBatchSize != null && daysBatchSize > 0) 
                endDt = startDt.addDays(daysBatchSize);
            else
                endDt = startDt.addDays(Integer.valueOf(schWindowDuration));
            
            DateTime st = DateTime.newInstance(startDt.year(),startDt.month(),startDt.day(),0,0,0);
            DateTime ed = DateTime.newInstance(endDt.year(),endDt.month(),endDt.day(),0,0,0);
            Event_Inp input = new Event_Inp(techIds, st, ed);
            return input;
    }

    
    private static List<SVMXC__Service_Group_Members__c> fetchTechIds(List<String> teamOrTerritoryList, String soql, Integer techBatchSize) {

        List<SVMXC__Service_Group_Members__c> techIds = new List<SVMXC__Service_Group_Members__c>();
        List<SVMXC__Service_Group_Members__c> techList = new List<SVMXC__Service_Group_Members__c>();

        if(teamOrTerritoryList.size() > 0) {
            for(String item : teamOrTerritoryList) {
                techList = Database.query(soql);
                Integer remaining = techBatchSize - techIds.size();
                if((techList.size() < remaining) || (techList.size() == remaining)) {
                    techIds.addAll(techList);
                } else {//(techList.size() > remaining)
                    for(Integer i = 0; i < remaining; i++) {//fill in the remaining places in list that has to be returned
                        techIds.add(techList.get(i));
                    }
                    techList.clear();
                    break;//number of tech ids that we have now is equal to techBatchSize, break out!
                }
                techList.clear();                           
            }
        }
        
        return techIds;
    }
    
    private static map<String,String> getmapSFuserTechId(list<Event>  lstEvent) {
            list<string> lstSFuserId = new list<string>();
            map<string,string> mapSFIdTechId = new map<string,string>();
            for(Event objEvent: lstEvent)
                lstSFuserId.add(objEvent.OwnerId);

            for(SVMXC__Service_Group_Members__c objTech: [Select Id,SVMXC__Salesforce_User__c,Name, SVMXC__Enable_Scheduling__c from SVMXC__Service_Group_Members__c where SVMXC__Salesforce_User__c IN :lstSFuserId and SVMXC__Active__c=true])    
                mapSFIdTechId.put(objTech.SVMXC__Salesforce_User__c,objTech.Id);
            return mapSFIdTechId;
        }

    private static String CheckNull(String s){
            if(s == NULL)
                return '';
            else
                return s;
    }
    
    private static Set<String> getConfiguredEventUpdateFields() {
        Set<String> flds = new Set<String>();
        Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
        //COMM_Utils_ManageSettings util = new COMM_Utils_ManageSettings();
        Map<String, String> fldMap = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET038','SET047',null);
        
        for(String fld : fldMap.values()) {
            if(fld.contains('Event.')) {
                List<String> evtField = fld.split('Event.', 2);
                if(souObjfieldMapEVT.containsKey(evtField[1]))
                	flds.add(evtField[1]);
            }
        }
        
        return flds;
    }

    /*private static Set<String> getConfiguredEventUpdateFields(Map<String,String> fldMap) {
        Set<String> flds = new Set<String>();
        
        for(String fld : fldMap.values()) {
            if(fld.contains('Event.')) {
                List<String> evtField = fld.split('Event.', 2);
                flds.add(evtField[1]);
            }
        }
        
        return flds;
    }*/
                
    public static DCX_CommonServiceManager.DCEvent_WO_WP createEvents(List<Event> lstEvent, 
                                                                      String timeZone, 
                                                                      list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                                                                      string techId, 
                                                                      Boolean updatePrimaryTech,
                                                                      Boolean deleteEventForOtherTechs,
                                                                      String techSFId,
                                                                      List<String> woFields)
    {
        String UserId = UserInfo.getUserId();
        Schema.Describesobjectresult discResUser = User.sObjectType.getDescribe();
        User.sObjectType.getDescribe();
        List<String> lstEventId = new List<String>();
        List<Event> lstSFEvents = new List<Event>();
        Map<String,String> FieldDef = new Map<String,String>();
        boolean IsFromUpsert;
        IsFromUpsert = false;
        system.debug(logginglevel.warn,'REQUEST: ' + timeZone + lstEvent);        
        Schema.Describesobjectresult discWorkOrder = SVMXC__Service_Order__c.sObjectType.getDescribe();
        Map<String,String> EVTFieldDef = new Map<String,String>();
        Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
        EVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapEVT); 
        Map<String,String> SVMXEVTFieldDef = new Map<String,String>();
        Map<String, SObjectField> souObjfieldMapSVMXEVT = Schema.SObjectType.SVMXC__SVMX_Event__c.fields.getMap();
        SVMXEVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapSVMXEVT);
        souObjfieldMapSVMXEVT.clear();
        souObjfieldMapEVT.clear();
        Boolean isEventExist = false;
        Map<String, String> mapEventSettings = new Map<String, String>();
        Map<String,String> settingvalues = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET001','SET073',null);
        Map<String, String> mapNewSettings = new Map<String, String>();
        DCX_CommonServiceManager.DCEvent_WO_WP eventsData = 
            new DCX_CommonServiceManager.DCEvent_WO_WP();
        DCON_Work_Order_WS.workorder_WP workOrderObj = new DCON_Work_Order_WS.workorder_WP();
        List<DCX_CommonServiceManager.Events_WP> lstEventWPs = 
            new List<DCX_CommonServiceManager.Events_WP>();
        DCX_CommonServiceManager.Events_WP event_WPObj = new DCX_CommonServiceManager.Events_WP();
        List<String> woIds = new List<String>();
        List<String> deletedEventIds = new List<String>();
        Set<String> lstTechID = new Set<String>();
        DateTime scheduledDateTime;
        String workOrderId = null;
        List<SVMXC__SVMX_Event__c> lstSVMXEvents = new List<SVMXC__SVMX_Event__c>();
        Boolean isError = false;
        String errMessage;
        set<String> setAvailableTechnicains = new set<String>();
        Map<Id,SVMXC__Service_Order__c> updatedWOMap = new Map<Id,SVMXC__Service_Order__c>();
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        SVMXC__Service_Group_Members__c emptyTech = new SVMXC__Service_Group_Members__c();
        system.debug(logginglevel.warn,'Create Event settingvalues : '+ settingvalues);
        Map<String,String> woEvtUpdateFieldMap = getConfiguredEventFieldsSET38To47(settingvalues);
        //Set<String> evtUpdateFields = getConfiguredEventFields(woEvtUpdateFieldMap);
        Set<String> evtUpdateFields = new Set<String>();
        Boolean dummyEventCall = false;
        DCX_EventServiceManager_Util eventServiceUtil = new DCX_EventServiceManager_Util();     
        String sfQuery;

        if(woEvtUpdateFieldMap.keySet().size() > 0)
        {
            for(String strfld : woEvtUpdateFieldMap.keySet())
            {
                if((String.valueOf(woEvtUpdateFieldMap.get(strfld)).contains('Event.')))
                {
                    List<String> Evtfield = String.valueOf(woEvtUpdateFieldMap.get(strfld)).split('Event.',2);
                    if(EVTFieldDef.containskey(Evtfield[1])) {
                        mapEventSettings.put(strfld,Evtfield[1]);
                        evtUpdateFields.add(Evtfield[1]);
                    }
                } 
            }
        } 

        for(DCON_Configuration_WS.SVMX_StringMap oSVMX_StringMap :lstKeyValue) {
            list<string> lststr = new list<string>();
            lststr = oSVMX_StringMap.Key.split('_');
            if(lststr != null && lststr.size() > 1) {
                /*if(lststr[0] != null && lststr[0].toUpperCase() == 'IDLE') {
                    idleDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'DRIVE') {
                    driveDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'SERVICE') {
                    serviceDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'SCOPE') {
                    woScope = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'VARIANCE') {
                    woVariance = Integer.valueOf(oSVMX_StringMap.Value);
                }*/
            } else {
                if(oSVMX_StringMap.Value.toUpperCase() == 'DATE')
                    mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateValue));
                else if(oSVMX_StringMap.Value.toUpperCase() == 'DATETIME')
                    mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateTimeValue));
                else
                    mapNewSettings.put(oSVMX_StringMap.Key,oSVMX_StringMap.Value);
            }
        }    
        
        try
        {
            if(timeZone == null || timeZone == '')
                timeZone = [SELECT TimeZoneSidKey from User where Id = :UserId].TimeZoneSidKey;
            System.debug(loggingLevel.Warn,'Calling checkDoublebookingforTech '+lstEvent);
            if(settingvalues.containsKey('DCON001_SET025') && 
                (settingvalues.get('DCON001_SET025').toUpperCase()=='DISALLOW')) {      
                checkDoublebookingforTech(lstEvent,timeZone,discResUser.getKeyPrefix(),settingvalues);    
            }    
            
            if(techId != null)
                setAvailableTechnicains.add(techId);
            if(setAvailableTechnicains.size() > 0)
                setAvailableTechnicains = getEventEnablesTechnicians(setAvailableTechnicains);

            
            for(Event oEvent: lstEvent)
            {
                
                if(oEvent.WhatId != NULL)
                    workOrderId = oEvent.WhatId;
                scheduledDateTime = 
                    dcUtils.getDateTimeInTimezone(DateTime.valueof(oEvent.ActivityDateTime).dateGmt(),DateTime.valueof(oEvent.ActivityDateTime).timeGmt(),timeZone);
                if(oEvent.OwnerId == null)
                    dummyEventCall = true;
            }
            
            if(dummyEventCall) {
                SVMXC__Service_Order__c dummyWo = [Select Id,SVMXC__Locked_By_DC__c from SVMXC__Service_Order__c where CreatedDate = LAST_N_DAYS:30 limit 1];
                COMM_SecurityUtils.getinstance().updateAsUser(dummyWo);
            }

            
            for(Event oEvent: lstEvent)
            {
                if(oEvent!=NULL)
                {
                    // Update the fields for SF events
                    if(String.valueof(oEvent.OwnerId).startsWith(discResUser.getKeyPrefix()))
                    {                    
                       lstSFEvents.add(populateSFEventDetails(oEvent,mapNewSettings,mapEventSettings,
                                                            timeZone,EVTFieldDef));
                    }
                    else
                    {
                        // Update the fields for SVMX events
                        if(setAvailableTechnicains.contains(oEvent.OwnerId))
                        {
                            lstSVMXEvents.add(populateSVMXEventDetails(oEvent,mapNewSettings,
                                                                       mapEventSettings,timeZone,
                                                                       SVMXEVTFieldDef));
                        }
                    }
                }
            }
            
            if(workOrderId != null) {
                tech = [Select Id,SVMXC__Service_Group__c,SVMXC__Email__c,Name,
                        SVMXC__Service_Group__r.SVMXC__Email__c,SVMXC__Enable_Scheduling__c from SVMXC__Service_Group_Members__c 
                        where Id = :techId];
                SVMXC__Service_Order__c woRec = new SVMXC__Service_Order__c();
                if(updatePrimaryTech) {
                    woRec.SVMXC__Group_Member__c = techId;
                    if(settingvalues.containsKey('DCON001_SET009') && 
                        settingvalues.get('DCON001_SET009').toUpperCase()=='TRUE' &&
                        (techSFId != null && techSFId != ''))
                        woRec.OwnerId = techSFId;
                    woRec.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
                    woRec.SVMXC__Member_Email__c = tech.SVMXC__Email__c;
                    woRec.SVMXC__Group_Email__c = tech.SVMXC__Service_Group__r.SVMXC__Email__c;
                }
                woRec.Id = workOrderId;
                woRec.SVMXC__Scheduled_Date_Time__c = scheduledDateTime; 
                woRec.SVMXC__Last_Dispatch_Event__c = 'Scheduled';
                
                DCX_Utils.updateWorkOrder(woRec,lstKeyValue,timeZone,woEvtUpdateFieldMap);
            }

            if(lstSFEvents.size()>0)
            {
                system.debug('Create Event SFflds : '+ lstSFEvents);
                List<Event> sfLstEvents = new List<Event>();
                //COMM_SecurityUtils.getinstance().insertAsUser(lstSFEvents); 
                eventServiceUtil.insertSFEventsUtil(lstSFEvents);
                if(tech == emptyTech && String.valueof(techId).startsWith(discResUser.getKeyPrefix()) == false) {
                    tech = [SELECT Id, Name,SVMXC__Salesforce_User__c, SVMXC__Service_Group__c, 
                            SVMXC__Service_Group__r.SVMXC__Email__c, SVMXC__Enable_Scheduling__c,SVMXC__Email__c from 
                            SVMXC__Service_Group_Members__c where Id = :techId];
                }
                Set<String> evtSetFields = new Set<String>();
                String evtQuery = 'Select Id,Subject,durationInMinutes,description,WhatId,WhoId,ActivityDate,ActivityDateTime,'
                                    +'StartDateTime,Location,OwnerId,SVMXC__Driving_Time__c,SVMXC__Overhead_Time_Before__c,'
                                    +'SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,SVMXC__Service_Duration__c,'
                                    +'SVMXC__Break_Time_Total__c,Type,IsAllDayEvent,SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,'
                                    +'Owner.Name';
                String whereEvtClause = ' from Event where Id in :lstSFEvents';
                if(evtUpdateFields.size() > 0) {
                    //sfLstEvents = Database.query('Select ' + SVMX_getFieldNamesFromList(combineEventFields(evtUpdateFields)) + whereEvtClause);
                    sfQuery = 'Select ' + SVMX_getFieldNamesFromList(combineEventFields(evtUpdateFields)) + whereEvtClause;
                    sfLstEvents = eventServiceUtil.retrieveSFEventsUtil(sfQuery,lstSFEvents);
                } else {
                    sfQuery = evtQuery + whereEvtClause;
                    sfLstEvents = eventServiceUtil.retrieveSFEventsUtil(sfQuery,lstSFEvents);
                    //sfLstEvents = Database.query(evtQuery + whereEvtClause);
                }

                for(Event ev : sfLstEvents)
                    lstEventWPs.add(populateSFEventInfoDetails(ev,tech,mapEventSettings,EVTFieldDef));
            }

            if(lstSVMXEvents.size()>0)
            {
                system.debug('Create Event Svmxflds : '+ lstSVMXEvents);
                List<SVMXC__SVMX_Event__c> svmxEvents = new List<SVMXC__SVMX_Event__c>();
                COMM_SecurityUtils.getinstance().insertAsUser(lstSVMXEvents);
                String evtSVMXQuery = 'Select Id,Name,SVMXC__DurationInMinutes__c,SVMXC__Description__c,SVMXC__WhatId__c,'
                                        +'SVMXC__WhoId__c,SVMXC__ActivityDate__c,SVMXC__ActivityDateTime__c,SVMXC__StartDateTime__c,'
                                        +'SVMXC__EndDateTime__c,SVMXC__Location__c,SVMXC__Technician__c,SVMXC__Driving_Time__c,'
                                        +'SVMXC__Overhead_Time_Before__c,SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,'
                                        +'SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,SVMXC__Type__c,SVMXC__IsAllDayEvent__c,'
                                        +'SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,SVMXC__Technician__r.Name';
                String whereSVMXClause = ' from SVMXC__SVMX_Event__c where Id in :lstSVMXEvents';
                if(evtUpdateFields.size() > 0) {
                    svmxEvents = Database.query( 'Select ' + SVMX_getFieldNamesFromList(combineSVMXEventFields(evtUpdateFields)) 
                                                + whereSVMXClause);
                } else {
                    svmxEvents = Database.query(evtSVMXQuery + whereSVMXClause);
                }
                for(SVMXC__SVMX_Event__c evt : svmxEvents) {
                    lstEventWPs.add(populateSVMXEventInfoDetails(evt,mapEventSettings,SVMXEVTFieldDef));
                }
            }
            eventsData.lstEvent = lstEventWPs;
            eventsData.settingValues = woEvtUpdateFieldMap;
            if(deleteEventForOtherTechs && workOrderId != null) {
                //deletedEventIds = deleteEventForWO(workOrderId,null,techId,techSFId,settingvalues);
                deletedEventIds = eventServiceUtil.deleteEventForWOUtil(workOrderId,null,techId,techSFId,settingvalues);
            }
            if(deletedEventIds.size() > 0)
                eventsData.deletedEventIds = deletedEventIds;
            
        }    
        catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
            
        }
        return eventsData;
    }

    public static set<String> combineSVMXEventFields(Set<String> evtUpdateFields) {
        Set<String> evFields = new Set<String>();
        evFields.add('Id');
        evFields.add('Name');
        evFields.add('SVMXC__DurationInMinutes__c');
        evFields.add('SVMXC__Description__c');
        evFields.add('SVMXC__WhatId__c');
        evFields.add('SVMXC__WhoId__c');
        evFields.add('SVMXC__ActivityDate__c');
        evFields.add('SVMXC__ActivityDateTime__c');
        evFields.add('SVMXC__StartDateTime__c');
        evFields.add('SVMXC__EndDateTime__c');
        evFields.add('SVMXC__Location__c');
        evFields.add('SVMXC__Technician__c');
        evFields.add('SVMXC__Driving_Time__c');
        evFields.add('SVMXC__Overhead_Time_Before__c');
        evFields.add('SVMXC__Overhead_Time_After__c');
        evFields.add('SVMXC__Driving_Time_Home__c');
        evFields.add('SVMXC__Service_Duration__c');
        evFields.add('SVMXC__Break_Time_Total__c');
        evFields.add('SVMXC__Type__c');
        evFields.add('SVMXC__IsAllDayEvent__c');
        evFields.add('SVMXC__SM_Latitude__c');
        evFields.add('SVMXC__SM_Longitude__c');
        evFields.add('SVMXC__Technician__r.Name');
        evFields.addAll(evtUpdateFields);
        for(String ev : evFields) {
            system.debug('combineSVMXEventFields ev = '+ev);
        }
        return evFields;
    }

    public static set<String> combineEventFields(Set<String> evtUpdateFields) {
        Set<String> evFields = new Set<String>();
        evFields.add('Id');
        evFields.add('Subject');
        evFields.add('durationInMinutes');
        evFields.add('description');
        evFields.add('WhatId');
        evFields.add('WhoId');
        evFields.add('ActivityDate');
        evFields.add('ActivityDateTime');
        evFields.add('StartDateTime');
        evFields.add('EndDateTime');
        evFields.add('Location');
        evFields.add('OwnerId');
        evFields.add('SVMXC__Driving_Time__c');
        evFields.add('SVMXC__Overhead_Time_Before__c');
        evFields.add('SVMXC__Overhead_Time_After__c');
        evFields.add('SVMXC__Driving_Time_Home__c');
        evFields.add('SVMXC__Service_Duration__c');
        evFields.add('SVMXC__Break_Time_Total__c');
        evFields.add('Type');
        evFields.add('IsAllDayEvent');
        evFields.add('SVMXC__SM_Latitude__c');
        evFields.add('SVMXC__SM_Longitude__c');
        evFields.add('Owner.Name');
        evFields.addAll(evtUpdateFields);
        for(String ev : evFields) {
            system.debug('combineEventFields ev = '+ev);
        }
        return evFields;
    }

   public static set<String> getEventEnablesTechnicians(set<String> technicianIds)
    {
        set<String> availabeltech = new set<String>();
        if(technicianIds.size() > 0){
            for(SVMXC__Service_Group_Members__c tech: [Select Id from SVMXC__Service_Group_Members__c 
                                                       where id IN :technicianIds and  
                                                       SVMXC__Enable_Scheduling__c = true]){
                //for(SVMXC__Service_Group_Members__c tech: techList){    
                availabeltech.add(tech.Id);
            }
        }
        return availabeltech;
    }

    public class Event_Inp {
        public List<SVMXC__Service_Group_Members__c> techIds {get; set;}
        public DateTime startDate {get; set;}
        public DateTime endDate {get; set;}
        
        public Event_Inp(List<SVMXC__Service_Group_Members__c> ids, DateTime st, DateTime ed) {
            this.techIds = ids;
            this.startDate = st;
            this.endDate = ed;
        }
    }
    
    public class DCxEvents {
        public List<DCX_CommonServiceManager.Events_WP> events;
        public String startDate;
        public String endDate; 
        public Map<Id,SVMXC__Service_Order__c> woInfoMap;
        DCxEvents(List<DCX_CommonServiceManager.Events_WP> evts, String st, String ed) {
            this.events = evts;
            this.startDate = st;
            this.endDate = ed;
        }
    }

    public class DCxFetchLaunchEvents {
        public List<DCX_CommonServiceManager.Events_WP> events {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public List<String> techIds {get;set;}
        DCxFetchLaunchEvents(List<DCX_CommonServiceManager.Events_WP> evts, String st, 
                             String ed, List<String> tIds) {
            this.events = evts;
            this.startDate = st;
            this.endDate = ed;
            this.techIds = tIds;
        }
    }
    
    private  static Map<String, String> getConfiguredEventFieldsSET38To47() {
        List<String> flds = new List<String>();
        //COMM_Utils_ManageSettings util = new COMM_Utils_ManageSettings();
        Map<String, String> fldMap = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET038','SET047',null);
        Map<String, String> fldMap1 = new map<string,string>();
        
            if(fldMap.get('DCON001_SET038') != null)
                fldMap1.put('SET038', fldMap.get('DCON001_SET038'));
            if(fldMap.get('DCON001_SET039') != null)
                fldMap1.put('SET039', fldMap.get('DCON001_SET039'));
            if(fldMap.get('DCON001_SET040') != null)
                fldMap1.put('SET040', fldMap.get('DCON001_SET040'));
            if(fldMap.get('DCON001_SET041') != null)
                fldMap1.put('SET041', fldMap.get('DCON001_SET041'));
            if(fldMap.get('DCON001_SET042') != null)
                fldMap1.put('SET042', fldMap.get('DCON001_SET042'));
            if(fldMap.get('DCON001_SET043') != null)
                fldMap1.put('SET043', fldMap.get('DCON001_SET043'));
            if(fldMap.get('DCON001_SET044') != null)
                fldMap1.put('SET044', fldMap.get('DCON001_SET044'));
            if(fldMap.get('DCON001_SET045') != null)
                fldMap1.put('SET045', fldMap.get('DCON001_SET045'));
            if(fldMap.get('DCON001_SET046') != null)
                fldMap1.put('SET046', fldMap.get('DCON001_SET046'));
            if(fldMap.get('DCON001_SET047') != null)
                fldMap1.put('SET047', fldMap.get('DCON001_SET047'));


        return fldMap1;
    }

    private  static Map<String, String> getConfiguredEventFieldsSET38To47(Map<String,String> fldMap) {
        Map<String, String> fldMap1 = new map<string,string>();
        
            if(fldMap.get('DCON001_SET038') != null)
                fldMap1.put('SET038', fldMap.get('DCON001_SET038'));
            if(fldMap.get('DCON001_SET039') != null)
                fldMap1.put('SET039', fldMap.get('DCON001_SET039'));
            if(fldMap.get('DCON001_SET040') != null)
                fldMap1.put('SET040', fldMap.get('DCON001_SET040'));
            if(fldMap.get('DCON001_SET041') != null)
                fldMap1.put('SET041', fldMap.get('DCON001_SET041'));
            if(fldMap.get('DCON001_SET042') != null)
                fldMap1.put('SET042', fldMap.get('DCON001_SET042'));
            if(fldMap.get('DCON001_SET043') != null)
                fldMap1.put('SET043', fldMap.get('DCON001_SET043'));
            if(fldMap.get('DCON001_SET044') != null)
                fldMap1.put('SET044', fldMap.get('DCON001_SET044'));
            if(fldMap.get('DCON001_SET045') != null)
                fldMap1.put('SET045', fldMap.get('DCON001_SET045'));
            if(fldMap.get('DCON001_SET046') != null)
                fldMap1.put('SET046', fldMap.get('DCON001_SET046'));
            if(fldMap.get('DCON001_SET047') != null)
                fldMap1.put('SET047', fldMap.get('DCON001_SET047'));


        return fldMap1;
    }
    
    public static  DCxEvents fetchEvents1(String UserId, String StartDate, String EndDate, String EventType, String timeZoneDateTimeFormat, List<String> TechnicianIds)
        {
            SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
            Boolean isLocal = false;
            List<String> SFUSerIds = new List<String>();
            List<String> SVMXUserIds = new List<String>();
            List<Event> lstSalesforceEvents = new List<Event>();
            List<SVMXC__SVMX_Event__c> lstServiceMaxEvents = new List<SVMXC__SVMX_Event__c>();
            set<String> techlst = new set<String>();
            List<DCX_CommonServiceManager.Events_WP> resultSet = 
                new List<DCX_CommonServiceManager.Events_WP>();
            Map<String,String> mapValidSettingsForUpdate = new Map<String,String>();
       //     mapValidSettingsForUpdate = getValidateSettingsFrom38To47();
            set<String> flds = new set<String>();
            try {
                List<String> fieldList = getConfiguredEventFields();
                if(fieldList.size() > 0) {
                        flds.addAll(fieldList);
                }
                system.debug('flds :'+flds);
            
                techlst.addAll(TechnicianIds);
                list<string> lstTimeZoneDateTime = new list<string>();
                lstTimeZoneDateTime = timeZoneDateTimeFormat.split('@');
                string timeZone = lstTimeZoneDateTime.get(0);
                lstTimeZoneDateTime.clear();
                isLocal = true;
                  
                //opz  
                //To support more than 14 day event for SF Tech, we are creating SVMX event based on the Config setting.According to the new logic we are retrieving both SF and SVMX Event for a technician
                for(SVMXC__Service_Group_Members__c tl: [Select id, SVMXC__Salesforce_User__c from 
                                                         SVMXC__Service_Group_Members__c where Id 
                                                         IN :techlst]) {
                    //Get all user Id associated with SF tech to retrieve SF event
                    if(tl.SVMXC__Salesforce_User__c != NULL)
                        SFUSerIds.add(tl.SVMXC__Salesforce_User__c);
                } 
                   Date DStartDate = Date.valueOf(StartDate);
                Date DEndDate = Date.valueOf(EndDate);
                Datetime DStartDatetime = Datetime.newInstanceGMT(DStartDate,Time.newInstance(0, 0, 0, 0));

                DateTime dtmStartDateTime = dcUtils.getDateTimeInTimezone(Date.valueOf(StartDate), Time.newInstance(0, 0, 0, 0), UserId);
                DateTime dtmEndDateTime = dcUtils.getDateTimeInTimezone(Date.valueOf(EndDate), Time.newInstance(23, 59, 59, 59), UserId);

                if(fieldList.size() > 0) {
                
                flds.add('SVMXC__Driving_Time__c');
                    flds.add('SVMXC__Overhead_Time_Before__c'); 
                    flds.add('SVMXC__Overhead_Time_After__c'); 
                    flds.add('SVMXC__Driving_Time_Home__c'); 
                    flds.add('SVMXC__Service_Duration__c');
                    flds.add('SVMXC__Break_Time_Total__c');
                    
                    flds.add('SVMXC__SM_Latitude__c');
                    flds.add('SVMXC__SM_Longitude__c');
                        
                        String whereStr ='';
                        whereStr = ' where (((StartDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime) OR (EndDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime)) OR (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND IsAllDayEvent = true)) and OwnerId IN :SFUSerIds and IsRecurrence = false';

                        lstSalesforceEvents = Database.query('Select Id, Type, ActivityDate, IsAllDayEvent, ActivityDateTime, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from Event ' + whereStr );

                    flds.add('SVMXC__IsAllDayEvent__c');

                    whereStr ='';
                    whereStr = ' where (((SVMXC__StartDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime) OR (SVMXC__EndDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR (SVMXC__ActivityDate__c <= :DEndDate and SVMXC__EndDateTime__c >= :DStartDatetime AND SVMXC__IsAllDayEvent__c = true) OR(SVMXC__StartDateTime__c = :DStartDatetime AND SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c IN :TechnicianIds';
                    lstServiceMaxEvents = Database.query('SELECT Id, SVMXC__Type__c, SVMXC__ActivityDate__c, SVMXC__ActivityDateTime__c,  SVMXC__Technician__c, SVMXC__Technician__r.Name, SVMXC__DurationInMinutes__c, Name, SVMXC__Description__c, SVMXC__WhatId__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c, SVMXC__Location__c, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from SVMXC__SVMX_Event__c  '+whereStr);
                }
                else {
                    lstSalesforceEvents = [Select Id, Type, ActivityDate, ActivityDateTime, 
                                            IsAllDayEvent, OwnerId, DurationInMinutes, Subject, 
                                            Description, WhatId, StartDateTime, EndDateTime, Location, 
                                            LastModifiedDate,SVMXC__Driving_Time__c, 
                                            SVMXC__Overhead_Time_Before__c, SVMXC__Overhead_Time_After__c,
                                            SVMXC__Driving_Time_Home__c, SVMXC__Service_Duration__c,
                                            SVMXC__Break_Time_Total__c,SVMXC__SM_Longitude__c,
                                            SVMXC__SM_Latitude__c from Event 
                                            where (((StartDateTime >= : dtmStartDateTime and 
                                            StartDateTime <= : dtmEndDateTime) OR 
                                            (EndDateTime >= : dtmStartDateTime and 
                                            StartDateTime <= : dtmEndDateTime)) OR 
                                            (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime 
                                            AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND 
                                            IsAllDayEvent = true)) and OwnerId IN :SFUSerIds and 
                                            IsRecurrence = false];

                    lstServiceMaxEvents = [Select Id, SVMXC__Type__c, SVMXC__ActivityDate__c, 
                                            SVMXC__ActivityDateTime__c, SVMXC__Technician__c, 
                                            SVMXC__Technician__r.Name, SVMXC__DurationInMinutes__c, 
                                            Name, SVMXC__Description__c, SVMXC__WhatId__c, 
                                            SVMXC__StartDateTime__c, SVMXC__EndDateTime__c, 
                                            SVMXC__Location__c, LastModifiedDate,SVMXC__Driving_Time__c, 
                                            SVMXC__IsAllDayEvent__c,SVMXC__Overhead_Time_Before__c, 
                                            SVMXC__Overhead_Time_After__c, SVMXC__Driving_Time_Home__c, 
                                            SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,
                                            SVMXC__SM_Longitude__c,SVMXC__SM_Latitude__c from 
                                            SVMXC__SVMX_Event__c where (((SVMXC__StartDateTime__c >= : dtmStartDateTime 
                                            and SVMXC__StartDateTime__c <= : dtmEndDateTime) OR 
                                            (SVMXC__EndDateTime__c >= : dtmStartDateTime and 
                                            SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR 
                                            (SVMXC__ActivityDate__c <= :DEndDate and 
                                            SVMXC__EndDateTime__c >= :DStartDatetime AND
                                            SVMXC__IsAllDayEvent__c = true) OR
                                            (SVMXC__StartDateTime__c = :DStartDatetime AND 
                                            SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c 
                                            IN :TechnicianIds];

                }




                resultSet = mergeEvents(lstSalesforceEvents, lstServiceMaxEvents, UserId, timeZoneDateTimeFormat, isLocal);
                if(resultSet != null && resultSet.size() > 0 ){
                    resultSet.get(resultSet.size()-1).lastSyncedTime = DateTime.now().getTime();
                }
                else{
                    DCX_CommonServiceManager.Events_WP obj = 
                        new DCX_CommonServiceManager.Events_WP();
                    obj.lastSyncedTime = DateTime.now().getTime();
                    resultSet.add(obj);
                }
            }
     
            catch(Exception ex) {
                system.debug(LoggingLevel.WARN, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
                //throw new SVMXException(ex);
            }

            DCxEvents evnt = new DCxEvents(resultSet,'','');
            system.debug(logginglevel.warn,'Event wrapper:: ' + resultSet);
            return evnt;
             
        }

        public static DCxEvents fetchEventsAndWOInfo(String UserId, String StartDate, String EndDate, 
                                                     String EventType, String timeZoneDateTimeFormat, 
                                                     List<String> TechnicianIds)
        {
            SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
            Boolean isLocal = false;
            List<String> SFUSerIds = new List<String>();
            List<String> SVMXUserIds = new List<String>();
            List<Event> lstSalesforceEvents = new List<Event>();
            List<SVMXC__SVMX_Event__c> lstServiceMaxEvents = new List<SVMXC__SVMX_Event__c>();
            set<String> techlst = new set<String>();
            List<DCX_CommonServiceManager.Events_WP> resultSet = 
                new List<DCX_CommonServiceManager.Events_WP>();
            Map<String,String> mapValidSettingsForUpdate = new Map<String,String>();
            Set<String> woSetIds = new Set<String>();
            List<String> woLstIds = new List<String>();
            Map<Id,SVMXC__Service_Order__c> woInfo = new Map<Id,SVMXC__Service_Order__c>();
            String sfQuery;
            Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
            DCX_EventServiceManager_Util eventServiceUtil = new DCX_EventServiceManager_Util();
       //     mapValidSettingsForUpdate = getValidateSettingsFrom38To47();
            set<String> flds = new set<String>();
            try {
                List<String> fieldList = getConfiguredEventFields();
                /*if(fieldList.size() > 0) {
                    if(souObjfieldMapEVT.containsKey())
                        flds.addAll(fieldList);
                }*/
                for(String fName : fieldList) {
                    if(souObjfieldMapEVT.containsKey(fName.toLowerCase())) {
                        flds.add(fName);
                    }
                }
                system.debug('flds :'+flds);
            
                techlst.addAll(TechnicianIds);
                list<string> lstTimeZoneDateTime = new list<string>();
                lstTimeZoneDateTime = timeZoneDateTimeFormat.split('@');
                string timeZone = lstTimeZoneDateTime.get(0);
                lstTimeZoneDateTime.clear();
                isLocal = true;
                  
                //opz  
                //To support more than 14 day event for SF Tech, we are creating SVMX event based on the Config setting.According to the new logic we are retrieving both SF and SVMX Event for a technician
                for(SVMXC__Service_Group_Members__c tl: [Select id, SVMXC__Salesforce_User__c from 
                                                         SVMXC__Service_Group_Members__c where Id 
                                                         IN :techlst]) {
                    //Get all user Id associated with SF tech to retrieve SF event
                    if(tl.SVMXC__Salesforce_User__c != NULL)
                        SFUSerIds.add(tl.SVMXC__Salesforce_User__c);
                } 
               // system.debug('SVMXC__Service_Group_Members__c :'+[Select id, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c where Id IN :techlst]);
                   Date DStartDate = Date.valueOf(StartDate);
                Date DEndDate = Date.valueOf(EndDate);
                Datetime DStartDatetime = Datetime.newInstanceGMT(DStartDate,Time.newInstance(0, 0, 0, 0));

                DateTime dtmStartDateTime = dcUtils.getDateTimeInTimezone(Date.valueOf(StartDate), Time.newInstance(0, 0, 0, 0), UserId);
                DateTime dtmEndDateTime = dcUtils.getDateTimeInTimezone(Date.valueOf(EndDate), Time.newInstance(23, 59, 59, 59), UserId);

                if(fieldList.size() > 0) {
                
                flds.add('SVMXC__Driving_Time__c');
                    flds.add('SVMXC__Overhead_Time_Before__c'); 
                    flds.add('SVMXC__Overhead_Time_After__c'); 
                    flds.add('SVMXC__Driving_Time_Home__c'); 
                    flds.add('SVMXC__Service_Duration__c');
                    flds.add('SVMXC__Break_Time_Total__c');
                    
                    flds.add('SVMXC__SM_Latitude__c');
                    flds.add('SVMXC__SM_Longitude__c');
                        
                        String whereStr ='';
                        whereStr = ' where (((StartDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime) OR (EndDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime)) OR (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND IsAllDayEvent = true)) and OwnerId IN :SFUSerIds and IsRecurrence = false';

                        sfQuery = 'Select Id, Type, ActivityDate, IsAllDayEvent, ActivityDateTime, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from Event ' + whereStr;
                        lstSalesforceEvents = eventServiceUtil.retrieveSFEventsWithParamsUtil(sfQuery,dtmStartDateTime,dtmEndDateTime,DEndDate,DStartDatetime,DStartDate,SFUSerIds);
                        //lstSalesforceEvents = Database.query('Select Id, Type, ActivityDate, IsAllDayEvent, ActivityDateTime, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from Event ' + whereStr );

                    flds.add('SVMXC__IsAllDayEvent__c');

                    whereStr ='';
                    whereStr = ' where (((SVMXC__StartDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime) OR (SVMXC__EndDateTime__c >= : dtmStartDateTime and SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR (SVMXC__ActivityDate__c <= :DEndDate and SVMXC__EndDateTime__c >= :DStartDatetime AND SVMXC__IsAllDayEvent__c = true) OR(SVMXC__StartDateTime__c = :DStartDatetime AND SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c IN :TechnicianIds';
                    lstServiceMaxEvents = Database.query('SELECT Id, SVMXC__Type__c, SVMXC__ActivityDate__c, SVMXC__ActivityDateTime__c,  SVMXC__Technician__c, SVMXC__Technician__r.Name, SVMXC__DurationInMinutes__c, Name, SVMXC__Description__c, SVMXC__WhatId__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c, SVMXC__Location__c, LastModifiedDate,' + SVMX_getFieldNamesFromList(flds) +' from SVMXC__SVMX_Event__c  '+whereStr);
                }
                else {
                    sfQuery = 'Select Id, Type, ActivityDate, ActivityDateTime, IsAllDayEvent, OwnerId, DurationInMinutes, Subject, Description, WhatId, StartDateTime, EndDateTime, Location, LastModifiedDate,SVMXC__Driving_Time__c, SVMXC__Overhead_Time_Before__c, SVMXC__Overhead_Time_After__c, SVMXC__Driving_Time_Home__c, SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,SVMXC__SM_Longitude__c,SVMXC__SM_Latitude__c from Event where (((StartDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime) OR (EndDateTime >= : dtmStartDateTime and StartDateTime <= : dtmEndDateTime)) OR (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND IsAllDayEvent = true)) and OwnerId IN :SFUSerIds and IsRecurrence = false';
                    lstSalesforceEvents = eventServiceUtil.retrieveSFEventsWithParamsUtil(sfQuery,dtmStartDateTime,dtmEndDateTime,DEndDate,DStartDatetime,DStartDate,SFUSerIds);
                    /*lstSalesforceEvents = [Select Id, Type, ActivityDate, ActivityDateTime, 
                                            IsAllDayEvent, OwnerId, DurationInMinutes, Subject, 
                                            Description, WhatId, StartDateTime, EndDateTime, Location, 
                                            LastModifiedDate,SVMXC__Driving_Time__c, 
                                            SVMXC__Overhead_Time_Before__c, SVMXC__Overhead_Time_After__c,
                                            SVMXC__Driving_Time_Home__c, SVMXC__Service_Duration__c,
                                            SVMXC__Break_Time_Total__c,SVMXC__SM_Longitude__c,
                                            SVMXC__SM_Latitude__c from Event 
                                            where (((StartDateTime >= : dtmStartDateTime and 
                                            StartDateTime <= : dtmEndDateTime) OR 
                                            (EndDateTime >= : dtmStartDateTime and 
                                            StartDateTime <= : dtmEndDateTime)) OR 
                                            (ActivityDate <= :DEndDate and EndDateTime >= :DStartDatetime 
                                            AND IsAllDayEvent = true ) OR(ActivityDate = :DStartDate AND 
                                            IsAllDayEvent = true)) and OwnerId IN :SFUSerIds and 
                                            IsRecurrence = false];*/

                    lstServiceMaxEvents = [Select Id, SVMXC__Type__c, SVMXC__ActivityDate__c, 
                                            SVMXC__ActivityDateTime__c, SVMXC__Technician__c, 
                                            SVMXC__Technician__r.Name, SVMXC__DurationInMinutes__c, 
                                            Name, SVMXC__Description__c, SVMXC__WhatId__c, 
                                            SVMXC__StartDateTime__c, SVMXC__EndDateTime__c, 
                                            SVMXC__Location__c, LastModifiedDate,SVMXC__Driving_Time__c, 
                                            SVMXC__IsAllDayEvent__c,SVMXC__Overhead_Time_Before__c, 
                                            SVMXC__Overhead_Time_After__c, SVMXC__Driving_Time_Home__c, 
                                            SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,
                                            SVMXC__SM_Longitude__c,SVMXC__SM_Latitude__c from 
                                            SVMXC__SVMX_Event__c where (((SVMXC__StartDateTime__c >= : dtmStartDateTime 
                                            and SVMXC__StartDateTime__c <= : dtmEndDateTime) OR 
                                            (SVMXC__EndDateTime__c >= : dtmStartDateTime and 
                                            SVMXC__StartDateTime__c <= : dtmEndDateTime)) OR 
                                            (SVMXC__ActivityDate__c <= :DEndDate and 
                                            SVMXC__EndDateTime__c >= :DStartDatetime AND
                                            SVMXC__IsAllDayEvent__c = true) OR
                                            (SVMXC__StartDateTime__c = :DStartDatetime AND 
                                            SVMXC__IsAllDayEvent__c = true)) and SVMXC__Technician__c 
                                            IN :TechnicianIds];

                }




                resultSet = mergeEvents(lstSalesforceEvents, lstServiceMaxEvents, UserId, timeZone, isLocal);
                if(resultSet != null && resultSet.size() > 0 ){
                    resultSet.get(resultSet.size()-1).lastSyncedTime = DateTime.now().getTime();
                    for(DCX_CommonServiceManager.Events_WP ev : resultSet) {
                        if(ev.event_WP.whatId != null) {
                            woSetIds.add(ev.event_WP.whatId);
                        }
                    }
                }
                else{
                    DCX_CommonServiceManager.Events_WP obj = 
                        new DCX_CommonServiceManager.Events_WP();
                    obj.lastSyncedTime = DateTime.now().getTime();
                    resultSet.add(obj);
                }

                if(woSetIds.size() > 0){
                    woLstIds.addAll(woSetIds);
                    woInfo = retrieveWorkOrdersForIds(woLstIds);
                }
            }
            
            catch(Exception ex) {
                system.debug(LoggingLevel.WARN, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
                //throw new SVMXException(ex);
            }

            DCxEvents evnt = new DCxEvents(resultSet,'','');
            evnt.woInfoMap = woInfo;
            system.debug(logginglevel.warn,'Event wrapper:: ' + resultSet);
            return evnt;
             
        }


        public  static  List<DCX_CommonServiceManager.Events_WP> mergeEvents(List<Event> lstSalesforceEvents, List<SVMXC__SVMX_Event__c> lstServiceMaxEvents, String UserId, String timeZone, Boolean isLocal)
        {
      
            string DatetimeFormat;
            Id wId;
            system.debug(LoggingLevel.WARN, 'Count of Salesforce Events: ' + lstSalesforceEvents.size() + '; Events: ' + lstSalesforceEvents);
            system.debug(LoggingLevel.WARN, 'Count of ServiceMax Events: ' + lstServiceMaxEvents.size() + '; Events: ' + lstServiceMaxEvents);
            map<string,string> mapSFIDTechId = new map<string,string>();
            mapSFIDTechId = getmapSFuserTechId(lstSalesforceEvents);// 
             system.debug('mapSFIDTechId :'+mapSFIDTechId);
            SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils();
            string FieldMapRTypeId;
            string RuleRecordTypeId;
            string ExpressionRTypeId;
            Map<String, String> supportNonWorkOrdEvent1 = new Map<String, String>();
          boolean supportNonWorkOrdEvent = true;        
            Map<id, sObject> mapWorkOrder;   
            Map<Id, List<Id>> mapEventHoverRuleIdFieldIdList = new Map<Id, List<Id>>();
            //#DCH-151 SK 20/5/2019
            Map<Id, List<DCX_CommonServiceManager.DCEvent_WP>> mapWorkOrderEvents = 
                new Map<Id, List<DCX_CommonServiceManager.DCEvent_WP>>();
            Map<Id, SVMXC__ServiceMax_Processes__c> mapEventHoverRules  = new Map<Id, SVMXC__ServiceMax_Processes__c>();  
            Map<Id, SVMXC__ServiceMax_Config_Data__c> mapEventHoverFields = new Map<Id, SVMXC__ServiceMax_Config_Data__c>();
            Map<Id, list<SVMXC__ServiceMax_Config_Data__c>> mapEventHoverRuleIdExpr  = new Map<Id, list<SVMXC__ServiceMax_Config_Data__c>>();
            set<String> WOIdsAddedtoResponse = new set<String>();
            List<String> WorkOrderIds = new List<String>();
            List<DCX_CommonServiceManager.Events_WP> resultSet = 
                new List<DCX_CommonServiceManager.Events_WP>();
            List<String> techSalesforceIds = new List <String>();
            Map<Id,String> techSFIdNameMap = new Map<Id,String>();

            for(RecordType recType : [Select SobjectType, Id, Name From RecordType where (SobjectType = 'SVMXC__ServiceMax_Processes__c' AND Name = 'SVMX Rule') OR (SobjectType = 'SVMXC__ServiceMax_Config_Data__c' AND Name IN ('Expressions', 'Field Mapping'))])   
            {
                if(recType.Name == 'SVMX Rule')
                    RuleRecordTypeId = recType.id;
                else if(recType.Name == 'Expressions')
                    ExpressionRTypeId = recType.id;
                else if(recType.Name == 'Field Mapping')
                    FieldMapRTypeId = recType.id;
            }

            try
            {        
               //#DCH-151 SK 20/5/2019        
               // Schema.Describesobjectresult woDefinitions = allObjs.get('Service_Order__c').getDescribe();
                    Schema.Describesobjectresult woDefinitions = SVMXC__Service_Order__c.sObjectType.getDescribe();
                //allObjs.clear();
                set<String> setDateTimeFields = new set<String>();
                set<String> setDateFields = new set<String>();
                set<String> setRefFields = new set<String>();
                Map<String, String> mapWOFieldNameLabel = new Map<String, String>();
                Set<String> setWOQueryFields = new Set<String>();
                setWOQueryFields.add('Id');
                setWOQueryFields.add('Name');
                setWOQueryFields.add('SVMXC__Service_Duration__c');
                setWOQueryFields.add('SVMXC__Driving_Time__c');

                // Get the labels for all the fields of Work Order and put them against field APIName
                Map<String, SObjectField> objWorkOrderFieldMap = Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap();
               // system.debug('objWorkOrderFieldMap: ' +objWorkOrderFieldMap);
                Map<String,Map<String,String>> mapFieldToPckLstValLbl = new Map<String,Map<String,String>>();
                Map<String,String> mapPicklistValLable = new Map<String,String>();
                for (String fieldKey : objWorkOrderFieldMap.keySet())
                {
                    Schema.SObjectField fsObj = objWorkOrderFieldMap.get(fieldKey); 
                    Schema.DescribeFieldResult field = fsObj.getDescribe();
                    if(field.isAccessible())
                    {
                        mapWOFieldNameLabel.put(field.getName(), field.getLabel());
                    }
                    if(String.valueOf(field.getType()) == 'PICKLIST') 
                    {
                        List<Schema.PicklistEntry> plv = field.getPicklistValues();
                        for( Schema.PicklistEntry f : plv)
                        {
                            mapPicklistValLable.put(f.getValue(),f.getLabel());
                        }
                        mapFieldToPckLstValLbl.put(fieldKey,mapPicklistValLable);
                    }
                }

                DCX_Utils.referenceFields_WP reference_M = dcUtils.SVMX_getReferenceFields(objWorkOrderFieldMap,true);
                objWorkOrderFieldMap.clear();
                List<String> allFields_L = reference_M.allFields_L; //Get the all field list
                List<String> refFields_L = reference_M.referenceFields_L; //Get the reference field list
                List<String> dateTimeFields_L = reference_M.dateTimeFields_L; //Get the dateTime field list
                List<String> dateFields_L = reference_M.dateFields_L; //Get the date field list
                Map<String,String> replacementRef = reference_M.replacementReference_M;  //Get the replacement reference field map
                Map<String,String> replacementNameField = reference_M.replacementField_M;  //Get the name field for reference map

                setDateTimeFields.addAll(dateTimeFields_L);
                setDateFields.addAll(dateFields_L);
                setRefFields.addAll(refFields_L);        
               Map<String, String> mapEventSettings = new Map<String, String>();
               Map<String,String> mapValidSettingsForUpdate =getConfiguredEventFieldsSET38To47();
                // Get the custom Event fields to be displayed in Event Create/Edit window, from DCON001 SET038 to SET047
               
               // Map<string, string>  set062 = getConfiguredEventFieldsSET062();
                // Get setting value to support Non-Work Order event
            //    if(set062 != NULL && set062('SET062') && DCON_Event_WS.svmxSettingList.get('SET062') != NULL)
            //COMM_Utils_ManageSettings util1 = new COMM_Utils_ManageSettings();
                    supportNonWorkOrdEvent1=COMM_Utils_ManageSettings.SVMX_getuniqueSettingValue('DCON001','SET062');//getConfiguredEventFieldsSET062();
                    
                
                Map<String,String> EVTFieldDef = new Map<String,String>();
                Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
                EVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapEVT);
                souObjfieldMapEVT.clear();

                Map<String,String> SVMXEVTFieldDef = new Map<String,String>();
                Map<String, SObjectField> souObjfieldMapSVMXEVT = Schema.SObjectType.SVMXC__SVMX_Event__c.fields.getMap();
                SVMXEVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapSVMXEVT);
                souObjfieldMapSVMXEVT.clear();
                Map<String, String> mapWOSettings = new Map<String, String>();
                // Get WO and event fields to be displayed in Event Create/Edit window, from DCON001 SET038 to SET047
                //mapEventSettings;//mapEventSettings;//getConfiguredEventFields_2();
                system.debug('mapValidSettingsForUpdate : '+mapValidSettingsForUpdate);
                // Get WO fields to be displayed in Event Create/Edit window
             // Map<String,String> mapValidSettingsForUpdate1 =getConfiguredEventFields_2();//mapEventSettings;//mapEventSettings;//getConfiguredEventFields_2();
               //  system.debug('mapValidSettingsForUpdate1 : '+mapValidSettingsForUpdate1);
                if(mapValidSettingsForUpdate.keySet().size() > 0)
                {
                    for(String strfld : mapValidSettingsForUpdate.keySet())
                    {
                        if((mapValidSettingsForUpdate.containsKey(strfld)) &&(!String.valueOf(mapValidSettingsForUpdate.get(strfld)).contains('Event.')))
                        {
                            mapWOSettings.put(strfld, mapValidSettingsForUpdate.get(strfld));
                        }

                      if((mapValidSettingsForUpdate.containsKey(strfld)) &&(String.valueOf(mapValidSettingsForUpdate.get(strfld)).contains('Event.')))
                        {
                             List<String> Evtfield = String.valueOf(mapValidSettingsForUpdate.get(strfld)).split('Event.',2);
                  //  EvtobjFieldRes = EventFields.get(Evtfield[1]);
                 //   SvmxEvtobjFieldRes = ServiceMaxEventFields.get(Evtfield[1]);
                            mapEventSettings.put(strfld, Evtfield[1]);
                        }

                        

                    }
                }

                // Process Salesforce events
                for (Event ev : lstSalesforceEvents) {
                    techSalesforceIds.add(ev.OwnerId);
                }

                if(techSalesforceIds.size() > 0) {
                    for (SVMXC__Service_Group_Members__c tcDt : [Select Id, Name, 
                                                                SVMXC__Salesforce_User__c from 
                                                                SVMXC__Service_Group_Members__c 
                                                                where SVMXC__Salesforce_User__c
                                                                In :techSalesforceIds])
                        techSFIdNameMap.put(tcDt.SVMXC__Salesforce_User__c,tcDt.Name);
                }

                for(Event e: lstSalesforceEvents)
                {
                    DCX_CommonServiceManager.DCEvent_WP event_TWO = 
                        new DCX_CommonServiceManager.DCEvent_WP();
                    event_TWO.description = CheckNull(e.Description);
                    event_TWO.IsAllDayEvent = e.IsAllDayEvent;
                    event_TWO.durationInMinutes = CheckNull(String.valueof(e.DurationInMinutes));
                    // This is the change due to the introduction of new fields in event objects
                    // To make the event management smooth
                    event_TWO.Driving_Time = CheckNull(String.valueof(e.SVMXC__Driving_Time__c));
                    event_TWO.Overhead_Time_Before = CheckNull(String.valueof(e.SVMXC__Overhead_Time_Before__c));
                    event_TWO.Overhead_Time_After = CheckNull(String.valueof(e.SVMXC__Overhead_Time_After__c));
                    event_TWO.Driving_Time_Home = CheckNull(String.valueof(e.SVMXC__Driving_Time_Home__c));
                    event_TWO.Service_Duration = CheckNull(String.valueof(e.SVMXC__Service_Duration__c));
                    event_TWO.Break_Time_Total = CheckNull(String.valueof(e.SVMXC__Break_Time_Total__c));
                    event_TWO.id = e.Id;
                    event_TWO.ownerId = CheckNull(e.ownerId);
                    event_TWO.techName = techSFIdNameMap.get(e.OwnerId);
                    
                    if(mapSFIDTechId.containsKey(e.ownerId))
                        event_TWO.TechId = mapSFIDTechId.get(e.ownerId);
                    
                    event_TWO.subject = CheckNull(e.Subject);
                    event_TWO.lastModifiedDateTime = e.LastModifiedDate;
                    event_TWO.location = CheckNull(e.location); 

                    //Defect# 014336 - added 'Type' field
                    event_TWO.Type = CheckNull(e.Type);
                    
                    if(e.SVMXC__SM_Latitude__c == null)
                        {
                            event_TWO.latitude = 'undefined';
                        }
                    else
                        {
                            event_TWO.latitude = String.valueOf(e.SVMXC__SM_Latitude__c);
                        }   
                    if(e.SVMXC__SM_Longitude__c == null)
                        {
                            event_TWO.longitude = 'undefined';  
                        }
                    else
                        {
                            event_TWO.longitude = String.valueOf(e.SVMXC__SM_Longitude__c);
                        }

                    //To support non Work Order event, set whatId to null.

                    if(supportNonWorkOrdEvent== true && e.WhatId != NULL)
                    {
                        //Pavitra : Add additional checks to identify the non-WO
                        if(String.valueof(e.WhatId).startsWith(woDefinitions.getKeyPrefix()) == false)
                        {                       
                            if(isSplRelatedHandling == false|| (isSplRelatedHandling == true && setApiName != null && setApiName.size()> 0 && !setApiName.contains(String.valueOf((Id.ValueOf(e.WhatId).getsobjectType())))))
                                event_TWO.additionalInfo = 'SVMX.NONWO';
                            else
                                event_TWO.additionalInfo = '';
                            
                            e.WhatId = NULL;    
                        } 
                        else
                        {
                            event_TWO.additionalInfo = '';                             
                            // nothing, it should be considered NonWork order, with no association                      
                        }
                    }
                    else
                    {
                        event_TWO.additionalInfo = '';
                    }
                    event_TWO.whatId = CheckNull(e.WhatId);     
                          

                    // Format the datetime in fixed 'MM/dd/yyyy hh:mm a' format, but in applicable time zone
                    // Because, Flex needs the date time string to be in this format
                    if(e.IsAllDayEvent)
                    {
                        if(e.StartDateTime != NULL)
                        {
                            event_TWO.startDateTime = e.StartDateTime.formatGMT('MM/dd/yyyy hh:mm a');
                            if(e.DurationInMinutes != NULL)
                            {
                                event_TWO.endDateTime = e.StartDateTime.addMinutes(Integer.valueof(e.DurationInMinutes)).formatGMT('MM/dd/yyyy hh:mm a');
                            }
                        }
                    }
                    else
                    {
                        if(e.StartDateTime != NULL)
                        {
                            event_TWO.startDateTime = e.StartDateTime.format('MM/dd/yyyy hh:mm a', timeZone);
                            if(e.DurationInMinutes != NULL)
                            {
                                event_TWO.endDateTime = e.StartDateTime.addMinutes(Integer.valueof(e.DurationInMinutes)).format('MM/dd/yyyy hh:mm a', timeZone);
                            }
                        }
                    }

                    // If there are custom Event fields to be displayed in Event Create/Edit window, add their values
                    if(mapEventSettings.keySet().size() > 0)
                    {
                        List<DCX_CommonServiceManager.KeyValuePair_WP> lstEvtKeyVal = 
                            new List<DCX_CommonServiceManager.KeyValuePair_WP>();
                        for(String strCurrentSetting : mapEventSettings.keySet())
                        {
                            if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && EVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && EVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATETIME')
                            {                                              
                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null ) 
                                {               
                                    if(isLocal == true)
                                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(e.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a')));

                                    else                            
                                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(e.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a', timeZone)));

                                }
                            }
                            else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && EVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && EVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATE')
                            {

                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null )         
                                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, Date.valueof(e.get(mapEventSettings.get(strCurrentSetting))).format()));
                            }
                            else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'TIME')
                            {
                                //23:10:00.000Z

                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null )   {
                                    List<String> lt = String.valueOf(e.get(mapEventSettings.get(strCurrentSetting))).split(':');
                                    String st = String.valueOf(lt[0])+':'+String.valueOf(lt[1]);
                                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, st));

                                }      
                            }
                            else 
                                lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, String.valueOf(e.get(mapEventSettings.get(strCurrentSetting)))));                                   
                        }
                        event_TWO.lstKeyValuePair = lstEvtKeyVal;
                        System.debug(logginglevel.warn,' Event Key Val'+lstEvtKeyVal);
                    }  
                    // Check What Id, and if Work Order, set the IsWorkOrder Flag
                    if(e.WhatId != NULL)
                    {
                        if(String.valueof(e.WhatId).startsWith(woDefinitions.getKeyPrefix()) == true)
                        {
                            event_TWO.isWorkOrder = true;
                            WorkOrderIds.add(e.WhatId);

                            List<DCX_CommonServiceManager.DCEvent_WP> lstEventWP = 
                                new List<DCX_CommonServiceManager.DCEvent_WP>();
                            lstEventWP.add(event_TWO);
                            if(mapWorkOrderEvents.get(e.WhatId) != NULL)
                                lstEventWP.addAll(mapWorkOrderEvents.get(e.WhatId));
                            mapWorkOrderEvents.put(e.WhatId, lstEventWP);
                        } 
                        //To support the setting based non-associated event identification
                        else 
                        {
                            If(isSplRelatedHandling == false|| (isSplRelatedHandling == true && setApiName != null && setApiName.size()> 0 && !setApiName.contains(String.valueOf((Id.ValueOf(e.WhatId).getsobjectType())))))
                            {
                                event_TWO.isWorkOrder = false;
                                DCX_CommonServiceManager.Events_WP event_TWP = 
                                    new DCX_CommonServiceManager.Events_WP(event_TWO);
                                resultSet.add(event_TWP); 
                            }
                            else 
                            {
                                // nothing, it should be considered as NonWork order, with no association
                            }
                        }
                    }
                    else
                    {
                        event_TWO.isWorkOrder = false;
                        DCX_CommonServiceManager.Events_WP event_TWP = 
                            new DCX_CommonServiceManager.Events_WP(event_TWO);
                        resultSet.add(event_TWP);
                    }
                }
                EVTFieldDef.clear();
                techSFIdNameMap.clear();
                techSalesforceIds.clear();

                // Process ServiceMax events
                for(SVMXC__SVMX_Event__c e: lstServiceMaxEvents)
                {
                    DCX_CommonServiceManager.DCEvent_WP event_TWO = 
                        new DCX_CommonServiceManager.DCEvent_WP();
                    event_TWO.description = CheckNull(e.SVMXC__Description__c);
                    event_TWO.IsAllDayEvent = e.SVMXC__IsAllDayEvent__c;
                    event_TWO.durationInMinutes = CheckNull(String.valueof(e.SVMXC__DurationInMinutes__c));
                    // This is the change due to the introduction of new fields in event objects
                    event_TWO.Driving_Time = CheckNull(String.valueof(e.SVMXC__Driving_Time__c));
                    event_TWO.Overhead_Time_Before = CheckNull(String.valueof(e.SVMXC__Overhead_Time_Before__c));
                    event_TWO.Overhead_Time_After = CheckNull(String.valueof(e.SVMXC__Overhead_Time_After__c));
                    event_TWO.Driving_Time_Home = CheckNull(String.valueof(e.SVMXC__Driving_Time_Home__c));
                    event_TWO.Service_Duration = CheckNull(String.valueof(e.SVMXC__Service_Duration__c));
                    event_TWO.Break_Time_Total = CheckNull(String.valueof(e.SVMXC__Break_Time_Total__c));                
                    event_TWO.id = e.Id;
                    event_TWO.ownerId = CheckNull(e.SVMXC__Technician__c);
                    event_TWO.TechId = CheckNull(e.SVMXC__Technician__c);
                    event_TWO.subject = CheckNull(e.Name);
                    event_TWO.lastModifiedDateTime = e.LastModifiedDate;
                    event_TWO.location = CheckNull(e.SVMXC__Location__c);

                    //Defect# 014336 - added 'Type' field
                    event_TWO.Type = CheckNull(e.SVMXC__Type__c);
                    event_TWO.techName = CheckNull(e.SVMXC__Technician__r.Name);
                    
                    if(e.SVMXC__SM_Latitude__c == null)
                        {
                            event_TWO.latitude = 'undefined';
                        }
                    else
                        {
                            event_TWO.latitude = String.valueOf(e.SVMXC__SM_Latitude__c);
                        }   
                    if(e.SVMXC__SM_Longitude__c == null)
                        {
                            event_TWO.longitude = 'undefined';  
                        }
                    else
                        {
                            event_TWO.longitude = String.valueOf(e.SVMXC__SM_Longitude__c);
                        }

                    //To support non Work Order event, set whatId to null.
                    if(supportNonWorkOrdEvent == true && e.SVMXC__WhatId__c != NULL)
                    {
                        if(String.valueof(e.SVMXC__WhatId__c).startsWith(woDefinitions.getKeyPrefix()) == false)
                        {
                            if(isSplRelatedHandling == false|| (isSplRelatedHandling == true && setApiName != null && setApiName.size()> 0 && !setApiName.contains(String.valueOf((Id.ValueOf(e.SVMXC__WhatId__c).getsobjectType())))))
                            {
                                event_TWO.additionalInfo = 'SVMX.NONWO';
                            }
                            else
                            {
                                event_TWO.additionalInfo = '';
                                // nothing, it should be considered NonWork order, with no association
                            }
                            e.SVMXC__WhatId__c = NULL;
                        }
                    }
                    else
                    {
                        event_TWO.additionalInfo = '';
                    }
                    if(e.SVMXC__WhatId__c != null) {
                        wId = e.SVMXC__WhatId__c;
                        event_TWO.whatId = wId;
                        
                    }
                    
                    if(e.SVMXC__IsAllDayEvent__c)
                    {
                        if(e.SVMXC__StartDateTime__c != NULL)
                        {
                            event_TWO.startDateTime = e.SVMXC__StartDateTime__c.formatGMT('MM/dd/yyyy hh:mm a');
                            if(e.SVMXC__DurationInMinutes__c != NULL)
                            {
                                event_TWO.endDateTime = e.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(e.SVMXC__DurationInMinutes__c)).formatGMT('MM/dd/yyyy hh:mm a');
                            }
                        }
                    }
                    else if(e.SVMXC__StartDateTime__c != NULL) {
                            event_TWO.startDateTime = e.SVMXC__StartDateTime__c.format('MM/dd/yyyy hh:mm a', timeZone);
                            if(e.SVMXC__DurationInMinutes__c != NULL)
                            {
                                event_TWO.endDateTime = e.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(e.SVMXC__DurationInMinutes__c)).format('MM/dd/yyyy hh:mm a', timeZone);
                            }
                    }
                                
                    // If there are custom Event fields to be displayed in Event Create/Edit window, add their values
                    if(mapEventSettings.keySet().size() > 0)
                    {
                        List<DCX_CommonServiceManager.KeyValuePair_WP> lstEvtKeyVal = 
                            new List<DCX_CommonServiceManager.KeyValuePair_WP>();
                        for(String strCurrentSetting : mapEventSettings.keySet())
                        {
                            if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATETIME')
                            {
                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null ) 
                                {               
                                    if(isLocal == true)
                                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(e.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a')));

                                    else                            
                                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(e.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a', timeZone)));

                                }
                            }
                            else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATE')
                            {

                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null )         
                                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, Date.valueof(e.get(mapEventSettings.get(strCurrentSetting))).format()));
                            }
                            else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'TIME')
                            {
                                //23:10:00.000Z

                                if( e.get(mapEventSettings.get(strCurrentSetting)) != null )   {
                                    List<String> lt = String.valueOf(e.get(mapEventSettings.get(strCurrentSetting))).split(':');
                                    String st = String.valueOf(lt[0])+':'+String.valueOf(lt[1]);
                                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, st));

                                }      
                            }
                            else 
                                lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, String.valueOf(e.get(mapEventSettings.get(strCurrentSetting)))));
                        }
                        event_TWO.lstKeyValuePair = lstEvtKeyVal;
                        System.debug(logginglevel.warn,' Event Key Val'+lstEvtKeyVal);
                    }
                    //mapEventSettings.clear();

                    // Check What Id, and if Work Order, set the IsWorkOrder Flag
                    if(e.SVMXC__WhatId__c != NULL)
                    {
                        if(String.valueof(e.SVMXC__WhatId__c).startsWith(woDefinitions.getKeyPrefix()) == true)
                        {
                            event_TWO.isWorkOrder = true;
                            WorkOrderIds.add(e.SVMXC__WhatId__c);

                            List<DCX_CommonServiceManager.DCEvent_WP> lstEventWP = 
                                new List<DCX_CommonServiceManager.DCEvent_WP>();
                            lstEventWP.add(event_TWO);
                            if(mapWorkOrderEvents.get(e.SVMXC__WhatId__c) != NULL)
                                lstEventWP.addAll(mapWorkOrderEvents.get(e.SVMXC__WhatId__c));
                            mapWorkOrderEvents.put(e.SVMXC__WhatId__c, lstEventWP);
                        }
                        //To support the setting based non-associated event identification
                        else 
                        {
                            if(isSplRelatedHandling == true && setApiName != null && setApiName.size()> 0 && setApiName.contains(String.valueOf((Id.ValueOf(e.SVMXC__WhatId__c).getsobjectType()))))
                            {
                                event_TWO.isWorkOrder = false;
                                DCX_CommonServiceManager.Events_WP event_TWP = 
                                    new DCX_CommonServiceManager.Events_WP(event_TWO);
                                resultSet.add(event_TWP); 
                            }
                            else 
                            {
                                // nothing, it should be considered NonWork order, with no association
                            }
                        }
                    }
                    else
                    {
                        event_TWO.isWorkOrder = false;
                        DCX_CommonServiceManager.Events_WP event_TWP = 
                            new DCX_CommonServiceManager.Events_WP(event_TWO);
                        resultSet.add(event_TWP);
                    }
                }     
                //30476
                mapEventSettings.clear();
         
 /*mapWorkOrder = new Map<id, SVMXC__Service_Order__c>();
 for(String fieldName : allFields_L)
                {
                    // Add the name fields for the reference fields
                    if(fieldName.contains('.'))
                    {
                        if(setWOQueryFields.contains(fieldName.split('\\.',2)[0].replace('__r','__c')))
                            setWOQueryFields.add(fieldName);
                        else if((fieldName == 'Owner.Name' && setWOQueryFields.contains('OwnerId')) || (fieldName == 'CreatedBy.Name' && setWOQueryFields.contains('CreatedById')) || (fieldName == 'LastModifiedBy.Name' && setWOQueryFields.contains('LastModifiedById')) || (fieldName == 'RecordType.Name' && setWOQueryFields.contains('RecordTypeId')))
                            setWOQueryFields.add(fieldName);
                    }
                }*/
               /* setWOQueryFields.addall(mapWOSettings.values());
                setWOQueryFields.retainAll(allFields_L);
                String querySelect = SVMX_getFieldNamesFromList(setWOQueryFields);
                system.debug('querySelect :'+querySelect );
                system.debug('mapWOSettings :'+mapWOSettings );
                system.debug('WorkOrderIds :'+WorkOrderIds );
                map<string, list<KeyValuePair_WP>> mapWOIdUpdateKeyVal = new map<string, list<KeyValuePair_WP>>();
t10 = DateTime.now().getTime();
system.debug('querySelect '+querySelect);
system.debug('mapWOSettings'+mapWOSettings);
                for(SVMXC__Service_Order__c wo: Database.query('SELECT ' + querySelect + ' FROM SVMXC__Service_Order__c WHERE Id IN:WorkOrderIds')) 
                {
                    mapWorkOrder.put(wo.Id, (sObject)wo);
                    if(mapWOSettings.size() > 0)
                    {
                        List<KeyValuePair_WP> lstWOUpdateFieldKeyVal = new List<KeyValuePair_WP>();
                        List<KeyValuePair_WP> lstWOKeyVal = new List<KeyValuePair_WP>();
                        for(String strCurrentSetting : mapWOSettings.keySet())
                        {
system.debug('mapWOSettings key'+mapWOSettings.keySet());
system.debug('strCurrentSetting '+strCurrentSetting);
                            //If the field is datetime field, it has to be  converted globes timezone if it is other than logged in user timezone
                            if(mapWOSettings.containskey(strCurrentSetting) && mapWOSettings.get(strCurrentSetting) != null && setDateTimeFields.contains(mapWOSettings.get(strCurrentSetting)))
                            {

                                if( wo.get(mapWOSettings.get(strCurrentSetting)) != null )
                                {
                                system.debug('wo.get(mapWOSettings.get(strCurrentSetting))' +wo.get(mapWOSettings.get(strCurrentSetting)));
                                    if(isLocal == true)
                                        lstWOKeyVal.add(new KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(wo.get(mapWOSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a')));

                                    else
                                        lstWOKeyVal.add(new KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(wo.get(mapWOSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a', timeZone)));
                                }
                            }
                        }
                        lstWOUpdateFieldKeyVal.addall(lstWOKeyVal);
                        mapWOIdUpdateKeyVal.put(wo.id,lstWOUpdateFieldKeyVal);
                        System.debug(logginglevel.warn,' WO Key Val'+lstWOUpdateFieldKeyVal);
                    }
                }*/
             /*   WorkOrderIds.clear();
                System.debug(logginglevel.warn,' mapWOIdUpdateKeyVal'+mapWOIdUpdateKeyVal);
t11 = DateTime.now().getTime();                
                for(id idWorkOrder : mapWorkOrderEvents.keySet())
                {
                    if(mapWorkOrderEvents.get(idWorkOrder) != NULL)
                    {
                        list<DCEvent_WP> lstDCEvent_WP = new list<DCEvent_WP>();
                        for(DCEvent_WP event: mapWorkOrderEvents.get(idWorkOrder))
                        {                    
                            if( event.lstKeyValuePair == null && mapWOIdUpdateKeyVal.get(idWorkOrder) != null)
                                event.lstKeyValuePair = mapWOIdUpdateKeyVal.get(idWorkOrder);
                            else if( mapWOIdUpdateKeyVal.get(idWorkOrder) != null)
                                event.lstKeyValuePair.addAll(mapWOIdUpdateKeyVal.get(idWorkOrder));                    
                            lstDCEvent_WP.add(event);
                            mapWorkOrderEvents.put(idWorkOrder,lstDCEvent_WP);
                        }
                    }
                }    */ 
              /*  system.debug(LoggingLevel.WARN, 'Size of mapWorkOrder: ' + mapWorkOrder.size() + '; Map: ' + mapWorkOrder);  
                for(Id idWorkOrder: mapWorkOrder.keySet())
                {
                   // if(!mapWOIdEventHoverRuleId.containsKey(idWorkOrder))
                   // {
                        if(mapWorkOrderEvents.get(idWorkOrder) != NULL)
                        {
                            for(DCEvent_WP event: mapWorkOrderEvents.get(idWorkOrder))
                            {
                                Events_WP event_TWP = new Events_WP(event);
                                sObject objWO = mapWorkOrder.get(idWorkOrder);
                                List<KeyValuePair_WP> lstWorkOrderKeyVal = new List<KeyValuePair_WP>();
                                
                                if(objWO.get('Name') != NULL)
                                {
                                    lstWorkOrderKeyVal.add(new KeyValuePair_WP('FIELDVALUE', 'Name', String.valueOf(objWO.get('Name'))));
                                }
                                if(objWO.get('SVMXC__Service_Duration__c') != NULL)
                                {
                                    lstWorkOrderKeyVal.add(new KeyValuePair_WP('FIELDVALUE', 'SVMXC__Service_Duration__c', String.valueOf(objWO.get('SVMXC__Service_Duration__c'))));
                                }
                                if(objWO.get('SVMXC__Driving_Time__c') != NULL)
                                {
                                    lstWorkOrderKeyVal.add(new KeyValuePair_WP('FIELDVALUE', 'SVMXC__Driving_Time__c', String.valueOf(objWO.get('SVMXC__Driving_Time__c'))));
                                }

                              //  if(event_TWP.event_WP.lstKeyValuePair == null)
                               // {
                               // system.debug('inside if'+lstWorkOrderKeyVal);
                                    event_TWP.event_WP.lstKeyValuePair = lstWorkOrderKeyVal;
                            
                                
                                resultSet.add(event_TWP);
                                WOIdsAddedtoResponse.add(idWorkOrder);
                            }
                        }
                  //  }
                }*/
                /*(Defect # 011533 ) : There may be a case when there will be a set of Events wrapper (event_TWP)in the
                    mapWorkOrderEvents which has not been added to the resultSet. 
                    This happens because the associated WO has been deleted, but having events
                    which needs to be plotted - This functionality will be removed, when PM 
                    confirms about 'no child events for deleted Parent WO' */
                for(String WOId:mapWorkOrderEvents.keyset())
                {
                    if(!WOIdsAddedtoResponse.contains(WOId))
                    {
                        for(DCX_CommonServiceManager.DCEvent_WP event: mapWorkOrderEvents.get(WOId))
                        {
                            DCX_CommonServiceManager.Events_WP event_TWP = 
                                new DCX_CommonServiceManager.Events_WP(event);
                            resultSet.add(event_TWP);
                        }
                    }
                }  

            }
            catch(Exception ex)
            {
                system.debug(LoggingLevel.WARN, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
               // throw new SVMXException(ex);
            }
            
            system.debug(LoggingLevel.WARN,'resultSet: '+resultSet); 


            return resultSet;
        }

         public  static Map<String,String> getEvtandWofields()
    {
        Map<String,String> mapValidSettings = getConfiguredEventFieldsSET38To47();
        system.debug(LoggingLevel.WARN, 'Map of settings defining Work Order & Event fields to be updated in DC Event window: ' + mapValidSettings);
        Map<String,String> mapValidSettingsForUpdate = new Map<String,String>();
        Map<String,Schema.DescribeFieldResult> EventFields = new Map<String,Schema.DescribeFieldResult>();
        Map<String,Schema.DescribeFieldResult> ServiceMaxEventFields = new Map<String,Schema.DescribeFieldResult>();        
        Map<String,Schema.SObjectField> EventfieldMapping = Event.sObjectType.getDescribe().fields.getMap();
        for(Schema.SObjectField fieldMap: EventfieldMapping.values()){
            Schema.DescribeFieldResult Eventfield = fieldMap.getDescribe();
            if(Eventfield.isUpdateable() && Eventfield.isCustom())
                EventFields.put(Eventfield.getName(),Eventfield);
        }
        EventfieldMapping.clear();

        //Schema.SObjectType objTSVMXEvent = allObjs.get('SVMX_Event__c') ;
        Schema.SObjectType objTSVMXEvent = SVMX_Event__c.sObjectType;
        Map<String,Schema.SObjectField> SVMXEventfieldMapping = objTSVMXEvent.getDescribe().fields.getMap();
        for(Schema.SObjectField fieldMap: SVMXEventfieldMapping.values()){
            Schema.DescribeFieldResult SVMXEventfield = fieldMap.getDescribe();
            if(SVMXEventfield.isUpdateable() && SVMXEventfield.isCustom())
                ServiceMaxEventFields.put(SVMXEventfield.getName(),SVMXEventfield);
        }
        Schema.DescribeFieldResult EvtobjFieldRes;
        Schema.DescribeFieldResult SvmxEvtobjFieldRes;

        if(mapValidSettings.keySet().size() > 0)
        {
            for(String strfld : mapValidSettings.keySet())
            {
                if((mapValidSettings.containsKey(strfld)) && (String.valueOf(mapValidSettings.get(strfld)).contains('Event.')))
                {
                    List<String> Evtfield = String.valueOf(mapValidSettings.get(strfld)).split('Event.',2);
                    EvtobjFieldRes = EventFields.get(Evtfield[1]);
                    SvmxEvtobjFieldRes = ServiceMaxEventFields.get(Evtfield[1]);

                    if((EventFields.ContainsKey(Evtfield[1]) && ServiceMaxEventFields.ContainsKey(Evtfield[1])) && ((EvtobjFieldRes.getType() == SvmxEvtobjFieldRes.getType())) && ((EvtobjFieldRes.getLength() == SvmxEvtobjFieldRes.getLength())))
                    {
                        mapValidSettingsForUpdate.put(strfld,mapValidSettings.get(strfld));
                    }
                }
                else
                {
                    mapValidSettingsForUpdate.put(strfld,mapValidSettings.get(strfld));
                }    
            }
        }

        return mapValidSettingsForUpdate;
    }

    public static List<String> getConfiguredEventFields() {
        List<String> flds = new List<String>();
        //COMM_Utils_ManageSettings util = new COMM_Utils_ManageSettings();
        Map<String, String> fldMap = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET038','SET047',null);
        
        for(String fld : fldMap.values()) {
            if(fld.contains('Event.')) {
                List<String> evtField = fld.split('Event.', 2);
                flds.add(evtField[1]);
            }
        }
        return flds;
    }

    public static Set<String> getConfiguredEventFields(Map<String, String> fldMap) {
        Set<String> flds = new Set<String>();
        
        for(String fld : fldMap.values()) {
            if(fld.contains('Event.')) {
                List<String> evtField = fld.split('Event.', 2);
                flds.add(evtField[1]);
            }
        }
        return flds;
    }

    public class TechEvent_WP
    {
        list<Event> lstSFEvent = new  list<Event>();
        list<SVMXC__SVMX_Event__c> lstSVMXEvent = new  list<SVMXC__SVMX_Event__c>();
    }

    public static void checkDoublebookingforTech(List<Event> lstEvent, String timeZone, String SFuserPrefix, Map<String, String> svmxSettingList)
    {
        DCON_Utils dcUtils = new DCON_Utils();
        if(lstEvent== null ||lstEvent.size() == 0)
            return;
        
            System.debug(logginglevel.error,'Input '+lstEvent +' ' + timeZone + ' '+SFuserPrefix);
            //WSCH_AuditLogger.debug('Input '+lstEvent +' ' + timeZone + ' '+SFuserPrefix);
            //WSCH_AuditLogger.debug('svmxSettingList '+svmxSettingList);
            //If false, check while WO Scheduling for all events
            if(svmxSettingList.containsKey('DCON001_SET026') && 
                svmxSettingList.get('DCON001_SET026').toUpperCase()=='FALSE')
            {                
                TechEvent_WP ObjExistingSFSVMXEvents = new TechEvent_WP();
                //Getting Existing SF and SVMX Event for given Event list to be created or updated
                ObjExistingSFSVMXEvents = GetExistingSFSVMXEvents(lstEvent,timeZone,SFuserPrefix);
                System.debug(logginglevel.error,'ObjExistingSFSVMXEvents '+ObjExistingSFSVMXEvents);//WSCH_AuditLogger.debug('ObjExistingSFSVMXEvents '+ObjExistingSFSVMXEvents);             
                //To check whether it is a work order related event or not- only WO events  
                if(svmxSettingList.containsKey('DCON001_SET028') && 
                    svmxSettingList.get('DCON001_SET028').toUpperCase()=='TRUE')
                {
                    //Display Error if double bookings are there
                    findOverlappingEvents(getmapTechEvent(getWOEvents(ObjExistingSFSVMXEvents.lstSFEvent),getWOEvents(ObjExistingSFSVMXEvents.lstSVMXEvent)),lstEvent,SFuserPrefix,timeZone);
                }
                else
                {
                    //Display Error if double bookings are there
                    findOverlappingEvents(getmapTechEvent(ObjExistingSFSVMXEvents.lstSFEvent,ObjExistingSFSVMXEvents.lstSVMXEvent),lstEvent,SFuserPrefix,timeZone);
                }
                
            }
            //If true, check while WO Scheduling for only work order objects
            if(svmxSettingList.containsKey('DCON001_SET026') && 
                (svmxSettingList.get('DCON001_SET026').toUpperCase()=='TRUE'))
            {
                //Getting only WO Events 
                lstEvent = getWOEvents(lstEvent);           
                TechEvent_WP ObjExistingSFSVMXEvents = new TechEvent_WP();
                //Getting Existing SF and SVMX Event overlapping with Given Event list to be created or updated
                if(lstEvent.size() > 0)
                {
                    ObjExistingSFSVMXEvents = GetExistingSFSVMXEvents(lstEvent,timeZone, SFuserPrefix);
                    System.debug(logginglevel.error,'ObjExistingSFSVMXEvents '+ObjExistingSFSVMXEvents);
                    //WSCH_AuditLogger.debug('ObjExistingSFSVMXEvents '+ObjExistingSFSVMXEvents);             
                    if(svmxSettingList.containsKey('DCON001_SET028') && 
                        svmxSettingList.get('DCON001_SET028').toUpperCase()=='TRUE')
                    {
                        //Display Error if double bookings are there
                        findOverlappingEvents(getmapTechEvent(getWOEvents(ObjExistingSFSVMXEvents.lstSFEvent),getWOEvents(ObjExistingSFSVMXEvents.lstSVMXEvent)),lstEvent, SFuserPrefix,timeZone);
                    }
                    else
                    {
                        //Display Error if double bookings are there
                        findOverlappingEvents(getmapTechEvent(ObjExistingSFSVMXEvents.lstSFEvent,ObjExistingSFSVMXEvents.lstSVMXEvent),lstEvent,SFuserPrefix,timeZone);
                    }
                }
            }
        //WSCH_AuditLogger.finish();

    }

    public static void findOverlappingEvents(map<String ,TechEvent_WP> mapTechidEvent,List<Event> lstEvent,String sFUserPrefix,String timeZone)
    {
        //WSCH_AuditLogger.debug('mapTechidEvent  '+mapTechidEvent);
        List<String> lstStrOverlappingEventDetails = new List<String>();
        boolean isDoubleBooked = false;
        try
        {
            for(Event objEvent: lstEvent)
            {   
            
                           
                if(objEvent.OwnerId != null && String.valueof(objEvent.OwnerId).startsWith(sFUserPrefix) == true && 
                mapTechidEvent.containskey(getTechId(objEvent.OwnerId)))
                {
                    // Checking overlapping SF Events 
                    lstStrOverlappingEventDetails.addall(getOverlappingEventDetails(objEvent, mapTechidEvent.get(getTechId(objEvent.OwnerId)),timeZone));
                    //WSCH_AuditLogger.debug('mapTechidEvent.get(getTechId(objEvent.OwnerId)) '+mapTechidEvent.get(getTechId(objEvent.OwnerId)));
                    System.debug(logginglevel.error,'lstStrOverlappingEventDetails if '+lstStrOverlappingEventDetails);
                }
                else if(mapTechidEvent.containskey(objEvent.OwnerId))
                {
                    // Checking overlapping SVMX Events 
                    lstStrOverlappingEventDetails.addall(getOverlappingEventDetails(objEvent, mapTechidEvent.get(objEvent.OwnerId),timeZone));
                    //WSCH_AuditLogger.debug('mapTechidEvent.get(objEvent.OwnerId) '+mapTechidEvent.get(objEvent.OwnerId));
                    System.debug(logginglevel.error,'lstStrOverlappingEventDetails else'+lstStrOverlappingEventDetails);
                }
            }
            System.debug(logginglevel.error,'mapTechidEvent '+mapTechidEvent);
            //WSCH_AuditLogger.debug('mapTechidEvent '+mapTechidEvent);             
            System.debug(logginglevel.error,'lstStrOverlappingEventDetails '+lstStrOverlappingEventDetails);
            //Display Overlapping Info
            if(lstStrOverlappingEventDetails.size()>0)
            {
                isDoubleBooked = true;
                throw new DCX_CommonServiceManager.DCxException();
                
            }
        }
        catch(Exception ex)
        {
            if(isDoubleBooked == true)
                throw new DCX_CommonServiceManager.DCxException(system.Label.DCON001_TAG238);
            else
               throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
               
        }
        
    }

    public static List<Event>  getWOEvents(List<Event> lstEvent)    
    {
        List<Event> lstWOEvent = new List<Event> ();
        for(Event objEvent:lstEvent)
        {
            //Check if whatid start With WO object Prefix, Which means WO event
            if(objEvent.WhatId!=NULL && String.valueof(objEvent.WhatId).startsWith(SVMXC__Service_Order__c.SObjectType.getDescribe().getKeyPrefix()))
                lstWOEvent.add(objEvent);
        }
        return lstWOEvent;
    }

    public static TechEvent_WP GetExistingSFSVMXEvents(List<Event> lstEvent, String timeZone, String SFuserPrefix)
    {
        map<String ,List<TechEvent_WP>> mapTechidEvent = new map<String ,List<TechEvent_WP>>();
        List<Event> lstSFEvent = new  List<Event>();
        List<SVMXC__SVMX_Event__c> lstSVMXEvent = new  List<SVMXC__SVMX_Event__c>();
        List<String> lstTech = new List<String>();
        List<String> lstSFUserId = new List<String>();
        DateTime eventStartTime ;
        DateTime eventEndTime ;
        //Find the time span and Tech to look for overlapping events. 
        // Time span for 2 datetime 18/9/2014 9:00 AM to  19/9/2014 10:00 AM and  20/9/2014 9:00 AM to 22/9/2014 10:00 AM will be : 18/9/2014 9:00 to 22/9/2014 10:00 AM
        for(Event objEvent: lstEvent)
        {
            if(String.valueof(objEvent.OwnerId).startsWith(SFUserPrefix))
                lstSFUserId.add(objEvent.OwnerId);
            else
                lstTech.add(objEvent.OwnerId);
            if(eventStartTime == null)
                eventStartTime = objEvent.StartDateTime;
            else if(eventStartTime != null && objEvent.StartDateTime < eventStartTime)
                eventStartTime = Date.valueOf(objEvent.StartDateTime);
            if(eventEndTime == null)    
                eventEndTime = eventStartTime.addMinutes(Integer.valueof(objEvent.DurationInMinutes)); //DateTime.valueof(eventStartTime).addMinutes(Integer.valueof(objEvent.DurationInMinutes));
            else if(eventEndTime != null && eventEndTime < DateTime.valueof(eventStartTime).addMinutes(Integer.valueof(objEvent.DurationInMinutes)))
                eventEndTime = DateTime.valueof(eventStartTime).addMinutes(Integer.valueof(objEvent.DurationInMinutes));
        }
        mapIdTech = getmapTechIdObj(lstTech,lstSFUserId);
        if(eventStartTime!= null)
        eventStartTime = dcUtils.getDateTimeInTimezone(DateTime.valueof(eventStartTime).dateGmt(), DateTime.valueof(eventStartTime).timeGmt(),timeZone).addHours(-12);
        if(eventEndTime!= null)
        eventEndTime = dcUtils.getDateTimeInTimezone(DateTime.valueof(eventEndTime).dateGmt(), DateTime.valueof(eventEndTime).timeGmt(), timeZone).addHours(12);
        //WSCH_AuditLogger.debug('lstTech : '+lstTech+'eventStartTime '+eventStartTime +'eventEndTime '+eventEndTime);
        //Getting SF events  with given time span and for the given Tech 
        //WSCH_AuditLogger.debug('mapSFUSerTechId.keyset():  '+mapSFUSerTechId.keyset());
        lstSFEvent = getLstSFEventforTech(mapSFUSerTechId.keyset(), eventStartTime, eventEndTime);
        //Getting SVMX events with given time span and for the given Tech 
        lstSVMXEvent = getLstSVMXEventforTech(mapSFUSerTechId.values(), eventStartTime, eventEndTime);
        // Populate the {TechID, TechEvent_WP}
        TechEvent_WP ObjExistingSFSVMXEvents = new TechEvent_WP();
        ObjExistingSFSVMXEvents.lstSFEvent.addall(lstSFEvent);
        ObjExistingSFSVMXEvents.lstSVMXEvent.addall(lstSVMXEvent);
        return ObjExistingSFSVMXEvents;
        
    }

    public static String DCX_Delete_Events_WS(String UserId, List<String> Events)
    {
        String StatusMessage;
        Schema.Describesobjectresult objE = Event.sObjectType.getDescribe();
        List<String> SFEvents = new List<String>();
        List<String> SMEvents = new List<String>();
        Set<String> wo_TL = new Set<String>();
        Set<String> owners_TL = new Set<String>();
        Set<String> otechnician_TL = new Set<String>();
        Set<Datetime> woAssigned_TL = new Set<Datetime>();
        DCX_EventServiceManager_Util eventServiceUtil = new DCX_EventServiceManager_Util();
        //List<SVMXC__DC_Platform_Event__e> platformEvents = new List<SVMXC__DC_Platform_Event__e>();

        try
        {
            //Validations
            if(Events == null || Events.size()==0)
                throw new DCX_CommonServiceManager.DCxException('Please provide some events to delete');
            for(String e: Events)
            {
                if(e.startsWith(objE.getKeyPrefix()))
                    SFEvents.add(e);
                else
                    SMEvents.add(e);
            }

            List<Event> SalesforceEventList = new List<Event>();
            String sfQuery = 'SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id IN :SFEvents';
            SalesforceEventList = eventServiceUtil.retrieveSFEventsForIdsUtil(sfQuery,SFEvents);
            //SalesforceEventList = [SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id IN :SFEvents];
            List<SVMXC__SVMX_Event__c> ServiceMaxEventList = new List<SVMXC__SVMX_Event__c>();
            ServiceMaxEventList = [SELECT Id, SVMXC__ActivityDateTime__c, SVMXC__WhatId__c, SVMXC__Technician__c from SVMXC__SVMX_Event__c where Id IN :SMEvents];

            for(Event e: SalesforceEventList){
                if(e.WhatId != NULL)
                    wo_TL.add(e.WhatId);
                if(e.ActivityDateTime != NULL)
                    woAssigned_TL.add(e.ActivityDateTime);
                if(e.OwnerId != NULL)
                    owners_TL.add(e.OwnerId);
            }

            for(SVMXC__SVMX_Event__c e: ServiceMaxEventList){
                if(e.SVMXC__WhatId__c != NULL)
                    wo_TL.add(e.SVMXC__WhatId__c);
                if(e.SVMXC__ActivityDateTime__c != NULL)
                    woAssigned_TL.add(e.SVMXC__ActivityDateTime__c);
                if(e.SVMXC__Technician__c != NULL)
                    otechnician_TL.add(e.SVMXC__Technician__c);
            }

            List<SVMXC__Service_Order__c> schWO = [Select Id, SVMXC__Last_Dispatch_Event__c,SVMXC__FirstScheduledDateTime__c, SVMXC__NoOfTimesScheduled__c, SVMXC__Scheduled_Date_Time__c, SVMXC__Group_Member__c, SVMXC__Group_Member__r.SVMXC__Salesforce_User__c from SVMXC__Service_Order__c where Id IN :wo_TL AND SVMXC__Scheduled_Date_Time__c IN :woAssigned_TL AND (SVMXC__Group_Member__c IN :otechnician_TL OR SVMXC__Group_Member__r.SVMXC__Salesforce_User__c IN :owners_TL) ];
            for(SVMXC__Service_Order__c wo: schWO){
                wo.SVMXC__Scheduled_Date_Time__c = NULL;
                wo.SVMXC__Last_Dispatch_Event__c='UnScheduled';
            }
            if(schWO.size() > 0) {
                // if(COMM_SecurityUtils.getInstance().verifyFieldAccess(schWO,COMM_SecurityUtils.Access.Updateable)){
                    COMM_SecurityUtils.getinstance().updateAsUser(schWO); //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                // } 
            }

            if(SalesforceEventList.size()>0) {
                // if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') ){
                    //COMM_SecurityUtils.getinstance().deleteAsUser(SalesforceEventList); //SDL-SVMX-DELETE-FLS-ENFORCED
                    eventServiceUtil.deleteSFEventsUtil(SalesforceEventList);
                // } 
            }
            if(ServiceMaxEventList.size()>0) {
                // if( COMM_SecurityUtils.getInstance().isDeletableObject('SVMXC__SVMX_Event__c') ){
                    COMM_SecurityUtils.getinstance().deleteAsUser(ServiceMaxEventList); //SDL-SVMX-DELETE-FLS-ENFORCED
                // } 
            }
            StatusMessage = 'Events deleted successfully';
        }
        catch(DmlException ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex.getDmlMessage(0));
        }
        catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
        }
        return StatusMessage;
    }

    public static list<SVMXC__SVMX_Event__c> getLstSVMXEventforTech(list<string> lstOwnerID,DateTime inputStartTime, DateTime inputEndTime)
    {
        //Following Scenarios are considered for checking Double booking
        // events that "end" during the input event's start and end time, 
        // events that "start" during the input event's start and end time
        // events that "start" before input event's start time and "end" after input event's end time
        // events that "start" within the input event's start and end time including fully overlapped events
        
        //WSCH_AuditLogger.debug('inputStartTime : '+inputStartTime +'   '+ inputEndTime+'  '+lstOwnerID); 
        date inputStartdate = inputStartTime.dateGMT();
        //date inputEnddate = inputStartTime.dateGMT(); seems typo, hence the below code - Win16
        date inputEnddate = inputEndTime.dateGMT();
        
        datetime inputStartdatetime = Datetime.newInstanceGmt(inputStartTime.dateGMT(),Time.newInstance(0, 0, 0, 0));
        //WSCH_AuditLogger.debug('inputStartdatetime : '+inputStartdatetime); 
        //return([Select Id,SVMXC__DurationInMinutes__c, SVMXC__WhatId__c,SVMXC__Technician__c, SVMXC__ActivityDate__c,SVMXC__ActivityDateTime__c,SVMXC__EndDateTime__c,SVMXC__StartDateTime__c,SVMXC__IsAllDayEvent__c from SVMXC__SVMX_Event__c where (SVMXC__Technician__c in:lstOwnerID) AND ((SVMXC__StartDateTime__c <= :inputEndTime and SVMXC__EndDateTime__c >= :inputStartTime)OR(SVMXC__StartDateTime__c = :inputStartdatetime AND SVMXC__IsAllDayEvent__c = true))]); 
        return([Select Id,SVMXC__DurationInMinutes__c, SVMXC__WhatId__c,SVMXC__Technician__c, SVMXC__ActivityDate__c,SVMXC__ActivityDateTime__c,SVMXC__EndDateTime__c,SVMXC__StartDateTime__c,SVMXC__IsAllDayEvent__c from SVMXC__SVMX_Event__c where (SVMXC__Technician__c in:lstOwnerID) AND ((SVMXC__StartDateTime__c <= :inputEndTime and SVMXC__EndDateTime__c >= :inputStartTime)OR (SVMXC__ActivityDate__c <= :inputEnddate and SVMXC__EndDateTime__c >= :inputStartdatetime AND SVMXC__IsAllDayEvent__c = true) OR(SVMXC__StartDateTime__c = :inputStartdatetime AND SVMXC__IsAllDayEvent__c = true))]); 
    }

    public static list<event> getLstSFEventforTech(set<string> lstOwnerID,DateTime inputStartTime, DateTime inputEndTime)
    {
        //Following Scenarios are considered for checking Double booking
        // events that "end" during the input event's start and end time, 
        // events that "start" during the input event's start and end time
        // events that "start" before input event's start time and "end" after input event's end time
        // events that "start" within the input event's start and end time including fully overlapped events
          
        //return([Select Id, WhatId,ActivityDateTime,OwnerId, EndDateTime, DurationInMinutes  from Event where (OwnerId in:lstOwnerID) AND (ActivityDateTime <= :inputEndTime and EndDateTime >= :inputStartTime)] ); 
        date inputStartdate = inputStartTime.dateGMT();
        date inputEndtdate = inputEndTime.dateGMT();
        //WSCH_AuditLogger.debug('inputStartdate:  '+inputStartdate);
        datetime inputStartdatetime = Datetime.newInstanceGmt(inputStartTime.dateGMT(),Time.newInstance(0, 0, 0, 0));
        //WSCH_AuditLogger.debug('inputStartdatetime : '+inputStartdatetime); 
        //return([Select Id, WhatId,ActivityDateTime,OwnerId, EndDateTime, DurationInMinutes,IsAllDayEvent,ActivityDate,StartDatetime  from Event where (OwnerId in:lstOwnerID) AND ((StartDateTime <= :inputEndTime and EndDateTime >= :inputStartTime)OR(StartDatetime = :inputStartdatetime AND IsAllDayEvent = true))]) ; 
        //Get list of Events for Tech within the time range inputStartTime and inputEndtdate with additional validation for All-Day events retival i.e. using ActivityDate instead of StartDateTime and in EndDateTime & inputStartdatetime time component is (0,0,0,0) (should be in All-day events)
        return([Select Id, WhatId,ActivityDateTime,OwnerId, EndDateTime, DurationInMinutes,IsAllDayEvent,ActivityDate,StartDatetime  from Event where (OwnerId in:lstOwnerID) AND ((StartDateTime <= :inputEndTime and EndDateTime >= :inputStartTime)OR (ActivityDate <= :inputEndtdate and EndDateTime >= :inputStartdatetime AND IsAllDayEvent = true ) OR(ActivityDate = :inputStartdate AND IsAllDayEvent = true))]) ; 
    }

    public static map<String,SVMXC__Service_Group_Members__c> getmapTechIdObj(list<String> lstTechId, list<String> lstSFUserId)
    {
        map<String,SVMXC__Service_Group_Members__c> mapTechIdTechObj ;
        mapTechIdTechObj =new map<String,SVMXC__Service_Group_Members__c>([Select Id,SVMXC__Salesforce_User__c,Name from SVMXC__Service_Group_Members__c where id IN :lstTechId or SVMXC__Salesforce_User__c IN :lstSFUserId]);
        
        
        for(String TechId : mapTechIdTechObj.keyset())
        {
            // Later, we need to have the SF userID too for the TechID to query the 'SF Event Object' against this Technician ID
            mapSFUSerTechId.put(mapTechIdTechObj.get(TechId).SVMXC__Salesforce_User__c,TechId);
            
            //setSFUSerId.add(mapTechIdTechObj.get(TechId).SVMXC__Salesforce_User__c);
        }
        //WSCH_AuditLogger.debug('mapSFUSerTechId: '+mapSFUSerTechId);
        return mapTechIdTechObj;
       
    }

    public Static string getTechId(string sFUser)
    {
        if(mapSFUSerTechId.containsKey(sFUser))
            return mapSFUSerTechId.get(sFUser);
        else
            return null;
    }

    public static string getTechName(String techId)
    {
        if(mapIdTech.containsKey(techId))
            return mapIdTech.get(techId).Name;
        else
            return null;
    }

    public static List<String> getOverlappingEventDetails(Event objEvent,TechEvent_WP objTechEvent_WP,String timeZone)
    {
        //Following Scenarios are considered for checking Double booking
        // events that "end" during the input event's start and end time, 
        // events that "start" during the input event's start and end time
        // events that "start" before input event's start time and "end" after input event's end time
        // events that "start" within the input event's start and end time including fully overlapped events
        
        
        List<String> lstStrOverlappingEventDetails = new List<String>();
        //Converting incoming event's StartDateTime to user timezone
        DateTime eventStartTime = dcUtils.getDateTimeInTimezone(DateTime.valueof(objEvent.StartDateTime).dateGmt(), DateTime.valueof(objEvent.StartDateTime).timeGmt(),timeZone);
        //eventEndTime = DateTime.newInstance(DateTime.valueof(eventEndTime).dateGmt(), DateTime.valueof(eventEndTime).timeGmt());
        DateTime eventEndTime = DateTime.valueof(eventStartTime).addMinutes(Integer.valueof(objEvent.DurationInMinutes));
        DateTime eventstartDate;
        if(objEvent.isAllDayEvent)
            eventstartDate = objEvent.ActivityDate;
        else
            eventstartDate = eventStartTime.dateGMT();// Why can't we take it directly from ActivityDate. Need to find if it is being passed from client in case of non-All Day event
        //WSCH_AuditLogger.debug('objEvent'+objEvent+'   '+objTechEvent_WP+'     '+eventEndTime);
        //WSCH_AuditLogger.debug('eventstartDate '+eventstartDate);
        for(Event SFEvent: objTechEvent_WP.lstSFEvent)
        {
            String idEvt = objEvent.id;
            if(objEvent != null && objEvent.id != null && String.IsNotBlank(idEvt))
            {
                //lstStrOverlappingEventDetails is just for message to the client..Not yet implemented
                if(SFEvent.isAllDayEvent && objEvent.Id != SFEvent.id)
                {
                    //WSCH_AuditLogger.debug('SFEvent.StartDateTime.dateGMT() '+SFEvent.StartDateTime.dateGMT());
                    //WSCH_AuditLogger.debug('SFEvent.EndDateTime.dateGMT() '+SFEvent.EndDateTime.dateGMT());
                    // Start And end time in selected globes time zone
                    // Temporarily provide the stored ALL day event, end time - in later release we need to work, to have it persisted
                    DateTime stored_eventStartTime = SFEvent.StartDateTime;
                    DateTime stored_eventEndTime = SFEvent.StartDateTime.addMinutes(Integer.valueof(SFEvent.DurationInMinutes));
                    
                    DateTime incomingEventStartTime = objEvent.StartDateTime; // getting back to the User's timezone, for All day event test
                    DateTime incomingEventEndTime = objEvent.StartDateTime.addMinutes(Integer.valueof(objEvent.DurationInMinutes));
                    //WSCH_AuditLogger.debug('stored_eventStartTime = '+stored_eventStartTime + ' < ' + incomingEventEndTime);
                    //WSCH_AuditLogger.debug('stored_eventEndTime = '+stored_eventEndTime + ' > ' + incomingEventStartTime );
                    //if(SFEvent.ActivityDate == eventstartDate && objEvent.Id != SFEvent.id)
                    //Pavi - Commented if(SFEvent.StartDateTime.dateGMT() == eventstartDate && objEvent.Id != SFEvent.id)
                    
                    if((stored_eventStartTime < incomingEventEndTime  && stored_eventEndTime > incomingEventStartTime) && objEvent.Id != SFEvent.id)
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+eventStartTime+' End Time: '+eventEndTime);   
                }
                else if((SFEvent.StartDateTime < eventEndTime  && SFEvent.EndDateTime > eventStartTime) && objEvent.Id != SFEvent.id)
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+eventStartTime+' End Time: '+eventEndTime);
            }
            else 
            {
                if(SFEvent.isAllDayEvent)
                {
                    //WSCH_AuditLogger.debug('SFEvent.StartDateTime.dateGMT() '+SFEvent.StartDateTime.dateGMT());
                   // if(SFEvent.ActivityDate == eventstartDate)
                    //if(SFEvent.StartDateTime.dateGMT() == eventstartDate)
                    // Start And end time in selected globes time zone
                    // Temporarily provide the stored ALL day event, end time - in later release we need to work, to have it persisted

                    DateTime stored_eventStartTime = SFEvent.StartDateTime;
                    DateTime stored_eventEndTime = SFEvent.StartDateTime.addMinutes(Integer.valueof(SFEvent.DurationInMinutes));

                    DateTime incomingEventStartTime = objEvent.StartDateTime; // getting back to the User's timezone, for All day event test
                    DateTime incomingEventEndTime = objEvent.StartDateTime.addMinutes(Integer.valueof(objEvent.DurationInMinutes));

                    if(stored_eventStartTime < incomingEventEndTime  && stored_eventEndTime > incomingEventStartTime)
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+stored_eventStartTime+' End Time: '+stored_eventEndTime);   
                }
                else if((SFEvent.StartDateTime < eventEndTime  && SFEvent.EndDateTime > eventStartTime))
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+eventStartTime+' End Time: '+eventEndTime);
            }
            
        }
        for(SVMXC__SVMX_Event__c SVMXEvent: objTechEvent_WP.lstSVMXEvent)
        {
            String idEvt = objEvent.id;
            if(objEvent != null && objEvent.id != null && String.IsNotBlank(idEvt))
            {  //update case         
                if(SVMXEvent.SVMXC__IsAllDayEvent__c && objEvent.Id != SVMXEvent.id)
                {
                    //WSCH_AuditLogger.debug('SVMXEvent.SVMXC__StartDateTime__c.dateGMT() '+SVMXEvent.SVMXC__StartDateTime__c.dateGMT());
                    //if(SVMXEvent.SVMXC__ActivityDate__c == eventstartDate)
                    //if(SVMXEvent.SVMXC__StartDateTime__c.dateGMT() == eventstartDate)
                    // Start And end time in selected globes time zone
                    // Temporarily provide the stored ALL day event, end time - in later release we need to work, to have it persisted

                    DateTime stored_eventStartTime = SVMXEvent.SVMXC__StartDateTime__c;
                    DateTime stored_eventEndTime = SVMXEvent.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(SVMXEvent.SVMXC__DurationInMinutes__c));

                    DateTime incomingEventStartTime = objEvent.StartDateTime; // getting back to the User's timezone, for All day event test
                    DateTime incomingEventEndTime = objEvent.StartDateTime.addMinutes(Integer.valueof(objEvent.DurationInMinutes));
                    
                    //WSCH_AuditLogger.debug('stored_eventStartTime = ' + stored_eventStartTime + ' < ' + incomingEventEndTime);
                    //WSCH_AuditLogger.debug('calculated_eventEndTime = ' + stored_eventEndTime + ' > ' + incomingEventStartTime );
                    //WSCH_AuditLogger.debug('stored_eventEndTime = ' + SVMXEvent.SVMXC__EndDateTime__c);
                    system.debug(logginglevel.error,'Update case objEvent.id =: ' + objEvent.id + 'stored_eventStartTime: '+stored_eventStartTime+'  incomingEventEndTime:  '+incomingEventEndTime+'  stored_eventEndTime  '+stored_eventEndTime+'  incomingEventStartTime  '+incomingEventStartTime);
                    if((stored_eventStartTime < incomingEventEndTime  && stored_eventEndTime > incomingEventStartTime) && objEvent.Id != SVMXEvent.id)  
                        lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+stored_eventStartTime+' End Time: '+stored_eventEndTime);
                }
                if((SVMXEvent.SVMXC__StartDateTime__c < eventEndTime  && SVMXEvent.SVMXC__EndDateTime__c > eventStartTime) && objEvent.Id != SVMXEvent.id)
                {
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+eventStartTime+' End Time: '+eventEndTime);
                    //WSCH_AuditLogger.debug('lstStrOverlappingEventDetails '+lstStrOverlappingEventDetails);
                }
            }
            else 
            { //create case 
                if(SVMXEvent.SVMXC__IsAllDayEvent__c)
                {
                    //WSCH_AuditLogger.debug('SVMXEvent.SVMXC__StartDateTime__c.dateGMT() '+SVMXEvent.SVMXC__StartDateTime__c.dateGMT());
                   // if(SVMXEvent.SVMXC__ActivityDate__c == eventstartDate)
                    //if(SVMXEvent.SVMXC__StartDateTime__c.dateGMT() == eventstartDate)
                    // Start And end time in selected globes time zone
                    // Temporarily provide the stored ALL day event, end time - in later release we need to work, to have it persisted

                    DateTime stored_eventStartTime = SVMXEvent.SVMXC__StartDateTime__c;
                    DateTime stored_eventEndTime = SVMXEvent.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(SVMXEvent.SVMXC__DurationInMinutes__c));

                    DateTime incomingEventStartTime = objEvent.StartDateTime; // getting back to the User's timezone, for All day event test
                    DateTime incomingEventEndTime = objEvent.StartDateTime.addMinutes(Integer.valueof(objEvent.DurationInMinutes ));
                    
                    //WSCH_AuditLogger.debug('stored_eventStartTime = '+stored_eventStartTime + ' < ' + incomingEventEndTime);
                   // //WSCH_AuditLogger.debug('calculated_eventEndTime = '+stored_eventEndTime + ' > ' + incomingEventStartTime );
                   // //WSCH_AuditLogger.debug('stored_eventEndTime = ' + SVMXEvent.SVMXC__EndDateTime__c);
                    
                    system.debug(logginglevel.error,'Create case objEvent.id =: ' + objEvent.id + 'stored_eventStartTime: '+stored_eventStartTime+'  incomingEventEndTime:  '+incomingEventEndTime+'  stored_eventEndTime  '+stored_eventEndTime+'  incomingEventStartTime  '+incomingEventStartTime);
                    
                    if(stored_eventStartTime < incomingEventEndTime  && stored_eventEndTime > incomingEventStartTime)   
                        lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+stored_eventStartTime+' End Time: '+stored_eventEndTime);
                }
                else if((SVMXEvent.SVMXC__StartDateTime__c < eventEndTime  && SVMXEvent.SVMXC__EndDateTime__c > eventStartTime))
                {
                    lstStrOverlappingEventDetails.add('Technician Name: ' + getTechName(getTechId(objEvent.OwnerId)) +' '+' Start Time: '+eventStartTime+' End Time: '+eventEndTime);
                    //WSCH_AuditLogger.debug('lstStrOverlappingEventDetails '+lstStrOverlappingEventDetails);
                    system.debug(logginglevel.error,'In else block for non All day event');
                    system.debug(logginglevel.error,'SVMXEvent.SVMXC__StartDateTime__c  '+SVMXEvent.SVMXC__StartDateTime__c+'eventEndTime  '+eventEndTime+'  SVMXEvent.SVMXC__EndDateTime__c  '+SVMXEvent.SVMXC__EndDateTime__c+'eventStartTime '+eventStartTime);
                }
            }
            
        }
        system.debug(logginglevel.error,'lstStrOverlappingEventDetails: '+lstStrOverlappingEventDetails);
        return lstStrOverlappingEventDetails;
    }

    public static map<String ,TechEvent_WP> getmapTechEvent(List<Event> lstSFEvent ,List<SVMXC__SVMX_Event__c> lstSVMXEvent )
    {
            map<String ,TechEvent_WP> mapTechEvent = new map<String ,TechEvent_WP> ();
            //Looping through SF event list to Build map of tech and TechEvent_WP
            for(Event objEvent :lstSFEvent)
            {
                if(mapTechEvent.containskey(getTechId(objEvent.OwnerId)))
                {
                    TechEvent_WP objTechEvent_WP = new TechEvent_WP();
                    objTechEvent_WP =  mapTechEvent.get(getTechId(objEvent.OwnerId));
                    objTechEvent_WP.lstSFEvent.add(objEvent);
                    mapTechEvent.put(getTechId(objEvent.OwnerId),objTechEvent_WP);
                }
                else
                {
                    TechEvent_WP objTechEvent_WP = new TechEvent_WP();
                    objTechEvent_WP.lstSFEvent.add(objEvent);
                    mapTechEvent.put(getTechId(objEvent.OwnerId),objTechEvent_WP);
                }
                
            }
            //Looping through SVMX event list to Build map of tech and TechEvent_WP
            for(SVMXC__SVMX_Event__c objEvent :lstSVMXEvent)
            {
                if(mapTechEvent.containskey(objEvent.SVMXC__Technician__c))
                {
                    TechEvent_WP objTechEvent_WP = new TechEvent_WP();
                    objTechEvent_WP =  mapTechEvent.get(objEvent.SVMXC__Technician__c);
                    objTechEvent_WP.lstSVMXEvent.add(objEvent);
                    mapTechEvent.put(objEvent.SVMXC__Technician__c,objTechEvent_WP);
                }
                else
                {
                    TechEvent_WP objTechEvent_WP = new TechEvent_WP();
                    objTechEvent_WP.lstSVMXEvent.add(objEvent);
                    mapTechEvent.put(objEvent.SVMXC__Technician__c,objTechEvent_WP);
                }
            }
            return mapTechEvent;
    }

    public static List<SVMXC__SVMX_Event__c>  getWOEvents(List<SVMXC__SVMX_Event__c> lstEvent)  
    {
        List<SVMXC__SVMX_Event__c> lstWOEvent = new List<SVMXC__SVMX_Event__c> ();
        for(SVMXC__SVMX_Event__c objEvent:lstEvent)
        {
            //Check if whatid start With WO object Prefix, Which means WO event
            if(objEvent.SVMXC__WhatId__c != NULL && String.valueof(objEvent.SVMXC__WhatId__c).startsWith(SVMXC__Service_Order__c.SObjectType.getDescribe().getKeyPrefix()))
                lstWOEvent.add(objEvent);
        }
        return lstWOEvent;
    }

    public static DateTime getLeastDateTime(List<DateTime> dateTimes)
    {
        DateTime leastDateTime;
        if(dateTimes.size() > 0)
        {
            for(DateTime dt: dateTimes)
            {
                if(leastDateTime == NULL)
                    leastDateTime = dt;
                else
                    if(dt < leastDateTime)
                        leastDateTime = dt;     
            }
        }

        return leastDateTime;
    }
  public static  List<DCEventHover_Wrapper>  getEventHoverRules() {
        
            string RuleRecordTypeId;
            string ExpressionRTypeId;
         Map<Id, SVMXC__ServiceMax_Processes__c> mapEventHoverRules  = new Map<Id, SVMXC__ServiceMax_Processes__c>(); 
         Map<Id, List<DCEventHover_WP>> eventHoverRules  = new Map<Id, List<DCEventHover_WP>>(); 
         List <DCEventHover_WP > listEventHover =new  List <DCEventHover_WP >();
         List <SVMXC__ServiceMax_Processes__c > oPro =new  List <SVMXC__ServiceMax_Processes__c >();
         List<DCEventHover_Wrapper> expressions = new List<DCEventHover_Wrapper>();
         DCEventHover_Wrapper exp;
         List<String> targetFields;
         for(RecordType recType : [Select SobjectType, Id, Name From RecordType where (SobjectType = 'SVMXC__ServiceMax_Processes__c' AND Name = 'SVMX Rule') OR (SobjectType = 'SVMXC__ServiceMax_Config_Data__c' AND Name IN ('Expressions', 'Field Mapping'))])   
            {
                if(recType.Name == 'SVMX Rule')
                    RuleRecordTypeId = recType.id;
                else if(recType.Name == 'Expressions')
                    ExpressionRTypeId = recType.id;
                
            }
            system.debug('ExpressionRTypeId'+ExpressionRTypeId + '  '+RuleRecordTypeId);
            oPro =  [Select SVMXC__Sequence__c, SVMXC__Advance_Expression__c, Id,
                            (Select Id, SVMXC__Sequence__c, SVMXC__Field_Name__c, SVMXC__Operator__c, 
                             SVMXC__Operand__c, SVMXC__Display_Type__c, SVMXC__Expression_Rule__c, SVMXC__Target_Field_Name__c,
                            SVMXC__Field_Relationship_Name__c From SVMXC__ServiceMax_Config_Data2__r 
                            where (SVMXC__Expression_Type__c = 'DISP_Event_Hover_Rule' or 
                            SVMXC__Expression_Type__c ='' or SVMXC__Expression_Type__c=null)
                            Order By SVMXC__Sequence__c) 
                          From SVMXC__ServiceMax_Processes__c  where RecordTypeId =:RuleRecordTypeId 
                          and SVMXC__Rule_Type__c = 'Event Hover Rule'];
                          system.debug('oPro :' +oPro);
         for(SVMXC__ServiceMax_Processes__c process : oPro)  
        {
            system.debug('process :'+process.Id);
           exp = new DCEventHover_Wrapper();
           targetFields = new List<String>();
           List<eventLine> eventLineItems = new List<eventLine>();
            for(SVMXC__ServiceMax_Config_Data__c configData : process.SVMXC__ServiceMax_Config_Data2__r) {

               if(configData.SVMXC__Field_Name__c != null) {
                   eventLine line  = new eventLine();
                    line.fieldName =  configData.SVMXC__Field_Name__c;
                    line.operator = configData.SVMXC__Operator__c;
                    line.fieldValue =configData.SVMXC__Operand__c;
                    eventLineItems.add(line);
               }
               else if(configData.SVMXC__Target_Field_Name__c != null) {
                   targetFields.add(configData.SVMXC__Target_Field_Name__c);
               }
            }
            exp.lines = eventLineItems;
            exp.target =  targetFields;
            exp.advExpression =  process.SVMXC__Advance_Expression__c;
            expressions.add(exp);
        }
        
/*
                system.debug('configData :' +oPro);
                DCEventHover_WP event_TWO = new DCEventHover_WP();
                event_TWO.sequence = configData.SVMXC__Sequence__c;
                event_TWO.fieldName  = configData.SVMXC__Field_Name__c;
                event_TWO.operator = configData.SVMXC__Operator__c;
                event_TWO.fieldValue  = configData.SVMXC__Operand__c;
                event_TWO.displayType = configData.SVMXC__Display_Type__c;
                event_TWO.expressionRule = configData.SVMXC__Expression_Rule__c;
                event_TWO.advExpression  = process.SVMXC__Advance_Expression__c ;
                event_TWO.hoverDisplayFields  = configData.SVMXC__Target_Field_Name__c ;
                
                listEventHover.add(event_TWO);
            
            if(listEventHover.size() > 0) {
                eventHoverRules.put(process.Id, listEventHover);
            }
        }*/
        
            return expressions;
    }
    
    public static void deleteEventsAndUpdateWO(List<String> Events)
    {
        //system.debug('Input Parameters: '+UserId+Events);
        String StatusMessage;
        Schema.Describesobjectresult objE = Event.sObjectType.getDescribe();
        List<String> SFEvents = new List<String>();
        List<String> SMEvents = new List<String>();
        Set<String> wo_TL = new Set<String>();
        Set<String> owners_TL = new Set<String>();
        Set<String> otechnician_TL = new Set<String>();
        Set<Datetime> woAssigned_TL = new Set<Datetime>();

        try
        {
            //Validations
            if(Events == null || Events.size()==0)
                //throw new SVMXException('Please provide some events to delete');
            for(String e: Events)
            {
                if(e.startsWith(objE.getKeyPrefix()))
                    SFEvents.add(e);
                else
                    SMEvents.add(e);
            }

            List<Event> SalesforceEventList = new List<Event>();
            SalesforceEventList = [SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id IN :SFEvents];
            List<SVMXC__SVMX_Event__c> ServiceMaxEventList = new List<SVMXC__SVMX_Event__c>();
            ServiceMaxEventList = [SELECT Id, SVMXC__ActivityDateTime__c, SVMXC__WhatId__c, SVMXC__Technician__c from SVMXC__SVMX_Event__c where Id IN :SMEvents];

            for(Event e: SalesforceEventList){
                if(e.WhatId != NULL)
                    wo_TL.add(e.WhatId);
                if(e.ActivityDateTime != NULL)
                    woAssigned_TL.add(e.ActivityDateTime);
                if(e.OwnerId != NULL)
                    owners_TL.add(e.OwnerId);
            }

            for(SVMXC__SVMX_Event__c e: ServiceMaxEventList){
                if(e.SVMXC__WhatId__c != NULL)
                    wo_TL.add(e.SVMXC__WhatId__c);
                if(e.SVMXC__ActivityDateTime__c != NULL)
                    woAssigned_TL.add(e.SVMXC__ActivityDateTime__c);
                if(e.SVMXC__Technician__c != NULL)
                    otechnician_TL.add(e.SVMXC__Technician__c);
            }

            List<SVMXC__Service_Order__c> schWO = [Select Id, SVMXC__Last_Dispatch_Event__c,
                                                   SVMXC__FirstScheduledDateTime__c, 
                                                   SVMXC__NoOfTimesScheduled__c, SVMXC__Scheduled_Date_Time__c,
                                                   SVMXC__Group_Member__c, 
                                                   SVMXC__Group_Member__r.SVMXC__Salesforce_User__c from 
                                                   SVMXC__Service_Order__c where Id IN :wo_TL AND 
                                                   SVMXC__Scheduled_Date_Time__c IN :woAssigned_TL AND 
                                                   (SVMXC__Group_Member__c IN :otechnician_TL OR 
                                                   SVMXC__Group_Member__r.SVMXC__Salesforce_User__c 
                                                   IN :owners_TL) ];
            for(SVMXC__Service_Order__c wo: schWO){
                wo.SVMXC__Scheduled_Date_Time__c = NULL;
                wo.SVMXC__Last_Dispatch_Event__c='UnScheduled';
            }
            if(schWO.size() > 0) {
                // if(COMM_SecurityUtils.getInstance().verifyFieldAccess(schWO,COMM_SecurityUtils.Access.Updateable)){
                    COMM_SecurityUtils.getinstance().updateAsUser(schWO); //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                // } else {
                //     throw new COMM_SecurityUtils.SecurityAccessException(System.label.COMM001_TAG142);
                // }
            }
            //updating records
            if(SalesforceEventList.size()>0) {
                // if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') ){
                    COMM_SecurityUtils.getinstance().deleteAsUser(SalesforceEventList);//SDL-SVMX-DELETE-FLS-ENFORCED
                // } 
            }
            if(ServiceMaxEventList.size()>0) {
                // if( COMM_SecurityUtils.getInstance().isDeletableObject('SVMXC__SVMX_Event__c') ){
                    COMM_SecurityUtils.getinstance().deleteAsUser(ServiceMaxEventList); //SDL-SVMX-DELETE-FLS-ENFORCED
                // } 
            }
            StatusMessage = 'Events deleted successfully';
        } catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
        }

        //return wo_TL;
    }

    public class DCEventHover_WP {
        public Decimal sequence{get; set;}
        public String fieldName  {get; set;}
        public String operator {get; set;}
        public String fieldValue  {get; set;}
        public String displayType {get; set;}
        public String expressionRule {get; set;}
        public String advExpression  {get; set;}
        public String hoverDisplayFields  {get; set;}
         public  DCEventHover_WP(){}

    }

    public class DCEventHover_Wrapper {
        public List<eventLine>  lines;
        public String advExpression;
        public List<String> target;

        public  DCEventHover_Wrapper() {
         }
    }

    public class eventUpsertTechChangeResponse {
        public list<DCX_CommonServiceManager.Events_WP> lstEvent {get; set;}
        public DCON_Work_Order_WS.workorder_WP objWorkOrder {get; set;}
        public String strWOAction {get; set;}
        public List<String> deletedEventIds;
        public Map<String,String> settingvalues;
        
        public  eventUpsertTechChangeResponse() {
        }
    }

    public class eventLine {
        public String fieldName;
        public String operator;
        public String fieldValue;

        public eventLine() {}
    }

    public static String eventSubject(String WOIdUserId)
    {

            //WOIdUserId will have work order id followed by UserId
            //Since this is a webservice, we could not change the arguments, hence we are sending both WoId and UserId in one string
            List<String> splitFileds = WOIdUserId.split(',');
            string WId = splitFileds[0];
            COMM_SVMXC_Utils4 oUtils = new COMM_SVMXC_Utils4();
            list<string> APIList = new list<string>();
            SVMXC__Service_Order__c Wo = new SVMXC__Service_Order__c();
            Map<Id,SVMXC__ServiceMax_Processes__c> RuleMap  = new Map<Id,SVMXC__ServiceMax_Processes__c>();
            list<SVMXC__ServiceMax_Processes__c> EvntSubRuleList = new list<SVMXC__ServiceMax_Processes__c>();  
            list<SVMXC__ServiceMax_Config_Data__c> ConfigDataList = new list<SVMXC__ServiceMax_Config_Data__c>();
            Map<Id,list<SVMXC__ServiceMax_Config_Data__c>> RuleExpMap  = 
                new Map<Id,list<SVMXC__ServiceMax_Config_Data__c>>();  
            list<SVMXC__ServiceMax_Config_Data__c> FieldMapList = new list<SVMXC__ServiceMax_Config_Data__c>();    
            Map<String,Schema.SObjectField> wofieldMapping = 
                SVMXC__Service_Order__c.sObjectType.getDescribe().fields.getMap();    
            string RuleRecordTypeId;
            string ExpressionRTypeId;
            string FieldMapRTypeId;

            for(RecordType r : [Select SobjectType, NamespacePrefix, Name, LastModifiedDate, LastModifiedById,
                                IsActive, Id, DeveloperName, Description, CreatedDate, CreatedById, 
                                BusinessProcessId From RecordType r where 
                                SobjectType = 'SVMXC__ServiceMax_Processes__c' OR 
                                SobjectType = 'SVMXC__ServiceMax_Config_Data__c'])   
            {
                if(r.Name == 'SVMX Rule'){
                    RuleRecordTypeId = r.id;
                }
                if(r.Name == 'Expressions'){
                    ExpressionRTypeId = r.id;
                }
                if(r.Name == 'Field Mapping'){
                    FieldMapRTypeId = r.id;
                } 
            }

            for(SVMXC__ServiceMax_Processes__c oPro : [Select SystemModstamp, SVMXC__MTTS_Minutes__c, 
                                                       SVMXC__Weight_Total_Distance__c, 
                                                       SVMXC__Weight_Time_Window__c, 
                                                       SVMXC__Weight_Route_Time__c, 
                                                       SVMXC__Weight_Route_Distance__c, 
                                                       SVMXC__Weight_Node_Type__c, SVMXC__Territory__c, 
                                                       SVMXC__Technician_User__c, 
                                                       SVMXC__Technician_Service_Group__c, 
                                                       SVMXC__Start_Time__c, SVMXC__Start_Date__c, 
                                                       SVMXC__Schedule_Event__c, 
                                                       SVMXC__Runs_Every_Wednesday__c, 
                                                       SVMXC__Runs_Every_Tuesday__c, 
                                                       SVMXC__Runs_Every_Thursday__c, 
                                                       SVMXC__Runs_Every_Sunday__c, 
                                                       SVMXC__Runs_Every_Saturday__c, 
                                                       SVMXC__Runs_Every_Monday__c, 
                                                       SVMXC__Runs_Every_Friday__c, SVMXC__Route_Type__c, 
                                                       SVMXC__Retain_Assignment__c, 
                                                       SVMXC__Retain_Appointment__c, 
                                                       SVMXC__Product_Match_Enabled__c, 
                                                       SVMXC__Preferred_Tech_Enabled__c, 
                                                       SVMXC__Frequency__c, SVMXC__Final_Exception_Process__c,
                                                       SVMXC__Expertise_Match_Enabled__c, SVMXC__End_Date__c,
                                                       SVMXC__Email_On_Success__c, SVMXC__Email_On_Error__c,
                                                       SVMXC__Distance_And_Time__c, 
                                                       SVMXC__Dispatch_Process_Status__c, 
                                                       SVMXC__Dispatch_Method__c, 
                                                       SVMXC__Calendar_Start_Type__c, 
                                                       SVMXC__Calendar_Start_Days__c, 
                                                       SVMXC__Calendar_End_Type__c, 
                                                       SVMXC__Calendar_End_Days__c, 
                                                       SVMXC__Assign_Work_Order_To__c, 
                                                       SVMXC__Assign_To_Technician__c, 
                                                       SVMXC__Assign_To_Queue__c, 
                                                       SVMXC__Assign_To_Dispatcher__c, SVMXC__Values__c, 
                                                       SVMXC__Target_Record_Type__c, 
                                                       SVMXC__Target_Object_Name__c, SVMXC__Submodule__c, 
                                                       SVMXC__SubmoduleID__c, SVMXC__Source_Object_Name__c, 
                                                       SVMXC__Settings_Name__c, SVMXC__Setting_Unique_ID__c, 
                                                       SVMXC__Setting_Type__c, SVMXC__SettingID__c, 
                                                       SVMXC__Sequence__c, SVMXC__Select__c, 
                                                       SVMXC__Search_Order__c, SVMXC__Rule_Type__c, 
                                                       SVMXC__Record_Type_Name__c, SVMXC__Process__c, 
                                                       SVMXC__ProcessID__c, SVMXC__Pick_First_Match__c, 
                                                       SVMXC__Parent_Object_Criteria__c, SVMXC__Name__c, 
                                                       SVMXC__Module__c, SVMXC__ModuleID__c, 
                                                       SVMXC__Match_Contact__c, SVMXC__Match_Account__c, 
                                                       SVMXC__MapID__c, SVMXC__IsStandard__c, 
                                                       SVMXC__IsPrivate__c, SVMXC__Installation_Key__c, 
                                                       SVMXC__Include_Top_Level__c, SVMXC__Include_Product__c, 
                                                       SVMXC__Include_Parent__c, SVMXC__Entitlement_Scope__c, 
                                                       SVMXC__Entitlement_By__c, SVMXC__Description__c, 
                                                       SVMXC__Default_Value__c, SVMXC__Data_Type__c, 
                                                       SVMXC__Counter_Vs_Dates_Rule__c, 
                                                       SVMXC__Child_Object_Criteria__c, 
                                                       SVMXC__Advance_Expression__c, SVMXC__Active__c, 
                                                       RecordTypeId, OwnerId, Name, LastModifiedDate, 
                                                       LastModifiedById,  IsDeleted, Id, CreatedDate, CreatedById 
                                                       From SVMXC__ServiceMax_Processes__c  where 
                                                       RecordTypeId =:RuleRecordTypeId and 
                                                       SVMXC__Rule_Type__c ='Event Subject Rule']){    
                RuleMap.put(oPro.Id,oPro);
            }
        ConfigDataList = [Select SystemModstamp, SVMXC__Dispatch_Process__c, SVMXC__User__c, 
                          SVMXC__Target_Field_Name__c, SVMXC__Stock_Status__c, 
                          SVMXC__Stock_History_Line_Lookup_Field__c, 
                          SVMXC__Stock_History_Header_Lookup_Field__c, SVMXC__Source_Field_Name__c, 
                          SVMXC__Setting_Unique_ID__c, SVMXC__Setting_ID__c, 
                          SVMXC__Setting_Configuration_Profile__c, SVMXC__SettingID__c, 
                          SVMXC__Sequence__c, SVMXC__Select__c, SVMXC__RecordType_Name__c, 
                          SVMXC__Profile__c, SVMXC__Profile_Name__c, SVMXC__Operator__c, 
                          SVMXC__Operand__c, SVMXC__Object_Name__c, SVMXC__MapID__c, 
                          SVMXC__Lookup_Field_API_Name__c, SVMXC__Location_Type__c, 
                          SVMXC__Location_Field_Name__c, SVMXC__Location_Field_From__c,
                          SVMXC__IsDefault__c, SVMXC__Inventory_Process__c, SVMXC__Internal_Value__c, 
                          SVMXC__Installation_Key__c, SVMXC__Field_Name__c, SVMXC__FKey_Name_Field__c, 
                          SVMXC__Expression_Type__c, SVMXC__Expression_Rule__c, SVMXC__Enter_Date__c, 
                          SVMXC__Display_Value__c, SVMXC__Display_Type__c, SVMXC__Display_Map_ID__c, 
                          SVMXC__Description__c, SVMXC__Configuration_Type__c, 
                          SVMXC__Config_Profile_Name__c, SVMXC__Active__c, SVMXC__Action__c, 
                          SVMXC__Access_Configuration_Profile__c, RecordTypeId, OwnerId, Name, 
                          LastModifiedDate, LastModifiedById,  IsDeleted, Id, CreatedDate, CreatedById, 
                          Field_Relationship_Name__c From SVMXC__ServiceMax_Config_Data__c where 
                          RecordTypeId=:ExpressionRTypeId and 
                          SVMXC__Expression_Type__c ='DISP_Event_Subject_Rule' and SVMXC__Expression_Rule__c 
                          IN:RuleMap.keyset()];//SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            for(SVMXC__ServiceMax_Config_Data__c oExp : ConfigDataList){
                if(!RuleExpMap.ContainsKey(oExp.SVMXC__Expression_Rule__c))
                    RuleExpMap.put(oExp.SVMXC__Expression_Rule__c, new list<SVMXC__ServiceMax_Config_Data__c>());
                RuleExpMap.get(oExp.SVMXC__Expression_Rule__c).add(oExp);
            }

            //Instead of querying all fields, query only required fields.
            Set<String> setWOFlds = new Set<String>();
            String strWOFldsQry = ''; 
            for(SVMXC__ServiceMax_Config_Data__c oExpression: ConfigDataList)
            {
                if(oExpression.SVMXC__Field_Name__c != null && oExpression.SVMXC__Field_Name__c.length() > 0 
                    && !setWOFlds.contains(oExpression.SVMXC__Field_Name__c))
                { 
                    setWOFlds.add(oExpression.SVMXC__Field_Name__c);
                    if(strWOFldsQry.length() > 0)
                        strWOFldsQry += ',';
                    strWOFldsQry += oExpression.SVMXC__Field_Name__c;
                    
                }
            }

            try {   
                Wo = database.query('Select ' + strWOFldsQry + ' ,Id From SVMXC__Service_Order__c ' + '  where Id =: WId');
            }
            catch(exception ex) { 
                system.debug(LoggingLevel.DEBUG, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
            }

            string RuleId = oUtils.SVMX_ExpressionParsing((SObject)Wo, RuleExpMap, RuleMap);

            RuleMap.clear();
            RuleExpMap.clear();
            if(RuleId!=null){
            FieldMapList = [Select SVMXC__Target_Field_Name__c, SVMXC__Field_Relationship_Name__c From 
                            SVMXC__ServiceMax_Config_Data__c where RecordTypeId=:FieldMapRTypeId and 
                            SVMXC__Expression_Rule__c =:RuleId order by SVMXC__Sequence__c]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            }
            
            List<String> evtSubRuleLst = new List<String>();
            if(FieldMapList!=null && FieldMapList.size()>0){
                for(SVMXC__ServiceMax_Config_Data__c oExp : FieldMapList){
                    APIList.add(oExp.SVMXC__Target_Field_Name__c);
                }
            }

            //START: DNS-623
            SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
            DCON_Utils dcUtils1 = new DCON_Utils(); 
            String queryStr; 
            Boolean isLocal = false;
            List<DCON_Work_Order_WS.workorder_WP> workorder_LWP = new List<DCON_Work_Order_WS.workorder_WP>(); //Result set for the method
            List<SVMXC__Service_Order__c> workorder_LO = new List<SVMXC__Service_Order__c>();
            List<String> refFields_L = new List<String>();
            List<String> dateTimeFields_L = new List<String>();
            List<String> dateFields_L = new List<String>();
            Map<String,String> replacementRef = new Map<String,String>();
            Map<String,String> replacementNameField = new Map<String,String>();
            Map<String, SObjectField> newSchemaFieldMap = new Map<String, SObjectField>();
            String fieldValue;
            Map<String, SObjectField> souObjfieldMap = 
                Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap(); // Get field definition map for work order
            
            //get the list of WO fields which are to be loaded from a subject rule defined
            Set<String> setWOFields =  new Set<String>(APIList);
            
            //Get only those WO fields which have to be populated
            for (String fieldKey : souObjfieldMap.keySet()) 
            {
                String fieldName='';
                Schema.SObjectField fsObj = souObjfieldMap.get(fieldKey); 
                Schema.DescribeFieldResult f = fsObj.getDescribe();
                fieldName = f.getName();
                
                if(setWOFields.contains(fieldName))
                    newSchemaFieldMap.put(fieldName, fsObj);
            }
            
            DCON_Utils.referenceFields_WP reference_M = 
                dcUtils1.SVMX_getReferenceFields(newSchemaFieldMap,true);    
            newSchemaFieldMap.clear();
            souObjfieldMap.clear();
            
            List<String> limitedFields_L = reference_M.allFields_L; //Get the all field list
            refFields_L = reference_M.referenceFields_L; //Get the reference field list
            dateTimeFields_L = reference_M.dateTimeFields_L; //Get the dateTime field list
            dateFields_L = reference_M.dateFields_L; //Get the date field list
            replacementRef = reference_M.replacementReference_M;  //Get the replacement reference field map
            replacementNameField = reference_M.replacementField_M;  //Get the name field for reference map
            queryStr = utils.SVMX_getFieldNamesFromList(limitedFields_L); //Convert the list of strings to coma seperated string
            system.debug('queryStr = '+queryStr);
            //Check for User TimeZone
            String timeZone;
            String UserId;
            //Check if UserId exists in the parameter passed
            if(splitFileds.size() > 1)
                UserId = splitFileds[1];
                
            try 
            {
                if(!UserId.equals(Userinfo.getUserId()))
                    timeZone = [SELECT TimeZoneSidKey from User where Id = :UserId].TimeZoneSidKey;
                else
                    timeZone = Userinfo.getTimeZone().getID();
            }
            catch(Exception ex)
            {
                timeZone = Userinfo.getTimeZone().getID();
            }

            DCON_Work_Order_WS.workorder_WP workorder_WP;
            List<DCON_Work_Order_WS.workorderSpecialFields_WP> specialFields_LWP;
            String eventSubject = '';

            try
            {
                if(FieldMapList!=null && FieldMapList.size()>0){
                    for(SVMXC__Service_Order__c workOrderObj:  Database.query('Select ' + queryStr + ' From SVMXC__Service_Order__c ' + '  where Id =: WId')) {

                        specialFields_LWP = new List<DCON_Work_Order_WS.workorderSpecialFields_WP>();

                        for(String s : refFields_L){
                            DCON_Work_Order_WS.workorderSpecialFields_WP tRef;
                            Sobject ref_TO = workOrderObj.getSobject(replacementRef.get(s));
                            if(ref_TO!=NULL){
                                tRef = new DCON_Work_Order_WS.workorderSpecialFields_WP(s, String.valueof(ref_TO.get(replacementNameField.get(s))) );
                                specialFields_LWP.add(tRef);
                            }
                        }

                        for(String s : dateTimeFields_L){
                            DCON_Work_Order_WS.workorderSpecialFields_WP tDateTime;
                            if(workOrderObj.get(s) != NULL){
                                tDateTime = new DCON_Work_Order_WS.workorderSpecialFields_WP(s, dcUtils1.getDateTimeInTimezone(Datetime.valueof(workOrderObj.get(s)).date(), Datetime.valueof(workOrderObj.get(s)).time(), timeZone).format() );
                                system.debug('yat tDateTime' + tDateTime);
                                specialFields_LWP.add(tDateTime);
                            }
                        }

                        for(String s : dateFields_L){
                            DCON_Work_Order_WS.workorderSpecialFields_WP tDate;
                            if(workOrderObj.get(s) != NULL){
                                tDate = new DCON_Work_Order_WS.workorderSpecialFields_WP(s, Date.valueof(String.valueof(workOrderObj.get(s))).format() );
                                specialFields_LWP.add(tDate);
                            }
                        }
                        for (String APIvalue : APIList) 
                {   
                     //string str = String.valueOf(workOrderObj.get(APIvalue));
                   if(String.valueOf(workOrderObj.get(APIvalue)) !=null)
                   {
                       fieldValue = null;
                       if(wofieldMapping.get(APIvalue).getDescribe().getType() == Schema.DisplayType.Reference) {
                            if(APIvalue == 'SVMXC__Case__c')
                                fieldValue = (String) workOrderObj.getSobject('SVMXC__Case__r').get('casenumber');
                            else if(APIvalue.equalsIgnoreCase('createdById'))
                                fieldValue = workOrderObj.CreatedBy.Name;
                            else if(APIvalue.equalsIgnoreCase('LastModifiedById'))
                                fieldValue = workOrderObj.LastModifiedBy.Name;
                            else if(APIvalue.equalsIgnoreCase('OwnerId'))
                                fieldValue = workOrderObj.Owner.Name;
                            else    
                                fieldValue = (String) workOrderObj.getSobject(APIvalue.substringBeforeLast('__c')+'__r').get('Name');
                       } else {
                           fieldValue = String.valueOf(workOrderObj.get(APIvalue));
                       }
                       if(eventSubject == '')
                       {
                           eventSubject = fieldValue;
                       }else{
                           eventSubject = eventSubject+';'+fieldValue;
                       }
                   }
                    
                }
                        workorder_WP = new DCON_Work_Order_WS.workorder_WP(workOrderObj,specialFields_LWP);
                        workorder_LWP.add(workorder_WP);
                        system.debug('workorder_WP :'+workorder_WP);
                    }
                }
            }
            catch(Exception ex){
                system.debug(LoggingLevel.DEBUG, 'Exception: Type - ' + ex.getTypeName() + '; Line No. - ' + ex.getLineNumber() + '; Cause - ' + ex.getCause() + '; Message - ' + ex.getMessage()+ '; Stack Trace - ' + ex.getStackTraceString());
             throw new DCX_CommonServiceManager.DCxException(ex.getmessage());
            }

           /* String jsonStr = JSON.serialize(workorder_LWP);
            //Defect #034133 - Added below code to display the fields of 'event subject rule' in sequence order. 
            List<DCON_Work_Order_WS.workorderSpecialFields_WP> subjectRuleSequence = new List<DCON_Work_Order_WS.workorderSpecialFields_WP>();
            DCON_Work_Order_WS.workorder_WP workorder_WP_Seq;
            DCON_Work_Order_WS.workorderSpecialFields_WP tempsubjectRuleSequence;
            Integer sequenceNo = 0;
            for (String APIvalue : APIList) 
                {   sequenceNo = sequenceNo + 1;
                    tempsubjectRuleSequence = new DCON_Work_Order_WS.workorderSpecialFields_WP(String.valueOf(sequenceNo),APIvalue);
                    subjectRuleSequence.add(tempsubjectRuleSequence);
                    
                }
            workorder_WP_Seq = new DCON_Work_Order_WS.workorder_WP(null,subjectRuleSequence);
            String jsonStr_Subject_rule_sequence = JSON.serialize(workorder_WP_Seq);
            String jsonStr1 = jsonStr + '~|' + jsonStr_Subject_rule_sequence;
            evtSubRuleLst.add(jsonStr1);*/
            //END: DNS-623
            return eventSubject;
        } 

    public static eventUpsertTechChangeResponse upsertEventOnTechChange(List<Event> lstEvent, 
                                                                        String woId, String timeZone, 
                                                                        list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                                                                        String techId,
                                                                        Boolean updatePrimaryTech,
                                                                        Boolean deleteEventForOtherTechs,
                                                                        String techSFId,
                                                                        Boolean updateWorkOrder,
                                                                        List<String> woFields) {
        List<String> deletedEventIds = new List<String>();
        String UserId = UserInfo.getUserId();
        Schema.Describesobjectresult discResUser = User.sObjectType.getDescribe();
        User.sObjectType.getDescribe();
        Schema.Describesobjectresult discWorkOrder = SVMXC__Service_Order__c.sObjectType.getDescribe();
        Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
        Map<String, SObjectField> souObjfieldMapSVMXEVT = Schema.SObjectType.SVMXC__SVMX_Event__c.fields.getMap();
        Map<String,String> SVMXEVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapSVMXEVT);
        Map<String,String> EVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapEVT);
        souObjfieldMapSVMXEVT.clear();
        souObjfieldMapEVT.clear();
        Map<String, String> mapEventSettings = new Map<String, String>();
        Map<String,String> settingvalues = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET001','SET073',null);
        Map<String, String> mapNewSettings = new Map<String, String>();
        DCON_Work_Order_WS.workorder_WP workOrderObj = new DCON_Work_Order_WS.workorder_WP();
        List<DCX_CommonServiceManager.Events_WP> lstEventWPs = 
            new List<DCX_CommonServiceManager.Events_WP>();
        DCX_CommonServiceManager.Events_WP event_WPObj = new DCX_CommonServiceManager.Events_WP();
        List<String> woIds = new List<String>();
        set<String> setAvailableTechnicains = new set<String>();
        Set<String> lstWOID = new Set<String>();
        Set<String> lstTechID = new Set<String>();
        Map<String, DateTime> mapEventIDScheduledDatetime = new Map<String, DateTime>();
        Map<String, DateTime> mapWorkOrderIDScheduledDatetime = new Map<String, DateTime>();
        DateTime scheduledDateTime;
        String workOrderId;
        SVMXC__Service_Order__c woRec = new SVMXC__Service_Order__c();
        List<Event> lstSFEvents = new List<Event>();
        eventUpsertTechChangeResponse resp = new eventUpsertTechChangeResponse();
        Schema.Describesobjectresult objEvent = Event.sObjectType.getDescribe();
        String EventKey = objEvent.getKeyPrefix();
        Schema.Describesobjectresult objUser = User.sObjectType.getDescribe();
        String UserKey = objUser.getKeyPrefix();
        List<Event> SFEvents = new  List<Event>();
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        SVMXC__Service_Group_Members__c emptyTech = new SVMXC__Service_Group_Members__c();
        Boolean insertRecord = false;
        List<String> EventDelList = new  List<String>();
        Map<Id,SVMXC__Service_Order__c> updatedWOMap = new Map<Id,SVMXC__Service_Order__c>();
        DCX_EventServiceManager_Util eventServiceUtil = new DCX_EventServiceManager_Util();                                                                    
        Map<String,String> woEvtUpdateFieldMap = getConfiguredEventFieldsSET38To47(settingvalues);
        system.debug('settingvalues '+settingvalues);
        system.debug('woEvtUpdateFieldMap :'+woEvtUpdateFieldMap );
        Set<String> evtUpdateFields = getConfiguredEventFields(woEvtUpdateFieldMap);
        String sfQuery;
        system.debug('evtUpdateFields :'+evtUpdateFields);
        try {
            system.debug('Event Id = '+lstEvent[0].Id);
            
            if(woEvtUpdateFieldMap.keySet().size() > 0)
            {
                for(String strfld : woEvtUpdateFieldMap.keySet()) {
                    if((woEvtUpdateFieldMap.containsKey(strfld)) && 
                        (String.valueOf(woEvtUpdateFieldMap.get(strfld)).contains('Event.'))) {
                        List<String> Evtfield = String.valueOf(woEvtUpdateFieldMap.get(strfld)).split('Event.',2);
                        mapEventSettings.put(strfld,Evtfield[1]);
                    } 
                }
            }
            
            
                for(DCON_Configuration_WS.SVMX_StringMap oSVMX_StringMap :lstKeyValue) {
                    list<string> lststr = new list<string>();
                    lststr = oSVMX_StringMap.Key.split('_');
                    if(lststr != null && lststr.size() > 1) {
                        /*if(lststr[0] != null && lststr[0].toUpperCase() == 'IDLE') {
                            idleDuration = Integer.valueOf(oSVMX_StringMap.Value);
                        }
                        if(lststr[0] != null && lststr[0].toUpperCase() == 'DRIVE') {
                            driveDuration = Integer.valueOf(oSVMX_StringMap.Value);
                        }
                        if(lststr[0] != null && lststr[0].toUpperCase() == 'SERVICE') {
                            serviceDuration = Integer.valueOf(oSVMX_StringMap.Value);
                        }
                        if(lststr[0] != null && lststr[0].toUpperCase() == 'SCOPE') {
                            woScope = Integer.valueOf(oSVMX_StringMap.Value);
                        }
                        if(lststr[0] != null && lststr[0].toUpperCase() == 'VARIANCE') {
                            woVariance = Integer.valueOf(oSVMX_StringMap.Value);
                        }*/
                    } else {
                        if(oSVMX_StringMap.Value.toUpperCase() == 'DATE')
                            mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateValue));
                        else if(oSVMX_StringMap.Value.toUpperCase() == 'DATETIME')
                            mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateTimeValue));
                        else
                            mapNewSettings.put(oSVMX_StringMap.Key,oSVMX_StringMap.Value);
                        }
                }
            
             
            List<SVMXC__SVMX_Event__c> lstSVMXEvents = new List<SVMXC__SVMX_Event__c>();
            Boolean isError = false;
            String eventId;

            if(timeZone == NULL || timeZone == '') {
                timeZone = [SELECT TimeZoneSidKey from User where Id = :UserId].TimeZoneSidKey;
            }

            if(settingvalues.containsKey('DCON001_SET027') && 
                (settingvalues.get('DCON001_SET027').toUpperCase()=='DISALLOW'))      
                checkDoublebookingforTech(lstEvent,timeZone,discResUser.getKeyPrefix(),settingvalues); 
            
            for(Event oEvent: lstEvent){
                if(oEvent != null && oEvent.OwnerId != null && 
                    String.valueof(oEvent.OwnerId).startsWith(discResUser.getKeyPrefix()) == false)
                    setAvailableTechnicains.add(oEvent.OwnerId);
            }
            setAvailableTechnicains = getEventEnablesTechnicians(setAvailableTechnicains);

            for(Event oEvent: lstEvent) {
                    //DC only supports WO Event and non associated event creation
                    //Therefore the below check is sufficient ( 'other event' case can be relaxed here)
                    //OPT-493
                    //We have added extra check to add only workorder Id if whatID of event as workorder ID
                if(oEvent.WhatId != NULL) {
                    String woKeyPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                    if(woKeyPrefix.equals(String.valueOf(oEvent.WhatId).substring(0,3))) {
                            lstWOID.add(oEvent.WhatId);
                    }   
                }
                if(woId != null)
                    workOrderId = woId;
                scheduledDateTime = 
                    dcUtils.getDateTimeInTimezone(DateTime.valueof(oEvent.ActivityDateTime).dateGmt(),
                                                  DateTime.valueof(oEvent.ActivityDateTime).timeGmt(),
                                                  timeZone);
                if(oEvent!=NULL) {

                    if(String.Valueof(oEvent.Id).startsWith(EventKey)) {
                        if(String.Valueof(oEvent.OwnerId).startsWith(UserKey)) {
                            Event TempSFEvent = populateSFEventDetails(oEvent,mapNewSettings,
                                                                       mapEventSettings,
                                                                       timeZone,
                                                                       EVTFieldDef);
                            TempSFEvent.Id = oEvent.Id;
                            lstSFEvents.add(TempSFEvent);
                        }
                        else {
                            if(setAvailableTechnicains.contains(oEvent.OwnerId)) {
                                EventDelList.add(oEvent.Id);
                                oEvent.Id = null;
                                insertRecord = true;
                                lstSVMXEvents.add(populateSVMXEventDetails(oEvent,mapNewSettings,
                                                                            mapEventSettings,timeZone,
                                                                            SVMXEVTFieldDef));
                            }
                        }
                    
                    } else {

                        if(String.Valueof(oEvent.OwnerId).startsWith(UserKey)==false) {
                            SVMXC__SVMX_Event__c TempSVMXEvent = populateSVMXEventDetails(oEvent,mapNewSettings,
                                                                                        mapEventSettings,
                                                                                        timeZone,
                                                                                        SVMXEVTFieldDef);
                            TempSVMXEvent.Id = oEvent.Id;
                            lstSVMXEvents.add(TempSVMXEvent);
                        } else {
                            EventDelList.add(oEvent.Id);
                            oEvent.Id = null;
                            insertRecord = true;
                            lstSFEvents.add(populateSFEventDetails(oEvent,mapNewSettings,
                                                                    mapEventSettings,
                                                                    timeZone,EVTFieldDef));
                        }
                    }
                }
            }
            
            if(lstSFEvents.size()>0){
                List<Event> sfLstEvents = new List<Event>();
                //COMM_SecurityUtils.getinstance().upsertAsUser(lstSFEvents); 
                eventServiceUtil.upsertSFEventsUtil(lstSFEvents);
                String evtQuery = 'Select Id,Subject,durationInMinutes,description,WhatId,WhoId,ActivityDate,ActivityDateTime,'
                                    +'StartDateTime,Location,OwnerId,SVMXC__Driving_Time__c,SVMXC__Overhead_Time_Before__c,'
                                    +'SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,SVMXC__Service_Duration__c,'
                                    +'SVMXC__Break_Time_Total__c,Type,IsAllDayEvent,SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,'
                                    +'Owner.Name';
                String whereEvtClause = ' from Event where Id in :lstSFEvents';
                if(evtUpdateFields.size() > 0) {
                    sfQuery = 'Select ' + SVMX_getFieldNamesFromList(combineEventFields(evtUpdateFields)) + whereEvtClause;
                    sfLstEvents = eventServiceUtil.retrieveSFEventsUtil(sfQuery,lstSFEvents);
                    //sfLstEvents = Database.query('Select ' + SVMX_getFieldNamesFromList(combineEventFields(evtUpdateFields)) + whereEvtClause);
                } else {
                    sfQuery = evtQuery + whereEvtClause;
                    sfLstEvents = eventServiceUtil.retrieveSFEventsUtil(sfQuery,lstSFEvents);
                    //sfLstEvents = Database.query(evtQuery + whereEvtClause);
                }
                if(tech == emptyTech && String.valueof(techId).startsWith(UserKey) == false) {
                    tech = [SELECT Id, Name,SVMXC__Salesforce_User__c, 
                                    SVMXC__Service_Group__c, 
                                    SVMXC__Service_Group__r.SVMXC__Email__c, 
                                    SVMXC__Enable_Scheduling__c, 
                                    SVMXC__Email__c from 
                                    SVMXC__Service_Group_Members__c 
                                    where Id = :techId];
                }
                for(event evt : sfLstEvents) {
                    lstEventWPs.add(populateSFEventInfoDetails(evt,tech,mapEventSettings,EVTFieldDef));
                }
            }

            if(lstSVMXEvents.size()>0) {
                List<SVMXC__SVMX_Event__c> svmxEvents = new List<SVMXC__SVMX_Event__c>();
                COMM_SecurityUtils.getinstance().upsertAsUser(lstSVMXEvents);
                String evtSVMXQuery = 'Select Id,Name,SVMXC__DurationInMinutes__c,SVMXC__Description__c,SVMXC__WhatId__c,'
                                        +'SVMXC__WhoId__c,SVMXC__ActivityDate__c,SVMXC__ActivityDateTime__c,SVMXC__StartDateTime__c,'
                                        +'SVMXC__EndDateTime__c,SVMXC__Location__c,SVMXC__Technician__c,SVMXC__Driving_Time__c,'
                                        +'SVMXC__Overhead_Time_Before__c,SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,'
                                        +'SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,SVMXC__Type__c,SVMXC__IsAllDayEvent__c,'
                                        +'SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,SVMXC__Technician__r.Name';
                String whereSVMXClause = ' from SVMXC__SVMX_Event__c where Id in :lstSVMXEvents';
                if(evtUpdateFields.size() > 0) {
                    svmxEvents = Database.query( 'Select ' + SVMX_getFieldNamesFromList(combineSVMXEventFields(evtUpdateFields)) 
                                                + whereSVMXClause);
                } else {
                    svmxEvents = Database.query(evtSVMXQuery + whereSVMXClause);
                }
                for(SVMXC__SVMX_Event__c evt : svmxEvents) {
                    lstEventWPs.add(populateSVMXEventInfoDetails(evt,mapEventSettings,SVMXEVTFieldDef));
                }
            }
            resp.lstEvent = lstEventWPs;
            
            if(workOrderId != null) {
                
                if(updatePrimaryTech) {
                    tech = [SELECT Id, SVMXC__Salesforce_User__c, 
                                    SVMXC__Service_Group__c, Name,
                                    SVMXC__Service_Group__r.SVMXC__Email__c, 
                                    SVMXC__Enable_Scheduling__c, SVMXC__Email__c from 
                                    SVMXC__Service_Group_Members__c 
                                    where Id = :techId];
                    if(tech.SVMXC__Service_Group__c != null)
                        woRec.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
                    if(tech.SVMXC__Email__c != null)
                        woRec.SVMXC__Member_Email__c = tech.SVMXC__Email__c;
                    if(tech.SVMXC__Service_Group__r.SVMXC__Email__c != null)
                        woRec.SVMXC__Group_Email__c = tech.SVMXC__Service_Group__r.SVMXC__Email__c;
                    woRec.SVMXC__Group_Member__c = techId;
                    if(settingvalues.containsKey('DCON001_SET009') && 
                       settingvalues.get('DCON001_SET009').toUpperCase()=='TRUE' && 
                       (techSFId != null && techSFId != ''))
                        woRec.OwnerId = techSFId;
                }
                
                woRec.Id = workOrderId;
                woRec.SVMXC__Scheduled_Date_Time__c = scheduledDateTime; 
                woRec.SVMXC__Last_Dispatch_Event__c = 'Scheduled';
                
                DCX_Utils.updateWorkOrder(woRec,lstKeyValue,timeZone,woEvtUpdateFieldMap);
            }
            
            if(deleteEventForOtherTechs) {
                //deletedEventIds = deleteEventForWO(woId,lstEvent[0].Id,techId,techSFId,settingvalues);
                deletedEventIds = eventServiceUtil.deleteEventForWOUtil(woId,lstEvent[0].Id,techId,techSFId,settingvalues);
            }
            if(EventDelList.size() > 0) {
                //deleteEvents(EventDelList);
                eventServiceUtil.deleteEventsUtil(EventDelList);
            }
            if(EventDelList.size() > 0)
                deletedEventIds.addAll(EventDelList);
            system.debug('Deleted Events = '+deletedEventIds);
            if(deletedEventIds.size() > 0)
                resp.deletedEventIds = deletedEventIds; 
            
            
            resp.settingValues = woEvtUpdateFieldMap;
            return resp;
        } catch (Exception ex) {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
        }
    }

    /*public static List<String> deleteEventForWO(String workOrderId,String eventId,String techId,String techSFId,Map<String,String> settingvalues) {
        List<String> deletedEventIds = new List<String>();
        List<Event> events = new List<Event>();
        List<Event> finalEvents = new List<Event>();
        List<SVMXC__SVMX_Event__c> SVMXevents = new List<SVMXC__SVMX_Event__c>();
        List<SVMXC__SVMX_Event__c> finalSVMXevents = new List<SVMXC__SVMX_Event__c>();
        if(settingvalues.Containskey('DCON001_SET024') && settingvalues.get('DCON001_SET024')=='True') {
            events = [SELECT Id from event where WhatId = :workOrderId and OwnerId != :techSFId 
                      and Id != :eventId];
            SVMXevents = [SELECT Id from SVMXC__SVMX_Event__c where SVMXC__WhatId__c = :workOrderId and
                          SVMXC__Technician__c != :techId and Id != :eventId];
 
            
        } else {
            events = [SELECT Id from event where WhatId = :workOrderId and StartDateTime > :System.now()
                      and OwnerId != :techSFId and Id != :eventId];
            SVMXevents = [SELECT Id from SVMXC__SVMX_Event__c where SVMXC__WhatId__c = :workOrderId 
                          and SVMXC__StartDateTime__c > :System.now() and Id != :eventId and
                          SVMXC__Technician__c != :techId];

        }

        if(events.size() > 0) {
            for (Event ev : events)
                deletedEventIds.add(ev.Id);
            COMM_SecurityUtils.getinstance().deleteAsUser(events);
        }
        if(SVMXevents.size() > 0) {
            for (SVMXC__SVMX_Event__c svmxEv : SVMXevents)
                deletedEventIds.add(svmxEv.Id);
            COMM_SecurityUtils.getinstance().deleteAsUser(SVMXevents);
        }

        return deletedEventIds;
    }  
    */
    public Static void deleteEvents(List<String> eIds) {
        List<Event> SalesforceEventList = [SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id 
                                           IN :eIds];
        List<SVMXC__SVMX_Event__c> ServiceMaxEventList = [SELECT Id, SVMXC__ActivityDateTime__c, 
                                                          SVMXC__WhatId__c, SVMXC__Technician__c 
                                                          from SVMXC__SVMX_Event__c where Id IN :eIds];
        if(SalesforceEventList.size() > 0)
            COMM_SecurityUtils.getinstance().deleteAsUser(SalesforceEventList);
        if(ServiceMaxEventList.size() > 0)
            COMM_SecurityUtils.getinstance().deleteAsUser(ServiceMaxEventList);
    }

    public static DCX_CommonServiceManager.DCEvent_WO_WP DCX_Upsert_Events_WS4(String UserId, 
                                                                               List<Event> Events, 
                                                                               String timeZone, 
                                                                               list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                                                                               String techId,
                                                                               String techSFId,
                                                                               List<String> woFields)
    {
        String StatusMessage;
        DCX_EventServiceManager_Util eventServiceUtil = new DCX_EventServiceManager_Util();   
        List<Event> SFEvents = new  List<Event>();
        List<Event> lstEventstoCreate = new  List<Event>();
        List<Event> SVMXEvents = new  List<Event>();
        List<String> EventDelList = new  List<String>();
        List<SVMXC__SVMX_Event__c> TempSVMXEventList = new List<SVMXC__SVMX_Event__c>();
        List<Event> UpsertSFEventlist = new List<Event>();
        List<SVMXC__SVMX_Event__c> UpsertSVMXEventlist = new List<SVMXC__SVMX_Event__c>();
        set<String> SVMXEventIds = new set<String>();
        set<String> SFEventIds = new set<String>();
        set<String> givenEventIds = new set<String>();
        Map<String, String> mapEventSettings = new Map<String, String>();
        Map<String, String> mapNewSettings = new Map<String, String>();
        List<String> lstEventId = new List<String>();
        set<String> setAvailableTechnicains = new set<String>();
        Set<String> techSalesforceIds = new Set<String>();
        Schema.Describesobjectresult discResUser = User.sObjectType.getDescribe();
        User.sObjectType.getDescribe();
        Schema.Describesobjectresult discWorkOrder;  
        DCX_CommonServiceManager.DCEvent_WO_WP eventsData = 
            new DCX_CommonServiceManager.DCEvent_WO_WP();
        DCON_Work_Order_WS.workorder_WP workOrderObj = new DCON_Work_Order_WS.workorder_WP();
        List<DCX_CommonServiceManager.Events_WP> lstEventWPs = 
            new List<DCX_CommonServiceManager.Events_WP>();
        DCX_CommonServiceManager.Events_WP event_WPObj = new DCX_CommonServiceManager.Events_WP();      
        List<String> woIds = new List<String>();
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        Map<Id,SVMXC__Service_Group_Members__c> techSFIdMap = 
            new Map<Id,SVMXC__Service_Group_Members__c>();
        Map<Id,SVMXC__Service_Order__c> updatedWOMap = new Map<Id,SVMXC__Service_Order__c>();
        system.debug(loggingLevel.warn,'REQUEST: ' + timeZone + Events);
        
        discWorkOrder = SVMXC__Service_Order__c.sObjectType.getDescribe();
        
        Map<String,String> WOFieldDef = new Map<String,String>();    
        Map<String, SObjectField> souObjfieldMapWO = Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap();
        WOFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapWO);        
        Map<String,String> EVTFieldDef = new Map<String,String>();
        Map<String, SObjectField> souObjfieldMapEVT = Schema.SObjectType.Event.fields.getMap();
        EVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapEVT);         
        Map<String,String> SVMXEVTFieldDef = new Map<String,String>();
        Map<String, SObjectField> souObjfieldMapSVMXEVT = Schema.SObjectType.SVMXC__SVMX_Event__c.fields.getMap();
        SVMXEVTFieldDef = dcUtils.SVMX_getAllFieldMap(souObjfieldMapSVMXEVT);        
    
        souObjfieldMapWO.clear();
        souObjfieldMapEVT.clear();
        souObjfieldMapSVMXEVT.clear();
        Map<String,String> settingvalues = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET001','SET073',null);
        Map<String,String> woEvtUpdateFieldMap = getConfiguredEventFieldsSET38To47(settingvalues);
        Set<String> evtUpdateFields = getConfiguredEventFields(woEvtUpdateFieldMap);
        //List<SVMXC__DC_Platform_Event__e> platformEvents = new List<SVMXC__DC_Platform_Event__e>();
        //SVMXC__DC_Platform_Event__e pe;
        SVMXC__Service_Order__c woRec;
        system.debug('Upsert Event settingvalues : '+ settingvalues);
        
        if(woEvtUpdateFieldMap.keySet().size() > 0)
        {
            for(String strfld : woEvtUpdateFieldMap.keySet())
            {
                if((woEvtUpdateFieldMap.containsKey(strfld)) && (String.valueOf(woEvtUpdateFieldMap.get(strfld)).contains('Event.')))
                {
                    List<String> Evtfield = String.valueOf(woEvtUpdateFieldMap.get(strfld)).split('Event.',2);
                    mapEventSettings.put(strfld,Evtfield[1]);
                } 
            }
        } 

        for(DCON_Configuration_WS.SVMX_StringMap oSVMX_StringMap :lstKeyValue) {
            list<string> lststr = new list<string>();
            lststr = oSVMX_StringMap.Key.split('_');
            if(lststr != null && lststr.size() > 1) {
                /*if(lststr[0] != null && lststr[0].toUpperCase() == 'IDLE') {
                    idleDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'DRIVE') {
                    driveDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'SERVICE') {
                    serviceDuration = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'SCOPE') {
                    woScope = Integer.valueOf(oSVMX_StringMap.Value);
                }
                if(lststr[0] != null && lststr[0].toUpperCase() == 'VARIANCE') {
                    woVariance = Integer.valueOf(oSVMX_StringMap.Value);
                }*/
            } else {
                if(oSVMX_StringMap.Value.toUpperCase() == 'DATE')
                    mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateValue));
                else if(oSVMX_StringMap.Value.toUpperCase() == 'DATETIME')
                    mapNewSettings.put(oSVMX_StringMap.Key,string.valueOf(oSVMX_StringMap.DateTimeValue));
                else
                    mapNewSettings.put(oSVMX_StringMap.Key,oSVMX_StringMap.Value);
            }
        }

        Map<String, SVMXC__SVMX_Event__c> SVMXEventMap = new Map<String, SVMXC__SVMX_Event__c>();
        Map<String, Event> SFEventMap = new Map<String, Event>();
       
        
        if(Events.size()==0)
            //throw new SVMXException('Please provide some events to insert');
        Boolean isError = false;
        Boolean isEventExist = false;
        String errMessage;
        boolean supportNonWorkOrdEvent = true;

        try
        {
            //Check for User TimeZone
            if(timeZone == null || timeZone == '')
                timeZone = [SELECT TimeZoneSidKey from User where Id = :UserId].TimeZoneSidKey;
                
            Schema.Describesobjectresult objEvent = Event.sObjectType.getDescribe();
            String EventKey = objEvent.getKeyPrefix();
            Schema.Describesobjectresult objUser = User.sObjectType.getDescribe();
            String UserKey = objUser.getKeyPrefix();
            String TempEventId;
            String TempOwnerId;
            set<String> availableTechnicains = new set<String>();
            list<event> lstEventUpdated = new list<event>();
            //Check for Technicians with SVMXC__Enable_Scheduling__c = true
            for(Event e: Events)
            {
                Event oEvent = e;
                string eventId;
                eventId = e.id;
                System.debug('eventId: '+eventId);
                if(eventId != null && eventId != '' && eventId != null)
                {
                    lstEventUpdated.add(e);
                    //Apurva:  Defect - 033903 
                    
                }
                DateTime eventStartTime = dcUtils.getDateTimeInTimezone(DateTime.valueof(oEvent.ActivityDateTime).dateGmt(), DateTime.valueof(oEvent.ActivityDateTime).timeGmt(), timeZone);
                DateTime eventEndTime = DateTime.valueof(eventStartTime).addMinutes(Integer.valueof(oEvent.DurationInMinutes));

                givenEventIds.add(e.Id);
                if(String.valueof(e.OwnerId).startsWith(UserKey) == false){
                    availableTechnicains.add(e.OwnerId);
                } else {
                    techSalesforceIds.add(e.OwnerId);
                }
            }

            //Check Double Booking if setting is enabled 
            system.debug('lstEventUpdated: '+lstEventUpdated);
            if(settingvalues != NULL && settingvalues.containskey('DCON001_SET027') && 
                settingvalues.get('DCON001_SET027').toUpperCase()=='DISALLOW')
            {
                if(lstEventUpdated.size()>0)
                    checkDoublebookingforTech(lstEventUpdated,timeZone,UserKey,settingvalues);
            }
            availableTechnicains = getEventEnablesTechnicians(availableTechnicains);
            //Setting the scheduled date time
            Set<String> wo_TL = new Set<String>();
            Set<String> tech_TL = new Set<String>();
            Map<String, DateTime> event_scheduleDate = new Map<String, DateTime>();
            Map<String, DateTime> onlyWo_scheduleDate = new Map<String, DateTime>();
            String woId = null;
            DateTime activityDate;
            for(Event EventItm: Events){
                string eventId;
                eventId = EventItm.id;
                //Make the list of new Events here, to judge when to enable WO triggers execution
                system.debug('eventId = ' + eventId );
                if(eventId == null || eventId == '')
                    lstEventstoCreate.add(EventItm);

                if(EventItm.WhatId != NULL)
                    wo_TL.add(EventItm.WhatId);
                if(EventItm.OwnerId != NULL)
                    tech_TL.add(EventItm.OwnerId);

                woId = EventItm.WhatId;
                activityDate =  dcUtils.getDateTimeInTimezone(DateTime.valueof(EventItm.ActivityDateTime).dateGmt(), DateTime.valueof(EventItm.ActivityDateTime).timeGmt(), timeZone);
                event_scheduleDate.put(EventItm.WhatId+''+EventItm.OwnerId,dcUtils.getDateTimeInTimezone(DateTime.valueof(EventItm.ActivityDateTime).dateGmt(), DateTime.valueof(EventItm.ActivityDateTime).timeGmt(), timeZone));
                onlyWo_scheduleDate.put(EventItm.WhatId,dcUtils.getDateTimeInTimezone(DateTime.valueof(EventItm.ActivityDateTime).dateGmt(), DateTime.valueof(EventItm.ActivityDateTime).timeGmt(), timeZone));
            }
            for(Event e: Events)
            {
                TempEventId = e.Id;
                TempOwnerId = e.OwnerId;
                if(TempEventId == null || TempEventId == '')
                    continue;
                
                else if(TempEventId.startsWith(EventKey))
                {
                    if(TempOwnerId.startsWith(UserKey)) {
                        SFEvents.add(e);
                        SFEventIds.add(TempEventId);
                    }
                    else
                    {
                        if(availableTechnicains.contains(e.OwnerId))
                        {
                            //Salesforce event is trying to change as ServiceMax User
                            //Delete the existing Event
                            EventDelList.add(e.Id);
                            //Insert the ServiceMax event
                            UpsertSVMXEventlist.add(populateSVMXEventDetails(e,mapNewSettings,
                                                                             mapEventSettings,timeZone,
                                                                             SVMXEVTFieldDef));
                        }
                    }
                }
                else
                {
                    if(TempOwnerId.startsWith(UserKey)==false)
                    {
                        SVMXEvents.add(e);
                        SVMXEventIds.add(e.Id);
                    }
                    else
                    {
                        //ServiceMax event is trying to change as Salesforce User
                        //Delete the existing Event
                        EventDelList.add(e.Id);
                        //Insert the Salesforce event
                        UpsertSFEventlist.add(populateSFEventDetails(e,mapNewSettings,mapEventSettings,
                                                                     timeZone,EVTFieldDef));
                    }
                }
            }
            system.debug('SVMXEventIds = '+SVMXEventIds);
            if(SVMXEventIds.size()>0){
                for(SVMXC__SVMX_Event__c SVMXe: [Select Id, SVMXC__ActivityDate__c, SVMXC__ActivityDateTime__c, SVMXC__Technician__c, SVMXC__DurationInMinutes__c, Name,SVMXC__Description__c, SVMXC__WhatId__c, SVMXC__StartDateTime__c, SVMXC__EndDateTime__c from SVMXC__SVMX_Event__c where Id IN :SVMXEventIds]){  
                    SVMXEventMap.put(SVMXe.Id, SVMXe);
                }
            }
            //Apurva:  Defect - 033903 
            if(SFEventIds.size()>0)
            {
                SFEventMap = new map<string,Event>([Select Id, ActivityDate, IsAllDayEvent, 
                                                    ActivityDateTime, OwnerId, DurationInMinutes, 
                                                    Subject,Description, WhatId, StartDateTime 
                                                    from Event Where Id IN :SFEventIds]);
            }
            //Salesforce Events
            for(Event e: SFEvents)
            {
                
                Event TempSFEvent = new Event();
                //Apurva:  Defect - 033903 
                if(e.Id  != NULL && SFEventMap.containskey(e.Id) && SFEventMap.get(e.Id)!=NULL){
                    
                    system.debug(LoggingLevel.Warn, 'TempSFEvent: ' +TempSFEvent);
                    system.debug(LoggingLevel.Warn, 'ActivityDateTime: ' + e.ActivityDateTime + '; ActivityDate: ' + e.ActivityDate+'  Event Id  '+ e.id);
                    //TempSFEvent = [Select Id, ActivityDate, IsAllDayEvent, ActivityDateTime, OwnerId, DurationInMinutes, Subject,Description, WhatId, StartDateTime from Event Where Id = :e.Id];
                    TempSFEvent = SFEventMap.get(e.Id);
                    TempSFEvent = populateSFEventDetails(e,mapNewSettings,
                                                         mapEventSettings,timeZone,
                                                         EVTFieldDef);
                    TempSFEvent.Id = e.Id;
                    UpsertSFEventlist.add(TempSFEvent);
                }
            }
            //ServiceMax Events
            for(Event e: SVMXEvents){
                SVMXC__SVMX_Event__c TempSVMXEvent = new SVMXC__SVMX_Event__c();
                if(SVMXEventMap.get(e.Id)!=NULL){
                    TempSVMXEvent = SVMXEventMap.get(e.Id);
                    TempSVMXEvent = populateSVMXEventDetails(e,mapNewSettings,
                                                             mapEventSettings,timeZone,
                                                             SVMXEVTFieldDef);
                    TempSVMXEvent.Id = e.Id;
                    system.debug('TempSVMXEvent = '+TempSVMXEvent);
                    UpsertSVMXEventlist.add(TempSVMXEvent);
                }
            }

            //If some conflicting events are there is there to delete
            if(EventDelList.size()>0) {
                //deleteEvents(EventDelList);
                eventServiceUtil.deleteEventsUtil(EventDelList);
            }
            
            /*for(Event oEvent : lstEventstoCreate) {
                if(oEvent != null && oEvent.OwnerId != null && 
                   String.valueof(oEvent.OwnerId).startsWith(discResUser.getKeyPrefix()) == false)
                    setAvailableTechnicains.add(oEvent.OwnerId);
            }
            setAvailableTechnicains = getEventEnablesTechnicians(setAvailableTechnicains);*/

            for(Event oEvent: lstEventstoCreate)
            {
                if(oEvent!=NULL)
                {
                    // Update the fields for SF events
                    if(String.valueof(oEvent.OwnerId).startsWith(discResUser.getKeyPrefix()))
                    {                    
                        UpsertSFEventlist.add(populateSFEventDetails(oEvent,mapNewSettings,
                                                                     mapEventSettings,
                                                                     timeZone,EVTFieldDef));
                    }
                    else
                    {
                        // Update the fields for SVMX events
                        if(availableTechnicains.contains(oEvent.OwnerId))
                        {
                            UpsertSVMXEventlist.add(populateSVMXEventDetails(oEvent,mapNewSettings,
                                                                             mapEventSettings,timeZone,
                                                                             SVMXEVTFieldDef));
                        }
                    }
                }
            }
            //If events are there to upsert
            system.debug('Upsert Event SFflds : '+ UpsertSFEventlist);
            system.debug('Upsert Event SVMXflds : '+ UpsertSVMXEventlist);
            //Defect fixed : BAC-4621 : Condition was wrong
            if(techSalesforceIds.size() > 0) {
                for (SVMXC__Service_Group_Members__c tcDt : [Select Id, Name, 
                                                             SVMXC__Salesforce_User__c from 
                                                             SVMXC__Service_Group_Members__c 
                                                             where SVMXC__Salesforce_User__c
                                                             In :techSalesforceIds])
                techSFIdMap.put(tcDt.SVMXC__Salesforce_User__c,tcDt);
            }

            if(woId != null){
                tech = [Select Id,SVMXC__Service_Group__c,SVMXC__Email__c, 
                        SVMXC__Service_Group__r.SVMXC__Email__c from SVMXC__Service_Group_Members__c 
                        where Id = :techId];
                woRec = new SVMXC__Service_Order__c();
                woRec.Id = woId;
                if(techSFId != null && techSFId != '' && settingvalues.containsKey('DCON001_SET009') && 
                    settingvalues.get('DCON001_SET009').toUpperCase()=='TRUE')
                    woRec.OwnerId = techSFId;
                woRec.SVMXC__Scheduled_Date_Time__c = activityDate;
                woRec.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
                woRec.SVMXC__Member_Email__c = tech.SVMXC__Email__c;
                woRec.SVMXC__Group_Email__c = tech.SVMXC__Service_Group__r.SVMXC__Email__c;
                woRec.SVMXC__Last_Dispatch_Event__c = 'Scheduled';
                woRec.SVMXC__Group_Member__c = techId;
            
            }

            if(UpsertSFEventlist.size() > 0 ) {
                List<Event> sfLstEvents = new List<Event>();
                //COMM_SecurityUtils.getinstance().upsertAsUser(UpsertSFEventlist); //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                eventServiceUtil.upsertSFEventsUtil(UpsertSFEventlist);
                String evtQuery = 'Select Id,Subject,durationInMinutes,description,WhatId,WhoId,ActivityDate,ActivityDateTime,'
                                    +'StartDateTime,Location,OwnerId,SVMXC__Driving_Time__c,SVMXC__Overhead_Time_Before__c,'
                                    +'SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,SVMXC__Service_Duration__c,'
                                    +'SVMXC__Break_Time_Total__c,Type,IsAllDayEvent,SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,'
                                    +'Owner.Name';
                String whereEvtClause = ' from Event where Id in :UpsertSFEventlist';
                if(evtUpdateFields.size() > 0) {
                    sfLstEvents = Database.query('Select ' + SVMX_getFieldNamesFromList(combineEventFields(evtUpdateFields)) + whereEvtClause);
                } else {
                    sfLstEvents = Database.query(evtQuery + whereEvtClause);
                }
                for(Event ev : sfLstEvents)
                    lstEventWPs.add(populateSFEventInfoDetails(ev,techSFIdMap.get(ev.OwnerId),mapEventSettings,EVTFieldDef));
            }
            
            if(UpsertSVMXEventlist.size() > 0 ) {
                List<SVMXC__SVMX_Event__c> upsertSVMXEvents = new List<SVMXC__SVMX_Event__c>();
                COMM_SecurityUtils.getinstance().upsertAsUser(UpsertSVMXEventlist); //SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                String evtSVMXQuery = 'Select Id,Name,SVMXC__DurationInMinutes__c,SVMXC__Description__c,SVMXC__WhatId__c,'
                                        +'SVMXC__WhoId__c,SVMXC__ActivityDate__c,SVMXC__ActivityDateTime__c,SVMXC__StartDateTime__c,'
                                        +'SVMXC__EndDateTime__c,SVMXC__Location__c,SVMXC__Technician__c,SVMXC__Driving_Time__c,'
                                        +'SVMXC__Overhead_Time_Before__c,SVMXC__Overhead_Time_After__c,SVMXC__Driving_Time_Home__c,'
                                        +'SVMXC__Service_Duration__c,SVMXC__Break_Time_Total__c,SVMXC__Type__c,SVMXC__IsAllDayEvent__c,'
                                        +'SVMXC__SM_Latitude__c,SVMXC__SM_Longitude__c,SVMXC__Technician__r.Name';
                String whereSVMXClause = ' from SVMXC__SVMX_Event__c where Id in :UpsertSVMXEventlist';
                if(evtUpdateFields.size() > 0) {
                    upsertSVMXEvents = Database.query('Select ' + SVMX_getFieldNamesFromList(combineSVMXEventFields(evtUpdateFields)) + whereSVMXClause);
                } else {
                    upsertSVMXEvents = Database.query(evtSVMXQuery + whereSVMXClause);
                }
                for(SVMXC__SVMX_Event__c evt : upsertSVMXEvents) {
                    lstEventWPs.add(populateSVMXEventInfoDetails(evt,mapEventSettings,SVMXEVTFieldDef));
                }
            }
            UserId = UserId +'_Upsert';
            if(woId != null) {
                updatedWOMap = DCX_Utils.updateAndReturnWorkOrder(woRec,lstKeyValue,timeZone,woEvtUpdateFieldMap,woFields);
                woIds.add(woId);
                workOrderObj.workorder_O = updatedWOMap.get(woId);
            }
            eventsData.lstEvent = lstEventWPs;
            eventsData.objWorkOrder = workOrderObj;
            eventsData.deletedEventIds = EventDelList;
        }
        catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
        }
        return eventsData; 
    }

    public static Map<Id,SVMXC__Service_Order__c> retrieveWorkOrdersForIds(List<String> woIds) {
        Map<Id,SVMXC__Service_Order__c> workOrderMap = new Map<Id,SVMXC__Service_Order__c>();
        string FieldMapRTypeId;
        string RuleRecordTypeId;
        Map<Id, SVMXC__ServiceMax_Processes__c> mapEventHoverRules  = 
            new Map<Id, SVMXC__ServiceMax_Processes__c>();
        Set<String> strWorkOrderFields = new Set<String>();
        String strQuery;
        String fieldNames = '';
        String lookUpFieldName = null;
        DCX_CommonServiceManager.UserSetting uSet = DCX_SettingServiceManager.fetchUserSettings();
        Map<String,Schema.SObjectField> wofieldMapping = 
            SVMXC__Service_Order__c.sObjectType.getDescribe().fields.getMap();
        strWorkOrderFields = DCX_Utils.wodefaultFields();
        strWorkOrderFields.addAll(DCX_Utils.getFieldUpdates());
        for(RecordType recType : [Select SobjectType, Id, Name From RecordType where 
                                  (SobjectType = 'SVMXC__ServiceMax_Processes__c' AND Name = 'SVMX Rule') OR
                                  (SobjectType = 'SVMXC__ServiceMax_Config_Data__c' AND Name IN 
                                  ('Expressions', 'Field Mapping'))]) {
            if(recType.Name == 'SVMX Rule')
                RuleRecordTypeId = recType.id;
            if(recType.Name == 'Field Mapping')
                FieldMapRTypeId = recType.id;
        }
        for(SVMXC__ServiceMax_Processes__c oPro : [Select SVMXC__Sequence__c,SVMXC__Advance_Expression__c, 
                                                   Id From SVMXC__ServiceMax_Processes__c  where 
                                                   RecordTypeId =:RuleRecordTypeId and 
                                                   SVMXC__Rule_Type__c = 'Event Hover Rule']) {
            mapEventHoverRules.put(oPro.Id, oPro);
        }
        for(SVMXC__ServiceMax_Config_Data__c objEventHoverField: [Select Id, SVMXC__Target_Field_Name__c,
                                                                  SVMXC__Sequence__c, 
                                                                  SVMXC__Expression_Rule__c From 
                                                                  SVMXC__ServiceMax_Config_Data__c where
                                                                  RecordTypeId = :FieldMapRTypeId and 
                                                                  SVMXC__Expression_Rule__c 
                                                                  IN :mapEventHoverRules.keyset() 
                                                                  order by SVMXC__Sequence__c DESC]) {
            strWorkOrderFields.add(objEventHoverField.SVMXC__Target_Field_Name__c);
        }
        strWorkOrderFields.add('Id');
        strWorkOrderFields.add('Name');
        strWorkOrderFields.add('SVMXC__Latitude__c');
        strWorkOrderFields.add('SVMXC__Longitude__c');
        
        for(String colorField : uSet.wo_sch_col_fields) {
           strWorkOrderFields.add(colorField); 
        }
        
        for (String fieldName : strWorkOrderFields) {
            if(wofieldMapping.containsKey(fieldName.toLowerCase())) {
                if (fieldNames.length()>0) {
                    fieldNames += ',';
                }
                if(!fieldName.contains('__r.')) {
                    if(wofieldMapping.get(fieldName).getDescribe().getType() == Schema.DisplayType.Reference) {
                        if(fieldName.equalsIgnoreCase('createdById')) {
                            fieldNames += 'CreatedBy.Name,';
                        } else if(fieldName.equalsIgnoreCase('LastModifiedById')) {
                            fieldNames += 'LastModifiedBy.Name,';
                        } else if(fieldName.equalsIgnoreCase('OwnerId')) {
                            fieldNames += 'Owner.Name,';
                        } else if(fieldName == 'SVMXC__Case__c') {
                        fieldName = 'SVMXC__Case__r.casenumber';
                        } else {
                            fieldName = fieldName.substringBefore('__c')+'__r.Name';
                        }  
                    }
                }
                fieldNames += fieldName;
            }
        }
        
        system.debug('fieldNames = '+strWorkOrderFields);
        strQuery = 'SELECT ' + fieldNames + ' FROM SVMXC__Service_Order__c Where Id in :woIds';
        system.debug('strQuery = '+strQuery);
        for(SVMXC__Service_Order__c wo : Database.Query(strQuery)) {
            workOrderMap.put(wo.Id,wo);
        }
        return workOrderMap;
    }

    public static Map<Id,SVMXC__Service_Order__c> retrieveWorkOrdersForIds(List<String> woIds,Map<String,String> settingValues,List<String> woFields) {
        Map<Id,SVMXC__Service_Order__c> workOrderMap = new Map<Id,SVMXC__Service_Order__c>();
        string FieldMapRTypeId;
        string RuleRecordTypeId;
        Map<Id, SVMXC__ServiceMax_Processes__c> mapEventHoverRules  = 
            new Map<Id, SVMXC__ServiceMax_Processes__c>();
        DCX_CommonServiceManager.UserSetting uSet = DCX_SettingServiceManager.fetchUserSettings();
        Set<String> strWorkOrderFields = new Set<String>();
        String strQuery;
        String fieldNames = '';
        String lookUpFieldName = null;
        Map<String,Schema.SObjectField> wofieldMapping = 
            SVMXC__Service_Order__c.sObjectType.getDescribe().fields.getMap();
        strWorkOrderFields = DCX_Utils.wodefaultFields();
        strWorkOrderFields.addAll(DCX_Utils.getFieldUpdates(settingvalues));
        strWorkOrderFields.addAll(DCX_Utils.woUpdateFields());
        for(RecordType recType : [Select SobjectType, Id, Name From RecordType where 
                                  (SobjectType = 'SVMXC__ServiceMax_Processes__c' AND Name = 'SVMX Rule') OR
                                  (SobjectType = 'SVMXC__ServiceMax_Config_Data__c' AND Name IN 
                                  ('Expressions', 'Field Mapping'))]) {
            if(recType.Name == 'SVMX Rule')
                RuleRecordTypeId = recType.id;
            if(recType.Name == 'Field Mapping')
                FieldMapRTypeId = recType.id;
        }
        for(SVMXC__ServiceMax_Processes__c oPro : [Select SVMXC__Sequence__c,SVMXC__Advance_Expression__c, 
                                                   Id From SVMXC__ServiceMax_Processes__c  where 
                                                   RecordTypeId =:RuleRecordTypeId and 
                                                   SVMXC__Rule_Type__c = 'Event Hover Rule']) {
            mapEventHoverRules.put(oPro.Id, oPro);
        }
        for(SVMXC__ServiceMax_Config_Data__c objEventHoverField: [Select Id, SVMXC__Target_Field_Name__c,
                                                                  SVMXC__Sequence__c, 
                                                                  SVMXC__Expression_Rule__c From 
                                                                  SVMXC__ServiceMax_Config_Data__c where
                                                                  RecordTypeId = :FieldMapRTypeId and 
                                                                  SVMXC__Expression_Rule__c 
                                                                  IN :mapEventHoverRules.keyset() 
                                                                  order by SVMXC__Sequence__c DESC]) {
            strWorkOrderFields.add(objEventHoverField.SVMXC__Target_Field_Name__c);
        }
        strWorkOrderFields.add('Id');
        strWorkOrderFields.add('Name');
        strWorkOrderFields.add('SVMXC__Latitude__c');
        strWorkOrderFields.add('SVMXC__Longitude__c');
        
        for(String colorField : uSet.wo_sch_col_fields) {
           strWorkOrderFields.add(colorField); 
        }
        
        for (String fieldName : strWorkOrderFields) {
            if(wofieldMapping.containsKey(fieldName.toLowerCase())){
                if (fieldNames.length()>0) {
                    fieldNames += ',';
                }
                system.debug('Field Name = '+fieldName);
                if(!fieldName.contains('__r.')) {
                    if(wofieldMapping.get(fieldName).getDescribe().getType() == Schema.DisplayType.Reference) {
                        if(fieldName.equalsIgnoreCase('createdById')) {
                            fieldNames += 'CreatedBy.Name,';
                        } else if(fieldName.equalsIgnoreCase('LastModifiedById')) {
                            fieldNames += 'LastModifiedBy.Name,';
                        } else if(fieldName.equalsIgnoreCase('OwnerId')) {
                            fieldNames += 'Owner.Name,';
                        } else if(fieldName == 'SVMXC__Case__c') {
                        fieldName = 'SVMXC__Case__r.casenumber';
                        } else {
                            fieldName = fieldName.substringBefore('__c')+'__r.Name';
                        }  
                    }
                }
                fieldNames += fieldName;
            }
        }
        
        system.debug('fieldNames = '+strWorkOrderFields);
        strQuery = 'SELECT ' + fieldNames + ' FROM SVMXC__Service_Order__c Where Id in :woIds';
        system.debug('strQuery = '+strQuery);
        for(SVMXC__Service_Order__c wo : Database.Query(strQuery)) {
            workOrderMap.put(wo.Id,wo);
        }
        return workOrderMap;
    }

    public static Event populateSFEventDetails(Event oEvent,Map<String, String> mapNewSettings,
                                             Map<String, String> mapEventSettings,
                                             String timeZone,
                                             Map<String,String> EVTFieldDef){
        Event TempSFEvent = new Event();
        if(oEvent.IsAllDayEvent)
        {
            TempSFEvent.StartDateTime = oEvent.ActivityDate;
            TempSFEvent.ActivityDateTime = oEvent.ActivityDate;
            TempSFEvent.ActivityDate = oEvent.ActivityDate;
        }
        else
        {
            TempSFEvent.ActivityDateTime = dcUtils.getDateTimeInTimezone(DateTime.valueof(oEvent.ActivityDateTime).dateGmt(), DateTime.valueof(oEvent.ActivityDateTime).timeGmt() , timeZone);
            TempSFEvent.StartDateTime = TempSFEvent.ActivityDateTime;
            TempSFEvent.ActivityDate = DateTime.valueof(TempSFEvent.ActivityDateTime).date();
        }

        TempSFEvent.OwnerId = oEvent.OwnerId;
        TempSFEvent.DurationInMinutes = Integer.valueof(oEvent.DurationInMinutes);
                        // This is the change due to the introduction of new fields in event objects
        TempSFEvent.SVMXC__Driving_Time__c = Integer.valueof(oEvent.SVMXC__Driving_Time__c);                
        TempSFEvent.SVMXC__Overhead_Time_Before__c = Integer.valueof(oEvent.SVMXC__Overhead_Time_Before__c);                
        TempSFEvent.SVMXC__Overhead_Time_After__c = Integer.valueof(oEvent.SVMXC__Overhead_Time_After__c);              
        TempSFEvent.SVMXC__Driving_Time_Home__c = Integer.valueof(oEvent.SVMXC__Driving_Time_Home__c);              
        TempSFEvent.SVMXC__Service_Duration__c = Integer.valueof(oEvent.SVMXC__Service_Duration__c);                
        TempSFEvent.SVMXC__Break_Time_Total__c = Integer.valueof(oEvent.SVMXC__Break_Time_Total__c); 
        TempSFEvent.IsAllDayEvent = oEvent.IsAllDayEvent;
        TempSFEvent.Subject = oEvent.Subject;
        TempSFEvent.Description = oEvent.Description;
        TempSFEvent.IsAllDayEvent = oEvent.IsAllDayEvent;
        TempSFEvent.WhatId = oEvent.WhatId;
        TempSFEvent.Location = oEvent.Location;
        TempSFEvent.StartDateTime = TempSFEvent.ActivityDateTime;

                        //Defect# 014336 - added 'Type' field
        TempSFEvent.Type = oEvent.Type;

                        // Field updates
        if(mapNewSettings.keySet().size() > 0)
        {

            for(String strfld : mapNewSettings.keySet())
            {
                if(mapEventSettings.containsKey(strfld))
                {
                    if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'DATETIME')
                    {
                        TempSFEvent.put(mapEventSettings.get(strfld),dcUtils.getDateTimeInTimezone(DateTime.valueof(mapNewSettings.get(strfld)).dateGmt(), DateTime.valueof(mapNewSettings.get(strfld)).timeGmt(), timeZone));
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'DATE')
                    {
                        TempSFEvent.put(mapEventSettings.get(strfld),Date.valueOf(mapNewSettings.get(strfld)));
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'BOOLEAN')
                    {
                        TempSFEvent.put(mapEventSettings.get(strfld),Boolean.valueOf(mapNewSettings.get(strfld)));
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'CURRENCY')
                    {
                        if(mapNewSettings.get(strfld)!='')
                            TempSFEvent.put(mapEventSettings.get(strfld),Double.valueOf(mapNewSettings.get(strfld)));
                        else
                            TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'INTEGER')
                    {
                        if(mapNewSettings.get(strfld)!='')
                            TempSFEvent.put(mapEventSettings.get(strfld),Integer.valueOf(mapNewSettings.get(strfld)));
                        else
                                TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'PERCENT')
                    {
                        if(mapNewSettings.get(strfld)!='')
                            TempSFEvent.put(mapEventSettings.get(strfld),Decimal.valueOf(mapNewSettings.get(strfld)));
                        else
                            TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'DOUBLE')
                    {
                        if(mapNewSettings.get(strfld)!='')
                            TempSFEvent.put(mapEventSettings.get(strfld),Double.valueOf(mapNewSettings.get(strfld)));
                        else
                            TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                    else if(EVTFieldDef.get(mapEventSettings.get(strfld)) == 'TIME')
                    {
                        //23:12
                        
                         
                        if(mapNewSettings.get(strfld)!=''){
                            List<String> lt = mapNewSettings.get(strfld).split(':');
                            Time tt = Time.newInstance( Integer.valueof(lt[0]), Integer.valueof(lt[1]),0,0);
                            TempSFEvent.put(mapEventSettings.get(strfld),tt);
                        }
                            
                        else
                            TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                    else
                    {
                        if(mapNewSettings.get(strfld)!='')
                            TempSFEvent.put(mapEventSettings.get(strfld),string.valueOf(mapNewSettings.get(strfld)));
                        else
                            TempSFEvent.put(mapEventSettings.get(strfld),null);
                    }
                }
            }
        }
        return TempSFEvent;
    }    

    public static SVMXC__SVMX_Event__c populateSVMXEventDetails(Event oEvent,
                                                                Map<String, String> mapNewSettings,
                                                                Map<String, String> mapEventSettings,
                                                                String timeZone,
                                                                Map<String,String> SVMXEVTFieldDef) {
        SVMXC__SVMX_Event__c TempSVMXEvent = new SVMXC__SVMX_Event__c();
        if(oEvent.IsAllDayEvent)
        {
            TempSVMXEvent.SVMXC__ActivityDate__c = oEvent.ActivityDate;
            TempSVMXEvent.SVMXC__StartDateTime__c = oEvent.ActivityDate;
            TempSVMXEvent.SVMXC__ActivityDateTime__c = oEvent.ActivityDate;
            TempSVMXEvent.SVMXC__EndDateTime__c = (Datetime) oEvent.EndDateTime.dateGmt();

        }
        else
        {
            TempSVMXEvent.SVMXC__ActivityDateTime__c = dcUtils.getDateTimeInTimezone(DateTime.valueof(oEvent.ActivityDateTime).dateGmt(), DateTime.valueof(oEvent.ActivityDateTime).timeGmt() , timeZone);
            TempSVMXEvent.SVMXC__StartDateTime__c = TempSVMXEvent.SVMXC__ActivityDateTime__c;
            TempSVMXEvent.SVMXC__ActivityDate__c = TempSVMXEvent.SVMXC__ActivityDateTime__c.date();
            DateTime endDate_T = DateTime.valueof(oEvent.ActivityDateTime).addMinutes(Integer.valueof(oEvent.DurationInMinutes));
            TempSVMXEvent.SVMXC__EndDateTime__c = dcUtils.getDateTimeInTimezone(endDate_T.dateGmt(), endDate_T.timeGmt() , timeZone);
        }
            TempSVMXEvent.SVMXC__Technician__c = oEvent.OwnerId;
            TempSVMXEvent.SVMXC__DurationInMinutes__c = Integer.valueof(oEvent.DurationInMinutes);
                            // This is the change due to the introduction of new fields in event objects
            TempSVMXEvent.SVMXC__Driving_Time__c = Integer.valueof(oEvent.SVMXC__Driving_Time__c);              
            TempSVMXEvent.SVMXC__Overhead_Time_Before__c = Integer.valueof(oEvent.SVMXC__Overhead_Time_Before__c);              
            TempSVMXEvent.SVMXC__Overhead_Time_After__c = Integer.valueof(oEvent.SVMXC__Overhead_Time_After__c);                
            TempSVMXEvent.SVMXC__Driving_Time_Home__c = Integer.valueof(oEvent.SVMXC__Driving_Time_Home__c);                
            TempSVMXEvent.SVMXC__Service_Duration__c = Integer.valueof(oEvent.SVMXC__Service_Duration__c);              
            TempSVMXEvent.SVMXC__Break_Time_Total__c = Integer.valueof(oEvent.SVMXC__Break_Time_Total__c); 
            TempSVMXEvent.SVMXC__IsAllDayEvent__c = oEvent.IsAllDayEvent; 
            TempSVMXEvent.Name = oEvent.Subject;
            TempSVMXEvent.SVMXC__Description__c = oEvent.Description;
            TempSVMXEvent.SVMXC__WhatId__c = oEvent.WhatId;
            TempSVMXEvent.SVMXC__Location__c = oEvent.Location;
            TempSVMXEvent.SVMXC__Type__c = oEvent.Type;
            TempSVMXEvent.SVMXC__StartDateTime__c = TempSVMXEvent.SVMXC__ActivityDateTime__c;

                            // Field updates
            if(mapNewSettings.keySet().size() > 0)
            {
                for(String strfld : mapNewSettings.keySet())
                {
                    if(mapEventSettings.containsKey(strfld))
                    {
                        if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'DATETIME')
                        {
                            TempSVMXEvent.put(mapEventSettings.get(strfld),dcUtils.getDateTimeInTimezone(DateTime.valueof(mapNewSettings.get(strfld)).dateGmt(), DateTime.valueof(mapNewSettings.get(strfld)).timeGmt(), timeZone));

                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'DATE')
                        {
                            TempSVMXEvent.put(mapEventSettings.get(strfld),Date.valueOf(mapNewSettings.get(strfld)));
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'BOOLEAN')
                        {
                            TempSVMXEvent.put(mapEventSettings.get(strfld),Boolean.valueOf(mapNewSettings.get(strfld)));
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'CURRENCY')
                        {
                            if(mapNewSettings.get(strfld)!='')
                                TempSVMXEvent.put(mapEventSettings.get(strfld),Double.valueOf(mapNewSettings.get(strfld)));
                            else
                                TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'INTEGER')
                        {
                            if(mapNewSettings.get(strfld)!='')
                                TempSVMXEvent.put(mapEventSettings.get(strfld),Integer.valueOf(mapNewSettings.get(strfld)));
                            else
                                TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'PERCENT')
                        {
                            if(mapNewSettings.get(strfld)!='')
                                TempSVMXEvent.put(mapEventSettings.get(strfld),Decimal.valueOf(mapNewSettings.get(strfld)));
                            else
                                TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'DOUBLE')
                        {
                            if(mapNewSettings.get(strfld)!='')
                                TempSVMXEvent.put(mapEventSettings.get(strfld),Double.valueOf(mapNewSettings.get(strfld)));
                            else
                                TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                        else if(SVMXEVTFieldDef.get(mapEventSettings.get(strfld)) == 'TIME')
                        {
                            //23:12
                            
                            
                            if(mapNewSettings.get(strfld)!=''){
                                system.debug('mapNewSettings.get(strfld) '+mapNewSettings.get(strfld));
                                List<String> lt = mapNewSettings.get(strfld).split(':');
                                Time tt = Time.newInstance( Integer.valueof(lt[0]), Integer.valueof(lt[1]),0,0);
                                TempSVMXEvent.put(mapEventSettings.get(strfld),tt);
                            }
                                
                            else
                            TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                        else
                        {
                            if(mapNewSettings.get(strfld)!='')
                                TempSVMXEvent.put(mapEventSettings.get(strfld),string.valueOf(mapNewSettings.get(strfld)));
                            else
                                TempSVMXEvent.put(mapEventSettings.get(strfld),null);
                        }
                    }
                }
            }
        return TempSVMXEvent;                  
    }

    public static DCX_CommonServiceManager.Events_WP populateSFEventInfoDetails(Event evt,SVMXC__Service_Group_Members__c tech,
                                                                                Map<String,String> mapEventSettings,
                                                                                Map<String,String> EVTFieldDef) {
        DCX_CommonServiceManager.DCEvent_WP eventInfo = new DCX_CommonServiceManager.DCEvent_WP();
        DCX_CommonServiceManager.Events_WP event_WPObj = new DCX_CommonServiceManager.Events_WP();
        eventInfo.id = evt.Id;
        eventInfo.subject = evt.Subject;
        eventInfo.durationInMinutes = String.Valueof(evt.DurationInMinutes);
        eventInfo.description = evt.Description;
        eventInfo.whatId = evt.WhatId;
        eventInfo.whoId = evt.WhoId;
        eventInfo.activityDate = String.Valueof(evt.ActivityDate);
        eventInfo.activityDateTime = String.Valueof(evt.ActivityDateTime);
        if(evt.IsAllDayEvent)
        {
            eventInfo.startDateTime = evt.StartDateTime.formatGMT('MM/dd/yyyy hh:mm a');
            if(evt.DurationInMinutes != NULL){
                eventInfo.endDateTime = evt.StartDateTime.addMinutes(Integer.valueof(evt.DurationInMinutes)).formatGMT('MM/dd/yyyy hh:mm a');
            }
            
        }
        else {
            if(evt.StartDateTime != NULL){
                eventInfo.startDateTime = evt.StartDateTime.format('MM/dd/yyyy hh:mm a');
                if(evt.DurationInMinutes != NULL)
                {
                    eventInfo.endDateTime = evt.StartDateTime.addMinutes(Integer.valueof(evt.DurationInMinutes)).format('MM/dd/yyyy hh:mm a');
                }
            }
        }
        eventInfo.location = evt.Location;
        eventInfo.ownerId = evt.OwnerId;
        if( tech!= null) {
        eventInfo.TechId = tech.Id;
        eventInfo.techName = tech.Name;
        }
        if(evt.WhatId!= null)
            eventInfo.isWorkOrder = true;
        eventInfo.Driving_Time = String.Valueof(evt.SVMXC__Driving_Time__c);
        eventInfo.Overhead_Time_Before = String.Valueof(evt.SVMXC__Overhead_Time_Before__c);
        eventInfo.Overhead_Time_After = String.Valueof(evt.SVMXC__Overhead_Time_After__c);
        eventInfo.Driving_Time_Home = String.Valueof(evt.SVMXC__Driving_Time_Home__c);
        eventInfo.Service_Duration = String.Valueof(evt.SVMXC__Service_Duration__c);
        eventInfo.Break_Time_Total = String.Valueof(evt.SVMXC__Break_Time_Total__c);
        eventInfo.Type = evt.Type;
        eventInfo.IsAllDayEvent = evt.IsAllDayEvent;
        eventInfo.Type = evt.Type;
        eventInfo.latitude = String.Valueof(evt.SVMXC__SM_Latitude__c);
        eventInfo.longitude = String.Valueof(evt.SVMXC__SM_Longitude__c);
        if(mapEventSettings.keySet().size() > 0) {
            List<DCX_CommonServiceManager.KeyValuePair_WP> lstEvtKeyVal = new List<DCX_CommonServiceManager.KeyValuePair_WP>();
            for(String strCurrentSetting : mapEventSettings.keySet()){
                if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null 
                    && EVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                    EVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATETIME') {                                               
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null ) {               
                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(evt.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a')));
                    }
                }
                else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && 
                        EVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                        EVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATE')
                {
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null )         
                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, Date.valueof(evt.get(mapEventSettings.get(strCurrentSetting))).format()));
                }
                else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && 
                EVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                EVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'TIME')
                {
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null )  
                    {
                        List<String> lt = String.valueOf(evt.get(mapEventSettings.get(strCurrentSetting))).split(':');
                        String st = String.valueOf(lt[0])+':'+String.valueOf(lt[1]);

                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, st));

                    }       
                }
                else 
                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, String.valueOf(evt.get(mapEventSettings.get(strCurrentSetting)))));                                   
            }
            eventInfo.lstKeyValuePair = lstEvtKeyVal;
        }
        event_WPObj.event_WP = eventInfo;
        return event_WPObj;
    } 

    public static DCX_CommonServiceManager.Events_WP populateSVMXEventInfoDetails(SVMXC__SVMX_Event__c evt,
                                                                                  Map<String,String> mapEventSettings,
                                                                                  Map<String,String> SVMXEVTFieldDef) {
        DCX_CommonServiceManager.DCEvent_WP eventInfo = new DCX_CommonServiceManager.DCEvent_WP();
        DCX_CommonServiceManager.Events_WP event_WPObj = new DCX_CommonServiceManager.Events_WP();
        eventInfo.id = evt.Id;
        eventInfo.subject = CheckNull(evt.Name);
        eventInfo.durationInMinutes = CheckNull(String.valueof(evt.SVMXC__DurationInMinutes__c));
        eventInfo.description = CheckNull(evt.SVMXC__Description__c);
        eventInfo.whatId = evt.SVMXC__WhatId__c;
        eventInfo.whoId = evt.SVMXC__WhoId__c;
        eventInfo.activityDate = String.Valueof(evt.SVMXC__ActivityDate__c);
        eventInfo.activityDateTime = String.Valueof(evt.SVMXC__ActivityDateTime__c);
        //eventInfo.startDateTime = String.Valueof(evt.SVMXC__StartDateTime__c);
        if(evt.SVMXC__IsAllDayEvent__c) {
            eventInfo.startDateTime = evt.SVMXC__StartDateTime__c.formatGMT('MM/dd/yyyy hh:mm a');
            if(evt.SVMXC__DurationInMinutes__c != null)
                eventInfo.endDateTime = 
                    evt.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(evt.SVMXC__DurationInMinutes__c)).formatGMT('MM/dd/yyyy hh:mm a');
        }
        else {
            eventInfo.startDateTime = evt.SVMXC__StartDateTime__c.format('MM/dd/yyyy hh:mm a');
            if(evt.SVMXC__DurationInMinutes__c != null){
                eventInfo.endDateTime = evt.SVMXC__StartDateTime__c.addMinutes(Integer.valueof(evt.SVMXC__DurationInMinutes__c)).format('MM/dd/yyyy hh:mm a');
            }
        }
        //eventInfo.endDateTime = String.Valueof(evt.SVMXC__EndDateTime__c);
        eventInfo.location = evt.SVMXC__Location__c;
        eventInfo.ownerId = evt.SVMXC__Technician__c;
        eventInfo.TechId = evt.SVMXC__Technician__c;
        if(evt.SVMXC__WhatId__c!= null)
            eventInfo.isWorkOrder = true;
        eventInfo.Driving_Time = String.Valueof(evt.SVMXC__Driving_Time__c);
        eventInfo.Overhead_Time_Before = String.Valueof(evt.SVMXC__Overhead_Time_Before__c);
        eventInfo.Overhead_Time_After = String.Valueof(evt.SVMXC__Overhead_Time_After__c);
        eventInfo.Driving_Time_Home = String.Valueof(evt.SVMXC__Driving_Time_Home__c);
        eventInfo.Service_Duration = String.Valueof(evt.SVMXC__Service_Duration__c);
        eventInfo.Break_Time_Total = String.Valueof(evt.SVMXC__Break_Time_Total__c);
        eventInfo.Type = evt.SVMXC__Type__c;
        eventInfo.IsAllDayEvent = evt.SVMXC__IsAllDayEvent__c;
        eventInfo.latitude = String.Valueof(evt.SVMXC__SM_Latitude__c);
        eventInfo.longitude = String.Valueof(evt.SVMXC__SM_Longitude__c);
        eventInfo.techName = evt.SVMXC__Technician__r.Name;
        if(mapEventSettings.keySet().size() > 0) {
            List<DCX_CommonServiceManager.KeyValuePair_WP> lstEvtKeyVal = new List<DCX_CommonServiceManager.KeyValuePair_WP>();
            for(String strCurrentSetting : mapEventSettings.keySet()){
                if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null 
                    && SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                    SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATETIME') {                                               
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null ) {               
                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield',strCurrentSetting, ((Datetime)(evt.get(mapEventSettings.get(strCurrentSetting)))).format('MM/dd/yyyy hh:mm a')));
                    }
                }
                else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && 
                        SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                        SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'DATE')
                {
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null )         
                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, Date.valueof(evt.get(mapEventSettings.get(strCurrentSetting))).format()));
                }
                else if(mapEventSettings.containskey(strCurrentSetting) && mapEventSettings.get(strCurrentSetting) != null && 
                        SVMXEVTFieldDef.containskey(mapEventSettings.get(strCurrentSetting)) && 
                        SVMXEVTFieldDef.get(mapEventSettings.get(strCurrentSetting)) == 'TIME')
                {
                    if(evt.get(mapEventSettings.get(strCurrentSetting)) != null )  
                    {
                        List<String> lt = String.valueOf(evt.get(mapEventSettings.get(strCurrentSetting))).split(':');
                        String st = String.valueOf(lt[0])+':'+String.valueOf(lt[1]);

                        lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, st));

                    }       
                }
                else 
                    lstEvtKeyVal.add(new DCX_CommonServiceManager.KeyValuePair_WP('Settingfield', strCurrentSetting, String.valueOf(evt.get(mapEventSettings.get(strCurrentSetting)))));                                   
            }
            eventInfo.lstKeyValuePair = lstEvtKeyVal;
        }
        event_WPObj.event_WP = eventInfo;
        return event_WPObj;
    }
    public class DCEventWarningReq_WP
    {
        public String WorkOrderId {get; set;}
        public String TechId {get; set;}
        public Datetime EventStartDateTime {get; set;}
        public Datetime EventEndDateTime {get; set;}
        public String timeZone {get; set;}
        public boolean isMachineAccessHrsEnabled {get; set;}
        public boolean isBusinessHrsEnabled {get; set;}
        public boolean isBasicWH {get; set;}

        
        public DCEventWarningReq_WP(String WoId, 
                                    String TechnicianId, 
                                    Datetime eventStDt, 
                                    Datetime eventEdDt, 
                                    String timZone,
                                    boolean isMacAccessHrs,
                                    boolean isBussHrs,
                                    boolean isBasicWH)
        {
            this.WorkOrderId = WoId;
            this.TechId = TechnicianId;
            this.EventStartDateTime = eventStDt;
            this.EventEndDateTime = eventEdDt;
            this.timeZone = timZone;
            this.isMachineAccessHrsEnabled = isMacAccessHrs;
            this.isBusinessHrsEnabled = isBussHrs;
             this.isBasicWH = isBasicWH;
        }
        public DCEventWarningReq_WP() {}
    }
     

     public class DCEventWarningResponce
    {
        public Boolean EventExistinBusinessHour =false;
        public  DCON_Configuration_WS.DCEventWarningResp_WP advancedBusinessHours;
     }
    public static DCEventWarningResponce DCX_EventWarnings_WS(DCEventWarningReq_WP req) {
        DateTime startDate = DateTime.valueof(req.EventStartDateTime);
        // In Old DC, client sending date with +05:30 always, new New DC clent always sed in GMT so adding +5:30
        startDate = startDate.addHours(5);
        startDate = startDate.addMinutes(30);

         DateTime startDate1 = 
                    dcUtils.getDateTimeInTimezone(startDate.dateGmt(),startDate.timeGmt(),req.timeZone);
        DCEventWarningResponce responce = new DCEventWarningResponce();
        if(req.isBasicWH ){

            responce.EventExistinBusinessHour =DCON_Configuration_WS.EventExistinBusinessHour(req.TechId,
                                                                                                                                                                    startDate1,
                                                                                                                                                                    req.timeZone);
        }
        else {
            DateTime endDate = DateTime.valueof(req.EventEndDateTime);
            endDate = startDate.addHours(5);
            endDate = startDate.addMinutes(30);

            DateTime endDate1 = 
                    dcUtils.getDateTimeInTimezone(DateTime.valueof(endDate).dateGmt(),DateTime.valueof(endDate).timeGmt(),req.timeZone); 
            
            DCON_Configuration_WS.DCEventWarningReq_WP req1 = new DCON_Configuration_WS.DCEventWarningReq_WP();
            req1.WorkOrderId = req.WorkOrderId;
            req1.TechId = req.TechId ;
            req1.EventStartDateTime = startDate1;
            req1.EventEndDateTime = endDate1;
            req1.timeZone =  req.timeZone;
            req1.isMachineAccessHrsEnabled =  req.isMachineAccessHrsEnabled;
            req1.isBusinessHrsEnabled =  req.isBusinessHrsEnabled;
            responce.advancedBusinessHours = DCON_Configuration_WS.DCON_EventWarnings_WS(req1);
        }
        return responce;
    }
    
    public class DCTech_WO_Response_WP 
    {
        public String StatusMessage;
        public Map<String,String> settingvalues;
        public DCTech_WO_Response_WP(String resp)
        {
            this.StatusMessage = resp;
        }
        public DCTech_WO_Response_WP() {}           
    }
    
    public without sharing class DCX_EventServiceManager_Util {
        //public DCX_EventServiceManager_Util(){}
        public void deleteEventsUtil(List<String> eIds) {
            List<Event> SalesforceEventList = [SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id 
                                           IN :eIds];
            List<SVMXC__SVMX_Event__c> ServiceMaxEventList = [SELECT Id, SVMXC__ActivityDateTime__c, 
                                                              SVMXC__WhatId__c, SVMXC__Technician__c 
                                                              from SVMXC__SVMX_Event__c where Id IN :eIds];
            if(SalesforceEventList.size() > 0) {
                if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') )
                    delete SalesforceEventList;
            }
            if(ServiceMaxEventList.size() > 0)
                COMM_SecurityUtils.getinstance().deleteAsUser(ServiceMaxEventList);    
        }
        
        public void upsertSFEventsUtil(List<Event> sfLstEvents) {
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(sfLstEvents,COMM_SecurityUtils.Access.Upsertable)){
                upsert sfLstEvents;
            } 
        }
        
        public void insertSFEventsUtil(List<Event> sfLstEvents) {
            if(COMM_SecurityUtils.getInstance().verifyFieldAccess(sfLstEvents,COMM_SecurityUtils.Access.Createable)){
                insert sfLstEvents;
            } 
        }
        
        public void deleteSFEventsUtil(List<Event> sfLstEvents) {
            if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') )
                delete sfLstEvents;
        }
        
        public List<String> deleteEventForWOUtil(String workOrderId,String eventId,String techId,String techSFId,Map<String,String> settingvalues) {
            List<String> deletedEventIds = new List<String>();
            List<Event> events = new List<Event>();
            List<Event> finalEvents = new List<Event>();
            List<SVMXC__SVMX_Event__c> SVMXevents = new List<SVMXC__SVMX_Event__c>();
            List<SVMXC__SVMX_Event__c> finalSVMXevents = new List<SVMXC__SVMX_Event__c>();
            if(settingvalues.Containskey('DCON001_SET024') && settingvalues.get('DCON001_SET024')=='True') {
                events = [SELECT Id from event where WhatId = :workOrderId and OwnerId != :techSFId 
                          and Id != :eventId];
                SVMXevents = [SELECT Id from SVMXC__SVMX_Event__c where SVMXC__WhatId__c = :workOrderId and
                              SVMXC__Technician__c != :techId and Id != :eventId];
     
                
            } else {
                events = [SELECT Id from event where WhatId = :workOrderId and StartDateTime > :System.now()
                          and OwnerId != :techSFId and Id != :eventId];
                SVMXevents = [SELECT Id from SVMXC__SVMX_Event__c where SVMXC__WhatId__c = :workOrderId 
                              and SVMXC__StartDateTime__c > :System.now() and Id != :eventId and
                              SVMXC__Technician__c != :techId];
    
            }
    
            if(events.size() > 0) {
                for (Event ev : events)
                    deletedEventIds.add(ev.Id);
                if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') )
                    delete events;
            }
            if(SVMXevents.size() > 0) {
                for (SVMXC__SVMX_Event__c svmxEv : SVMXevents)
                    deletedEventIds.add(svmxEv.Id);
                COMM_SecurityUtils.getinstance().deleteAsUser(SVMXevents);
            }
    
            return deletedEventIds;
        }

        public List<Event> retrieveSFEventsUtil(String sfQuery,List<Event> lstSFEvents) {
            return Database.Query(sfQuery);
        }
        
        public List<Event> retrieveSFEventsForIdsUtil(String sfQuery,List<String> SFEvents) {
            return Database.Query(sfQuery);
        }
        
        public List<Event> retrieveSFEventsWithParamsUtil(String sfQuery,DateTime dtmStartDateTime, DateTime dtmEndDateTime, Date DEndDate, Datetime DStartDatetime, Date DStartDate, List<String> SFUSerIds) {
            return Database.Query(sfQuery);
        }
        
        public DCTech_WO_Response_WP deleteAESEvents(DCX_Wrapper.deleteJDMEvent request) {
           DCTech_WO_Response_WP resp = new DCTech_WO_Response_WP();
           DCX_EventServiceManager_Util eventsUtil = new DCX_EventServiceManager_Util();
           List<Event> SFEvents = new List<Event>();
           DateTime dtmStartDateTime;
           List<SVMXC__SVMX_Event__c> SVMXEvents = new List<SVMXC__SVMX_Event__c>();
           Map<String,String> svmxSettingList = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET001','SET073',null);
           try {
               if(request.WorkOrderId == '' || request.TechId == '') {
                throw new DCX_CommonServiceManager.DCxException('Please provide workorderId and/or techId to unassign');
               }
               
               if(request.timeZone == NULL || request.timeZone == '') {
                    request.timeZone = Userinfo.getTimeZone().getID();
               }
               System.debug('request.EventStartDtTm:' + request.EventStartDtTm);
               if(request.EventStartDtTm == null && !request.isDeleteAllEvents && !String.isBlank(request.deleteSingleEventId)) {
                    List<String> evtIds = new List<String>();
                    evtIds.add(request.deleteSingleEventId);
                    eventsUtil.deleteEventsUtil(evtIds); 
                    resp.StatusMessage += request.deleteSingleEventId;  
                    SVMXC__Service_Order__c schWO = [Select Id, SVMXC__Last_Dispatch_Event__c,SVMXC__FirstScheduledDateTime__c, 
                                                     SVMXC__NoOfTimesScheduled__c, SVMXC__Scheduled_Date_Time__c, SVMXC__Group_Member__c, 
                                                     SVMXC__Group_Member__r.SVMXC__Salesforce_User__c from SVMXC__Service_Order__c where 
                                                     Id = :request.WorkOrderId]; 
                    schWO.SVMXC__Scheduled_Date_Time__c = null;
                    schWO.SVMXC__Last_Dispatch_Event__c = 'UnScheduled';
               }
               else if(request.EventStartDtTm != null)
                {
                    dtmStartDateTime = DCX_Utils.doTZConversion(request.EventStartDtTm, request.timeZone, 'GMT');
                    
                    if(request.isEarlierEvents)
                    {
                        //Check if deleting past events are allowed
                        if(svmxSettingList.Containskey('DCON001_SET024') && svmxSettingList.get('DCON001_SET024') == 'true')
                        {
                            SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM event 
                                        WHERE WhatId =:request.WorkOrderId
                                        AND OwnerId =:request.OwnerId
                                        AND StartDateTime <= :dtmStartDateTime];
                                            
                            SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM SVMXC__SVMX_Event__c 
                                        WHERE (SVMXC__WhatId__c =:request.WorkOrderId 
                                        OR SVMXC__Service_Order__c =:request.WorkOrderId)
                                        AND SVMXC__Technician__c =:request.TechId
                                        AND SVMXC__StartDateTime__c <= :dtmStartDateTime];
                        }
                        //Check if only the selected events and the events earlier than the selected events are to be deleted
                        else
                        {
                            SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM event 
                                        WHERE (WhatId =:request.WorkOrderId
                                        AND OwnerId =:request.OwnerId
                                        AND StartDateTime <= :dtmStartDateTime
                                        AND StartDateTime >= :System.now()) OR Id = :request.eventId];
                                            
                            SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM SVMXC__SVMX_Event__c 
                                        WHERE ((SVMXC__WhatId__c =:request.WorkOrderId 
                                        OR SVMXC__Service_Order__c =:request.WorkOrderId)
                                        AND SVMXC__Technician__c =:request.TechId
                                        AND SVMXC__StartDateTime__c <= :dtmStartDateTime
                                        AND SVMXC__StartDateTime__c >= :System.now()) OR Id = :request.eventId];
                        }
                    }
                    //for deleting later events
                    else
                    {
                        if(svmxSettingList.Containskey('DCON001_SET024') && svmxSettingList.get('DCON001_SET024') == 'true')
                        {
                            SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM event 
                                        WHERE WhatId =:request.WorkOrderId
                                        AND OwnerId =:request.OwnerId
                                        AND StartDateTime >= :dtmStartDateTime];
                                            
                            SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM SVMXC__SVMX_Event__c 
                                        WHERE (SVMXC__WhatId__c =:request.WorkOrderId 
                                        OR SVMXC__Service_Order__c =:request.WorkOrderId)
                                        AND SVMXC__Technician__c =:request.TechId
                                        AND SVMXC__StartDateTime__c >= :dtmStartDateTime];
                        }
                        //Check if only the selected events and the events earlier than the selected events are to be deleted
                        else
                        {
                            SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM event 
                                        WHERE (WhatId =:request.WorkOrderId
                                        AND OwnerId =:request.OwnerId
                                        AND StartDateTime >= :dtmStartDateTime
                                        AND StartDateTime >= :System.now()) OR Id = :request.eventId];
                                            
                            SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                        FROM SVMXC__SVMX_Event__c 
                                        WHERE ((SVMXC__WhatId__c =:request.WorkOrderId 
                                        OR SVMXC__Service_Order__c =:request.WorkOrderId)
                                        AND SVMXC__Technician__c =:request.TechId
                                        AND SVMXC__StartDateTime__c >= :dtmStartDateTime
                                        AND SVMXC__StartDateTime__c >= :System.now()) OR Id = :request.eventId];
                        }
                    }
                }
                else if(request.EventStartDtTm == null && request.isDeleteAllEvents)
                {
                    //This is the setting to delete PAST Events if SET024 is true
                    if(svmxSettingList.Containskey('DCON001_SET024') && svmxSettingList.get('DCON001_SET024') == 'true')
                    {
                        SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM event 
                                    WHERE WhatId =:request.WorkOrderId];
                                    
                        SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM SVMXC__SVMX_Event__c 
                                    WHERE (SVMXC__WhatId__c =:request.WorkOrderId 
                                    OR SVMXC__Service_Order__c =:request.WorkOrderId)];
                    }
                    //Check if the past event deletion is not allowed then delete events from the current datetime
                    //if SET024 = false, then past events deletion is not allowed
                    else
                    {
                        SFEvents = [SELECT Id, SVMXC__Service_Duration__c 
                                    FROM event 
                                    WHERE (WhatId =: request.WorkOrderId 
                                    AND StartDateTime >= :System.now()) OR Id = :request.eventId];
                                    
                        SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM SVMXC__SVMX_Event__c 
                                    WHERE ((SVMXC__Service_Order__c =: request.WorkOrderId
                                    OR SVMXC__WhatId__c =:request.WorkOrderId)
                                    AND SVMXC__StartDateTime__c >= :System.now()) OR Id = :request.eventId];
                    }
                }
                else if(request.EventStartDtTm == null && !request.isDeleteAllEvents)
                {
                    //This is the setting to delete PAST Events if SET024 is true
                    if(svmxSettingList.Containskey('DCON001_SET024') && svmxSettingList.get('DCON001_SET024') == 'true')
                    {
                        SFEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM event 
                                    WHERE WhatId =:request.WorkOrderId
                                    AND OwnerId =:request.OwnerId];
                                    
                        SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM SVMXC__SVMX_Event__c 
                                    WHERE (SVMXC__WhatId__c =:request.WorkOrderId 
                                    OR SVMXC__Service_Order__c =:request.WorkOrderId)
                                    AND SVMXC__Technician__c =:request.TechId];
                    }
                    //Check if the past event deletion is not allowed then delete events from the current datetime
                    //if SET024 = false, then past events deletion is not allowed
                    else
                    {
                        SFEvents = [SELECT Id, SVMXC__Service_Duration__c 
                                    FROM event 
                                    WHERE (WhatId =: request.WorkOrderId 
                                    AND OwnerId =: request.OwnerId
                                    AND StartDateTime >= :System.now()) OR Id = :request.eventId];
                                    
                        SVMXEvents = [SELECT Id, SVMXC__Service_Duration__c
                                    FROM SVMXC__SVMX_Event__c 
                                    WHERE ((SVMXC__Service_Order__c =: request.WorkOrderId
                                    OR SVMXC__WhatId__c =:request.WorkOrderId)
                                    AND SVMXC__Technician__c =: request.TechId
                                    AND SVMXC__StartDateTime__c >= :System.now()) OR Id = :request.eventId];
                    }
                }
               
                for(event objEvent: SFEvents)
                {
                    if(resp.StatusMessage != '')
                        resp.StatusMessage += ',';
                    resp.StatusMessage += objEvent.Id;
                }
                
                for(SVMXC__SVMX_Event__c objEvent: SVMXEvents)
                {
                    if(resp.StatusMessage != '')
                        resp.StatusMessage += ',';
                    resp.StatusMessage += objEvent.Id;
                }
                        
                if(SFEvents.size() > 0 && COMM_SecurityUtils.getInstance().isDeletableObject('Event'))
                { 
                    delete SFEvents; 
                }
            
                if(SVMXEvents.size() > 0 && COMM_SecurityUtils.getInstance().isDeletableObject('SVMXC__SVMX_Event__c'))
                { 
                    delete SVMXEvents; 
                }
               resp.settingvalues = svmxSettingList;
               
           }
           catch(Exception ex) {
            throw new DCX_CommonServiceManager.DCxException(ex.getMessage());
           }
           return resp;
           
        }
    }
}