public class ContactTriggerHandler {
    public static void primaryORExecutiveLogic(List<Contact> contactList, Map<Id,Contact> oldContactMap) {
        Set<Id> organizationIds = new Set<Id>();
        Map<Id,Contact> mapOrgIdToPrimaryContact = new Map<Id,Contact>();
        Map<Id,Contact> mapOrgIdToExecutiveContact = new Map<Id,Contact>();
        Map<Id,Contact> mapOrgIdToBothContact = new Map<Id,Contact>();
        Map<Id,Contact> mapOrgIdToContact = new Map<Id,Contact>();
        Map<Id,npe5__Affiliation__c> mapConIdToAffiliation = new Map<Id,npe5__Affiliation__c>();
        for(contact con :contactList) {
            if(String.isBlank(con.npsp__Primary_Affiliation__c) && !String.isBlank(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)
               && (con.Primary_Contact__c || con.Executive_Contact__c)) {
                   system.debug('Trigger Contact->'+con.Id+'-'+con.Primary_Contact__c+'-'+con.Executive_Contact__c);
                   organizationIds.add(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
               }
        }
        system.debug('organizationIds--'+organizationIds);
        for(npe5__Affiliation__c affil :[Select Id, npe5__Contact__c, npe5__Status__c, npe5__Organization__c FROM npe5__Affiliation__c WHERE npe5__Organization__c IN :organizationIds AND npe5__Contact__c IN :contactList AND npe5__Status__c = 'Current']) {
            if(oldContactMap.containskey(affil.npe5__Contact__c) 
               && oldContactMap.get(affil.npe5__Contact__c).npsp__Primary_Affiliation__c == affil.npe5__Organization__c) {
                   mapConIdToAffiliation.put(affil.npe5__Contact__c, affil);
                   
               }
        }
        system.debug('mapConIdToAffiliation--'+mapConIdToAffiliation);
        for(Contact con :[Select Id, Primary_Contact__c, Executive_Contact__c, npsp__Primary_Affiliation__c
                          FROM Contact WHERE npsp__Primary_Affiliation__c IN :organizationIds AND Id NOT IN :contactList]) {
                              if(con.Primary_Contact__c && con.Executive_Contact__c) {
                                  mapOrgIdToBothContact.put(con.npsp__Primary_Affiliation__c, con);
                              }
                              if(con.Primary_Contact__c && !con.Executive_Contact__c) {
                                  mapOrgIdToPrimaryContact.put(con.npsp__Primary_Affiliation__c, con);
                              }
                              if(!con.Primary_Contact__c && con.Executive_Contact__c) {
                                  mapOrgIdToExecutiveContact.put(con.npsp__Primary_Affiliation__c, con);
                              }
                              if(!con.Primary_Contact__c && !con.Executive_Contact__c) {
                                  mapOrgIdToContact.put(con.npsp__Primary_Affiliation__c, con);
                              }
                          }
        system.debug('mapOrgIdToExecutiveContact'+mapOrgIdToExecutiveContact);
        system.debug('mapOrgIdToPrimaryContact'+mapOrgIdToPrimaryContact);
        system.debug('mapOrgIdToBothContact'+mapOrgIdToBothContact);
        system.debug('mapOrgIdToContact'+mapOrgIdToContact);
        List<Contact> conListToUpdate = new List<Contact>();
        Set<Id> affiliationIds = new Set<Id>();
        for(Contact con :contactList) {
            system.debug('Trigger Contact->'+con.Id+'-'+con.Primary_Contact__c+'-'+con.Executive_Contact__c);
            if(String.isBlank(con.npsp__Primary_Affiliation__c) && !String.isBlank(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c) && mapConIdToAffiliation.containsKey(con.Id)) {
                if(mapOrgIdToBothContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                    con.Executive_Contact__c = false;
                    con.Primary_Contact__c = false;
                    npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                    affiliationIds.add(tempAffiliation.id);
                } else if(con.Executive_Contact__c && con.Primary_Contact__c) {
                    if(mapOrgIdToPrimaryContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        con.Executive_Contact__c = false;
                        con.Primary_Contact__c = false;
                        Contact tempContact = mapOrgIdToPrimaryContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Executive_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else if(mapOrgIdToExecutiveContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        con.Executive_Contact__c = false;
                        con.Primary_Contact__c = false;
                        Contact tempContact = mapOrgIdToExecutiveContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Primary_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else if(mapOrgIdToContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        con.Executive_Contact__c = false;
                        con.Primary_Contact__c = false;
                        Contact tempContact = mapOrgIdToContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Executive_Contact__c = true;
                        tempContact.Primary_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else {
                        con.addError('Unable to remove the affiliation of a Contact when the single Affiliated Contact of a Member Agency');
                    }
                } else if(!con.Executive_Contact__c && con.Primary_Contact__c) {
                    if(mapOrgIdToExecutiveContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        con.Primary_Contact__c = false;
                        Contact tempContact = mapOrgIdToExecutiveContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Primary_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else if(mapOrgIdToContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        Contact tempContact = mapOrgIdToContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Primary_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else {
                        con.addError('Unable to remove the affiliation of a Contact when the single Affiliated Contact of a Member Agency');
                    }
                } else if(con.Executive_Contact__c && !con.Primary_Contact__c) {
                    if(mapOrgIdToPrimaryContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        con.Executive_Contact__c = false;
                        Contact tempContact = mapOrgIdToPrimaryContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Executive_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else if(mapOrgIdToContact.containsKey(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c)) {
                        Contact tempContact = mapOrgIdToContact.get(oldContactMap.get(con.Id).npsp__Primary_Affiliation__c);
                        tempContact.Executive_Contact__c = true;
                        if(!conListToUpdate.contains(tempContact))
                            conListToUpdate.add(tempContact);
                        npe5__Affiliation__c tempAffiliation = mapConIdToAffiliation.get(con.Id);
                        affiliationIds.add(tempAffiliation.id);
                    } else {
                        con.addError('Unable to remove the affiliation of a Contact when the single Affiliated Contact of a Member Agency');
                    }
                }
            }
        }
        system.debug('conListToUpdate--'+conListToUpdate);
        if(!conListToUpdate.isEmpty()) {
            //update conListToUpdate;
        }
        system.debug('affiliationIds--'+affiliationIds);
        if(!affiliationIds.isEmpty()) {
            updateAffiliation(affiliationIds);
        }
    }
    @future
    public static void updateAffiliation(Set<Id> affilIds) {
        List<npe5__Affiliation__c> upadteAffilList = new List<npe5__Affiliation__c>();
        for(npe5__Affiliation__c affil :[Select Id, npe5__Contact__c, npe5__Status__c, npe5__Primary__c, npe5__Organization__c FROM npe5__Affiliation__c Where Id IN :affilIds]) {
            affil.npe5__Primary__c = false;
            affil.npe5__Status__c = 'Former';
            upadteAffilList.add(affil);
        }
        system.debug('upadteAffilList--'+upadteAffilList);
        if(!upadteAffilList.isEmpty()) {
            update upadteAffilList;
        }
    }
}