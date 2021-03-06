public with sharing class DispatchConsole_DCH{

    public String UserTimeFormate { get; set; }
  public String baseURL {get;set;}
  public String nameSpace {get;set;}
  public String isOptimaxLicenseEnabled1 {get;set;}
  public String workOrderId {get;set;}
  public String userId {get;set;}
  public String workOrderName {get;set;}
  public String UserTimeFormat {get;set;}
  //public DateTime date_time { get; set; }

  public DispatchConsole_DCH() {
    Organization org = [select InstanceName, NamespacePrefix, Name, isSandbox from Organization];
    ApexClass cs = [select NamespacePrefix from ApexClass where Name = 'DispatchConsole_DCH'];
    baseURL = 'https://'+org.InstanceName+'.salesforce.com';
    nameSpace = cs.NamespacePrefix;
    //dateTimeFormat = UserInfo.dateTimeFormat;
    userId = UserInfo.getuserid();
    String strActiveProvider = WSCH_CommonUtils.getActiveRealTimeOptimizationEngine();
    isOptimaxLicenseEnabled1 = 'false';
    if(String.isNotBlank(strActiveProvider) && strActiveProvider.equals('OPTIMAXECO'))
    {
      isOptimaxLicenseEnabled1 = 'true';  
    }
    String wid = System.currentPageReference().getParameters().get('woId');
    if(wid != null)
      workOrderId = wid;
      
    String wName = System.currentPageReference().getParameters().get('wno');
    if(wName != null)
      workOrderName = wName ;
  }
  public string getUserTimezone(){
        return UserInfo.getTimeZone().getID();
    }
    
    public String getTimeFormat(){
    Map<String, String> mappedValues = new Map<String, String>(); //map for holding locale to datetime format
        mappedValues = MapValues(); //populate the map with all the locale specific datetime formats
        String user_locale = UserInfo.getLocale(); //grab the locale of the user
        UserTimeFormat = 'h:mm a'; //variable for the datetime format defaulted to the US format
        if (mappedValues.containsKey(user_locale)) { //if the map contains the correct datetime format
            UserTimeFormat = mappedValues.get(user_locale); //grab the datetime format for the locale
        }
        //UserTimeFormat = date_time.format(datetime_format); //create a string with the proper format
        return UserTimeFormat;
        
   
   }

    public String getTAG028() {return System.Label.DCON001_TAG028;} //Loading user settings    
    public String getTAG029() {return System.Label.DCON001_TAG029;} //Loading Configuration   
    public String getTAG030() {return System.Label.DCON001_TAG030;} //Loading Work Orders    
    public String getTAG031() {return System.Label.DCON001_TAG031;} //Loading Teams and Territories    
    public String getTAG032() {return System.Label.DCON001_TAG032;} //Loading Technicians    
    public String getTAG033() {return System.Label.DCON001_TAG033;} //Loading Events
    
    private Map<String, String> MapValues() {
        Map<String, String> locale_map = new Map<String, String>(); //holds the locale to timedate formats
        locale_map.put('af_ZA', 'yyyy-MM-dd HH:mm');
        locale_map.put('ar_AE', 'd/M/yyyy h:mm a');
        locale_map.put('ar_BH', 'd/M/yyyy h:mm a');
        locale_map.put('ar_DZ', 'd/M/yyyy h:mm a');
        locale_map.put('ar_EG', 'd/M/yyyy h:mm a');
        locale_map.put('ar_IQ', 'd/M/yyyy h:mm a');
        locale_map.put('ar_JO', 'dd/MM/yyyy hh:mm a');
        locale_map.put('ar_KW', 'd/M/yyyy h:mm a');
        locale_map.put('ar_LB', 'dd/MM/yyyy hh:mm a');
        locale_map.put('ar_LY', 'd/M/yyyy h:mm a');
        locale_map.put('ar_MA', 'd/M/yyyy HH:mm');
        locale_map.put('ar_OM', 'd/M/yyyy h:mm a');
        locale_map.put('ar_QA', 'd/M/yyyy h:mm a');
        locale_map.put('ar_SA', 'dd/MM/yyyy hh:mm a');
        locale_map.put('ar_SD', 'd/M/yyyy h:mm a');
        locale_map.put('ar_SY', 'dd/MM/yyyy hh:mm a');
        locale_map.put('ar_TN', 'd/M/yyyy h:mm a');
        locale_map.put('ar_YE', 'd/M/yyyy h:mm a');
        locale_map.put('az_AZ', 'dd.MM.yyyy HH:mm');
        locale_map.put('be_BY', 'd.M.yyyy H.mm');
        locale_map.put('bg_BG', 'dd.MM.yyyy HH:mm');
        locale_map.put('bn_BD', 'd/M/yyyy h:mm a');
        locale_map.put('bn_IN', 'd/M/yyyy h:mm a');
        locale_map.put('bs_BA', 'd.M.yyyy. HH:mm');
        locale_map.put('ca_ES', 'dd/MM/yyyy HH:mm');
        locale_map.put('ca_ES_EURO', 'dd/MM/yyyy HH:mm');
        locale_map.put('cs_CZ', 'd.M.yyyy H:mm');
        locale_map.put('cy_GB', 'dd/MM/yyyy HH:mm');
        locale_map.put('da_DK', 'dd-MM-yyyy HH:mm');
        locale_map.put('de_AT', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_AT_EURO', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_BE', 'dd.MM.yyyy, HH:mm');
        locale_map.put('de_DE', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_DE_EURO', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_LU', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_LU_EURO', 'dd.MM.yyyy HH:mm');
        locale_map.put('de_CH', 'dd.MM.yyyy HH:mm');
        locale_map.put('dz_BT', 'yyyy-MM-dd ཆུ་ཚོད་ h སྐར་མ་ mm a');
        locale_map.put('el_GR', 'd/M/yyyy h:mm a');
        locale_map.put('en_AG', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_AU', 'd/MM/yyyy h:mm a');
        locale_map.put('en_BB', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_BS', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_BZ', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_BM', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_BW', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_CA', 'dd/MM/yyyy h:mm a');
        locale_map.put('en_CM', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_KY', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_ER', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_FK', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_FJ', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_GM', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_GH', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_GI', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_GY', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_HK', 'd/M/yyyy, h:mm a');
        locale_map.put('en_IN', 'd/M/yyyy h:mm a');
        locale_map.put('en_ID', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_IE', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_IE_EURO', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_JM', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_KE', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_LR', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_MG', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_MW', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_MY', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_MU', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_NA', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_NZ', 'd/MM/yyyy h:mm a');
        locale_map.put('en_NG', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_PK', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_PG', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_PH', 'M/d/yyyy h:mm a');
        locale_map.put('en_RW', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_SH', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_WS', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_SC', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_SL', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_SG', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_SX', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_SB', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_ZA', 'yyyy/MM/dd h:mm a');
        locale_map.put('en_SZ', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_TZ', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_TO', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_TT', 'dd/MM/yyyy, h:mm a');
        locale_map.put('en_UG', 'dd/MM/yyyy, HH:mm');
        locale_map.put('en_GB', 'dd/MM/yyyy HH:mm');
        locale_map.put('en_US', 'M/d/yyyy h:mm a');
        locale_map.put('en_VU', 'dd/MM/yyyy, h:mm a');
        locale_map.put('es_AR', 'dd/MM/yyyy HH:mm');
        locale_map.put('es_BO', 'dd-MM-yyyy hh:mm a');
        locale_map.put('es_CL', 'dd-MM-yyyy H:mm');
        locale_map.put('es_CO', 'd/MM/yyyy hh:mm a');
        locale_map.put('es_CR', 'dd/MM/yyyy hh:mm a');
        locale_map.put('es_CU', 'd/M/yyyy HH:mm');
        locale_map.put('es_DO', 'dd/MM/yyyy hh:mm a');
        locale_map.put('es_EC', 'dd/MM/yyyy H:mm');
        locale_map.put('es_ES', 'd/MM/yyyy H:mm');
        locale_map.put('es_ES_EURO', 'd/MM/yyyy H:mm');
        locale_map.put('es_GT', 'd/MM/yyyy hh:mm a');
        locale_map.put('es_HN', 'MM-dd-yyyy hh:mm a');
        locale_map.put('es_MX', 'd/MM/yyyy hh:mm a');
        locale_map.put('es_NI', 'MM-dd-yyyy hh:mm a');
        locale_map.put('es_PA', 'MM/dd/yyyy hh:mm a');
        locale_map.put('es_PE', 'dd/MM/yyyy hh:mm a');
        locale_map.put('es_PR', 'MM-dd-yyyy hh:mm a');
        locale_map.put('es_PY', 'dd/MM/yyyy hh:mm a');
        locale_map.put('es_SV', 'MM-dd-yyyy hh:mm a');
        locale_map.put('es_US', 'M/d/yyyy h:mm a');
        locale_map.put('es_UY', 'dd/MM/yyyy hh:mm a');
        locale_map.put('es_VE', 'dd/MM/yyyy hh:mm a');
        locale_map.put('et_EE', 'd.MM.yyyy H:mm');
        locale_map.put('eu_ES', 'yyyy/M/d HH:mm');
        locale_map.put('fa_IR', 'yyyy/M/d،\u200f H:mm');
        locale_map.put('fi_FI', 'd.M.yyyy H:mm');
        locale_map.put('fi_FI_EURO', 'd.M.yyyy H:mm');
        locale_map.put('fr_BE', 'd/MM/yyyy H:mm');
        locale_map.put('fr_CA', 'yyyy-MM-dd HH:mm');
        locale_map.put('fr_KM', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_FR', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_FR_EURO', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_GN', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_HT', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_LU', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_MR', 'dd/MM/yyyy h:mm a');
        locale_map.put('fr_MC', 'dd/MM/yyyy HH:mm');
        locale_map.put('fr_CH', 'dd.MM.yyyy HH:mm');
        locale_map.put('fr_WF', 'dd/MM/yyyy HH:mm');
        locale_map.put('ga_IE', 'dd/MM/yyyy HH:mm');
        locale_map.put('gu_IN', 'd/M/yyyy hh:mm a');
        locale_map.put('hi_IN', 'd/M/yyyy h:mm a');
        locale_map.put('hr_HR', 'dd.MM.yyyy. HH:mm');
        locale_map.put('hu_HU', 'yyyy.MM.dd. H:mm');
        locale_map.put('hy_AM', 'dd.MM.yyyy, HH:mm');
        locale_map.put('in_ID', 'dd/MM/yyyy H:mm');
        locale_map.put('is_IS', 'd.M.yyyy HH:mm');
        locale_map.put('it_CH', 'dd.MM.yyyy HH:mm');
        locale_map.put('it_IT', 'dd/MM/yyyy H.mm');
        locale_map.put('iw_IL', 'HH:mm dd/MM/yyyy');
        locale_map.put('ja_JP', 'yyyy/MM/dd H:mm');
        locale_map.put('ka_GE', 'dd.MM.yyyy, HH:mm');
        locale_map.put('kk_KZ', 'dd.MM.yyyy, HH:mm');
        locale_map.put('km_KH', 'd/M/yyyy, h:mm a');
        locale_map.put('kn_IN', 'd/M/yyyy hh:mm a');
        locale_map.put('ko_KP', 'yyyy. M. d. a h:mm');
        locale_map.put('ko_KR', 'yyyy. M. d a h:mm');
        locale_map.put('ky_KG', 'd/M/yyyy HH:mm');
        locale_map.put('lb_LU', 'dd.MM.yyyy HH:mm');
        locale_map.put('lo_LA', 'd/M/yyyy, H:mm');
        locale_map.put('lt_LT', 'yyyy.M.d HH.mm');
        locale_map.put('lu_CD', 'd/M/yyyy HH:mm');
        locale_map.put('lv_LV', 'dd.MM.yyyy HH:mm');
        locale_map.put('mk_MK', 'd.M.yyyy HH:mm');
        locale_map.put('ml_IN', 'd/M/yyyy h:mm a');
        locale_map.put('mr_IN', 'd/M/yyyy, h:mm a');
        locale_map.put('ms_BN', 'd/MM/yyyy, h:mm a');
        locale_map.put('ms_MY', 'dd/MM/yyyy h:mm a');
        locale_map.put('mt_MT', 'dd/MM/yyyy HH:mm');
        locale_map.put('my_MM', 'dd-MM-yyyy B H:mm');
        locale_map.put('ne_NP', 'yyyy/M/d, HH:mm');
        locale_map.put('nl_AW', 'dd-MM-yyyy HH:mm');
        locale_map.put('nl_BE', 'd/MM/yyyy H:mm');
        locale_map.put('nl_NL', 'd-M-yyyy H:mm');
        locale_map.put('nl_SR', 'dd-MM-yyyy HH:mm');
        locale_map.put('no_NO', 'dd.MM.yyyy HH:mm');
        locale_map.put('pl_PL', 'dd.MM.yyyy HH:mm');
        locale_map.put('ps_AF', 'GGGGG yyyy/M/d H:mm');
        locale_map.put('pt_AO', 'dd/MM/yyyy, HH:mm');
        locale_map.put('pt_BR', 'dd/MM/yyyy HH:mm');
        locale_map.put('pt_CV', 'dd/MM/yyyy, HH:mm');
        locale_map.put('pt_MZ', 'dd/MM/yyyy, HH:mm');
        locale_map.put('pt_PT', 'dd-MM-yyyy H:mm');
        locale_map.put('pt_ST', 'dd/MM/yyyy, HH:mm');
        locale_map.put('rm_CH', 'dd-MM-yyyy HH:mm');
        locale_map.put('rn_BI', 'd/M/yyyy HH:mm');
        locale_map.put('ro_MD', 'dd.MM.yyyy, HH:mm');
        locale_map.put('ro_RO', 'dd.MM.yyyy HH:mm');
        locale_map.put('ru_KZ', 'dd.MM.yyyy, H:mm');
        locale_map.put('ru_RU', 'dd.MM.yyyy H:mm');
        locale_map.put('sh_BA', 'dd.MM.yyyy. HH:mm');
        locale_map.put('sh_CS', 'dd.MM.yyyy. HH:mm');
        locale_map.put('sh_ME', 'dd.MM.yyyy. HH:mm');
        locale_map.put('sk_SK', 'd.M.yyyy H:mm');
        locale_map.put('sl_SI', 'd.M.yyyy H:mm');
        locale_map.put('so_DJ', 'dd/MM/yyyy h:mm a');
        locale_map.put('so_SO', 'dd/MM/yyyy h:mm a');
        locale_map.put('sr_BA', 'yyyy-MM-dd HH:mm');
        locale_map.put('sr_CS', 'd.M.yyyy. HH.mm');
        locale_map.put('sr_RS', 'd.M.yyyy. HH.mm');
        locale_map.put('sq_AL', 'yyyy-MM-dd h.mm.a');
        locale_map.put('sv_SE', 'yyyy-MM-dd HH:mm');
        locale_map.put('sw_KE', 'dd/MM/yyyy, HH:mm');
        locale_map.put('ta_IN', 'd/M/yyyy, a h:mm');
        locale_map.put('ta_LK', 'd/M/yyyy, HH:mm');
        locale_map.put('te_IN', 'dd-MM-yyyy h:mm a');
        locale_map.put('tg_TJ', 'dd/MM/yyyy HH:mm');
        locale_map.put('th_TH', 'd/M/yyyy, H:mm น.');
        locale_map.put('ti_ET', 'dd/MM/yyyy h:mm a');
        locale_map.put('tl_PH', 'M/d/yyyy h:mm a');
        locale_map.put('tr_TR', 'dd.MM.yyyy HH:mm');
        locale_map.put('uk_UA', 'dd.MM.yyyy H:mm');
        locale_map.put('ur_PK', 'd/M/yyyy h:mm a');
        locale_map.put('uz_LATN_UZ', 'dd/MM/yyyy, HH:mm');
        locale_map.put('vi_VN', 'HH:mm dd/MM/yyyy');
        locale_map.put('yo_BJ', 'dd/MM/yyyy HH:mm');
        locale_map.put('xh_ZA', 'M/d/yyyy h:mm a');
        locale_map.put('zh_CN', 'yyyy-M-d ah:mm');
        locale_map.put('zh_CN_PINYIN', 'yyyy/M/d ah:mm');
        locale_map.put('zh_CN_STROKE', 'yyyy/M/d ah:mm');
        locale_map.put('zh_HK', 'yyyy年M月d日 ah:mm');
        locale_map.put('zh_HK_STROKE', 'd/M/yyyy ah:mm');
        locale_map.put('zh_MO', 'd/M/yyyy ah:mm');
        locale_map.put('zh_SG', 'dd/MM/yyyy a hh:mm');
        locale_map.put('zh_TW', 'yyyy/M/d a h:mm');
        locale_map.put('zh_TW_STROKE', 'yyyy/M/d ah:mm');
        locale_map.put('zu_ZA', 'M/d/yyyy HH:mm');
        return locale_map; //return the map
    }
}