#+ This module implements ZipCode Model Types and functions
#+
#+ This module implements ZipCode Model Types and functions
#+

IMPORT os
IMPORT util

#+ This is the ZipCode type
#+
#+ Define variables or arrays with this type to hold Zipcode detailled records.
#+
#+ @code
#+ 	DEFINE zipCodeList DYNAMIC ARRAY OF TZipCode
#+	DEFINE r_zipcode TZipCode
#+
PUBLIC TYPE TZipCode RECORD
	zip_code CHAR(5),
	latitude DECIMAL(10,6),
	longitude DECIMAL(10,6),
	city STRING,
	state_id CHAR(2),
	state_name STRING,
	zcta STRING,
	parent_zcta STRING,
	population INTEGER,
	density FLOAT,
	county_fips CHAR(5),
	county_name STRING
END RECORD

#+ Load zipcodes
#+
#+ Load ALL zipcodes from a csv file
#+
#+ @code
#+ LET completeList = ZipCodeModel.loadZipCodes()
#+
#+ @param
#+
#+ @return zipCodeList a dynamic array of zipcodes
#+
PUBLIC FUNCTION loadZipCodes() RETURNS DYNAMIC ARRAY OF TZipCode
	DEFINE zipCodeList DYNAMIC ARRAY OF TZipCode
	DEFINE r_zipcode TZipCode
	DEFINE fileLine STRING
	DEFINE idx INTEGER
	DEFINE channel base.Channel
	DEFINE csvFile STRING

	LET csvFile = SFMT("..%1zipcodes%1uszips.csv", os.Path.separator())
	IF os.Path.exists(csvFile) THEN

		LET channel = base.Channel.create()
		TRY
			CALL channel.openFile(csvFile, "r")
			LET idx = 0
			WHILE (fileLine := channel.readLine()) IS NOT NULL
				CALL r_zipcode.initFromCSV(fileLine)
				LET idx = idx + 1
				LET zipCodeList[idx] = r_zipcode
			END WHILE
			CALL channel.close()

		CATCH

			CALL zipCodeList.clear()

		END TRY

	END IF

	RETURN zipCodeList

END FUNCTION #loadZipCodes

#+ Initialize from CSV file
#+
#+ Method that reads a line from a CSV and loads a new record entry for the zipcode array
#+
#+ @code
#+ WHILE (fileLine := channel.readLine()) IS NOT NULL
#+  CALL r_zipcode.initFromCSV(fileLine)
#+
#+ @param csvLine source file line
#+
#+ @return
#+
PUBLIC FUNCTION (self TZipCode) initFromCSV(csvLine STRING) RETURNS ()
	DEFINE parser base.StringTokenizer
	DEFINE fieldValue base.StringBuffer
	DEFINE idx INTEGER

	LET idx = 0
	LET parser = base.StringTokenizer.create(csvLine, ",")
	WHILE parser.hasMoreTokens()
		LET idx = idx + 1
		LET fieldValue = base.StringBuffer.create()
		CALL fieldValue.append(parser.nextToken())
		CALL fieldValue.replace('"', '', 0)
		CASE idx
			WHEN 1
				LET self.zip_code = fieldValue.toString()
			WHEN 2
				LET self.latitude = fieldValue.toString()
			WHEN 3
				LET self.longitude = fieldValue.toString()
			WHEN 4
				LET self.city = fieldValue.toString()
			WHEN 5
				LET self.state_id = fieldValue.toString()
			WHEN 6
				LET self.state_name = fieldValue.toString()
			WHEN 7
				LET self.zcta = fieldValue.toString()
			WHEN 8
				LET self.parent_zcta = fieldValue.toString()
			WHEN 9
				LET self.population = fieldValue.toString()
			WHEN 10
				LET self.density = fieldValue.toString()
			WHEN 11
				LET self.county_fips = fieldValue.toString()
			WHEN 12
				LET self.county_name = fieldValue.toString()
		END CASE
	END WHILE

END FUNCTION #initFromCSV

#+ TZipCode isEmpty method
#+
#+ Method that checks if the final desired zipcode is finally found (or not yet in that case)
#+
#+ @code
#+ IF NOT search_zipcode.isEmpty() THEN
#+
#+ @param
#+
#+ @return
#+
PUBLIC FUNCTION (self TZipCode) isEmpty() RETURNS BOOLEAN

	RETURN (self.zip_code IS NULL)

END FUNCTION #isEmpty