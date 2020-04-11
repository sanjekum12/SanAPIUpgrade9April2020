@RestResource(urlMapping='/scheduling/batch/initiate')
global with sharing class WSCH_LTP_Initiate_Service {
    public static final String NO_OP_ERROR_MESSAGE = 'Empty or Invalid operation type';

    public class SVMXException extends Exception{}
    SVMXC.COMM_Utils_ManageSettings clsCommSettings = new SVMXC.COMM_Utils_ManageSettings();
    
    @HttpPost
    global static WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP doPost() {
        //String returnMsg = NO_OP_ERROR_MESSAGE;
        WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP initResponse = new WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP();
        RestRequest request = RestContext.request;
        Blob data = request.requestBody;
        String initReq = data.toString();
        try {
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doPost::Json Request: ' + initReq);
            WSCH_LTP_Scheduling_Stubs.InitJobRequest_WP req = (WSCH_LTP_Scheduling_Stubs.InitJobRequest_WP)JSON.deserialize(initReq, WSCH_LTP_Scheduling_Stubs.InitJobRequest_WP.class);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::after parsing...: ' + req);
            initResponse = invokeInitJob(req);
        } catch(Exception ex){
            WSCH_AuditLogger.error('WSCH_LTP_Initiate_Service::doPost():Exception occured..'+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());         
        } finally{
            WSCH_AuditLogger.finish();
        }
        return initResponse;
    }
    
    
    public static WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP invokeInitJob(WSCH_LTP_Scheduling_Stubs.InitJobRequest_WP req) {
        WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP initResponse = new WSCH_LTP_Scheduling_Stubs.InitJobResponse_WP();
        String dispatchProcessGuid = req.dispatchProcessGuid;
        String territoryGuid;
        if(req.territoryGuid.contains('_'))
        {
            list<String> lstTerritoryDef = new list<String>();
            lstTerritoryDef = req.territoryGuid.split('_');
            territoryGuid = lstTerritoryDef[0];
        }
        String connectionId = dispatchProcessGuid + '_' + territoryGuid;
        //String respJson='';
        SVMXC.COMM_Utils_ManageSettings commSettings = new SVMXC.COMM_Utils_ManageSettings();
        list<string> lstSettings = new list<string>();
        lstSettings.add('GLOB001_GBL007');
        lstSettings.add('OMAX002_SET002');
        map<String, String> mapSetting = commSettings.SVMX_getGlobalSettingList(lstSettings);

        // Do not proceed if the setting Enable Dispatch Optimization is set to FALSE
        if(mapSetting.containsKey('GLOB001_GBL007') && mapSetting.get('GLOB001_GBL007').toUpperCase() == 'FALSE')
        {
            throw new SVMXException('Dispatch optimization is not enabled for the organization.');
        }

        if(dispatchProcessGuid != null && dispatchProcessGuid.length() > 0 && territoryGuid != null && territoryGuid.length() > 0)
        {
            // Check if there are any jobs running for the given dispatch process & territory
            // with status Initiated, In Progress, Precalc Completed, QTL Completed, Resources Sent or Work Orders Being Sent. If yes, check age of job and decide as below
            // (1) If zombie, mark as zombie and start new job
            // (2) If not, throw exception and do not start new job 
            list<SVMXC__SVMX_Jobs__c> SVMXJobs = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c   from SVMXC__SVMX_Jobs__c where SVMXC__SVMX_Process__c = :dispatchProcessGuid and SVMXC__Territory__c = :territoryGuid and SVMXC__Type__c = :WSCH_ECO_Constants.SVMXJOB_LTP_TYPE and (SVMXC__OptiMax_Message__c = 'Initiated' OR SVMXC__OptiMax_Message__c = 'Staging' OR SVMXC__OptiMax_Message__c = 'In Progress')];  //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::invokeInitJob...: ' + SVMXJobs.size());
            boolean createNewJobRecord = false;
            if(SVMXJobs.size() == 0)
                createNewJobRecord = true;
            
            if(SVMXJobs.size() > 0)
            {
                list <SVMXC__SVMX_Jobs__c> SVMXJobsUpdate = new list<SVMXC__SVMX_Jobs__c> ();
                Datetime dtmNow = system.now();
                String strJobIds = '';
                String zombieJobId = '';
                try
                {
                    for(SVMXC__SVMX_Jobs__c oj: SVMXJobs)
                    {
                        Double dblAge = ((dtmNow.getTime() - oj.SVMXC__Start_Time__c.getTime()) / 60000);
                        if(dblAge >= Double.valueof(mapSetting.get('OMAX002_SET002')))
                        {
                            oj.SVMXC__Age__c = dblAge;
                            oj.SVMXC__Status__c = String.valueof(-4);
                            oj.SVMXC__End_Time__c = dtmNow;
                            oj.SVMXC__OptiMax_Message__c = 'Canceled - Zombie';
                            zombieJobId = oj.id;
                            SVMXJobsUpdate.add(oj);
                            // Marked existing job as Zombie, so create a new job for this run
                            createNewJobRecord = true;
                        }
                        else
                        {
                            strJobIds += oj.Id + '-' + oj.Name;
                            throw new SVMXException('OptiMax job(s) ' + strJobIds + ' for the same territory in progress');
                        }
                    }
                    
                    update SVMXJobsUpdate; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
                } catch(Exception ex){
                    WSCH_AuditLogger.error('WSCH_LTP_Initiate_Service::invokeInitJob():Exception occured..'+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());         
                    //respJson = ex.getMessage();
                    WSCH_AuditLogger.finish();
                }
            }

            if(createNewJobRecord)
            {
                // Check if territory exists
                SVMXC__Territory__c objTerritory = new SVMXC__Territory__c();
                try
                {
                    objTerritory = [Select Id from SVMXC__Territory__c where Id = :territoryGuid.trim()];
                    WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::Territory ' + territoryGuid + ' exists');

                    // Check if dispatch process exists
                    SVMXC__ServiceMax_Processes__c objSVMXProcess = new SVMXC__ServiceMax_Processes__c();
                    objSVMXProcess = [Select Id from SVMXC__ServiceMax_Processes__c where Id = :dispatchProcessGuid]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
                    system.debug('Dispatch Process ' + dispatchProcessGuid + ' exists');
                    
                    SVMXC__SVMX_Jobs__c objSVMXJob = new SVMXC__SVMX_Jobs__c();
                    objSVMXJob.SVMXC__SVMX_Process__c = dispatchProcessGuid;
                    objSVMXJob.SVMXC__Territory__c = territoryGuid;
                    objSVMXJob.SVMXC__OptiMax_Message__c = 'Initiated'; 
                    objSVMXJob.SVMXC__Start_Time__c = system.now();
                    objSVMXJob.SVMXC__Initiated_By__c = Userinfo.getUserId();
                    objSVMXJob.SVMXC__Status__c = req.jobInstanceId;
                    //if(req.jobType =='LTPS')
                        objSVMXJob.SVMXC__Type__c = WSCH_ECO_Constants.SVMXJOB_LTP_TYPE; // Long term plan schedule
                    //else
                    //    objSVMXJob.SVMXC__Type__c = 'FULL';  // FULL
                    insert objSVMXJob; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
                    WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::invokeInitJob():SVMX Job record created: ' + objSVMXJob);
                    initResponse.jobInstanceId = req.jobInstanceId;
                    initResponse.jobInstanceGuid = objSVMXJob.Id;
                    //respJson=JSON.serialize(resp);
                    //invoke future call for callout with workorders, technicians and events ids.
                    doSendIds(objSVMXJob.Id);
                } catch(Exception ex){
                    WSCH_AuditLogger.error('WSCH_LTP_Initiate_Service::invokeInitJob():Exception occured while trying to create svmxjob record..'+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());         
                    WSCH_AuditLogger.finish();
                }
            }
        }
        return initResponse;
    }
    
    @future(callout=true)
    public static void doSendIds(String strSVMXJobId){
        WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: Start of Future call: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());
        Datetime dtmSchedulingHorizonStart;
        Datetime dtmSchedulingHorizonEnd;
        SMAX_OptiMax_Engine_Ext clsOMaxExtension = new SMAX_OptiMax_Engine_Ext();
        String strDefaultBHourId;
        BusinessHours objDefTerritoryBH;
        SVMXC__Territory__c objTerritory = new SVMXC__Territory__c();
        SVMXC__ServiceMax_Processes__c objSVMXProcess = new SVMXC__ServiceMax_Processes__c();
        SVMXC__SVMX_Jobs__c objJob = new SVMXC__SVMX_Jobs__c();
        List<SVMXC__SVMX_Jobs__c> lstSvmxJobs = new List<SVMXC__SVMX_Jobs__c>();
        List<SVMXC__Service_Group_Members__c> lstTechnicians = new List<SVMXC__Service_Group_Members__c>();
        List<SVMXC__Service_Order__c> lstWorkOrderObj = new List<SVMXC__Service_Order__c>();        
        list<BusinessHours> lstBusinessHours = new list<BusinessHours>();
        Map<String, BusinessHours> mapBusinessHours = new Map<String, BusinessHours>();
        List<String> lstWOIds = new List<String>();
        List<String> lstTechIds = new List<String>();
        List<String> lstEventIds = new List<String>();
        set<String> setAvailTechAsSFUserList = new set<String>();
        set<String> setAvailTechAsSVMXUserList = new set<String>();
        map<String,SVMXC__Service_Order__c> mapConfirmedWOs = new  map<String,SVMXC__Service_Order__c>();
        Map<Id, Event> mapSFEvent = new Map<Id, Event>();
        Map<Id, SVMXC__SVMX_Event__c> mapSVMXEvent = new Map<Id, SVMXC__SVMX_Event__c>();   
        Map<String, String> mapUsersTechnicians = new Map<String, String>();
        WSCH_LTP_Scheduling_Stubs.ExecuteJobRequest_WP exeJobReq = new WSCH_LTP_Scheduling_Stubs.ExecuteJobRequest_WP();
        Map<String, String> optParameters = new Map<String, String>();
        SVMXC.COMM_Utils_ManageSettings clsCommSettings = new SVMXC.COMM_Utils_ManageSettings();
        String serviceName = WSCH_Provider_ECO_Callout_Helper.LTP_SERVICE_PATH;
        List<SVMXC__Service_Order__c> lstInvalidWOs = new List<SVMXC__Service_Order__c>();  
        //WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::begin...');

        try
        {
            objJob = [Select Id, SVMXC__Status__c, SVMXC__Age__c, SVMXC__Start_Time__c, SVMXC__End_Time__c, SVMXC__SVMX_Process__c,
                        SVMXC__Territory__c, SVMXC__Sent_Work_Orders__c, SVMXC__Sent_Resources__c, SVMXC__Sent_Events_Count__c, SVMXC__OptiMax_Message__c from SVMXC__SVMX_Jobs__c where Id = :strSVMXJobId]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::objJob:'+objJob);
        
            objTerritory = [Select Id, SVMXC__Territory_s_Business_Hours__c, SVMXC__Territory_s_Business_Hours__r.TimeZoneSidKey, SVMXC__Territory_s_Business_Hours__r.Id, SVMXC__Break_Hours__c, SVMXC__Average_Driving_Time__c, SVMXC__Per_Mile_Cost__c,
                            SVMXC__Max_Distance__c, SVMXC__Average_Speed__c, SVMXC__Fixed_Cost__c, SVMXC__Per_hour_Cost__c, SVMXC__Mode_Of_Travel__c,SVMXC__SM_Overnight_Stay_Policy__c
                            from SVMXC__Territory__c
                            where Id = :objJob.SVMXC__Territory__c];
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::objTerritory:'+objTerritory);

            lstBusinessHours = [Select Id, Name, IsDefault, IsActive, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime,
                                ThursdayStartTime, ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime
                                from BusinessHours where Id =: objTerritory.SVMXC__Territory_s_Business_Hours__c OR IsDefault = TRUE];
                                //where IsActive = TRUE AND (IsDefault = TRUE OR TimeZoneSidKey = :territoryTZsidKey)];
            lstBusinessHours = clsOMaxExtension.getCompleteBusinessHour(lstBusinessHours);
            for(BusinessHours bh : lstBusinessHours)
            {
                mapBusinessHours.put(bh.Id, bh);
                if(bh.IsDefault == TRUE)
                    strDefaultBHourId = bh.Id;
            }
            //Heap size issue
            lstBusinessHours.clear();

            
            objSVMXProcess = [Select Id, SVMXC__Child_Object_Criteria__c, SVMXC__Frequency__c, SVMXC__Full_Run_Unit__c, SVMXC__Retain_Appointment__c,
                            SVMXC__Retain_Assignment__c, SVMXC__Route_Type__c, SVMXC__Weight_Time_Window__c, SVMXC__Weight_Total_Distance__c, SVMXC__Weight_Route_Distance__c,
                            SVMXC__Weight_Node_Type__c, SVMXC__Calendar_Start_Type__c, SVMXC__Calendar_End_Type__c, 
                            SVMXC__Weight_Route_Time__c,
                            SVMXC__Tolerance__c, SVMXC__Calendar_Start_Days__c, SVMXC__Calendar_End_Days__c, SVMXC__Preferred_Tech_Enabled__c, SVMXC__Expertise_Match_Enabled__c,
                            SVMXC__Product_Match_Enabled__c, SVMXC__SM_Drive_Before_Shift_Start__c, SVMXC__SM_Drive_After_Shift_End__c, SVMXC__Optimization_Goal__c,SVMXC__Window_Height__c,SVMXC__Window_Width__c 
                            from SVMXC__ServiceMax_Processes__c
                            where Id =:objJob.SVMXC__SVMX_Process__c]; //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::objSVMXProcess:'+objSVMXProcess);

            //TODO: calculate LTP horizon from dispatch process definition
            objDefTerritoryBH = mapBusinessHours.get(objTerritory.SVMXC__Territory_s_Business_Hours__c);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::objDefTerritoryBH:'+objDefTerritoryBH);
            Map<String, list<Date>> mapHorizonDetails = new Map<String, list<Date>>();
            mapHorizonDetails = doCreateLTPHorizon(objSVMXProcess,objDefTerritoryBH);
            List<Date> lstSchedHorizDates = new List<Date>();
            lstSchedHorizDates.addAll(mapHorizonDetails.values()[0]);
            List<String> lstString = new List<String>();
            lstString.addAll(mapHorizonDetails.keySet());
            List<String> ltpStartEndDT = lstString[0].split(',');
            dtmSchedulingHorizonStart = Datetime.valueOfGMT(ltpStartEndDT[0].trim());
            dtmSchedulingHorizonEnd = Datetime.valueOfGMT(ltpStartEndDT[1].trim());
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::LTP Job horizon start and end datetime:'+dtmSchedulingHorizonStart+' - '+dtmSchedulingHorizonEnd);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::setSchedHorizDates size:'+lstSchedHorizDates.size());
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: start preparing work order Ids: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());

            //TODO:Need to implement batch query due to query limit (50K records)
            //Split the horizon dates into multiple group of 30 days and f                      
            String strWorkOrderQuery = 'Select Id, Name, SVMXC__Preferred_Business_Hours__c, SVMXC__Preferred_Business_Hours__r.IsActive, SVMXC__Primary_Territory__c, SVMXC__QTL_Status__c,SVMXC__Zip__c,SVMXC__Locked_By_DC__c,SVMXC__SM_Lock_Appointment_Schedule__c, SVMXC__Latitude__c,SVMXC__Longitude__c,SVMXC__Street__c,SVMXC__City__c,SVMXC__State__c,SVMXC__Country__c,SVMXC__Preferred_Start_Time__c,SVMXC__Preferred_End_Time__c,SVMXC__OptiMax_Error_Text__c from SVMXC__Service_Order__c WHERE SVMXC__Primary_Territory__c = \'' + objJob.SVMXC__Territory__c + '\' AND SVMXC__Dispatch_Process__c = \'' + objJob.SVMXC__SVMX_Process__c + '\'';

            if(objSVMXProcess.SVMXC__Child_Object_Criteria__c != NULL)
                strWorkOrderQuery += ' AND (' + objSVMXProcess.SVMXC__Child_Object_Criteria__c + ')';
            
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::strWorkOrderQuery:'+strWorkOrderQuery);       

            lstWorkOrderObj = Database.query(strWorkOrderQuery);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::lstWorkOrderObj size():'+lstWorkOrderObj.size());

            for(SVMXC__Service_Order__c wo : lstWorkOrderObj){
                //create map of work orders falls under confirmed. Need to send the events instead work order.
                if(wo.SVMXC__Locked_By_DC__c == true || wo.SVMXC__SM_Lock_Appointment_Schedule__c == WSCH_ECO_Constants.SCHEDULE_LOCK_IN_PLACE ){ 
                    mapConfirmedWOs.put(wo.Name,wo);
                    continue;
                }
                if(wo.SVMXC__Preferred_Start_Time__c == NULL && wo.SVMXC__Preferred_End_Time__c == NULL) {
                    WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds:As both PST and PET are available, skipping this WO - ' + wo.Id);
                    String errorText = 'As both PST and PET are not available, skipping this WO from scheduling';
                    WSCH_CommonUtils.setOptimizerErrorText(wo, errorText);
                    lstInvalidWOs.add(wo);
                    continue;
                }                
                lstWOIds.add(wo.Name);
            }
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::lstWOIds.size():'+lstWOIds.size());
                        
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: start preparing technician Ids: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());

            // Retrieve technician records from Service_Group_Members__c for the given territory ID
            lstTechnicians = [Select Id, Name, SVMXC__Service_Territory__c, SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__c, SVMXC__Service_Territory__r.SVMXC__Per_Mile_Cost__c,
                            SVMXC__Service_Territory__r.SVMXC__Per_Hour_Cost__c, SVMXC__Service_Territory__r.SVMXC__Fixed_Cost__c, SVMXC__Service_Territory__r.SVMXC__Max_Hours__c,
                            SVMXC__Service_Territory__r.SVMXC__Average_Speed__c, SVMXC__Service_Territory__r.SVMXC__Max_Daily_Hours__c, SVMXC__Max_Hours__c,
                            SVMXC__Service_Territory__r.SVMXC__Max_Distance__c, 
                            SVMXC__Salesforce_User__c, SVMXC__Salesforce_User__r.IsActive, SVMXC__Fixed_Cost__c, SVMXC__Latitude_Home__c, SVMXC__Longitude_Home__c, SVMXC__Per_hour_Cost__c,
                            SVMXC__Per_Mile_Cost__c, SVMXC__Average_Speed__c, SVMXC__Max_Daily_Hours__c, SVMXC__Max_Distance__c,
                            SVMXC__Working_Hours__c ,SVMXC__Working_Hours__r.IsActive, SVMXC__Break_Hours__r.IsActive,
                            SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c , SVMXC__Break_Hours__c, SVMXC__Enable_Scheduling__c,SVMXC__SM_Overnight_Stay_Policy__c,SVMXC__Service_Territory__r.SVMXC__Territory_s_Business_Hours__r.IsActive
                            from SVMXC__Service_Group_Members__c 
                            where SVMXC__Active__c = TRUE AND SVMXC__Service_Territory__c = :objJob.SVMXC__Territory__c AND ((SVMXC__Enable_Scheduling__c = TRUE AND SVMXC__Salesforce_User__c = NULL) OR (SVMXC__Salesforce_User__c != NULL AND SVMXC__Salesforce_User__r.IsActive = true) )];                 
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::lstTechnicians size():'+lstTechnicians.size());

            for(SVMXC__Service_Group_Members__c tech : lstTechnicians){
                String strTechId = tech.Id+'_'+tech.Name;
                lstTechIds.add(strTechId);
                
                if(tech.SVMXC__Salesforce_User__c != NULL)
                {   
                    setAvailTechAsSFUserList.add(tech.SVMXC__Salesforce_User__c);
                    mapUsersTechnicians.put(tech.SVMXC__Salesforce_User__c, tech.Id);
                }
                else
                    setAvailTechAsSVMXUserList.add(tech.Id);
            }
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::setAvailTechAsSFUserList:'+setAvailTechAsSFUserList.size());
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::setAvailTechAsSVMXUserList:'+setAvailTechAsSVMXUserList.size());
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::lstTechIds:'+lstTechIds.size());

            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: start preparing event Ids: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());
            //Retrieve technician events and collect non workorder events
            mapSFEvent = getMapNonWOSFEventforTech(setAvailTechAsSFUserList, dtmSchedulingHorizonStart,dtmSchedulingHorizonEnd);
            mapSVMXEvent = getMapNonWOSVMXEventforTech(setAvailTechAsSVMXUserList, dtmSchedulingHorizonStart,dtmSchedulingHorizonEnd);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::mapSFEvent:'+mapSFEvent);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::mapSVMXEvent:'+mapSVMXEvent);           
            
            for(Event e:mapSFEvent.values()){
                String technicianId = mapUsersTechnicians.get(e.OwnerId);
                String techEventId = 'Event_'+technicianId+'_'+e.Id;
                lstEventIds.add(techEventId);
            }
            
            for(SVMXC__SVMX_Event__c e: mapSVMXEvent.values()){
                String technicianId = e.SVMXC__Technician__c;
                String techEventId = 'Event_'+technicianId+'_'+e.Id;
                lstEventIds.add(techEventId);
            }
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::lstEventIds:'+lstEventIds);
            
            //setting optimization parameter for the run.
            //String strDistanceProvider = WSCH_CommonUtils.getSettingValue('DCON001','SET071'); 
            optParameters.put('distanceProvider', 'Heuristic');
            
            if(objTerritory.SVMXC__Mode_Of_Travel__c != NULL)
            {
                optParameters.put('modeOfTravel', String.valueOf(objTerritory.SVMXC__Mode_Of_Travel__c));
            }else{
                optParameters.put('modeOfTravel', 'Driving');
            }
            optParameters.put('modeOfJob','LongTermPlan');
                     
            //setting the values in executeJob request wrapper for callout.
            exeJobReq.jobInstanceGuid=strSVMXJobId;
            exeJobReq.jobInstanceId = objJob.SVMXC__Status__c;
            exeJobReq.workOrderIds = lstWOIds;
            exeJobReq.resourceIds = lstTechIds;
            exeJobReq.eventIds = lstEventIds;
            exeJobReq.parameters = optParameters;

            //making callout
            String requestJson=JSON.serialize(exeJobReq); 
            //WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::requestJson:'+requestJson);
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: End preparing event Ids: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());
            String calloutEndpoint = WSCH_Provider_ECO_Callout_Helper.OPTIMAXSERVICE_ENDPOINT_URL + WSCH_Provider_ECO_Callout_Helper.LTP_SERVICE_PATH;
            WSCH_Provider_ECO_Stubs.Response_WP response_x =  WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,calloutEndpoint);
            if(response_x.status == '200'){
                WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::Callout was successfull.'+response_x);
            } else{
                WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds::Callout failed.'+response_x);
            }
            WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doSendIds: End of Future call: No of Queries used in this transaction so far: ' + Limits.getQueries()+' | '+'heap size :'+Limits.getHeapSize());
            if(lstInvalidWOs.size() > 0 ) update lstInvalidWOs;
            //TODO: update the no of work orders, technicians and events sent details in the SVMXJob record
            if(lstWOIds != null && lstWOIds.size() > 0 && lstTechIds != null && lstTechIds.size() > 0 ){
                objJob.SVMXC__Sent_Work_Orders__c = lstWOIds.size();
                objJob.SVMXC__Sent_Resources__c = lstTechIds.size();
                objJob.SVMXC__Sent_Events_Count__c = lstEventIds.size();
            }else{
                objJob.SVMXC__OptiMax_Message__c = 'Initiate Error';
                objJob.SVMXC__End_Time__c = Datetime.now(); 
            }
            update objJob;
            WSCH_AuditLogger.finish();
        }
        catch(Exception e)
        {
            WSCH_AuditLogger.error('WSCH_LTP_Initiate_Service::doSendIds::Exception type caught: ' + e.getTypeName()+'\n' +'Message: ' + e.getMessage()+'\n'+'Cause: ' + e.getCause()+'\n'+'Line number: ' + e.getLineNumber()+'\n'+'Stack trace: ' + e.getStackTraceString()+'\n');
            WSCH_AuditLogger.finish();
        }
        
    }
    


    public static Map<String, List<Date>> doCreateLTPHorizon(SVMXC__ServiceMax_Processes__c objSVMXProcess, BusinessHours objDefTerritoryBH){
        SMAX_OptiMax_Engine_Ext clsOMaxExtension = new SMAX_OptiMax_Engine_Ext();
        Integer intNoOfDays = 0;
        If(objSVMXProcess.SVMXC__Calendar_End_Days__c != null){
            intNoOfDays = (objSVMXProcess.SVMXC__Calendar_End_Days__c).intValue();
        }else{
            //This is the case of standalone LTP dispatch process.
            intNoOfDays = (objSVMXProcess.SVMXC__Window_Height__c).intValue();
        }
        Date datStartDate;
        Date datEndDate;
        Datetime dtmNow = system.now();
        DateTime dtmSchedulingHorizonStartDateTime;
        Datetime dtmLastProcessedDateTime;
        set<Date> setSchedHorizDates = new set<Date>();
        String strHorizonStartEndDT;
        Map<String, List<Date>> mapHorizonDetails = new Map<String, List<Date>>();
        if(intNoOfDays < 1)
            intNoOfDays = 1;
        
        Integer intStartAfterDays;
        intStartAfterDays = objSVMXProcess.SVMXC__Window_Height__c.intValue();
        if(intStartAfterDays < 0)
        intStartAfterDays = 0;

        Datetime tempStDt = clsOMaxExtension.getNextWorkingHour(objDefTerritoryBH, dtmNow);
        for (integer i = 0; i < intStartAfterDays; i++)
        {
            // We add 1 minute to the tempStDt every time through the loop to force getNextWorkingHour
            // function to return the next working day. Else, it will keep returning the same date time
            tempStDt = clsOMaxExtension.getNextWorkingHour(objDefTerritoryBH, tempStDt.addMinutes(1));
        }
        dtmSchedulingHorizonStartDateTime = tempStDt;
        // Get the date of the first day in the scheduling horizon in Business Hour time zone
        datStartDate = Date.valueOf(dtmSchedulingHorizonStartDateTime.format('yyyy-MM-dd', objDefTerritoryBH.timeZoneSidKey));

        // Starting from the first day, get all the dates in the scheduling horizon
        dtmlastProcessedDateTime = dtmSchedulingHorizonStartDateTime;
        strHorizonStartEndDT = String.ValueOfGMT(dtmlastProcessedDateTime);
        //WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doCreateLTPHorizon::LTP Job horizon startdatetime:'+strHorizonStartEndDT);

        // Starting from the primary job horizon end date, get all the dates till the LTP dispatch process definition end date.
        //SVMXC__Max_Hours_Per_Day__c - This is the field used to store the horizon end date for LTP
        integer intNoOfDaysLTP = objSVMXProcess.SVMXC__Window_Width__c.intValue();
        Date ltpTempDate = datStartDate;
        setSchedHorizDates.add(ltpTempDate);
        for(integer i = 0; i < intNoOfDaysLTP - 1; i++)
        {
            dtmlastProcessedDateTime = clsOMaxExtension.getNextWorkingHour(objDefTerritoryBH, dtmlastProcessedDateTime.addMinutes(1));
            ltpTempDate = Date.valueOf(dtmlastProcessedDateTime.format('yyyy-MM-dd', objDefTerritoryBH.timeZoneSidKey));
            setSchedHorizDates.add(ltpTempDate);
            datEndDate = ltpTempDate;
        }
        strHorizonStartEndDT = strHorizonStartEndDT+','+dtmlastProcessedDateTime;
        WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::doCreateLTPHorizon::LTP Job horizon start and end datetime:'+strHorizonStartEndDT);
        //lstHorizondate.add(dtmlastProcessedDateTime);
        if(datEndDate != NULL)
            intNoOfDays = datStartDate.daysBetween(datEndDate) + 1;
        
        List<Date> lstSchedHorizDates = new List<Date>(setSchedHorizDates);
        mapHorizonDetails.put(strHorizonStartEndDT,lstSchedHorizDates);
        return mapHorizonDetails;
    }

    //Get List of  SF Event for Tech within the time range
    public static Map<Id, Event> getMapNonWOSFEventforTech(set<string> lstOwnerID,DateTime inputStartTime, DateTime inputEndTime)
    {
        date inputStartdate = inputStartTime.dateGMT();
        date inputEnddate = inputEndTime.dateGMT();
        datetime inputStartdatetime = Datetime.newInstanceGmt(inputStartTime.dateGMT(),Time.newInstance(0, 0, 0, 0));
        WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::getMapNonWOSFEventforTech::LTP Job horizon start,end date and start dateime:'+inputStartdate+' | '+inputEnddate+' | '+inputStartdatetime);
        Map<Id, Event> tempEvents = new Map<Id, Event>([Select Id, WhatId,OwnerId from Event where (OwnerId in:lstOwnerID) AND (SVMXC__Service_Duration__c > 0) AND (WhatId = NULL) AND ((StartDateTime <= :inputEndTime and EndDateTime >= :inputStartTime)OR (ActivityDate <= :inputEnddate and EndDateTime >= :inputStartdatetime AND IsAllDayEvent = true ) OR(ActivityDate = :inputStartdate AND IsAllDayEvent = true))]);
        return tempEvents;
    }
    
    //Get List of  SVMX Event for Tech within the time range inputStartTime and inputEndtdate
    public static Map<Id, SVMXC__SVMX_Event__c> getMapNonWOSVMXEventforTech(set<String> lstTechID,DateTime inputStartTime, DateTime inputEndTime)
    {
        date inputStartdate = inputStartTime.dateGMT();
        date inputEnddate = inputEndTime.dateGMT();
        datetime inputStartdatetime = Datetime.newInstanceGmt(inputStartTime.dateGMT(),Time.newInstance(0, 0, 0, 0));
        WSCH_AuditLogger.debug('WSCH_LTP_Initiate_Service::getMapNonWOSVMXEventforTech::LTP Job horizon start,end date and start dateime:'+inputStartdate+' | '+inputEnddate+' | '+inputStartdatetime);
        Map<Id, SVMXC__SVMX_Event__c> tempEvents = new Map<Id, SVMXC__SVMX_Event__c>([Select Id, Name,SVMXC__Technician__c from SVMXC__SVMX_Event__c where (SVMXC__Technician__c in:lstTechID) AND (SVMXC__Service_Order__c = null) AND ((SVMXC__StartDateTime__c <= :inputEndTime and SVMXC__EndDateTime__c >= :inputStartTime)OR (SVMXC__ActivityDate__c <= :inputEnddate and SVMXC__EndDateTime__c >= :inputStartdatetime AND SVMXC__IsAllDayEvent__c = true) OR(SVMXC__StartDateTime__c = :inputStartdatetime AND SVMXC__IsAllDayEvent__c = true))]); 
        return tempEvents;
    }
    
        
}