@isTest(seeAllData = false)
public with sharing class WSCH_Provider_ECO_ChangedItems_UT {
    
    static testMethod void testEcoChangedItems() {
        
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Order_Status__c='Open';
        wo.SVMXC__City__c='Austin';
        wo.SVMXC__State__c='CA';
        wo.SVMXC__Zip__c='75001';
        insert wo;
        
        //String jsonStr='{"workItems":[{"id":"'+wo.Name+'", "booking":{"start":"21-07-2014 09:00", "arr":"21-07-2014 09:00", "end":"21-07-2014 17:00", "tech":"T004"}, "task":{"action":"NOTIFIED", "tied":"true"}, "atRisk":{"type":"Allocation Issue", "offset":"20"}}]}';
        //{"state":"ON_TENTATIVE","errorcode":"[No error!]","workItems":[{"id":"WO-00015361","type":"JOB","booking":{"start":"2016-12-04 07:08","end_x":"2016-12-06 18:58","arr":"2016-12-06 17:58","tech":""}}],"changeTime":"2016-11-30 06:58","requested":false}
        
        String jsonStr = '{"state":"ON_TENTATIVE","errorcode":"[No error!]","workItems":[{"id":"'+ wo.Name +'","type":"JOB","booking":{"start":"2016-12-04 07:08","end_x":"2016-12-06 18:58","arr":"2016-12-06 17:58","tech":""}}],"changeTime":"2016-11-30 06:58","requested":false}';
        
        WSCH_Provider_ECO_ChangedItems.doProcessRestRequest(jsonStr);
        
         String jsonStr1 = '{"state":"ON_TENTATIVE","errorcode":"[No error!]","workItems":[],"changeTime":"","requested":false}';
         WSCH_Provider_ECO_ChangedItems.doProcessRestRequest(jsonStr1);
         
          String jsonStr2 = '{"state":"ON_TENTATIVE","errorcode":"[No error!]","workItems":[],"changeTime":","requested":false}';
         WSCH_Provider_ECO_ChangedItems.doProcessRestRequest(jsonStr2);
         
         String jsonStr3 = '{"state":"ON_TENTATIVE","errorcode":"[No error!]","workItems":[{"id":"'+ wo.Name +'","type":"JOB","booking":{"start":"2016-12-04 07:08","end_x":"2016-12-06 18:58","arr":"2016-12-06 17:58","tech":""}}],"changeTime":"2016-11-30 06:58","requested":false}';
         
        RestRequest req = new RestRequest(); 
        req.requestURI = '/services/apexrest/scheduling/eco/changeditems';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(jsonStr3);
        RestContext.request = req;
        WSCH_Provider_ECO_ChangedItems.doPost();
        
    
        
    }
}