public class AffiliationTriggerHelper {


    public static void upateAffiliationStatus(List<npe5__Affiliation__c> affList, Map<Id, npe5__Affiliation__c> oldMap){

        Set<Id> accIdSet = new Set<Id>();
        for(npe5__Affiliation__c aff: affList){
            accIdSet.add(aff.npe5__Organization__c);
        }

        List<npe5__Affiliation__c> allAffiliationList = [SELECT Id,npe5__Organization__c,npe5__Contact__c,npe5__Contact__r.Primary_Contact__c,npe5__Contact__r.Executive_Contact__c FROM npe5__Affiliation__c WHERE npe5__Organization__c IN:accIdSet AND (npe5__Contact__r.Primary_Contact__c = true OR npe5__Contact__r.Executive_Contact__c = true)];

        Map<Id, List<npe5__Affiliation__c>> accIdToPrimaryContactListMap = new Map<Id, List<npe5__Affiliation__c>>();
        Map<Id, List<npe5__Affiliation__c>> accIdToExecitiveContactListMap = new Map<Id, List<npe5__Affiliation__c>>();
        for(npe5__Affiliation__c aff:allAffiliationList){

            if(aff.npe5__Contact__r.Primary_Contact__c){
                if(!accIdToPrimaryContactListMap.containsKey(aff.npe5__Organization__c)){
                    accIdToPrimaryContactListMap.put(aff.npe5__Organization__c, new List<npe5__Affiliation__c>());
                }
                
                    accIdToPrimaryContactListMap.get(aff.npe5__Organization__c).add(aff);
            }

            if(aff.npe5__Contact__r.Executive_Contact__c){
                if(!accIdToExecitiveContactListMap.containsKey(aff.npe5__Organization__c)){
                    accIdToExecitiveContactListMap.put(aff.npe5__Organization__c, new List<npe5__Affiliation__c>());
                }
                
                accIdToExecitiveContactListMap.get(aff.npe5__Organization__c).add(aff);
            }
        }

        Map<Id,npe5__Affiliation__c> affListToupdate = new Map<Id,npe5__Affiliation__c>();
        set<Id> affIdSet = new Set<Id>();
        for(npe5__Affiliation__c aff: affList){
            Boolean isExecutive = accIdToExecitiveContactListMap.containsKey(aff.npe5__Organization__c);
            Boolean isPrimary = accIdToPrimaryContactListMap.containsKey(aff.npe5__Organization__c);
            Integer primarySize = isPrimary?accIdToPrimaryContactListMap.get(aff.npe5__Organization__c).size():0;
            Integer executiveSize = isExecutive?accIdToExecitiveContactListMap.get(aff.npe5__Organization__c).size():0;
            Boolean isPrimaryChanged = !aff.npe5__Primary__c && oldMap.get(aff.Id).npe5__Primary__c;
            if(isPrimaryChanged){
                npe5__Affiliation__c affupdate = new npe5__Affiliation__c();
                affupdate.Id = aff.Id;
                affupdate.npe5__Status__c = 'Former';
                if(!affListToupdate.containsKey(aff.Id)){
                    affListToupdate.put(aff.Id,affupdate);
                }else{
                    affListToupdate.get(aff.Id).npe5__Status__c = 'Former';
                }
                if(isExecutive && isPrimary && primarySize == 1 &&executiveSize == 1 ){
                    npe5__Affiliation__c exec = accIdToExecitiveContactListMap.get(aff.npe5__Organization__c)[0];
                    npe5__Affiliation__c prm = accIdToPrimaryContactListMap.get(aff.npe5__Organization__c)[0];
                    if(exec.id != prm.id && exec.id != aff.Id){
                        exec.npe5__Primary__c = true;
                        if(!affListToupdate.containsKey(exec.Id)){
                            affListToupdate.put(exec.Id,exec);
                        }else{
                            affListToupdate.get(aff.Id).npe5__Primary__c = true;
                        }
                    }else if(exec.id != prm.id && prm.id != aff.Id){
                        prm.npe5__Primary__c = true;
                        if(!affListToupdate.containsKey(prm.Id)){
                            affListToupdate.put(prm.Id,prm);
                        }else{
                            affListToupdate.get(aff.Id).npe5__Primary__c = true;
                        }
                    }else{
                        aff.addError('Unable to remove the affiliation of a Contact when the single Affiliated Contact of a Member Agency.');
                    }


                }/*else{
                    aff.addError('There is other primary or executive contact.');
                }*/
            }
        }


        if(affListToupdate.size() > 0)
        update affListToupdate.values();


    }

}