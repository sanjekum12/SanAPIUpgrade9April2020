@isTest
public class DCX_Utils_UT {

  @isTest static void getDateTimeInTimezone_test() {
    DCX_Utils utils = new DCX_Utils();
    utils.getDateTimeInTimezone(system.today(), Time.newInstance(4, 2, 3, 4), 'Asia/Kolkata');
  }

  @isTest static void SVMX_getAllFieldMap_test() {
    Schema.SObjectType objTSVMXEvent = SVMX_Event__c.sObjectType;
    Map<String,Schema.SObjectField> fldMap = objTSVMXEvent.getDescribe().fields.getMap();
    DCX_Utils utils = new DCX_Utils();
    utils.SVMX_getAllFieldMap(fldMap);
  }

  @isTest static void SVMX_getGlobalReferenceMap_test() {
    DCX_Utils utils = new DCX_Utils();
    utils.SVMX_getGlobalReferenceMap();
  }

  @isTest static void SVMX_getReferenceFields_test() {
    DCX_Utils utils = new DCX_Utils();
    Schema.SObjectType objTSVMXEvent = SVMXC__Service_Order__c.sObjectType;
    Map<String,Schema.SObjectField> fldMap = objTSVMXEvent.getDescribe().fields.getMap();
    utils.SVMX_getReferenceFields(fldMap, true);
  }

  @isTest static void getBHStartEndDateTime_test() {
    // Get the default business hours
    BusinessHours bh = [SELECT CreatedById,CreatedDate,FridayEndTime,FridayStartTime,Id,IsActive,LastModifiedById,LastModifiedDate,LastViewedDate,MondayEndTime,MondayStartTime,Name,SaturdayEndTime,SaturdayStartTime,SundayEndTime,SundayStartTime,SystemModstamp,ThursdayEndTime,ThursdayStartTime,TimeZoneSidKey,TuesdayEndTime,TuesdayStartTime,WednesdayEndTime,WednesdayStartTime FROM BusinessHours WHERE IsDefault = true];
    DCX_Utils.getBHStartEndDateTime('Asia/Kolkata', system.today(), bh);
  }

  @isTest static void doTZConversion_test() {
    DCX_Utils.doTZConversion(DateTime.now(), 'Asia/Kolkata', 'Pacific/Auckland');
  }

}