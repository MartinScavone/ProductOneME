# Product-One ME Official Repository

This is the official repository for Product-One M-E design tool.
This computer code has been developed as part of a Thesis research project (1). The author of this thesis licensed the thesis report, all original work created throughout the project (including Product-One's source code) with a Creative Commons Attribution Share Alike 4.0 International [cc-by-sa-4.0] License. 
When making use of Product-One, you agree to accept the following conditions:
  1) Respect the terms of the CC-BY-SA-4.0 int'l license. The license terms can be read here: http://
creativecommons.org/licenses/by-sa/4.0/ 
  2) Acknowledge that Product-One and its source code are given AS-IS, and without warranty of fitting any particular purpose. Release the author (Scavone, M) of any liability that may result as a consequence (either direct or indirect) of the use, lack of use, or misuse of Product-One. As the end-user of Product-One, you are expected to analyze and construe the results given by Product-One and rely on your engineering judegement.
  
--------------------------
(1) Ref: Scavone, M. (2019): "IMPLEMENTATION OF A MECHANISTIC-EMPIRICAL PAVEMENT DESIGN METHOD FOR URUGUAYAN ROADWAYS". M. Sc. Thesis. Virginia Polytechnic Institute and State University. Blacksburg, VA, USA. Available at: https://vtechworks.lib.vt.edu/handle/10919/90777

-------------------------

# Brief notes on the use of Product-One M-E

* Product-One M-E has been written in Matlab language. You may need a Matlab interpreter (either Matlab(R) or GNU-Octave) to run the software. 
* The "MAIN_CODE.m" file is Product-One's front-end script. You must run that script from the interpreter's command window to execute Product-One. 
* All the input data to the design process must be loaded onto the input data spreadsheet before running the MAIN_CODE. A template of the input data spreadsheet is "dataInput.xlsx".
You may want to have different spreadsheets with inputs for different projects, so you may save each under a different filename.
Upon execution, Product-One will ask you the name of the input data spreadsheet, go the interpreter's main command window and write accordingly.
* Refer to Scavone (2019) [full citation above] for further insight on the contents of Product-One.

------------------------
# GNU-Octave users read this:
Product-One makes use of the excel-spreadsheet read/write functions (xlsread and xlswrite) to read the problem inputs and write results, and the "datetime" function for plotting results. None of these functions are shipped with Octave by default, so you must install them prior to running Product-One. 
If you run Product-One and don't have these packages installed in your system, Product-One would issue a warning prompting you to do so, and pop an error right afterwards (Product-One checks for these packages in the 'integrityCheck' script, it looks for the xls*** and datetime functions in the Octave environment, and tries to load the packages case these are not around).

The xlsread and xlswrite functions are part of the 'io' package, which is available through the Octave-Forge. 
The datetime function is part of the 'Chrono' package by A.P.Janke, which is available at: https://github.com/apjanke/octave-chrono. If you cannot install 'Chrono' from the linked source, I copied a tarball version of it I managed to put to run while testing the software (see the 'dependencies' folder). 'Chrono' is (C) by A. P. Janke, and distributed under the GPL v3 License. 

