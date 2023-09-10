import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Account.Id';
import uploadFiles from '@salesforce/apex/PaymentReceipt_Ctrl.uploadFiles';
import checkAffiliate from '@salesforce/apex/PaymentReceipt_Ctrl.checkAffiliate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UploadImages extends LightningElement {
    @track isAffiliate = false;
    @api recordId; // Expose the recordId from the Lightning Record Page
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
    account;
    get accountId() {
        return getFieldValue(this.account.data, ACCOUNT_ID_FIELD);
    }
    @wire(checkAffiliate, { accountId: '$recordId' })
    recordTypeHandler({ data, error}) {
        console.log('Account Record Type:', data);
        if (data) {
            this.isAffiliate = true;
        } else if (error) {
            console.error('Error retrieving Account Record Type:', error);
        }
    }
    get acceptedFormats() {
        return ['.jpg', '.png', '.jpeg'];
    }
    
    handleFileUpload(event) {
        const fileInput = this.template.querySelector('lightning-file-upload');
        let files = event.detail.files;
        files = JSON.stringify(files);
        if (files.length > 0) {
            console.log('files-->',files);
            uploadFiles({ files })
                .then(result => {
                    // Handle success
                    const evt = new ShowToastEvent({
                        title: "Success",
                        message: "Image Uploaded Successfully",
                        variant: "success",
                    });
                    this.dispatchEvent(evt);
                    console.log('Image uploaded successfully.');
                })
                .catch(error => {
                    // Handle error
                    const evt = new ShowToastEvent({
                        title: "Error",
                        message: "Image Upload Unsuccessful",
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                    console.error('Error uploading image:', error);
                });
        }
    }
    handleFileSize(event) {
        console.log('on change event-->');
        const fileInput = this.template.querySelector('lightning-file-upload');
        const files = event.target.files;
        
        // Perform file size validation for each file
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            const fileSize = file.size; // File size in bytes
            const maxSize = 102400; // Maximum file size in bytes (e.g., 100KB)
            
            if (fileSize > maxSize) {
                const evt = new ShowToastEvent({
                    title: "Error",
                    message: "File size exceeds the maximum limit.",
                    variant: "error",
                });
                this.dispatchEvent(evt);
                //console.error('Error uploading image:', error);
                fileInput.clear();
                return; // Exit the method if file size exceeds the limit
            }
        }
    }
}