#+ This module implements ZipCode Lookup UI management
#+
#+ This module implements ZipCode Lookup UI management
#+

IMPORT util
IMPORT FGL ZipCodeModel

#+ Complete List of zipcodes
#+
DEFINE completeList DYNAMIC ARRAY OF TZipCode

#+ Current filtered list of zipcodes
#+
DEFINE filteredList DYNAMIC ARRAY OF TZipCode

#+ Current search critera for a zipcode
#+
DEFINE searchText string

#+ Constant cCompleterMax
#+
#+ Sets the maximum number of occurences displayed by the completer feature for the filtered list of ZipCodes -- limit is 50
#+
#+ @code
#+ IF nxtIdx <= cCompleterMax THEN
#+
CONSTANT cCompleterMax = 21

#+ Build zipcode cache
#+
#+ Initializes the current filtered/cached zipcode list
#+
#+ @code
#+ CALL buildZipCodeCache()
#+
#+ @param
#+
#+ @return
#+
PUBLIC FUNCTION buildZipCodeCache() RETURNS ()

	CALL completeList.clear()
	LET completeList = ZipCodeModel.loadZipCodes()
	CALL completeList.sort("zip_code", FALSE)
	CALL completeList.copyTo(filteredList)
	LET searchText = NULL

END FUNCTION #buildZipCodeCache

#+ Flush zipcode cache
#+
#+ Resets the current filtered/cached zipcode list
#+
#+ @code
#+ 	CALL flushZipCodeCache()
#+
#+ @param
#+
#+ @return
#+
PUBLIC FUNCTION flushZipCodeCache() RETURNS ()

	CALL completeList.clear()
	CALL filteredList.clear()
	LET searchText = NULL

END FUNCTION #flushZipCodeCache

#+ Zipcode completer
#+
#+ Manages the ongoing filtered list associated with the completer attribute + on change logic 
#+
#+ @code
#+ 	ON CHANGE zip_code
#+	    CALL zipCodeCompleter(DIALOG, r_address.zip_code)
#+
#+ @param dlg current dialog object
#+ @param zipCode current zipcode search criteria
#+
#+ @return
#+
PUBLIC FUNCTION zipCodeCompleter(dlg ui.Dialog, zipCode STRING) RETURNS ()
	DEFINE searchLength INTEGER
	DEFINE idx INTEGER = 0
	DEFINE fieldValue STRING
	DEFINE refinedList DYNAMIC ARRAY OF TZipCode
	DEFINE matchList DYNAMIC ARRAY OF STRING
	DEFINE nxtIdx INTEGER = 0

	LET zipCode = zipCode.trim()
	IF searchText IS NOT NULL AND zipCode.getIndexOf(searchText, 1) != 1 THEN
		CALL completeList.copyTo(filteredList)
	END IF

	LET searchLength = zipCode.getLength()
	FOR idx = 1 TO filteredList.getLength()

		LET fieldValue = filteredList[idx].zip_code
		IF fieldValue.subString(1, searchLength) == zipCode THEN
			LET nxtIdx = nxtIdx + 1
			LET refinedList[nxtIdx] = filteredList[idx]
			IF nxtIdx <= cCompleterMax THEN
				--LET matchList[nxtIdx] = SFMT("%1 - %2, %3",
				--	refinedList[nxtIdx].zip_code,
				--	refinedList[nxtIdx].city,
				--	refinedList[nxtIdx].state_id)
				LET matchList[nxtIdx] = refinedList[nxtIdx].zip_code
			END IF
		ELSE
			IF refinedList.getLength() > 0 THEN
				EXIT FOR
			END IF
		END IF

	END FOR

	LET searchText = zipCode.trim()
	CALL dlg.setCompleterItems(matchList)
	IF refinedList.getLength() > 0 THEN
		CALL filteredList.clear()
		CALL refinedList.copyTo(filteredList)
	END IF

END FUNCTION #zipCodeCompleter

#+ Get zipcode record
#+
#+ Retrieves all info associated with the final zipcode found into a record  
#+
#+ @code
#+ 	IF LENGTH(r_address.zip_code CLIPPED) == 5 THEN
#+	    CALL getZipCodeRec(r_address.zip_code) RETURNING search_zipcode.*
#+
#+ @param p_zone_code final complete uniquely found zipcode
#+
#+ @return r_zipcode complete record info associated with the final zipcode found
#+
PUBLIC FUNCTION getZipCodeRec(p_zone_code CHAR(5)) RETURNS (TZipCode)
	DEFINE r_zipcode TZipCode
	DEFINE idx INTEGER

	FOR idx = 1 TO filteredList.getLength()
		IF p_zone_code == filteredList[idx].zip_code THEN
			LET r_zipcode = filteredList[idx]
			RETURN r_zipcode.*
		END IF
	END FOR

	FOR idx = 1 TO completeList.getLength()
		IF p_zone_code == completeList[idx].zip_code THEN
			LET r_zipcode = completeList[idx]
			RETURN r_zipcode.*
		END IF
	END FOR

	INITIALIZE r_zipcode.* TO NULL
	RETURN r_zipcode.*

END FUNCTION #getZipCodeRec

#+ Show zipcode zoom
#+
#+ Displays a popup/lookup and manages the dialog block (input + display array) that allows the user to filter on zipcodes
#+
#+ @code
#+ 		ON ACTION zoom
#+			IF INFIELD(zip_code) THEN
#+				CALL showZipCodeZoom() RETURNING search_zipcode.*
#+
#+ @param
#+
#+ @return selectedRec selected record
#+
PUBLIC FUNCTION showZipCodeZoom() RETURNS (TZipCode)
	DEFINE selectedRec TZipCode
	DEFINE searchRec TZipCode
	DEFINE zoomRecs DYNAMIC ARRAY OF TZipCode
	DEFINE idx INTEGER

	OPEN WINDOW zoomWindow WITH FORM "ZipCodeZoom"
		ATTRIBUTES(STYLE="dialog", TEXT="Zip Code Zoom")

	CALL completeList.copyTo(zoomRecs)

	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT searchRec.zip_code, searchRec.city, searchRec.state_name, searchRec.county_name
		FROM s_zipcode.*
			ON CHANGE s_zip_code, s_city, s_state, s_county
				LET zoomRecs = filterArray(searchRec.*)
		END INPUT

		DISPLAY ARRAY zoomRecs TO s_zipcodes.*
			ON ACTION selected_row
                ACCEPT DIALOG
		END DISPLAY

         ON ACTION ACCEPT
            ACCEPT dialog

		ON ACTION CANCEL
			INITIALIZE selectedRec.* TO NULL
			EXIT dialog

       
        AFTER DIALOG
            LET idx = DIALOG.getCurrentRow("s_zipcodes")
            LET selectedRec = zoomRecs[idx]
        
	END DIALOG

	CLOSE WINDOW zoomWindow

	RETURN selectedRec.*

END FUNCTION #showZipCodeZoom

#+ Filter array
#+
#+ Logic that filters the array on the go as the user input criterias 
#+
#+ @code
#+ 		ON CHANGE s_zip_code, s_city, s_state, s_county
#+		    LET zoomRecs = filterArray(searchRec.*)
#+
#+ @param r_zipcode current searching criterias in the associated input subdialog
#+
#+ @return filteredArray current filtered array of zipcodes
#+
PRIVATE FUNCTION filterArray(r_zipcode TZipCode) RETURNS (DYNAMIC ARRAY OF TZipCode)
	DEFINE filteredArray DYNAMIC ARRAY OF TZipCode
	DEFINE idx INTEGER
	DEFINE filterIdx INTEGER
	DEFINE searchLen INTEGER

	IF r_zipcode.zip_code IS NULL AND r_zipcode.city IS NULL 
		AND r_zipcode.state_name IS NULL AND r_zipcode.county_name IS NULL THEN
		CALL completeList.copyTo(filteredArray)
		RETURN filteredArray
	END IF

	CALL filteredArray.clear()
	FOR idx = 1 TO completeList.getLength()
		IF r_zipcode.zip_code IS NOT NULL THEN
			LET r_zipcode.zip_code = r_zipcode.zip_code CLIPPED
			LET searchLen = LENGTH(r_zipcode.zip_code)
			IF r_zipcode.zip_code != completeList[idx].zip_code[1,searchLen] THEN
				CONTINUE FOR
			END IF
			IF searchLen > LENGTH(completeList[idx].zip_code) THEN
				CONTINUE FOR
			END IF
		END IF

		IF r_zipcode.city IS NOT NULL THEN
			LET r_zipcode.city = r_zipcode.city CLIPPED
			LET searchLen = LENGTH(r_zipcode.city)
			IF r_zipcode.city != completeList[idx].city.subString(1,searchLen) THEN
				CONTINUE FOR
			END IF
			IF searchLen > LENGTH(completeList[idx].city) THEN
				CONTINUE FOR
			END IF
		END IF

		IF r_zipcode.state_name IS NOT NULL THEN
			LET r_zipcode.state_name = r_zipcode.state_name CLIPPED
			LET searchLen = LENGTH(r_zipcode.state_name)
			IF r_zipcode.state_name != completeList[idx].state_name.subString(1,searchLen) THEN
				CONTINUE FOR
			END IF
			IF searchLen > LENGTH(completeList[idx].state_name) THEN
				CONTINUE FOR
			END IF
		END IF

		IF r_zipcode.county_name IS NOT NULL THEN
			LET r_zipcode.county_name = r_zipcode.county_name CLIPPED
			LET searchLen = LENGTH(r_zipcode.county_name)
			IF r_zipcode.county_name != completeList[idx].county_name.subString(1,searchLen) THEN
				CONTINUE FOR
			END IF
			IF searchLen > LENGTH(completeList[idx].county_name) THEN
				CONTINUE FOR
			END IF
		END IF

		LET filterIdx = filterIdx + 1
		LET filteredArray[filterIdx] = completeList[idx]

	END FOR

	RETURN filteredArray

END FUNCTION #filterArray