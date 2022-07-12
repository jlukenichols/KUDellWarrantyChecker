# KUDellWarrantyChecker
Reads a list of Dell service tags from a CSV file, performs a Dell API lookup to get Dell warranty data, saves that data into a CSV file, then imports the data back into PDQ Inventory custom fields. You should duplicate the provided "DefaultSettings.ps1" file and rename it to "CustomSettings.ps1" and make your changes in there. If you just modify the data in DefaultSettings.ps1 they will be overwritten when you pull a new version from the GitHub repo. If the two custom variables do not yet exist in PDQ Inventory they should be automatically created by the script. The field names should be "Warranty End Date" and "Purchase Date" and the data type for both should be "Date & Time". If you want to change the variable names then you will have to modify the "$ShipDateCustomFieldName" and "$EntitlementEndDateCustomFieldName" values in your CustomSettings.ps1 file.
