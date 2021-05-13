IMPORT util
IMPORT FGL ZipCodeModel

DEFINE completeList DYNAMIC ARRAY OF TZipCode
DEFINE filteredList DYNAMIC ARRAY OF TZipCode
DEFINE searchText STRING

CONSTANT cCompleterMax = 21

PUBLIC FUNCTION buildZipCodeCache() RETURNS ()

	CALL completeList.clear()
	LET completeList = ZipCodeModel.loadZipCodes()
	CALL completeList.sort("zip_code", FALSE)
	CALL completeList.copyTo(filteredList)
	LET searchText = NULL

END FUNCTION #buildZipCodeCache

PUBLIC FUNCTION flushZipCodeCache() RETURNS ()

	CALL completeList.clear()
	CALL filteredList.clear()
	LET searchText = NULL

END FUNCTION #flushZipCodeCache

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
			ON CHANGE s_zip_code
				CALL zoomRecs.clear()
				LET zoomRecs = filterArray(searchRec.*)
			ON CHANGE s_city
				CALL zoomRecs.clear()
				LET zoomRecs = filterArray(searchRec.*)
			ON CHANGE s_state
				CALL zoomRecs.clear()
				LET zoomRecs = filterArray(searchRec.*)
			ON CHANGE s_county
				CALL zoomRecs.clear()
				LET zoomRecs = filterArray(searchRec.*)
		END INPUT

		DISPLAY ARRAY zoomRecs TO s_zipcodes.*
			ON ACTION selected_row
				LET idx = DIALOG.getCurrentRow("s_zipcodes")
				LET selectedRec = zoomRecs[idx]
				ACCEPT DIALOG
		END DISPLAY

		ON ACTION CANCEL
			INITIALIZE selectedRec.* TO NULL
			EXIT DIALOG

	END DIALOG

	CLOSE WINDOW zoomWindow

	RETURN selectedRec.*

END FUNCTION #showZipCodeZoom

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