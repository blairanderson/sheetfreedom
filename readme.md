# SheetFreedom
## Create a Readable/Trackable API from a Google Sheet.
 
I have a confession to make: I love google products but I hate google APIs. They're never developer friendly. Authentication is horrible. This application serves to give you access to your data.  


Features:

- One-Click Authentication with Google
- Simply select from a list of your files and then select a single sheet
- Create multiple ApiKeys per sheet.

TODO:

- [ ] ApiKey-level limits(3000 calls per month)
- [ ] column-specific transformers(X column should be shown as day instead of datetime)
- [ ] column-specific functions
- [ ] row specific tasks(do XYZ on this data)
- [ ] spreadsheet visualizations



things to review for google api:

To enable the sheet api you have to enable sheets apis.
https://console.developers.google.com/apis/api/sheets.googleapis.com/overview

While developing, i was having problems with google oauth and capturing the refresh token. 

https://github.com/zquestz/omniauth-google-oauth2/issues/111

