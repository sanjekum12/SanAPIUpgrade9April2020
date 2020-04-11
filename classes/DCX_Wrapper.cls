public with sharing class DCX_Wrapper {


    public class DCX_Response{
        public Object content;
        public Boolean success;
        //public Object errors;
        public String message;
        public Integer errorCode;
        public DCX_Response(){

        }
    }
  
    
    public class INTF_getViewDefinition_WS_Object {
        public String userId;
        public String groupId;
        public String profileId;
        public List <INTF_WebServicesDef.INTF_StringListMap> stringMap;

        
        public INTF_getViewDefinition_WS_Object() {
            
        }
        
        public INTF_getViewDefinition_WS_Object(String userId,String groupId,String profileId,List<INTF_WebServicesDef.INTF_StringListMap> stringLMap) {
            this.userId = userId;
            this.groupId = groupId;
            this.profileId = profileId;
            this.stringMap = stringLMap;
        }
    } 
    public class DCON_ViewWoCount_WS_Object {
        public List<String> viewIds;

        
        public DCON_ViewWoCount_WS_Object() {
            
        }
        
        public DCON_ViewWoCount_WS_Object(List<String> viewIds){
            this.viewIds = viewIds;
        }
    }
    
    public class EventDataRequest {
        
        public String startDate;
        public String endDate;
        public String tzDtFormat;
        public List<String> techIds;
        
        public EventDataRequest() {
            
        }
        
        public EventDataRequest(String startDate, String endDate, String timeZoneDateTimeFormat, List<String> techIds) {
            this.startDate = startDate;
            this.endDate = endDate;
            this.tzDtFormat = timeZoneDateTimeFormat;
            this.techIds = techIds;
        }
    }
    public class DCON_Retrieve_TechnicianInfo_Tree_WS_Object {
        public String keyValPairs;
        public list<String> techIds;
        
        public DCON_Retrieve_TechnicianInfo_Tree_WS_Object() {
            
        }
        
        public DCON_Retrieve_TechnicianInfo_Tree_WS_Object(String keyValPairs, List<String> techIds) {
            
            this.keyValPairs = keyValPairs;
            this.techIds = techIds;
        }
    }
    public class DCON_Keyword_Search_WS_Object {
        public String keyword;
        public String findWhat;
        public String keywordMatch;
        public String searchType;
        
        public DCON_Keyword_Search_WS_Object() {
            
        }
        
        public DCON_Keyword_Search_WS_Object(String keyword, String FindWhat, String KeywordMatch, String SearchType) {
            
            this.keyword = keyword;
            this.findWhat = findWhat;
            this.keywordMatch = keywordMatch;
            this.searchType = searchType;
        }
    }
    
    public class UpdateWOTech_Object {
        public List<String> WorkOrderIds = new List<String>();
        public String TechnicianId{get;set;} 
        public String timeZone{get;set;}  
        public List<Event> EventList = new List<Event>();
        public Boolean setOwner{get;set;}
        public list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue = new list<DCON_Configuration_WS.SVMX_StringMap>();
        public Boolean isUpdate{get;set;}
        
        public UpdateWOTech_Object() {
            
        }
        
        public UpdateWOTech_Object(List<String> WorkOrderIds,
                        String TechnicianId,
                        String timeZone,
                        List<Event> EventList, 
                        Boolean setOwner,
                        List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                        Boolean isUpdate) {
            this.WorkOrderIds = WorkOrderIds; 
            this.TechnicianId = TechnicianId;
            this.timeZone = timeZone;
            this.EventList = EventList;
            this.setOwner = setOwner;
            this.lstKeyValue = lstKeyValue;
            this.isUpdate = isUpdate;
        }
    }
    
    public class AssignWOTeam_Object {
        public List<String> WorkOrderIds;
        public String TeamId;
        public Boolean SetOwner;
        public String dispatchStatus;
         public Boolean unassignWorkorder;
        
        public AssignWOTeam_Object() {
            
        }
        
        public AssignWOTeam_Object( List<String> WorkOrderIds, String TeamId, Boolean SetOwner,String dispatchStatus,Boolean unassignWorkorder) {
            
            this.WorkOrderIds = WorkOrderIds;
            this.TeamId = TeamId;
            this.SetOwner = SetOwner;
            this.dispatchStatus = dispatchStatus;
            this.unassignWorkorder = unassignWorkorder;
        }
    }
    public class UnassignWO_Object {
        public List<String> WorkOrderIds;
        
        public UnassignWO_Object() {
            
        }
        
        public UnassignWO_Object(List<String> WorkOrderIds) {
            
            this.WorkOrderIds = WorkOrderIds;
        }
    }
    
     public class UnassignJDMWO_Object {
         public String WorkOrderId {get; set;}
        public String TechId {get; set;}
        public String OwnerId {get; set;}
        public String EventStartDateTime {get; set;} /** @deprecated **/
        public DateTime EventStartDtTm {get; set;}
        public boolean isEarlierEvents {get; set;}
        public String timeZone {get; set;}
        public String eventId {get; set;} //will get this event Id only when we are trying to select and delete an event from past. 
        public boolean isDeleteAllEvents {get; set;}
        public String deleteSingleEventId {get; set;} //When user selects single event for delete, this variable will be fed.
        public boolean isUnassignTech{get; set;}
        
        public UnassignJDMWO_Object() {
            
        }
        
        public UnassignJDMWO_Object(String WoId, String TechnicianId, String OwnId, boolean earlierEvents, DateTime EventSDTime, String userTimeZone,String eventId,boolean isDeleteAllEvents,String deleteSingleEventId,boolean isUnassignTech) {
            
            this.WorkOrderId = WoId;
            this.TechId = TechnicianId;
            this.OwnerId = OwnId;
            this.isEarlierEvents = earlierEvents;
            this.EventStartDtTm = EventSDTime;
            this.timeZone = userTimeZone;
            this.eventId = eventId;
            this.isDeleteAllEvents = isDeleteAllEvents;
            this.deleteSingleEventId = deleteSingleEventId;
            this.isUnassignTech = isUnassignTech;
        }
    }
    
     public class AssignWOTOMutliTech_Object {
        public String WorkOrderId;
        public String TechnicianId;
        public String timeZone;
        public List<Event> EventList;
        public Boolean updatePrimaryTech;
        public list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue;
        public Boolean deleteEventForOtherTechs;
        public String techSFId;
        public Boolean updateWorkOrder;
        public List<String> woFields;
        
        public AssignWOTOMutliTech_Object() {
            
        }
        
        public AssignWOTOMutliTech_Object( String woId, String TechnicianId, 
                                          String timeZone, List<Event> EventList, 
                                          Boolean updatePrimaryTc, 
                                          list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                                          Boolean tc,String tcSFId, Boolean uWO,List<String> wFields) {
            
            this.WorkOrderId = woId;
            this.TechnicianId = TechnicianId;
            this.timeZone = timeZone;
            this.EventList = EventList;
            this.updatePrimaryTech = updatePrimaryTc;
            this.lstKeyValue = lstKeyValue;
            this.deleteEventForOtherTechs = tc;
            this.techSFId = tcSFId;
            this.updateWorkOrder = uWO;
            this.woFields = wFields;
        }
    }
    
    public class UnassignWOTOMutliTech_Object {
        public List<String> WorkOrderIds;
        public String TechnicianId;
        public String timeZone;
        public List<Event> EventList;
        public Boolean setOwner;
        public list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue;
        
        public UnassignWOTOMutliTech_Object() {
            
        }
        
        public UnassignWOTOMutliTech_Object( List<String> WorkOrderIds, String TechnicianId, String timeZone, List<Event> EventList, Boolean setOwner, list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue) {
            
            this.WorkOrderIds = WorkOrderIds;
            this.TechnicianId = TechnicianId;
            this.timeZone = timeZone;
            this.EventList = EventList;
            this.setOwner = setOwner;
            this.lstKeyValue = lstKeyValue;
        }
    }
    
    public class ResetWO_Object {
        public List<String> WorkOrderIds;
        
        public ResetWO_Object() {
            
        }
        
        public ResetWO_Object(List<String> WorkOrderIds) {
            
            this.WorkOrderIds = WorkOrderIds;
        }
    }

    public class eventWODataRequest {
        public List<String> eventIds;
        public List<String> keyValPairs;
        public String viewId;
        public List<String> dispatchStatus;
        public String timeZoneDateTimeFormat;
        public List<String> workOrderIds;
    }

    public class woEventsRequest {
        public String startDate;
        public String endDate;
        public String timeZone;
        public String woId;
    }

    public class updateDeleteEventsRequest {
        public String startDate;
        public String endDate;
        public String eventType;
        public String timeZoneDateTimeFormat;
        public String lastRetrievedDate;
        public List<String> technicianIds;
    }

    public class upsertEventsRequest {
        public List<Event> events;
        public String timeZone;
        public list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue;
        public String techId;
        public Boolean updatePrimaryTech;
        public Boolean deleteEventForOtherTechs;
        public String techSFId;
        public List<String> woFields;
    }

    public class deleteEventsRequest {
        public List<String> eventIds;
    }

    public class deleteEventsResponse {
        public String delEventIds; 
        public DCON_Work_Order_WS.DCTech_WO_Response_WP eventsResponse;
        public Map<Id,SVMXC__Service_Order__c> woInfo;
    }
	
    public class deleteAESEventsResponse {
        public String delEventIds; 
        public DCX_EventServiceManager.DCTech_WO_Response_WP eventsResponse;
        public Map<Id,SVMXC__Service_Order__c> woInfo;
    }
    
    public class assignWOResponse {
        public  DCX_WOServiceManager.assignWOTeam_Response statusMessage;
        public Map<Id,SVMXC__Service_Order__c> woInfo;
    }

    public class allEventsRequest {
        public List<String> woIds;
        public List<String> technicianIds;
        public String timeZoneDateTimeFormat;
    }

    public class DCON_Retrieve_Tech_WorkingHrs_WS_Object {
        public List<String> lsttechId;
        public String startdate;
        public String enddate;

        
        public DCON_Retrieve_Tech_WorkingHrs_WS_Object() {
            
        }
        
        public DCON_Retrieve_Tech_WorkingHrs_WS_Object(List<String> lsttechId, String startdate, String enddate){
            this.lsttechId = lsttechId;
            this.startdate = startdate;
            this.enddate = enddate;
        }
    }

    public class scheduledTechniciansRequest {
        public List<String> workOrderIds;

        public scheduledTechniciansRequest() {
            
        }
        
        public scheduledTechniciansRequest(List<String> workOrderIds){
            this.workOrderIds = workOrderIds;
        }
    }
    
    public class getWOforMutliAssign_Object {
        public List<String> workOrderIds;
        public List<String> technicianIds;
        public String operationType{get; set;}
        public String timezone{get; set;}
        public List<Event> Eventlist;
        public List< String > EventIds;
        public List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue;
        public List<String> getworkOrderIds;
        public List<Event> getEventlist;
        public List<Event> setEventlist;
        public String techSFId;
        public List<String> woFields;
        
        public getWOforMutliAssign_Object() {
            
        }

        public getWOforMutliAssign_Object(List<String> workOrderIds,List<String> technicianIds,String operationType,String timezone,List<Event> Eventlist,
        List< String > EventIds,List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,List<String> getworkOrderIds,List<Event> getEventlist,List<Event> setEventlist,String tcSFId,List<String> wFields) {
            this.workOrderIds =workOrderIds;
            this.technicianIds = technicianIds;
            this.operationType = operationType;
            this.timezone = timezone;
            this.Eventlist = Eventlist;
            this.EventIds = EventIds;
            this.lstKeyValue = lstKeyValue;
            this.getworkOrderIds = getworkOrderIds;
            this.getEventlist = getEventlist;
            this.setEventlist = setEventlist;
            this.techSFId = tcSFId;
            this.woFields = wFields;
        }
        
    }
    
     public class getEventHover_Object {
        public String WorkOrderId;

        public getEventHover_Object() {
            
        }
        
        public getEventHover_Object(String WorkOrderId){
            this.WorkOrderId = WorkOrderId;
        }
    }
    
     public class DCON_WO_Get_Dependency_Details_WS_Object {
        public List<Event> lstSFEvent;
        public List<SVMXC__SVMX_Event__c> lstSVMXEvent;
        public String timeZone;
        public List<String> listWOIds;

        
        public DCON_WO_Get_Dependency_Details_WS_Object() {
            
        }
        
        public DCON_WO_Get_Dependency_Details_WS_Object(List<Event> lstSFEvent, List<SVMXC__SVMX_Event__c> lstSVMXEvent, String timeZone,List<String> listWOIds){
            this.lstSFEvent = lstSFEvent;
            this.lstSVMXEvent = lstSVMXEvent;
            this.timeZone = timeZone;
            this.listWOIds = listWOIds;
        }
    }
    
    public class getDependencyCheck_Object {
        public List<Event> lstSFEvent = new list<Event>();
            public List<SVMXC__SVMX_Event__c> lstSVMXEvent = new List<SVMXC__SVMX_Event__c>();
            public String timeZone{get;set;}
            public String userId{get;set;}
            public List<String> listWOIds = new List<String>();
        
        public getDependencyCheck_Object() {
            
        }
        
        public getDependencyCheck_Object(List<Event> lstSFEvent, List<SVMXC__SVMX_Event__c> lstSVMXEvent, String timeZone,String userId,List<String> listWOIds){
            this.lstSFEvent = lstSFEvent; 
                this.timeZone = timeZone;
                this.lstSVMXEvent = lstSVMXEvent;
                this.userId = userId;
                this.listWOIds = listWOIds;
        }
    }
    
    public class diployUserSettingObject {
        public List<string> settings;
        public List<string> userids;
        
        public diployUserSettingObject() {
            
        }
        
        public diployUserSettingObject(List<string> settings,List<string> userids) {
            
            this.settings = settings;
            system.debug('settings :'+this.settings);
            this.userids = userids;
            system.debug('userids :'+this.userids);
        }
    }
    
    public class getWObyIdsObject {
        public String timeZone;
        public List<String> workorderIds;
        
        public getWObyIdsObject() {
            
        }
        
        public getWObyIdsObject(String timeZone,List<String> workorderIds) {
            
            this.timeZone = timeZone;
            this.workorderIds = workorderIds;
        }
    }

    public class workOrdersForIds {
        public List<String> workorderIds;
        
        public workOrdersForIds() {}

        public workOrdersForIds(List<String> workorderIds) {
            this.workorderIds = workorderIds;
        }
    }

    public class technicianIds {
        public List<String> techIds;
        public List<String> techFields;
        
        public technicianIds() {}

        public technicianIds(List<String> reqIds,List<String> tFields) {
            this.techIds = reqIds;
            this.techFields = tFields;
        }
    }

    public class advTechSearchRequest {

        public String woId;
        public Boolean isPreferredTechEnabled;
        public Boolean isProductExpertiseEnabled;
        public Boolean isSkillsEnabled;
        public Boolean isEligibilityEnabled;
        public List<String> lstTech;

        public advTechSearchRequest() {}

        public advTechSearchRequest(String woId,Boolean isPreferredTechEnabled,Boolean isProductExpertiseEnabled,Boolean isSkillsEnabled,Boolean isEligibilityEnabled,List<String> lstTech) {
            this.woId = woId;
            this.isPreferredTechEnabled = isPreferredTechEnabled;
            this.isProductExpertiseEnabled = isProductExpertiseEnabled;
            this.isSkillsEnabled = isSkillsEnabled;
            this.isEligibilityEnabled = isEligibilityEnabled;
            this.lstTech = lstTech;
        }
    }

      public class createLJSEvent_object 
    {
        public String timeZone;
        public List<Event> lstEvent = new list<Event>();    
        public List<String> lsttechId = new List<String>();     
        public Integer eventMinDuration;
        public boolean isTechWorkingHrsEnabled;
       public  boolean isMachineWorkingHrsEnabled;
        public boolean isOverlappingEnabled;
        public boolean isCalculateEndTime;
       public  list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue = new list<DCON_Configuration_WS.SVMX_StringMap>();
        public boolean IsUnAssignWorkOrder;
        public boolean IsdeleteEvents;
        public String techSFId;
        public List<String> woFields;
        
        public createLJSEvent_object() {}
        
        public createLJSEvent_object( 
                        List<Event> lstEvent,
                        String timeZone,
                        List<String> lsttechId,
                        integer eventMinDuration, 
                        boolean isTechWorkingHrsEnabled,
                        boolean isMachineWorkingHrsEnabled,
                        boolean isOverlappingEnabled,
                        boolean isCalculateEndTime,
                        List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue,
                        boolean IsUnAssignWorkOrder,
                        boolean IsdeleteEvents,
                        String tcSFId,
                        List<String> wFields 
                        ) 
        {
            
            this.lstEvent = lstEvent; 
            this.timeZone = timeZone;
            this.lsttechId = lsttechId;
            this.eventMinDuration = eventMinDuration;
            this.isTechWorkingHrsEnabled = isTechWorkingHrsEnabled;
            this.isMachineWorkingHrsEnabled = isMachineWorkingHrsEnabled;
            this.isOverlappingEnabled = isOverlappingEnabled;
            this.isCalculateEndTime = isCalculateEndTime;
            this.lstKeyValue = lstKeyValue;
            this.IsUnAssignWorkOrder = IsUnAssignWorkOrder;
            this.IsdeleteEvents = IsdeleteEvents;
            this.techSFId = tcSFId;
            this.woFields = wFields;
        }
    }

         public class deleteJDMEvent {
      public  DateTime EventStartDtTm {get;set;}
         public String WorkOrderId {get;set;}
         public String TechId {get;set;}
         public boolean isDeleteAllEvents {get;set;}
         public  String timeZone {get;set;}
         public String eventId {get;set;}
         public boolean isUnassignTech {get;set;}
         public String OwnerId {get;set;}
        // public String EventStartDateTime {get;set;}
         public boolean isEarlierEvents {get;set;}
         public String deleteSingleEventId {get;set;}
         //public List<String> woFields;
        
        public deleteJDMEvent() {
            
        }
        
        public deleteJDMEvent(List<String> workorderIds) {
            this.EventStartDtTm =EventStartDtTm;
         this.WorkOrderId =WorkOrderId;
         this.TechId =TechId;
         this.isDeleteAllEvents =isDeleteAllEvents;
         this.timeZone= timeZone;
         this.eventId= eventId;
        this.isUnassignTech=isUnassignTech;
         this.OwnerId=OwnerId;
       //  this.EventStartDateTime =EventStartDateTime;
         this.isEarlierEvents= isEarlierEvents;
         this.deleteSingleEventId = deleteSingleEventId;
        }
    }

    /*  public class DCON_Retrieve_Work_Orders_WS2_Object {
        public String sfdcId;
        public List<String> keyValPairs;
        public String UserId; 
        public String ViewId; 
        public List<String> DispatchStatus;
        public String timeZone;
        public List<String> workorderIds;
        
        public DCON_Retrieve_Work_Orders_WS2_Object() {
            
        }
        
        public DCON_Retrieve_Work_Orders_WS2_Object(List<String> keyValPairs, String UserId, String ViewId, List<String> DispatchStatus,String timeZone, List<String> workorderIds) {
            this.keyValPairs = keyValPairs;
            this.UserId = UserId;
            this.ViewId = ViewId;
            this.DispatchStatus = DispatchStatus;
            this.timeZone = timeZone;
            this.workorderIds = workorderIds;
        }
    }*/
    
    /*public class DCON_Retrieve_AllWorkOrder_Ids_WS_Object {
        public String sfdcId;
        public List<String> keyValPairs;
        public String UserId; 
        public String ViewId; 
        public List<String> DispatchStatus;
        public String timeZone;

        
        public DCON_Retrieve_AllWorkOrder_Ids_WS_Object() {
            
        }
        
        public DCON_Retrieve_AllWorkOrder_Ids_WS_Object(List<String> keyValPairs, String UserId, String ViewId, List<String> DispatchStatus,String timeZone) {
            this.keyValPairs = keyValPairs;
            this.UserId = UserId;
            this.ViewId = ViewId;
            this.DispatchStatus = DispatchStatus;
            this.timeZone = timeZone;

        }
    }*/
   /* public class DCON_Retrieve_Events_WS_Object {
        public String startDate;
        public String endDate; 
        public String eventType; 
        public String timeZoneFormat;
        public List<String> technicianIds;

        
        public DCON_Retrieve_Events_WS_Object() {
            
        }
        
        public DCON_Retrieve_Events_WS_Object( String startDate, String endDate, String eventType, String timeZoneFormat, List<String> technicianIds) {
            this.startDate = startDate;
            this.endDate = endDate;
            this.eventType = eventType;
            this.timeZoneFormat = timeZoneFormat;
            this.technicianIds = technicianIds;

        }
    }*/
  /*  public class DCON_Retrieve_Technician_Tree_WS_Object {
        public String UserId;
        public String SearchType;
        public Boolean RetrieveAllRecords; 
        public String timeZone;
        public List<String> ServiceTeamTerr;

        
        public DCON_Retrieve_Technician_Tree_WS_Object() {
            
        }
        
        public DCON_Retrieve_Technician_Tree_WS_Object(String UserId, String SearchType, Boolean RetrieveAllRecords,String timeZone,List<String> ServiceTeamTerr) {
            this.UserId = UserId;
            this.SearchType = SearchType;
            this.RetrieveAllRecords = RetrieveAllRecords;
            this.timeZone =timeZone;
            this.ServiceTeamTerr =ServiceTeamTerr;

        }
    }  */
   /* public class DCON_Retrieve_Territory_Tree_WS_Object {
        public String UserId;
        public Boolean RetrieveAllRecords; 

        
        public DCON_Retrieve_Territory_Tree_WS_Object() {
            
        }
        
        public DCON_Retrieve_Territory_Tree_WS_Object(String UserId, Boolean RetrieveAllRecords) {
            this.UserId = UserId;
            this.RetrieveAllRecords = RetrieveAllRecords;
        }
    }*/
   /*   public class getTechDetails_Object {
        public List<String> lstTechIds;

        
        public getTechDetails_Object() {
            
        }
        
        public getTechDetails_Object(List<String> lstTechIds) {
            this.lstTechIds = lstTechIds;
        }
    } */
    
    /* public class SFM_getObjectFieldList_WS_Object {
        public String userId;
        public String groupId;
        public String profileId;
        public List<SFM_WrapperDef.SFM_StringMap> stringMap;

        
        public SFM_getObjectFieldList_WS_Object() {
            
        }
        
        public SFM_getObjectFieldList_WS_Object(String userId,String groupId,String profileId,List<SFM_WrapperDef.SFM_StringMap> stringMap) {
            this.userId = userId;
            this.groupId = groupId;
            this.profileId = profileId;
            this.stringMap = stringMap;
        }
    } */

 
    
   /*  public class DCON_WO_Get_Dependency_Details_WS_Object {
        public List<Event> lstSFEvent;
        public List<SVMXC__SVMX_Event__c> lstSVMXEvent;
        public String timeZone;
        public String userId;
        public List<String> listWOIds;

        
        public DCON_WO_Get_Dependency_Details_WS_Object() {
            
        }
        
        public DCON_WO_Get_Dependency_Details_WS_Object(List<Event> lstSFEvent, List<SVMXC__SVMX_Event__c> lstSVMXEvent, String timeZone,String userId,List<String> listWOIds){
            this.lstSFEvent = lstSFEvent;
            this.lstSVMXEvent = lstSVMXEvent;
            this.timeZone = timeZone;
            this.userId = userId;
            this.listWOIds = listWOIds;
        }
    } */
    /*  */
    /*public class DCON_Update_User_Settings_WS_Object {
        public String UserId;
        public String UserSettings;
        
        public DCON_Update_User_Settings_WS_Object() {
            
        }
        
        public DCON_Update_User_Settings_WS_Object(String UserId, String UserSettings){
            
            XmlSerializer serializer = new XmlSerializer();
            String jsonString = serializer.jsonToXML(UserSettings);
            system.debug('jsonString :' +jsonString );
            this.UserId = UserId;
            this.UserSettings =  UserSettings;
               
            
        }
    }*/
    
  /*  public class INTF_getViewData_WS_1_Object {
        public String objectname;
        public String viewid;
        public String recordlimit;
        public String latitude;
        public String longitude;
        public String radius;
        
        public INTF_getViewData_WS_1_Object() {
            
        }
        
        public INTF_getViewData_WS_1_Object(String latitude,String longitude,String objectname,String radius,String recordlimit,String viewid) {
            this.objectname = objectname;
            this.viewid = viewid;
            this.recordlimit = recordlimit;
            this.latitude = latitude;
            this.longitude = longitude;
            this.radius = radius;
        }
    } */ 
   /* public class diployUserSettingObject {
        public List<string> settings;
        public List<string> userids;
        
        public diployUserSettingObject() {
            
        }
        
        public diployUserSettingObject(List<string> settings,List<string> userids) {
            
            this.settings = settings;
            system.debug('settings :'+this.settings);
            this.userids = userids;
            system.debug('userids :'+this.userids);
        }
    }*/
    
}