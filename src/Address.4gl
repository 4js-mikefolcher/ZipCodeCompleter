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
END record

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

	CALL buildZipCodeCache()

	INPUT r_address.* FROM s_address.*
		ATTRIBUTES(WITHOUT DEFAULTS=TRUE, ACCEPT=FALSE, CANCEL=FALSE, UNBUFFERED)

		ON ACTION zoom
			IF INFIELD(zip_code) THEN
				CALL showZipCodeZoom() RETURNING search_zipcode.*
				IF NOT search_zipcode.isEmpty() THEN
					LET r_address.zip_code = search_zipcode.zip_code
					LET r_address.city = search_zipcode.city
					LET r_address.state = search_zipcode.state_name
					DISPLAY r_address.zip_code TO s_address.zip_code
					DISPLAY r_address.city TO s_address.city
					DISPLAY r_address.state TO s_address.state
				END IF
			END IF

		ON CHANGE zip_code
			CALL zipCodeCompleter(DIALOG, r_address.zip_code)
			IF LENGTH(r_address.zip_code CLIPPED) == 5 THEN
				CALL getZipCodeRec(r_address.zip_code)
					RETURNING search_zipcode.*
				LET r_address.city = search_zipcode.city
				LET r_address.state = search_zipcode.state_name
            ELSE
                LET r_address.city = NULL
                LET r_address.state = NULL
			END IF

		ON ACTION save ATTRIBUTES(TEXT="Save")
			ACCEPT INPUT

		ON ACTION cancel_input ATTRIBUTES(TEXT="Exit")
			EXIT INPUT

		AFTER INPUT
			INITIALIZE r_address.* TO NULL
			CONTINUE INPUT

	END INPUT

	CALL flushZipCodeCache()

END FUNCTION #inputAddress