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
	zip_code CHAR(5),
	email_addr STRING
END RECORD

#+ Main
#+
MAIN

	OPTIONS INPUT WRAP

	OPEN WINDOW AddressForm WITH FORM "AddressForm"

	MENU "Select a Statement"
		COMMAND "Input"
			CALL inputAddress()
			LET int_flag = FALSE
		COMMAND "Construct"
			CALL constructAddress()
			LET int_flag = FALSE
		COMMAND "Exit"
			EXIT MENU
	END MENU

	CLOSE WINDOW AddressForm

END main #Main

#+ Input Address
#+
#+ This is an input function for addresses
#+
#+ @code
#+ CALL inputAddress()
#+
PRIVATE FUNCTION inputAddress() RETURNS ()
	DEFINE r_address TAddress
	DEFINE search_zipcode TZipCode
	DEFINE zip_code_search STRING

	CALL buildZipCodeCache()

	INPUT r_address.first_name, r_address.last_name,
		   r_address.street_addr, r_address.city,
			r_address.state, zip_code_search, r_address.zip_code,
			r_address.email_addr
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

#+ Construct Address
#+
#+ This is an construct statement function for addresses
#+
#+ @code
#+ CALL constructAddress()
#+
PRIVATE FUNCTION constructAddress() RETURNS ()
	DEFINE wherePart1 STRING
	DEFINE wherePart2 STRING
	DEFINE search_zipcode TZipCode
	DEFINE zip_code_search STRING

	CALL buildZipCodeCache()

	DIALOG ATTRIBUTES(UNBUFFERED)

		CONSTRUCT wherePart1 ON
				formonly.first_name, formonly.last_name,
				formonly.street_addr, formonly.city,
				formonly.state, formonly.zip_code
			FROM s1_address.*

		END CONSTRUCT

		INPUT zip_code_search FROM formonly.zip_code_search

			ON ACTION zoom
				IF INFIELD(zip_code_search) THEN
					CALL showZipCodeZoom() RETURNING search_zipcode.*
					IF NOT search_zipcode.isEmpty() THEN
						LET zip_code_search = search_zipcode.toString()
					END IF
				END IF

			ON CHANGE zip_code_search
				CALL zipCodeCompleter(DIALOG, zip_code_search)
				IF zip_code_search.getLength() >= 5 THEN
					CALL getZipCodeRecFromString(zip_code_search)
						RETURNING search_zipcode.*
					IF NOT search_zipcode.isEmpty() THEN
						LET zip_code_search = search_zipcode.toString()
					END IF
				END IF

			END INPUT

		CONSTRUCT wherePart2 ON
				formonly.email_addr
			FROM formonly.email_addr

		END CONSTRUCT

			ON ACTION ACCEPT
				ACCEPT DIALOG

			ON ACTION CANCEL
				LET int_flag = TRUE
				EXIT DIALOG

			AFTER DIALOG
				IF search_zipcode.isEmpty() THEN
					DISPLAY zip_code_search TO formonly.zip_code
				ELSE
					DISPLAY search_zipcode.zip_code TO formonly.zip_code
				END IF

	END DIALOG

	IF NOT int_flag THEN
		CALL showWherePart(SFMT("%1 AND %2", wherePart1, wherePart2))
	END IF

END FUNCTION #constructAddress

#+ Show Address
#+
#+ This function displays a dialog popup with the address entered by the user
#+
#+ @code
#+ CALL showAddress(r_address.*)
#+
#+ @param p_address Address record entered by the user
#+
PRIVATE FUNCTION showAddress(p_address TAddress) RETURNS ()

	MENU "Address Info"
		ATTRIBUTES(STYLE="dialog", COMMENT=util.JSON.format(util.JSON.stringify(p_address)))
		COMMAND "OK"
			EXIT MENU
	END MENU

END FUNCTION #showAddress

#+ Show Where Part
#+
#+ This function displays a dialog popup with the where part string built by
#+ the construct statement in the showConstruct() function.
#+
#+ @code
#+ CALL showWherePart("formonly.first_name MATCHES 'M*' AND 1=1")
#+
#+ @param wherePart Where part string built in the CONSTRUCT statement
#+
PRIVATE FUNCTION showWherePart(wherePart STRING) RETURNS ()

	MENU "Where Part"
		ATTRIBUTES(STYLE="dialog", COMMENT=wherePart)
		COMMAND "OK"
			EXIT MENU
	END MENU

END FUNCTION #showWherePart