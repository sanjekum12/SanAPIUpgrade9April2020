@isTest
private with sharing class PORD_CreateRMALines_UT
{
    private static SVMXC.PORD_CreateRMALines ControllerObj1;
    private static Account account;
    private static Contact contact ;
    private static Case case1;
    private static Product2  prodShpLine,prod;      
    private static Pricebook2 pbStd; 
    private static PricebookEntry pbe,pbe1;
    private static SVMXC__Site__c sourceLocation,destLocation;
    private static RecordType rtRMA,rtRMALine,rtRR ;
    private static SVMXC__RMA_Shipment_Order__c rmaObject1,rmaObject2,rmaObject3; 
    private static SVMXC__RMA_Shipment_Line__c  rmaLineObject1,rmaLineObject2,rmaLineObject3,rmaLineObject4,rmaLineObject5;
    private static List<SVMXC__RMA_Shipment_Line__c> shpLineArray = new List<SVMXC__RMA_Shipment_Line__c>();
    private static SVMXC__Installed_Product__c IBObject ;
    private static SVMXC__Service_Order__c svo;
    private static SVMXC__Service_Order_Line__c svoRRLine1;
    
/*******************************************************************************************************************
Variables for Configuration Setting Data
*******************************************************************************************************************/
   
    private static List<RecordType> AllRecordTypes  = new List<RecordType>();
 
    
/*******************************************************************************************************************
Test Method
*******************************************************************************************************************/
    
    static testMethod void PORD_CreateRMALines_UT_Test()
        {
        try{     
            try{  
                
            AllRecordTypes =[SELECT Id , Name,SobjectType  FROM RecordType];
            } catch (Exception e){ }// System.debug(e.getMessage());        }    
             
        account = new Account(
                                        Name ='Account',
                                        ShippingStreet='ABC',
                                        ShippingCity='PQR ',
                                        ShippingState = 'XYZ',
                                        ShippingPostalCode='111',
                                        ShippingCountry='XYZ',
                                        BillingStreet='ABC',
                                        BillingCity='PQR ',
                                        BillingState = 'XYZ',
                                        BillingPostalCode='111',
                                        BillingCountry='XYZ'
                                        ); 
        insert account;
        System.assertEquals('Account', account.Name);

        contact = new Contact(LastName='Last',AccountId =account.Id,Email='svmxmailfortest@servicemax.com');
        insert contact;
        System.assertEquals('Last', contact.LastName);
        
        
        case1 = new Case(Status ='New', Priority = 'Medium', 
                                        Origin = 'Email',                                        
                                                                                    
                                        ContactId =contact.Id,
                                        AccountId=account.Id                                         
                                        ); 
        insert case1; 
        System.assertEquals('New', case1.Status);
        
        contact = new Contact(LastName='Last',AccountId =account.Id,Email='svmxmailfortest@servicemax.com',
                                        OtherStreet = 'Other', OtherState ='CA', OtherPostalCode ='95051', OtherCountry ='USA',OtherCity='ABC',
                                        MailingStreet = 'Other', MailingState ='CA', MailingPostalCode ='95051', MailingCountry ='USA',MailingCity='ABC');
        insert contact;
        System.assertEquals('Last', contact.LastName);
        
    
        prodShpLine =     new Product2(
                                       Name = 'prodShpLine', 
                                       ProductCode = '1235', 
                                       Family = 'Accessory', 
                                       SVMXC__Inherit_Parent_Warranty__c =True 
                                       );
        insert prodShpLine;
        System.assertEquals('prodShpLine', prodShpLine.Name);
     
        prod =       new Product2(
                                       Name = 'Prod', 
                                       ProductCode = '1235', 
                                       Family = 'Accessory', 
                                       SVMXC__Inherit_Parent_Warranty__c =True
                                       );
        insert prod;
        System.assertEquals('Prod', prod.Name);


        for ( RecordType rectype:AllRecordTypes)
            {
            if ((rectype.Name =='RMA')&&(rectype.SobjectType =='SVMXC__RMA_Shipment_Order__c'))                
                rtRMA = rectype;
                
            }
        for ( RecordType rectype:AllRecordTypes)
            {
            if ((rectype.Name =='RMA')&&(rectype.SobjectType =='SVMXC__RMA_Shipment_Line__c'))             
                rtRMALine = rectype;
                
            }
        for ( RecordType rectype:AllRecordTypes)
            {
            if ((rectype.Name =='Request/Receipt')&&(rectype.SobjectType =='SVMXC__Service_Order_Line__c'))             
                rtRR = rectype;
                
            }   
     sourceLocation = new SVMXC__Site__c(
                                        SVMXC__Zip__c ='90909090',
                                        SVMXC__Street__c ='ABC',
                                        SVMXC__State__c ='ABC',
                                        SVMXC__Country__c ='ABC',
                                        SVMXC__City__c ='ABC',
                                        SVMXC__Account__c=account.Id
                                        );
     insert sourceLocation;
     System.assertEquals('90909090', sourceLocation.SVMXC__Zip__c);
    
    destLocation = new SVMXC__Site__c(
                                        SVMXC__Zip__c ='90909090',
                                        SVMXC__Street__c ='ABC',
                                        SVMXC__State__c ='ABC',
                                        SVMXC__Country__c ='ABC',
                                        SVMXC__City__c ='ABC',
                                        SVMXC__Account__c=account.Id
                                        );
    insert destLocation;
    System.assertEquals('ABC', destLocation.SVMXC__Street__c);
       
   
    rmaObject1 = new SVMXC__RMA_Shipment_Order__c(
                                             SVMXC__Source_Location__c =sourceLocation.Id, 
                                             SVMXC__Expected_Delivery_Date__c =System.today(), 
                                             SVMXC__Destination_Location__c=destLocation.Id, 
                                             SVMXC__Contact__c =contact.Id, 
                                             SVMXC__Company__c=account.Id, 
                                             SVMXC__Case__c =case1.Id, 
                                             RecordTypeId = rtRMA.Id,
                                              
                                             SVMXC__Order_Status__c='Open'                                           
                                             );
    insert rmaObject1;
    System.assertEquals('Open', rmaObject1.SVMXC__Order_Status__c);

     rmaObject2 = new SVMXC__RMA_Shipment_Order__c(
                                             SVMXC__Source_Location__c =sourceLocation.Id, 
                                             SVMXC__Expected_Delivery_Date__c =System.today(), 
                                             SVMXC__Destination_Location__c=destLocation.Id, 
                                             SVMXC__Contact__c =contact.Id, 
                                             SVMXC__Company__c=account.Id, 
                                             SVMXC__Case__c =case1.Id, 
                                             RecordTypeId = rtRMA.Id,
                                              
                                             SVMXC__Order_Status__c='Open'                                           
                                             );
    insert rmaObject2;
   
    
    rmaObject3 = new SVMXC__RMA_Shipment_Order__c(
                                             SVMXC__Source_Location__c =sourceLocation.Id, 
                                             SVMXC__Expected_Delivery_Date__c =System.today(), 
                                             SVMXC__Destination_Location__c=destLocation.Id, 
                                             SVMXC__Contact__c =contact.Id, 
                                             SVMXC__Company__c=account.Id, 
                                             SVMXC__Case__c =case1.Id, 
                                             RecordTypeId = rtRMA.Id,
                                              
                                             SVMXC__Order_Status__c='Open'                                           
                                             );
    insert rmaObject3;
    
    
   
    rmaLineObject1 = new SVMXC__RMA_Shipment_Line__c(
                                                    SVMXC__RMA_Shipment_Order__c=rmaObject1.Id , 
                                                    RecordTypeId = rtRMALine.Id ,
                                                    SVMXC__Product__c = prodShpLine.Id,
                                                    SVMXC__Line_Status__c ='Open',
                                                    SVMXC__Select__c = true,                                                    
                                                    SVMXC__Actual_Quantity2__c =3
                                                    ); 
    insert rmaLineObject1;
    
  
  
  
/*******************************************************************************************************************
Configuring Standard Price for Product
*******************************************************************************************************************/
      try{
          pbStd = [select name, IsActive from Pricebook2 where IsStandard = true limit 1 ];
          pbStd.IsActive = true;
          update pbStd ;
      } catch (Exception e){}

   /* Create a pricebook entries. */

    if(pbStd != null ){
        pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbStd.id;
        pbe.Product2Id   = prod.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 10;    
        pbe.UseStandardPrice = false;   
        insert pbe;    
   }
        
    svo = new SVMXC__Service_Order__c (
                                        SVMXC__Case__c = case1.Id ,
                                        SVMXC__Company__c = account.Id , 
                                        SVMXC__Contact__c =contact.Id, 
                                        SVMXC__Order_Status__c = 'Open',
                                        SVMXC__Priority__c ='Medium',
                                        SVMXC__Order_Type__c='Field Service'
                                        );
    insert svo;
    svoRRLine1 = new SVMXC__Service_Order_Line__c(
                                        SVMXC__Service_Order__c = svo.Id, 
                                         
                                        RecordTypeId = rtRR.Id,
                                        SVMXC__Product__c = prod.Id);
    insert svoRRLine1;

        Test.startTest();
/*******************************************************************************************************************
Scenario to Launch Page with url parameters id 
*******************************************************************************************************************/
       PageReference pageRef1 = new PageReference('Page.SVMXC.PORD_CreateRMALines');
       pageRef1.getParameters().put('rid',rmaObject1.Id);
       Test.setCurrentPageReference(pageRef1); 
       ControllerObj1 = new SVMXC.PORD_CreateRMALines();
        ControllerObj1.getUserLocaleKey();
    	ControllerObj1.getUserID();
    	ControllerObj1.getUserOrgID();

/*******************************************************************************************************************
Scenario to qualify the method setAddress() with different Address Types
*******************************************************************************************************************/
      ControllerObj1.SelectedAddressType = 'Account Shipping Address';
      ControllerObj1.setAddressForSourceLoc();
      ControllerObj1.SelectedAddressType = 'Account Billing Address';      
      ControllerObj1.setAddressForTargetLoc();
      ControllerObj1.SelectedAddressType = 'Contact Mailing Address';
      ControllerObj1.SelectedAddressType = 'Contact Other Address';
      ControllerObj1.SelectedAddressType = 'Installed Product Address';
      ControllerObj1.SelectedAddressType = 'I will Enter a Location/Address';
      ControllerObj1.SelectedAddressType = null;
      
      SVMXC__RMA_Shipment_Order__c PO1 = new SVMXC__RMA_Shipment_Order__c();
      
      PO1 = ControllerObj1.getSourcePO();
      PO1.SVMXC__Source_Location__c = sourceLocation.Id;
      ControllerObj1.setSourcePO(PO1);
      //ControllerObj1.setAddress();
     

/*******************************************************************************************************************
Scenario to Add a new Line to Shipment Order
*******************************************************************************************************************/
        
        
        List<SVMXC__RMA_Shipment_Line__c> objArray1 = new List<SVMXC__RMA_Shipment_Line__c> ();
        objArray1.add(rmaLineObject1);
        ControllerObj1.setNewRMAShpipmentLines( objArray1);
    
        PageReference addLineRef = ControllerObj1.AddLine();
        


/*******************************************************************************************************************
Scenario to Remove a new Line to Shipment Order
*******************************************************************************************************************/

        PageReference removeLineRef = ControllerObj1.RemoveLine();
        



/*******************************************************************************************************************
Scenario to populate Product and Product Price for  Line in Shipment Order
*******************************************************************************************************************/

        IBObject = new SVMXC__Installed_Product__c(
                    Name = 'Test IB1',
                    SVMXC__Status__c = 'Installed',
                    SVMXC__Product__c = prod.Id,
                    SVMXC__Date_Installed__c = System.Today(),
                    SVMXC__Contact__c = contact.Id,
                    SVMXC__Company__c = account.Id
                    );
        insert IBObject;
        
        case1.SVMXC__Component__c = IBObject.Id;
        update case1;
        
        svo.SVMXC__Component__c = IBObject.Id;
        update svo;
        
        rmaLineObject2 = new SVMXC__RMA_Shipment_Line__c(
                                                    SVMXC__RMA_Shipment_Order__c=rmaObject1.Id , 
                                                    RecordTypeId = rtRMALine.Id ,
                                                    Serial_Number__c = IBObject.Id,
                                                    SVMXC__Line_Status__c ='Open',
                                                    SVMXC__Select__c = true,
                                                    SVMXC__Actual_Quantity2__c =3
                                                    ); 
       
        
        rmaLineObject3 = new SVMXC__RMA_Shipment_Line__c(
                                                    SVMXC__RMA_Shipment_Order__c=rmaObject1.Id , 
                                                    RecordTypeId = rtRMALine.Id ,
                                                    Serial_Number__c = IBObject.Id,
                                                    SVMXC__Product__c = prod.Id,
                                                    SVMXC__Line_Status__c ='Open',
                                                    SVMXC__Select__c = true,
                                                    SVMXC__Actual_Quantity2__c =3,
                                                    SVMXC__Use_Price_From_Pricebook__c = true
                                                    ); 
        //insert rmaLineObject3;//DO NOT INSERT HERE AS THE LINE IS INSERTED THROUGH CONTROLLER
        
    
        List<SVMXC__RMA_Shipment_Line__c> objArray2 = new List<SVMXC__RMA_Shipment_Line__c> ();
        objArray2.add(rmaLineObject2);
        objArray2.add(rmaLineObject3);
        
        ControllerObj1.setNewRMAShpipmentLines( objArray2);
        
        PageReference updateLineRecord = ControllerObj1.UpdateLineRecord();


/*******************************************************************************************************************
Scenario to Create Shipment Order with Lines
*******************************************************************************************************************/
        PageReference clearWarnings   = ControllerObj1.ClearWarnings();
        

/*******************************************************************************************************************
Scenario to display Warnings
*******************************************************************************************************************/

        ControllerObj1.AddToWarningsList('Msg');
        ControllerObj1.getshowWarnings();
        ControllerObj1.DisplayErrorsNWarnings();


/*******************************************************************************************************************
Scenario to Cancel the creation of Shipment Order with Lines
*******************************************************************************************************************/
        PageReference cancel   = ControllerObj1.Cancel();

/*******************************************************************************************************************
Scenario to hide and display PageBlockTable
*******************************************************************************************************************/
        
        ControllerObj1.setNewRMAShpipmentLines( objArray2);
        Boolean showTableCols = ControllerObj1.getDisplayTableColumns();
        
        List<SVMXC__RMA_Shipment_Line__c> objArray3 = new List<SVMXC__RMA_Shipment_Line__c> (); 
        
        ControllerObj1.setNewRMAShpipmentLines( objArray3);     
        Boolean hideTableCols = ControllerObj1.getDisplayTableColumns();
       
/*******************************************************************************************************************
Scenario to qualify regular set & get methods
*******************************************************************************************************************/
      ControllerObj1.setSourcePO(ControllerObj1.getSourcePO());
      List<SVMXC__RMA_Shipment_Line__c> NewShipmentLines = ControllerObj1.getNewRMAShpipmentLines();      
      Boolean chkAllLines = ControllerObj1.getCheckAllLines();
      ControllerObj1.setCheckAllLines(true);
      ControllerObj1.setshowWarnings(true);
      List<String> strList1 = ControllerObj1.getErrorsList();
      ControllerObj1.AddToWarningsList('msg');
      List<String> strList2 = ControllerObj1.getWarningsList();
      Boolean dblMesg = ControllerObj1.getDisplayBlockLevelMessage();
      Boolean dForm = ControllerObj1.getDisplayForm();
      String strAddType = ControllerObj1.getSelectedAddressType() ;
      ControllerObj1.setSelectedAddressType(strAddType);
      
/*******************************************************************************************************************
Code to modify  Current Settings and applying different Scenarios
*******************************************************************************************************************/
        //Clearing all the Settings
        ControllerObj1.AllSubModuleSettings.clear();
        ControllerObj1.ValidateAllSettings();
        PageReference pageRef3 = new PageReference('Page.SVMXC.PORD_CreateRMALines');
        pageRef3.getParameters().put('rid',rmaObject1.Id);
        Test.setCurrentPageReference(pageRef1); 
       
       //Populating different values for Settings
       //Setng_usePriceFromPriceBook   -SET010
       //Setng_RMAPriceBookName - SET011
    system.assert(ControllerObj1.getTAG001()!=null,'TAG001 assertion failed');
    system.assert(ControllerObj1.getTAG003()!=null,'TAG003 assertion failed');
    system.assert(ControllerObj1.getTAG004()!=null,'TAG004 assertion failed');
    system.assert(ControllerObj1.getTAG005()!=null,'TAG005 assertion failed');
    system.assert(ControllerObj1.getTAG006()!=null,'TAG006 assertion failed');
    system.assert(ControllerObj1.getTAG007()!=null,'TAG007 assertion failed');
    system.assert(ControllerObj1.getTAG008()!=null,'TAG008 assertion failed');
    system.assert(ControllerObj1.getTAG009()!=null,'TAG009 assertion failed');
    system.assert(ControllerObj1.getTAG010()!=null,'TAG010 assertion failed');
    system.assert(ControllerObj1.getTAG017()!=null,'TAG017 assertion failed');
    system.assert(ControllerObj1.getTAG018()!=null,'TAG018 assertion failed');
    system.assert(ControllerObj1.getTAG024()!=null,'TAG024 assertion failed');
    system.assert(ControllerObj1.getTAG025()!=null,'TAG025 assertion failed');
    system.assert(ControllerObj1.getTAG036()!=null,'TAG036 assertion failed');
    system.assert(ControllerObj1.getTAG039()!=null,'TAG039 assertion failed');
    system.assert(ControllerObj1.getTAG043()!=null,'TAG043 assertion failed');
    system.assert(ControllerObj1.getTAG044()!=null,'TAG044 assertion failed');
    system.assert(ControllerObj1.getTAG045()!=null,'TAG045 assertion failed');
    system.assert(ControllerObj1.getTAG046()!=null,'TAG046 assertion failed');
    system.assert(ControllerObj1.getTAG049()!=null,'TAG049 assertion failed');
    system.assert(ControllerObj1.getTAG050()!=null,'TAG050 assertion failed');
    system.assert(ControllerObj1.getTAG051()!=null,'TAG051 assertion failed');
    system.assert(ControllerObj1.getHLPURL()!=null,'HLPURL assertion failed');
        
    ControllerObj1.AllSubModuleSettings.put('SET010','TRUE');
    ControllerObj1.AllSubModuleSettings.put('SET011',null);     
    ControllerObj1.ValidateAllSettings();
    ControllerObj1.AllSubModuleSettings.put('SET010','FALSE');      
    ControllerObj1.AllSubModuleSettings.put('SET011','No Price Book');
    ControllerObj1.ValidateAllSettings();
    test.stopTest();  
     
    }catch(exception Ex){}
   }//Test Method
}