import { LightningElement, api, track, wire } from 'lwc';
import search3 from '@salesforce/apex/SearchComponentController.search3';
import search4 from '@salesforce/apex/SearchComponentController.search4';
import getRecentlyCreatedRecord from '@salesforce/apex/SearchComponentController.getRecentlyCreatedRecord';
const DELAY = 10;

import { NavigationMixin } from 'lightning/navigation';

export default class SearchComponent extends NavigationMixin(LightningElement) {

    /* values for an existing selected record */
    @api valueId;
    @api valueName;
    @api searchCmp;
    @api marginTop     = '0%';
    @api objName       = 'Account';
    @api iconName      = 'standard:account';
    @api labelName;
    @api currentRecordId;
    @api placeholder   = 'Search';
    @api fields        = ['Name'];
    @api displayFields = ['Name, AccountNumber'];
    @api showLabel     = false;
    @api parentAPIName = 'ParentId';
    @api createRecord  = false;
    @api parentId;

    /* values to be passed to create the new record */
    @api recordTypeId;
    @api fieldsToCreate = [];

    /* Create fields for using in Datatable for Multiple In-line Edit */
    @api index;

    @track error;

    searchTerm;
    delayTimeout;

    searchRecords;
    selectedRecord;
    objectLabel;
    isLoading = false;
    showButton = false;
    showModal = false;

    field;
    field1;

    ICON_URL       = '/apexpages/slds/latest/assets/icons/{0}-sprite/svg/symbols.svg#{1}';
    ICON_URL_NEW   = '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#add';
    ICON_URL_CLOSE = '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close';

    connectedCallback(){

        let icons           = this.iconName.split(':');
        this.ICON_URL       = this.ICON_URL.replace('{0}',icons[0]);
        this.ICON_URL       = this.ICON_URL.replace('{1}',icons[1]);

        if(this.objName.includes('__c')){
            let obj = this.objName.substring(0, this.objName.length-3);
            this.objectLabel = obj.replaceAll('_',' ');
        }else{
            this.objectLabel = this.objName;
        }

        if( this.valueId && this.valueName ){
            this.selectedRecord = {
                FIELD1 : this.valueName,
                Id     : this.valueId
            }
        }

        this.objectLabel    = this.titleCase(this.objectLabel);
        console.log(this.displayFields);
        let fieldList;
        if( !Array.isArray(this.displayFields)){
            fieldList       = this.displayFields.split(',');
        }else{
            fieldList       = this.displayFields;
        }
        if(fieldList.length > 1){
            this.field  = fieldList[0].trim();
            this.field1 = fieldList[1].trim();
        }
        
        let combinedFields = [];
        fieldList.forEach(field => {
            if( !this.fields.includes(field.trim()) ){
                combinedFields.push( field.trim() );
            }
        });

        this.fields = combinedFields.concat( JSON.parse(JSON.stringify(this.fields)) );

        if(this.valueId && this.valueName){
            this.selectedRecord = {
                FIELD1   : this.valueName,
                recordId : this.valueId
            }
        }

    }

    handleInputChange(event){
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        //this.isLoading = true;
        this.delayTimeout = setTimeout(() => {
            if(this.searchCmp !== "transaction"){
                search3({
                    objectName : this.objName,
                    fields     : this.fields,
                    searchTerm : searchKey,
                    parentId   : this.parentId
                })
                .then(result => {
                    let stringResult = JSON.stringify(result);
                    let allResult    = JSON.parse(stringResult);
                    allResult.forEach( record => {
                        record.FIELD1       = record[this.field];
                        record.FIELD2       = record[this.field1];
                        
                    });
                    this.searchRecords = allResult;
                })
                .catch(error => {
                    console.error('Error:', error);
                })
                .finally( ()=>{
                    this.showButton = this.createRecord;
                });
            }else{
                search4({
                    searchTerm : searchKey,
                    currentAffiliate:this.parentId
                }).then(res => {
                    console.log(res);
                    let stringResult = JSON.stringify(res);
                    let allResult    = JSON.parse(stringResult);
                    allResult.forEach( record => {
                        record.FIELD1       = record["Name"];
                        record.FIELD2       = record[this.field1];
                        
                    });
                    this.searchRecords = allResult;
                }).catch(err => {

                })
            }
        }, DELAY);
    }

    handleSelect(event){

        let recordId = event.currentTarget.dataset.recordId;
        let selectRecord = this.searchRecords.find((item) => {
            return item.Id === recordId;
        });
        this.selectedRecord = selectRecord;
        const selectedEvent = new CustomEvent('lookup', {
            bubbles    : true,
            composed   : true,
            cancelable : true,
            detail: {
                data : {
                    record          : selectRecord,
                    recordId        : recordId,
                    currentRecordId : this.currentRecordId,
                    parentAPIName   : this.parentAPIName,
                    index           : this.index
                }
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    handleClose(){
        this.selectedRecord = undefined;
        this.searchRecords  = undefined;
        this.showButton     = false;
        const selectedEvent = new CustomEvent('lookup', {
            bubbles    : true,
            composed   : true,
            cancelable : true,
            detail: {
                data : {
                    record          : undefined,
                    recordId        : undefined,
                    currentRecordId : this.currentRecordId,
                    parentAPIName   : this.parentAPIName,
                    index           : this.index
                }
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    titleCase(string) {
        var sentence = string.toLowerCase().split(" ");
        for(var i = 0; i< sentence.length; i++){
            sentence[i] = sentence[i][0].toUpperCase() + sentence[i].slice(1);
        }
        return sentence;
    }

    handleNewRecord = event => {
        event.preventDefault();
        this.showModal = true;
    }

    handleCancel = event => {
        event.preventDefault();
        this.showModal = false;
    }

    handleSuccess = event => {
        event.preventDefault();
        this.showModal = false;
        let recordId   = event.detail.id;
        this.hanleCreatedRecord(recordId);
    }

    hanleCreatedRecord = (recordId) => {
        getRecentlyCreatedRecord({
            recordId   : recordId,
            fields     : this.fields,
            objectName : this.objName
        })
        .then(result => {
            if(result){
                this.selectedRecord = {
                    FIELD1   : result[this.field],
                    Id       : recordId
                };
                const selectedEvent = new CustomEvent('lookup', {
                    bubbles    : true,
                    composed   : true,
                    cancelable : true,
                    detail: {
                        data : {
                            record          : this.selectedRecord,
                            recordId        : recordId,
                            currentRecordId : this.currentRecordId,
                            parentAPIName   : this.parentAPIName,
                            index           : this.index
                        }
                    }
                });
                this.dispatchEvent(selectedEvent);
            }
        })
        .catch(error => {
            console.error('Error: \n ', error);
        })
        .finally( ()=>{
            this.showModal = false;
        });
    }

    @api
    handleRecordClear(event){   
        this.valueId = undefined;
        this.valueName = undefined;
        this.selectedRecord = undefined;
        this.searchRecords  = undefined;
        this.showButton     = false;
    }
}