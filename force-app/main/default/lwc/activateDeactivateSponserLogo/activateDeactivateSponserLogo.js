import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getFilesByAccount from '@salesforce/apex/FileController.getFilesByAccount';
import updateFileRecords from '@salesforce/apex/FileController.updateFileRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ActivateDeactivateSponserLogo extends LightningElement {

    @api recordId;
    files;
    updatedRecords = [];

    @wire(getFilesByAccount,{recordId:'$recordId'})
    wiredFiles(result) {
        console.log(result);
        this.files = result.data;
    }

    handleCheckboxChange(event) {
        const fileId = event.target.dataset.fileid;
        const isActive = event.target.checked;

        this.updatedRecords.push({ fileId: fileId, isActive: isActive });

    }

    handleSave(event) {
        updateFileRecords({ updatedRecordsJSON: JSON.stringify(this.updatedRecords) })
        .then((res) => {
          // After the update is completed, refresh the file list
            console.log(res);
            const evt = new ShowToastEvent({
                title: "Files update",
                message: 'Files updated successfully',
                variant: "success",
            });
            this.dispatchEvent(evt);
            window.location.reload();
        })
        .catch((error) => {
            console.error('Error updating file records:', error);
            const evt = new ShowToastEvent({
                title: "Files update",
                message: error,
                variant: "error",
            });
            this.dispatchEvent(evt);
        });
    }

}