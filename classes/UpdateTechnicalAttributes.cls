/* Security Scanned */
global with sharing class UpdateTechnicalAttributes extends IOTImplInterface {
    override public Object execute(IoTRequest.ServiceRequestAlert request) { 
        System.debug('Request reached: ' + request);
        if(request != null && request.Event != null && request.Asset != null && request.Others != null){
            String installedProductId = getInstalledProductID();
            if(installedProductId != null){
                String payloadObject = String.valueOf(JSON.serialize(request.Event.instancePayload));
                object instantIndex = updateOrInsertInstantTable(payloadObject,installedProductId);
                if(instantIndex != null){
                    object historyIndex = updateOrInsertHistoryTable(payloadObject,installedProductId,String.valueOf(instantIndex));
                }
                return String.valueOf(instantIndex);
            } else {
                return 'Installed Product not found';
            }
        }
        else if(request.Asset == null){
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', 'Asset cannot be null', false);
            return new ErrorMessage('','', 'Asset cannot be null');
        }
        else if(request.Event == null){
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', 'Event cannot be null', false);
            return new ErrorMessage('','', 'Event cannot be null');
        }
        else if(request.Others == null){
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', 'Others cannot be null', false);
            return new ErrorMessage('','', 'Others cannot be null');
        }
        else{
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', 'request cannot be null', false);
            return new ErrorMessage('','', 'request cannot be null');
        }
    }

    public Object updateOrInsertInstantTable(String payload,String installedProductId){
        SVMXC__SM_IB_Attributes_Template_Instance__c newInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
        newInstance.SVMXC__SM_Attr_Payload__c = payload;
        newInstance.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
        newInstance.SVMXC__SM_Installed_Product_Id__c = installedProductId;
        newInstance.SVMXC__SM_Captured_On__c = System.now();
        String instanceId = getInstantEntryAvailable(installedProductId);

        if(instanceId != null){
            newInstance.Id = instanceId;
        }
        try{
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( newInstance, COMM_SecurityUtils.Access.Createable ) ) {
                //SDL-SVM-CREATE-UPDATE-FLS-ENFORCED
                upsert newInstance;
            } 
            //#ANA-152 - Update the event object with the information.
            updateTarget(COMPLETED_STATUS, newInstance.id, '', false);
            return newInstance.id;
        }
        catch(Exception ex){
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', ex.getMessage(), false);
            return new ErrorMessage('','', ex.getMessage()); 
        }
    }


    public Object updateOrInsertHistoryTable(String payload,string installedProductId, String instanceId){
        SVMXC__SM_IB_Attributes_History__c newHistory = new SVMXC__SM_IB_Attributes_History__c();
        newHistory.SVMXC__SM_Attr_Payload__c = payload;
        newHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
        newHistory.SVMXC__SM_Installed_Product_Id__c = installedProductId;
        newHistory.SVMXC__SM_Captured_On__c = System.now();
        newHistory.SVMXC__SM_Instance_Template_Id__c = instanceId;
        SVMXC__SM_IB_Attributes_History__c historyObj = getHistoryEntryAvailableForToday(installedProductId);
        Datetime currentDateTime = System.now();
        Date currentDate = currentDateTime.date();
        Date capturedOnDate ;
        if(historyObj != null){
            Datetime capturedOnDateTime = historyObj.SVMXC__SM_Captured_On__c;
            if(capturedOnDateTime != null){
                capturedOnDate = capturedOnDateTime.date();
            }
            if(capturedOnDate != null){
                if(!(currentDate > capturedOnDate)){
                    newHistory.Id = historyObj.Id;  
                }else{
                    
                }
            }
        }
        try{
            if( COMM_SecurityUtils.getInstance().verifyFieldAccess( newHistory, COMM_SecurityUtils.Access.Createable ) ) {
                //SDL-SVM-CREATE-UPDATE-FLS-ENFORCED
                upsert newHistory;
            } 
            //#ANA-152 - Update the event object with the information.
            updateTarget(COMPLETED_STATUS, newHistory.id, '', false);
            return newHistory.id;
        }
        catch(Exception ex){
            //#ANA-152 - Update the event object with the information.
            updateTarget(ERROR_STATUS, '', ex.getMessage(), false);
            return new ErrorMessage('','', ex.getMessage()); 
        } 
    }

    String getInstantEntryAvailable(String installedProductId){
        List<SVMXC__SM_IB_Attributes_Template_Instance__c> instantRecords = [Select Id from SVMXC__SM_IB_Attributes_Template_Instance__c where SVMXC__SM_Installed_Product_Id__c =: installedProductId];
        if(instantRecords.size() > 0){
            return instantRecords[0].id;
        }
        return null;
    } 

    SVMXC__SM_IB_Attributes_History__c getHistoryEntryAvailableForToday(String installedProductId){
        //SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
        List<SVMXC__SM_IB_Attributes_History__c> historyRecords = [Select Id,SVMXC__SM_Captured_On__c from SVMXC__SM_IB_Attributes_History__c where SVMXC__SM_Installed_Product_Id__c =: installedProductId ORDER BY SVMXC__SM_Captured_On__c DESC NULLS LAST LIMIT 1];
        if(historyRecords.size() > 0){
            return historyRecords[0];
        }
        return null;
    }

    String getInstalledProductID(){
        Object installedProductIds = super.IPLookup_IoT();
        if(installedProductIds instanceof Id){
            return String.valueOf(installedProductIds);
        }
        return null;
    }
}