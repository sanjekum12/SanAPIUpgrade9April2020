@RestResource(urlMapping='/scheduling/eco/technician/*')
global with sharing class WSCH_ECO_Client_TechnicianServices {
    public static final String RETURN_MESSAGE_FOR_TECH_UPDATE = 'Technician Horizon Updated';
    public static final String RETURN_MESSAGE_FOR_WO_UPDATE = 'WOs falling within the Horizon are sent';
    public static final String RETURN_MESSAGE_FOR_NON_WO_EVENT_UPDATE = 'Non WO Events falling within the Horizon are sent';
    public static final String NO_OP_ERROR_MESSAGE = 'Empty or Invalid operation type';
    
    @HttpPost
    global static String doPost() {
        String returnMsg = NO_OP_ERROR_MESSAGE;
        RestRequest request = RestContext.request;
        Blob data = request.requestBody;
        String changeReq = data.toString();
        try {
            WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::doPost::Json Request: ' + changeReq);
            WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP req = (WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP)JSON.deserialize(changeReq, WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP.class);
            if('HORIZON_UPDATE'.equals(req.operation)) {
                returnMsg = updateTechHorizon(req);
            } else if('WO_UPDATE'.equals(req.operation)){
                returnMsg = WSCH_ECO_Client_TechnicianServices.scheduleWOsFallingInHorizon(req);
            } else if('NON_WO_EVENT_UPDATE'.equals(req.operation)) {
                returnMsg = WSCH_ECO_Client_TechnicianServices.scheduleEventsFallingInHorizon(req);
            }
        } catch(Exception ex){
            WSCH_AuditLogger.error('WSCH_ECO_Client_TechnicianServices::doPost():Exception occured..'+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());         
        } finally{
            WSCH_AuditLogger.finish();
        }
        return returnMsg;
    }
    
    private static String updateTechHorizon(WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP req) {
        String dispatchProcessGuid = req.dispatchProcessGuid;
        String territoryGuid = req.territoryGuid;
        String connectionId = dispatchProcessGuid + '_' + territoryGuid;
        
        //Fetch the Optimizer Object from the technician id 
        //list<SVMXC__SVMX_Optimizer__c> technicianOptimizers = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__Optimizer_External_ID__c,SVMXC__WhatId__c,SVMXC__Optimizer_Connection_ID__c,SVMXC__WhatType__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in : connectionIds];
        list<SVMXC__SVMX_Optimizer__c> technicianOptimizers = [Select id, SVMXC__Optimizer_Change_Token__c,SVMXC__WhatId__c,SVMXC__Optimizer_Connection_ID__c,SVMXC__WhatType__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__Optimizer_Connection_ID__c =: connectionId AND SVMXC__WhatType__c ='TECHNICIAN' AND SVMXC__Optimizer_Change_Token__c != 'CHANGE_REMOVE_TECH'];
        WSCH_AuditLogger.debug('technicianOptimizers ' + technicianOptimizers);
        for(SVMXC__SVMX_Optimizer__c optimizerObj : technicianOptimizers){
            optimizerObj.SVMXC__Optimizer_Change_Token__c = 'CHANGE_UPDATE_TECH';
        }
        //invoking manage technicians callout
        WSCH_OptimizedSchedulingService.manageTechnicians(technicianOptimizers);
        //WSCH_ECO_Client_TechnicianServices.scheduleWOsFallingInHorizon(req);
        //WSCH_ECO_Client_TechnicianServices.scheduleEventsFallingInHorizon(req);
        return RETURN_MESSAGE_FOR_TECH_UPDATE;
    }
    
    //Below method schedules all the Unscheduled WOs that were skipped earlier due to not falling within the DP horizon as they were at a later date.
    public static String scheduleWOsFallingInHorizon(WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP req) {
        String dispatchProcessGuid = req.dispatchProcessGuid;
        String territoryGuid = req.territoryGuid;
        
        List<SVMXC__ServiceMax_Processes__c> lstOfDPProcessObj = [SELECT Id, SVMXC__Calendar_Start_Days__c, SVMXC__Calendar_End_Days__c, SVMXC__Dispatch_Method__c, SVMXC__Frequency__c, SVMXC__Full_Run_Unit__c from SVMXC__ServiceMax_Processes__c 
                                                                where RecordType.Name = 'Dispatch Process' AND Id =:dispatchProcessGuid];
            
        SVMXC__Territory__c territoryObj = [Select SVMXC__Territory_s_Business_Hours__r.Id from SVMXC__Territory__c where Id =:territoryGuid]; 
            
        BusinessHours bh = [Select Id, Name, IsDefault, IsActive, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, 
                            WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, 
                            SaturdayEndTime, SundayStartTime, SundayEndTime from BusinessHours where IsActive = TRUE AND 
                            Id =: territoryObj.SVMXC__Territory_s_Business_Hours__r.Id ];
        
        if(lstOfDPProcessObj != null && lstOfDPProcessObj.size() > 0) {
            List<DateTime> lstHorizonStartAndEndDateTime = WSCH_CommonUtils.getDPHorizonStartAndEndDates(lstOfDPProcessObj[0], bh);
            if(lstHorizonStartAndEndDateTime != null && lstHorizonStartAndEndDateTime.size() == 2) {
                DateTime horizonStartDateTime = lstHorizonStartAndEndDateTime[0];
                DateTime horizonEndDateTime = lstHorizonStartAndEndDateTime[1];
                
                //converting the horizon datetimes in GMT from territory timezone before comparing against the PST and PET whose values are in GMT.
                DateTime horizonStartDateTimeInGMT = WSCH_DateUtils.doTZConversion(horizonStartDateTime, bh.timeZoneSidKey, 'GMT');
                DateTime horizonEndDateTimeInGMT = WSCH_DateUtils.doTZConversion(horizonEndDateTime, bh.timeZoneSidKey, 'GMT');
                
                //Fetch all the WOs which are within the above horizon dates
                List<SVMXC__Service_Order__c> lstofWOsWithinHorizon = new List<SVMXC__Service_Order__c>();
                String strfld = WSCH_CommonUtils.getWorkorderFields();
                /*if(String.isNotBlank(strfld)){
                    String strRelationFields = ', SVMXC__Company__r.Id, SVMXC__Company__r.Name, SVMXC__Company__r.AccountNumber, SVMXC__Contact__r.FirstName, SVMXC__Contact__r.LastName, SVMXC__Contact__r.Phone, SVMXC__Contact__r.MobilePhone, SVMXC__Site__r.Name, SVMXC__Preferred_Technician__r.SVMXC__Optimizer_External_ID__c, SVMXC__Dispatch_Process__r.SVMXC__Target_URL__c, SVMXC__Preferred_Business_Hours__r.IsActive, SVMXC__Preferred_Business_Hours__r.Id, SVMXC__Group_Member__r.Id,SVMXC__Group_Member__r.Name,SVMXC__Product__r.Name';
                    lstofWOsWithinHorizon =  database.query('Select ' + strfld + strRelationFields + ' From SVMXC__Service_Order__c ' + '  where (SVMXC__Dispatch_Process__c =: dispatchProcessGuid) AND SVMXC__Dispatch_Status__c = \'New\' AND SVMXC__OptiMax_Status__c IN (\'OPT_SKIPPED\',\'OPT_UNASSIGNED\') AND ((SVMXC__Preferred_Start_Time__c >=: horizonStartDateTimeInGMT AND SVMXC__Preferred_Start_Time__c <=: horizonEndDateTimeInGMT) OR (SVMXC__Preferred_End_Time__c >= :horizonStartDateTimeInGMT AND SVMXC__Preferred_End_Time__c <= :horizonEndDateTimeInGMT))');
                }else {
                    lstofWOsWithinHorizon = [Select Name, Id, SVMXC__Work_Order_Scheduling_Status__c, SVMXC__Service_Group__c, SVMXC__Group_Member__c, SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Country__c, SVMXC__Group_Member__r.SVMXC__Salesforce_User__c, SVMXC__Zip__c, SVMXC__Service_Duration__c, SVMXC__Skill_Set__c, SVMXC__Preferred_Start_Time__c, SVMXC__Preferred_End_Time__c, SVMXC__Scheduled_Date_Time__c, SVMXC__Purpose_of_Visit__c, SVMXC__Preferred_Technician__c,SVMXC__Primary_Territory__c,SVMXC__Dispatch_Priority__c,SVMXC__Preferred_Business_Hours__c,SVMXC__Scheduling_Change_Token__c,SVMXC__Acknowledged_By_Technician_Date_Time__c,SVMXC__Started_Driving_To_Location_Date_Time__c,SVMXC__Actual_Onsite_Response__c,SVMXC__Finished_Onsite_Date_Time__c,SVMXC__Completed_Date_Time__c,SVMXC__Scheduling_Retry_Count__c,SVMXC__Dispatch_Process__c,SVMXC__Driving_Time__c,SVMXC__Locked_By_DC__c,SVMXC__OptiMax_Error_Occurred__c,SVMXC__Priority__c,SVMXC__Contact__c,SVMXC__Contact__r.Name,SVMXC__Contact__r.FirstName, SVMXC__Contact__r.LastName, SVMXC__Contact__r.Phone, SVMXC__Contact__r.MobilePhone,SVMXC__FirstScheduledDateTime__c,SVMXC__OptiMax_Error_Text__c,SVMXC__OptiMax_Status__c,SVMXC__Service_Contract__c,SVMXC__Product__c,SVMXC__Partner_Account__c,SVMXC__Appointment_Promised_Time_Slot__c,SVMXC__Service_Zone_ID__c, SVMXC__Company__c, SVMXC__Company__r.Id, SVMXC__Company__r.Name, SVMXC__Company__r.AccountNumber, SVMXC__Site__c, SVMXC__SM_Optimizer_Message_Creation_Date_Time__c,SVMXC__Preferred_Business_Hours__r.IsActive, SVMXC__Preferred_Business_Hours__r.Id, SVMXC__Dispatch_Status__c, SVMXC__SM_Schedule_Violation_Penalty__c from SVMXC__Service_Order__c where (SVMXC__Dispatch_Process__c =: dispatchProcessGuid) AND SVMXC__Dispatch_Status__c = 'New' AND SVMXC__OptiMax_Status__c IN ('OPT_SKIPPED','OPT_UNASSIGNED') AND ((SVMXC__Preferred_Start_Time__c >=: horizonStartDateTimeInGMT AND SVMXC__Preferred_Start_Time__c <=: horizonEndDateTimeInGMT) OR (SVMXC__Preferred_End_Time__c >= :horizonStartDateTimeInGMT AND SVMXC__Preferred_End_Time__c <= :horizonEndDateTimeInGMT))];
                }*/
                
                //commented the above logic. Introduced the below one to handle both OPT_UNASSIGNED and OPT_SKIPPED WOs
                if(String.isNotBlank(strfld)){
                    String strRelationFields = ', SVMXC__Company__r.Id, SVMXC__Company__r.Name, SVMXC__Company__r.AccountNumber, SVMXC__Contact__r.FirstName, SVMXC__Contact__r.LastName, SVMXC__Contact__r.Phone, SVMXC__Contact__r.MobilePhone, SVMXC__Site__r.Name, SVMXC__Preferred_Technician__r.SVMXC__Optimizer_External_ID__c, SVMXC__Dispatch_Process__r.SVMXC__Target_URL__c, SVMXC__Preferred_Business_Hours__r.IsActive, SVMXC__Preferred_Business_Hours__r.Id, SVMXC__Group_Member__r.Id,SVMXC__Group_Member__r.Name,SVMXC__Product__r.Name';
                    lstofWOsWithinHorizon =  database.query('Select ' + strfld + strRelationFields + ' From SVMXC__Service_Order__c ' + '  where (SVMXC__Dispatch_Process__c =: dispatchProcessGuid) AND SVMXC__Dispatch_Status__c = \'New\' AND ((SVMXC__OptiMax_Status__c IN (\'OPT_SKIPPED\') AND ((SVMXC__Preferred_Start_Time__c >=: horizonStartDateTimeInGMT AND SVMXC__Preferred_Start_Time__c <=: horizonEndDateTimeInGMT) OR (SVMXC__Preferred_End_Time__c >= :horizonStartDateTimeInGMT AND SVMXC__Preferred_End_Time__c <= :horizonEndDateTimeInGMT))) OR SVMXC__OptiMax_Status__c IN (\'OPT_UNASSIGNED\'))');
                }else {
                    lstofWOsWithinHorizon = [Select Name, Id, SVMXC__Work_Order_Scheduling_Status__c, SVMXC__Service_Group__c, SVMXC__Group_Member__c, SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Country__c, SVMXC__Group_Member__r.SVMXC__Salesforce_User__c, SVMXC__Zip__c, SVMXC__Service_Duration__c, SVMXC__Skill_Set__c, SVMXC__Preferred_Start_Time__c, SVMXC__Preferred_End_Time__c, SVMXC__Scheduled_Date_Time__c, SVMXC__Purpose_of_Visit__c, SVMXC__Preferred_Technician__c,SVMXC__Primary_Territory__c,SVMXC__Dispatch_Priority__c,SVMXC__Preferred_Business_Hours__c,SVMXC__Scheduling_Change_Token__c,SVMXC__Acknowledged_By_Technician_Date_Time__c,SVMXC__Started_Driving_To_Location_Date_Time__c,SVMXC__Actual_Onsite_Response__c,SVMXC__Finished_Onsite_Date_Time__c,SVMXC__Completed_Date_Time__c,SVMXC__Scheduling_Retry_Count__c,SVMXC__Dispatch_Process__c,SVMXC__Driving_Time__c,SVMXC__Locked_By_DC__c,SVMXC__OptiMax_Error_Occurred__c,SVMXC__Priority__c,SVMXC__Contact__c,SVMXC__Contact__r.Name,SVMXC__Contact__r.FirstName, SVMXC__Contact__r.LastName, SVMXC__Contact__r.Phone, SVMXC__Contact__r.MobilePhone,SVMXC__FirstScheduledDateTime__c,SVMXC__OptiMax_Error_Text__c,SVMXC__OptiMax_Status__c,SVMXC__Service_Contract__c,SVMXC__Product__c,SVMXC__Partner_Account__c,SVMXC__Appointment_Promised_Time_Slot__c,SVMXC__Service_Zone_ID__c, SVMXC__Company__c, SVMXC__Company__r.Id, SVMXC__Company__r.Name, SVMXC__Company__r.AccountNumber, SVMXC__Site__c, SVMXC__SM_Optimizer_Message_Creation_Date_Time__c,SVMXC__Preferred_Business_Hours__r.IsActive, SVMXC__Preferred_Business_Hours__r.Id, SVMXC__Dispatch_Status__c, SVMXC__SM_Schedule_Violation_Penalty__c from SVMXC__Service_Order__c where (SVMXC__Dispatch_Process__c =: dispatchProcessGuid) AND SVMXC__Dispatch_Status__c = 'New' AND ((SVMXC__OptiMax_Status__c IN ('OPT_SKIPPED') AND ((SVMXC__Preferred_Start_Time__c >=: horizonStartDateTimeInGMT AND SVMXC__Preferred_Start_Time__c <=: horizonEndDateTimeInGMT) OR (SVMXC__Preferred_End_Time__c >= :horizonStartDateTimeInGMT AND SVMXC__Preferred_End_Time__c <= :horizonEndDateTimeInGMT))) OR SVMXC__OptiMax_Status__c IN ('OPT_UNASSIGNED'))];
                }
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleWOsFallingInHorizon:lstofWOsWithinHorizon.size() - ' + lstofWOsWithinHorizon.size());
                
                if(lstofWOsWithinHorizon.size() > 0) {
                    List<String> lstWOIds = new List<String>();
                    for(SVMXC__Service_Order__c eachWO : lstofWOsWithinHorizon) {
                        lstWOIds.add(eachWO.Id);
                    }
                    WSCH_ECO_Client_TechnicianServices.scheduleWOsInHorizon(lstWOIds);
                }
            }
        }
        return RETURN_MESSAGE_FOR_WO_UPDATE;
    }
    
    @future(callout=true)
    public static void scheduleWOsInHorizon(List<String> lstWOIds) {
        try{
            WSCH_OptimizedSchedulingService.triggerExecuted = true;
            WSCH_OptimizedSchedulingService.isCallOutExecuted = true;
            List<SVMXC__Service_Order__c> lstOfWOs = WSCH_ECO_CommonUtils.fetchWorkOrders(lstWOIds);
            WSCH_OptimizedSchedulingService.manageWorkOrders(lstOfWOs);
        } catch(Exception ex) {
            WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleWOsInHorizon: Exception caught: ' + ex.getMessage());
        }
    }
    
    public static String scheduleEventsFallingInHorizon(WSCH_ECO_Client_Stubs.TechnicianHorizonUpdateRequest_WP req) {
        
        String dispatchProcessGuid = req.dispatchProcessGuid;
        String territoryGuid = req.territoryGuid;
        
        List<SVMXC__ServiceMax_Processes__c> lstOfDPProcessObj = [SELECT Id, SVMXC__Calendar_Start_Days__c, SVMXC__Calendar_End_Days__c, SVMXC__Dispatch_Method__c, SVMXC__Frequency__c from SVMXC__ServiceMax_Processes__c 
                                                                where RecordType.Name = 'Dispatch Process' AND Id =:dispatchProcessGuid];
            
        SVMXC__Territory__c territoryObj = [Select SVMXC__Territory_s_Business_Hours__r.Id from SVMXC__Territory__c where Id =:territoryGuid]; 
            
        BusinessHours bh = [Select Id, Name, IsDefault, IsActive, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, 
                            WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, 
                            SaturdayEndTime, SundayStartTime, SundayEndTime from BusinessHours where IsActive = TRUE AND 
                            Id =: territoryObj.SVMXC__Territory_s_Business_Hours__r.Id ];
                            
        if(lstOfDPProcessObj != null && lstOfDPProcessObj.size() > 0) {
            List<DateTime> lstHorizonStartAndEndDateTime = WSCH_CommonUtils.getDPHorizonStartAndEndDates(lstOfDPProcessObj[0], bh);
            if(lstHorizonStartAndEndDateTime != null && lstHorizonStartAndEndDateTime.size() == 2) {
                DateTime horizonStartDateTime = lstHorizonStartAndEndDateTime[0];
                DateTime horizonEndDateTime = lstHorizonStartAndEndDateTime[1];
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:horizonStartDateTime - ' + horizonStartDateTime);
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:horizonEndDateTime - ' + horizonEndDateTime);
                
                DateTime horizonStartDateTimeGMT = WSCH_DateUtils.doTZConversion(horizonStartDateTime, bh.TimeZoneSidKey, 'GMT');
                DateTime horizonEndDateTimeGMT = WSCH_DateUtils.doTZConversion(horizonEndDateTime, bh.TimeZoneSidKey, 'GMT');
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:horizonStartDateTimeGMT - ' + horizonStartDateTimeGMT);
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:horizonEndDateTimeGMT - ' + horizonEndDateTimeGMT);
                
                List<Event> lstOfEvents = new List<Event>();
                List<SVMXC__SVMX_Event__c> lstOfSmaxEvents = new List<SVMXC__SVMX_Event__c>();
                List<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizer = new List<SVMXC__SVMX_Optimizer__c>();
                set<String> setAvailTechAsSFUserList = new set<String>();
                set<String> setAvailTechAsSVMXUserList = new set<String>();
                Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
                
                Map<Id, SVMXC__Service_Group_Members__c> mapOfAllTechnicians = new Map<Id, SVMXC__Service_Group_Members__c>([Select Id, Name, SVMXC__Service_Territory__c, SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__c, SVMXC__Service_Territory__r.SVMXC__Per_Mile_Cost__c,
                            SVMXC__Service_Territory__r.SVMXC__Per_Hour_Cost__c, SVMXC__Service_Territory__r.SVMXC__Fixed_Cost__c, SVMXC__Service_Territory__r.SVMXC__Max_Hours__c,
                            SVMXC__Service_Territory__r.SVMXC__Average_Speed__c, SVMXC__Service_Territory__r.SVMXC__Max_Daily_Hours__c, SVMXC__Max_Hours__c,
                            SVMXC__Service_Territory__r.SVMXC__Max_Distance__c, 
                            SVMXC__Salesforce_User__c, SVMXC__Salesforce_User__r.IsActive, SVMXC__Fixed_Cost__c, SVMXC__Latitude_Home__c, SVMXC__Longitude_Home__c, SVMXC__Per_hour_Cost__c,
                            SVMXC__Per_Mile_Cost__c, SVMXC__Average_Speed__c, SVMXC__Max_Daily_Hours__c, SVMXC__Max_Distance__c,
                            SVMXC__Working_Hours__c ,SVMXC__Working_Hours__r.IsActive,
                            SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c , SVMXC__Break_Hours__c, SVMXC__Enable_Scheduling__c,SVMXC__SM_Overnight_Stay_Policy__c,SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__r.IsActive
                            from SVMXC__Service_Group_Members__c 
                            where SVMXC__Active__c = TRUE AND SVMXC__Service_Territory__c = :territoryGuid AND ((SVMXC__Enable_Scheduling__c = TRUE AND SVMXC__Salesforce_User__c = NULL) OR (SVMXC__Salesforce_User__c != NULL AND SVMXC__Salesforce_User__r.IsActive = true) )]);  
                
                for(SVMXC__Service_Group_Members__c tech : mapOfAllTechnicians.values()) {
                    if(tech.SVMXC__Salesforce_User__c != NULL) {
                        setAvailTechAsSFUserList.add(tech.SVMXC__Salesforce_User__c);
                        mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);
                    }
                    else {
                        setAvailTechAsSVMXUserList.add(tech.Id);
                    }
                }
                
                String strOptConnIdWithNoTechId = dispatchProcessGuid+'_'+territoryGuid;
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon: mapOfAllTechnicians.size() :' + mapOfAllTechnicians.size());
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon: mapOfAllTechnicians :' + mapOfAllTechnicians);
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon: strOptConnIdWithNoTechId :' + strOptConnIdWithNoTechId);
                
                //fetch all the OptimizerTransRecords for all the SFEvents and SmaxEvents whose status is OPT_COMPLETED, OPT_ERROR, OPT_FAIL
                lstSVMXOptimizer = [SELECT ID , SVMXC__WhatId__c, SVMXC__WhatType__c, SVMXC__Optimizer_External_Id__c, SVMXC__Optimizer_Status__c, SVMXC__Optimizer_Error_Text__c, SVMXC__Optimizer_Change_Token__c, 
                                        SVMXC__Optimizer_Retry_count__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatType__c = 'NON_WO_EVENT' AND SVMXC__Optimizer_Status__c IN ('OPT_COMPLETED','OPT_ERROR','OPT_FAIL') AND SVMXC__Optimizer_Connection_ID__c LIKE: '%' + strOptConnIdWithNoTechId + '%'];
                                        
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:list of opt_trans records within Horizon to filter:lstSVMXOptimizer.size() - ' + lstSVMXOptimizer.size());
                
                String sfEventKeyPrefix = Schema.SObjectType.Event.getKeyPrefix();
                String smaxEventKeyPrefix = Schema.SObjectType.SVMXC__SVMX_Event__c.getKeyPrefix();
                List<String> lstOfsfEventIds = new List<String>();
                List<String> lstOfSmaxEventIds = new List<String>();
                
                //seggregate the SFEvents and SmaxEvents Ids from the optimizers.
                for(SVMXC__SVMX_Optimizer__c eachOptTrans : lstSVMXOptimizer) {
                    String[] strSplitWhatID = (String.valueOf(eachOptTrans.SVMXC__WhatId__c)).split('_',-1); //fetch the object Prefix from a0v2I00000aiyGGQAY_Aaron
                    String strPrefix = (strSplitWhatID[0].trim()).substring(0,3);
                    if(sfEventKeyPrefix.equals(strPrefix)) {
                        lstOfsfEventIds.add(strSplitWhatID[0].trim());
                    } else if(smaxEventKeyPrefix.equals(strPrefix)) {
                        lstOfSmaxEventIds.add(strSplitWhatID[0].trim());
                    }
                }
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:setAvailTechAsSVMXUserList.size():'+ setAvailTechAsSVMXUserList.size());
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:lstOfSmaxEventIds.size():'+ lstOfSmaxEventIds.size());
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:lstOfsfEventIds.size():'+ lstOfsfEventIds.size());
                
                //query all the SFEvents excluding the above Ids within the Horizon dates
                String strSmaxEventfld = WSCH_ECO_Client_TechnicianServices.getSmaxEventFields();
                if(String.isNotBlank(strSmaxEventfld)){
                    //lstOfSmaxEvents =  database.query('Select ' + strSmaxEventfld + ' From SVMXC__SVMX_Event__c ' + ' WHERE Id NOT IN:lstOfSmaxEventIds AND SVMXC__WhatId__c = null AND SVMXC__Technician__c in:setAvailTechAsSVMXUserList AND ((SVMXC__StartDateTime__c >=: horizonStartDateTimeGMT AND SVMXC__StartDateTime__c <=: horizonEndDateTimeGMT) OR (SVMXC__EndDateTime__c >= :horizonStartDateTimeGMT AND SVMXC__EndDateTime__c <= :horizonEndDateTimeGMT))');
                    lstOfSmaxEvents =  database.query('Select ' + strSmaxEventfld + ' From SVMXC__SVMX_Event__c ' + ' WHERE Id NOT IN:lstOfSmaxEventIds AND SVMXC__WhatId__c = null AND SVMXC__Technician__c in:setAvailTechAsSVMXUserList AND (SVMXC__StartDateTime__c <=: horizonEndDateTimeGMT OR SVMXC__EndDateTime__c >= :horizonStartDateTimeGMT)');
                }
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:SmaxEvents within Horizon:lstOfSmaxEvents.size() - ' + lstOfSmaxEvents.size());
                
                List<String> technicianIds = WSCH_ECO_CommonUtils.getNonWOTechniciansFromSVMXEvents(lstOfSmaxEvents);               
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:technicianIds from SmaxEvents technicianIds.size() - ' + technicianIds.size());
                
                //query all the SmaxEvents excluding the above Ids within the Horizon dates
                String strEventfld = WSCH_ECO_Client_TechnicianServices.getSFEventFields();
                if(String.isNotBlank(strEventfld)){
                    //lstOfEvents =  database.query('Select ' + strEventfld + ' From Event ' + '  WHERE Id NOT IN:lstOfsfEventIds AND WhatId = null AND OwnerId in:setAvailTechAsSFUserList AND ((StartDateTime >=: horizonStartDateTimeGMT AND StartDateTime <=: horizonEndDateTimeGMT) OR (EndDateTime >= :horizonStartDateTimeGMT AND EndDateTime <= :horizonEndDateTimeGMT))');
                    lstOfEvents =  database.query('Select ' + strEventfld + ' From Event ' + '  WHERE Id NOT IN:lstOfsfEventIds AND WhatId = null AND OwnerId in:setAvailTechAsSFUserList AND ((StartDateTime <=: horizonEndDateTimeGMT) OR (EndDateTime >= :horizonStartDateTimeGMT))');
                }
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:SFEvents within Horizon:lstOfEvents.size() - ' + lstOfEvents.size());
                
                technicianIds.addAll(WSCH_ECO_CommonUtils.getNonWOTechniciansFromSFEvents(lstOfEvents));                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:technicianIds from SmaxEvents and SFEvents technicianIds.size() - ' + technicianIds.size());
                
                List<SVMXC__SVMX_Optimizer__c> lstOfSVMXOptimizer = getLstOfOptimizers(lstOfEvents, lstOfSmaxEvents, mapOfAllTechnicians);
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:list of existing opt_trans within Horizon which are not OPT_COMPLETED or OPT_ERROR or OPT_FAIL:lstOfSVMXOptimizer.size() - ' + lstOfSVMXOptimizer.size());
                
                Map<String, SVMXC__SVMX_Optimizer__c> mapOfeventIdOptTransaction = new Map<String, SVMXC__SVMX_Optimizer__c>();
                SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
                List<SVMXC__SVMX_Optimizer__c> optimizerObjects = new List<SVMXC__SVMX_Optimizer__c>();
                List<SVMXC__SVMX_Optimizer__c> lstOfQualifiedSVMXOptimizer = new List<SVMXC__SVMX_Optimizer__c>();
                List<String> lstOfEventIds = new List<String>();
                
                //Below logic logs all the optimizer transaction records that were created for the events and those events were not sent to server
                //and not marked OPT_ERROR or OPT_FAIL or empty by any chance.
                for(SVMXC__SVMX_Optimizer__c eachOptTransRecord : lstOfSVMXOptimizer) {
                    String[] strWhatIdSplit = (eachOptTransRecord.SVMXC__WhatId__c).split('_', -1);  //'eventid_techid'
                    WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices:: Delete the following optimizer transaction record to avoid inconsistency: ' + strWhatIdSplit[0].trim());
                }
                
                //create the optimizer transaction records for the above smax events
                for(SVMXC__SVMX_Event__c eachSmaxEvent : lstOfSmaxEvents) {
                    optimizer = WSCH_ECO_Client_TechnicianServices.createOptimizerObject(String.valueOf(eachSmaxEvent.id),WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE,WSCH_ECO_Constants.OPT_NON_WORK_ORDER_EVENT_TYPE,dispatchProcessGuid,territoryGuid,mapOfAllTechnicians.get(eachSmaxEvent.SVMXC__Technician__c));
                    optimizerObjects.add(optimizer);
                }
                
                //create the optimizer transaction records for the above SFevents
                for(Event eachSFEvent : lstOfEvents) {
                    optimizer = WSCH_ECO_Client_TechnicianServices.createOptimizerObject(String.valueOf(eachSFEvent.id),WSCH_ECO_Constants.OPT_OPTIMIZER_CHANGE_TOKEN_CREATE,WSCH_ECO_Constants.OPT_NON_WORK_ORDER_EVENT_TYPE,dispatchProcessGuid,territoryGuid,mapOwnerIDTechId.get(eachSFEvent.OwnerId));
                    optimizerObjects.add(optimizer);
                }
                
                insert optimizerObjects;
                
                //add the newly created optimizer transaction records to the qualified list
                lstOfQualifiedSVMXOptimizer.addAll(optimizerObjects);
                
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:no. of optimizer Transactions newly created - ' + optimizerObjects.size());
                WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsFallingInHorizon:no. of optimizer Transactions to be synced to server - ' + lstOfQualifiedSVMXOptimizer.size());
                
                if(lstOfQualifiedSVMXOptimizer != null && lstOfQualifiedSVMXOptimizer.size() != 0){
                    List<String> lstOptTransIds = new List<String>();
                    for(SVMXC__SVMX_Optimizer__c eachOptTransObj : lstOfQualifiedSVMXOptimizer) {
                        lstOptTransIds.add(eachOptTransObj.Id);
                    }
                    WSCH_ECO_Client_TechnicianServices.scheduleEventsInHorizon(lstOptTransIds);
                }
            }
        }
        return RETURN_MESSAGE_FOR_NON_WO_EVENT_UPDATE;
    }
    
    public static SVMXC__SVMX_Optimizer__c createOptimizerObject(String eventid, String changeToken,String eventType,String dProcess,String teritory,SVMXC__Service_Group_Members__c technician) {
        SVMXC__SVMX_Optimizer__c obj = new SVMXC__SVMX_Optimizer__c();
        obj.SVMXC__WhatType__c = eventType;
        obj.SVMXC__WhatId__c = eventid+'_'+technician.name;
        obj.SVMXC__Optimizer_Change_Token__c = changeToken;
        obj.SVMXC__Optimizer_Connection_ID__c = dProcess+'_'+teritory+'_'+technician.id;
        return obj;
    }
    
    @future(callout=true)
    public static void scheduleEventsInHorizon(List<String> lstOfOptimizerIds) {
        try {
            WSCH_OptimizedSchedulingService.triggerExecuted = true;
            WSCH_OptimizedSchedulingService.isCallOutExecuted = true;
            List<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizer = WSCH_CommonUtils.fetchSVMXOptimizerById(lstOfOptimizerIds);
            //Call manageNonWOEvents for all the OptimizerTransRecords
            WSCH_OptimizedSchedulingService.manageNonWorkOrderEvents(lstSVMXOptimizer);
        } catch(Exception ex) {
            WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices::scheduleEventsInHorizon: Exception caught: ' + ex.getMessage());
        }
    }
    
    public static list<SVMXC__SVMX_Optimizer__c> getLstOfOptimizers(list<Event> sfEvents, List<SVMXC__SVMX_Event__c> svmxEvents, Map<Id,SVMXC__Service_Group_Members__c> mapOfTechnicians)
    { 
        WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices : getEventIdAndOptimizers ');
        map<String,SVMXC__SVMX_Optimizer__c> mapIdOptimizer = new map<String,SVMXC__SVMX_Optimizer__c>();   
        list<String> lstEventID= new list<String> ();           
        list<SVMXC__SVMX_Optimizer__c> lstSVMXOptimizer = new list<SVMXC__SVMX_Optimizer__c> ();

        //Map<Id,SVMXC__Service_Group_Members__c> techniciansMap= WSCH_ECO_CommonUtils.getTechnicians(technicianIds);
        
        Map<Id,SVMXC__Service_Group_Members__c> mapOwnerIDTechId = new Map<Id,SVMXC__Service_Group_Members__c>();
        //create ownerId map
        for(SVMXC__Service_Group_Members__c tech : mapOfTechnicians.values()){
                if(tech.SVMXC__Salesforce_User__c != null)
                    mapOwnerIDTechId.put(tech.SVMXC__Salesforce_User__c, tech);   
        }        

        SVMXC__Service_Group_Members__c technician;
        if(null != sfEvents){
            for(Event objEvent : sfEvents){
                technician = mapOwnerIDTechId.get(objEvent.OwnerId);
                if(null != technician){
                    lstEventID.add(objEvent.id+'_'+technician.name);
                }
            }
        }
            
        if (null != svmxEvents){
            for(SVMXC__SVMX_Event__c objEvent : svmxEvents){
                technician = mapOfTechnicians.get(objEvent.SVMXC__Technician__c);
                if(null != technician){
                   lstEventID.add(objEvent.id+'_'+technician.name); 
                }
            }
        }
            
        /*lstSVMXOptimizer = [SELECT ID , SVMXC__WhatId__c, SVMXC__WhatType__c, SVMXC__Optimizer_External_Id__c, SVMXC__Optimizer_Status__c, SVMXC__Optimizer_Error_Text__c, SVMXC__Optimizer_Change_Token__c, 
                                        SVMXC__Optimizer_Retry_count__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstEventID AND SVMXC__Optimizer_Status__c = 'OPT_ERROR'];*/
                                        
        lstSVMXOptimizer = [SELECT ID , SVMXC__WhatId__c, SVMXC__WhatType__c, SVMXC__Optimizer_External_Id__c, SVMXC__Optimizer_Status__c, SVMXC__Optimizer_Error_Text__c, SVMXC__Optimizer_Change_Token__c, 
                                        SVMXC__Optimizer_Retry_count__c,SVMXC__Optimizer_Connection_ID__c  from SVMXC__SVMX_Optimizer__c  where SVMXC__WhatId__c in: lstEventID AND SVMXC__WhatType__c = 'NON_WO_EVENT' AND SVMXC__Optimizer_Status__c NOT IN ('OPT_COMPLETED','OPT_ERROR','OPT_FAIL')];
          
        WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices : Optimizer Objects size  - '+lstSVMXOptimizer.size());
       
        return lstSVMXOptimizer;
    }
    
    public static String getSmaxEventFields() {
        String strFlds = '';
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapOfFields = gd.get('SVMXC__SVMX_Event__c').getDescribe().fields.getMap();
            List<String> lstOfKeys = new List<String>(mapOfFields.keySet());
            lstOfKeys.sort();
            for(String key : lstOfKeys)  
            {  
                Schema.DescribeFieldResult fieldResult = mapOfFields.get(key).getDescribe();  
                if(fieldResult.isAccessible())
                {  
                    if(strFlds.length() > 0)
                        strFlds += ',';
                    strFlds += fieldResult.getName();
                }
                
            }
        }catch(Exception ex){
            String exceptionMsg = 'WSCH_ECO_Client_TechnicianServices::getSmaxEventFields(): ';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + '\n  Stack Trace:: ' + ex.getStackTraceString());
        }       
        //WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices:getSmaxEventFields::SMAX_Event fields returned: '+strFlds);
        return strFlds;
    }
    
    public static String getSFEventFields() {
        String strFlds = '';
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapOfFields = gd.get('Event').getDescribe().fields.getMap();
            List<String> lstOfKeys = new List<String>(mapOfFields.keySet());
            lstOfKeys.sort();
            for(String key : lstOfKeys)  
            {  
                Schema.DescribeFieldResult fieldResult = mapOfFields.get(key).getDescribe();  
                if(fieldResult.isAccessible())
                {  
                    if(strFlds.length() > 0)
                        strFlds += ',';
                    strFlds += fieldResult.getName();
                }
            }
        }catch(Exception ex){
            String exceptionMsg = 'WSCH_ECO_Client_TechnicianServices::getSFEventFields(): ';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + '\n  Stack Trace:: ' + ex.getStackTraceString());
        }       
        //WSCH_AuditLogger.debug('WSCH_ECO_Client_TechnicianServices:getSFEventFields::SFEvent fields returned: '+strFlds);
        return strFlds;
    }
}