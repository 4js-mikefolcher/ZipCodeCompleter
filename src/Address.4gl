IMPORT util
IMPORT FGL ZipCodeModel
IMPORT FGL ZipCodeUI

#+ This is the Adress type
#+
#+ Define variables with this type to hold address records.
#+
#+ @code
#+ DEFINE r_address TAddress
#+
TYPE TAddress RECORD
	first_name STRING,
	last_name STRING,
	street_addr STRING,
	city STRING,
	state STRING,
	zip_code CHAR(5)
END RECORD

#+ Main
#+
MAIN

	OPTIONS INPUT WRAP

	OPEN WINDOW AddressForm WITH FORM "AddressForm"

	CALL inputAddress()

	CLOSE WINDOW AddressForm

END main #Main

#+ Input Address
#+
#+ This is an input function for adresses
#+
#+ @code
#+ CALL inputAddress()
#+
#+ @param
#+
#+ @return
#+
PRIVATE FUNCTION inputAddress() RETURNS ()
	DEFINE r_address TAddress
	DEFINE search_zipcode TZipCode
	DEFINE zip_code_search STRING

	CALL buildZipCodeCache()

	INPUT r_address.first_name, r_address.last_name,
		   r_address.street_addr, r_address.city,
			r_address.state, zip_code_search, r_address.zip_code
		FROM s_address.*
		ATTRIBUTES(WITHOUT DEFAULTS=TRUE, ACCEPT=FALSE, CANCEL=FALSE, UNBUFFERED)

		ON ACTION zoom
			IF INFIELD(zip_code_search) THEN
				CALL showZipCodeZoom() RETURNING search_zipcode.*
				IF NOT search_zipcode.isEmpty() THEN
					LET r_address.zip_code = search_zipcode.zip_code
					LET r_address.city = search_zipcode.city
					LET r_address.state = search_zipcode.state_name
					LET zip_code_search = search_zipcode.toString()
				END IF
			END IF

		ON CHANGE zip_code_search
			CALL zipCodeCompleter(DIALOG, zip_code_search)
			IF zip_code_search.getLength() >= 5 THEN
				CALL getZipCodeRecFromString(zip_code_search)
					RETURNING search_zipcode.*
				IF search_zipcode.isEmpty() THEN
					LET r_address.city = NULL
					LET r_address.state = NULL
					LET r_address.zip_code = NULL
				ELSE
					LET r_address.city = search_zipcode.city
					LET r_address.state = search_zipcode.state_name
					LET r_address.zip_code = search_zipcode.zip_code
				END IF
			END IF

		ON ACTION save ATTRIBUTES(TEXT="Save")
			ACCEPT INPUT

		ON ACTION cancel_input ATTRIBUTES(TEXT="Exit")
			EXIT INPUT

		AFTER INPUT
			CALL showAddress(r_address.*)
			INITIALIZE r_address.* TO NULL
			LET zip_code_search = NULL
			CONTINUE INPUT

	END INPUT

	CALL flushZipCodeCache()

END FUNCTION #inputAddress

PRIVATE FUNCTION showAddress(p_address TAddress) RETURNS ()

	MENU "Address Info"
		ATTRIBUTES(STYLE="dialog", COMMENT=util.JSON.format(util.JSON.stringify(p_address)))
		COMMAND "OK"
			EXIT MENU
	END MENU

END FUNCTION #showAddress