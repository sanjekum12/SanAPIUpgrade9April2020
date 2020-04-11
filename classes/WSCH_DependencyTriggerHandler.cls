public with sharing class WSCH_DependencyTriggerHandler{
    public static Boolean SyncFlag;
    public static List<SVMXC__Service_Order__c> relatedWorkOrders = new List<SVMXC__Service_Order__c>();
    public static List<String> dependentWorkOrderIds = new List<String>(); 
    
    public static Boolean getDependencySetting(){
        Boolean dependencySetting = false, boolGBL007 = false;
        try{
            String strGBL007 = WSCH_CommonUtils.getSettingValue('GLOB001', 'GBL007');
            boolGBL007 = Boolean.valueOf(strGBL007);
            dependencySetting = Boolean.valueOf(WSCH_CommonUtils.getSettingValue('DCON004', 'SET014'));
        }catch(Exception ex){
            String exceptionMsg = 'WSCH_DependencyTriggerHandler :: getDependencySetting() :: ';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
            dependencySetting = false;
            boolGBL007 = false;
        }
        if(Test.isRunningTest()){
            return true;
        }
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler::getDependencySetting:: Dispatch Optimization:'+boolGBL007+'   Dependency Setting:'+dependencySetting);
        return (dependencySetting && boolGBL007) ;
        //return true;
    }
    
    
    //check if the optimizer setting is enabled in after insert trigger context.
    public static void doQualify(String dependencyGroupId, List<Service_Order_Dependency__c> dependencyList){   
        if(!Test.isRunningTest()){  
            if(!WSCH_CommonUtils.isOptimizerEnabled()) {
                return;
            }
        }
        
        WSCH_TriggerHandler.updateWorkOrders(dependentWorkOrderIds, WSCH_Constants.STATUS_OPT_PENDING, 'CREATE_DEPENDENCY_WO');
        WSCH_DependencyTriggerHandler.getBookDependencyRequestResponse(dependencyGroupId);
        //WSCH_OptimizedSchedulingService.manageDependencyGroup(dependencyGroupId, dependencyList);
    }
    //Method to identify and Optimize Dependency Group Booking API based on the work order field changes
    public static void doIdentifyDependencyGroupAPI(List<Service_Order_Dependency__c> newDependencyList,List<Service_Order_Dependency__c> oldDependencyList) {
        if(!Test.isRunningTest()){
            if(!WSCH_CommonUtils.isOptimizerEnabled()) {
                return;
            }
        }
        Set<String> qualifiedDependencyGroups = new Set<String>();
        for(Integer i=0; i<newDependencyList.size(); i++){
            if(markChangeToken(newDependencyList[i],oldDependencyList[i])){
                qualifiedDependencyGroups.add(newDependencyList[i].SVMXC__Dependency_Group__c);
            }
            else if(newDependencyList.size() != oldDependencyList.size()){
                qualifiedDependencyGroups.add(newDependencyList[i].SVMXC__Dependency_Group__c);
            }
        }
        if(qualifiedDependencyGroups != null){
            for (String multiJobId: qualifiedDependencyGroups){
                WSCH_DependencyTriggerHandler.getBookDependencyRequestResponse(multiJobId);
            }
        }
    }
    
    public static void deleteWODependencyFromGroup(List<Service_Order_Dependency__c> lstOfDeletedWODependencyRecord) {
        List<String> woIds = new List<String>();
        //fetch the WO ids from the dependency records which has been deleted
        if(lstOfDeletedWODependencyRecord != null && lstOfDeletedWODependencyRecord.size() > 0) {
            for(Service_Order_Dependency__c eachWODependency : lstOfDeletedWODependencyRecord) {
                woIds.add(eachWODependency.SVMXC__Primary_Work_Order__c);
                woIds.add(eachWODependency.SVMXC__Secondary_Work_Order__c);
            }
        }
        //query all the WOs whose Ids were retrieved above
        List<SVMXC__Service_Order__c> woList = WSCH_CommonUtils.fetchWorkOrders(woIds);
        List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
        WSCH_AuditLogger.debug('woList-->'+woList);
        
        //iterate all the above retrieved WOs and nullify the Dependency Group Id lookup
        if(woList != null && woList.size() > 0) {
            for(SVMXC__Service_Order__c eachWO : woList) {
                eachWO.SVMXC__Dependency_Group__c = null;
                wosToUpdate.add(eachWO);
            }
        }
        
        if(wosToUpdate.size() > 0) {
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( wosToUpdate, COMM_SecurityUtils.Access.Upsertable) ) {		//SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    upsert wosToUpdate; 
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.label.COMM001_TAG142));
                return;
            }
        }
        WSCH_AuditLogger.finish();
    }
    
    //Method to identify and Optimize Dependency Group Booking API based on the work order field changes
    public static List<SVMXC__Service_Order_Dependency__c> getUpdatedDependencyGroupsForBatch(List<Service_Order_Dependency__c> newDependencyList,List<Service_Order_Dependency__c> oldDependencyList) {
        if(!Test.isRunningTest()){
            if(!WSCH_CommonUtils.isOptimizerEnabled()) {
                return null;
            }
        }
        
        List<SVMXC__Service_Order_Dependency__c>  qualifiedDependencyGroups = new List<SVMXC__Service_Order_Dependency__c>();
        for(Integer i=0; i<newDependencyList.size(); i++){
            if(markChangeToken(newDependencyList[i],oldDependencyList[i])){
                qualifiedDependencyGroups.add(newDependencyList[i]);
            }
            else if(newDependencyList.size() != oldDependencyList.size()){
                qualifiedDependencyGroups.add(newDependencyList[i]);
            }
        }
        return qualifiedDependencyGroups;
    }
    
    /*public static void doQualifyInsertDependencyForBatch(List<Service_Order_Dependency__c> newDependencyList, List<SVMXC__Service_Order__c> woList) {
        Set<SVMXC__Service_Order__c> dependencyGroupWoSet = new Set<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c WO: woList){
            for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: newDependencyList){
                if(WO.Id == groupDependencyRecords.SVMXC__Primary_Work_Order__c || WO.Id == groupDependencyRecords.SVMXC__Secondary_Work_Order__c) {
                    WO.SVMXC__Dependency_Group__c = groupDependencyRecords.SVMXC__Dependency_Group__c;
                    //checking if the WO is already present to avoid duplicate. This WO may already be part of this 
                    //list as it could have been a Secondary WO from a previous relation definition
                    if(!dependencyGroupWoSet.contains(WO)) {
                        dependencyGroupWoSet.add(WO);
                    }
                }
            }
            /*WO.SVMXC__Dependency_Group__c = Trigger.new[0].SVMXC__Dependency_Group__c;
            dependencyGroupWoList.add(WO);
        }
        
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependencyForBatch: dependencyGroupWoSet - ' + dependencyGroupWoSet);
        List<SVMXC__Service_Order__c> lstWOsToUpdate;
        if(dependencyGroupWoSet.size() > 0) {
            lstWOsToUpdate = new List<SVMXC__Service_Order__c>(dependencyGroupWoSet);
            update lstWOsToUpdate;
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependencyForBatch:Updated the WO with the groupID');
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependencyForBatch:lstWOsToUpdate.size() - ' + lstWOsToUpdate.size());
        }
        WSCH_AuditLogger.finish();
    }*/

    //Method to update the workorders with the dependency groupID on the WorkOrders when creating Work Order Dependency objects from SFM
    public static void doQualifyInsertDependency(List<Service_Order_Dependency__c> newDependencyList, List<SVMXC__Service_Order__c> woList) {
        Set<SVMXC__Service_Order__c> dependencyGroupWoSet = new Set<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c WO: woList){
            for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: newDependencyList){
                if(WO.Id == groupDependencyRecords.SVMXC__Primary_Work_Order__c || WO.Id == groupDependencyRecords.SVMXC__Secondary_Work_Order__c) {
                    WO.SVMXC__Dependency_Group__c = groupDependencyRecords.SVMXC__Dependency_Group__c;
                    //checking if the WO is already present to avoid duplicate. This WO may already be part of this 
                    //list as it could have been a Secondary WO from a previous relation definition
                    if(!dependencyGroupWoSet.contains(WO)) {
                        dependencyGroupWoSet.add(WO);
                    }
                }
            }
            /*WO.SVMXC__Dependency_Group__c = Trigger.new[0].SVMXC__Dependency_Group__c;
            dependencyGroupWoList.add(WO);*/
        }
        
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependency: dependencyGroupWoSet - ' + dependencyGroupWoSet);
        List<SVMXC__Service_Order__c> lstWOsToUpdate;
        if(dependencyGroupWoSet.size() > 0) {
            lstWOsToUpdate = new List<SVMXC__Service_Order__c>(dependencyGroupWoSet);
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( lstWOsToUpdate, COMM_SecurityUtils.Access.Updateable) ) {		//SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    update lstWOsToUpdate;
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.label.COMM001_TAG142));
                return;
            }
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependency:Updated the WO with the groupID');
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyInsertDependency:lstWOsToUpdate.size() - ' + lstWOsToUpdate.size());
        }
        WSCH_AuditLogger.finish();
    }

    //Method to update the workorders with the dependency groupID on the WorkOrders when updating the existing Work Order Dependency objects from SFM
    /*public static void doQualifyUpdatedDependencyForBatch(List<Service_Order_Dependency__c> newDependencyList,List<Service_Order_Dependency__c> oldDependencyList) {
        List<SVMXC__Service_Order_Dependency__c>  qualifiedDependencyGroups = WSCH_DependencyTriggerHandler.getUpdatedDependencyGroupsForBatch(newDependencyList, oldDependencyList);
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: qualifiedDependencyGroups - ' + qualifiedDependencyGroups);
        
        if(qualifiedDependencyGroups == null || (qualifiedDependencyGroups != null && qualifiedDependencyGroups.size() == 0)) {
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: No qualified dependency group for update found');
            return;
        }
        Set<String> WO_Ids = new Set<String>();
        for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: qualifiedDependencyGroups){
            WO_Ids.add(string.valueof(groupDependencyRecords.SVMXC__Primary_Work_Order__c));
            WO_Ids.add(string.valueof(groupDependencyRecords.SVMXC__Secondary_Work_Order__c));
        }
        Set<SVMXC__Service_Order__c> dependencyGroupWoSet = new Set<SVMXC__Service_Order__c>();
        List<String> WoIdList = new List<String>();
        WoIdList.addAll(WO_Ids);
        List<SVMXC__Service_Order__c> woList = WSCH_CommonUtils.fetchWorkOrders(WoIdList);
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: woList-->'+woList);
        
        for(SVMXC__Service_Order__c WO: woList){
            for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: qualifiedDependencyGroups){
                if(WO.Id == groupDependencyRecords.SVMXC__Primary_Work_Order__c || WO.Id == groupDependencyRecords.SVMXC__Secondary_Work_Order__c) {
                    WO.SVMXC__Dependency_Group__c = groupDependencyRecords.SVMXC__Dependency_Group__c;
                    //checking if the WO is already present to avoid duplicate. This WO may already be part of this 
                    //list as it could have been a Secondary WO from a previous relation definition
                    if(!dependencyGroupWoSet.contains(WO)) {
                        dependencyGroupWoSet.add(WO);
                    }
                }
            }
            /*WO.SVMXC__Dependency_Group__c = qualifiedDependencyGroups[0].SVMXC__Dependency_Group__c;
            dependencyGroupWoList.add(WO);
        }
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: dependencyGroupWoSet - ' + dependencyGroupWoSet);
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        List<SVMXC__Service_Order__c> lstWOsToUpdate;
        if(dependencyGroupWoSet.size() > 0) {
            lstWOsToUpdate = new List<SVMXC__Service_Order__c>(dependencyGroupWoSet);
            update lstWOsToUpdate;
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: Updated the WO with the groupID');
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: lstWOsToUpdate.size() - ' + lstWOsToUpdate.size());
        }
        WSCH_AuditLogger.finish();
    }*/

    //Method to update the workorders with the dependency groupID on the WorkOrders when updating the existing Work Order Dependency objects from SFM
    public static void doQualifyUpdatedDependency(List<Service_Order_Dependency__c> newDependencyList,List<Service_Order_Dependency__c> oldDependencyList) {
        List<SVMXC__Service_Order_Dependency__c>  qualifiedDependencyGroups = WSCH_DependencyTriggerHandler.getUpdatedDependencyGroupsForBatch(newDependencyList, oldDependencyList);
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependency: qualifiedDependencyGroups - ' + qualifiedDependencyGroups);
        
        if(qualifiedDependencyGroups == null || (qualifiedDependencyGroups != null && qualifiedDependencyGroups.size() == 0)) {
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependencyForBatch: No qualified dependency group for update found');
            return;
        }
        Set<String> WO_Ids = new Set<String>();
        for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: qualifiedDependencyGroups){
            WO_Ids.add(string.valueof(groupDependencyRecords.SVMXC__Primary_Work_Order__c));
            WO_Ids.add(string.valueof(groupDependencyRecords.SVMXC__Secondary_Work_Order__c));
        }
        Set<SVMXC__Service_Order__c> dependencyGroupWoSet = new Set<SVMXC__Service_Order__c>();
        List<String> WoIdList = new List<String>();
        WoIdList.addAll(WO_Ids);
        List<SVMXC__Service_Order__c> woList = WSCH_CommonUtils.fetchWorkOrders(WoIdList);
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependency: woList-->'+woList);
        
        for(SVMXC__Service_Order__c WO: woList){
            for(SVMXC__Service_Order_Dependency__c groupDependencyRecords: qualifiedDependencyGroups){
                if(WO.Id == groupDependencyRecords.SVMXC__Primary_Work_Order__c || WO.Id == groupDependencyRecords.SVMXC__Secondary_Work_Order__c) {
                    WO.SVMXC__Dependency_Group__c = groupDependencyRecords.SVMXC__Dependency_Group__c;
                    //checking if the WO is already present to avoid duplicate. This WO may already be part of this 
                    //list as it could have been a Secondary WO from a previous relation definition
                    if(!dependencyGroupWoSet.contains(WO)) {
                        dependencyGroupWoSet.add(WO);
                    }
                }
            }
            /*WO.SVMXC__Dependency_Group__c = qualifiedDependencyGroups[0].SVMXC__Dependency_Group__c;
            dependencyGroupWoList.add(WO);*/
        }
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependency: dependencyGroupWoSet - ' + dependencyGroupWoSet);
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        List<SVMXC__Service_Order__c> lstWOsToUpdate;
        if(dependencyGroupWoSet.size() > 0) {
            lstWOsToUpdate = new List<SVMXC__Service_Order__c>(dependencyGroupWoSet);
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( lstWOsToUpdate, COMM_SecurityUtils.Access.Updateable) ) {		//SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    update lstWOsToUpdate;
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.label.COMM001_TAG142));
                return;
            }
            
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependency: Updated the WO with the groupID');
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler: doQualifyUpdatedDependency: lstWOsToUpdate.size() - ' + lstWOsToUpdate.size());
        }
        WSCH_AuditLogger.finish();
    }
    
    // Method to return the map of groupId to list of dependency records associated with it.
    public static Map<String, List<Service_Order_Dependency__c>> getDependencyMap(List<Service_Order_Dependency__c> WoDependencyList){
        Map<String, List<Service_Order_Dependency__c>> serviceOrderMap = new Map<String, List<Service_Order_Dependency__c>>();
        Set<String> dependencyManagementId = new Set<String>();
        Set<String> multiJobId = new Set<String>();

        List<SVMXC__Dependency_Management__c> dependencyManagementRecords = new List<SVMXC__Dependency_Management__c>();
        WSCH_AuditLogger.debug('WoDependencyList-->'+WoDependencyList);
        
        if(WoDependencyList == null) {
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler:getDependencyMap():WoDependencyList is empty or null: ' + WoDependencyList);
            return null;
        }
        
        for(Service_Order_Dependency__c svcOdr: WoDependencyList){
            dependencyManagementId.add(svcOdr.SVMXC__Dependency_Group__c);
        }
        
        try{
            for(String depGroup: dependencyManagementId){
                for(Service_Order_Dependency__c  svcOdr: WoDependencyList){
                    if(depGroup == svcOdr.SVMXC__Dependency_Group__c){
                        List<Service_Order_Dependency__c > serviceOrderlst = new List<Service_Order_Dependency__c >();
                        if(serviceOrderMap.containskey(depGroup)){
                            serviceOrderlst = serviceOrderMap.get(depGroup);
                            serviceOrderlst.add(svcOdr);
                            serviceOrderMap.put(depGroup, serviceOrderlst);
                        }
                        else{
                            serviceOrderlst.add(svcOdr);
                            serviceOrderMap.put(depGroup, serviceOrderlst);
                        }
                    }
                    
                }
            }
        }catch(exception ex){
            String exceptionMsg = 'WSCH_DependencyTriggerHandler :: getDependencyMap';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());
        }
        WSCH_AuditLogger.debug('serviceOrderMap-->'+serviceOrderMap);
        return serviceOrderMap;
    }
    
    //initiate future callout for BookDependencyJob API call
    @future(callout = true)
    public static void getBookDependencyRequestResponse(String multiJobId){ 
        List<Service_Order_Dependency__c> serviceOrderList = new List<Service_Order_Dependency__c>();
        serviceOrderList = WSCH_CommonUtils.fetchGroupDependency(multiJobId);
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler::getBookDependencyRequestResponse:: Work Order Dependency Records:'+serviceOrderList);
        WSCH_OptimizedSchedulingService.manageDependencyGroup(multiJobId, serviceOrderList);
    }
    
    //initiate future method for cancel book dependency group request
    /*@kundan- Commented this code as this functionality is not required for the current release.
    @future(callout = true)
    public static void cancelDependencyGroup(List<String> multiJobId, List<String> WoIds){ 
        //List<Service_Order_Dependency__c> serviceOrderList = new List<Service_Order_Dependency__c>();
        //serviceOrderList = WSCH_CommonUtils.fetchGroupDependency(multiJobId);
        WSCH_OptimizedSchedulingService.triggerExecuted = true;
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler::cancelDependencyGroup:: multiJobIDs to be cancelled:'+multiJobId);
        WSCH_OptimizedSchedulingService.cancelDependencyGroup(multiJobId, WoIds);
    }*/
    
    //validate work orders associated with WO depedency List in before Insert and before Update trigger context.
    public static void validateDependencyGroup(List<Service_Order_Dependency__c> svcOdrList, String multiJobId, String triggerContext){
        if(WSCH_DependencyTriggerHandler.getDependencySetting() == false){
            for(Service_Order_Dependency__c svcOrder: svcOdrList){
                svcOrder.addError(system.label.DCON003_TAG101);
            }
        }
        Boolean isLatestLessThenEarliest = false;
        Boolean isTargetTimeInvalid = false;
        Boolean isCostIdDoesNotExist = false;
        Boolean woIsPartOfDependentGroup = false;
        Boolean woDoNotQualify = false;
        Boolean hasMultipleConnectionNames = false;
        Decimal earliestTimeInMinutes;
        Decimal latestTimeInMinutes;
        Decimal targetTimeInMinutes;
        String WoDetail;
        Set<String> WOSetIds = new Set<String>();       
        try{
            for(Service_Order_Dependency__c serviceOrder : svcOdrList){
                WOSetIds.add(serviceOrder.SVMXC__Primary_Work_Order__c);
                WOSetIds.add(serviceOrder.SVMXC__Secondary_Work_Order__c);
                if(serviceOrder.SVMXC__Maximum_Time_Deviation__c != null){
                    if(serviceOrder.SVMXC__Maximum_Time_Deviation_Units__c == 'Hours'){
                        earliestTimeInMinutes = serviceOrder.SVMXC__Maximum_Time_Deviation__c * 60;
                    }
                    else if(serviceOrder.SVMXC__Maximum_Time_Deviation_Units__c == 'Days'){
                        earliestTimeInMinutes = serviceOrder.SVMXC__Maximum_Time_Deviation__c * 60 *60;
                    }
                    else if(serviceOrder.SVMXC__Maximum_Time_Deviation_Units__c == 'Minutes'){
                        earliestTimeInMinutes = serviceOrder.SVMXC__Maximum_Time_Deviation__c;
                    }
                }
                if(serviceOrder.SVMXC__Minimum_Time_Deviation__c != null){
                    if(serviceOrder.SVMXC__Minimum_Time_Deviation_Units__c == 'Hours'){
                        latestTimeInMinutes = serviceOrder.SVMXC__Minimum_Time_Deviation__c * 60;
                    }
                    else if(serviceOrder.SVMXC__Minimum_Time_Deviation_Units__c == 'Days'){
                        latestTimeInMinutes = serviceOrder.SVMXC__Minimum_Time_Deviation__c * 60 *60;
                    }
                    else if(serviceOrder.SVMXC__Minimum_Time_Deviation_Units__c == 'Minutes'){
                        latestTimeInMinutes = serviceOrder.SVMXC__Minimum_Time_Deviation__c;
                    }
                }
                if(serviceOrder.SVMXC__Targeted_Time_Difference__c != null){
                    if(serviceOrder.SVMXC__Targeted_Time_Variance_Cost_ID__c == '' || serviceOrder.SVMXC__Targeted_Time_Variance_Cost_ID__c == null){
                        isCostIdDoesNotExist = true;
                    }
                    if(serviceOrder.SVMXC__Targeted_Time_Difference_Units__c == 'Hours'){
                        targetTimeInMinutes = serviceOrder.SVMXC__Targeted_Time_Difference__c * 60;
                    }
                    else if(serviceOrder.SVMXC__Targeted_Time_Difference_Units__c == 'Days'){
                        targetTimeInMinutes = serviceOrder.SVMXC__Targeted_Time_Difference__c * 60 *60;
                    }
                    else if(serviceOrder.SVMXC__Targeted_Time_Difference_Units__c == 'Minutes'){
                        targetTimeInMinutes = serviceOrder.SVMXC__Targeted_Time_Difference__c;
                    }
                }
                if(latestTimeInMinutes < earliestTimeInMinutes){
                    isLatestLessThenEarliest = true;
                }
                else if(targetTimeInMinutes > latestTimeInMinutes || targetTimeInMinutes < earliestTimeInMinutes){
                    isTargetTimeInvalid = true;
                }
            }
            
            dependentWorkOrderIds.AddAll(WOSetIds);
            //WSCH_Provider_SP_RealTimeOptimizer realTimeOptimizer = new WSCH_Provider_SP_RealTimeOptimizer();
            //relatedWorkOrders = WSCH_CommonUtils.fetchWorkOrders(dependentWorkOrderIds);
            //WSCH_Provider_SP_RealTimeOptimizer.mapWoConName = new Map<Id, String>();
            //realTimeOptimizer.populateDispatchProcessSpURL(relatedWorkOrders);
            Set<String> setOfConnectionName = new Set<String>(); 
            relatedWorkOrders = [SELECT Id, Name, SVMXC__Dependency_Group__c, SVMXC__Zip__c, SVMXC__Service_Duration__c, SVMXC__OptiMax_Status__c, SVMXC__Scheduling_Change_Token__c, SVMXC__Optimizer_Connection_Name__c, SVMXC__Dispatch_Process__r.SVMXC__Target_URL__c from SVMXC__Service_Order__c where ID IN: dependentWorkOrderIds];
            WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler::validateDependencyGroup:WO in the Group:'+relatedWorkOrders);
            for(SVMXC__Service_Order__c WO: relatedWorkOrders){           
                //WSCH_Provider_SP_RealTimeOptimizer.getSpConnName(WO.SVMXC__Dispatch_Process__c, WO.SVMXC__Optimizer_Connection_Name__c, WO.Id);
                if(WO.SVMXC__Optimizer_Connection_Name__c != null){
                    setOfConnectionName.add(WO.SVMXC__Optimizer_Connection_Name__c);
                }
                else if(WO.SVMXC__Dispatch_Process__r.SVMXC__Target_URL__c != null){
                    setOfConnectionName.add(WO.SVMXC__Dispatch_Process__r.SVMXC__Target_URL__c);
                }
                if(setOfConnectionName.size() >1){
                    hasMultipleConnectionNames = true;
                }
                if(WO.SVMXC__Zip__c == '' || WO.SVMXC__Zip__c == null || WO.SVMXC__Service_Duration__c == null){
                    if(WoDetail != null){
                        WoDetail = WoDetail + ',' +WO.Name;
                    }else{
                        WoDetail = WO.Name;
                    }
                    woDoNotQualify = true;
                }
                else if(WO.SVMXC__Dependency_Group__c != null){
                    System.debug('multiJobId-->'+multiJobId+'WO.SVMXC__Dependency_Group__c-->'+WO.SVMXC__Dependency_Group__c);
                    if(triggerContext == 'beforeUpdate' && WO.SVMXC__Dependency_Group__c != multiJobId){
                        woIsPartOfDependentGroup = true;
                        if(WoDetail != null){
                            WoDetail = WoDetail + ',' +WO.Name;
                        }else{
                            WoDetail = WO.Name;
                        }
                    }
                    else if(triggerContext == 'beforeInsert'){
                        System.debug('insert multiJobId-->'+multiJobId+'WO.SVMXC__Dependency_Group__c-->'+WO.SVMXC__Dependency_Group__c);
                        woIsPartOfDependentGroup = true;
                        if(WoDetail != null){
                            WoDetail = WoDetail + ',' +WO.Name;
                        }else{
                            WoDetail = WO.Name;
                        }
                    }
                }
            }
        WSCH_AuditLogger.debug('WSCH_DependencyTriggerHandler::validateDependencyGroup::setOfConnectionName:'+setOfConnectionName+'woDoNotQualify:'+woDoNotQualify+'woIsPartOfDependentGroup:'+woIsPartOfDependentGroup);
        /*SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.Id = 'abc';
        insert wo;*/
        }catch(exception ex){
            String exceptionMsg = 'WSCH_DependencyTriggerHandler :: validateDependencyGroup';
            WSCH_AuditLogger.error(exceptionMsg+ex.getMessage() + '\n Stack Trace:: ' + ex.getStackTraceString());  
        }
        for(Service_Order_Dependency__c svcOrder: svcOdrList){
            if(isCostIdDoesNotExist){
                svcOrder.addError(system.label.DCON003_TAG093);
            }
            else if(isTargetTimeInvalid){
                svcOrder.addError(system.label.DCON003_TAG094);
            }
            else if(isLatestLessThenEarliest){
                //svcOrder.addError(system.label.DCON003_TAG095);
            }
            else if(hasMultipleConnectionNames){
                svcOrder.addError(system.label.DCON003_TAG096);
            }
            else if(woDoNotQualify){
                svcOrder.addError(system.label.DCON003_TAG097+':'+WoDetail);
            }
            else if(woIsPartOfDependentGroup){
                svcOrder.addError(system.label.DCON003_TAG098+':'+WoDetail);
            }
        }             
    }
    // Method to check if dependency records are qualified for a group dependency API call on update.
    public static boolean markChangeToken(Service_Order_Dependency__c newDependencyRecord, Service_Order_Dependency__c oldDependencyRecord){
        Boolean isQualifyAndMark = false;
        String schedulingChangeToken = '';
        if(newDependencyRecord.SVMXC__Primary_Work_Order__c != oldDependencyRecord.SVMXC__Primary_Work_Order__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
            
            //if the Old WO is replaced with a new WO in the WO Dependency record, nullify the Group ID from the Old WO
            SVMXC__Service_Order__c woToUpdate = WSCH_CommonUtils.fetchWorkOrderById(String.valueOf(oldDependencyRecord.SVMXC__Primary_Work_Order__c));
            woToUpdate.SVMXC__Dependency_Group__c = null;
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( woToUpdate, COMM_SecurityUtils.Access.Upsertable) ) {		//SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    upsert woToUpdate;
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.label.COMM001_TAG142));
                return null;
            }
        }
        else if(newDependencyRecord.SVMXC__Secondary_Work_Order__c != oldDependencyRecord.SVMXC__Secondary_Work_Order__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
            
            //if the Old WO is replaced with a new WO in the WO Dependency record, nullify the Group ID from the Old WO
            SVMXC__Service_Order__c woToUpdate = WSCH_CommonUtils.fetchWorkOrderById(String.valueOf(oldDependencyRecord.SVMXC__Secondary_Work_Order__c));
            woToUpdate.SVMXC__Dependency_Group__c = null;
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( woToUpdate, COMM_SecurityUtils.Access.Upsertable) ) {		//SDL-SVMX-CREATE-UPDATE-FLS-ENFORCED
                    upsert woToUpdate;
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.label.COMM001_TAG142));
                return null;
            }
        }
        else if(newDependencyRecord.SVMXC__Resource_Dependency__c != oldDependencyRecord.SVMXC__Resource_Dependency__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Time_Dependency__c != oldDependencyRecord.SVMXC__Time_Dependency__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Minimum_Time_Deviation__c != oldDependencyRecord.SVMXC__Minimum_Time_Deviation__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Minimum_Time_Deviation_Units__c != oldDependencyRecord.SVMXC__Minimum_Time_Deviation_Units__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Maximum_Time_Deviation__c != oldDependencyRecord.SVMXC__Maximum_Time_Deviation__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Maximum_Time_Deviation_Units__c != oldDependencyRecord.SVMXC__Maximum_Time_Deviation_Units__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Dependency_Group__c != oldDependencyRecord.SVMXC__Dependency_Group__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Targeted_Time_Variance_Cost_ID__c != oldDependencyRecord.SVMXC__Targeted_Time_Variance_Cost_ID__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Targeted_Time_Difference__c != oldDependencyRecord.SVMXC__Targeted_Time_Difference__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        else if(newDependencyRecord.SVMXC__Targeted_Time_Difference_Units__c != oldDependencyRecord.SVMXC__Targeted_Time_Difference_Units__c){
            //schedulingChangeToken = 'CHANGE_DEPENDENCY_WO';
            isQualifyAndMark = true;
        }
        
        return isQualifyAndMark;
    }
}