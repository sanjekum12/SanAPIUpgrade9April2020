/*
A concrete OptiMaxECO related implementation class for the IRealTimeOptimizer.
This class encapsulates all the logic of invoking ECO webservices related to real time optimization such as InitiJob,
ManageWorkOrders etc. In addition to invoking the webservices, it is the responsibility of this class to perform
the data transformations from input to webservice request and webservice response to required output format using
data mappers.
*/

public class WSCH_Provider_ECO_SchedulingService implements WSCH_IRealTimeOptimizer {
    
    public WSCH_WorkOrderResponse manageWorkOrders(List<SVMXC__Service_Order__c> workOrders) {
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders():strOldWO..'+WSCH_TriggerHandler.strOldWO);
        if(workOrders == null || workOrders.size() == 0){
            WSCH_AuditLogger.warn('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::Invalid input.There are no work orders to be managed');
            WSCH_AuditLogger.rca('Invalid input.There are no work orders to be managed');
            throw new WSCH_EXCEPTION('Invalid input. There is no work orders to be managed');
        }
        
        Map<Id,List<SVMXC__Service_Order__c>> mapTerritoryIdWOs= new Map<Id,List<SVMXC__Service_Order__c>>();
        Map<Id,List<SVMXC__Service_Order__c>> mapInitJobWOs = new Map<Id, List<SVMXC__Service_Order__c>>();
        Map<Id,List<SVMXC__Service_Order__c>> mapManageJobWos = new Map<Id, List<SVMXC__Service_Order__c>>();
        Map<Id,List<SVMXC__SVMX_Jobs__c>> mapTeritoryJobs = new Map<Id, List<SVMXC__SVMX_Jobs__c>>();
        List<SVMXC__Service_Order__c> lstValidWOs = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> lstErrorWOs = new List<SVMXC__Service_Order__c>();
        List<String> workOrderNames = new List<String>();
        List<String> errorWOOrderNames = new List<String>();
        
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::start, No of Queries used in this transaction so far: ' + Limits.getQueries());
        WSCH_AuditLogger.logGovernerLimits('Before Invoke InitJob or ManageJob');
        
        WSCH_WorkOrderResponse workOrderResponse = new WSCH_WorkOrderResponse();
        try{
            
            //set optimax status, retry count and other optimization related fields 
            //setWorkOrderStatus(workOrders,WSCH_ECO_Constants.STATUS_OPT_PENDING,null);
            
            //validate work orders service duration,zip
            //remove the invalid work orders for callout and update the error details on the work orders
            for(SVMXC__Service_Order__c wo : workOrders){
                if(isWorkOrderValid(wo)){
                    lstValidWOs.add(wo);
                    workOrderNames.add(wo.name);
                    if(!mapTerritoryIdWOs.containsKey(wo.SVMXC__Primary_Territory__c))
                        mapTerritoryIdWOs.put(wo.SVMXC__Primary_Territory__c, new List<SVMXC__Service_Order__c>());
                        
                    mapTerritoryIdWOs.get(wo.SVMXC__Primary_Territory__c).add(wo);
                }else{
                    //String errorText = 'Work Order Zip/Service Duration is null or QTL status is Disallow.';
                    String errorText = 'Either work Order (complete address or zip/country) or Service Duration is null or QTL status is Disallow.';
                    WSCH_CommonUtils.setOptimizerErrorText(wo, errorText);
                    wo.SVMXC__OptiMax_Status__c = WSCH_ECO_Constants.STATUS_OPT_ERROR;
                    lstErrorWOs.add(wo);
                    errorWOOrderNames.add(wo.name);
                }
                
                // Update retry count
                if(null == wo.SVMXC__Scheduling_Retry_Count__c || wo.SVMXC__Scheduling_Retry_Count__c == 0) {
                    wo.SVMXC__Scheduling_Retry_Count__c = 1;
                } else {
                    wo.SVMXC__Scheduling_Retry_Count__c = wo.SVMXC__Scheduling_Retry_Count__c + 1;
                }
            }
            
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::Valid WOs : ' + lstValidWOs.size());
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::Error WOs : ' + lstErrorWOs.size());
            

           
            //create territory object map for data preparation
            Map<Id, SVMXC__Territory__c> mapAllTeritories = getTerritoriesMap(lstValidWOs);
            
            //mapTeritoryWOs = getTerritoryWOsMap(lstValidWOs);
            Set<Id> setTerritoryId = mapTerritoryIdWOs.keyset();
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::mapTerritoryIdWOs : ' + mapTerritoryIdWOs);
            
            //query the svmx jobs records for territoryId
            list<SVMXC__SVMX_Jobs__c> lstSVMXJob = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c,SVMXC__Type__c from SVMXC__SVMX_Jobs__c where SVMXC__Territory__c In :setTerritoryId and SVMXC__Type__c = 'ECO' and SVMXC__OptiMax_Message__c !='IDLE'];   //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::lstSVMXJob : ' + lstSVMXJob);          
            
            mapTeritoryJobs = getTerritoryJobsMap(lstSVMXJob);
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::mapTeritoryJobs : ' + mapTeritoryJobs);
            //WSCH_AuditLogger.rca('The Error Workorder which are not sent to the server for scheduling ' + errorWOOrderNames);
            //WSCH_AuditLogger.rca('The Workorders to be sent to the server for scheduling ' + workOrderNames);
            //need to make the decision whether we need to make initJob call or other.      
            for(Id territoryId : mapTerritoryIdWOs.keyset()){
                if(!mapTeritoryJobs.containsKey(territoryId)){
                    mapInitJobWOs.put(territoryId, mapTerritoryIdWOs.get(territoryId));
                }else{
                    mapManageJobWos.put(territoryId, mapTerritoryIdWOs.get(territoryId));
                }
            }
            
            
            
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::mapInitJobWOs : ' + mapInitJobWOs);
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::mapManageJobWos : ' + mapManageJobWos);
            
            if(mapInitJobWOs != null && mapInitJobWOs.size() > 0){
                for(Id territoryId :mapInitJobWOs.keyset()){
                    WSCH_AuditLogger.rca('Invoking the Init Job for the teritory'+mapAllTeritories.get(territoryId));
                    initJob(mapAllTeritories.get(territoryId),mapInitJobWOs.get(territoryId));
                }
            }
            
            if(mapManageJobWos != null && mapManageJobWos.size() > 0){
                for(Id territoryId :mapManageJobWos.keyset()){
                    manageJob(mapAllTeritories.get(territoryId),mapManageJobWos.get(territoryId));
                }               
            }
            workOrderResponse.getLstWorkOrder().addAll(lstValidWOs);
            workOrderResponse.getLstWorkOrder().addAll(lstErrorWOs);
        } catch (Exception ex) {
            String exceptionMsg = 'WSCH_Provider_ECO_SchedulingService :: manageWorkOrders() :: ';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            throw new WSCH_EXCEPTION(exceptionMsg+ex.getStackTraceString());
            
        } 
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders()::end, No of Queries used in this transaction so far: ' + Limits.getQueries());
        WSCH_AuditLogger.logGovernerLimits('After Invoke InitJob or ManageJob');
        return workOrderResponse;
    }
    
    private void initJob(SVMXC__Territory__c objTerritory, List<SVMXC__Service_Order__c> lstWOs){
        //Invoking InitJob api call     
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJob():territory -'+objTerritory.Name +'-'+objTerritory.Id);
        WSCH_Provider_ECO_Stubs.InitJobRequest_WP request_x = WSCH_Provider_ECO_DataMapper.initJobRequest(objTerritory,lstWOs);
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJobRequest(): before process lstWOs..'+lstWOs);
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJob():request_x.workOrders..'+request_x.workOrders);
        List<WSCH_Provider_ECO_Stubs.WorkOrder_WP> lstWO_WPs = request_x.workOrders;
        String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
        String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_INTI_JOB_METHOD;
        if(lstWO_WPs != null && lstWO_WPs.size() > 0) {
            List<SVMXC__Service_Order__c> filteredWOList = new List<SVMXC__Service_Order__c>();
            List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
            Set<String> filteredWOSet = new Set<String>();
            for(integer i = 0; i < lstWO_WPs.size(); i++) {
                filteredWOSet.add(lstWO_WPs.get(i).workOrderId);
            }
            for(integer i = 0; i < lstWOs.size(); i++)  {
                if(filteredWOSet.add(lstWOs.get(i).name)) {
                   woList.add(lstWOs.get(i));
                } else {
                   filteredWOList.add(lstWOs.get(i));
                }
            }
            
            String requestJson=JSON.serialize(request_x); 
            WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,serviceName,methodName);

             
            if(response_x.status == '200'){
                setWorkOrderStatus(filteredWOList, WSCH_ECO_Constants.STATUS_OPT_INITIATED, response_x);
            //TODO create optimizer Transaction record for each technician events.
            } else {
                setWorkOrderStatus(filteredWOList, WSCH_ECO_Constants.STATUS_OPT_ERROR, response_x);
            }
            
            lstWOs = null;
            lstWOs = filteredWOList;
            if(woList != null && woList.size() > 0 ) {
                response_x = new WSCH_Provider_ECO_Stubs.Response_WP();
                response_x.status = 'Client Validation';  
                response_x.message = 'Skipping this work order as booking window is outside scheduling horizon/could not find the RTO Dispatch Process';
                setWorkOrderStatus(woList, WSCH_ECO_Constants.STATUS_OPT_SKIPPED, response_x);
                WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJob():response_x2..'+response_x);
                for(integer i = 0; i < woList.size(); i++)  {
                    lstWOs.add(woList.get(i));
                }
            }
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJob(): after process lstWOs..'+lstWOs);
        } else {
            WSCH_Provider_ECO_Stubs.Response_WP response_x = new WSCH_Provider_ECO_Stubs.Response_WP();
            response_x.status = 'Client Validation';  
            response_x.message = 'Skipping this work order as booking window is outside scheduling horizon/could not find the RTO Dispatch Process';
            setWorkOrderStatus(lstWOs, WSCH_ECO_Constants.STATUS_OPT_SKIPPED, response_x);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::initJob():response_x..'+response_x);
            WSCH_AuditLogger.rca('Respons of the InitJob Call \n'+response_x);
        }
        WSCH_AuditLogger.rca('Init Job Call is Successfully made, a push request will be sent by server shortly');
    }
    
    private void manageJob(SVMXC__Territory__c objTerritory, List<SVMXC__Service_Order__c> lstWOs){
        //Invoking ManageJob api call  
        WSCH_AuditLogger.rca('Invoking the ManageJob API Call for Teritory'+objTerritory.Name +'; Id : '+objTerritory.Id);
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageJob():territory -'+objTerritory.Name +'-'+objTerritory.Id);
        WSCH_Provider_ECO_Stubs.ManageWorkOrderRequest_WP request_x = WSCH_Provider_ECO_DataMapper.manageJobRequest(objTerritory,lstWOs); 
        List<WSCH_Provider_ECO_Stubs.WorkOrder_WP> lstWO_WPs = request_x.workOrders;
        if(lstWO_WPs != null && lstWO_WPs.size() > 0) {
            List<SVMXC__Service_Order__c> filteredWOList = new List<SVMXC__Service_Order__c>();
            List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
            Set<String> filteredWOSet = new Set<String>();
            for(integer i = 0; i < lstWO_WPs.size(); i++) {
                filteredWOSet.add(lstWO_WPs.get(i).workOrderId);
            }
            for(integer i = 0; i < lstWOs.size(); i++)  {
                if(filteredWOSet.add(lstWOs.get(i).name)) {
                   woList.add(lstWOs.get(i));
                } else {
                   filteredWOList.add(lstWOs.get(i));
                }
            }
            
            String requestJson=JSON.serialize(request_x); 
            String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
            String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_MANAGE_WO_METHOD;
            WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,serviceName,methodName);
            if(response_x.status == '200'){
                setWorkOrderStatus(filteredWOList, WSCH_ECO_Constants.STATUS_OPT_TENTATIVE, response_x);
            } else{
                setWorkOrderStatus(filteredWOList, WSCH_ECO_Constants.STATUS_OPT_ERROR, response_x);
            }
            
            lstWOs = null;
            lstWOs = filteredWOList;
            if(woList != null && woList.size() > 0 ) {
                response_x = new WSCH_Provider_ECO_Stubs.Response_WP();
                response_x.status = 'Client Validation';  
                response_x.message = 'Skipping this work order as booking window is outside scheduling horizon/could not find the RTO Dispatch Process';
                setWorkOrderStatus(woList, WSCH_ECO_Constants.STATUS_OPT_SKIPPED, response_x);
                WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders():response_x2..'+response_x);
                for(integer i = 0; i < woList.size(); i++)  {
                    lstWOs.add(woList.get(i));
                }
            }
        } /*else {
            WSCH_Provider_ECO_Stubs.Response_WP response_x = new WSCH_Provider_ECO_Stubs.Response_WP();
            response_x.status = 'Client Validation';  
            response_x.message = 'Skipping this work order as booking window is outside scheduling horizon/could not find the RTO Dispatch Process';
            setWorkOrderStatus(lstWOs, WSCH_ECO_Constants.STATUS_OPT_SKIPPED, response_x);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders():response_x..'+response_x);
            WSCH_AuditLogger.rca('Respons of the ManageJob Call \n'+response_x);
        }
        WSCH_AuditLogger.rca('ManageJob Call is Successfully made, a push request will be sent by server shortly');*/
            
    }    
    
    public boolean isWorkOrderValid(SVMXC__Service_Order__c workOrder) {
        boolean isValid=true;
        //if(workOrder.SVMXC__Service_Duration__c == null || workOrder.SVMXC__Zip__c == null || workOrder.SVMXC__Primary_Territory__c == null || workOrder.SVMXC__QTL_Status__c == 'No Qualified Technicians (Disallow)'){
        if(workOrder.SVMXC__Latitude__c == NULL && workOrder.SVMXC__Longitude__c == NULL){
            if((workOrder.SVMXC__Service_Duration__c == null || workOrder.SVMXC__Primary_Territory__c == null || workOrder.SVMXC__QTL_Status__c == 'No Qualified Technicians (Disallow)')||((workOrder.SVMXC__Zip__c == null || workOrder.SVMXC__Country__c == null))){
                isValid=false;
            }
        }
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::isWorkOrderValid ' + isValid);
        return isValid;
    } 
       
    public Map<Id, SVMXC__Territory__c> getTerritoriesMap(List<SVMXC__Service_Order__c> listWOs){
        set<Id> setTerritoryIds = new set<Id>();
        for(SVMXC__Service_Order__c wo : listWOs){
            setTerritoryIds.add(wo.SVMXC__Primary_Territory__c);
        }
        Map<Id, SVMXC__Territory__c> mapTerritory = new Map<Id, SVMXC__Territory__c>([Select Id, Name,SVMXC__Territory_s_Business_Hours__c, SVMXC__Territory_s_Business_Hours__r.TimeZoneSidKey, SVMXC__Break_Hours__c, SVMXC__Average_Driving_Time__c, SVMXC__Per_Mile_Cost__c,
                                SVMXC__Max_Distance__c, SVMXC__Average_Speed__c, SVMXC__Fixed_Cost__c, SVMXC__Per_hour_Cost__c, SVMXC__Mode_Of_Travel__c
                                from SVMXC__Territory__c
                                where Id in :setTerritoryIds]);  
        return mapTerritory;
    }
        
    public Map<Id,List<SVMXC__Service_Order__c>> getTerritoryWOsMap(List<SVMXC__Service_Order__c> listWOs){
        Map<Id,List<SVMXC__Service_Order__c>> mapTerritoryIdWOs= new Map<Id,List<SVMXC__Service_Order__c>>();
        for(SVMXC__Service_Order__c wo : listWOs){
            if(!mapTerritoryIdWOs.containsKey(wo.SVMXC__Primary_Territory__c))
                mapTerritoryIdWOs.put(wo.SVMXC__Primary_Territory__c, new List<SVMXC__Service_Order__c>());
                mapTerritoryIdWOs.get(wo.SVMXC__Primary_Territory__c).add(wo);
        }
        return mapTerritoryIdWOs;
    }
    
    public Map<Id,List<SVMXC__SVMX_Jobs__c>> getTerritoryJobsMap(List<SVMXC__SVMX_Jobs__c> listJobs){
        Map<Id,List<SVMXC__SVMX_Jobs__c>> mapTerritoryIdJobs= new Map<Id,List<SVMXC__SVMX_Jobs__c>>();
        for(SVMXC__SVMX_Jobs__c objJob : listJobs){
            if(!mapTerritoryIdJobs.containsKey(objJob.SVMXC__Territory__c))
                mapTerritoryIdJobs.put(objJob.SVMXC__Territory__c, new List<SVMXC__SVMX_Jobs__c>());
                mapTerritoryIdJobs.get(objJob.SVMXC__Territory__c).add(objJob);
        }
        return mapTerritoryIdJobs;      
    }
    
    public void setWorkOrderStatus(List<SVMXC__Service_Order__c> listWOs, String status, WSCH_Provider_ECO_Stubs.Response_WP returnCode){
        for(SVMXC__Service_Order__c workOrder : listWOs){
            if ('CHANGE_CANCEL_WO'.equalsIgnoreCase(workOrder.SVMXC__Scheduling_Change_Token__c)) {
                workOrder.SVMXC__OptiMax_Status__c = WSCH_ECO_Constants.STATUS_OPT_COMPLETED;
            }else {
                workOrder.SVMXC__OptiMax_Status__c = status;
            }
            //Identifying the work order assigned through DC with dispatch process and promised appointment slots are null.
            //Set "Assigned by DC" to promised appointment slot field to identify the RTO work order. 
            if(workOrder.SVMXC__Dispatch_Process__c == null 
            && workOrder.SVMXC__Appointment_Promised_Time_Slot__c == null){
            //&& 'CHANGE_JOB_FIXED'.equalsIgnoreCase(workOrder.SVMXC__Scheduling_Change_Token__c)){
                WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageJob::setWorkOrderStatus():set Assigned by DC to Appointment Promised slot field. ');
                workOrder.SVMXC__Appointment_Promised_Time_Slot__c = 'Assigned by DC';
                WSCH_AuditLogger.rca('the field SVMXC__Appointment_Promised_Time_Slot__c of workorder is set to Assigned by DC');
            }
            String errorText = 'Return Code:' + returnCode.status + ' | Return Msg:' + returnCode.message;
            WSCH_CommonUtils.setOptimizerErrorText(workOrder, errorText);         
        
        }
    }
    
  
    public WSCH_Provider_SP_StubsV91.BookDependencyGroupResponse manageDependencyGroup(String multiJobId, List<Service_Order_Dependency__c> serviceOrderList) {
        return null;
    }
    
    public WSCH_WorkOrderUpdateResponse getWorkOrderUpdates(SVMXC__Territory__c territory){
        return null;
    }
    
    public WSCH_AppointmentsResponse getAvailableAppointments(SVMXC__Service_Order__c workOrder , WSCH_ApptParam apptParamObj, Integer size, Integer currentIndex){
        // Update retry count
        /*if(null == workOrder.SVMXC__Scheduling_Retry_Count__c || workOrder.SVMXC__Scheduling_Retry_Count__c == 0) {
            workOrder.SVMXC__Scheduling_Retry_Count__c = 1;
        } else {
            workOrder.SVMXC__Scheduling_Retry_Count__c = workOrder.SVMXC__Scheduling_Retry_Count__c + 1;
        }*/
        try{
            List<SVMXC__Service_Order__c> lstWOs = new List<SVMXC__Service_Order__c>();
            lstWOs.add(workOrder);
            
            Map<Id, SVMXC__Territory__c> mapAllTeritories = getTerritoriesMap(lstWOs);
            SVMXC__Territory__c woTerritory = mapAllTeritories.get(workOrder.SVMXC__Primary_Territory__c);
            WSCH_AppointmentsResponse techSlotResponse = new WSCH_AppointmentsResponse();
            List<SVMXC__Service_Order__c> lstApptWo = new List<SVMXC__Service_Order__c>();
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::getAvailableAppointments():apptParamObj.costOrDates => '+apptParamObj.costOrDates +'- apptParamObj.startDateTime =>'+apptParamObj.startDateTime + '- apptParamObj.endDateTime =>'+apptParamObj.endDateTime);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::getAvailableAppointments():territory -'+woTerritory.Name +'-'+woTerritory.Id);
            WSCH_Provider_ECO_Stubs.AppointmentOfferRequest_WP request_x = WSCH_Provider_ECO_DataMapper.manageOfferAppointmentRequest(woTerritory,workOrder,apptParamObj);
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::getAvailableAppointments():request_x====>'+request_x); 
            String requestJson=JSON.serialize(request_x);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::getAvailableAppointments():requestJson..'+requestJson);
            if(request_x != null && request_x.workOrder == null) {
                WSCH_AuditLogger.rca('Unfortunately, there is no appointment windows for non working day. Please contact administrator.');
                techSlotResponse.statusMessage = 'Unfortunately, there is no appointment windows for non working day. Please contact administrator.';
                techSlotResponse.statusCode = 7;
                return techSlotResponse;
            }
            //String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
            String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH_VERSION_2;
            String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_GET_APPOINTMENT_OFFERS_METHOD;
            WSCH_AuditLogger.rca('Invokig the get Appointments API to server ');
            WSCH_Provider_ECO_Stubs.AppointmentOfferResponse_WP apptOfferResponse = WSCH_Provider_ECO_Callout_Helper.apptOfferCallOut(requestJson,serviceName,methodName);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::getAvailableAppointments():apptOfferResponse..'+apptOfferResponse);
         
            
            if(apptOfferResponse != null && apptOfferResponse.responseWP.status == '200') {
                //map the response in datamapper         
                WSCH_AuditLogger.rca('Response of Get Appointments Call :-   '+apptOfferResponse.responseWP.status);       
                WSCH_Provider_ECO_DataMapper.manageOfferAppointmentResponse(apptOfferResponse, techSlotResponse, apptParamObj);
                return techSlotResponse;
            } else {            
                if(apptOfferResponse.responseWP.status != null) {
                    apptOfferResponse.statusCode = Integer.valueOf(apptOfferResponse.responseWP.status);
                    apptOfferResponse.errorMessage = apptOfferResponse.responseWP.message;
                }
                WSCH_Provider_ECO_DataMapper.manageOfferAppointmentResponse(apptOfferResponse, techSlotResponse, apptParamObj); 
                return techSlotResponse;
            }
        } catch(Exception ex) {
            WSCH_AuditLogger.error('WSCH_Provider_ECO_SchedulingService :: getAvailableAppointments() :: Line no: '+ ex.getLineNumber() + '\n' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            WSCH_AuditLogger.rca('WSCH_Provider_ECO_SchedulingService :: getAvailableAppointments() :: Line no: '+ ex.getLineNumber() + '\n' + ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            WSCH_AuditLogger.finish();
            throw new WSCH_Exception(ex.getMessage());
        }
        return null;
    }
    
    public WSCH_AppointmentsResponse bookAppointment(SVMXC__Service_Order__c workOrder, WSCH_Appointment slot){    
        WSCH_AppointmentsResponse techSlotResponse = new WSCH_AppointmentsResponse();
        try{
            List<SVMXC__Service_Order__c> lstWOs = new List<SVMXC__Service_Order__c>();
            lstWOs.add(workOrder);
            
            Map<Id, SVMXC__Territory__c> mapAllTeritories = getTerritoriesMap(lstWOs);
            SVMXC__Territory__c woTerritory = mapAllTeritories.get(workOrder.SVMXC__Primary_Territory__c);
            List<SVMXC__Service_Order__c> lstApptWo = new List<SVMXC__Service_Order__c>();
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::bookAppointment():territory -'+woTerritory.Name +'-'+woTerritory.Id);
            WSCH_Provider_ECO_Stubs.BookAppointmentRequest_WP request_x = WSCH_Provider_ECO_DataMapper.manageBookAppointmentRequest(woTerritory,workOrder,slot);
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::bookAppointment():request_x====>'+request_x); 
            String requestJson=JSON.serialize(request_x);
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::bookAppointment():requestJson..'+requestJson);
            //String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;            
            String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH_VERSION_2;
            String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_BOOK_APPOINTMENT_METHOD;
             WSCH_AuditLogger.rca('Invoking the BookAppointment for the teritory'+woTerritory.Name);
            WSCH_Provider_ECO_Stubs.BookAppointmentResponse_WP bookApptResponse = WSCH_Provider_ECO_Callout_Helper.bookApptCallOut(requestJson,serviceName,methodName);
            //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::bookAppointment():bookApptResponse..'+bookApptResponse);
            
            if(bookApptResponse.responseWP.status == '200'){
                 WSCH_AuditLogger.rca('The Book Appointment Call is succesful');
                if (bookApptResponse.statusCode == 0) {
                    WSCH_AuditLogger.rca('Setting the workorder status to OPT_TENTATIVE after book Appointment');
                    setWorkOrderStatus(lstWOs,WSCH_ECO_Constants.STATUS_OPT_TENTATIVE,bookApptResponse.responseWP);
                    WSCH_OptimizedSchedulingService.triggerExecuted = true;
                    WSCH_OptimizedSchedulingService.isCallOutExecuted = true;
                    workOrder.SVMXC__Appointment_Promised_Time_Slot__c = String.format(' {0}, {1}, {2}', new List<String>{slot.getStrStartDateTime(), slot.getStrEndDateTime(), slot.getSlotCategory()});
                    //when book an appointment for force fix work order reset the locked by dc flag.
                    if(workOrder.SVMXC__Locked_By_DC__c == true)
                        workOrder.SVMXC__Locked_By_DC__c = false;
                }
                WSCH_Provider_ECO_DataMapper.manageBookAppointmentResponse(bookApptResponse, techSlotResponse);
                
            }else{
                if(bookApptResponse.responseWP.status != null) {
                    bookApptResponse.statusCode = Integer.valueOf(bookApptResponse.responseWP.status);
                }
                WSCH_Provider_ECO_DataMapper.manageBookAppointmentResponse(bookApptResponse, techSlotResponse);
                setWorkOrderStatus(lstWOs,WSCH_ECO_Constants.STATUS_OPT_ERROR,bookApptResponse.responseWP);
            }
            WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders():response_x..'+bookApptResponse);
        } catch(Exception ex) {
            WSCH_AuditLogger.error('WSCH_Provider_ECO_SchedulingService :: bookAppointment() :: '+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            WSCH_AuditLogger.finish();
            throw new WSCH_Exception(ex.getMessage());
        } 
        return techSlotResponse;
    }
    
    public String getJobStatus(SVMXC__Service_Order__c workOrder) {
        return null;
    }
    
   public WSCH_NonWOEventResponse manageNonWorkOrderEvents(List<SVMXC__SVMX_Optimizer__c> optimizers){
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageNonWorkOrderEvents()'+optimizers.size());
        
        WSCH_Provider_ECO_Stubs.Response_WP response_x;
        WSCH_NonWOEventResponse response = new WSCH_NonWOEventResponse();
        List<SVMXC__SVMX_Optimizer__c> optListToUpdate = new List<SVMXC__SVMX_Optimizer__c>();
        WSCH_Provider_ECO_Stubs.ManageTechnicianEventRequest_WP manageEventRequest;
                
        Map<String,WSCH_Provider_ECO_Stubs.ManageTechnicianEventRequest_WP> requestMap = WSCH_Provider_ECO_DataMapper.createManageTechnicianEventRequest(optimizers);
        Map<String,SVMXC__SVMX_Jobs__c> terIdsAndJobsMap = WSCH_ECO_CommonUtils.getSVMXJobsByTerritories(new List<String>(requestMap.keySet()));
         
        for(String teritoryId : requestMap.keySet()){
            if(!terIdsAndJobsMap.containsKey(teritoryId)){
                 WSCH_AuditLogger.debug('initJob for this teritory is not invoked yet, cannot call manageEvents : WSCH_Provider_ECO_SchedulingService: '+teritoryId);  
                 WSCH_AuditLogger.rca('initJob for this teritory is not invoked yet, cannot call manageEvents : WSCH_Provider_ECO_SchedulingService: '+teritoryId); 
            }else{
                manageEventRequest = requestMap.get(teritoryId);
                if(manageEventRequest.technicianEvents.size() > 0) {
                    String requestJson=JSON.serialize(manageEventRequest);
                    String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
                    String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_MANAGE_EVENT_METHOD;
                    WSCH_AuditLogger.rca('Invoking Manage Non Workorder Events'); 
                    response_x = WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,serviceName,methodName);
                      
                    //response_x = WSCH_Provider_ECO_Callout_Helper.manageEvents(manageEventRequest); 
                    if(response_x.status == '200') {
                        WSCH_AuditLogger.rca('The requests to Manage Non Work order event is sent to the server'); 
                        optListToUpdate.addAll(saveNonWorkOrderEventOptimizers(manageEventRequest,optimizers,response_x));
                    }else{
                        optListToUpdate.addAll(saveNonWorkOrderEventOptimizers(manageEventRequest,optimizers,response_x));
                    }
                    WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageNonWorkOrderEvents():response_x..'+response_x);        
                }
            }
        }  
        response.setEvents(optListToUpdate);
        return response;
     }
    
    
    public List<SVMXC__SVMX_Optimizer__c> cancelWorkOrders(List<SVMXC__SVMX_Optimizer__c> workOrders) {
        if(workOrders == null || workOrders.size() == 0){
            WSCH_AuditLogger.warn('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::Invalid input.There are no work orders to be cancel');
            WSCH_AuditLogger.rca('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::Invalid input.There are no work orders to be cancel');
            throw new WSCH_EXCEPTION('Invalid input. There is no work orders to be cancel');
        }
        Map<String,List<String>> mapTerritoryIdWOName= new Map<String,List<String>>();
        Map<String,SVMXC__SVMX_Optimizer__c> mapWoNameOptimizer= new Map<String,SVMXC__SVMX_Optimizer__c>();
        Map<Id,List<SVMXC__SVMX_Jobs__c>> mapTeritoryJobs = new Map<Id, List<SVMXC__SVMX_Jobs__c>>();
        Map<Id,List<String>> mapCancelJobWos = new Map<Id, List<String>>();     
        for(SVMXC__SVMX_Optimizer__c optimizer :workOrders){
            String[] lstIds = optimizer.SVMXC__Optimizer_Connection_ID__c.split('_');
            if(!mapTerritoryIdWOName.containsKey(lstIds[1]))
                mapTerritoryIdWOName.put(lstIds[1], new List<String>());
                
            mapTerritoryIdWOName.get(lstIds[1]).add(optimizer.SVMXC__WhatId__c+'_'+lstIds[0]+'_'+lstIds[1]);
            mapWoNameOptimizer.put(optimizer.SVMXC__WhatId__c,optimizer);
            
        }
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::mapTerritoryIdWOs : ' + mapTerritoryIdWOName);
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::mapWoNameOptimizer : ' + mapWoNameOptimizer);
        Set<String> setTerritoryId = mapTerritoryIdWOName.keyset();
        
        //query the svmx jobs records for territoryId
        list<SVMXC__SVMX_Jobs__c> lstSVMXJob = [Select id, Name, SVMXC__OptiMax_Message__c, SVMXC__SVMX_Process__c, SVMXC__Territory__c,SVMXC__Start_Time__c,SVMXC__Age__c, SVMXC__Status__c, SVMXC__End_Time__c,SVMXC__Type__c from SVMXC__SVMX_Jobs__c where SVMXC__Territory__c In :setTerritoryId and SVMXC__Type__c = 'ECO' and SVMXC__OptiMax_Message__c !='IDLE'];
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::lstSVMXJob : ' + lstSVMXJob);          
        
        mapTeritoryJobs = getTerritoryJobsMap(lstSVMXJob);
        //WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::mapTeritoryJobs : ' + mapTeritoryJobs);
        
        //need to make the decision whether we need to make initJob call or other.      
        for(Id territoryId : mapTerritoryIdWOName.keyset()){
            if(!mapTeritoryJobs.containsKey(territoryId)){
                //initjob call
                WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::InitJob not invoked yet for this territory. So cancelJob not invoked. TerritoryId : ' + territoryId);
                WSCH_AuditLogger.rca('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::InitJob not invoked yet for this territory. So cancelJob not invoked. TerritoryId : ' + territoryId);
            }else{
                mapCancelJobWos.put(territoryId, mapTerritoryIdWOName.get(territoryId));
            }
        }
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelWorkOrders()::mapCancelJobWos : ' + mapCancelJobWos);
        WSCH_AuditLogger.rca('Invoking the Cancel WO Call');
        if(mapCancelJobWos != null && mapCancelJobWos.size() > 0){
            for(Id territoryId :mapCancelJobWos.keyset()){
                cancelJob(mapTerritoryIdWOName.get(territoryId),mapWoNameOptimizer);
            }
        }
        return workOrders;
    }
    
    public Boolean manageSchedulingResults(String strJobInfo) {
        
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrderResults():strJobInfo -'+strJobInfo);
        Boolean isCallSuccess = false;
        WSCH_Provider_ECO_Stubs.ManageWorkOrdersResultRequest_WP request_x = WSCH_Provider_ECO_DataMapper.manageWorkOrdersResultRequest(strJobInfo); 
        String requestJson=JSON.serialize(request_x); 
        String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
        String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_MANAGE_SCHD_RESULTS_METHOD;
        WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,serviceName,methodName);
        //WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.manageWorkOrders(request_x);
        if(response_x.status == '200'){
            isCallSuccess = true;
        }
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::manageWorkOrders():response_x..'+response_x);
        return isCallSuccess;
    }

    private void cancelJob(List<String> lstWOs, Map<String,SVMXC__SVMX_Optimizer__c> mapWoOptimizer){
        //Invoking manageWorkOrders api call  
        WSCH_Provider_ECO_Stubs.ManageWorkOrderRequest_WP request_x = WSCH_Provider_ECO_DataMapper.cancelJobRequest(lstWOs);
        String requestJson=JSON.serialize(request_x); 
        String serviceName = WSCH_Provider_ECO_Callout_Helper.ECO_SCHEDULING_SERVICE_PATH;
        String methodName = WSCH_Provider_ECO_Callout_Helper.ECO_MANAGE_WO_METHOD;
        WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.callOut(requestJson,serviceName,methodName);
        //WSCH_Provider_ECO_Stubs.Response_WP response_x = WSCH_Provider_ECO_Callout_Helper.manageWorkOrders(request_x);
        if(response_x.status == '200'){
             WSCH_AuditLogger.debug('Request to cancel workorder is sent to the server');
             WSCH_AuditLogger.debug('Updating the Work Order status to OPT_CIMPLETED');
            setOptimizerStatus(lstWOs,mapWoOptimizer,WSCH_ECO_Constants.STATUS_OPT_COMPLETED,response_x);
        }else{
            setOptimizerStatus(lstWOs,mapWoOptimizer,WSCH_ECO_Constants.STATUS_OPT_ERROR,response_x);
        }
        WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::cancelJob():response_x..'+response_x);
    }   
    
     private List<SVMXC__SVMX_Optimizer__c> saveNonWorkOrderEventOptimizers(WSCH_Provider_ECO_Stubs.ManageTechnicianEventRequest_WP manageEventRequest, 
                List<SVMXC__SVMX_Optimizer__c> optimizers,WSCH_Provider_ECO_Stubs.Response_WP response){
         WSCH_AuditLogger.debug('saveNonWorkOrderEventOptimizers status :- '+ response);
         WSCH_AuditLogger.rca('Save the OPtimizer Object');
         Map<String,SVMXC__SVMX_Optimizer__c> optimizerWhatTypes = WSCH_ECO_CommonUtils.getEventIdAndOptimizers(optimizers);
          
         SVMXC__SVMX_Optimizer__c optToUpdate;
         List<SVMXC__SVMX_Optimizer__c> updateList = new List<SVMXC__SVMX_Optimizer__c>();
         
         List<WSCH_Provider_ECO_Stubs.TechniciansEvent_WP>  technicianEvents = manageEventRequest.technicianEvents;
         WSCH_AuditLogger.debug('WSCH_Provider_ECO_SchedulingService::saveNonWorkOrderEventOptimizers:technicianEvents.size(): '+technicianEvents.size());
          
         String eventId;
         for(WSCH_Provider_ECO_Stubs.TechniciansEvent_WP techEvent: technicianEvents){
             //WSCH_AuditLogger.debug('saveNonWorkOrderEventOptimizers  techEvent '+techEvent );
             eventId = techEvent.eventId.split('_')[1];
             //WSCH_AuditLogger.debug('Split Evnt Id'+eventId);
             if(optimizerWhatTypes.containsKey(eventId)){
                 //WSCH_AuditLogger.debug('optimizerWhatTypes has the event');
                 optToUpdate = optimizerWhatTypes.get(eventId);
             
                 if(response.status == '200'){
                     optToUpdate.SVMXC__Optimizer_Status__c = WSCH_ECO_Constants.ECO_OPT_COMPLETE;
                 }else{
                     optToUpdate.SVMXC__Optimizer_Status__c = WSCH_ECO_Constants.ECO_OPT_ERROR;
                 }
                 optToUpdate.SVMXC__Optimizer_Error_Text__c ='Return Code:' + response.status + ' | Return Msg:' + response.message;
              
                 // Update retry count
                 if(null == optToUpdate.SVMXC__Optimizer_Retry_Count__c) {
                     optToUpdate.SVMXC__Optimizer_Retry_Count__c = 1;
                 } else {
                     optToUpdate.SVMXC__Optimizer_Retry_Count__c = optToUpdate.SVMXC__Optimizer_Retry_Count__c + 1;
                 }
             }
             updateList.add(optToUpdate);
         }
         return updateList;
    }
  
    public void setOptimizerStatus(List<String> lstWoNameDPTerritory, Map<String,SVMXC__SVMX_Optimizer__c> mapWoNameOptimizerObj, String status,WSCH_Provider_ECO_Stubs.Response_WP returnCode){
        for(String strWoNameDPTerritory :lstWoNameDPTerritory){
            String[] lstIds = strWoNameDPTerritory.split('_');
            SVMXC__SVMX_Optimizer__c optTrnObj = mapWoNameOptimizerObj.get(lstIds[0]);
            optTrnObj.SVMXC__Optimizer_Status__c = status;
            optTrnObj.SVMXC__Optimizer_Error_Text__c = 'Return Code:' + returnCode.status + ' | Return Msg:' + returnCode.message;
            
            // Update retry count
            if(null == optTrnObj.SVMXC__Optimizer_Retry_Count__c) {
                optTrnObj.SVMXC__Optimizer_Retry_Count__c = 1;
            } else {
                optTrnObj.SVMXC__Optimizer_Retry_Count__c = optTrnObj.SVMXC__Optimizer_Retry_Count__c + 1;
            }
        }
    }
    
}