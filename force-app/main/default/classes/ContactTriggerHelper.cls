public class ContactTriggerHelper {
    

    public static void SingleCurrentAffiliateValidation(List<Contact> conList, Map<Id,Contact> oldMap){

        Set<Id> accIdSet = new Set<Id>();
        Map<Id, List<Id>> currentConToAccAffiliateListMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> prmConToAccAffiliateListMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> exeConToAccAffiliateListMap = new Map<Id, List<Id>>();
        Map<Id, List<npe5__Affiliation__c>> currentAccToAffliateList = new Map<Id, List<npe5__Affiliation__c>>();
        Map<Id, List<npe5__Affiliation__c>> prmAccToAffliateList = new Map<Id, List<npe5__Affiliation__c>>();
        Map<Id, List<npe5__Affiliation__c>> exeAccToAffliateList = new Map<Id, List<npe5__Affiliation__c>>();
        List<npe5__Affiliation__c> affiliations = [ SELECT 
                                                    npe5__Organization__c
                                                    FROM npe5__Affiliation__c 
                                                    WHERE npe5__Contact__c IN: conList];
        
        for(npe5__Affiliation__c aff: affiliations){
            accIdSet.add(aff.npe5__Organization__c);
        }

        System.debug(accIdSet);
        Set<Id> conIdSet = new Set<Id>();
        affiliations =  [SELECT npe5__Contact__c
                        FROM npe5__Affiliation__c 
                        WHERE npe5__Organization__c IN: accIdSet];

        for(npe5__Affiliation__c aff: affiliations){
            conIdSet.add(aff.npe5__Contact__c);
        }
        
        affiliations =  [SELECT Id,
                        npe5__Organization__c
                        FROM npe5__Affiliation__c 
                        WHERE npe5__Contact__c IN: conIdSet];

        for(npe5__Affiliation__c aff: affiliations){
            accIdSet.add(aff.npe5__Organization__c);
        }
        affiliations =  [SELECT Id,npe5__Contact__c,
                        npe5__Contact__r.Executive_Contact__c,
                        npe5__Contact__r.Primary_Contact__c,
                        npe5__Status__c,
                        npe5__Organization__c,
                        npe5__Organization__r.Name
                        FROM npe5__Affiliation__c 
                        //WHERE npe5__Status__c = 'Current' AND 
                        WHERE npe5__Organization__c IN: accIdSet];

        for(npe5__Affiliation__c aff: affiliations){
            if('Current'.equalsIgnoreCase(aff.npe5__Status__c)){
                if(!currentConToAccAffiliateListMap.containsKey(aff.npe5__Contact__c)){
                    currentConToAccAffiliateListMap.put(aff.npe5__Contact__c, new List<Id>());
                }

                
                if(!currentAccToAffliateList.containsKey(aff.npe5__Organization__c)){
                    currentAccToAffliateList.put(aff.npe5__Organization__c, new List<npe5__Affiliation__c>());
                }

                currentAccToAffliateList.get(aff.npe5__Organization__c).add(aff);

                currentConToAccAffiliateListMap.get(aff.npe5__Contact__c).add(aff.npe5__Organization__c);
            }

            if(aff.npe5__Contact__r.Primary_Contact__c){
                if(!prmconToAccAffiliateListMap.containsKey(aff.npe5__Contact__c)){
                    prmconToAccAffiliateListMap.put(aff.npe5__Contact__c, new List<Id>());
                }

                
                if(!prmaccToAffliateList.containsKey(aff.npe5__Organization__c)){
                    prmaccToAffliateList.put(aff.npe5__Organization__c, new List<npe5__Affiliation__c>());
                }

                prmaccToAffliateList.get(aff.npe5__Organization__c).add(aff);

                prmconToAccAffiliateListMap.get(aff.npe5__Contact__c).add(aff.npe5__Organization__c);
            }

            if(aff.npe5__Contact__r.Executive_Contact__c){
                if(!execonToAccAffiliateListMap.containsKey(aff.npe5__Contact__c)){
                    execonToAccAffiliateListMap.put(aff.npe5__Contact__c, new List<Id>());
                }

                
                if(!exeaccToAffliateList.containsKey(aff.npe5__Organization__c)){
                    exeaccToAffliateList.put(aff.npe5__Organization__c, new List<npe5__Affiliation__c>());
                }

                exeaccToAffliateList.get(aff.npe5__Organization__c).add(aff);

                execonToAccAffiliateListMap.get(aff.npe5__Contact__c).add(aff.npe5__Organization__c);
            }
        }

        System.debug(currentConToAccAffiliateListMap);
        System.debug(prmconToAccAffiliateListMap);
        System.debug(execonToAccAffiliateListMap);

        System.debug(currentAccToAffliateList);
        System.debug(prmaccToAffliateList);
        System.debug(exeaccToAffliateList);

        for(Contact con: conList){
            System.debug(con);
            System.debug(oldMap.get(con.Id).Primary_Contact__c);
            System.debug(con.Primary_Contact__c);
            System.debug(currentConToAccAffiliateListMap.get(con.Id));
            if(currentConToAccAffiliateListMap.containsKey(con.Id)){
                for(Id accId:  currentConToAccAffiliateListMap.get(con.Id)){
                    if(currentAccToAffliateList.containsKey(accId)){
                        List<npe5__Affiliation__c> affList = currentAccToAffliateList.get(accId);
                        System.debug(affList);
                        if(affList.size() <=1 && affList[0].npe5__Contact__c == con.Id && oldMap.get(con.Id).Executive_Contact__c && !con.Executive_Contact__c){
                            con.addError('This contact is only the current executive contact for '+affList[0].npe5__Organization__r.Name);
                            break;
                        }

                        if(affList.size() <=1 && affList[0].npe5__Contact__c == con.Id && oldMap.get(con.Id).Primary_Contact__c && !con.Primary_Contact__c){
                            con.addError('This contact is only the current primary contact for '+affList[0].npe5__Organization__r.Name);
                        }
                    }
                }
            }

            System.debug(con.Id);
            System.debug(prmconToAccAffiliateListMap.containsKey(con.Id));
            if(prmconToAccAffiliateListMap.containsKey(con.Id)){
                System.debug(prmconToAccAffiliateListMap.get(con.Id));
                for(Id accId:  prmconToAccAffiliateListMap.get(con.Id)){
                    if(prmaccToAffliateList.containsKey(accId)){
                        List<npe5__Affiliation__c> affList = prmaccToAffliateList.get(accId);
                        System.debug(affList);                       
                        if(affList.size() <=1 && affList[0].npe5__Contact__c == con.Id && oldMap.get(con.Id).Primary_Contact__c && !con.Primary_Contact__c){
                            System.debug(' flag :: '+!con.Primary_Contact__c);
                            con.addError('This contact is the only primary contact for '+affList[0].npe5__Organization__r.Name);
                        }
                    }
                }
            }

            if(execonToAccAffiliateListMap.containsKey(con.Id)){
                for(Id accId:  execonToAccAffiliateListMap.get(con.Id)){
                    if(exeaccToAffliateList.containsKey(accId)){
                        List<npe5__Affiliation__c> affList = exeaccToAffliateList.get(accId);
                        System.debug(affList);
                        if(affList.size() <=1 && affList[0].npe5__Contact__c == con.Id && oldMap.get(con.Id).Executive_Contact__c && !con.Executive_Contact__c){
                            con.addError('This contact is the only executive contact for '+affList[0].npe5__Organization__r.Name);
                        }
                    }
                }
            }


        }



    }
}